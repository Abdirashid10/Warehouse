const { Inventory, Movement, Order, Warehouse } = require('../models');
const { ORDER_STATUSES } = require('../constants/orderStatus');
const { CREATED_BY_SELECT, formatCreatedBy } = require('../utils/createdByDto');
const { formatMovementResponse } = require('../utils/movementDto');
const { fetchInventoryTrackingRows } = require('../services/inventoryTrackingService');
const {
  summarizeInventoryFinancials,
  summarizeWarehouseTotals,
} = require('../utils/inventoryValuation');
const { utilizationPercent } = require('../services/warehouseInventoryStats');

/** YYYY-MM-DD in UTC — matches Mongo $dateToString default. */
function formatYmdUtc(d) {
  return d.toISOString().slice(0, 10);
}

function utcStartOfToday() {
  const d = new Date();
  d.setUTCHours(0, 0, 0, 0);
  return d;
}

function utcStartNDaysAgo(n) {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() - n);
  d.setUTCHours(0, 0, 0, 0);
  return d;
}

function localStartOfToday() {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
}

/**
 * Build 7-day movement trend from aggregation rows.
 * Maps RETURN → inbound bucket; TRANSFER gets its own bucket.
 */
function buildMovementTrend(aggRows) {
  const map = new Map();
  for (const row of aggRows) {
    const key = `${row._id.day}|${row._id.bucket}`;
    map.set(key, (map.get(key) || 0) + row.total);
  }

  const days = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setUTCDate(d.getUTCDate() - i);
    const label = formatYmdUtc(d);
    days.push({
      date: label,
      inbound: map.get(`${label}|inbound`) || 0,
      outbound: map.get(`${label}|outbound`) || 0,
      transfer: map.get(`${label}|transfer`) || 0,
    });
  }
  return days;
}

/**
 * Derive order-level stats from a single aggregation
 * so totalOrders always equals the sum of per-status counts.
 */
function buildOrderStats(statusAggRows) {
  const byStatus = {};
  for (const s of ORDER_STATUSES) byStatus[s] = 0;

  let total = 0;
  for (const row of statusAggRows) {
    if (row._id && byStatus.hasOwnProperty(row._id)) {
      byStatus[row._id] = row.count;
    }
    total += row.count;
  }

  return { totalOrders: total, ordersByStatus: byStatus };
}

async function getDashboardStats(_req, res) {
  try {
    const todayLocal = localStartOfToday();
    const tomorrowLocal = new Date(todayLocal);
    tomorrowLocal.setDate(tomorrowLocal.getDate() + 1);

    const trendStart = utcStartNDaysAgo(6);

    const [
      inventoryTracking,
      recentMovements,
      activeWarehouseIds,
      todayMovementsCount,
      trendAgg,
      ordersByStatusAgg,
      recentOrders,
      ordersCreatedTrendAgg,
    ] = await Promise.all([
      fetchInventoryTrackingRows(),

      Movement.find()
        .sort({ createdAt: -1 })
        .limit(10)
        .populate({
          path: 'productId',
          select: 'sku name categoryId',
          populate: { path: 'categoryId', select: 'name' },
        })
        .populate('warehouseId', 'name location')
        .populate('toWarehouseId', 'name location')
        .populate('userId', CREATED_BY_SELECT)
        .populate('createdBy', CREATED_BY_SELECT)
        .lean(),

      Inventory.distinct('warehouseId', { quantity: { $gt: 0 } }),

      Movement.countDocuments({
        createdAt: { $gte: todayLocal, $lt: tomorrowLocal },
      }),

      Movement.aggregate([
        {
          $match: {
            createdAt: { $gte: trendStart },
            type: { $in: ['INBOUND', 'OUTBOUND', 'RETURN', 'TRANSFER'] },
          },
        },
        {
          $addFields: {
            bucket: {
              $switch: {
                branches: [
                  { case: { $in: ['$type', ['INBOUND', 'RETURN']] }, then: 'inbound' },
                  { case: { $eq: ['$type', 'OUTBOUND'] }, then: 'outbound' },
                  { case: { $eq: ['$type', 'TRANSFER'] }, then: 'transfer' },
                ],
                default: 'other',
              },
            },
          },
        },
        {
          $group: {
            _id: {
              day: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
              bucket: '$bucket',
            },
            total: { $sum: '$quantity' },
          },
        },
      ]),

      Order.aggregate([{ $group: { _id: '$status', count: { $sum: 1 } } }]),

      Order.find()
        .sort({ updatedAt: -1 })
        .limit(5)
        .select('order_number customer_name status total_quantity grand_total updatedAt createdAt')
        .lean(),

      Order.aggregate([
        { $match: { createdAt: { $gte: trendStart } } },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
            count: { $sum: 1 },
          },
        },
      ]),
    ]);

    /* Same rows, same helper as /reports/inventory-audit → identical figures. */
    const financials = summarizeInventoryFinancials(inventoryTracking.rows);
    const totalStockValue = financials.cost_value;

    const inventorySummary = inventoryTracking.summary;
    const lowStockLineCount = inventorySummary.low_stock ?? 0;
    const outOfStockLineCount = inventorySummary.out_of_stock ?? 0;
    const inStockLineCount = inventorySummary.in_stock ?? 0;
    const totalUnitsOnHand = inventorySummary.total_units ?? 0;

    const seen = new Set();
    const activityFeed = [];
    for (const m of recentMovements) {
      const mid = m._id.toString();
      if (seen.has(mid)) continue;
      seen.add(mid);
      activityFeed.push(
        formatMovementResponse({
          id: mid,
          _id: mid,
          type: m.type,
          quantity: m.quantity,
          delta: m.delta,
          reason: m.reason,
          timestamp: m.timestamp,
          createdAt: m.createdAt,
          source_location: m.source_location ?? '',
          destination_location: m.destination_location ?? '',
          product: m.productId,
          warehouse: m.warehouseId,
          toWarehouse: m.toWarehouseId || null,
          user: m.userId,
          created_by: formatCreatedBy(m),
        })
      );
      if (activityFeed.length >= 8) break;
    }

    const activeWarehousesCount = activeWarehouseIds.filter(Boolean).length;
    const movementTrend = buildMovementTrend(trendAgg);

    const { totalOrders, ordersByStatus } = buildOrderStats(ordersByStatusAgg);

    const ordersCreatedMap = new Map(ordersCreatedTrendAgg.map((r) => [r._id, r.count]));
    const orderTrend = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setUTCDate(d.getUTCDate() - i);
      const label = formatYmdUtc(d);
      orderTrend.push({ date: label, orders: ordersCreatedMap.get(label) || 0 });
    }

    const uniqueOrders = [];
    const seenOrders = new Set();
    for (const o of recentOrders) {
      const oid = o._id.toString();
      if (seenOrders.has(oid)) continue;
      seenOrders.add(oid);
      uniqueOrders.push(o);
    }

    return res.json({
      totalStockValue,
      lowStockLineCount,
      lowStockProductCount: lowStockLineCount,
      outOfStockLineCount,
      inStockLineCount,
      totalUnitsOnHand,
      inventorySummary,
      activeWarehousesCount,
      todayMovementsCount,
      movementTrend,
      activityFeed,
      totalOrders,
      ordersByStatus,
      recentOrders: uniqueOrders,
      orderTrend,
    });
  } catch (err) {
    console.error('getDashboardStats error:', err.message);
    return res.status(500).json({ message: 'Failed to load dashboard stats' });
  }
}

/**
 * Operational widgets: alerts, warehouse performance, task summary, smart insights.
 * Separate endpoint to keep /stats fast and allow independent polling.
 */
async function getDashboardWidgets(req, res) {
  try {
    const Task = require('../models/Task');
    const { listTasksForUser } = require('../services/taskService');
    const { formatTask } = require('../utils/taskDto');
    const { summarizeTaskStats, isTaskOverdue, workflowBucket, toDashboardTaskSummary } = require('../utils/taskStats');

    const [
      inventoryTracking,
      allTaskRows,
      warehouseDocs,
      pendingOrderCount,
      recentTasks,
    ] = await Promise.all([
      fetchInventoryTrackingRows(),

      listTasksForUser(req.user, {}),

      Warehouse.find().select('name location capacity').lean(),

      Order.countDocuments({ status: 'Pending' }),

      (async () => {
        const recentQuery = req.user.role === 'Staff' ? { assignedToId: req.user.id } : {};
        return Task.find(recentQuery)
          .sort({ createdAt: -1 })
          .limit(5)
          .select('title taskType priority status statusHistory dueDate assignedToId warehouseId')
          .populate('assignedToId', 'username')
          .populate('warehouseId', 'name')
          .lean();
      })(),
    ]);

    const formattedTasks = allTaskRows.map(formatTask);
    const stats = summarizeTaskStats(formattedTasks);
    const taskSummary = {
      ...toDashboardTaskSummary(stats),
      recentTasks: recentTasks.map((t) => ({
        id: t._id,
        title: t.title,
        type: t.taskType,
        priority: t.priority,
        status: workflowBucket({ status: t.status, statusHistory: t.statusHistory }),
        isOverdue: isTaskOverdue({ status: t.status, dueDate: t.dueDate, statusHistory: t.statusHistory }),
        dueDate: t.dueDate,
        assignee: t.assignedToId?.username || '—',
        warehouse: t.warehouseId?.name || '—',
      })),
    };

    const highPriorityPendingTasks = formattedTasks.filter((t) => {
      const bucket = workflowBucket(t);
      return ['Pending', 'Accepted', 'In Progress', 'Waiting Confirmation'].includes(bucket)
        && ['high', 'critical'].includes(t.priority);
    }).length;

    const overdueTaskCount = stats.overdue;

    /* ── Alerts ── */
    const rows = inventoryTracking.rows || [];
    const lowStockItems = rows
      .filter((r) => r.stock_status === 'Low Stock')
      .slice(0, 5)
      .map((r) => ({
        product: r.product?.name || '—',
        sku: r.product?.sku || '—',
        warehouse: r.warehouse?.name || '—',
        quantity: r.current_quantity,
        threshold: r.min_stock_threshold,
      }));

    const outOfStockItems = rows
      .filter((r) => r.stock_status === 'Out of Stock')
      .slice(0, 5)
      .map((r) => ({
        product: r.product?.name || '—',
        sku: r.product?.sku || '—',
        warehouse: r.warehouse?.name || '—',
      }));

    /* ── Expiry alerts ── */
    const expirySummary = inventoryTracking.expiry_summary || {};
    const expiredItems = rows
      .filter((r) => r.expiry_status === 'Expired')
      .slice(0, 5)
      .map((r) => ({
        product: r.product?.name || '—',
        sku: r.product?.sku || '—',
        warehouse: r.warehouse?.name || '—',
        batch: r.batch_number || '—',
        expiryDate: r.expiry_date,
        quantity: r.current_quantity,
      }));

    const expiringSoonItems = rows
      .filter((r) => r.expiry_status === 'Expiring Soon')
      .slice(0, 5)
      .map((r) => ({
        product: r.product?.name || '—',
        sku: r.product?.sku || '—',
        warehouse: r.warehouse?.name || '—',
        batch: r.batch_number || '—',
        expiryDate: r.expiry_date,
        daysLeft: r.days_until_expiry,
        quantity: r.current_quantity,
      }));

    const alerts = {
      lowStockCount: inventoryTracking.summary.low_stock ?? 0,
      outOfStockCount: inventoryTracking.summary.out_of_stock ?? 0,
      pendingOrderCount,
      overdueTaskCount,
      highPriorityTasks: highPriorityPendingTasks,
      lowStockItems,
      outOfStockItems,
      expiredCount: expirySummary.expired ?? 0,
      expiringSoonCount: expirySummary.expiring_soon ?? 0,
      expiring30dCount: expirySummary.expiring_30d ?? 0,
      safeExpiryCount: expirySummary.safe ?? 0,
      expiredItems,
      expiringSoonItems,
    };

    /* ── Warehouse performance ──
       Rolled up from the same tracking rows as the KPIs and the audit report,
       so per-warehouse units always sum to totalUnitsOnHand. */
    const capacityById = new Map(
      warehouseDocs.map((w) => [w._id.toString(), w])
    );

    const warehouseStats = summarizeWarehouseTotals(rows)
      .sort((a, b) => b.total_units - a.total_units)
      .slice(0, 5)
      .map((w) => {
        const doc = capacityById.get(w.warehouse_id) || {};
        const capacity = doc.capacity || 0;
        return {
          id: w.warehouse_id,
          name: doc.name || w.warehouse_name,
          location: doc.location || w.warehouse_location,
          capacity,
          totalUnits: w.total_units,
          lineCount: w.line_count,
          utilization: utilizationPercent(w.total_units, capacity),
        };
      });

    /* ── Smart insights ── */
    const insights = [];

    if (warehouseStats.length > 0) {
      insights.push({
        type: 'warehouse',
        icon: 'warehouse',
        message: `${warehouseStats[0].name} holds the most inventory with ${warehouseStats[0].totalUnits.toLocaleString()} units`,
        severity: 'info',
      });
    }

    if (alerts.outOfStockCount > 0) {
      insights.push({
        type: 'inventory',
        icon: 'alert',
        message: `${alerts.outOfStockCount} product${alerts.outOfStockCount > 1 ? 's are' : ' is'} out of stock and need${alerts.outOfStockCount === 1 ? 's' : ''} urgent restocking`,
        severity: 'critical',
      });
    }

    if (alerts.lowStockCount > 0) {
      insights.push({
        type: 'inventory',
        icon: 'warning',
        message: `${alerts.lowStockCount} inventory line${alerts.lowStockCount > 1 ? 's are' : ' is'} running low — consider reordering`,
        severity: 'warning',
      });
    }

    if (taskSummary.overdue > 0) {
      insights.push({
        type: 'tasks',
        icon: 'overdue',
        message: `${taskSummary.overdue} task${taskSummary.overdue > 1 ? 's are' : ' is'} overdue — action required`,
        severity: 'critical',
      });
    }

    if (pendingOrderCount > 0) {
      insights.push({
        type: 'orders',
        icon: 'orders',
        message: `${pendingOrderCount} order${pendingOrderCount > 1 ? 's' : ''} pending processing`,
        severity: pendingOrderCount > 5 ? 'warning' : 'info',
      });
    }

    if (alerts.expiredCount > 0) {
      insights.push({
        type: 'expiry',
        icon: 'expired',
        message: `${alerts.expiredCount} product${alerts.expiredCount > 1 ? 's have' : ' has'} expired — remove from inventory immediately`,
        severity: 'critical',
      });
    }

    if (alerts.expiringSoonCount > 0) {
      insights.push({
        type: 'expiry',
        icon: 'expiring',
        message: `${alerts.expiringSoonCount} product${alerts.expiringSoonCount > 1 ? 's are' : ' is'} expiring within 7 days — take action`,
        severity: 'warning',
      });
    }

    const highUtilWh = warehouseStats.find((w) => w.utilization >= 85);
    if (highUtilWh) {
      insights.push({
        type: 'warehouse',
        icon: 'capacity',
        message: `${highUtilWh.name} is at ${highUtilWh.utilization}% capacity — consider redistribution`,
        severity: 'warning',
      });
    }

    if (taskSummary.inProgress > 0) {
      insights.push({
        type: 'tasks',
        icon: 'tasks',
        message: `${taskSummary.inProgress} task${taskSummary.inProgress > 1 ? 's' : ''} currently in progress`,
        severity: 'info',
      });
    }

    return res.json({ alerts, taskSummary, warehouseStats, insights, expirySummary: expirySummary });
  } catch (err) {
    console.error('getDashboardWidgets error:', err.message);
    return res.status(500).json({ message: 'Failed to load dashboard widgets' });
  }
}

module.exports = { getDashboardStats, getDashboardWidgets };
