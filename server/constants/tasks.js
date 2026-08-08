const TASK_TYPES = [
  'Stock Transfer',
  'Return Task',
  'Inventory Receive',
  'Outbound Dispatch',
  'Inventory Count',
  'Order Packing',
  'Stock Adjustment',
  'Inspection',
  'Cleaning',
];

/** Primary warehouse operation tasks (Supervisor/Admin create → Staff execute). */
const OPERATION_TASK_TYPES = [
  'Stock Transfer',
  'Return Task',
  'Inventory Receive',
  'Outbound Dispatch',
  'Inventory Count',
];

const TASK_TYPE_LABELS = {
  'Stock Transfer': 'Transfer Task',
  'Return Task': 'Return Task',
  'Inventory Receive': 'Receive Task',
  'Outbound Dispatch': 'Dispatch Task',
  'Inventory Count': 'Stock Count Task',
  'Order Packing': 'Order Packing',
  'Stock Adjustment': 'Stock Adjustment',
  Inspection: 'Inspection',
  Cleaning: 'Cleaning',
};

const STATUS_LABELS = {
  Pending: 'Awaiting',
  Accepted: 'Accepted',
  'In Progress': 'In Progress',
  'Waiting Confirmation': 'Awaiting Confirmation',
  Completed: 'Completed',
  Rejected: 'Rejected',
  Overdue: 'Overdue',
};

const TASK_TYPE_META = {
  'Inventory Receive': { movementType: 'INBOUND', requiresStock: false, requiresQuantity: true, requiresProduct: true, operational: true, requiresSupplier: true },
  'Stock Transfer':    { movementType: 'TRANSFER', requiresStock: true, requiresQuantity: true, requiresProduct: true, operational: true },
  'Return Task':       { movementType: 'RETURN', requiresStock: false, requiresQuantity: true, requiresProduct: true, operational: true, requiresReturnReason: true },
  'Outbound Dispatch': { movementType: 'OUTBOUND', requiresStock: true, requiresQuantity: true, requiresProduct: true, operational: true, requiresDestination: true },
  'Order Packing':     { movementType: null, requiresStock: false, requiresQuantity: false, requiresProduct: false, operational: true },
  'Inventory Count':   { movementType: null, requiresStock: false, requiresQuantity: false, requiresProduct: false, operational: true },
  'Stock Adjustment':  { movementType: 'ADJUSTMENT', requiresStock: true, requiresQuantity: true, requiresProduct: true, operational: true },
  'Inspection':        { movementType: null, requiresStock: false, requiresQuantity: false, requiresProduct: false, operational: false },
  'Cleaning':          { movementType: null, requiresStock: false, requiresQuantity: false, requiresProduct: false, operational: false },
};

const TASK_STATUSES = [
  'Pending',
  'Accepted',
  'In Progress',
  'Waiting Confirmation',
  'Completed',
  'Rejected',
  'Overdue',
];

const TASK_PRIORITIES = ['low', 'medium', 'high', 'critical'];

const TASK_STATUS_FLOW = {
  Pending:                ['Accepted', 'Rejected', 'In Progress', 'Completed'],
  Accepted:               ['In Progress', 'Rejected'],
  'In Progress':          ['Waiting Confirmation', 'Completed', 'Pending'],
  'Waiting Confirmation': ['Completed', 'In Progress'],
  Overdue:                ['Accepted', 'In Progress', 'Completed', 'Rejected'],
  Completed:              [],
  Rejected:               ['Pending'],
};

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

function isOperationalTaskType(taskType) {
  const meta = TASK_TYPE_META[taskType];
  return meta?.movementType != null;
}

function getTaskTypeMeta(taskType) {
  return TASK_TYPE_META[taskType] || null;
}

const LEGACY_TYPE_MAP = {
  'Stock Count': 'Inventory Count',
  'Stock Count Task': 'Inventory Count',
  'Inventory Check': 'Inspection',
  'Receive Inventory': 'Inventory Receive',
  'Receive Task': 'Inventory Receive',
  'Pack Order': 'Order Packing',
  'Prepare Shipment': 'Outbound Dispatch',
  'Dispatch Order': 'Outbound Dispatch',
  'Dispatch Task': 'Outbound Dispatch',
  'Warehouse Transfer': 'Stock Transfer',
  'Transfer Task': 'Stock Transfer',
};

function normalizeLegacyTaskType(type) {
  return LEGACY_TYPE_MAP[type] || type;
}

function getTaskTypeLabel(taskType) {
  return TASK_TYPE_LABELS[taskType] || taskType;
}

function getStatusLabel(status) {
  return STATUS_LABELS[status] || status;
}

module.exports = {
  TASK_TYPES,
  OPERATION_TASK_TYPES,
  TASK_TYPE_LABELS,
  STATUS_LABELS,
  TASK_TYPE_META,
  TASK_STATUSES,
  TASK_PRIORITIES,
  TASK_STATUS_FLOW,
  STAFF_STATUS_ACTIONS,
  MANAGER_STATUS_ACTIONS,
  isOperationalTaskType,
  getTaskTypeMeta,
  normalizeLegacyTaskType,
  getTaskTypeLabel,
  getStatusLabel,
};
