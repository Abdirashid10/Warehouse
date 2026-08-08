import { cn } from '../../lib/utils';
import { AlertTriangle } from 'lucide-react';

const STATUS_STYLES = {
  Pending: 'border-slate-200 bg-slate-50 text-slate-700 dark:border-slate-600 dark:bg-slate-500/15 dark:text-slate-200',
  Accepted: 'border-sky-200 bg-sky-50 text-sky-800 dark:border-sky-500/35 dark:bg-sky-500/15 dark:text-sky-200',
  'In Progress': 'border-orange-200 bg-orange-50 text-orange-800 dark:border-orange-500/35 dark:bg-orange-500/15 dark:text-orange-200',
  'Waiting Confirmation': 'border-orange-200 bg-orange-50 text-orange-800 dark:border-orange-500/35 dark:bg-orange-500/15 dark:text-orange-200',
  Completed: 'border-emerald-200 bg-emerald-50 text-emerald-800 dark:border-emerald-500/35 dark:bg-emerald-500/15 dark:text-emerald-200',
  Rejected: 'border-red-200 bg-red-50 text-red-700 dark:border-red-500/35 dark:bg-red-500/15 dark:text-red-300',
  Overdue: 'border-red-300 bg-red-100 text-red-900 dark:border-red-600/50 dark:bg-red-900/30 dark:text-red-200',
};

const STATUS_LABELS = {
  Pending: 'Awaiting',
  'Waiting Confirmation': 'Awaiting Confirm',
};

const PRIORITY_STYLES = {
  low: 'border-border bg-muted text-muted-foreground',
  medium: 'border-amber-200/70 bg-amber-50 text-amber-800 dark:border-amber-500/35 dark:bg-amber-500/15 dark:text-amber-200',
  high: 'border-orange-200/70 bg-orange-50 text-orange-800 dark:border-orange-500/35 dark:bg-orange-500/15 dark:text-orange-200',
  critical: 'border-red-200/70 bg-red-50 text-red-800 dark:border-red-500/35 dark:bg-red-500/15 dark:text-red-300',
};

export function TaskStatusBadge({ status, workflowStatus }) {
  const displayStatus = workflowStatus || status;
  return (
    <span className={cn('inline-flex wms-badge capitalize', STATUS_STYLES[displayStatus] || STATUS_STYLES.Pending)}>
      {STATUS_LABELS[displayStatus] || displayStatus}
    </span>
  );
}

export function TaskOverdueBadge({ className }) {
  return (
    <span className={cn('inline-flex items-center gap-0.5 wms-badge border-red-300 bg-red-100 text-red-900 dark:border-red-600/50 dark:bg-red-900/30 dark:text-red-200', className)}>
      <AlertTriangle className="h-3 w-3" />
      Overdue
    </span>
  );
}

export function TaskPriorityBadge({ priority }) {
  return (
    <span className={cn('inline-flex wms-badge capitalize', PRIORITY_STYLES[priority] || PRIORITY_STYLES.medium)}>
      {priority}
    </span>
  );
}

/** Shared KPI card colors — keep in sync with status palette. */
export const TASK_KPI_ITEMS = [
  { key: 'total', statKey: 'total', label: 'Total Tasks', color: 'text-foreground', bg: 'bg-muted/40', ring: 'ring-border' },
  { key: 'Pending', statKey: 'awaiting', label: 'Awaiting', color: 'text-slate-600 dark:text-slate-300', bg: 'bg-slate-100 dark:bg-slate-700/50', ring: 'ring-slate-200 dark:ring-slate-600' },
  { key: 'Accepted', statKey: 'accepted', label: 'Accepted', color: 'text-sky-600 dark:text-sky-300', bg: 'bg-sky-50 dark:bg-sky-500/10', ring: 'ring-sky-200 dark:ring-sky-500/30' },
  { key: 'In Progress', statKey: 'inProgress', label: 'In Progress', color: 'text-orange-600 dark:text-orange-300', bg: 'bg-orange-50 dark:bg-orange-500/10', ring: 'ring-orange-200 dark:ring-orange-500/30' },
  { key: 'Completed', statKey: 'completed', label: 'Completed', color: 'text-emerald-600 dark:text-emerald-300', bg: 'bg-emerald-50 dark:bg-emerald-500/10', ring: 'ring-emerald-200 dark:ring-emerald-500/30' },
  { key: 'Rejected', statKey: 'rejected', label: 'Rejected', color: 'text-red-600 dark:text-red-400', bg: 'bg-red-50 dark:bg-red-500/10', ring: 'ring-red-200 dark:ring-red-500/30' },
  { key: 'Overdue', statKey: 'overdue', label: 'Overdue', color: 'text-red-800 dark:text-red-300', bg: 'bg-red-100 dark:bg-red-900/30', ring: 'ring-red-300 dark:ring-red-600/40' },
];
