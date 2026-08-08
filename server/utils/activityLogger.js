const { UserActivityLog } = require('../models');
const { getClientIp, serializeAuditValue, normalizeWarehouseIds } = require('./auditHelpers');

/**
 * Record an audit event. Pass `req` when available to capture IP address.
 */
async function logAudit(req, {
  actorId,
  actorRole = '',
  targetUserId = null,
  action,
  module,
  details = '',
  entityType = '',
  entityId = '',
  entityLabel = '',
  beforeValue = '',
  afterValue = '',
  warehouseIds = [],
}) {
  if (!actorId || !action || !module) return;

  try {
    await UserActivityLog.create({
      actorId,
      actorRole: String(actorRole || '').trim(),
      targetUserId,
      action: String(action).trim().slice(0, 120),
      module: String(module).trim().slice(0, 80),
      details: String(details || '').trim().slice(0, 1000),
      entityType: String(entityType || '').trim().slice(0, 60),
      entityId: String(entityId || '').trim().slice(0, 80),
      entityLabel: String(entityLabel || '').trim().slice(0, 200),
      beforeValue: serializeAuditValue(beforeValue),
      afterValue: serializeAuditValue(afterValue),
      ipAddress: getClientIp(req).slice(0, 64),
      warehouseIds: normalizeWarehouseIds(warehouseIds),
    });
  } catch (_err) {
    // Intentionally swallow logging errors to avoid blocking business flows.
  }
}

/** Backward-compatible wrapper (no req / extended fields). */
async function logActivity(payload) {
  return logAudit(null, payload);
}

module.exports = { logActivity, logAudit };
