const mongoose = require('mongoose');
const { UserActivityLog } = require('../models');
const { resolveModuleFilter, normalizeModuleKey } = require('../constants/audit');

function parsePage(value) {
  const n = parseInt(String(value ?? ''), 10);
  return Number.isFinite(n) && n >= 1 ? n : 1;
}

function parseLimit(value, fallback = 50, max = 200) {
  const n = parseInt(String(value ?? ''), 10);
  if (!Number.isFinite(n) || n < 1) return fallback;
  return Math.min(n, max);
}

function parseDateRange(from, to) {
  const range = {};
  if (from) {
    const d = new Date(from);
    if (!Number.isNaN(d.getTime())) range.$gte = d;
  }
  if (to) {
    const d = new Date(to);
    if (!Number.isNaN(d.getTime())) {
      d.setHours(23, 59, 59, 999);
      range.$lte = d;
    }
  }
  return Object.keys(range).length ? range : null;
}

function formatActivityLog(log) {
  return {
    id: log._id.toString(),
    action: log.action,
    module: log.module,
    details: log.details || '',
    actorRole: log.actorRole || log.actorId?.role || '',
    entityType: log.entityType || '',
    entityId: log.entityId || '',
    entityLabel: log.entityLabel || '',
    beforeValue: log.beforeValue || '',
    afterValue: log.afterValue || '',
    ipAddress: log.ipAddress || '',
    warehouseIds: (log.warehouseIds || []).map((id) => id.toString()),
    createdAt: log.createdAt,
    actor: log.actorId
      ? {
          id: log.actorId._id?.toString(),
          username: log.actorId.username,
          role: log.actorId.role,
          fullName: log.actorId.fullName,
        }
      : null,
    target: log.targetUserId
      ? {
          id: log.targetUserId._id?.toString(),
          username: log.targetUserId.username,
          role: log.targetUserId.role,
          fullName: log.targetUserId.fullName,
        }
      : null,
  };
}

function buildActivityFilter(req) {
  const filter = {};

  const moduleValues = resolveModuleFilter(req.query.module);
  if (moduleValues) filter.module = { $in: moduleValues };

  if (req.query.action) {
    filter.action = { $regex: req.query.action, $options: 'i' };
  }
  if (req.query.actor_id && mongoose.Types.ObjectId.isValid(req.query.actor_id)) {
    filter.actorId = req.query.actor_id;
  }

  const dateRange = parseDateRange(req.query.from, req.query.to);
  if (dateRange) filter.createdAt = dateRange;

  if (req.query.q) {
    const q = String(req.query.q).trim();
    filter.$or = [
      { action: { $regex: q, $options: 'i' } },
      { module: { $regex: q, $options: 'i' } },
      { details: { $regex: q, $options: 'i' } },
      { entityLabel: { $regex: q, $options: 'i' } },
      { entityId: { $regex: q, $options: 'i' } },
      { beforeValue: { $regex: q, $options: 'i' } },
      { afterValue: { $regex: q, $options: 'i' } },
    ];
  }

  if (req.user.role === 'Supervisor') {
    const supervisorId = new mongoose.Types.ObjectId(req.user.id);
    const assigned = (req.user.assignedWarehouseIds || [])
      .filter((id) => mongoose.Types.ObjectId.isValid(id))
      .map((id) => new mongoose.Types.ObjectId(id));

    filter.$and = filter.$and || [];
    if (assigned.length === 0) {
      filter.$and.push({ actorId: supervisorId });
    } else {
      filter.$and.push({
        $or: [
          { actorId: supervisorId },
          { warehouseIds: { $in: assigned } },
        ],
      });
    }
  }

  return filter;
}

/**
 * GET /api/audit/activities — Admin: full log; Supervisor: own logs or assigned-warehouse logs.
 */
async function listActivities(req, res) {
  try {
    const page = parsePage(req.query.page);
    const limit = parseLimit(req.query.limit, 50);
    const skip = (page - 1) * limit;
    const filter = buildActivityFilter(req);

    const [total, logs, moduleAgg] = await Promise.all([
      UserActivityLog.countDocuments(filter),
      UserActivityLog.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('actorId', 'username role fullName')
        .populate('targetUserId', 'username role fullName')
        .lean(),
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

    return res.json({
      activities: logs.map(formatActivityLog),
      pagination: { page, limit, total, pages: Math.max(1, Math.ceil(total / limit)) },
      moduleCounts,
    });
  } catch (err) {
    console.error('listActivities error:', err.message);
    return res.status(500).json({ message: 'Failed to load activity logs' });
  }
}

/**
 * GET /api/audit/recent — recent audit entries for dashboards/reports.
 */
async function getRecentActivities(req, res) {
  try {
    const limit = parseLimit(req.query.limit, 10, 50);
    const filter = buildActivityFilter(req);

    const logs = await UserActivityLog.find(filter)
      .sort({ createdAt: -1 })
      .limit(limit)
      .populate('actorId', 'username role fullName')
      .populate('targetUserId', 'username role fullName')
      .lean();

    return res.json({ activities: logs.map(formatActivityLog) });
  } catch (err) {
    console.error('getRecentActivities error:', err.message);
    return res.status(500).json({ message: 'Failed to load recent activity' });
  }
}

module.exports = { listActivities, getRecentActivities, buildActivityFilter };
