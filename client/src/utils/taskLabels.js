/** Display labels for task types (API stores canonical enum values). */
export const TASK_TYPE_LABELS = {
  'Stock Transfer': 'Transfer Task',
  'Return Task': 'Return Task',
  'Inventory Receive': 'Receive Task',
  'Outbound Dispatch': 'Dispatch Task',
  'Inventory Count': 'Stock Count Task',
  'Order Packing': 'Order Packing',
  'Stock Adjustment': 'Stock Adjustment',
  'Inspection': 'Inspection',
  'Cleaning': 'Cleaning',
};

export const STATUS_LABELS = {
  Pending: 'Awaiting',
  Accepted: 'Accepted',
  'In Progress': 'In Progress',
  'Waiting Confirmation': 'Awaiting Confirmation',
  Completed: 'Completed',
  Rejected: 'Rejected',
  Overdue: 'Overdue',
};

export function taskTypeLabel(taskType) {
  return TASK_TYPE_LABELS[taskType] || taskType || '—';
}

export function statusLabel(status) {
  return STATUS_LABELS[status] || status || '—';
}

export const OPERATION_TASK_TYPES = [
  'Stock Transfer',
  'Return Task',
  'Inventory Receive',
  'Outbound Dispatch',
  'Inventory Count',
];
