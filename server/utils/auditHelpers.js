const mongoose = require('mongoose');

function getClientIp(req) {
  if (!req) return '';
  const forwarded = req.headers?.['x-forwarded-for'];
  if (forwarded) return String(forwarded).split(',')[0].trim();
  return req.socket?.remoteAddress || req.ip || '';
}

function serializeAuditValue(value) {
  if (value == null || value === '') return '';
  if (typeof value === 'string') return value.slice(0, 2000);
  try {
    return JSON.stringify(value).slice(0, 2000);
  } catch {
    return String(value).slice(0, 2000);
  }
}

function normalizeWarehouseIds(ids) {
  if (!Array.isArray(ids)) return [];
  return ids
    .filter(Boolean)
    .map((id) => (mongoose.Types.ObjectId.isValid(id) ? new mongoose.Types.ObjectId(id) : null))
    .filter(Boolean);
}

function buildMovementAuditDetails({ type, quantity, product, warehouse, toWarehouse, customer }) {
  const productName = product?.name || product?.sku || 'Product';
  const fromName = warehouse?.name || '—';
  if (type === 'TRANSFER') {
    return `${productName}: ${quantity} unit(s) from ${fromName} to ${toWarehouse?.name || '—'}`;
  }
  if (type === 'OUTBOUND') {
    return `${productName}: ${quantity} unit(s) dispatched from ${fromName}${customer ? ` to ${customer}` : ''}`;
  }
  if (type === 'INBOUND') {
    return `${productName}: ${quantity} unit(s) received at ${fromName}`;
  }
  if (type === 'RETURN') {
    return `${productName}: ${quantity} unit(s) returned to ${fromName}`;
  }
  if (type === 'ADJUSTMENT') {
    return `${productName}: quantity adjusted at ${fromName}`;
  }
  return `${productName}: ${type} movement at ${fromName}`;
}

module.exports = {
  getClientIp,
  serializeAuditValue,
  normalizeWarehouseIds,
  buildMovementAuditDetails,
};
