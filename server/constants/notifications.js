const NOTIFICATION_TYPES = ['success', 'warning', 'error', 'info'];

const NOTIFICATION_PRIORITIES = ['low', 'medium', 'high', 'critical'];

const NOTIFICATION_CATEGORIES = ['inventory', 'order', 'warehouse', 'user', 'system', 'task'];

/** Roles that receive operational alerts (inventory, orders, warehouse). */
const ALERT_RECIPIENT_ROLES = ['Admin', 'Supervisor'];

/** Roles that receive user-management and security alerts. */
const ADMIN_ALERT_ROLES = ['Admin'];

module.exports = {
  NOTIFICATION_TYPES,
  NOTIFICATION_PRIORITIES,
  NOTIFICATION_CATEGORIES,
  ALERT_RECIPIENT_ROLES,
  ADMIN_ALERT_ROLES,
};
