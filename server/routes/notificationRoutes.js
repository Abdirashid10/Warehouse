const express = require('express');
const {
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
} = require('../controllers/notificationController');
const { authenticate, checkRole } = require('../middleware/authMiddleware');
const { SUPERVISOR_ACCESS_ROLES } = require('../constants/roles');

const router = express.Router();

router.use(authenticate);

router.get('/', listNotifications);
router.get('/recent', getRecentNotifications);
router.get('/unread-count', getUnreadCount);
router.get('/admin', checkRole(['Admin']), listAllNotifications);
router.patch('/read-all', markAllNotificationsRead);
router.delete('/clear-read', clearReadNotifications);
router.delete('/clear-all', clearAllNotifications);
router.post('/sync-stock-alerts', checkRole(SUPERVISOR_ACCESS_ROLES), syncStockAlerts);
router.patch('/:id/read', markNotificationRead);
router.delete('/:id', deleteNotification);

module.exports = router;
