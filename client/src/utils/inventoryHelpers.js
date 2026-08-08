/** Normalize Mongo/API ids to comparable strings. */
export function normalizeEntityId(value) {
  if (value == null || value === '') return '';
  return String(value);
}

export function getProductId(product) {
  if (!product) return '';
  return normalizeEntityId(product.id ?? product._id);
}

export function getWarehouseId(warehouse) {
  if (!warehouse) return '';
  return normalizeEntityId(warehouse.id ?? warehouse._id ?? warehouse.warehouse_id);
}

export function getWarehouseName(warehouse) {
  if (!warehouse) return '';
  return warehouse.name ?? warehouse.warehouse_name ?? '';
}

/** Dev-only structured logging for stock movement debugging. */
export function debugStockMovement(label, payload) {
  if (import.meta.env?.DEV) {
    console.debug(`[stock-movement] ${label}`, payload);
  }
}
