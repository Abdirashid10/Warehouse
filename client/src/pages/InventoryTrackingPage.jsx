import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { CreatedByCell } from '../components/CreatedByCell';
import { StockStatusBadge } from '../components/StockStatusBadge';
import { ExpiryStatusBadge } from '../components/ExpiryStatusBadge';
import { MoveStockPanel } from '../components/inventory/MoveStockPanel';
import {
  AlertTriangle,
  ArrowDownToLine,
  ArrowRightLeft,
  ArrowUpFromLine,
  Box,
  ChevronDown,
  ChevronUp,
  Loader2,
  Package,
  PackageMinus,
  Plus,
  Search,
  ShieldAlert,
  ShieldCheck,
  SlidersHorizontal,
  Timer,
  Warehouse,
} from 'lucide-react';
import {
  applyStockStatusToRow,
  enrichInventoryRows,
  summarizeInventoryRows,
} from '../utils/stockStatus';
import { formatRemainingDays } from '../utils/expiryStatus';

/* ─── API ─── */

async function fetchTracking(q, warehouseId, expiryFilter) {
  const params = {};
  if (q) params.q = q;
  if (warehouseId) params.warehouse_id = warehouseId;
  if (expiryFilter) params.expiry_filter = expiryFilter;
  const { data } = await api.get('/inventory/tracking', { params });
  return data;
}

async function fetchWarehouses() {
  const { data } = await api.get('/inventory/warehouses');
  return data;
}

/* ─── Helpers ─── */

function fmt(n) {
  if (n == null || Number.isNaN(n)) return '0';
  return Number(n).toLocaleString();
}

function relDate(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  const now = Date.now();
  const diff = now - d.getTime();
  const m = Math.floor(diff / 60_000);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const days = Math.floor(h / 24);
  if (days < 7) return `${days}d ago`;
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

/* ─── Sort config ─── */

const SORT_FIELDS = ['product', 'warehouse', 'quantity', 'status', 'expiry'];

function sortRows(rows, field, dir) {
  if (!field) return rows;
  return [...rows].sort((a, b) => {
    let va, vb;
    switch (field) {
      case 'product': va = (a.product?.name || '').toLowerCase(); vb = (b.product?.name || '').toLowerCase(); break;
      case 'warehouse': va = (a.warehouse?.name || '').toLowerCase(); vb = (b.warehouse?.name || '').toLowerCase(); break;
      case 'quantity': va = a.current_quantity ?? 0; vb = b.current_quantity ?? 0; break;
      case 'status': { const o = { 'Out of Stock': 0, 'Low Stock': 1, 'In Stock': 2 }; va = o[a.stock_status] ?? 3; vb = o[b.stock_status] ?? 3; break; }
      case 'expiry': va = a.days_until_expiry ?? 99999; vb = b.days_until_expiry ?? 99999; break;
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

export function InventoryTrackingPage() {
  const queryClient = useQueryClient();
  const { user } = useAuth();
  const canManage = user?.role === 'Admin' || user?.role === 'Supervisor';

  const [search, setSearch] = useState('');
  const [warehouseFilter, setWarehouseFilter] = useState('');
  const [expiryFilter, setExpiryFilter] = useState('');
  const [stockFilter, setStockFilter] = useState('');
  const [moveOpen, setMoveOpen] = useState(false);
  const [moveProduct, setMoveProduct] = useState(null);
  const [sortField, setSortField] = useState('');
  const [sortDir, setSortDir] = useState('asc');
  const [showFilters, setShowFilters] = useState(false);

  const { data, isLoading, isError, error, refetch } = useQuery({
    queryKey: ['inventory', 'tracking', search, warehouseFilter, expiryFilter],
    queryFn: () => fetchTracking(search, warehouseFilter, expiryFilter),
    staleTime: 0,
    refetchOnWindowFocus: true,
  });

  const { data: whData } = useQuery({
    queryKey: ['warehouses'],
    queryFn: fetchWarehouses,
  });

  const allRows = useMemo(() => enrichInventoryRows(data?.rows || []), [data?.rows]);
  const summary = useMemo(() => summarizeInventoryRows(allRows), [allRows]);
  const expirySummary = data?.expiry_summary || {};
  const warehouses = whData?.warehouses || [];

  const filteredRows = useMemo(() => {
    if (!stockFilter) return allRows;
    return allRows.filter((r) => {
      if (stockFilter === 'low') return r.stock_status === 'Low Stock';
      if (stockFilter === 'out') return r.stock_status === 'Out of Stock';
      if (stockFilter === 'in') return r.stock_status === 'In Stock';
      return true;
    });
  }, [allRows, stockFilter]);

  const rows = useMemo(() => sortRows(filteredRows, sortField, sortDir), [filteredRows, sortField, sortDir]);

  const seedMutation = useMutation({
    mutationFn: () => api.post('/inventory/seed-sample'),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['inventory'] });
      queryClient.invalidateQueries({ queryKey: ['movements', 'list'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard', 'stats'] });
    },
  });

  function openMove(row) {
    setMoveProduct(row?.product || null);
    setMoveOpen(true);
  }

  function invalidate() {
    queryClient.invalidateQueries({ queryKey: ['inventory'] });
    queryClient.invalidateQueries({ queryKey: ['movements', 'list'] });
    queryClient.invalidateQueries({ queryKey: ['dashboard', 'stats'] });
  }

  function toggleSort(field) {
    if (sortField === field) {
      setSortDir((d) => (d === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortField(field);
      setSortDir('asc');
    }
  }

  const activeFilters = [warehouseFilter, expiryFilter, stockFilter].filter(Boolean).length;

  /* ═══ Render ═══ */
  return (
    <div className="space-y-4 px-1">

      {/* ── Header ── */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-lg font-bold text-foreground">Inventory Tracking</h1>
          <p className="text-xs text-muted-foreground">Live stock levels by product and warehouse · {fmt(summary.total_lines)} lines tracked</p>
        </div>
        {canManage && (
          <div className="flex items-center gap-1.5 shrink-0">
            <button type="button" onClick={() => { setMoveProduct(null); setMoveOpen(true); }} className="inline-flex items-center gap-1.5 rounded-lg border border-accent bg-accent px-3 py-1.5 text-xs font-semibold text-white shadow-sm transition hover:bg-accent/90 active:scale-[0.97]">
              <Plus className="h-3.5 w-3.5" /> Record Stock
            </button>
            {rows.length === 0 && (
              <button type="button" disabled={seedMutation.isPending} onClick={() => seedMutation.mutate()} className="rounded-lg border border-border px-3 py-1.5 text-xs font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground disabled:opacity-50">
                {seedMutation.isPending ? 'Seeding…' : 'Seed Sample'}
              </button>
            )}
          </div>
        )}
      </div>

      {/* ── KPI Cards ── */}
      <div className="grid grid-cols-2 gap-2 sm:grid-cols-4 lg:grid-cols-8">
        <KpiMini label="Total Units" value={fmt(summary.total_units)} icon={Box} color="text-blue-600 dark:text-blue-400" bg="bg-blue-50 dark:bg-blue-500/10" />
        <KpiMini label="In Stock" value={summary.in_stock} icon={Package} color="text-emerald-600 dark:text-emerald-400" bg="bg-emerald-50 dark:bg-emerald-500/10" />
        <KpiMini label="Low Stock" value={summary.low_stock} icon={AlertTriangle} color="text-amber-600 dark:text-amber-400" bg="bg-amber-50 dark:bg-amber-500/10" clickable onClick={() => setStockFilter(stockFilter === 'low' ? '' : 'low')} active={stockFilter === 'low'} />
        <KpiMini label="Out of Stock" value={summary.out_of_stock} icon={PackageMinus} color="text-red-600 dark:text-red-400" bg="bg-red-50 dark:bg-red-500/10" clickable onClick={() => setStockFilter(stockFilter === 'out' ? '' : 'out')} active={stockFilter === 'out'} />
        <KpiMini label="Expired" value={expirySummary.expired ?? 0} icon={ShieldAlert} color="text-red-600 dark:text-red-400" bg="bg-red-50 dark:bg-red-500/10" />
        <KpiMini label="Expiring Soon" value={expirySummary.expiring_soon ?? 0} icon={Timer} color="text-amber-600 dark:text-amber-400" bg="bg-amber-50 dark:bg-amber-500/10" />
        <KpiMini label="Expiring 30d" value={expirySummary.expiring_30d ?? 0} icon={Timer} color="text-orange-500 dark:text-orange-400" bg="bg-orange-50 dark:bg-orange-500/10" />
        <KpiMini label="Safe" value={expirySummary.safe ?? 0} icon={ShieldCheck} color="text-emerald-600 dark:text-emerald-400" bg="bg-emerald-50 dark:bg-emerald-500/10" />
      </div>

      {/* ── Filters Bar ── */}
      <div className="flex flex-wrap items-center gap-2">
        {/* Search */}
        <div className="relative flex-1 min-w-[180px] max-w-sm">
          <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search product, SKU, barcode…"
            className="wms-input h-8 w-full pl-8 text-xs"
          />
        </div>

        {/* Stock status pills */}
        <div className="flex items-center gap-1">
          {[
            { key: '', label: 'All' },
            { key: 'in', label: 'In Stock', count: summary.in_stock },
            { key: 'low', label: 'Low', count: summary.low_stock },
            { key: 'out', label: 'Out', count: summary.out_of_stock },
          ].map(({ key, label, count }) => (
            <button key={key} type="button" onClick={() => setStockFilter(key)} className={`rounded-md px-2 py-1 text-[11px] font-semibold transition ${stockFilter === key ? 'bg-accent text-white' : 'bg-muted/50 text-muted-foreground hover:text-foreground'}`}>
              {label}{count != null && count > 0 ? ` ${count}` : ''}
            </button>
          ))}
        </div>

        {/* Expand / collapse advanced filters */}
        <button type="button" onClick={() => setShowFilters(!showFilters)} className={`inline-flex items-center gap-1 rounded-md border px-2 py-1 text-[11px] font-medium transition ${showFilters || activeFilters > 0 ? 'border-accent bg-accent/5 text-accent' : 'border-border text-muted-foreground hover:text-foreground'}`}>
          <SlidersHorizontal className="h-3 w-3" /> Filters{activeFilters > 0 ? ` (${activeFilters})` : ''}
        </button>

        {/* Quick actions (right side) */}
        {canManage && (
          <div className="ml-auto flex items-center gap-1">
            <button type="button" onClick={() => { setMoveProduct(null); setMoveOpen(true); }} className="inline-flex items-center gap-1 rounded-md border border-emerald-200 bg-emerald-50 px-2 py-1 text-[11px] font-semibold text-emerald-700 transition hover:bg-emerald-100 dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-300 dark:hover:bg-emerald-500/20" title="Record Inbound">
              <ArrowDownToLine className="h-3 w-3" /> <span className="hidden sm:inline">Inbound</span>
            </button>
            <button type="button" onClick={() => { setMoveProduct(null); setMoveOpen(true); }} className="inline-flex items-center gap-1 rounded-md border border-orange-200 bg-orange-50 px-2 py-1 text-[11px] font-semibold text-orange-700 transition hover:bg-orange-100 dark:border-orange-500/30 dark:bg-orange-500/10 dark:text-orange-300 dark:hover:bg-orange-500/20" title="Record Outbound">
              <ArrowUpFromLine className="h-3 w-3" /> <span className="hidden sm:inline">Outbound</span>
            </button>
            <button type="button" onClick={() => { setMoveProduct(null); setMoveOpen(true); }} className="inline-flex items-center gap-1 rounded-md border border-sky-200 bg-sky-50 px-2 py-1 text-[11px] font-semibold text-sky-700 transition hover:bg-sky-100 dark:border-sky-500/30 dark:bg-sky-500/10 dark:text-sky-300 dark:hover:bg-sky-500/20" title="Transfer Stock">
              <ArrowRightLeft className="h-3 w-3" /> <span className="hidden sm:inline">Transfer</span>
            </button>
          </div>
        )}
      </div>

      {/* ── Advanced Filters Row ── */}
      {showFilters && (
        <div className="flex flex-wrap items-center gap-2 rounded-lg border border-border/60 bg-muted/10 px-3 py-2">
          <select value={warehouseFilter} onChange={(e) => setWarehouseFilter(e.target.value)} className="wms-input h-7 text-[11px] min-w-[130px]">
            <option value="">All Warehouses</option>
            {warehouses.map((w) => <option key={w._id} value={w._id}>{w.name}</option>)}
          </select>
          <select value={expiryFilter} onChange={(e) => setExpiryFilter(e.target.value)} className="wms-input h-7 text-[11px] min-w-[140px]">
            <option value="">All Expiry</option>
            <option value="expired">Expired</option>
            <option value="expiring_soon">Expiring Soon (7d)</option>
            <option value="expiring_30d">Expiring (30d)</option>
            <option value="safe">Safe</option>
            <option value="no_expiry">No Expiry Date</option>
          </select>
          {(warehouseFilter || expiryFilter || stockFilter) && (
            <button type="button" onClick={() => { setWarehouseFilter(''); setExpiryFilter(''); setStockFilter(''); }} className="text-[11px] font-medium text-accent hover:underline">Clear all</button>
          )}
        </div>
      )}

      {/* ── Alert Banners (compact) ── */}
      {(summary.low_stock > 0 || summary.out_of_stock > 0) && !stockFilter && (
        <div className="flex flex-wrap gap-2">
          {summary.low_stock > 0 && (
            <button type="button" onClick={() => setStockFilter('low')} className="flex items-center gap-1.5 rounded-lg border border-amber-200/60 bg-amber-50/40 px-2.5 py-1.5 text-[11px] font-medium text-amber-800 transition hover:bg-amber-50 dark:border-amber-500/25 dark:bg-amber-500/5 dark:text-amber-300 dark:hover:bg-amber-500/10">
              <AlertTriangle className="h-3 w-3 text-amber-500" />
              <span className="font-bold tabular-nums">{summary.low_stock}</span> low stock line{summary.low_stock !== 1 ? 's' : ''}
            </button>
          )}
          {summary.out_of_stock > 0 && (
            <button type="button" onClick={() => setStockFilter('out')} className="flex items-center gap-1.5 rounded-lg border border-red-200/60 bg-red-50/40 px-2.5 py-1.5 text-[11px] font-medium text-red-800 transition hover:bg-red-50 dark:border-red-500/25 dark:bg-red-500/5 dark:text-red-300 dark:hover:bg-red-500/10">
              <PackageMinus className="h-3 w-3 text-red-500" />
              <span className="font-bold tabular-nums">{summary.out_of_stock}</span> out of stock
            </button>
          )}
        </div>
      )}

      {/* ── Main Table ── */}
      {isLoading ? (
        <LoadingSkeleton />
      ) : isError ? (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-3 text-xs text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
          {error?.response?.data?.message || 'Failed to load inventory data.'}
          <button type="button" onClick={() => refetch()} className="ml-2 font-semibold underline">Retry</button>
        </div>
      ) : rows.length === 0 ? (
        <div className="flex flex-col items-center gap-3 rounded-xl border border-dashed border-border bg-muted/10 py-14 text-center">
          <Package className="h-10 w-10 text-muted-foreground/20" />
          <div>
            <p className="text-sm font-medium text-muted-foreground">
              {search || warehouseFilter || expiryFilter || stockFilter
                ? 'No inventory matches your filters'
                : 'No warehouse stock yet'}
            </p>
            <p className="mt-0.5 text-[11px] text-muted-foreground/70">
              {search || stockFilter
                ? 'Try adjusting your search or filter criteria.'
                : 'Create products, then record an inbound movement to begin tracking.'}
            </p>
          </div>
          {canManage && !search && !stockFilter && (
            <button type="button" onClick={() => { setMoveProduct(null); setMoveOpen(true); }} className="mt-1 inline-flex items-center gap-1 rounded-md border border-accent bg-accent/5 px-3 py-1.5 text-xs font-semibold text-accent transition hover:bg-accent/10">
              <Plus className="h-3 w-3" /> Record First Stock
            </button>
          )}
        </div>
      ) : (
        <div className="overflow-hidden rounded-lg border border-border">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <SortTh label="Product" field="product" sortField={sortField} sortDir={sortDir} onSort={toggleSort} className="pl-3" />
                  <SortTh label="Warehouse" field="warehouse" sortField={sortField} sortDir={sortDir} onSort={toggleSort} className="hidden sm:table-cell" />
                  <SortTh label="Qty" field="quantity" sortField={sortField} sortDir={sortDir} onSort={toggleSort} align="right" />
                  <th className="px-3 py-2.5 text-right text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Avail</th>
                  <th className="px-3 py-2.5 text-right text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden md:table-cell">Rsv</th>
                  <th className="px-3 py-2.5 text-right text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden md:table-cell">Dmg</th>
                  <SortTh label="Status" field="status" sortField={sortField} sortDir={sortDir} onSort={toggleSort} />
                  <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden lg:table-cell">Batch</th>
                  <SortTh label="Expiry" field="expiry" sortField={sortField} sortDir={sortDir} onSort={toggleSort} className="hidden lg:table-cell" />
                  <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden xl:table-cell">Updated</th>
                  {canManage && <th className="px-3 py-2.5 text-right text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Actions</th>}
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40">
                {rows.map((row) => {
                  const live = applyStockStatusToRow(row);
                  const p = live.product || {};
                  const isLow = live.stock_status === 'Low Stock';
                  const isOut = live.stock_status === 'Out of Stock';

                  return (
                    <tr key={live.id} className={`group transition ${isOut ? 'bg-red-50/30 dark:bg-red-500/[0.03]' : isLow ? 'bg-amber-50/30 dark:bg-amber-500/[0.03]' : 'hover:bg-muted/20'}`}>
                      {/* Product */}
                      <td className="px-3 py-2">
                        <p className="font-semibold text-foreground leading-tight">{p.name || '—'}</p>
                        <p className="mt-0.5 text-[10px] text-muted-foreground font-mono">{p.sku || '—'}</p>
                      </td>

                      {/* Warehouse */}
                      <td className="px-3 py-2 hidden sm:table-cell">
                        <span className="inline-flex items-center gap-1 text-muted-foreground">
                          <Warehouse className="h-3 w-3 text-sky-500/60" />
                          <span className="text-foreground font-medium">{row.warehouse?.name || '—'}</span>
                        </span>
                      </td>

                      {/* Quantity */}
                      <td className="px-3 py-2 text-right">
                        <span className={`text-sm font-bold tabular-nums ${isOut ? 'text-red-600 dark:text-red-400' : isLow ? 'text-amber-700 dark:text-amber-400' : 'text-foreground'}`}>
                          {live.current_quantity}
                        </span>
                        {live.min_stock_threshold > 0 && (
                          <p className="text-[9px] text-muted-foreground tabular-nums">min {live.min_stock_threshold}</p>
                        )}
                      </td>

                      {/* Available */}
                      <td className="px-3 py-2 text-right">
                        <span className="font-semibold tabular-nums text-emerald-700 dark:text-emerald-400">{live.available_stock}</span>
                      </td>

                      {/* Reserved */}
                      <td className="px-3 py-2 text-right hidden md:table-cell">
                        <span className={`tabular-nums ${live.reserved_stock > 0 ? 'font-medium text-amber-700 dark:text-amber-400' : 'text-muted-foreground'}`}>{live.reserved_stock}</span>
                      </td>

                      {/* Damaged */}
                      <td className="px-3 py-2 text-right hidden md:table-cell">
                        <span className={`tabular-nums ${live.damaged_stock > 0 ? 'font-medium text-red-600 dark:text-red-400' : 'text-muted-foreground'}`}>{live.damaged_stock}</span>
                      </td>

                      {/* Stock Status */}
                      <td className="px-3 py-2"><StockStatusBadge status={live.stock_status} /></td>

                      {/* Batch */}
                      <td className="px-3 py-2 hidden lg:table-cell">
                        <span className="font-mono text-[10px] text-muted-foreground">{live.batch_number || '—'}</span>
                      </td>

                      {/* Expiry */}
                      <td className="px-3 py-2 hidden lg:table-cell">
                        {live.expiry_date ? (
                          <div className="flex items-center gap-1.5">
                            <ExpiryStatusBadge status={live.expiry_status} />
                            <span className="text-[10px] text-muted-foreground tabular-nums">{formatRemainingDays(live.days_until_expiry)}</span>
                          </div>
                        ) : (
                          <span className="text-[10px] text-muted-foreground">—</span>
                        )}
                      </td>

                      {/* Updated */}
                      <td className="px-3 py-2 hidden xl:table-cell">
                        <span className="text-[10px] text-muted-foreground tabular-nums">{relDate(row.last_updated)}</span>
                      </td>

                      {/* Actions */}
                      {canManage && (
                        <td className="px-3 py-2 text-right">
                          <button
                            type="button"
                            onClick={() => openMove(row)}
                            className="rounded border border-border p-1.5 text-muted-foreground opacity-0 transition group-hover:opacity-100 hover:bg-muted hover:text-foreground focus:opacity-100"
                            title="Adjust stock"
                          >
                            <ArrowRightLeft className="h-3 w-3" />
                          </button>
                        </td>
                      )}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ── Footer ── */}
      {rows.length > 0 && (
        <div className="flex flex-wrap items-center justify-between gap-2 text-[11px] text-muted-foreground">
          <p>
            {rows.length === allRows.length
              ? `${rows.length} inventory line${rows.length !== 1 ? 's' : ''}`
              : `${rows.length} of ${allRows.length} lines (filtered)`
            }
            {' '} · {fmt(summary.total_units)} total units across {warehouses.length} warehouse{warehouses.length !== 1 ? 's' : ''}
          </p>
          <div className="flex items-center gap-3">
            {summary.low_stock > 0 && <span className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-amber-500" /> {summary.low_stock} low</span>}
            {summary.out_of_stock > 0 && <span className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-red-500" /> {summary.out_of_stock} out</span>}
            {(expirySummary.expired ?? 0) > 0 && <span className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-red-500" /> {expirySummary.expired} expired</span>}
          </div>
        </div>
      )}

      {/* ── Move Stock Panel ── */}
      <MoveStockPanel
        open={moveOpen}
        onClose={() => { setMoveOpen(false); setMoveProduct(null); }}
        initialProduct={moveProduct}
        onSuccess={() => { invalidate(); setMoveOpen(false); setMoveProduct(null); }}
      />
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   Sub-components
   ═══════════════════════════════════════════════════════════════ */

function KpiMini({ label, value, icon: Icon, color, bg, clickable, onClick, active }) {
  const Wrapper = clickable ? 'button' : 'div';
  return (
    <Wrapper
      type={clickable ? 'button' : undefined}
      onClick={clickable ? onClick : undefined}
      className={`rounded-lg border px-2.5 py-2 text-left transition ${active ? 'border-accent bg-accent/5 ring-1 ring-accent/20' : 'border-border bg-card'} ${clickable ? 'cursor-pointer hover:shadow-sm' : ''}`}
    >
      <div className="flex items-center gap-1.5">
        <div className={`flex h-4.5 w-4.5 items-center justify-center rounded ${bg}`}>
          <Icon className={`h-2.5 w-2.5 ${color}`} strokeWidth={2.2} />
        </div>
        <span className="text-[9px] font-semibold uppercase tracking-wider text-muted-foreground">{label}</span>
      </div>
      <p className={`mt-0.5 text-base font-bold tabular-nums leading-tight ${color}`}>{value}</p>
    </Wrapper>
  );
}

function SortTh({ label, field, sortField, sortDir, onSort, align, className = '' }) {
  const active = sortField === field;
  return (
    <th className={`px-3 py-2.5 ${className}`}>
      <button
        type="button"
        onClick={() => onSort(field)}
        className={`inline-flex items-center gap-0.5 text-[10px] font-bold uppercase tracking-wider transition ${active ? 'text-accent' : 'text-muted-foreground hover:text-foreground'} ${align === 'right' ? 'ml-auto' : ''}`}
      >
        {label}
        {active && (sortDir === 'asc' ? <ChevronUp className="h-2.5 w-2.5" /> : <ChevronDown className="h-2.5 w-2.5" />)}
      </button>
    </th>
  );
}

function LoadingSkeleton() {
  return (
    <div className="space-y-2">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="h-10 animate-pulse rounded-lg bg-muted/30" />
      ))}
    </div>
  );
}
