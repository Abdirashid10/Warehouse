const { TASK_STATUS_FLOW, STAFF_STATUS_ACTIONS, MANAGER_STATUS_ACTIONS } = require('../constants/tasks');

function canManageTasks(role) {
  return role === 'Admin' || role === 'Supervisor';
}

function canDeleteTasks(role) {
  return role === 'Admin';
}

function canCreateTasks(role) {
  return canManageTasks(role);
}

function canAssignTasks(role) {
  return canManageTasks(role);
}

function canConfirmTask(role) {
  return role === 'Admin' || role === 'Supervisor';
}

function staffMayUpdateStatus(role) {
  return role === 'Staff';
}

function buildTaskListFilter(user) {
  if (user.role === 'Staff') {
    return { assignedToId: user.id };
  }
  return {};
}

function isValidStatusTransition(currentStatus, nextStatus) {
  const allowed = TASK_STATUS_FLOW[currentStatus] || [];
  return allowed.includes(nextStatus);
}

function getAllowedActions(currentStatus, role) {
  if (role === 'Staff') {
    return STAFF_STATUS_ACTIONS[currentStatus] || [];
  }
  return MANAGER_STATUS_ACTIONS[currentStatus] || [];
}

module.exports = {
  canManageTasks,
  canDeleteTasks,
  canCreateTasks,
  canAssignTasks,
  canConfirmTask,
  staffMayUpdateStatus,
  buildTaskListFilter,
  isValidStatusTransition,
  getAllowedActions,
};
