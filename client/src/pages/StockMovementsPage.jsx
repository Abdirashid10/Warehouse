import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { CreatedByCell } from '../components/CreatedByCell';
import { MovementTypeBadge } from '../components/MovementTypeBadge';
import { MovementQuantityCell } from '../components/MovementQuantityCell';
import {
  movementFromLocation,
  movementToLocation,
  resolveSignedQuantity,
} from '../utils/movementHelpers';
import { formatPerformerDisplay, performerSearchText } from '../utils/performerDisplay';
import {
  ArrowDownToLine,
  ArrowRight,
  ArrowRightLeft,
  ArrowUpFromLine,
  Box,
  ChevronDown,
  ChevronUp,
  ClipboardList,
  Loader2,
  Package,
  Plus,
  RotateCcw,
  Search,
  SlidersHorizontal,
  User,
  Warehouse,
} from 'lucide-react';

/* ─── API ─── */

async function fetchMovements() {
  const { data } = await api.get('/inventory/movements', { params: { limit: 300 } });
  return data;
}

async function fetchWarehouses() {
  const { data } = await api.get('/inventory/warehouses');
  return data;
}

/* ─── Helpers ─── */

function relDate(iso) {
  if (!iso) return '—';
  const diff = Date.now() - new Date(iso).getTime();
  const m = Math.floor(diff / 60_000);
  if (m < 1) return 'just now';
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  if (d < 7) return `${d}d ago`;
  return new Date(iso).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

function fmtDate(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' });
}

const TYPE_ICONS = {
  INBOUND: ArrowDownToLine,
  OUTBOUND: ArrowUpFromLine,
  TRANSFER: ArrowRightLeft,
  ADJUSTMENT: Box,
  RETURN: RotateCcw,
};

const TYPE_COLORS = {
  INBOUND: 'text-emerald-600 dark:text-emerald-400',
  OUTBOUND: 'text-orange-600 dark:text-orange-400',
  TRANSFER: 'text-sky-600 dark:text-sky-400',
  ADJUSTMENT: 'text-amber-600 dark:text-amber-400',
  RETURN: 'text-teal-600 dark:text-teal-400',
};

const TYPE_BG = {
  INBOUND: 'bg-emerald-50 dark:bg-emerald-500/10',
  OUTBOUND: 'bg-orange-50 dark:bg-orange-500/10',
  TRANSFER: 'bg-sky-50 dark:bg-sky-500/10',
  ADJUSTMENT: 'bg-amber-50 dark:bg-amber-500/10',
  RETURN: 'bg-teal-50 dark:bg-teal-500/10',
};

const SORT_FIELDS = ['date', 'type', 'product', 'quantity'];

function sortRows(rows, field, dir) {
  if (!field) return rows;
  return [...rows].sort((a, b) => {
    let va, vb;
    switch (field) {
      case 'date': va = new Date(a.createdAt || 0).getTime(); vb = new Date(b.createdAt || 0).getTime(); break;
      case 'type': va = a.type || ''; vb = b.type || ''; break;
      case 'product': va = (a.productId?.name || '').toLowerCase(); vb = (b.productId?.name || '').toLowerCase(); break;
      case 'quantity': va = Math.abs(resolveSignedQuantity(a)); vb = Math.abs(resolveSignedQuantity(b)); break;
      default: return 0;
    }
    if (va < vb) return dir === 'asc' ? -1 : 1;
    if (va > vb) return dir === 'asc' ? 1 : -1;
    return 0;
  });
}

/* ═══════════════════════════════════════════════════════════════
   MAIN EXPORT
   ═══════════════════════════════════════════════════════════════ */

export function StockMovementsPage() {
  const queryClient = useQueryClient();
  const { user } = useAuth();
  const canManage = user?.role === 'Admin' || user?.role === 'Supervisor';

  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [warehouseFilter, setWarehouseFilter] = useState('');
  const [showFilters, setShowFilters] = useState(false);
  const [sortField, setSortField] = useState('date');
  const [sortDir, setSortDir] = useState('desc');
  const [expanded, setExpanded] = useState(null);

  const { data, isLoading, isError, error, refetch } = useQuery({
    queryKey: ['movements', 'list'],
    queryFn: fetchMovements,
    refetchOnWindowFocus: true,
  });

  const { data: whData } = useQuery({
    queryKey: ['warehouses'],
    queryFn: fetchWarehouses,
    staleTime: 120_000,
  });

  const rows = data?.movements || [];
  const warehouses = whData?.warehouses || [];

  /* ── Derived data ── */
  const stats = useMemo(() => {
    const s = { total: rows.length, INBOUND: 0, OUTBOUND: 0, TRANSFER: 0, ADJUSTMENT: 0, RETURN: 0 };
    rows.forEach((m) => { if (s[m.type] !== undefined) s[m.type]++; });
    s.inbound = s.INBOUND + s.RETURN;
    return s;
  }, [rows]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return rows.filter((m) => {
      if (typeFilter && m.type !== typeFilter) return false;
      if (warehouseFilter) {
        const whId = m.warehouseId?._id || m.warehouseId?.id || '';
        const fwId = m.from_warehouse?._id || m.from_warehouse?.id || '';
        const twId = m.to_warehouse?._id || m.to_warehouse?.id || '';
        if (whId !== warehouseFilter && fwId !== warehouseFilter && twId !== warehouseFilter) return false;
      }
      if (!q) return true;
      const hay = [
        m.type, m.productId?.sku, m.productId?.name,
        m.warehouseId?.name, m.from_warehouse?.name, m.to_warehouse?.name,
        m.source_location, m.destination_location,
        m.reason, performerSearchText(m.created_by), performerSearchText(m.performed_by),
      ].filter(Boolean).join(' ').toLowerCase();
      return hay.includes(q);
    });
  }, [rows, search, typeFilter, warehouseFilter]);

  const sorted = useMemo(() => sortRows(filtered, sortField, sortDir), [filtered, sortField, sortDir]);

  const seedMutation = useMutation({
    mutationFn: () => api.post('/inventory/seed-sample'),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['movements', 'list'] });
      queryClient.invalidateQueries({ queryKey: ['inventory'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard', 'stats'] });
    },
  });

  function toggleSort(field) {
    if (sortField === field) setSortDir((d) => d === 'asc' ? 'desc' : 'asc');
    else { setSortField(field); setSortDir(field === 'date' ? 'desc' : 'asc'); }
  }

  const activeFilters = [typeFilter, warehouseFilter].filter(Boolean).length;

  /* ═══ Render ═══ */
  return (
    <div className="space-y-4 px-1">

      {/* ── Header ── */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-lg font-bold text-foreground">{user?.role === 'Staff' ? 'Stock Operations' : 'Stock Movements'}</h1>
          <p className="text-xs text-muted-foreground">Complete audit trail · {stats.total} operations tracked</p>
        </div>
        {canManage && rows.length === 0 && (
          <button type="button" disabled={seedMutation.isPending} onClick={() => seedMutation.mutate()} className="rounded-lg border border-border px-3 py-1.5 text-xs font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground disabled:opacity-50 shrink-0">
            {seedMutation.isPending ? 'Seeding…' : 'Seed Sample'}
          </button>
        )}
      </div>

      {/* ── KPI Cards ── */}
      <div className="grid grid-cols-3 gap-2 sm:grid-cols-5">
        {[
          { key: '', label: 'Total', value: stats.total, icon: Box, color: 'text-slate-600 dark:text-slate-300', bg: 'bg-slate-100 dark:bg-slate-700/60' },
          { key: 'INBOUND', label: 'Inbound', value: stats.inbound, icon: ArrowDownToLine, color: TYPE_COLORS.INBOUND, bg: TYPE_BG.INBOUND },
          { key: 'OUTBOUND', label: 'Outbound', value: stats.OUTBOUND, icon: ArrowUpFromLine, color: TYPE_COLORS.OUTBOUND, bg: TYPE_BG.OUTBOUND },
          { key: 'TRANSFER', label: 'Transfers', value: stats.TRANSFER, icon: ArrowRightLeft, color: TYPE_COLORS.TRANSFER, bg: TYPE_BG.TRANSFER },
          { key: 'ADJUSTMENT', label: 'Adjustments', value: stats.ADJUSTMENT, icon: Box, color: TYPE_COLORS.ADJUSTMENT, bg: TYPE_BG.ADJUSTMENT },
        ].map(({ key, label, value, icon: Icon, color, bg }) => {
          const active = typeFilter === key;
          return (
            <button key={label} type="button" onClick={() => setTypeFilter(active ? '' : key)} className={`rounded-lg border px-2.5 py-2 text-left transition ${active ? 'border-accent bg-accent/5 ring-1 ring-accent/20' : 'border-border bg-card hover:shadow-sm'}`}>
              <div className="flex items-center gap-1.5">
                <div className={`flex h-5 w-5 items-center justify-center rounded ${bg}`}>
                  <Icon className={`h-3 w-3 ${color}`} strokeWidth={2.2} />
                </div>
                <span className="text-[9px] font-semibold uppercase tracking-wider text-muted-foreground">{label}</span>
              </div>
              <p className={`mt-0.5 text-lg font-bold tabular-nums leading-tight ${color}`}>{value}</p>
            </button>
          );
        })}
      </div>

      {/* ── Filters Bar ── */}
      <div className="flex flex-wrap items-center gap-2">
        <div className="relative flex-1 min-w-[180px] max-w-sm">
          <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
          <input type="text" value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search product, SKU, warehouse, staff…" className="wms-input h-8 w-full pl-8 text-xs" />
        </div>

        {/* Type pills */}
        <div className="flex items-center gap-1">
          <button type="button" onClick={() => setTypeFilter('')} className={`rounded-md px-2 py-1 text-[11px] font-semibold transition ${!typeFilter ? 'bg-accent text-white' : 'bg-muted/50 text-muted-foreground hover:text-foreground'}`}>All</button>
          {['INBOUND', 'OUTBOUND', 'TRANSFER', 'ADJUSTMENT', 'RETURN'].map((t) => {
            const c = stats[t] || 0;
            if (c === 0 && typeFilter !== t) return null;
            return (
              <button key={t} type="button" onClick={() => setTypeFilter(typeFilter === t ? '' : t)} className={`rounded-md px-2 py-1 text-[11px] font-semibold transition ${typeFilter === t ? 'bg-accent text-white' : 'bg-muted/50 text-muted-foreground hover:text-foreground'}`}>
                {t} {c}
              </button>
            );
          })}
        </div>

        <button type="button" onClick={() => setShowFilters(!showFilters)} className={`inline-flex items-center gap-1 rounded-md border px-2 py-1 text-[11px] font-medium transition ${showFilters || activeFilters > 0 ? 'border-accent bg-accent/5 text-accent' : 'border-border text-muted-foreground hover:text-foreground'}`}>
          <SlidersHorizontal className="h-3 w-3" /> Filters{activeFilters > 0 ? ` (${activeFilters})` : ''}
        </button>
      </div>

      {/* ── Advanced Filters ── */}
      {showFilters && (
        <div className="flex flex-wrap items-center gap-2 rounded-lg border border-border/60 bg-muted/10 px-3 py-2">
          <select value={warehouseFilter} onChange={(e) => setWarehouseFilter(e.target.value)} className="wms-input h-7 text-[11px] min-w-[130px]">
            <option value="">All Warehouses</option>
            {warehouses.map((w) => <option key={w._id} value={w._id}>{w.name}</option>)}
          </select>
          {(typeFilter || warehouseFilter) && (
            <button type="button" onClick={() => { setTypeFilter(''); setWarehouseFilter(''); }} className="text-[11px] font-medium text-accent hover:underline">Clear all</button>
          )}
        </div>
      )}

      {/* ── Main Table ── */}
      {isLoading ? (
        <LoadingSkeleton />
      ) : isError ? (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-3 text-xs text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
          {error?.response?.data?.message || 'Failed to load movements.'}
          <button type="button" onClick={() => refetch()} className="ml-2 font-semibold underline">Retry</button>
        </div>
      ) : sorted.length === 0 ? (
        <div className="flex flex-col items-center gap-3 rounded-xl border border-dashed border-border bg-muted/10 py-14 text-center">
          <ArrowRightLeft className="h-10 w-10 text-muted-foreground/20" />
          <div>
            <p className="text-sm font-medium text-muted-foreground">{search || typeFilter || warehouseFilter ? 'No movements match your filters' : 'No stock movements yet'}</p>
            <p className="mt-0.5 text-[11px] text-muted-foreground/70">
              {search || typeFilter ? 'Try adjusting your search or filter criteria.' : 'Record stock from Inventory Tracking to begin.'}
            </p>
          </div>
        </div>
      ) : (
        <div className="overflow-hidden rounded-lg border border-border">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <SortTh label="Type" field="type" sortField={sortField} sortDir={sortDir} onSort={toggleSort} className="pl-3 w-24" />
                  <SortTh label="Product" field="product" sortField={sortField} sortDir={sortDir} onSort={toggleSort} />
                  <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden sm:table-cell">Route</th>
                  <SortTh label="Qty" field="quantity" sortField={sortField} sortDir={sortDir} onSort={toggleSort} align="right" />
                  <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden md:table-cell">Performed By</th>
                  <SortTh label="Date" field="date" sortField={sortField} sortDir={sortDir} onSort={toggleSort} className="hidden lg:table-cell" />
                  <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden xl:table-cell">Notes</th>
                  <th className="px-3 py-2.5 w-8" />
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40">
                {sorted.map((m) => {
                  const id = m.id || m._id;
                  const TypeIcon = TYPE_ICONS[m.type] || Box;
                  const typeColor = TYPE_COLORS[m.type] || 'text-slate-500';
                  const fromLoc = movementFromLocation(m);
                  const toLoc = movementToLocation(m);
                  const isExpanded = expanded === id;
                  const hasTask = Boolean(m.taskId);

                  return (
                    <tr key={id} className={`group transition ${isExpanded ? 'bg-muted/20' : 'hover:bg-muted/10'}`}>
                      {/* Type */}
                      <td className="px-3 py-2.5 pl-3">
                        <div className="flex items-center gap-2">
                          <div className={`flex h-6 w-6 items-center justify-center rounded-md ${TYPE_BG[m.type] || 'bg-muted'}`}>
                            <TypeIcon className={`h-3 w-3 ${typeColor}`} strokeWidth={2.2} />
                          </div>
                          <span className={`text-[11px] font-bold uppercase ${typeColor}`}>{m.type}</span>
                        </div>
                      </td>

                      {/* Product */}
                      <td className="px-3 py-2.5">
                        <p className="font-semibold text-foreground leading-tight">{m.productId?.name || '—'}</p>
                        <p className="mt-0.5 text-[10px] text-muted-foreground font-mono">{m.productId?.sku || '—'}</p>
                      </td>

                      {/* Route */}
                      <td className="px-3 py-2.5 hidden sm:table-cell">
                        {m.type === 'TRANSFER' ? (
                          <div className="flex items-center gap-1.5 text-[11px]">
                            <span className="inline-flex items-center gap-0.5 rounded border border-blue-200/60 bg-blue-50/60 px-1.5 py-px font-medium text-blue-700 dark:border-blue-500/25 dark:bg-blue-500/10 dark:text-blue-300">
                              <Warehouse className="h-2.5 w-2.5" /> {fromLoc}
                            </span>
                            <ArrowRight className="h-3 w-3 text-muted-foreground shrink-0" />
                            <span className="inline-flex items-center gap-0.5 rounded border border-emerald-200/60 bg-emerald-50/60 px-1.5 py-px font-medium text-emerald-700 dark:border-emerald-500/25 dark:bg-emerald-500/10 dark:text-emerald-300">
                              <Warehouse className="h-2.5 w-2.5" /> {toLoc}
                            </span>
                          </div>
                        ) : (
                          <div className="text-[11px]">
                            <span className="inline-flex items-center gap-0.5 text-muted-foreground">
                              <Warehouse className="h-2.5 w-2.5" />
                              <span className="font-medium text-foreground">{m.type === 'INBOUND' || m.type === 'RETURN' ? toLoc : fromLoc}</span>
                            </span>
                          </div>
                        )}
                      </td>

                      {/* Quantity */}
                      <td className="px-3 py-2.5 text-right">
                        <MovementQuantityCell movement={m} />
                      </td>

                      {/* Performed By */}
                      <td className="px-3 py-2.5 hidden md:table-cell">
                        {(() => {
                          const performer = formatPerformerDisplay(m.performed_by || m.created_by);
                          return (
                            <div className="flex items-center gap-1.5">
                              <div className="flex h-5 w-5 items-center justify-center rounded-full bg-muted text-muted-foreground">
                                <User className="h-3 w-3" />
                              </div>
                              <span className={`text-[11px] font-medium ${performer.deleted ? 'text-muted-foreground italic' : 'text-foreground'}`}>
                                {performer.primary}
                              </span>
                            </div>
                          );
                        })()}
                      </td>

                      {/* Date */}
                      <td className="px-3 py-2.5 hidden lg:table-cell">
                        <span className="text-[10px] text-muted-foreground tabular-nums">{relDate(m.createdAt)}</span>
                      </td>

                      {/* Notes */}
                      <td className="px-3 py-2.5 hidden xl:table-cell">
                        {m.reason ? (
                          <p className="text-[10px] text-muted-foreground truncate max-w-[180px]" title={m.reason}>{m.reason}</p>
                        ) : (
                          <span className="text-[10px] text-muted-foreground/50">—</span>
                        )}
                      </td>

                      {/* Expand */}
                      <td className="px-2 py-2.5">
                        <button
                          type="button"
                          onClick={() => setExpanded(isExpanded ? null : id)}
                          className="rounded border border-border p-1 text-muted-foreground opacity-0 transition group-hover:opacity-100 hover:bg-muted hover:text-foreground focus:opacity-100"
                        >
                          {isExpanded ? <ChevronUp className="h-3 w-3" /> : <ChevronDown className="h-3 w-3" />}
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* ── Expanded detail rows ── */}
          {expanded && (() => {
            const m = sorted.find((r) => (r.id || r._id) === expanded);
            if (!m) return null;
            const fromLoc = movementFromLocation(m);
            const toLoc = movementToLocation(m);
            return (
              <div className="border-t border-border bg-muted/10 px-4 py-3">
                <div className="grid gap-x-8 gap-y-2 text-xs sm:grid-cols-2 lg:grid-cols-4">
                  <DetailCell label="Movement Type" value={m.type} />
                  <DetailCell label="Product" value={`${m.productId?.sku || '—'} — ${m.productId?.name || '—'}`} />
                  <DetailCell label="From" value={fromLoc} />
                  <DetailCell label="To" value={toLoc} />
                  <DetailCell label="Quantity" value={`${Math.abs(resolveSignedQuantity(m))} units`} />
                  <DetailCell label="Performed By" value={formatPerformerDisplay(m.performed_by || m.created_by).withRole} />
                  <DetailCell label="Date & Time" value={fmtDate(m.createdAt)} />
                  {m.reason && <DetailCell label="Notes" value={m.reason} className="lg:col-span-1" />}
                  {m.taskId && (
                    <div>
                      <p className="text-[9px] font-semibold uppercase text-muted-foreground">Related Task</p>
                      <Link to={`/tasks/${typeof m.taskId === 'object' ? m.taskId._id || m.taskId.id : m.taskId}`} className="mt-0.5 inline-flex items-center gap-1 text-[11px] font-medium text-accent hover:underline">
                        <ClipboardList className="h-3 w-3" /> View Task
                      </Link>
                    </div>
                  )}
                  {m.batchNumber && <DetailCell label="Batch" value={m.batchNumber} />}
                  {m.condition && <DetailCell label="Condition" value={m.condition} />}
                </div>
              </div>
            );
          })()}
        </div>
      )}

      {/* ── Footer ── */}
      {sorted.length > 0 && (
        <div className="flex flex-wrap items-center justify-between gap-2 text-[11px] text-muted-foreground">
          <p>
            {sorted.length === rows.length
              ? `${sorted.length} movement${sorted.length !== 1 ? 's' : ''}`
              : `${sorted.length} of ${rows.length} movements (filtered)`}
          </p>
          <div className="flex items-center gap-3">
            {stats.inbound > 0 && <span className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-emerald-500" /> {stats.inbound} inbound</span>}
            {stats.OUTBOUND > 0 && <span className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-orange-500" /> {stats.OUTBOUND} outbound</span>}
            {stats.TRANSFER > 0 && <span className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-sky-500" /> {stats.TRANSFER} transfers</span>}
            {stats.ADJUSTMENT > 0 && <span className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-amber-500" /> {stats.ADJUSTMENT} adjustments</span>}
          </div>
        </div>
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   Sub-components
   ═══════════════════════════════════════════════════════════════ */

function SortTh({ label, field, sortField, sortDir, onSort, align, className = '' }) {
  const active = sortField === field;
  return (
    <th className={`px-3 py-2.5 ${className}`}>
      <button type="button" onClick={() => onSort(field)} className={`inline-flex items-center gap-0.5 text-[10px] font-bold uppercase tracking-wider transition ${active ? 'text-accent' : 'text-muted-foreground hover:text-foreground'} ${align === 'right' ? 'ml-auto' : ''}`}>
        {label}
        {active && (sortDir === 'asc' ? <ChevronUp className="h-2.5 w-2.5" /> : <ChevronDown className="h-2.5 w-2.5" />)}
      </button>
    </th>
  );
}

function DetailCell({ label, value, className = '' }) {
  return (
    <div className={className}>
      <p className="text-[9px] font-semibold uppercase text-muted-foreground">{label}</p>
      <p className="mt-0.5 font-medium text-foreground">{value || '—'}</p>
    </div>
  );
}

function LoadingSkeleton() {
  return (
    <div className="space-y-1.5">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="h-11 animate-pulse rounded-lg bg-muted/30" />
      ))}
    </div>
  );
}
