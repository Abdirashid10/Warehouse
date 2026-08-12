const { Product, Movement } = require('../models');
const { COLLECTIONS, leftJoin } = require('../utils/lookupHelpers');
const { formatPerformedByUser } = require('../utils/createdByDto');
const { fetchInventoryTrackingRows } = require('../services/inventoryTrackingService');
const {
  roundMoney,
  lineUnits,
  lineCostValue,
  lineRetailValue,
  conditionSplit,
  summarizeInventoryFinancials,
  summarizeConditionBreakdown,
  summarizeWarehouseTotals,
} = require('../utils/inventoryValuation');

const FAST_MOVING_DAYS = 90;
const AUDIT_TRAIL_LIMIT = 20;

/**
 * GET /api/reports/valuation — legacy summary (Admin & Supervisor).
 */
async function getValuation(req, res) {
  try {
    const report = await buildInventoryAuditPayload();
    return res.json({
      valuation: {
        total_units: report.financial_summary.total_units,
        inventory_lines: report.financial_summary.inventory_lines,
        product_count: report.financial_summary.product_count,
        cost_value: report.financial_summary.cost_value,
        retail_value: report.financial_summary.retail_value,
        estimated_profit: report.financial_summary.estimated_profit,
        generated_at: report.generated_at,
      },
    });
  } catch (err) {
    console.error('getValuation error:', err.message);
    return res.status(500).json({ message: 'Failed to generate valuation report' });
  }
}

/**
 * GET /api/reports/inventory-audit — full WMS inventory audit dataset.
 */
async function getInventoryAudit(req, res) {
  try {
    const payload = await buildInventoryAuditPayload(req.user);
    return res.json(payload);
  } catch (err) {
    console.error('getInventoryAudit error:', err.message);
    return res.status(500).json({ message: 'Failed to generate inventory audit report' });
  }
}

async function buildInventoryAuditPayload(user) {
  const generatedAt = new Date();

  /*
   * The audit dataset is derived from the exact same live tracking rows the
   * dashboard reads (services/inventoryTrackingService), so every figure the
   * PDF prints is the figure the web dashboard and mobile app display.
   */
  const [tracking, productCount, fastMoving, auditRows] = await Promise.all([
    fetchInventoryTrackingRows(),
    Product.countDocuments(),
    aggregateFastMoving(),
    aggregateAuditTrail(),
  ]);

  const detailRows = (tracking.rows || []).map(toAuditDetailRow).sort(bySkuThenWarehouse);

  const financials = summarizeInventoryFinancials(detailRows);
  const conditionBreakdown = summarizeConditionBreakdown(detailRows);
  const warehouseComparison = summarizeWarehouseTotals(detailRows).map((w) => ({
    warehouse_id: w.warehouse_id,
    warehouse_name: w.warehouse_name,
    total_units: w.total_units,
    line_count: w.line_count,
    cost_value: w.cost_value,
    retail_value: w.retail_value,
  }));

  const lowStockAlerts = detailRows
    .filter((r) => r.stock_status === 'Low Stock' || r.stock_status === 'Out of Stock')
    .map((r) => ({
      sku: r.sku,
      product_name: r.product_name,
      category: r.category,
      warehouse: r.warehouse_name,
      current_quantity: r.current_quantity,
      min_stock_threshold: r.min_stock_threshold,
      stock_status: r.stock_status,
      unit_cost: r.unit_cost,
      line_cost_value: r.line_cost_value,
    }));

  return {
    generated_at: generatedAt.toISOString(),
    generated_by: user
      ? {
          id: user.id || user._id?.toString(),
          username: user.username,
          email: user.email,
          role: user.role,
        }
      : null,
    system_name: 'LOGISTICS WMS',
    financial_summary: {
      cost_value: financials.cost_value,
      retail_value: financials.retail_value,
      total_units: financials.total_units,
      estimated_profit: financials.estimated_profit,
      inventory_lines: financials.inventory_lines,
      in_stock_lines: financials.in_stock_lines,
      low_stock_lines: financials.low_stock_lines,
      out_of_stock_lines: financials.out_of_stock_lines,
      product_count: productCount,
    },
    /* Identical shape/values to the dashboard's `inventorySummary`. */
    inventory_summary: tracking.summary,
    warehouse_comparison: warehouseComparison,
    condition_breakdown: conditionBreakdown,
    inventory_detail: detailRows,
    low_stock_alerts: lowStockAlerts,
    fast_moving_products: fastMoving,
    audit_trail: auditRows,
  };
}

/** Tracking row → audit detail register row (one product × warehouse line). */
function toAuditDetailRow(row) {
  const split = conditionSplit(row);

  const detail = {
    id: row.id,
    product_id: row.product_id,
    warehouse_id: row.warehouse_id,
    sku: row.sku || '—',
    product_name: row.product_name || '—',
    category: row.product?.category?.name || '—',
    warehouse_name: row.warehouse_name || '—',
    warehouse_location: row.warehouse?.location || '',
    current_quantity: lineUnits(row),
    good_qty: split.good,
    damaged_qty: split.damaged,
    inspection_qty: split.inspection,
    condition_summary: `Good: ${split.good} · Damaged: ${split.damaged} · Insp: ${split.inspection}`,
    /* Rounded first, then multiplied — printed unit cost × qty == printed line value. */
    unit_cost: roundMoney(row.product?.unit_cost),
    unit_price: roundMoney(row.product?.unit_price),
    min_stock_threshold: row.min_stock_threshold ?? 0,
    stock_status: row.stock_status,
  };

  detail.line_cost_value = lineCostValue(detail);
  detail.line_retail_value = lineRetailValue(detail);
  return detail;
}

function bySkuThenWarehouse(a, b) {
  return (
    String(a.sku).localeCompare(String(b.sku)) ||
    String(a.warehouse_name).localeCompare(String(b.warehouse_name))
  );
}

async function aggregateFastMoving() {
  const since = new Date();
  since.setDate(since.getDate() - FAST_MOVING_DAYS);

  const rows = await Movement.aggregate([
    {
      $match: {
        type: 'OUTBOUND',
        createdAt: { $gte: since },
      },
    },
    {
      $group: {
        _id: '$productId',
        outbound_units: { $sum: '$quantity' },
        movement_count: { $sum: 1 },
      },
    },
    { $sort: { outbound_units: -1 } },
    { $limit: 5 },
    ...leftJoin('_id', COLLECTIONS.products, 'product'),
    {
      $lookup: {
        from: COLLECTIONS.categories,
        localField: 'product.categoryId',
        foreignField: '_id',
        as: 'category',
      },
    },
    { $unwind: { path: '$category', preserveNullAndEmptyArrays: true } },
  ]);

  return rows.map((r, index) => ({
    rank: index + 1,
    product_id: r._id?.toString(),
    sku: r.product?.sku || '—',
    product_name: r.product?.name || '—',
    category: r.category?.name || '—',
    outbound_units: r.outbound_units ?? 0,
    movement_count: r.movement_count ?? 0,
    period_days: FAST_MOVING_DAYS,
  }));
}

async function aggregateAuditTrail() {
  const rows = await Movement.aggregate([
    { $sort: { createdAt: -1 } },
    { $limit: AUDIT_TRAIL_LIMIT },
    ...leftJoin('productId', COLLECTIONS.products, 'product'),
    ...leftJoin('warehouseId', COLLECTIONS.warehouses, 'warehouse'),
    ...leftJoin('toWarehouseId', COLLECTIONS.warehouses, 'toWarehouse'),
    ...leftJoin('createdBy', COLLECTIONS.users, 'creator'),
    {
      $lookup: {
        from: COLLECTIONS.users,
        localField: 'userId',
        foreignField: '_id',
        as: 'performer',
      },
    },
    { $unwind: { path: '$performer', preserveNullAndEmptyArrays: true } },
  ]);

  return rows.map((m) => {
    const performer = formatPerformedByUser(
      { creator: m.creator, performer: m.performer },
      { missingMeansDeleted: true }
    );
    return {
      id: m._id.toString(),
      type: m.type,
      quantity: m.quantity,
      reason: m.reason || '',
      source_location: m.source_location || '',
      destination_location: m.destination_location || '',
      timestamp: m.timestamp || m.createdAt,
      created_at: m.createdAt,
      product_sku: m.product?.sku || '—',
      product_name: m.product?.name || '—',
      warehouse_name: m.warehouse?.name || '—',
      to_warehouse_name: m.toWarehouse?.name || '',
      performed_by: performer?.display_name || performer?.name || 'Deleted User',
      performed_by_role: performer?.role || '',
    };
  });
}

module.exports = { getValuation, getInventoryAudit };
