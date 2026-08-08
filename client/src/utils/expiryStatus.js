const MS_PER_DAY = 86_400_000;

export function daysUntilExpiry(expiryDate) {
  if (!expiryDate) return null;
  const exp = new Date(expiryDate);
  if (isNaN(exp.getTime())) return null;
  const now = new Date();
  now.setHours(0, 0, 0, 0);
  const expDay = new Date(exp);
  expDay.setHours(0, 0, 0, 0);
  return Math.ceil((expDay - now) / MS_PER_DAY);
}

export function getExpiryStatus(expiryDate) {
  const days = daysUntilExpiry(expiryDate);
  if (days === null) return 'No Expiry';
  if (days <= 0) return 'Expired';
  if (days <= 7) return 'Expiring Soon';
  if (days <= 30) return 'Expiring (30d)';
  return 'Safe';
}

export function expiryBadgeConfig(status) {
  switch (status) {
    case 'Expired':
      return {
        label: 'Expired',
        className:
          'bg-red-100 text-red-800 ring-1 ring-red-300 dark:bg-red-500/20 dark:text-red-200 dark:ring-red-500/40',
      };
    case 'Expiring Soon':
      return {
        label: 'Expiring Soon',
        className:
          'bg-amber-100 text-amber-800 ring-1 ring-amber-300 dark:bg-amber-500/20 dark:text-amber-200 dark:ring-amber-500/40',
      };
    case 'Expiring (30d)':
      return {
        label: 'Expiring (30d)',
        className:
          'bg-orange-50 text-orange-700 ring-1 ring-orange-200 dark:bg-orange-500/15 dark:text-orange-200 dark:ring-orange-500/30',
      };
    case 'Safe':
      return {
        label: 'Safe',
        className:
          'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200 dark:bg-emerald-500/15 dark:text-emerald-200 dark:ring-emerald-500/30',
      };
    default:
      return {
        label: '—',
        className:
          'bg-slate-50 text-slate-500 ring-1 ring-slate-200 dark:bg-slate-700/50 dark:text-slate-400 dark:ring-slate-600',
      };
  }
}

export function formatRemainingDays(days) {
  if (days === null || days === undefined) return '—';
  if (days <= 0) return 'Expired';
  if (days === 1) return '1 day left';
  return `${days} days left`;
}
