const mongoose = require('mongoose');
const { User, Notification, Inventory, Product, Warehouse } = require('../models');
const { getStockStatus } = require('../utils/stockStatus');
const { getExpiryStatus, daysUntilExpiry } = require('../utils/expiryStatus');
const {
  ALERT_RECIPIENT_ROLES,
  ADMIN_ALERT_ROLES,
} = require('../constants/notifications');
const { CONDITION_DAMAGED } = require('../constants/inventoryConditions');

const CAPACITY_WARNING_RATIO = 0.9;

function formatNotification(doc, createdByUser = null) {
  if (!doc) return null;
  const row = doc.toObject ? doc.toObject() : doc;
  const creator = createdByUser || row.createdBy;
  return {
    id: row._id?.toString(),
    title: row.title,
    message: row.message,
    type: row.type,
    priority: row.priority,
    category: row.category,
    read: Boolean(row.read),
    readAt: row.readAt || null,
    relatedEntityId: row.relatedEntityId || '',
    relatedEntityType: row.relatedEntityType || '',
    href: row.href || '',
    createdBy: row.createdBy?.toString?.() || row.createdBy || null,
    createdByUser: creator && typeof creator === 'object'
      ? {
          id: creator._id?.toString(),
          username: creator.username,
          role: creator.role,
          fullName: creator.fullName || '',
        }
      : null,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

async function getActiveUsersByRoles(roles) {
  return User.find({
    role: { $in: roles },
    archived: { $ne: true },
    status: 'Active',
  })
    .select('_id role username')
    .lean();
}

/**
 * Create or refresh a single notification for one recipient.
 * When dedupeKey is set, updates an existing unread notification instead of duplicating.
 */
async function createNotification({
  recipientId,
  title,
  message,
  type = 'info',
  priority = 'medium',
  category = 'system',
  relatedEntityId = '',
  relatedEntityType = '',
  createdBy = null,
  href = '',
  dedupeKey = null,
}) {
  if (!recipientId || !title || !message) return null;

  try {
    if (dedupeKey) {
      const existing = await Notification.findOne({
        recipientId,
        dedupeKey,
        read: false,
      });
      if (existing) {
        existing.title = String(title).trim();
        existing.message = String(message).trim();
        existing.type = type;
        existing.priority = priority;
        existing.category = category;
        existing.relatedEntityId = String(relatedEntityId || '');
        existing.relatedEntityType = String(relatedEntityType || '');
        existing.href = String(href || '');
        if (createdBy) existing.createdBy = createdBy;
        await existing.save();
        await emitRealtime(existing);
        return existing;
      }
    }

    const created = await Notification.create({
      recipientId,
      title: String(title).trim(),
      message: String(message).trim(),
      type,
      priority,
      category,
      relatedEntityId: String(relatedEntityId || ''),
      relatedEntityType: String(relatedEntityType || ''),
      href: String(href || ''),
      dedupeKey: dedupeKey || null,
      createdBy: createdBy || null,
      read: false,
      readAt: null,
    });
    await emitRealtime(created);
    return created;
  } catch (_err) {
    return null;
  }
}

async function emitRealtime(doc) {
  try {
    const { emitNotificationDoc } = require('../realtime/notificationEmitter');
    await emitNotificationDoc(doc);
  } catch (_err) {
    /* socket optional */
  }
}

async function notifyRoles({
  roles,
  title,
  message,
  type = 'info',
  priority = 'medium',
  category = 'system',
  relatedEntityId = '',
  relatedEntityType = '',
  createdBy = null,
  href = '',
  dedupeKey = null,
  excludeUserId = null,
}) {
  const users = await getActiveUsersByRoles(roles);
  const tasks = users
    .filter((user) => !excludeUserId || String(user._id) !== String(excludeUserId))
    .map((user) =>
      createNotification({
        recipientId: user._id,
        title,
        message,
        type,
        priority,
        category,
        relatedEntityId,
        relatedEntityType,
        createdBy,
        href,
        dedupeKey: dedupeKey ? `${dedupeKey}:${user._id}` : null,
      })
    );
  await Promise.all(tasks);
}

async function notifyUser(payload) {
  return createNotification(payload);
}

async function getLineStockContext(productId, warehouseId) {
  if (!mongoose.Types.ObjectId.isValid(productId) || !mongoose.Types.ObjectId.isValid(warehouseId)) {
    return null;
  }

  const [product, warehouse, qtyAgg] = await Promise.all([
    Product.findById(productId).select('sku name minStockThreshold').lean(),
    Warehouse.findById(warehouseId).select('name capacity').lean(),
    Inventory.aggregate([
      {
        $match: {
          productId: new mongoose.Types.ObjectId(productId),
          warehouseId: new mongoose.Types.ObjectId(warehouseId),
        },
      },
      { $group: { _id: null, total: { $sum: '$quantity' } } },
    ]),
  ]);

  if (!product || !warehouse) return null;

  const currentQuantity = qtyAgg[0]?.total ?? 0;
  const minThreshold = product.minStockThreshold ?? 0;
  const stockStatus = getStockStatus(currentQuantity, minThreshold);

  return {
    product,
    warehouse,
    currentQuantity,
    minThreshold,
    stockStatus,
  };
}

async function syncStockAlertsForLocation({ productId, warehouseId, actorId = null }) {
  const ctx = await getLineStockContext(productId, warehouseId);
  if (!ctx) return;

  const { product, warehouse, currentQuantity, minThreshold, stockStatus } = ctx;
  const lineId = `${productId}_${warehouseId}`;
  const productLabel = product.name || product.sku || 'Product';

  if (stockStatus === 'Low Stock') {
    await notifyRoles({
      roles: ALERT_RECIPIENT_ROLES,
      title: 'Low stock alert',
      message: `${productLabel} at ${warehouse.name} is below minimum threshold (${currentQuantity} on hand, min ${minThreshold}).`,
      type: 'warning',
      priority: 'high',
      category: 'inventory',
      relatedEntityId: lineId,
      relatedEntityType: 'inventory_line',
      createdBy: actorId,
      href: '/inventory-tracking',
      dedupeKey: `low-stock:${lineId}`,
    });
    return;
  }

  if (stockStatus === 'Out of Stock') {
    await notifyRoles({
      roles: ALERT_RECIPIENT_ROLES,
      title: 'Out of stock alert',
      message: `${productLabel} at ${warehouse.name} is out of stock.`,
      type: 'error',
      priority: 'critical',
      category: 'inventory',
      relatedEntityId: lineId,
      relatedEntityType: 'inventory_line',
      createdBy: actorId,
      href: '/inventory-tracking',
      dedupeKey: `out-of-stock:${lineId}`,
    });
  }
}

async function syncWarehouseCapacityAlert({ warehouseId, actorId = null }) {
  if (!mongoose.Types.ObjectId.isValid(warehouseId)) return;

  const warehouse = await Warehouse.findById(warehouseId).select('name capacity').lean();
  if (!warehouse || !warehouse.capacity) return;

  const usageAgg = await Inventory.aggregate([
    { $match: { warehouseId: new mongoose.Types.ObjectId(warehouseId) } },
    { $group: { _id: null, total: { $sum: '$quantity' } } },
  ]);
  const used = usageAgg[0]?.total ?? 0;
  const ratio = used / warehouse.capacity;

  if (ratio < CAPACITY_WARNING_RATIO) return;

  const pct = Math.round(ratio * 100);
  await notifyRoles({
    roles: ALERT_RECIPIENT_ROLES,
    title: 'Warehouse capacity warning',
    message: `${warehouse.name} is at ${pct}% capacity (${used} / ${warehouse.capacity} units).`,
    type: 'warning',
    priority: ratio >= 1 ? 'critical' : 'high',
    category: 'warehouse',
    relatedEntityId: warehouseId.toString(),
    relatedEntityType: 'warehouse',
    createdBy: actorId,
    href: '/warehouses',
    dedupeKey: `warehouse-capacity:${warehouseId}`,
  });
}

async function notifyInventoryMovement({
  type,
  quantity,
  product,
  warehouse,
  toWarehouse = null,
  condition,
  actorId,
  movementId,
}) {
  const sku = product?.sku || product?.name || 'Product';
  const warehouseName = warehouse?.name || 'warehouse';
  let title = 'Stock updated';
  let message = '';
  let notifType = 'info';
  let priority = 'medium';

  switch (type) {
    case 'INBOUND':
      title = 'Stock received';
      message = `${quantity} unit(s) of ${sku} received at ${warehouseName}.`;
      notifType = 'success';
      break;
    case 'OUTBOUND':
      title = 'Stock dispatched';
      message = `${quantity} unit(s) of ${sku} dispatched from ${warehouseName}.`;
      notifType = 'info';
      break;
    case 'ADJUSTMENT':
      title = 'Stock adjustment';
      message = `${sku} quantity was adjusted at ${warehouseName}.`;
      break;
    case 'TRANSFER':
      title = 'Stock transferred';
      message = `${quantity} unit(s) of ${sku} transferred from ${warehouseName} to ${toWarehouse?.name || 'destination warehouse'}.`;
      notifType = 'success';
      break;
    case 'RETURN':
      title = 'Stock returned';
      message = `${quantity} unit(s) of ${sku} returned to ${warehouseName}.`;
      notifType = 'success';
      break;
    default:
      message = `${type} movement recorded for ${sku} at ${warehouseName}.`;
  }

  if (condition === CONDITION_DAMAGED) {
    title = 'Damaged stock recorded';
    message = `${quantity} unit(s) of ${sku} marked as damaged at ${warehouseName}.`;
    notifType = 'warning';
    priority = 'high';
  }

  await notifyRoles({
    roles: ALERT_RECIPIENT_ROLES,
    title,
    message,
    type: notifType,
    priority,
    category: 'inventory',
    relatedEntityId: movementId?.toString() || '',
    relatedEntityType: 'movement',
    createdBy: actorId,
    href: '/stock-movements',
    dedupeKey: movementId ? `movement:${movementId}` : null,
    excludeUserId: actorId,
  });
}

async function notifyOrderCreated({ order, actorId }) {
  await notifyRoles({
    roles: ALERT_RECIPIENT_ROLES,
    title: 'New order created',
    message: `Order ${order.order_number} for ${order.customer_name} is pending fulfillment.`,
    type: 'info',
    priority: 'medium',
    category: 'order',
    relatedEntityId: order._id?.toString(),
    relatedEntityType: 'order',
    createdBy: actorId,
    href: `/orders/${order._id}`,
    dedupeKey: `order-created:${order._id}`,
    excludeUserId: actorId,
  });
}

async function notifyOrderStatusChange({ order, previousStatus, newStatus, actorId }) {
  const orderId = order._id?.toString();
  const orderNumber = order.order_number;
  let title = 'Order status changed';
  let message = `Order ${orderNumber} moved from ${previousStatus} to ${newStatus}.`;
  let notifType = 'info';
  let priority = 'medium';

  if (newStatus === 'Processing') {
    title = 'Order processing';
    message = `Order ${orderNumber} is now being processed.`;
  } else if (newStatus === 'Packed') {
    title = 'Order packed';
    message = `Order ${orderNumber} has been packed and is ready to ship.`;
    notifType = 'success';
    priority = 'high';
  } else if (newStatus === 'Shipped') {
    title = 'Order shipped';
    message = `Order ${orderNumber} has been shipped.`;
    notifType = 'success';
    priority = 'high';
  } else if (newStatus === 'Delivered') {
    title = 'Order delivered';
    message = `Order ${orderNumber} was delivered successfully.`;
    notifType = 'success';
    priority = 'high';
  }

  await notifyRoles({
    roles: ALERT_RECIPIENT_ROLES,
    title,
    message,
    type: notifType,
    priority,
    category: 'order',
    relatedEntityId: orderId,
    relatedEntityType: 'order',
    createdBy: actorId,
    href: `/orders/${orderId}`,
    dedupeKey: `order-status:${orderId}:${newStatus}`,
    excludeUserId: actorId,
  });
}

async function notifyOrderCancelled({ order, actorId }) {
  const orderId = order._id?.toString();
  const orderNumber = order.order_number;
  await notifyRoles({
    roles: ALERT_RECIPIENT_ROLES,
    title: 'Order cancelled',
    message: `Order ${orderNumber} for ${order.customer_name} was cancelled.`,
    type: 'warning',
    priority: 'high',
    category: 'order',
    relatedEntityId: orderId,
    relatedEntityType: 'order',
    createdBy: actorId,
    href: '/orders',
    dedupeKey: `order-cancelled:${orderId}`,
    excludeUserId: actorId,
  });
}

async function notifyUserStatusChanged({ targetUser, previousStatus, newStatus, actorId, actorName }) {
  const username = targetUser.username || targetUser.email || 'User';
  await notifyRoles({
    roles: ADMIN_ALERT_ROLES,
    title: 'User status changed',
    message: `${username} status changed from ${previousStatus} to ${newStatus} by ${actorName || 'Admin'}.`,
    type: 'warning',
    priority: 'high',
    category: 'user',
    relatedEntityId: targetUser._id?.toString() || targetUser.id,
    relatedEntityType: 'user',
    createdBy: actorId,
    href: '/users',
    dedupeKey: `user-status:${targetUser._id || targetUser.id}:${newStatus}`,
    excludeUserId: actorId,
  });

  const recipientId = targetUser._id?.toString() || targetUser.id;
  if (recipientId && newStatus !== 'Active') {
    await notifyUser({
      recipientId,
      title: 'Account status updated',
      message: `Your account status is now ${newStatus}. Contact an administrator if you need access restored.`,
      type: 'warning',
      priority: 'high',
      category: 'user',
      relatedEntityId: recipientId,
      relatedEntityType: 'user',
      createdBy: actorId,
      href: '/profile',
      dedupeKey: `user-status-self:${recipientId}:${newStatus}`,
    });
  }
}

async function notifyUserWarehouseAssigned({ user, warehouse, actorId, actorName }) {
  const userId = user._id?.toString() || user.id;
  const warehouseId = warehouse._id?.toString() || warehouse.id;
  const warehouseName = warehouse.name || 'Warehouse';

  await notifyUser({
    recipientId: userId,
    title: 'Warehouse assigned',
    message: `You have been assigned to ${warehouseName}.`,
    type: 'info',
    priority: 'medium',
    category: 'user',
    relatedEntityId: warehouseId,
    relatedEntityType: 'warehouse',
    createdBy: actorId,
    href: '/warehouses',
    dedupeKey: `user-warehouse:${userId}:${warehouseId}`,
  });

  await notifyRoles({
    roles: ADMIN_ALERT_ROLES,
    title: 'User assigned warehouse',
    message: `${user.username || user.email} was assigned to ${warehouseName} by ${actorName || 'Admin'}.`,
    type: 'info',
    priority: 'medium',
    category: 'user',
    relatedEntityId: userId,
    relatedEntityType: 'user',
    createdBy: actorId,
    href: '/users',
    dedupeKey: `user-warehouse-admin:${userId}:${warehouseId}`,
    excludeUserId: actorId,
  });
}

async function notifyWarehouseCreated({ warehouse, actorId, actorName }) {
  await notifyRoles({
    roles: ALERT_RECIPIENT_ROLES,
    title: 'New warehouse created',
    message: `${warehouse.name} (${warehouse.location}) was created by ${actorName || 'Admin'}.`,
    type: 'success',
    priority: 'medium',
    category: 'warehouse',
    relatedEntityId: warehouse._id?.toString(),
    relatedEntityType: 'warehouse',
    createdBy: actorId,
    href: '/warehouses',
    dedupeKey: `warehouse-created:${warehouse._id}`,
    excludeUserId: actorId,
  });
}

async function notifyUserLifecycle({
  action,
  targetUser,
  actorId,
  actorName,
}) {
  const username = targetUser.username || targetUser.email || 'User';
  let title = 'User updated';
  let message = `${username} account was updated.`;
  let notifType = 'info';
  let priority = 'medium';

  if (action === 'created') {
    title = 'New user added';
    message = `${username} was added as ${targetUser.role} by ${actorName || 'Admin'}.`;
    notifType = 'success';
  } else if (action === 'archived') {
    title = 'User archived';
    message = `${username} was archived and can no longer sign in.`;
    notifType = 'warning';
    priority = 'high';
  } else if (action === 'suspended') {
    title = 'User suspended';
    message = `${username} was suspended by ${actorName || 'Admin'}.`;
    notifType = 'warning';
    priority = 'high';
  } else if (action === 'deleted') {
    title = 'User removed';
    message = `${username} was removed from the system.`;
    notifType = 'error';
    priority = 'high';
  } else if (action === 'warehouse_assigned') {
    title = 'User assigned warehouse';
    message = `${username} was assigned to a warehouse by ${actorName || 'Admin'}.`;
    notifType = 'info';
  } else if (action === 'status_changed') {
    title = 'User status changed';
    message = `${username} account status was updated by ${actorName || 'Admin'}.`;
    notifType = 'warning';
    priority = 'high';
  }

  await notifyRoles({
    roles: ADMIN_ALERT_ROLES,
    title,
    message,
    type: notifType,
    priority,
    category: 'user',
    relatedEntityId: targetUser._id?.toString() || targetUser.id,
    relatedEntityType: 'user',
    createdBy: actorId,
    href: '/users',
    dedupeKey: `user-${action}:${targetUser._id || targetUser.id}`,
    excludeUserId: actorId,
  });
}

async function notifyLogin({ user }) {
  const today = new Date().toISOString().slice(0, 10);
  await notifyRoles({
    roles: ADMIN_ALERT_ROLES,
    title: 'User login',
    message: `${user.username || user.email} (${user.role}) signed in.`,
    type: 'info',
    priority: 'low',
    category: 'system',
    relatedEntityId: user.id || user._id?.toString(),
    relatedEntityType: 'user',
    createdBy: user.id || user._id,
    href: '/users',
    dedupeKey: `login:${user.id || user._id}:${today}`,
    excludeUserId: user.id || user._id?.toString(),
  });
}

async function afterInventoryChange({
  productId,
  warehouseId,
  fromWarehouseId,
  toWarehouseId,
  type,
  quantity,
  condition,
  actorId,
  movementId,
  product,
  warehouse,
  toWarehouse,
}) {
  await notifyInventoryMovement({
    type,
    quantity,
    product,
    warehouse,
    toWarehouse,
    condition,
    actorId,
    movementId,
  });

  const locations =
    type === 'TRANSFER'
      ? [
          { productId, warehouseId: fromWarehouseId },
          { productId, warehouseId: toWarehouseId },
        ]
      : [{ productId, warehouseId }];

  for (const loc of locations) {
    if (!loc.warehouseId) continue;
    await syncStockAlertsForLocation({
      productId: loc.productId,
      warehouseId: loc.warehouseId,
      actorId,
    });
    await syncWarehouseCapacityAlert({
      warehouseId: loc.warehouseId,
      actorId,
    });
    await syncExpiryAlertsForLocation({
      productId: loc.productId,
      warehouseId: loc.warehouseId,
      actorId,
    });
  }
}

async function notifyWarehouseStaffAssignment({ warehouse, staffIds, previousIds, actorId }) {
  const warehouseId = warehouse._id?.toString();
  const warehouseName = warehouse.name || 'Warehouse';
  const prevSet = new Set((previousIds || []).map(String));
  const added = (staffIds || []).map(String).filter((id) => !prevSet.has(id));

  for (const staffId of added) {
    await notifyUser({
      recipientId: staffId,
      title: 'Warehouse assignment',
      message: `You have been assigned to ${warehouseName}.`,
      type: 'info',
      priority: 'medium',
      category: 'warehouse',
      relatedEntityId: warehouseId,
      relatedEntityType: 'warehouse',
      createdBy: actorId,
      href: '/warehouses',
      dedupeKey: `warehouse-assigned:${warehouseId}:${staffId}`,
    });

    await notifyRoles({
      roles: ADMIN_ALERT_ROLES,
      title: 'User assigned warehouse',
      message: `Staff member assigned to ${warehouseName}.`,
      type: 'info',
      priority: 'medium',
      category: 'user',
      relatedEntityId: staffId,
      relatedEntityType: 'user',
      createdBy: actorId,
      href: '/users',
      dedupeKey: `user-wh-admin:${warehouseId}:${staffId}`,
      excludeUserId: actorId,
    });
  }

  if (added.length > 0) {
    await notifyRoles({
      roles: ALERT_RECIPIENT_ROLES,
      title: 'Warehouse staff updated',
      message: `${added.length} staff member(s) assigned to ${warehouseName}.`,
      type: 'info',
      priority: 'low',
      category: 'warehouse',
      relatedEntityId: warehouseId,
      relatedEntityType: 'warehouse',
      createdBy: actorId,
      href: '/warehouses',
      dedupeKey: `warehouse-staff-batch:${warehouseId}:${added.sort().join(',')}`,
      excludeUserId: actorId,
    });
  }
}

async function afterOrderStockChange(order, actorId) {
  for (const line of order.items || []) {
    await syncStockAlertsForLocation({
      productId: line.product_id,
      warehouseId: line.warehouse_id,
      actorId,
    });
    await syncWarehouseCapacityAlert({
      warehouseId: line.warehouse_id,
      actorId,
    });
  }
}

async function syncExpiryAlertsForLocation({ productId, warehouseId, actorId }) {
  try {
    const invLines = await Inventory.find({ productId, warehouseId }).lean();
    if (!invLines.length) return;

    const product = await Product.findById(productId).select('name sku').lean();
    const wh = await Warehouse.findById(warehouseId).select('name').lean();
    const productName = product?.name || product?.sku || 'Unknown product';
    const whName = wh?.name || 'Warehouse';

    for (const line of invLines) {
      if (!line.expiryDate) continue;

      const days = daysUntilExpiry(line.expiryDate);
      const status = getExpiryStatus(line.expiryDate);
      const batch = line.batchNumber ? ` batch ${line.batchNumber}` : '';

      if (status === 'Expired') {
        await notifyRoles({
          roles: ALERT_RECIPIENT_ROLES,
          title: 'Product expired',
          message: `${productName}${batch} at ${whName} has expired.`,
          type: 'error',
          priority: 'high',
          category: 'inventory',
          relatedEntityId: productId?.toString(),
          relatedEntityType: 'product',
          createdBy: actorId || null,
          href: '/inventory-tracking',
          dedupeKey: `expiry-expired:${productId}:${warehouseId}:${line._id}`,
        });
      } else if (status === 'Expiring Soon') {
        await notifyRoles({
          roles: ALERT_RECIPIENT_ROLES,
          title: 'Product expiring soon',
          message: `${productName}${batch} at ${whName} expires in ${days} day${days !== 1 ? 's' : ''}.`,
          type: 'warning',
          priority: 'high',
          category: 'inventory',
          relatedEntityId: productId?.toString(),
          relatedEntityType: 'product',
          createdBy: actorId || null,
          href: '/inventory-tracking',
          dedupeKey: `expiry-soon:${productId}:${warehouseId}:${line._id}`,
        });
      } else if (status === 'Expiring (30d)') {
        await notifyRoles({
          roles: ALERT_RECIPIENT_ROLES,
          title: 'Product expiring in 30 days',
          message: `${productName}${batch} at ${whName} expires in ${days} days.`,
          type: 'info',
          priority: 'medium',
          category: 'inventory',
          relatedEntityId: productId?.toString(),
          relatedEntityType: 'product',
          createdBy: actorId || null,
          href: '/inventory-tracking',
          dedupeKey: `expiry-30d:${productId}:${warehouseId}:${line._id}`,
        });
      }
    }
  } catch (err) {
    console.error('syncExpiryAlertsForLocation error:', err.message);
  }
}

module.exports = {
  formatNotification,
  createNotification,
  notifyRoles,
  notifyUser,
  syncStockAlertsForLocation,
  syncWarehouseCapacityAlert,
  syncExpiryAlertsForLocation,
  notifyInventoryMovement,
  notifyOrderCreated,
  notifyOrderStatusChange,
  notifyOrderCancelled,
  notifyWarehouseCreated,
  notifyWarehouseStaffAssignment,
  notifyUserLifecycle,
  notifyUserStatusChanged,
  notifyUserWarehouseAssigned,
  notifyLogin,
  afterInventoryChange,
  afterOrderStockChange,
};
