/**
 * Client mirror of server/utils/stockStatus.js — status is NEVER stored; always derived live.
 */

export const STOCK_STATUSES = ['In Stock', 'Low Stock', 'Out of Stock'];

function normalizeQuantity(currentQuantity) {
  const qty = Number(currentQuantity);
  return Number.isFinite(qty) ? qty : 0;
}

function normalizeMinThreshold(minStockThreshold) {
  const min = Number(minStockThreshold);
  return Number.isFinite(min) && min >= 0 ? min : 0;
}

export function resolveMinThreshold(row, fallback = 0) {
  if (row == null) return normalizeMinThreshold(fallback);
  const min =
    row.min_stock_threshold ??
    row.minStockThreshold ??
    row.product?.min_stock_threshold ??
    row.product?.minStockThreshold ??
    fallback;
  return normalizeMinThreshold(min);
}

export function resolveQuantity(row) {
  if (row == null) return 0;
  if (row.current_quantity != null) return normalizeQuantity(row.current_quantity);
  if (row.currentQuantity != null) return normalizeQuantity(row.currentQuantity);
  if (row.quantity != null) return normalizeQuantity(row.quantity);
  return 0;
}

export function isOutOfStock(currentQuantity) {
  return normalizeQuantity(currentQuantity) <= 0;
}

export function isLowStock(currentQuantity, minStockThreshold = 0) {
  const qty = normalizeQuantity(currentQuantity);
  const min = normalizeMinThreshold(minStockThreshold);
  return qty > 0 && qty <= min;
}

export function isInStock(currentQuantity, minStockThreshold = 0) {
  const qty = normalizeQuantity(currentQuantity);
  const min = normalizeMinThreshold(minStockThreshold);
  return qty > min;
}

export function calculateInventoryStatus(currentQuantity, minStockThreshold = 0) {
  const qty = normalizeQuantity(currentQuantity);
  const min = normalizeMinThreshold(minStockThreshold);
  if (qty <= 0) return 'Out of Stock';
  if (qty > 0 && qty <= min) return 'Low Stock';
  return 'In Stock';
}

/** Recompute status from quantity — ignores any stale stock_status from API/cache. */
export function applyStockStatusToRow(row) {
  if (!row) return row;
  const current_quantity = resolveQuantity(row);
  const min_stock_threshold = resolveMinThreshold(row, 0);
  const stock_status = calculateInventoryStatus(current_quantity, min_stock_threshold);
  return {
    ...row,
    current_quantity,
    min_stock_threshold,
    stock_status,
  };
}

export function enrichInventoryRows(rows) {
  if (!Array.isArray(rows)) return [];
  return rows.map(applyStockStatusToRow);
}

export function summarizeInventoryRows(rows) {
  const enriched = enrichInventoryRows(rows);
  return {
    total_lines: enriched.length,
    in_stock: enriched.filter((r) => r.stock_status === 'In Stock').length,
    low_stock: enriched.filter((r) => r.stock_status === 'Low Stock').length,
    out_of_stock: enriched.filter((r) => r.stock_status === 'Out of Stock').length,
    total_units: enriched.reduce((sum, row) => sum + Math.max(0, row.current_quantity), 0),
  };
}
