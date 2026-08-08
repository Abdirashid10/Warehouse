export function getRolePermissionsSummary(role) {
  if (role === 'Admin') {
    return [
      'Full system administration',
      'User & role management',
      'All warehouses and inventory',
      'Reports and audit logs',
    ];
  }
  if (role === 'Supervisor') {
    return [
      'Inventory and stock movements',
      'Orders and fulfillment',
      'Warehouse management',
      'Reports access',
    ];
  }
  return [
    'View assigned inventory',
    'Receive, dispatch, and transfer stock',
    'Update tasks and process assigned orders',
  ];
}

export function getAccountStatusLabel(status, archived) {
  if (archived || status === 'Archived') return 'Archived';
  if (status === 'Suspended') return 'Suspended';
  return 'Active';
}

export function getAccountStatusClass(status, archived) {
  if (archived || status === 'Archived') {
    return 'border-slate-200/70 bg-slate-50/60 text-slate-700 dark:border-slate-500/35 dark:bg-slate-500/15 dark:text-slate-300';
  }
  if (status === 'Suspended') {
    return 'border-amber-200/60 bg-amber-50/50 text-amber-800 dark:border-amber-500/35 dark:bg-amber-500/15 dark:text-amber-200';
  }
  return 'border-emerald-200/70 bg-emerald-50/60 text-emerald-700 dark:border-emerald-500/35 dark:bg-emerald-500/15 dark:text-emerald-200';
}
