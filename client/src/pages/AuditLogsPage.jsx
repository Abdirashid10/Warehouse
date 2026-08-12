import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Activity,
  AlertTriangle,
  ArrowRightLeft,
  Boxes,
  ChevronLeft,
  ChevronRight as ChevRight,
  ClipboardList,
  Clock,
  Filter,
  Loader2,
  Package,
  Search,
  Shield,
  ShoppingCart,
  User,
  Users,
  Warehouse,
  X,
} from 'lucide-react';
import { api } from '../api/client';

/* ─── API ─── */

async function fetchActivities(params) {
  const { data } = await api.get('/audit/activities', { params });
  return data;
}

/* ─── Helpers ─── */

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

function fullDate(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' });
}

function fmt(n) { return Number(n || 0).toLocaleString(); }

const MODULE_META = {
  inventory: { icon: Package, label: 'Inventory', color: 'text-emerald-600 dark:text-emerald-400', bg: 'bg-emerald-50 dark:bg-emerald-500/10' },
  warehouse: { icon: Warehouse, label: 'Warehouse', color: 'text-sky-600 dark:text-sky-400', bg: 'bg-sky-50 dark:bg-sky-500/10' },
  order: { icon: ShoppingCart, label: 'Orders', color: 'text-blue-600 dark:text-blue-400', bg: 'bg-blue-50 dark:bg-blue-500/10' },
  task: { icon: ClipboardList, label: 'Tasks', color: 'text-violet-600 dark:text-violet-400', bg: 'bg-violet-50 dark:bg-violet-500/10' },
  user: { icon: Users, label: 'Users', color: 'text-orange-600 dark:text-orange-400', bg: 'bg-orange-50 dark:bg-orange-500/10' },
  profile: { icon: User, label: 'Profile', color: 'text-slate-600 dark:text-slate-400', bg: 'bg-slate-50 dark:bg-slate-500/10' },
  movement: { icon: ArrowRightLeft, label: 'Movement', color: 'text-cyan-600 dark:text-cyan-400', bg: 'bg-cyan-50 dark:bg-cyan-500/10' },
  system: { icon: Shield, label: 'System', color: 'text-rose-600 dark:text-rose-400', bg: 'bg-rose-50 dark:bg-rose-500/10' },
};

function getModuleMeta(mod) {
  const key = (mod || '').toLowerCase();
  return MODULE_META[key] || { icon: Activity, label: mod || 'Other', color: 'text-muted-foreground', bg: 'bg-muted' };
}

const ROLE_BADGE = {
  Admin: 'bg-red-100 text-red-700 dark:bg-red-500/15 dark:text-red-400',
  Supervisor: 'bg-amber-100 text-amber-700 dark:bg-amber-500/15 dark:text-amber-400',
  Staff: 'bg-sky-100 text-sky-700 dark:bg-sky-500/15 dark:text-sky-400',
};

const MODULE_OPTIONS = [
  { value: 'inventory', label: 'Inventory' },
  { value: 'movement', label: 'Movement' },
  { value: 'warehouse', label: 'Warehouse' },
  { value: 'order', label: 'Orders' },
  { value: 'task', label: 'Tasks' },
  { value: 'user', label: 'Users' },
  { value: 'profile', label: 'Profile' },
];

/** KPI tiles, in display order. Rendered only when the role may read them. */
const MODULE_KPIS = [
  { key: 'inventory', label: 'Inventory', icon: Package, color: 'text-emerald-600 dark:text-emerald-400', bg: 'bg-emerald-50 dark:bg-emerald-500/10' },
  { key: 'warehouse', label: 'Warehouse', icon: Warehouse, color: 'text-sky-600 dark:text-sky-400', bg: 'bg-sky-50 dark:bg-sky-500/10' },
  { key: 'task', label: 'Tasks', icon: ClipboardList, color: 'text-violet-600 dark:text-violet-400', bg: 'bg-violet-50 dark:bg-violet-500/10' },
  { key: 'order', label: 'Orders', icon: ShoppingCart, color: 'text-blue-600 dark:text-blue-400', bg: 'bg-blue-50 dark:bg-blue-500/10' },
  { key: 'user', label: 'Users', icon: Users, color: 'text-orange-600 dark:text-orange-400', bg: 'bg-orange-50 dark:bg-orange-500/10' },
];

/* Literal class names so Tailwind's scanner keeps them. */
const KPI_GRID_COLS = {
  2: 'sm:grid-cols-2',
  3: 'sm:grid-cols-3',
  4: 'sm:grid-cols-4',
  5: 'sm:grid-cols-5',
  6: 'sm:grid-cols-6',
};

/** Mirrors server MODULE_ALIASES → canonical keys for KPI fallbacks. */
const MODULE_KEY_LOOKUP = {
  inventory: 'inventory',
  warehouse: 'warehouse',
  order: 'order',
  orders: 'order',
  task: 'task',
  tasks: 'task',
  user: 'user',
  'user management': 'user',
  profile: 'profile',
  system: 'system',
  movement: 'movement',
};

function normalizeModuleKey(moduleValue) {
  if (!moduleValue) return null;
  const trimmed = String(moduleValue).trim();
  if (!trimmed) return null;
  return MODULE_KEY_LOOKUP[trimmed.toLowerCase()] || trimmed.toLowerCase();
}

/* ═══════════════════════════════════════════════════════════════
   MAIN EXPORT
   ═══════════════════════════════════════════════════════════════ */

export function AuditLogsPage() {
  const [searchQ, setSearchQ] = useState('');
  const [moduleFilter, setModuleFilter] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [showFilters, setShowFilters] = useState(false);
  const [page, setPage] = useState(1);
  const [expanded, setExpanded] = useState(null);

  const queryParams = useMemo(() => {
    const p = { page, limit: 50 };
    if (moduleFilter) p.module = moduleFilter;
    if (searchQ) p.q = searchQ;
    if (dateFrom) p.from = dateFrom;
    if (dateTo) p.to = dateTo;
    return p;
  }, [page, moduleFilter, searchQ, dateFrom, dateTo]);

  const { data, isLoading, isError, isFetching } = useQuery({
    queryKey: ['audit', 'activities', queryParams],
    queryFn: () => fetchActivities(queryParams),
    staleTime: 10_000,
    keepPreviousData: true,
  });

  const activities = data?.activities || [];
  const pagination = data?.pagination || { page: 1, pages: 1, total: 0 };
  const moduleCounts = data?.moduleCounts || {};

  /* The API decides what this role may read; `null` means unrestricted (Admin).
     Anything not listed — User Management above all — is never offered here. */
  const visibleModules = data?.visibleModules ?? null;
  const canSeeModule = (key) => visibleModules === null || visibleModules.includes(key);

  const kpiCards = MODULE_KPIS.filter((m) => canSeeModule(m.key));
  const moduleOptions = MODULE_OPTIONS.filter((o) => canSeeModule(o.value));

  const pageCategoryCounts = useMemo(() => {
    const c = { inventory: 0, warehouse: 0, order: 0, task: 0, user: 0, profile: 0 };
    activities.forEach((a) => {
      const k = normalizeModuleKey(a.module);
      if (k && c[k] !== undefined) c[k]++;
    });
    return c;
  }, [activities]);

  const hasFilter = searchQ || moduleFilter || dateFrom || dateTo;

  function handleSearch(val) {
    setSearchQ(val);
    setPage(1);
  }

  function handleModuleFilter(val) {
    setModuleFilter(val === moduleFilter ? '' : val);
    setPage(1);
  }

  return (
    <div className="space-y-4 px-1">

      {/* ── Header ── */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-lg font-bold text-foreground">Audit & Activity Logs</h1>
          <p className="text-xs text-muted-foreground">
            Operational traceability & user accountability · {fmt(pagination.total)} activities logged
            {isFetching && !isLoading ? ' · Refreshing…' : ''}
          </p>
        </div>
      </div>

      {/* ── KPI Cards ── */}
      <div className={`grid grid-cols-3 gap-2 ${KPI_GRID_COLS[kpiCards.length + 1] || 'sm:grid-cols-6'}`}>
        <KpiMini label="Total" value={fmt(pagination.total)} icon={Activity} color="text-sky-600 dark:text-sky-400" bg="bg-sky-50 dark:bg-sky-500/10" />
        {kpiCards.map((m) => (
          <KpiMini
            key={m.key}
            label={m.label}
            value={moduleCounts[m.key] || pageCategoryCounts[m.key] || 0}
            icon={m.icon}
            color={m.color}
            bg={m.bg}
            active={moduleFilter === m.key}
            onClick={() => handleModuleFilter(m.key)}
          />
        ))}
      </div>

      {/* ── Search + Filters ── */}
      <div className="flex items-center gap-2">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
          <input type="text" value={searchQ} onChange={(e) => handleSearch(e.target.value)} placeholder="Search actions, modules, details…" className="wms-input h-8 w-full pl-8 text-xs" />
        </div>
        <button type="button" onClick={() => setShowFilters(!showFilters)} className={`inline-flex items-center gap-1 rounded-md border px-2 py-1.5 text-[11px] font-medium transition ${showFilters ? 'border-accent bg-accent/5 text-accent' : 'border-border text-muted-foreground hover:bg-muted hover:text-foreground'}`}>
          <Filter className="h-3 w-3" /> Filters
        </button>
        {hasFilter && (
          <button type="button" onClick={() => { setSearchQ(''); setModuleFilter(''); setDateFrom(''); setDateTo(''); setPage(1); }} className="inline-flex items-center gap-1 rounded-md border border-border px-2 py-1.5 text-[11px] font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground">
            <X className="h-3 w-3" /> Clear
          </button>
        )}
      </div>

      {/* Advanced filters */}
      {showFilters && (
        <div className="flex flex-wrap gap-3 rounded-lg border border-border/60 bg-muted/10 px-3 py-2.5">
          <div className="flex items-center gap-1">
            <span className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground mr-1">Module:</span>
            <select value={moduleFilter} onChange={(e) => { setModuleFilter(e.target.value); setPage(1); }} className="rounded-md border border-border bg-card px-2 py-1 text-[10px] font-medium text-foreground">
              <option value="">All Modules</option>
              {moduleOptions.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          </div>
          <div className="flex items-center gap-1">
            <span className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground mr-1">From:</span>
            <input type="date" value={dateFrom} onChange={(e) => { setDateFrom(e.target.value); setPage(1); }} className="rounded-md border border-border bg-card px-2 py-1 text-[10px]" />
          </div>
          <div className="flex items-center gap-1">
            <span className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground mr-1">To:</span>
            <input type="date" value={dateTo} onChange={(e) => { setDateTo(e.target.value); setPage(1); }} className="rounded-md border border-border bg-card px-2 py-1 text-[10px]" />
          </div>
        </div>
      )}

      {/* ── Activity Feed ── */}
      {isLoading ? (
        <LoadingSkeleton />
      ) : isError ? (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-3 text-xs text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">Failed to load audit logs.</div>
      ) : activities.length === 0 ? (
        <div className="flex flex-col items-center gap-3 rounded-xl border border-dashed border-border bg-muted/10 py-14 text-center">
          <Shield className="h-10 w-10 text-muted-foreground/15" />
          <div>
            <p className="text-sm font-medium text-muted-foreground">{hasFilter ? 'No matching activities' : 'No activities logged yet'}</p>
            <p className="mt-0.5 text-[11px] text-muted-foreground/70">{hasFilter ? 'Try adjusting your filters.' : 'System operations will be recorded here automatically.'}</p>
          </div>
        </div>
      ) : (
        <div className="rounded-lg border border-border bg-card overflow-x-auto">
          <table className="min-w-full text-left text-[11px]">
            <thead>
              <tr className="border-b border-border bg-muted/30">
                <th className="w-8 px-2 py-2.5" />
                <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Module</th>
                <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Action</th>
                <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden sm:table-cell">User</th>
                <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden md:table-cell">Role</th>
                <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden lg:table-cell">Details</th>
                <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground text-right">Time</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/40">
              {activities.map((a) => {
                const isExp = expanded === a.id;
                return <AuditRow key={a.id} activity={a} isExpanded={isExp} onToggle={() => setExpanded(isExp ? null : a.id)} />;
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* ── Pagination ── */}
      {pagination.pages > 1 && (
        <div className="flex items-center justify-between pt-1">
          <p className="text-[10px] text-muted-foreground tabular-nums">
            Page {pagination.page} of {pagination.pages} · {fmt(pagination.total)} activities
          </p>
          <div className="flex gap-1">
            <button type="button" disabled={page <= 1} onClick={() => setPage((p) => Math.max(1, p - 1))} className="inline-flex items-center gap-1 rounded-md border border-border px-2 py-1 text-[11px] font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground disabled:opacity-40">
              <ChevronLeft className="h-3 w-3" /> Prev
            </button>
            <button type="button" disabled={page >= pagination.pages} onClick={() => setPage((p) => p + 1)} className="inline-flex items-center gap-1 rounded-md border border-border px-2 py-1 text-[11px] font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground disabled:opacity-40">
              Next <ChevRight className="h-3 w-3" />
            </button>
          </div>
        </div>
      )}

      {/* ── Footer ── */}
      {activities.length > 0 && (
        <p className="text-[10px] text-muted-foreground">
          Showing {activities.length} activities on this page
          {Object.entries(moduleCounts).length > 0 && (
            <> · {Object.entries(moduleCounts).map(([m, c]) => `${m}: ${c}`).join(' · ')}</>
          )}
        </p>
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   AUDIT TABLE ROW
   ═══════════════════════════════════════════════════════════════ */

function AuditRow({ activity, isExpanded, onToggle }) {
  const a = activity;
  const meta = getModuleMeta(a.module);
  const Icon = meta.icon;
  const actorName = a.actor?.fullName || a.actor?.username || '—';
  const actorRole = a.actor?.role || '';

  return (
    <>
      <tr className="transition hover:bg-muted/20 cursor-pointer" onClick={onToggle}>
        <td className="px-2 py-2">
          <ChevRight className={`h-3 w-3 text-muted-foreground transition-transform ${isExpanded ? 'rotate-90' : ''}`} />
        </td>
        <td className="px-3 py-2">
          <div className="flex items-center gap-1.5">
            <div className={`flex h-5 w-5 items-center justify-center rounded ${meta.bg}`}>
              <Icon className={`h-3 w-3 ${meta.color}`} />
            </div>
            <span className={`text-[10px] font-bold uppercase tracking-wider ${meta.color}`}>{meta.label}</span>
          </div>
        </td>
        <td className="px-3 py-2">
          <p className="text-xs font-semibold text-foreground">{a.action}</p>
        </td>
        <td className="px-3 py-2 hidden sm:table-cell">
          <div className="flex items-center gap-1.5">
            <div className="flex h-5 w-5 items-center justify-center rounded-full bg-muted text-[9px] font-bold text-muted-foreground">
              {(actorName[0] || '?').toUpperCase()}
            </div>
            <span className="text-xs text-foreground">{actorName}</span>
          </div>
        </td>
        <td className="px-3 py-2 hidden md:table-cell">
          {actorRole && <span className={`inline-block rounded px-1.5 py-0.5 text-[8px] font-bold ${ROLE_BADGE[actorRole] || 'bg-muted text-muted-foreground'}`}>{actorRole}</span>}
        </td>
        <td className="px-3 py-2 hidden lg:table-cell">
          <p className="text-[10px] text-muted-foreground truncate max-w-[240px]">{a.details || '—'}</p>
        </td>
        <td className="px-3 py-2 text-right">
          <span className="text-[10px] text-muted-foreground whitespace-nowrap">{relDate(a.createdAt)}</span>
        </td>
      </tr>
      {isExpanded && (
        <tr>
          <td colSpan={7} className="bg-muted/10 px-4 py-3">
            <div className="grid grid-cols-2 gap-x-6 gap-y-2 text-[11px] sm:grid-cols-3 lg:grid-cols-4">
              <DetailField label="Action" value={a.action} />
              <DetailField label="Module" value={a.module} />
              <DetailField label="Performed By" value={actorName} />
              <DetailField label="Role" value={actorRole || '—'} />
              <DetailField label="Date & Time" value={fullDate(a.createdAt)} />
              {a.target && <DetailField label="Target User" value={`${a.target.fullName || a.target.username} (${a.target.role || '—'})`} />}
              {a.entityLabel && <DetailField label="Entity" value={`${a.entityType || '—'}: ${a.entityLabel}`} />}
              {a.beforeValue && <DetailField label="Before" value={formatAuditValue(a.beforeValue)} />}
              {a.afterValue && <DetailField label="After" value={formatAuditValue(a.afterValue)} />}
              {a.ipAddress && <DetailField label="IP Address" value={a.ipAddress} />}
              {a.details && <div className="col-span-full"><DetailField label="Details" value={a.details} /></div>}
            </div>
          </td>
        </tr>
      )}
    </>
  );
}

/* ═══════════════════════════════════════════════════════════════
   SUB-COMPONENTS
   ═══════════════════════════════════════════════════════════════ */

function KpiMini({ label, value, icon: Icon, color, bg, active, onClick }) {
  return (
    <button type="button" onClick={onClick} disabled={!onClick} className={`rounded-lg border bg-card px-2 py-2 text-left transition ${active ? 'border-accent ring-1 ring-accent/20' : 'border-border'} ${onClick ? 'cursor-pointer hover:shadow-sm' : 'cursor-default'}`}>
      <div className="flex items-center gap-1.5">
        <div className={`flex h-4.5 w-4.5 items-center justify-center rounded ${bg}`}>
          <Icon className={`h-2.5 w-2.5 ${color}`} strokeWidth={2.5} />
        </div>
        <span className="text-[8px] font-bold uppercase tracking-wider text-muted-foreground">{label}</span>
      </div>
      <p className={`mt-0.5 text-base font-bold tabular-nums leading-tight ${color}`}>{value}</p>
    </button>
  );
}

function DetailField({ label, value }) {
  return (
    <div>
      <p className="text-[9px] font-semibold uppercase tracking-wider text-muted-foreground">{label}</p>
      <p className="text-xs text-foreground break-words">{value ?? '—'}</p>
    </div>
  );
}

function formatAuditValue(raw) {
  if (!raw) return '—';
  try {
    const parsed = JSON.parse(raw);
    if (typeof parsed === 'object') {
      return Object.entries(parsed).map(([k, v]) => `${k}: ${v}`).join(' · ');
    }
    return String(parsed);
  } catch {
    return raw;
  }
}

function LoadingSkeleton() {
  return (
    <div className="space-y-2">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="h-12 animate-pulse rounded-lg bg-muted/30" />
      ))}
    </div>
  );
}
