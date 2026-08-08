import {
  formatOrderDateTime,
  statusTimelineIcon,
} from '../utils/orderHelpers';

export function OrderStatusTimeline({ history = [] }) {
  if (!history.length) {
    return <p className="text-sm text-slate-500">No status history yet.</p>;
  }

  const sorted = [...history].sort(
    (a, b) => new Date(a.changed_at) - new Date(b.changed_at)
  );

  return (
    <ol className="relative border-l border-slate-700 pl-6">
      {sorted.map((entry, idx) => (
        <li key={`${entry.status}-${entry.changed_at}-${idx}`} className="mb-6 last:mb-0">
          <span className="absolute -left-[9px] flex h-4 w-4 items-center justify-center rounded-full bg-slate-900 text-[10px]">
            {statusTimelineIcon(entry.status)}
          </span>
          <p className="text-sm font-medium text-slate-100">
            {entry.status}
            <span className="font-normal text-slate-500">
              {' '}
              — {formatOrderDateTime(entry.changed_at)}
            </span>
          </p>
          <p className="mt-0.5 text-xs text-slate-400">
            by {entry.changed_by?.name || 'Unknown'}
            {entry.changed_by?.role ? ` (${entry.changed_by.role})` : ''}
          </p>
        </li>
      ))}
    </ol>
  );
}
