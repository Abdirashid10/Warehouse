/** Maps UI module keys to stored module values (legacy + normalized). */
const MODULE_ALIASES = {
  inventory: ['Inventory', 'inventory'],
  movement: ['Movement', 'movement'],
  warehouse: ['Warehouse', 'warehouse'],
  order: ['Orders', 'order'],
  task: ['Tasks', 'task'],
  user: ['User Management', 'user'],
  profile: ['Profile', 'profile'],
  system: ['System', 'system'],
};

/**
 * Audit modules a Supervisor may read.
 *
 * Deliberately mirrors what the Supervisor role can actually DO:
 * stock movements and inventory edits, warehouse and order management, tasks,
 * and their own profile changes. Stock movements are recorded under the
 * `Inventory` module (entityType 'movement'); `movement` is kept for legacy
 * rows and the UI filter.
 *
 * `user` (User Management) is absent by design — /api/users is Admin-only, so
 * those entries, including the target user's identity, must never reach a
 * Supervisor. `system` is likewise Admin-only.
 */
const SUPERVISOR_AUDIT_MODULES = [
  'inventory',
  'movement',
  'warehouse',
  'order',
  'task',
  'profile',
];

/** Modules only an Admin may read. Exported for tests and UI gating. */
const ADMIN_ONLY_AUDIT_MODULES = ['user', 'system'];

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
  'Waiting Confirmation': 'Submitted for Confirmation',
  Completed: 'Completed',
  Rejected: 'Rejected',
  Overdue: 'Overdue',
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

/**
 * Canonical module keys a role may read, or `null` for unrestricted (Admin).
 * Fails closed: an unrecognised role sees nothing.
 */
function visibleModuleKeysForRole(role) {
  if (role === 'Admin') return null;
  if (role === 'Supervisor') return SUPERVISOR_AUDIT_MODULES;
  return [];
}

/** Canonical module keys → every stored module value they cover. */
function moduleValuesForKeys(keys) {
  const values = [];
  for (const key of keys || []) {
    const aliases = MODULE_ALIASES[key];
    if (aliases) values.push(...aliases);
    else values.push(key);
  }
  return [...new Set(values)];
}

/**
 * Can `role` see a log stored under `moduleValue`?
 * Unknown modules are denied for non-Admins so a new module cannot leak by
 * simply not being listed yet.
 */
function isModuleVisibleToRole(moduleValue, role) {
  const allowed = visibleModuleKeysForRole(role);
  if (allowed === null) return true;
  const key = normalizeModuleKey(moduleValue);
  return key ? allowed.includes(key) : false;
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
  SUPERVISOR_AUDIT_MODULES,
  ADMIN_ONLY_AUDIT_MODULES,
  resolveModuleFilter,
  normalizeModuleKey,
  visibleModuleKeysForRole,
  moduleValuesForKeys,
  isModuleVisibleToRole,
  inventoryActionLabel,
  taskStatusActionLabel,
};
