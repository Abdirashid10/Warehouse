export const ROLES = ['Admin', 'Supervisor', 'Staff'];

/** Roles that may access Reports (Admin and Supervisor). */
export function canAccessReports(role) {
  return role === 'Admin' || role === 'Supervisor';
}

/** Roles that may manage products, inventory, warehouses, movements. */
export function canManageOperations(role) {
  return role === 'Admin' || role === 'Supervisor';
}

/** Staff can advance order status (Pack, Ship) but not create/delete orders. */
const STAFF_ALLOWED_TRANSITIONS = ['Processing', 'Packed', 'Shipped'];

export function canAdvanceOrderStatus(role, targetStatus) {
  if (role === 'Admin' || role === 'Supervisor') return true;
  if (role === 'Staff') return STAFF_ALLOWED_TRANSITIONS.includes(targetStatus);
  return false;
}

export function roleBadgeClass(role) {
  if (role === 'Admin') {
    return 'border-violet-200/70 bg-violet-50/60 text-violet-800 dark:border-violet-400/40 dark:bg-violet-500/15 dark:text-violet-100';
  }
  if (role === 'Supervisor') {
    return 'border-amber-200/60 bg-amber-50/50 text-amber-800 dark:border-amber-500/35 dark:bg-amber-500/15 dark:text-amber-200';
  }
  return 'border-sky-200/70 bg-sky-50/60 text-sky-800 dark:border-sky-500/35 dark:bg-sky-500/15 dark:text-sky-200';
}
