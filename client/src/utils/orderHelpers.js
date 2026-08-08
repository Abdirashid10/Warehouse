export function orderStatusBadgeClass(status) {

  switch (status) {

    case 'Pending':

      return 'bg-amber-50 text-amber-800 ring-1 ring-amber-200 dark:bg-amber-500/20 dark:text-amber-200 dark:ring-amber-500/35';

    case 'Processing':

      return 'bg-blue-50 text-blue-800 ring-1 ring-blue-200 dark:bg-blue-500/20 dark:text-blue-200 dark:ring-blue-500/35';

    case 'Packed':

      return 'bg-violet-50 text-violet-800 ring-1 ring-violet-200 dark:bg-violet-500/20 dark:text-violet-200 dark:ring-violet-500/35';

    case 'Shipped':

      return 'bg-orange-50 text-orange-800 ring-1 ring-orange-200 dark:bg-orange-500/20 dark:text-orange-200 dark:ring-orange-500/35';

    case 'Delivered':

      return 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200 dark:bg-emerald-500/20 dark:text-emerald-200 dark:ring-emerald-500/35';

    default:

      return 'bg-slate-100 text-slate-600 ring-1 ring-slate-200 dark:bg-slate-700 dark:text-slate-300 dark:ring-slate-600';

  }

}



export const ORDER_STATUSES = ['Pending', 'Processing', 'Packed', 'Shipped', 'Delivered'];



export const STATUS_FLOW = {

  Pending: 'Processing',

  Processing: 'Packed',

  Packed: 'Shipped',

  Shipped: 'Delivered',

  Delivered: null,

};



export function statusTimelineIcon(status) {

  switch (status) {

    case 'Pending':

      return '🟡';

    case 'Processing':

      return '🔵';

    case 'Packed':

      return '🟣';

    case 'Shipped':

      return '🟠';

    case 'Delivered':

      return '🟢';

    default:

      return '⚪';

  }

}



export function formatOrderDateTime(iso) {

  if (!iso) return '—';

  try {

    return new Date(iso).toLocaleString(undefined, {

      dateStyle: 'medium',

      timeStyle: 'short',

    });

  } catch {

    return '—';

  }

}



export function getNextOrderStatus(current) {

  return STATUS_FLOW[current] ?? null;

}



/** All forward statuses from current (excluding current). */

export function getAllowedTransitions(current) {

  const allowed = [];

  let cursor = current;

  while (STATUS_FLOW[cursor]) {

    cursor = STATUS_FLOW[cursor];

    allowed.push(cursor);

  }

  return allowed;

}



/** Display order reference (ORD-YYYY-###); maps legacy NEX to ORD. */

export function normalizeOrderNumberDisplay(orderNumber) {

  const raw = String(orderNumber || '').trim().toUpperCase();

  const match = raw.match(/^(ORD|NEX)-(\d{4})-(\d+)$/i);

  if (!match) return raw;

  return `ORD-${match[2]}-${String(Number(match[3])).padStart(3, '0')}`;

}



/** Search by ORD-2026-001, 2026-001, 001, or legacy NEX-2026-001. */

export function orderMatchesSearchQuery(order, query) {

  const q = String(query || '').trim().toLowerCase();

  if (!q) return true;

  const num = order?.order_number || '';

  const display = normalizeOrderNumberDisplay(num).toLowerCase();

  const stored = String(num).toLowerCase();

  if (stored.includes(q) || display.includes(q)) return true;

  const match = display.match(/^ord-(\d{4})-(\d+)$/i);

  if (!match) return false;

  const yearSeq = `${match[1]}-${match[2]}`;

  const yearSeqPlain = `${match[1]}-${Number(match[2])}`;

  return (

    yearSeq.includes(q) ||

    yearSeqPlain.includes(q) ||

    match[2].includes(q) ||

    String(Number(match[2])) === q

  );

}