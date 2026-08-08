import { Link } from 'react-router-dom';
import { cn } from '../../lib/utils';
import { getNotificationIcon, getNotificationTone } from '../../utils/notificationMeta';
import {
  Check,
  ChevronRight,
  Clock,
  ExternalLink,
  Trash2,
} from 'lucide-react';

function relDate(iso) {
  if (!iso) return '—';
  const now = Date.now();
  const diff = now - new Date(iso).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 7) return `${days}d ago`;
  return new Date(iso).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

const PRIORITY_STYLES = {
  critical: 'border-l-red-500',
  high: 'border-l-amber-500',
  medium: 'border-l-sky-500',
  low: 'border-l-slate-300 dark:border-l-slate-600',
};

const TONE_ICON_BG = {
  success: 'bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400',
  warning: 'bg-amber-50 text-amber-600 dark:bg-amber-500/10 dark:text-amber-400',
  danger: 'bg-red-50 text-red-600 dark:bg-red-500/10 dark:text-red-400',
  accent: 'bg-sky-50 text-sky-600 dark:bg-sky-500/10 dark:text-sky-400',
  default: 'bg-muted text-muted-foreground',
};

const TONE_CATEGORY_BADGE = {
  success: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/15 dark:text-emerald-400',
  warning: 'bg-amber-100 text-amber-700 dark:bg-amber-500/15 dark:text-amber-400',
  danger: 'bg-red-100 text-red-700 dark:bg-red-500/15 dark:text-red-400',
  accent: 'bg-sky-100 text-sky-700 dark:bg-sky-500/15 dark:text-sky-400',
  default: 'bg-muted text-muted-foreground',
};

export function NotificationCard({
  notification,
  compact = false,
  onMarkRead,
  onDelete,
  onNavigate,
}) {
  const Icon = getNotificationIcon(notification.category, notification.type);
  const tone = getNotificationTone(notification.type);
  const unread = !notification.read;
  const priority = notification.priority || 'medium';
  const borderClass = PRIORITY_STYLES[priority] || PRIORITY_STYLES.medium;

  const inner = (
    <div
      className={cn(
        'group relative flex items-start gap-2.5 rounded-lg border-l-[3px] px-3 py-2.5 transition',
        borderClass,
        unread
          ? 'border border-l-[3px] border-accent/15 bg-accent/[0.03]'
          : 'border border-l-[3px] border-transparent hover:bg-muted/40',
        compact ? 'py-2' : 'py-2.5'
      )}
    >
      {/* Icon */}
      <div className={cn('mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-lg', TONE_ICON_BG[tone] || TONE_ICON_BG.default)}>
        <Icon className="h-3.5 w-3.5" />
      </div>

      {/* Content */}
      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-1.5">
          <p className={cn('text-xs leading-snug', unread ? 'font-bold text-foreground' : 'font-medium text-foreground')}>
            {notification.title}
          </p>
          <span className={cn('inline-block rounded px-1.5 py-0.5 text-[8px] font-bold uppercase tracking-wider', TONE_CATEGORY_BADGE[tone] || TONE_CATEGORY_BADGE.default)}>
            {notification.category}
          </span>
          {priority === 'critical' && (
            <span className="inline-block rounded bg-red-100 px-1 py-0.5 text-[7px] font-bold uppercase text-red-700 dark:bg-red-500/15 dark:text-red-400">Critical</span>
          )}
          {priority === 'high' && (
            <span className="inline-block rounded bg-amber-100 px-1 py-0.5 text-[7px] font-bold uppercase text-amber-700 dark:bg-amber-500/15 dark:text-amber-400">High</span>
          )}
          {unread && <span className="h-1.5 w-1.5 shrink-0 rounded-full bg-accent" aria-label="Unread" />}
        </div>
        <p className={cn('mt-0.5 text-[11px] leading-relaxed', unread ? 'text-muted-foreground' : 'text-muted-foreground/80', compact ? 'line-clamp-1' : 'line-clamp-2')}>
          {notification.message}
        </p>
        <div className="mt-1 flex flex-wrap items-center gap-2">
          <span className="flex items-center gap-0.5 text-[9px] text-muted-foreground/70">
            <Clock className="h-2.5 w-2.5" /> {relDate(notification.createdAt)}
          </span>
          {notification.createdByUser?.username && (
            <span className="text-[9px] text-muted-foreground/70">
              by {notification.createdByUser.fullName || notification.createdByUser.username}
            </span>
          )}
          <span className={`rounded px-1 py-0.5 text-[8px] font-bold uppercase ${unread ? 'bg-accent/10 text-accent' : 'bg-muted text-muted-foreground'}`}>
            {unread ? 'Unread' : 'Read'}
          </span>
          {notification.href && (
            <span className="flex items-center gap-0.5 text-[9px] font-medium text-accent">
              <ExternalLink className="h-2.5 w-2.5" /> View
            </span>
          )}
        </div>
      </div>

      {/* Actions */}
      {!compact && (onMarkRead || onDelete) && (
        <div className="flex shrink-0 items-center gap-0.5 opacity-0 transition group-hover:opacity-100">
          {unread && onMarkRead && (
            <button type="button" onClick={(e) => { e.preventDefault(); e.stopPropagation(); onMarkRead(notification.id); }} className="rounded-md p-1.5 text-muted-foreground transition hover:bg-muted hover:text-foreground" title="Mark read">
              <Check className="h-3 w-3" />
            </button>
          )}
          {onDelete && (
            <button type="button" onClick={(e) => { e.preventDefault(); e.stopPropagation(); onDelete(notification.id); }} className="rounded-md p-1.5 text-muted-foreground transition hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-500/10" title="Delete">
              <Trash2 className="h-3 w-3" />
            </button>
          )}
        </div>
      )}

      {/* Chevron for linked */}
      {notification.href && !compact && (
        <ChevronRight className="mt-1.5 h-3.5 w-3.5 shrink-0 text-muted-foreground/30 transition group-hover:text-muted-foreground" />
      )}
    </div>
  );

  if (notification.href) {
    return (
      <Link to={notification.href} onClick={onNavigate} className="block">
        {inner}
      </Link>
    );
  }

  return inner;
}
