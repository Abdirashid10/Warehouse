/**
 * Derived inventory statistics — the single source of truth for every summary
 * number the product shows (web dashboard, mobile app, reports screen, PDF).
 *
 * Every helper here consumes the SAME product × warehouse rows produced by
 * services/inventoryTrackingService, so a KPI can never drift from the report
 * that is supposed to explain it:
 *
 *   - one line  = one (product, warehouse) pair (NOT one Inventory document —
 *     Inventory is split per condition, so raw doc counts over-report lines)
 *   - unit totals ignore the product join, so stock attached to a deleted
 *     product is still counted (the dashboard counts it, so the PDF must too)
 *   - money values are rounded per line, then summed, so the printed line
 *     values in a report always add up to the printed total
 */

function roundMoney(n) {
  return Math.round((Number(n) || 0) * 100) / 100;
}

function toNumber(value) {
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

/** On-hand units for one line. Never negative — matches summarizeInventoryRows. */
function lineUnits(row) {
  if (!row || typeof row !== 'object') return 0;
  const qty = row.current_quantity ?? row.currentQuantity ?? row.quantity;
  return Math.max(0, toNumber(qty));
}

function unitCostOf(row) {
  return toNumber(row?.unit_cost ?? row?.product?.unit_cost ?? row?.product?.unitCost);
}

function unitPriceOf(row) {
  return toNumber(row?.unit_price ?? row?.product?.unit_price ?? row?.product?.unitPrice);
}

function lineCostValue(row) {
  return roundMoney(lineUnits(row) * unitCostOf(row));
}

function lineRetailValue(row) {
  return roundMoney(lineUnits(row) * unitPriceOf(row));
}

/**
 * Condition split for one line. Accepts tracking rows (available_stock…) and
 * audit detail rows (good_qty…). Stock stored under an unrecognised condition
 * falls back to "good" so the split always totals lineUnits().
 */
function conditionSplit(row) {
  const units = lineUnits(row);
  const damaged = Math.max(0, toNumber(row?.damaged_stock ?? row?.damaged_qty));
  const inspection = Math.max(0, toNumber(row?.reserved_stock ?? row?.inspection_qty));
  const good = Math.max(0, units - damaged - inspection);
  return { good, damaged, inspection };
}

/**
 * Financial + line-count summary. `total_units` / `inventory_lines` /
 * `low_stock_lines` / `out_of_stock_lines` are byte-identical to the dashboard's
 * inventorySummary because both are computed from the same rows.
 */
function summarizeInventoryFinancials(rows) {
  const list = Array.isArray(rows) ? rows : [];

  let totalUnits = 0;
  let costValue = 0;
  let retailValue = 0;
  let inStock = 0;
  let lowStock = 0;
  let outOfStock = 0;

  for (const row of list) {
    totalUnits += lineUnits(row);
    costValue += lineCostValue(row);
    retailValue += lineRetailValue(row);
    if (row?.stock_status === 'Low Stock') lowStock += 1;
    else if (row?.stock_status === 'Out of Stock') outOfStock += 1;
    else inStock += 1;
  }

  const cost_value = roundMoney(costValue);
  const retail_value = roundMoney(retailValue);

  return {
    cost_value,
    retail_value,
    estimated_profit: roundMoney(retail_value - cost_value),
    total_units: totalUnits,
    inventory_lines: list.length,
    in_stock_lines: inStock,
    low_stock_lines: lowStock,
    out_of_stock_lines: outOfStock,
  };
}

/**
 * System-wide condition distribution. total_qty always equals
 * summarizeInventoryFinancials(rows).total_units.
 */
function summarizeConditionBreakdown(rows) {
  const list = Array.isArray(rows) ? rows : [];

  let available_qty = 0;
  let damaged_qty = 0;
  let inspection_qty = 0;

  for (const row of list) {
    const split = conditionSplit(row);
    available_qty += split.good;
    damaged_qty += split.damaged;
    inspection_qty += split.inspection;
  }

  const total_qty = available_qty + damaged_qty + inspection_qty;
  const pct = (part) => (total_qty ? roundMoney((part / total_qty) * 100) : 0);

  return {
    available_qty,
    damaged_qty,
    inspection_qty,
    total_qty,
    available_pct: pct(available_qty),
    damaged_pct: pct(damaged_qty),
    inspection_pct: pct(inspection_qty),
  };
}

/**
 * Per-warehouse rollup. Summing total_units across the result reproduces the
 * system-wide total_units exactly, and line_count uses the same
 * one-line-per-product×warehouse rule as every other count.
 */
function summarizeWarehouseTotals(rows) {
  const list = Array.isArray(rows) ? rows : [];
  const byWarehouse = new Map();

  for (const row of list) {
    const id = row?.warehouse_id || row?.warehouse?.id || '';
    const key = id || 'unknown';
    let entry = byWarehouse.get(key);
    if (!entry) {
      entry = {
        warehouse_id: id || null,
        warehouse_name: row?.warehouse_name || row?.warehouse?.name || 'Unknown',
        warehouse_location: row?.warehouse_location || row?.warehouse?.location || '',
        total_units: 0,
        line_count: 0,
        cost_value: 0,
        retail_value: 0,
      };
      byWarehouse.set(key, entry);
    }
    entry.total_units += lineUnits(row);
    entry.line_count += 1;
    entry.cost_value += lineCostValue(row);
    entry.retail_value += lineRetailValue(row);
  }

  return [...byWarehouse.values()]
    .map((entry) => ({
      ...entry,
      cost_value: roundMoney(entry.cost_value),
      retail_value: roundMoney(entry.retail_value),
    }))
    .sort((a, b) => a.warehouse_name.localeCompare(b.warehouse_name));
}

module.exports = {
  roundMoney,
  lineUnits,
  lineCostValue,
  lineRetailValue,
  conditionSplit,
  summarizeInventoryFinancials,
  summarizeConditionBreakdown,
  summarizeWarehouseTotals,
};
