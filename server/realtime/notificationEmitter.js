const { Notification } = require('../models');
const { formatNotification } = require('../services/notificationService');

let io = null;

function setSocketIo(socketIo) {
  io = socketIo;
}

function userRoom(userId) {
  return `user:${String(userId)}`;
}

function emitToUser(userId, event, payload) {
  if (!io || !userId) return;
  io.to(userRoom(userId)).emit(event, payload);
}

async function countUnread(recipientId) {
  return Notification.countDocuments({
    recipientId,
    read: false,
  });
}

async function emitUnreadCount(userId) {
  const unreadCount = await countUnread(userId);
  emitToUser(userId, 'notifications:unread', { unreadCount });
  return unreadCount;
}

async function emitNotificationDoc(doc) {
  if (!doc) return null;
  const row = doc.toObject ? doc.toObject() : doc;
  const recipientId = row.recipientId?._id?.toString?.() || String(row.recipientId || '');
  if (!recipientId) return null;

  const notification = formatNotification(row);
  emitToUser(recipientId, 'notification:new', { notification });
  const unreadCount = await countUnread(recipientId);
  emitToUser(recipientId, 'notifications:unread', { unreadCount });
  return { notification, unreadCount };
}

function emitNotificationRead(userId, notification, unreadCount) {
  emitToUser(userId, 'notification:read', {
    notification,
    unreadCount,
  });
  emitToUser(userId, 'notifications:unread', { unreadCount });
}

function emitAllRead(userId, unreadCount = 0) {
  emitToUser(userId, 'notifications:all-read', { unreadCount });
  emitToUser(userId, 'notifications:unread', { unreadCount });
}

function emitNotificationDeleted(userId, notificationId, unreadCount) {
  emitToUser(userId, 'notification:deleted', { id: notificationId, unreadCount });
  emitToUser(userId, 'notifications:unread', { unreadCount });
}

function getIo() {
  return io;
}

module.exports = {
  setSocketIo,
  getIo,
  emitToUser,
  emitUnreadCount,
  emitNotificationDoc,
  emitNotificationRead,
  emitAllRead,
  emitNotificationDeleted,
  countUnread,
};
