/**
 * Final audit log role-filter verification.
 */
require('dotenv').config();
const mongoose = require('mongoose');
const { connectDB } = require('../config/db');
const { User, UserActivityLog, Warehouse } = require('../models');
const { buildActivityFilter } = require('../controllers/auditController');
const { normalizeModuleKey } = require('../constants/audit');

function legacySupervisorFilter(supervisorId, assignedIds) {
  const assigned = assignedIds
    .filter((id) => mongoose.Types.ObjectId.isValid(id))
    .map((id) => new mongoose.Types.ObjectId(id));
  const scopeOr = [
    { actorId: new mongoose.Types.ObjectId(supervisorId) },
    { module: { $in: ['Tasks', 'Profile'] } },
  ];
  if (assigned.length) scopeOr.push({ warehouseIds: { $in: assigned } });
  return { $and: [{ $or: scopeOr }] };
}

async function resolveAssignedWarehouses(user) {
  let ids = (user.assignedWarehouseIds || []).map((id) => id.toString());
  if ((user.role === 'Staff' || user.role === 'Supervisor') && ids.length === 0) {
    const warehouseQuery =
      user.role === 'Staff'
        ? { assignedStaffIds: user._id }
        : { $or: [{ assignedStaffIds: user._id }, { createdBy: user._id }] };
    const linked = await Warehouse.find(warehouseQuery).select('_id name').lean();
    return { ids: linked.map((w) => w._id.toString()), warehouses: linked };
  }
  const warehouses = ids.length
    ? await Warehouse.find({ _id: { $in: ids } }).select('_id name').lean()
    : [];
  return { ids, warehouses };
}

function makeReq(user, assignedWarehouseIds) {
  return {
    user: {
      id: user._id.toString(),
      role: user.role,
      assignedWarehouseIds,
    },
    query: {},
  };
}

async function analyzeFilter(filter, label) {
  const [total, logs, moduleAgg] = await Promise.all([
    UserActivityLog.countDocuments(filter),
    UserActivityLog.find(filter)
      .sort({ createdAt: -1 })
      .populate('actorId', 'username role')
      .lean(),
    UserActivityLog.aggregate([
      { $match: filter },
      { $group: { _id: '$module', count: { $sum: 1 } } },
    ]),
  ]);

  const moduleCounts = {};
  for (const row of moduleAgg) {
    const key = normalizeModuleKey(row._id);
    if (key) moduleCounts[key] = (moduleCounts[key] || 0) + row.count;
  }

  const byActorRole = {};
  const byReason = { own: 0, warehouse: 0, invalid: 0 };
  const supervisorId = label.includes('supervisor') ? logs[0]?.actorId?._id : null;

  for (const log of logs) {
    const role = log.actorId?.role || 'unknown';
    byActorRole[role] = (byActorRole[role] || 0) + 1;
  }

  const newest = logs[0];
  const oldest = logs[logs.length - 1];

  return {
    label,
    total,
    moduleCounts,
    kpiSum: Object.values(moduleCounts).reduce((s, n) => s + n, 0),
    byActorRole,
    newest: newest
      ? {
          action: newest.action,
          module: newest.module,
          actor: newest.actorId?.username,
          actorRole: newest.actorId?.role,
          createdAt: newest.createdAt,
          warehouseIds: (newest.warehouseIds || []).map(String),
        }
      : null,
    oldestCreatedAt: oldest?.createdAt || null,
    sampleExcludedReasons: null,
  };
}

async function explainSupervisorExclusions(supervisor, assignedIds) {
  const supervisorId = supervisor._id;
  const assigned = assignedIds
    .filter((id) => mongoose.Types.ObjectId.isValid(id))
    .map((id) => new mongoose.Types.ObjectId(id));

  const legacyFilter = legacySupervisorFilter(supervisorId.toString(), assignedIds);
  const newFilter = buildActivityFilter(makeReq(supervisor, assignedIds));

  const legacyIds = new Set(
    (await UserActivityLog.find(legacyFilter).select('_id').lean()).map((l) => l._id.toString())
  );
  const newIds = new Set(
    (await UserActivityLog.find(newFilter).select('_id').lean()).map((l) => l._id.toString())
  );

  const excluded = [...legacyIds].filter((id) => !newIds.has(id));
  const excludedLogs = await UserActivityLog.find({ _id: { $in: excluded } })
    .populate('actorId', 'username role')
    .lean();

  const reasons = { globalTasksProfile: 0, otherActorNoWarehouse: 0, other: 0 };
  const breakdown = { byModule: {}, byActorRole: {} };

  for (const log of excludedLogs) {
    const mod = log.module;
    breakdown.byModule[mod] = (breakdown.byModule[mod] || 0) + 1;
    const role = log.actorId?.role || 'unknown';
    breakdown.byActorRole[role] = (breakdown.byActorRole[role] || 0) + 1;

    const isOwn = log.actorId?._id?.toString() === supervisorId.toString();
    const whOverlap =
      assigned.length > 0 &&
      (log.warehouseIds || []).some((wid) =>
        assigned.some((a) => a.toString() === wid.toString())
      );

    if (!isOwn && !whOverlap && ['Tasks', 'Profile'].includes(mod)) {
      reasons.globalTasksProfile++;
    } else if (!isOwn && !whOverlap) {
      reasons.otherActorNoWarehouse++;
    } else {
      reasons.other++;
    }
  }

  const wronglyHidden = excludedLogs.filter((log) => {
    const isOwn = log.actorId?._id?.toString() === supervisorId.toString();
    const whOverlap =
      assigned.length > 0 &&
      (log.warehouseIds || []).some((wid) =>
        assigned.some((a) => a.toString() === wid.toString())
      );
    return isOwn || whOverlap;
  });

  return {
    legacyCount: legacyIds.size,
    newCount: newIds.size,
    excludedCount: excluded.length,
    exclusionReasons: reasons,
    excludedBreakdown: breakdown,
    wronglyHiddenCount: wronglyHidden.length,
    wronglyHidden: wronglyHidden.map((l) => ({
      action: l.action,
      module: l.module,
      actor: l.actorId?.username,
    })),
  };
}

async function validateSupervisorLogs(supervisor, assignedIds, logs) {
  const supervisorId = supervisor._id.toString();
  const assigned = assignedIds.map(String);
  const violations = [];

  for (const log of logs) {
    const isOwn = log.actorId?._id?.toString() === supervisorId;
    const whOverlap = (log.warehouseIds || []).some((wid) => assigned.includes(wid.toString()));
    if (!isOwn && !whOverlap) {
      violations.push({
        id: log._id.toString(),
        action: log.action,
        module: log.module,
        actor: log.actorId?.username,
        actorRole: log.actorId?.role,
        warehouseIds: (log.warehouseIds || []).map(String),
      });
    }
  }
  return violations;
}

async function main() {
  await connectDB();

  const admin = await User.findOne({ role: 'Admin', archived: { $ne: true } }).lean();
  const supervisor = await User.findOne({ username: 'rashka' }).lean()
    || await User.findOne({ role: 'Supervisor', archived: { $ne: true } }).lean();

  const { ids: supervisorWarehouseIds, warehouses: supervisorWarehouses } =
    await resolveAssignedWarehouses(supervisor);

  const allCount = await UserActivityLog.countDocuments();
  const adminAnalysis = await analyzeFilter(buildActivityFilter(makeReq(admin, [])), 'admin');
  const supervisorAnalysis = await analyzeFilter(
    buildActivityFilter(makeReq(supervisor, supervisorWarehouseIds)),
    'supervisor'
  );

  const supervisorLogs = await UserActivityLog.find(
    buildActivityFilter(makeReq(supervisor, supervisorWarehouseIds))
  )
    .sort({ createdAt: -1 })
    .populate('actorId', 'username role')
    .lean();

  const violations = await validateSupervisorLogs(
    supervisor,
    supervisorWarehouseIds,
    supervisorLogs
  );
  const exclusions = await explainSupervisorExclusions(supervisor, supervisorWarehouseIds);

  const legacyNewest = await UserActivityLog.findOne(
    legacySupervisorFilter(supervisor._id.toString(), supervisorWarehouseIds)
  )
    .sort({ createdAt: -1 })
    .populate('actorId', 'username role')
    .lean();

  console.log(
    JSON.stringify(
      {
        allLogsInDb: allCount,
        supervisorWarehouses,
        admin: adminAnalysis,
        supervisor: supervisorAnalysis,
        reduction: {
          from: exclusions.legacyCount,
          to: exclusions.newCount,
          delta: exclusions.legacyCount - exclusions.newCount,
          expectedDueToFilter: exclusions.excludedCount,
          exclusionReasons: exclusions.exclusionReasons,
          excludedBreakdown: exclusions.excludedBreakdown,
        },
        topRecordChange: {
          legacyNewest: legacyNewest
            ? {
                action: legacyNewest.action,
                module: legacyNewest.module,
                actor: legacyNewest.actorId?.username,
                actorRole: legacyNewest.actorId?.role,
                createdAt: legacyNewest.createdAt,
              }
            : null,
          currentNewest: supervisorAnalysis.newest,
        },
        wronglyHidden: {
          count: exclusions.wronglyHiddenCount,
          samples: exclusions.wronglyHidden,
        },
        filterViolations: violations,
        productionChecks: {
          adminSeesAll: adminAnalysis.total === allCount,
          supervisorKpiMatchesTotal: supervisorAnalysis.kpiSum === supervisorAnalysis.total,
          noFilterViolations: violations.length === 0,
          noWronglyHidden: exclusions.wronglyHiddenCount === 0,
        },
      },
      null,
      2
    )
  );

  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
