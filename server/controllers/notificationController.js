const mongoose = require('mongoose');
const { Notification } = require('../models');
const { formatNotification } = require('../services/notificationService');
const {
  emitNotificationRead,
  emitAllRead,
  emitNotificationDeleted,
  emitUnreadCount,
  countUnread,
} = require('../realtime/notificationEmitter');
const {
  NOTIFICATION_TYPES,
  NOTIFICATION_CATEGORIES,
} = require('../constants/notifications');

function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(id);
}

function parseLimit(value, fallback = 50, max = 200) {
  const n = parseInt(String(value ?? ''), 10);
  if (!Number.isFinite(n) || n < 1) return fallback;
  return Math.min(n, max);
}

function parsePage(value) {
  const n = parseInt(String(value ?? ''), 10);
  if (!Number.isFinite(n) || n < 1) return 1;
  return n;
}

function parseDateRange(from, to) {
  const range = {};
  if (from) {
    const d = new Date(from);
    if (!Number.isNaN(d.getTime())) range.$gte = d;
  }
  if (to) {
    const d = new Date(to);
    if (!Number.isNaN(d.getTime())) {
      d.setHours(23, 59, 59, 999);
      range.$lte = d;
    }
  }
  return Object.keys(range).length ? range : null;
}

/**
 * GET /api/notifications — current user's notifications.
 */
async function listNotifications(req, res) {
  try {
    const { type, category, read, limit, page, from, to, q, section } = req.query;
    const filter = { recipientId: req.user.id };

    if (type && NOTIFICATION_TYPES.includes(type)) filter.type = type;
    if (section === 'system') {
      filter.category = { $in: ['system', 'user', 'warehouse'] };
    } else if (category && NOTIFICATION_CATEGORIES.includes(category)) {
      filter.category = category;
    }
    if (read === 'true') filter.read = true;
    if (read === 'false') filter.read = false;

    const dateRange = parseDateRange(from, to);
    if (dateRange) filter.createdAt = dateRange;

    if (q) {
      const term = String(q).trim();
      filter.$or = [
        { title: { $regex: term, $options: 'i' } },
        { message: { $regex: term, $options: 'i' } },
      ];
    }

    const perPage = parseLimit(limit, 20, 100);
    const currentPage = parsePage(page);
    const skip = (currentPage - 1) * perPage;

    const [rows, total, unreadCount] = await Promise.all([
      Notification.find(filter)
        .sort({ read: 1, createdAt: -1 })
        .skip(skip)
        .limit(perPage)
        .populate('createdBy', 'username role fullName')
        .lean(),
      Notification.countDocuments(filter),
      countUnread(req.user.id),
    ]);

    return res.json({
      notifications: rows.map((row) => formatNotification(row)),
      unreadCount,
      pagination: {
        page: currentPage,
        limit: perPage,
        total,
        pages: Math.max(1, Math.ceil(total / perPage)),
      },
    });
  } catch (err) {
    console.error('listNotifications error:', err.message);
    return res.status(500).json({ message: 'Failed to load notifications' });
  }
}

/**
 * GET /api/notifications/recent — recent notifications for dashboards/reports.
 */
async function getRecentNotifications(req, res) {
  try {
    const limit = parseLimit(req.query.limit, 10, 50);
    const rows = await Notification.find({ recipientId: req.user.id })
      .sort({ createdAt: -1 })
      .limit(limit)
      .populate('createdBy', 'username role fullName')
      .lean();

    const unreadCount = await countUnread(req.user.id);
    return res.json({
      notifications: rows.map((row) => formatNotification(row)),
      unreadCount,
    });
  } catch (err) {
    console.error('getRecentNotifications error:', err.message);
    return res.status(500).json({ message: 'Failed to load recent notifications' });
  }
}

/**
 * GET /api/notifications/unread-count
 */
async function getUnreadCount(req, res) {
  try {
    const unreadCount = await Notification.countDocuments({
      recipientId: req.user.id,
      read: false,
    });
    return res.json({ unreadCount });
  } catch (err) {
    console.error('getUnreadCount error:', err.message);
    return res.status(500).json({ message: 'Failed to load unread count' });
  }
}

/**
 * GET /api/notifications/admin — Admin view of all notifications.
 */
async function listAllNotifications(req, res) {
  try {
    const { type, category, read, limit } = req.query;
    const filter = {};

    if (type && NOTIFICATION_TYPES.includes(type)) filter.type = type;
    if (category && NOTIFICATION_CATEGORIES.includes(category)) filter.category = category;
    if (read === 'true') filter.read = true;
    if (read === 'false') filter.read = false;

    const rows = await Notification.find(filter)
      .sort({ createdAt: -1 })
      .limit(parseLimit(limit, 100))
      .populate('recipientId', 'username email role')
      .populate('createdBy', 'username email role')
      .lean();

    return res.json({
      notifications: rows.map((row) => ({
        ...formatNotification(row),
        recipient: row.recipientId
          ? {
              id: row.recipientId._id?.toString(),
              username: row.recipientId.username,
              email: row.recipientId.email,
              role: row.recipientId.role,
            }
          : null,
        createdByUser: row.createdBy
          ? {
              id: row.createdBy._id?.toString(),
              username: row.createdBy.username,
              role: row.createdBy.role,
            }
          : null,
      })),
    });
  } catch (err) {
    console.error('listAllNotifications error:', err.message);
    return res.status(500).json({ message: 'Failed to load notifications' });
  }
}

async function markNotificationRead(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid notification id' });
    }

    const doc = await Notification.findOneAndUpdate(
      { _id: id, recipientId: req.user.id },
      { $set: { read: true, readAt: new Date() } },
      { new: true }
    ).lean();

    if (!doc) {
      return res.status(404).json({ message: 'Notification not found' });
    }

    const formatted = formatNotification(doc);
    const unreadCount = await countUnread(req.user.id);
    emitNotificationRead(req.user.id, formatted, unreadCount);

    return res.json({ notification: formatted, unreadCount });
  } catch (err) {
    console.error('markNotificationRead error:', err.message);
    return res.status(500).json({ message: 'Failed to mark notification as read' });
  }
}

async function markAllNotificationsRead(req, res) {
  try {
    const result = await Notification.updateMany(
      { recipientId: req.user.id, read: false },
      { $set: { read: true, readAt: new Date() } }
    );
    emitAllRead(req.user.id, 0);
    return res.json({ updated: result.modifiedCount ?? 0, unreadCount: 0 });
  } catch (err) {
    console.error('markAllNotificationsRead error:', err.message);
    return res.status(500).json({ message: 'Failed to mark all as read' });
  }
}

async function deleteNotification(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid notification id' });
    }

    const doc = await Notification.findOneAndDelete({
      _id: id,
      recipientId: req.user.id,
    }).lean();

    if (!doc) {
      return res.status(404).json({ message: 'Notification not found' });
    }

    const unreadCount = await countUnread(req.user.id);
    emitNotificationDeleted(req.user.id, id, unreadCount);

    return res.json({ message: 'Notification cleared', unreadCount });
  } catch (err) {
    console.error('deleteNotification error:', err.message);
    return res.status(500).json({ message: 'Failed to clear notification' });
  }
}

async function clearReadNotifications(req, res) {
  try {
    const result = await Notification.deleteMany({
      recipientId: req.user.id,
      read: true,
    });
    return res.json({ deleted: result.deletedCount ?? 0 });
  } catch (err) {
    console.error('clearReadNotifications error:', err.message);
    return res.status(500).json({ message: 'Failed to clear notifications' });
  }
}

async function clearAllNotifications(req, res) {
  try {
    const result = await Notification.deleteMany({ recipientId: req.user.id });
    return res.json({ deleted: result.deletedCount ?? 0 });
  } catch (err) {
    console.error('clearAllNotifications error:', err.message);
    return res.status(500).json({ message: 'Failed to clear notifications' });
  }
}

async function syncStockAlerts(req, res) {
  try {
    const { fetchInventoryTrackingRows } = require('../services/inventoryTrackingService');
    const { syncStockAlertsForLocation } = require('../services/notificationService');

    const { rows } = await fetchInventoryTrackingRows();
    const alertRows = rows.filter(
      (row) => row.stock_status === 'Low Stock' || row.stock_status === 'Out of Stock'
    );

    for (const row of alertRows) {
      await syncStockAlertsForLocation({
        productId: row.product_id,
        warehouseId: row.warehouse_id,
        actorId: req.user.id,
      });
    }

    return res.json({ synced: alertRows.length });
  } catch (err) {
    console.error('syncStockAlerts error:', err.message);
    return res.status(500).json({ message: 'Failed to sync stock alerts' });
  }
}

module.exports = {
  listNotifications,
  getRecentNotifications,
  getUnreadCount,
  listAllNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  deleteNotification,
  clearReadNotifications,
  clearAllNotifications,
  syncStockAlerts,
};
