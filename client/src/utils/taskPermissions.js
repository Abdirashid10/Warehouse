export function canManageTasks(role) {
  return role === 'Admin' || role === 'Supervisor';
}

export function canDeleteTasks(role) {
  return role === 'Admin';
}

export function canCreateTasks(role) {
  return canManageTasks(role);
}

export function canConfirmTask(role) {
  return role === 'Admin' || role === 'Supervisor';
}

const STAFF_STATUS_ACTIONS = {
  Pending:                ['Accepted', 'Rejected'],
  Accepted:               ['In Progress'],
  'In Progress':          ['Completed'],
  'Waiting Confirmation': [],
  Overdue:                ['Accepted', 'In Progress'],
  Completed:              [],
  Rejected:               [],
};

const MANAGER_STATUS_ACTIONS = {
  Pending:                ['Accepted', 'In Progress', 'Completed', 'Rejected'],
  Accepted:               ['In Progress', 'Rejected'],
  'In Progress':          ['Waiting Confirmation', 'Completed', 'Pending'],
  'Waiting Confirmation': ['Completed', 'In Progress'],
  Overdue:                ['Accepted', 'In Progress', 'Completed', 'Rejected'],
  Completed:              [],
  Rejected:               ['Pending'],
};

export function staffStatusActions(currentStatus) {
  return STAFF_STATUS_ACTIONS[currentStatus] || [];
}

export function managerStatusActions(currentStatus) {
  return MANAGER_STATUS_ACTIONS[currentStatus] || [];
}

export function getStatusActions(currentStatus, role) {
  if (role === 'Staff') return staffStatusActions(currentStatus);
  return managerStatusActions(currentStatus);
}

export const STATUS_CONFIG = {
  Pending:                { color: 'slate', label: 'Awaiting', icon: 'clock' },
  Accepted:               { color: 'sky', label: 'Accepted', icon: 'thumbs-up' },
  'In Progress':          { color: 'blue', label: 'In Progress', icon: 'play' },
  'Waiting Confirmation': { color: 'amber', label: 'Awaiting Confirm', icon: 'hourglass' },
  Completed:              { color: 'emerald', label: 'Completed', icon: 'check' },
  Rejected:               { color: 'red', label: 'Rejected', icon: 'x' },
  Overdue:                { color: 'red', label: 'Overdue', icon: 'alert' },
};

export const ACTION_LABELS = {
  Accepted:               { label: 'Accept', icon: 'thumbs-up', variant: 'sky' },
  'In Progress':          { label: 'Start Work', icon: 'play', variant: 'blue' },
  'Waiting Confirmation': { label: 'Submit for Approval', icon: 'send', variant: 'amber' },
  Completed:              { label: 'Complete', icon: 'check', variant: 'emerald' },
  Rejected:               { label: 'Reject', icon: 'x', variant: 'red' },
  Pending:                { label: 'Reopen', icon: 'rotate', variant: 'slate' },
};
