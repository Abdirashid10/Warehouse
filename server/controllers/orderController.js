const mongoose = require('mongoose');
const { Order, Product, Warehouse, Inventory } = require('../models');
const { ORDER_STATUSES, isValidStatusTransition, getNextStatus } = require('../constants/orderStatus');
const { generateOrderNumber } = require('../utils/orderNumber');
const { formatOrder, minuteTimestamp, ORDER_POPULATE } = require('../utils/orderDto');
const { recordMovement } = require('../utils/movementService');
const { formatOutboundReason } = require('../utils/outboundReason');
const { CONDITION_AVAILABLE } = require('../constants/inventoryConditions');
const { logAudit } = require('../utils/activityLogger');
const {
  notifyOrderCreated,
  notifyOrderStatusChange,
  notifyOrderCancelled,
  afterOrderStockChange,
} = require('../services/notificationService');
const { emitInventoryChanged } = require('../realtime/inventoryEmitter');

function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(id);
}

async function validateItems(items) {
  if (!Array.isArray(items) || items.length === 0) {
    throw Object.assign(new Error('At least one line item is required'), { status: 400 });
  }
  const normalized = [];
  const requestedByKey = new Map();
  const availableByKey = new Map();
  for (const row of items) {
    const productId = row.product_id || row.productId;
    const warehouseId = row.warehouse_id || row.warehouseId;
    const qty = Number(row.quantity);
    if (!productId || !warehouseId) {
      throw Object.assign(new Error('Each item needs product_id and warehouse_id'), { status: 400 });
    }
    if (!isValidObjectId(productId) || !isValidObjectId(warehouseId)) {
      throw Object.assign(new Error('Invalid product_id or warehouse_id in items'), { status: 400 });
    }
    if (!Number.isFinite(qty) || qty < 1 || !Number.isInteger(qty)) {
      throw Object.assign(new Error('Item quantity must be a positive integer'), { status: 400 });
    }
    const [product, warehouse] = await Promise.all([
      Product.findById(productId).select('_id sku name unitPrice'),
      Warehouse.findById(warehouseId).select('_id name'),
    ]);
    if (!product) {
      throw Object.assign(new Error(`Product not found: ${productId}`), { status: 400 });
    }
    if (!warehouse) {
      throw Object.assign(new Error(`Warehouse not found: ${warehouseId}`), { status: 400 });
    }
    const stockLine = await Inventory.findOne({
      productId: product._id,
      warehouseId: warehouse._id,
      condition: CONDITION_AVAILABLE,
    })
      .select('quantity')
      .lean();
    const availableQty = Number(stockLine?.quantity || 0);
    const key = `${product._id.toString()}::${warehouse._id.toString()}`;
    requestedByKey.set(key, (requestedByKey.get(key) || 0) + qty);
    availableByKey.set(key, {
      availableQty,
      sku: product.sku,
      warehouseName: warehouse.name,
    });

    const unitPrice = Number(product.unitPrice || 0);
    normalized.push({
      product_id: product._id,
      warehouse_id: warehouse._id,
      quantity: qty,
      unit_price: unitPrice,
      line_total: qty * unitPrice,
    });
  }
  for (const [key, requestedQty] of requestedByKey.entries()) {
    const meta = availableByKey.get(key);
    if (requestedQty > (meta?.availableQty || 0)) {
      throw Object.assign(
        new Error(
          `Insufficient available stock for ${meta?.sku || 'product'} in ${
            meta?.warehouseName || 'warehouse'
          } (available: ${meta?.availableQty || 0})`
        ),
        { status: 400, code: 'INSUFFICIENT_STOCK' }
      );
    }
  }
  return normalized;
}

function computeOrderTotals(items) {
  const total_items = items.length;
  const total_quantity = items.reduce((sum, item) => sum + (item.quantity || 0), 0);
  const grand_total = items.reduce((sum, item) => sum + (item.line_total || 0), 0);
  return { total_items, total_quantity, grand_total };
}

async function reserveOrderStock(order, userId) {
  for (const line of order.items) {
    const reason = formatOutboundReason(order.order_number, `Reserved for ${order.customer_name}`);
    await recordMovement({
      productId: line.product_id,
      warehouseId: line.warehouse_id,
      userId,
      type: 'OUTBOUND',
      quantity: line.quantity,
      reason,
      condition: CONDITION_AVAILABLE,
      destination_location: order.customer_name,
    });
  }
}

async function releaseOrderStock(order, userId) {
  for (const line of order.items) {
    const reason = `Release reserved stock for ${order.order_number}`;
    await recordMovement({
      productId: line.product_id,
      warehouseId: line.warehouse_id,
      userId,
      type: 'INBOUND',
      quantity: line.quantity,
      reason,
      condition: CONDITION_AVAILABLE,
      source_location: 'Reservation Release',
      destination_location: line.warehouse_id?.name || '',
    });
  }
}

async function getNextOrderNumber(_req, res) {
  try {
    const order_number = await generateOrderNumber();
    return res.json({ order_number });
  } catch (err) {
    console.error('getNextOrderNumber error:', err.message);
    return res.status(500).json({ message: 'Failed to generate order number' });
  }
}

async function listOrders(req, res) {
  try {
    const status = req.query.status;
    const searchQ = String(req.query.q || req.query.search || '').trim();
    const filter = {};
    const isStaff = req.user?.role === 'Staff';

    if (isStaff) {
      filter.status = { $in: ['Processing', 'Packed', 'Shipped'] };
      if (status && ['Processing', 'Packed', 'Shipped'].includes(status)) {
        filter.status = status;
      }
    } else if (status && ORDER_STATUSES.includes(status)) {
      filter.status = status;
    }

    let orders = await Order.find(filter)
      .sort({ createdAt: -1 })
      .populate('items.product_id', 'sku name')
      .populate('items.warehouse_id', 'name')
      .lean();

    if (searchQ) {
      const { orderNumberMatchesSearch } = require('../utils/orderNumber');
      const qLower = searchQ.toLowerCase();
      orders = orders.filter(
        (o) =>
          orderNumberMatchesSearch(o.order_number, searchQ) ||
          (o.customer_name || '').toLowerCase().includes(qLower) ||
          (o.delivery_address || '').toLowerCase().includes(qLower) ||
          (o.status || '').toLowerCase().includes(qLower)
      );
    }

    return res.json({
      orders: orders.map(formatOrder),
      counts: { total: orders.length },
    });
  } catch (err) {
    console.error('listOrders error:', err.message);
    return res.status(500).json({ message: 'Failed to load orders' });
  }
}

async function getOrder(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid order id' });
    }

    const order = await Order.findById(id).populate(ORDER_POPULATE).lean();
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    return res.json({ order: formatOrder(order) });
  } catch (err) {
    console.error('getOrder error:', err.message);
    return res.status(500).json({ message: 'Failed to load order' });
  }
}

async function createOrder(req, res) {
  try {
    const {
      customer_name,
      phone_number,
      delivery_address,
      priority,
      expected_delivery_date,
      notes,
      items,
    } = req.body;
    if (!customer_name || typeof customer_name !== 'string' || !customer_name.trim()) {
      return res.status(400).json({ message: 'customer_name is required' });
    }
    if (!delivery_address || !String(delivery_address).trim()) {
      return res.status(400).json({ message: 'delivery_address is required' });
    }

    const normalizedItems = await validateItems(items);
    const totals = computeOrderTotals(normalizedItems);
    const order_number = await generateOrderNumber();
    const now = minuteTimestamp();

    const order = await Order.create({
      order_number,
      customer_name: customer_name.trim(),
      phone_number: String(phone_number || '').trim(),
      delivery_address: String(delivery_address || '').trim(),
      notes: String(notes || '').trim(),
      priority: ['Normal', 'Urgent', 'High Priority'].includes(priority) ? priority : 'Normal',
      expected_delivery_date: expected_delivery_date ? new Date(expected_delivery_date) : null,
      items: normalizedItems,
      ...totals,
      status: 'Pending',
      status_history: [
        {
          status: 'Pending',
          changed_at: now,
          changed_by: req.user.id,
        },
      ],
      createdBy: req.user.id,
    });
    try {
      await reserveOrderStock(order, req.user.id);
    } catch (reserveErr) {
      await Order.findByIdAndDelete(order._id);
      throw reserveErr;
    }

    const populated = await Order.findById(order._id).populate(ORDER_POPULATE).lean();
    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      action: 'Create',
      module: 'Orders',
      entityType: 'order',
      entityId: order._id.toString(),
      entityLabel: order.order_number,
      afterValue: { status: 'Pending', customer: order.customer_name },
      details: `Order ${order.order_number} created for ${order.customer_name}`,
    });
    await notifyOrderCreated({ order: populated, actorId: req.user.id });
    await afterOrderStockChange(order, req.user.id);
    emitInventoryChanged({ type: 'ORDER_RESERVE', orderId: order._id?.toString() });
    return res.status(201).json({ order: formatOrder(populated) });
  } catch (err) {
    const status = err.status || 500;
    if (status !== 500) {
      return res.status(status).json({ message: err.message });
    }
    console.error('createOrder error:', err.message);
    return res.status(500).json({ message: 'Failed to create order' });
  }
}

async function updateOrder(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid order id' });
    }

    const order = await Order.findById(id);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    if (order.status !== 'Pending') {
      return res.status(400).json({
        message: 'Only Pending orders can be edited. Update status instead.',
      });
    }

    const { customer_name, phone_number, delivery_address, priority, expected_delivery_date, notes, items } =
      req.body;
    if (customer_name != null) {
      if (typeof customer_name !== 'string' || !customer_name.trim()) {
        return res.status(400).json({ message: 'customer_name cannot be empty' });
      }
      order.customer_name = customer_name.trim();
    }
    if (delivery_address != null) {
      if (!String(delivery_address).trim()) {
        return res.status(400).json({ message: 'delivery_address cannot be empty' });
      }
      order.delivery_address = String(delivery_address).trim();
    }
    if (phone_number != null) order.phone_number = String(phone_number).trim();
    if (notes != null) order.notes = String(notes).trim();
    if (priority != null) {
      if (!['Normal', 'Urgent', 'High Priority'].includes(priority)) {
        return res.status(400).json({ message: 'Invalid priority value' });
      }
      order.priority = priority;
    }
    if (expected_delivery_date != null) {
      order.expected_delivery_date = expected_delivery_date ? new Date(expected_delivery_date) : null;
    }
    if (items != null) {
      await releaseOrderStock(order, req.user.id);
      order.items = await validateItems(items);
      await reserveOrderStock(order, req.user.id);
      Object.assign(order, computeOrderTotals(order.items));
    }
    await order.save();

    const populated = await Order.findById(order._id).populate(ORDER_POPULATE).lean();
    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      action: 'Update',
      module: 'Orders',
      entityType: 'order',
      entityId: order._id.toString(),
      entityLabel: order.order_number,
      afterValue: { customer: order.customer_name, priority: order.priority },
      details: `Order ${order.order_number} updated`,
    });
    return res.json({ order: formatOrder(populated) });
  } catch (err) {
    const status = err.status || 500;
    if (status !== 500) {
      return res.status(status).json({ message: err.message });
    }
    console.error('updateOrder error:', err.message);
    return res.status(500).json({ message: 'Failed to update order' });
  }
}

async function deleteOrder(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid order id' });
    }

    const order = await Order.findById(id);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    if (order.status !== 'Pending') {
      return res.status(400).json({
        message: 'Only Pending orders can be deleted',
      });
    }

    await releaseOrderStock(order, req.user.id);
    const orderSnapshot = order.toObject();
    await Order.findByIdAndDelete(id);

    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      action: 'Delete',
      module: 'Orders',
      entityType: 'order',
      entityId: id,
      entityLabel: orderSnapshot.order_number,
      beforeValue: { status: orderSnapshot.status, customer: orderSnapshot.customer_name },
      details: `Order ${orderSnapshot.order_number} cancelled/deleted`,
    });
    await notifyOrderCancelled({ order: orderSnapshot, actorId: req.user.id });

    return res.json({ message: 'Order deleted' });
  } catch (err) {
    console.error('deleteOrder error:', err.message);
    return res.status(500).json({ message: 'Failed to delete order' });
  }
}

async function updateOrderStatus(req, res) {
  try {
    const { id } = req.params;
    const { status: newStatus } = req.body;

    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid order id' });
    }
    if (!newStatus || !ORDER_STATUSES.includes(newStatus)) {
      return res.status(400).json({
        message: `status must be one of: ${ORDER_STATUSES.join(', ')}`,
      });
    }

    const order = await Order.findById(id);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    if (order.status === newStatus) {
      return res.status(400).json({ message: 'Order is already in this status' });
    }

    if (!isValidStatusTransition(order.status, newStatus)) {
      const next = getNextStatus(order.status);
      return res.status(400).json({
        message: next
          ? `Invalid transition. Next allowed status: ${next}`
          : 'Order is already at the final status',
      });
    }

    const STAFF_ALLOWED_TARGETS = ['Processing', 'Packed', 'Shipped'];
    if (req.user?.role === 'Staff') {
      if (!STAFF_ALLOWED_TARGETS.includes(newStatus)) {
        return res.status(403).json({
          message: 'Staff can only advance orders to Processing, Packed, or Shipped',
        });
      }
    }

    const previousStatus = order.status;

    if (newStatus === 'Shipped' && order.status !== 'Shipped' && !order.shipped_at) {
      order.shipped_at = new Date();
    }

    order.status = newStatus;
    order.status_history.push({
      status: newStatus,
      changed_at: minuteTimestamp(),
      changed_by: req.user.id,
    });
    await order.save();

    const populated = await Order.findById(order._id).populate(ORDER_POPULATE).lean();
    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      action: 'Status Change',
      module: 'Orders',
      entityType: 'order',
      entityId: order._id.toString(),
      entityLabel: order.order_number,
      beforeValue: { status: previousStatus },
      afterValue: { status: newStatus },
      details: `Order ${order.order_number}: ${previousStatus} → ${newStatus}`,
    });
    await notifyOrderStatusChange({
      order: populated,
      previousStatus,
      newStatus,
      actorId: req.user.id,
    });
    await afterOrderStockChange(order, req.user.id);
    emitInventoryChanged({ type: 'ORDER_STATUS', orderId: order._id?.toString(), status: newStatus });
    return res.json({
      order: formatOrder(populated),
      message: `Order status updated to ${newStatus}`,
    });
  } catch (err) {
    const status = err.status || 500;
    if (status !== 500) {
      return res.status(status).json({ message: err.message });
    }
    console.error('updateOrderStatus error:', err.message);
    return res.status(500).json({ message: 'Failed to update order status' });
  }
}

module.exports = {
  getNextOrderNumber,
  listOrders,
  getOrder,
  createOrder,
  updateOrder,
  deleteOrder,
  updateOrderStatus,
};
