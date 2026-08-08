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

/** The completion button names the operation it will execute. */
const COMPLETE_LABELS = {
  TRANSFER: 'Complete Transfer',
  INBOUND: 'Complete Receive',
  OUTBOUND: 'Complete Dispatch',
  RETURN: 'Complete Return',
  ADJUSTMENT: 'Complete Adjustment',
};

/**
 * The one action that moves the task forward from its current status. Rendered as the
 * primary (solid) button; everything else in the list is a secondary escape hatch.
 */
const PRIMARY_NEXT_STATUS = {
  Pending: 'Accepted',
  Accepted: 'In Progress',
  'In Progress': 'Completed',
  'Waiting Confirmation': 'Completed',
  Overdue: 'In Progress',
};

export function primaryActionFor(currentStatus) {
  return PRIMARY_NEXT_STATUS[currentStatus] || null;
}

/**
 * Label/icon/variant for a transition, specialised by task type where it helps:
 * Accepted → "Start Work", then In Progress → "Complete Transfer" on a transfer task.
 */
export function taskActionConfig(nextStatus, task) {
  const base = ACTION_LABELS[nextStatus];
  if (!base) return null;

  if (nextStatus === 'Completed') {
    const movementType = task?.task_type_meta?.movement_type;
    return { ...base, label: COMPLETE_LABELS[movementType] || base.label };
  }
  return base;
}
