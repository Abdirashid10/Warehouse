/**
 * WMS stock status — derived only from live quantities (never stored in MongoDB).
 *
 * LOW STOCK:  quantity > 0 && quantity <= minStockThreshold
 * OUT OF STOCK: quantity <= 0
 * IN STOCK:    quantity > minStockThreshold
 */

const STOCK_STATUSES = ['In Stock', 'Low Stock', 'Out of Stock'];

function normalizeQuantity(currentQuantity) {
  const qty = Number(currentQuantity);
  return Number.isFinite(qty) ? qty : 0;
}

function normalizeMinThreshold(minStockThreshold) {
  const min = Number(minStockThreshold);
  return Number.isFinite(min) && min >= 0 ? min : 0;
}

function resolveMinThreshold(rowOrProduct, fallback = 0) {
  if (rowOrProduct == null) return normalizeMinThreshold(fallback);
  if (typeof rowOrProduct === 'number') return normalizeMinThreshold(rowOrProduct);
  const min =
    rowOrProduct.min_stock_threshold ??
    rowOrProduct.minStockThreshold ??
    rowOrProduct.product?.min_stock_threshold ??
    rowOrProduct.product?.minStockThreshold ??
    fallback;
  return normalizeMinThreshold(min);
}

function resolveQuantity(row) {
  if (row == null || typeof row !== 'object') return 0;
  if (row.current_quantity != null) return normalizeQuantity(row.current_quantity);
  if (row.currentQuantity != null) return normalizeQuantity(row.currentQuantity);
  if (row.quantity != null) return normalizeQuantity(row.quantity);
  return 0;
}

function isOutOfStock(currentQuantity) {
  return normalizeQuantity(currentQuantity) <= 0;
}

function isLowStock(currentQuantity, minStockThreshold = 0) {
  const qty = normalizeQuantity(currentQuantity);
  const min = normalizeMinThreshold(minStockThreshold);
  return qty > 0 && qty <= min;
}

function isInStock(currentQuantity, minStockThreshold = 0) {
  const qty = normalizeQuantity(currentQuantity);
  const min = normalizeMinThreshold(minStockThreshold);
  return qty > min;
}

function getStockStatus(currentQuantity, minStockThreshold = 0) {
  const qty = normalizeQuantity(currentQuantity);
  const min = normalizeMinThreshold(minStockThreshold);
  if (qty <= 0) return 'Out of Stock';
  if (qty > 0 && qty <= min) return 'Low Stock';
  return 'In Stock';
}

function calculateInventoryStatus(currentQuantity, minStockThreshold = 0) {
  return getStockStatus(currentQuantity, minStockThreshold);
}

/**
 * Always recalculate status from quantity + threshold (ignores any stale stock_status).
 */
function applyStockStatusToRow(row) {
  if (!row || typeof row !== 'object') return row;
  const current_quantity = resolveQuantity(row);
  const min_stock_threshold = resolveMinThreshold(row, 0);
  const stock_status = getStockStatus(current_quantity, min_stock_threshold);
  return {
    ...row,
    current_quantity,
    min_stock_threshold,
    stock_status,
  };
}

function enrichInventoryRows(rows) {
  if (!Array.isArray(rows)) return [];
  return rows.map(applyStockStatusToRow);
}

function getLowStockItems(rows) {
  return enrichInventoryRows(rows).filter((row) => row.stock_status === 'Low Stock');
}

function getOutOfStockItems(rows) {
  return enrichInventoryRows(rows).filter((row) => row.stock_status === 'Out of Stock');
}

function summarizeInventoryRows(rows) {
  const enriched = enrichInventoryRows(rows);
  return {
    total_lines: enriched.length,
    in_stock: enriched.filter((r) => r.stock_status === 'In Stock').length,
    low_stock: enriched.filter((r) => r.stock_status === 'Low Stock').length,
    out_of_stock: enriched.filter((r) => r.stock_status === 'Out of Stock').length,
    total_units: enriched.reduce((sum, row) => sum + Math.max(0, row.current_quantity), 0),
  };
}

module.exports = {
  STOCK_STATUSES,
  normalizeQuantity,
  normalizeMinThreshold,
  resolveMinThreshold,
  resolveQuantity,
  isOutOfStock,
  isLowStock,
  isInStock,
  getStockStatus,
  calculateInventoryStatus,
  applyStockStatusToRow,
  enrichInventoryRows,
  getLowStockItems,
  getOutOfStockItems,
  summarizeInventoryRows,
};
