/** Maps UI module keys to stored module values (legacy + normalized). */
const MODULE_ALIASES = {
  inventory: ['Inventory', 'inventory'],
  warehouse: ['Warehouse', 'warehouse'],
  order: ['Orders', 'order'],
  task: ['Tasks', 'task'],
  user: ['User Management', 'user'],
  profile: ['Profile', 'profile'],
  system: ['System', 'system'],
};

const INVENTORY_ACTIONS = {
  INBOUND: 'Receive',
  OUTBOUND: 'Dispatch',
  RETURN: 'Return',
  TRANSFER: 'Transfer',
  ADJUSTMENT: 'Adjustment',
};

const TASK_STATUS_ACTIONS = {
  Pending: 'Created',
  Accepted: 'Accepted',
  'In Progress': 'Started',
  Completed: 'Completed',
  Rejected: 'Rejected',
};

/** Stored DB values (any casing) → canonical UI/API module key. */
const MODULE_KEY_LOOKUP = (() => {
  const lookup = {};
  for (const [key, aliases] of Object.entries(MODULE_ALIASES)) {
    lookup[key] = key;
    for (const alias of aliases) {
      lookup[String(alias).toLowerCase()] = key;
    }
  }
  return lookup;
})();

function resolveModuleFilter(moduleKey) {
  if (!moduleKey) return null;
  const key = String(moduleKey).toLowerCase();
  return MODULE_ALIASES[key] || [moduleKey];
}

/** Map a stored module label to the canonical key used by KPI cards and filters. */
function normalizeModuleKey(moduleValue) {
  if (!moduleValue) return null;
  const trimmed = String(moduleValue).trim();
  if (!trimmed) return null;
  return MODULE_KEY_LOOKUP[trimmed.toLowerCase()] || trimmed.toLowerCase();
}

function inventoryActionLabel(type) {
  return INVENTORY_ACTIONS[type] || type || 'Movement';
}

function taskStatusActionLabel(status) {
  return TASK_STATUS_ACTIONS[status] || 'Status Change';
}

module.exports = {
  MODULE_ALIASES,
  MODULE_KEY_LOOKUP,
  INVENTORY_ACTIONS,
  TASK_STATUS_ACTIONS,
  resolveModuleFilter,
  normalizeModuleKey,
  inventoryActionLabel,
  taskStatusActionLabel,
};
