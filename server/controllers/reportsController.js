const { Inventory, Product, Movement } = require('../models');
const {
  COLLECTIONS,
  leftJoin,
  formatUserDoc,
  formatProductLean,
} = require('../utils/lookupHelpers');
const { applyStockStatusToRow } = require('../utils/stockStatus');
const { formatPerformedByUser } = require('../utils/createdByDto');
const {
  CONDITION_AVAILABLE,
  CONDITION_DAMAGED,
  CONDITION_INSPECTION,
} = require('../constants/inventoryConditions');

const FAST_MOVING_DAYS = 90;
const AUDIT_TRAIL_LIMIT = 20;

function roundMoney(n) {
  return Math.round((Number(n) || 0) * 100) / 100;
}

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

  const [financialRows, warehouseRows, conditionRows, detailRows, fastMoving, auditRows] =
    await Promise.all([
      aggregateFinancialSummary(),
      aggregateWarehouseComparison(),
      aggregateConditionBreakdown(),
      aggregateInventoryDetail(),
      aggregateFastMoving(),
      aggregateAuditTrail(),
    ]);

  const financial = financialRows[0] || {
    totalUnits: 0,
    costValue: 0,
    retailValue: 0,
    lineCount: 0,
  };

  const costValue = roundMoney(financial.costValue);
  const retailValue = roundMoney(financial.retailValue);
  const estimatedProfit = roundMoney(retailValue - costValue);

  const productCount = await Product.countDocuments();

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

  const conditionTotal =
    conditionRows.available_qty +
    conditionRows.damaged_qty +
    conditionRows.inspection_qty;

  const conditionBreakdown = {
    available_qty: conditionRows.available_qty,
    damaged_qty: conditionRows.damaged_qty,
    inspection_qty: conditionRows.inspection_qty,
    total_qty: conditionTotal,
    available_pct: conditionTotal
      ? roundMoney((conditionRows.available_qty / conditionTotal) * 100)
      : 0,
    damaged_pct: conditionTotal
      ? roundMoney((conditionRows.damaged_qty / conditionTotal) * 100)
      : 0,
    inspection_pct: conditionTotal
      ? roundMoney((conditionRows.inspection_qty / conditionTotal) * 100)
      : 0,
  };

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
      cost_value: costValue,
      retail_value: retailValue,
      total_units: financial.totalUnits,
      estimated_profit: estimatedProfit,
      inventory_lines: financial.lineCount,
      product_count: productCount,
    },
    warehouse_comparison: warehouseRows,
    condition_breakdown: conditionBreakdown,
    inventory_detail: detailRows,
    low_stock_alerts: lowStockAlerts,
    fast_moving_products: fastMoving,
    audit_trail: auditRows,
  };
}

async function aggregateFinancialSummary() {
  return Inventory.aggregate([
    {
      $lookup: {
        from: COLLECTIONS.products,
        localField: 'productId',
        foreignField: '_id',
        as: 'product',
      },
    },
    { $unwind: { path: '$product', preserveNullAndEmptyArrays: false } },
    {
      $group: {
        _id: null,
        totalUnits: { $sum: '$quantity' },
        costValue: { $sum: { $multiply: ['$quantity', '$product.unitCost'] } },
        retailValue: { $sum: { $multiply: ['$quantity', '$product.unitPrice'] } },
        lineCount: { $sum: 1 },
      },
    },
  ]);
}

async function aggregateWarehouseComparison() {
  const rows = await Inventory.aggregate([
    {
      $lookup: {
        from: COLLECTIONS.products,
        localField: 'productId',
        foreignField: '_id',
        as: 'product',
      },
    },
    { $unwind: { path: '$product', preserveNullAndEmptyArrays: false } },
    ...leftJoin('warehouseId', COLLECTIONS.warehouses, 'warehouse'),
    {
      $group: {
        _id: '$warehouseId',
        warehouse_name: { $first: '$warehouse.name' },
        total_units: { $sum: '$quantity' },
        cost_value: { $sum: { $multiply: ['$quantity', '$product.unitCost'] } },
        retail_value: { $sum: { $multiply: ['$quantity', '$product.unitPrice'] } },
      },
    },
    { $sort: { warehouse_name: 1 } },
  ]);

  return rows.map((r) => ({
    warehouse_id: r._id?.toString(),
    warehouse_name: r.warehouse_name || 'Unknown',
    total_units: r.total_units ?? 0,
    cost_value: roundMoney(r.cost_value),
    retail_value: roundMoney(r.retail_value),
  }));
}

async function aggregateConditionBreakdown() {
  const rows = await Inventory.aggregate([
    {
      $group: {
        _id: '$condition',
        qty: { $sum: '$quantity' },
      },
    },
  ]);

  let available_qty = 0;
  let damaged_qty = 0;
  let inspection_qty = 0;

  for (const row of rows) {
    const c = String(row._id || '');
    if (c === CONDITION_AVAILABLE) available_qty = row.qty ?? 0;
    else if (c === CONDITION_DAMAGED) damaged_qty = row.qty ?? 0;
    else if (c === CONDITION_INSPECTION) inspection_qty = row.qty ?? 0;
    else available_qty += row.qty ?? 0;
  }

  return { available_qty, damaged_qty, inspection_qty };
}

async function aggregateInventoryDetail() {
  const raw = await Inventory.aggregate([
    {
      $group: {
        _id: { productId: '$productId', warehouseId: '$warehouseId' },
        current_quantity: { $sum: '$quantity' },
        good_qty: {
          $sum: {
            $cond: [{ $eq: ['$condition', CONDITION_AVAILABLE] }, '$quantity', 0],
          },
        },
        damaged_qty: {
          $sum: {
            $cond: [{ $eq: ['$condition', CONDITION_DAMAGED] }, '$quantity', 0],
          },
        },
        inspection_qty: {
          $sum: {
            $cond: [{ $eq: ['$condition', CONDITION_INSPECTION] }, '$quantity', 0],
          },
        },
      },
    },
    ...leftJoin('_id.productId', COLLECTIONS.products, 'product'),
    ...leftJoin('_id.warehouseId', COLLECTIONS.warehouses, 'warehouse'),
    {
      $lookup: {
        from: COLLECTIONS.categories,
        localField: 'product.categoryId',
        foreignField: '_id',
        as: 'category',
      },
    },
    { $unwind: { path: '$category', preserveNullAndEmptyArrays: true } },
    { $sort: { 'product.sku': 1, 'warehouse.name': 1 } },
  ]);

  return raw.map((row) => {
    const product = row.product
      ? formatProductLean({ ...row.product, category: row.category })
      : null;
    const qty = row.current_quantity ?? 0;
    const unitCost = product?.unit_cost ?? 0;
    const unitPrice = product?.unit_price ?? 0;
    const minThreshold = product?.min_stock_threshold ?? 0;

    return applyStockStatusToRow({
      id: `${row._id.productId}_${row._id.warehouseId}`,
      sku: product?.sku || '—',
      product_name: product?.name || '—',
      category: product?.category?.name || '—',
      warehouse_name: row.warehouse?.name || '—',
      warehouse_location: row.warehouse?.location || '',
      current_quantity: qty,
      good_qty: row.good_qty ?? 0,
      damaged_qty: row.damaged_qty ?? 0,
      inspection_qty: row.inspection_qty ?? 0,
      condition_summary: `Good: ${row.good_qty ?? 0} · Damaged: ${row.damaged_qty ?? 0} · Insp: ${row.inspection_qty ?? 0}`,
      unit_cost: roundMoney(unitCost),
      unit_price: roundMoney(unitPrice),
      line_cost_value: roundMoney(qty * unitCost),
      line_retail_value: roundMoney(qty * unitPrice),
      min_stock_threshold: minThreshold,
    });
  });
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
