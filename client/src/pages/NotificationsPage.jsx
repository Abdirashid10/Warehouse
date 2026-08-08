import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  AlertTriangle,
  ArrowRightLeft,
  Bell,
  BellOff,
  Boxes,
  CheckCheck,
  ChevronLeft,
  ChevronRight,
  ClipboardList,
  Filter,
  Loader2,
  Package,
  Search,
  ShoppingCart,
  Trash2,
  Warehouse,
  X,
} from 'lucide-react';
import {
  useNotifications,
  useUnreadCount,
  useNotificationMutations,
} from '../hooks/useNotifications';
import { NotificationCard } from '../components/notifications/NotificationCard';
import { NOTIFICATION_CATEGORIES } from '../utils/notificationMeta';

/* ─── Helpers ─── */

function fmt(n) { return Number(n || 0).toLocaleString(); }

/* ═══════════════════════════════════════════════════════════════
   MAIN EXPORT
   ═══════════════════════════════════════════════════════════════ */

const NOTIFICATION_SECTIONS = [
  { id: '', label: 'All' },
  { id: 'task', label: 'Tasks', category: 'task' },
  { id: 'inventory', label: 'Inventory', category: 'inventory' },
  { id: 'order', label: 'Orders', category: 'order' },
  { id: 'system', label: 'System', section: 'system' },
];

export function NotificationsPage() {
  const [section, setSection] = useState('');
  const [readFilter, setReadFilter] = useState('');
  const [page, setPage] = useState(1);
  const [searchQ, setSearchQ] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [showFilters, setShowFilters] = useState(false);
  const [viewMode, setViewMode] = useState('table');

  const params = useMemo(() => {
    const p = { page, limit: 20 };
    const active = NOTIFICATION_SECTIONS.find((s) => s.id === section);
    if (active?.category) p.category = active.category;
    if (active?.section) p.section = active.section;
    if (readFilter === 'unread') p.read = 'false';
    if (readFilter === 'read') p.read = 'true';
    if (searchQ.trim()) p.q = searchQ.trim();
    if (dateFrom) p.from = dateFrom;
    if (dateTo) p.to = dateTo;
    return p;
  }, [section, readFilter, page, searchQ, dateFrom, dateTo]);

  const { data, isLoading, isError } = useNotifications(params);
  const { data: unreadData } = useUnreadCount();
  const { markRead, markAllRead, remove, clearRead } = useNotificationMutations();

  const allNotifications = data?.notifications || [];
  const pagination = data?.pagination || { page: 1, pages: 1, total: 0 };
  const unreadCount = unreadData?.unreadCount ?? data?.unreadCount ?? 0;

  const notifications = allNotifications;

  const hasActiveFilter = readFilter || section || searchQ || dateFrom || dateTo;

  return (
    <div className="space-y-4 px-1">

      {/* ── Header ── */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-lg font-bold text-foreground">Notifications</h1>
          <p className="text-xs text-muted-foreground">
            Realtime operational alerts & workflow updates · {pagination.total} total{unreadCount > 0 ? ` · ${unreadCount} unread` : ''}
          </p>
        </div>
        <div className="flex items-center gap-1.5 shrink-0">
          {unreadCount > 0 && (
            <button type="button" onClick={() => markAllRead.mutate()} disabled={markAllRead.isPending} className="inline-flex items-center gap-1 rounded-md border border-border px-2 py-1.5 text-[11px] font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground disabled:opacity-50">
              <CheckCheck className="h-3 w-3" /> Mark All Read
            </button>
          )}
          <button type="button" onClick={() => clearRead.mutate()} disabled={clearRead.isPending || !allNotifications.some((n) => n.read)} className="inline-flex items-center gap-1 rounded-md border border-border px-2 py-1.5 text-[11px] font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground disabled:opacity-50" title="Clear all read notifications">
            <Trash2 className="h-3 w-3" /> Clear Read
          </button>
        </div>
      </div>

      {/* ── Section Tabs ── */}
      <div className="flex flex-wrap gap-1">
        {NOTIFICATION_SECTIONS.map((tab) => (
          <button
            key={tab.id || 'all'}
            type="button"
            onClick={() => { setSection(tab.id); setPage(1); }}
            className={`rounded-md px-2.5 py-1.5 text-[11px] font-semibold transition ${
              section === tab.id ? 'bg-accent text-white' : 'bg-muted/50 text-muted-foreground hover:text-foreground'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* ── KPI Cards ── */}
      <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
        <KpiMini label="Unread" value={unreadCount} icon={Bell} color="text-sky-600 dark:text-sky-400" bg="bg-sky-50 dark:bg-sky-500/10" active={readFilter === 'unread'} onClick={() => { setReadFilter(readFilter === 'unread' ? '' : 'unread'); setPage(1); }} />
        <KpiMini label="On Page" value={notifications.length} icon={ClipboardList} color="text-violet-600 dark:text-violet-400" bg="bg-violet-50 dark:bg-violet-500/10" active={false} />
        <KpiMini label="Total" value={pagination.total} icon={Package} color="text-emerald-600 dark:text-emerald-400" bg="bg-emerald-50 dark:bg-emerald-500/10" active={false} />
        <KpiMini label="Pages" value={pagination.pages} icon={ShoppingCart} color="text-blue-600 dark:text-blue-400" bg="bg-blue-50 dark:bg-blue-500/10" active={false} />
      </div>

      {/* ── Search + Filter Bar ── */}
      <div className="flex items-center gap-2">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
          <input type="text" value={searchQ} onChange={(e) => setSearchQ(e.target.value)} placeholder="Search notifications…" className="wms-input h-8 w-full pl-8 text-xs" />
        </div>
        <button type="button" onClick={() => setShowFilters(!showFilters)} className={`inline-flex items-center gap-1 rounded-md border px-2 py-1.5 text-[11px] font-medium transition ${showFilters ? 'border-accent bg-accent/5 text-accent' : 'border-border text-muted-foreground hover:bg-muted hover:text-foreground'}`}>
          <Filter className="h-3 w-3" /> Filters
        </button>
        <button type="button" onClick={() => setViewMode(viewMode === 'table' ? 'cards' : 'table')} className="inline-flex items-center gap-1 rounded-md border border-border px-2 py-1.5 text-[11px] font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground">
          {viewMode === 'table' ? 'Cards' : 'Table'}
        </button>
        {hasActiveFilter && (
          <button type="button" onClick={() => { setReadFilter(''); setSection(''); setSearchQ(''); setDateFrom(''); setDateTo(''); setPage(1); }} className="inline-flex items-center gap-1 rounded-md border border-border px-2 py-1.5 text-[11px] font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground">
            <X className="h-3 w-3" /> Clear
          </button>
        )}
      </div>

      {/* ── Advanced Filters ── */}
      {showFilters && (
        <div className="flex flex-wrap gap-2 rounded-lg border border-border/60 bg-muted/10 px-3 py-2.5">
          {/* Read status */}
          <div className="flex items-center gap-1">
            <span className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground mr-1">Status:</span>
            {['', 'unread', 'read'].map((f) => (
              <button key={f || 'all'} type="button" onClick={() => { setReadFilter(f); setPage(1); }} className={`rounded-md px-2 py-1 text-[10px] font-semibold transition ${readFilter === f ? 'bg-accent text-white' : 'bg-card border border-border text-muted-foreground hover:text-foreground'}`}>
                {f === '' ? 'All' : f === 'unread' ? 'Unread' : 'Read'}
              </button>
            ))}
          </div>
          <div className="flex items-center gap-1">
            <span className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground mr-1">From:</span>
            <input type="date" value={dateFrom} onChange={(e) => { setDateFrom(e.target.value); setPage(1); }} className="rounded-md border border-border bg-card px-2 py-1 text-[10px]" />
          </div>
          <div className="flex items-center gap-1">
            <span className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground mr-1">To:</span>
            <input type="date" value={dateTo} onChange={(e) => { setDateTo(e.target.value); setPage(1); }} className="rounded-md border border-border bg-card px-2 py-1 text-[10px]" />
          </div>
          <div className="w-px self-stretch bg-border/60 hidden sm:block" />
          {/* Category legacy select hidden — use section tabs */}
          <div className="hidden items-center gap-1">
            <span className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground mr-1">Category:</span>
            <select value={section} onChange={(e) => { setSection(e.target.value); setPage(1); }} className="rounded-md border border-border bg-card px-2 py-1 text-[10px] font-medium text-foreground">
              {NOTIFICATION_CATEGORIES.map((c) => (
                <option key={c.value || 'all'} value={c.value}>{c.label}</option>
              ))}
            </select>
          </div>
        </div>
      )}

      {/* ── Notifications Feed ── */}
      {isLoading ? (
        <LoadingSkeleton />
      ) : isError ? (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-3 text-xs text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
          Failed to load notifications.
        </div>
      ) : notifications.length === 0 ? (
        <div className="flex flex-col items-center gap-3 rounded-xl border border-dashed border-border bg-muted/10 py-14 text-center">
          <BellOff className="h-10 w-10 text-muted-foreground/15" />
          <div>
            <p className="text-sm font-medium text-muted-foreground">
              {hasActiveFilter ? 'No matching notifications' : 'No notifications yet'}
            </p>
            <p className="mt-0.5 text-[11px] text-muted-foreground/70">
              {hasActiveFilter ? 'Try adjusting your filters.' : 'New operational alerts will appear here in realtime.'}
            </p>
          </div>
        </div>
      ) : viewMode === 'table' ? (
        <div className="rounded-lg border border-border bg-card overflow-x-auto">
          <table className="min-w-full text-left text-[11px]">
            <thead>
              <tr className="border-b border-border bg-muted/30">
                <th className="px-3 py-2.5 font-bold uppercase tracking-wider text-muted-foreground">Title</th>
                <th className="px-3 py-2.5 font-bold uppercase tracking-wider text-muted-foreground hidden md:table-cell">Message</th>
                <th className="px-3 py-2.5 font-bold uppercase tracking-wider text-muted-foreground hidden sm:table-cell">User</th>
                <th className="px-3 py-2.5 font-bold uppercase tracking-wider text-muted-foreground">Date</th>
                <th className="px-3 py-2.5 font-bold uppercase tracking-wider text-muted-foreground">Status</th>
                <th className="px-3 py-2.5 text-right font-bold uppercase tracking-wider text-muted-foreground">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/40">
              {notifications.map((n) => (
                <tr key={n.id} className="hover:bg-muted/20">
                  <td className="px-3 py-2.5">
                    <p className={`font-semibold ${n.read ? 'text-foreground' : 'text-accent'}`}>{n.title}</p>
                    <span className="text-[9px] uppercase text-muted-foreground">{n.category}</span>
                  </td>
                  <td className="px-3 py-2.5 hidden md:table-cell text-muted-foreground max-w-xs truncate">{n.message}</td>
                  <td className="px-3 py-2.5 hidden sm:table-cell text-foreground">{n.createdByUser?.fullName || n.createdByUser?.username || '—'}</td>
                  <td className="px-3 py-2.5 whitespace-nowrap text-muted-foreground">{new Date(n.createdAt).toLocaleString(undefined, { dateStyle: 'short', timeStyle: 'short' })}</td>
                  <td className="px-3 py-2.5">
                    <span className={`rounded px-1.5 py-0.5 text-[9px] font-bold uppercase ${n.read ? 'bg-muted text-muted-foreground' : 'bg-accent/10 text-accent'}`}>{n.read ? 'Read' : 'Unread'}</span>
                  </td>
                  <td className="px-3 py-2.5 text-right">
                    {!n.read && (
                      <button type="button" onClick={() => markRead.mutate(n.id)} className="text-[10px] font-medium text-accent hover:underline">Mark read</button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="space-y-1.5">
          {notifications.map((n) => (
            <NotificationCard
              key={n.id}
              notification={n}
              onMarkRead={(id) => markRead.mutate(id)}
              onDelete={(id) => remove.mutate(id)}
            />
          ))}
        </div>
      )}

      {/* ── Pagination ── */}
      {pagination.pages > 1 && (
        <div className="flex items-center justify-between pt-1">
          <p className="text-[10px] text-muted-foreground tabular-nums">
            Page {pagination.page} of {pagination.pages} · {pagination.total} notifications
          </p>
          <div className="flex gap-1">
            <button type="button" disabled={page <= 1} onClick={() => setPage((p) => Math.max(1, p - 1))} className="inline-flex items-center gap-1 rounded-md border border-border px-2 py-1 text-[11px] font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground disabled:opacity-40">
              <ChevronLeft className="h-3 w-3" /> Prev
            </button>
            <button type="button" disabled={page >= pagination.pages} onClick={() => setPage((p) => p + 1)} className="inline-flex items-center gap-1 rounded-md border border-border px-2 py-1 text-[11px] font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground disabled:opacity-40">
              Next <ChevronRight className="h-3 w-3" />
            </button>
          </div>
        </div>
      )}

      {/* ── Footer ── */}
      {notifications.length > 0 && (
        <p className="text-[10px] text-muted-foreground">
          {notifications.length === allNotifications.length
            ? `${allNotifications.length} notifications on this page`
            : `${notifications.length} of ${allNotifications.length} (filtered)`}
        </p>
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   SUB-COMPONENTS
   ═══════════════════════════════════════════════════════════════ */

function KpiMini({ label, value, icon: Icon, color, bg, active, onClick }) {
  return (
    <button type="button" onClick={onClick} disabled={!onClick} className={`rounded-lg border bg-card px-2 py-2 text-left transition ${active ? 'border-accent ring-1 ring-accent/20' : 'border-border hover:border-border'} ${onClick ? 'cursor-pointer hover:shadow-sm' : 'cursor-default'}`}>
      <div className="flex items-center gap-1.5">
        <div className={`flex h-4.5 w-4.5 items-center justify-center rounded ${bg}`}>
          <Icon className={`h-2.5 w-2.5 ${color}`} strokeWidth={2.5} />
        </div>
        <span className="text-[8px] font-bold uppercase tracking-wider text-muted-foreground">{label}</span>
      </div>
      <p className={`mt-0.5 text-base font-bold tabular-nums leading-tight ${color}`}>{fmt(value)}</p>
    </button>
  );
}

function LoadingSkeleton() {
  return (
    <div className="space-y-2">
      {Array.from({ length: 5 }).map((_, i) => (
        <div key={i} className="h-16 animate-pulse rounded-lg bg-muted/30" />
      ))}
    </div>
  );
}
