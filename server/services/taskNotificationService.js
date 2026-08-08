const { notifyUser, notifyRoles } = require('./notificationService');
const { ALERT_RECIPIENT_ROLES } = require('../constants/notifications');

function taskLabel(task) {
  const row = task.toObject ? task.toObject() : task;
  return row.title || 'Warehouse task';
}

function assigneeId(task) {
  const row = task.toObject ? task.toObject() : task;
  const ref = row.assignedToId;
  return ref?._id?.toString() || ref?.toString();
}

async function notifyTaskAssigned({ task, actor }) {
  const recipientId = assigneeId(task);
  if (!recipientId) return;

  const warehouseName = task.warehouseId?.name || 'warehouse';
  await notifyUser({
    recipientId,
    title: 'New task assigned',
    message: `${taskLabel(task)} at ${warehouseName} is due ${new Date(task.dueDate).toLocaleDateString()}.`,
    type: 'info',
    priority: task.priority === 'critical' ? 'critical' : 'high',
    category: 'task',
    relatedEntityId: task._id?.toString(),
    relatedEntityType: 'task',
    createdBy: actor?.id,
    href: '/tasks',
    dedupeKey: `task-assigned:${task._id}:${recipientId}`,
  });
}

async function notifyTaskAccepted({ task, actor }) {
  const warehouseName = task.warehouseId?.name || 'warehouse';
  const assignee = task.assignedToId?.username || task.assignedToId?.fullName || 'Staff';

  await notifyRoles({
    roles: ALERT_RECIPIENT_ROLES,
    title: 'Task accepted',
    message: `${assignee} accepted ${taskLabel(task)} at ${warehouseName}.`,
    type: 'info',
    priority: 'medium',
    category: 'task',
    relatedEntityId: task._id?.toString(),
    relatedEntityType: 'task',
    createdBy: actor?.id,
    href: '/tasks',
    dedupeKey: `task-accepted:${task._id}`,
    excludeUserId: actor?.id,
  });
}

async function notifyTaskStarted({ task, actor }) {
  const warehouseName = task.warehouseId?.name || 'warehouse';
  const assignee = task.assignedToId?.username || task.assignedToId?.fullName || 'Staff';

  await notifyRoles({
    roles: ALERT_RECIPIENT_ROLES,
    title: 'Task started',
    message: `${assignee} started ${taskLabel(task)} at ${warehouseName}.`,
    type: 'info',
    priority: 'medium',
    category: 'task',
    relatedEntityId: task._id?.toString(),
    relatedEntityType: 'task',
    createdBy: actor?.id,
    href: '/tasks',
    dedupeKey: `task-started:${task._id}`,
    excludeUserId: actor?.id,
  });
}

async function notifyTaskRejected({ task, actor }) {
  const warehouseName = task.warehouseId?.name || 'warehouse';
  const assignee = task.assignedToId?.username || task.assignedToId?.fullName || 'Staff';

  await notifyRoles({
    roles: ALERT_RECIPIENT_ROLES,
    title: 'Task rejected',
    message: `${assignee} rejected ${taskLabel(task)} at ${warehouseName}.`,
    type: 'warning',
    priority: 'high',
    category: 'task',
    relatedEntityId: task._id?.toString(),
    relatedEntityType: 'task',
    createdBy: actor?.id,
    href: '/tasks',
    dedupeKey: `task-rejected:${task._id}`,
    excludeUserId: actor?.id,
  });

  const assignerId = task.assignedById?._id?.toString() || task.assignedById?.toString();
  if (assignerId && String(assignerId) !== String(actor?.id)) {
    await notifyUser({
      recipientId: assignerId,
      title: 'Task rejected',
      message: `${assignee} rejected ${taskLabel(task)} at ${warehouseName}.`,
      type: 'warning',
      priority: 'high',
      category: 'task',
      relatedEntityId: task._id?.toString(),
      relatedEntityType: 'task',
      createdBy: actor?.id,
      href: '/tasks',
      dedupeKey: `task-rejected-assigner:${task._id}:${assignerId}`,
    });
  }
}

async function notifyTaskCompleted({ task, actor }) {
  const warehouseName = task.warehouseId?.name || 'warehouse';
  const assignee = task.assignedToId?.username || task.assignedToId?.fullName || 'Staff';

  await notifyRoles({
    roles: ALERT_RECIPIENT_ROLES,
    title: 'Task completed',
    message: `${taskLabel(task)} at ${warehouseName} was completed by ${assignee}.`,
    type: 'success',
    priority: 'medium',
    category: 'task',
    relatedEntityId: task._id?.toString(),
    relatedEntityType: 'task',
    createdBy: actor?.id,
    href: '/tasks',
    dedupeKey: `task-completed:${task._id}`,
    excludeUserId: actor?.id,
  });
}

async function notifyTaskStatusUpdated({ task, previousStatus, newStatus, actor }) {
  const recipientId = assigneeId(task);
  const warehouseName = task.warehouseId?.name || 'warehouse';
  const label = taskLabel(task);

  if (recipientId && actor?.id && String(recipientId) !== String(actor.id)) {
    await notifyUser({
      recipientId,
      title: 'Task status updated',
      message: `${label} at ${warehouseName} changed from ${previousStatus} to ${newStatus}.`,
      type: 'info',
      priority: 'medium',
      category: 'task',
      relatedEntityId: task._id?.toString(),
      relatedEntityType: 'task',
      createdBy: actor?.id,
      href: '/tasks',
      dedupeKey: `task-status:${task._id}:${newStatus}:${recipientId}`,
    });
  }

  if (newStatus !== 'Completed') {
    await notifyRoles({
      roles: ALERT_RECIPIENT_ROLES,
      title: 'Task status updated',
      message: `${label} at ${warehouseName} is now ${newStatus}.`,
      type: 'info',
      priority: 'medium',
      category: 'task',
      relatedEntityId: task._id?.toString(),
      relatedEntityType: 'task',
      createdBy: actor?.id,
      href: '/tasks',
      dedupeKey: `task-status-supervisor:${task._id}:${newStatus}`,
      excludeUserId: actor?.id,
    });
  }
}

async function notifyTaskOverdue({ task }) {
  const recipientId = assigneeId(task);
  if (!recipientId) return;

  await notifyUser({
    recipientId,
    title: 'Task overdue',
    message: `${taskLabel(task)} is past its due date. Please update progress.`,
    type: 'warning',
    priority: 'high',
    category: 'task',
    relatedEntityId: task._id?.toString(),
    relatedEntityType: 'task',
    href: '/tasks',
    dedupeKey: `task-overdue:${task._id}:${recipientId}`,
  });

  await notifyRoles({
    roles: ALERT_RECIPIENT_ROLES,
    title: 'Overdue task',
    message: `${taskLabel(task)} assigned to ${task.assignedToId?.username || 'staff'} is overdue.`,
    type: 'warning',
    priority: 'high',
    category: 'task',
    relatedEntityId: task._id?.toString(),
    relatedEntityType: 'task',
    href: '/tasks',
    dedupeKey: `task-overdue-supervisor:${task._id}`,
    excludeUserId: recipientId,
  });
}

module.exports = {
  notifyTaskAssigned,
  notifyTaskAccepted,
  notifyTaskStarted,
  notifyTaskCompleted,
  notifyTaskRejected,
  notifyTaskStatusUpdated,
  notifyTaskOverdue,
};
