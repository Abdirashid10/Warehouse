/**
 * Verify audit log role filtering and KPI/table alignment.
 * Usage: node scripts/verify-audit-role-filter.js
 */
require('dotenv').config();
const mongoose = require('mongoose');
const { connectDB } = require('../config/db');
const { User, UserActivityLog } = require('../models');
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

async function summarize(userDoc, assignedWarehouseIds) {
  const req = {
    user: {
      id: userDoc._id.toString(),
      role: userDoc.role,
      assignedWarehouseIds,
    },
    query: {},
  };
  const filter = buildActivityFilter(req);

  const [total, logs, moduleAgg] = await Promise.all([
    UserActivityLog.countDocuments(filter),
    UserActivityLog.find(filter).select('module actorId').populate('actorId', 'role username').lean(),
    UserActivityLog.aggregate([
      { $match: filter },
      { $group: { _id: '$module', count: { $sum: 1 } } },
    ]),
  ]);

  const moduleCounts = {};
  for (const row of moduleAgg) {
    const key = normalizeModuleKey(row._id);
    if (!key) continue;
    moduleCounts[key] = (moduleCounts[key] || 0) + row.count;
  }

  const tableKeyCounts = {};
  for (const row of logs) {
    const key = normalizeModuleKey(row.module);
    if (!key) continue;
    tableKeyCounts[key] = (tableKeyCounts[key] || 0) + 1;
  }

  const adminActorLogs = logs.filter((l) => l.actorId?.role === 'Admin').length;

  return {
    username: userDoc.username,
    role: userDoc.role,
    assignedWarehouseIds,
    total,
    moduleCounts,
    tableKeyCounts,
    kpiSum: Object.values(moduleCounts).reduce((s, n) => s + n, 0),
    kpiMatchesTotal: Object.values(moduleCounts).reduce((s, n) => s + n, 0) === total,
    adminActorLogsVisible: adminActorLogs,
  };
}

async function legacySupervisorSummary(supervisor) {
  const assigned = (supervisor.assignedWarehouseIds || []).map((id) => id.toString());
  const filter = legacySupervisorFilter(supervisor._id.toString(), assigned);
  const total = await UserActivityLog.countDocuments(filter);
  const adminActorLogs = await UserActivityLog.countDocuments({
    ...filter,
    actorId: { $in: await User.find({ role: 'Admin' }).distinct('_id') },
  });
  return { total, adminActorLogsVisible: adminActorLogs };
}

async function resolveAssignedWarehouses(user) {
  let ids = (user.assignedWarehouseIds || []).map((id) => id.toString());
  if ((user.role === 'Staff' || user.role === 'Supervisor') && ids.length === 0) {
    const warehouseQuery =
      user.role === 'Staff'
        ? { assignedStaffIds: user._id }
        : { $or: [{ assignedStaffIds: user._id }, { createdBy: user._id }] };
    const linked = await require('../models').Warehouse.find(warehouseQuery).select('_id').lean();
    ids = linked.map((w) => w._id.toString());
  }
  return ids;
}

async function main() {
  await connectDB();

  const admin = await User.findOne({ role: 'Admin', archived: { $ne: true } }).lean();
  const supervisor = await User.findOne({ role: 'Supervisor', archived: { $ne: true } }).lean();
  if (!admin || !supervisor) throw new Error('Need Admin and Supervisor users');

  const supervisorWarehouses = await resolveAssignedWarehouses(supervisor);
  const legacy = await legacySupervisorSummary(supervisor);
  const adminResult = await summarize(admin, []);
  const supervisorResult = await summarize(supervisor, supervisorWarehouses);
  const allLogs = await UserActivityLog.countDocuments();

  console.log(JSON.stringify({
    allLogsInDb: allLogs,
    before: {
      supervisor: {
        username: supervisor.username,
        total: legacy.total,
        adminActorLogsVisible: legacy.adminActorLogsVisible,
      },
    },
    after: {
      admin: adminResult,
      supervisor: supervisorResult,
    },
  }, null, 2));

  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
