const { fetchInventoryTrackingRows } = require('./inventoryTrackingService');
const { summarizeWarehouseTotals } = require('../utils/inventoryValuation');

/**
 * On-hand units and stock lines per warehouse, derived from the same live
 * tracking rows as the dashboard KPIs and the audit report — so a warehouse
 * card, the dashboard, and the PDF can never show different totals.
 *
 * A "line" is one product × warehouse pair (Inventory stores one document per
 * condition, so counting documents would over-report lines).
 */
async function fetchWarehouseInventoryTotals(warehouseIds = null) {
  const ids = Array.isArray(warehouseIds) ? warehouseIds.map(String).filter(Boolean) : [];
  const { rows } = await fetchInventoryTrackingRows(ids.length ? { warehouseIds: ids } : {});

  const map = new Map();
  for (const entry of summarizeWarehouseTotals(rows)) {
    if (!entry.warehouse_id) continue;
    map.set(entry.warehouse_id, {
      totalUnits: entry.total_units,
      lineCount: entry.line_count,
    });
  }
  return map;
}

function utilizationPercent(totalUnits, capacity) {
  const cap = Number(capacity) || 0;
  const units = Number(totalUnits) || 0;
  if (cap <= 0) return 0;
  return Math.min(100, Math.round((units / cap) * 100));
}

module.exports = {
  fetchWarehouseInventoryTotals,
  utilizationPercent,
};
