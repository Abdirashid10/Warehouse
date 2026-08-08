export function stockStatusClass(status) {
  switch (status) {
    case 'In Stock':
      return 'border-emerald-200/70 bg-emerald-50/60 text-emerald-700 dark:border-emerald-500/35 dark:bg-emerald-500/15 dark:text-emerald-200';
    case 'Low Stock':
      return 'border-orange-200/60 bg-orange-50/50 text-orange-800 dark:border-orange-500/35 dark:bg-orange-500/15 dark:text-orange-200';
    case 'Out of Stock':
      return 'border-red-200/70 bg-red-50/60 text-red-700 dark:border-red-500/35 dark:bg-red-500/15 dark:text-red-200';
    default:
      return 'border-border bg-slate-50 text-slate-600 dark:border-slate-600 dark:bg-slate-700 dark:text-slate-300';
  }
}

export function StockStatusBadge({ status }) {
  return <span className={`wms-badge ${stockStatusClass(status)}`}>{status}</span>;
}
