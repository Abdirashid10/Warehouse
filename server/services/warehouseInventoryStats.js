const Inventory = require('../models/Inventory');

/**
 * Sum on-hand units and stock lines per warehouse from live inventory records.
 * Matches dashboard warehouse performance aggregation.
 */
async function fetchWarehouseInventoryTotals(warehouseIds = null) {
  const match = { quantity: { $gt: 0 } };
  if (Array.isArray(warehouseIds) && warehouseIds.length > 0) {
    match.warehouseId = { $in: warehouseIds };
  }

  const rows = await Inventory.aggregate([
    { $match: match },
    {
      $group: {
        _id: '$warehouseId',
        totalUnits: { $sum: '$quantity' },
        lineCount: { $sum: 1 },
      },
    },
  ]);

  const map = new Map();
  for (const row of rows) {
    if (!row._id) continue;
    map.set(row._id.toString(), {
      totalUnits: row.totalUnits ?? 0,
      lineCount: row.lineCount ?? 0,
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
