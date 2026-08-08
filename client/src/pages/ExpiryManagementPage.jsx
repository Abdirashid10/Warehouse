import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  AlertTriangle,
  ArrowRightLeft,
  Calendar,
  ChevronRight,
  Clock,
  Filter,
  Package,
  Search,
  ShieldAlert,
  ShieldCheck,
  Timer,
  Warehouse,
  X,
} from 'lucide-react';
import { api } from '../api/client';
import { ExpiryStatusBadge } from '../components/ExpiryStatusBadge';
import { daysUntilExpiry, getExpiryStatus, formatRemainingDays } from '../utils/expiryStatus';
import { getWarehouseName } from '../utils/inventoryHelpers';

const DELETED_PRODUCT = 'Deleted Product';
const DELETED_WAREHOUSE = 'Deleted Warehouse';

function resolveProductName(row) {
  const name = row.product_name || row.product?.name;
  if (name && name !== '—') return name;
  if (row.product_id || row.product?.id) return DELETED_PRODUCT;
  return DELETED_PRODUCT;
}

function resolveWarehouseName(row) {
  const name = row.warehouse_name || getWarehouseName(row.warehouse);
  if (name) return name;
  if (row.warehouse_id || row.warehouse?.id) return DELETED_WAREHOUSE;
  return DELETED_WAREHOUSE;
}

function resolveSku(row) {
  const sku = row.sku || row.product?.sku;
  return sku && sku !== '—' ? sku : '—';
}

function normalizeExpiryRow(row) {
  const product_name = resolveProductName(row);
  const warehouse_name = resolveWarehouseName(row);
  const sku = resolveSku(row);
  const expiry_date = row.expiry_date || row.expiryDate || null;
  const manufacture_date = row.manufacture_date || row.manufactureDate || null;
  const batch_number = row.batch_number || row.batchNumber || '';
  const current_quantity = row.current_quantity ?? row.currentQuantity ?? 0;

  return {
    ...row,
    product_name,
    warehouse_name,
    sku,
    expiry_date,
    manufacture_date,
    batch_number,
    current_quantity,
  };
}

/* ─── API ─── */

async function fetchTracking(warehouseId, expiryFilter) {
  const params = {};
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

function fmt(n) { return Number(n || 0).toLocaleString(); }

function fmtDate(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
}

function enrichRow(row) {
  const normalized = normalizeExpiryRow(row);
  const ed = normalized.expiry_date;
  return {
    ...normalized,
    _days: daysUntilExpiry(ed),
    _status: getExpiryStatus(ed),
  };
}

/* ─── Sort ─── */

const SORT_FIELDS = ['product', 'warehouse', 'expiry', 'quantity'];

function sortRows(rows, field, dir) {
  return [...rows].sort((a, b) => {
    let va, vb;
    switch (field) {
      case 'product': va = (a.product_name || '').toLowerCase(); vb = (b.product_name || '').toLowerCase(); break;
      case 'warehouse': va = (a.warehouse_name || '').toLowerCase(); vb = (b.warehouse_name || '').toLowerCase(); break;
      case 'expiry': va = a._days ?? 99999; vb = b._days ?? 99999; break;
      case 'quantity': va = a.current_quantity ?? 0; vb = b.current_quantity ?? 0; break;
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

export function ExpiryManagementPage() {
  const [searchQ, setSearchQ] = useState('');
  const [warehouseFilter, setWarehouseFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [showFilters, setShowFilters] = useState(false);
  const [sortField, setSortField] = useState('expiry');
  const [sortDir, setSortDir] = useState('asc');
  const [expanded, setExpanded] = useState(null);

  const { data, isLoading, isError } = useQuery({
    queryKey: ['inventory', 'tracking', '', warehouseFilter, ''],
    queryFn: () => fetchTracking(warehouseFilter, ''),
    staleTime: 0,
    refetchOnWindowFocus: true,
  });

  const { data: whData } = useQuery({ queryKey: ['warehouses'], queryFn: fetchWarehouses });
  const warehouses = whData?.warehouses || [];

  const allRows = useMemo(() => (data?.rows || []).map(enrichRow), [data?.rows]);

  const expiryRows = useMemo(() => {
    return allRows.filter((r) => r.expiry_date || r.expiryDate);
  }, [allRows]);

  const summary = useMemo(() => {
    const s = { expired: 0, expiring_soon: 0, expiring_30d: 0, safe: 0, total: 0, total_qty_at_risk: 0 };
    expiryRows.forEach((r) => {
      s.total++;
      if (r._status === 'Expired') { s.expired++; s.total_qty_at_risk += (r.current_quantity || 0); }
      else if (r._status === 'Expiring Soon') { s.expiring_soon++; s.total_qty_at_risk += (r.current_quantity || 0); }
      else if (r._status === 'Expiring (30d)') s.expiring_30d++;
      else s.safe++;
    });
    return s;
  }, [expiryRows]);

  const filteredRows = useMemo(() => {
    let rows = expiryRows;

    if (statusFilter) {
      const map = { expired: 'Expired', soon: 'Expiring Soon', '30d': 'Expiring (30d)', safe: 'Safe' };
      const target = map[statusFilter];
      if (target) rows = rows.filter((r) => r._status === target);
    }

    if (searchQ) {
      const q = searchQ.toLowerCase();
      rows = rows.filter((r) =>
        (r.product_name || '').toLowerCase().includes(q) ||
        (r.sku || '').toLowerCase().includes(q) ||
        (r.warehouse_name || '').toLowerCase().includes(q) ||
        (r.batch_number || '').toLowerCase().includes(q)
      );
    }

    return sortRows(rows, sortField, sortDir);
  }, [expiryRows, statusFilter, searchQ, sortField, sortDir]);

  function toggleSort(field) {
    if (sortField === field) setSortDir((d) => d === 'asc' ? 'desc' : 'asc');
    else { setSortField(field); setSortDir('asc'); }
  }

  const warehouseRisk = useMemo(() => {
    const map = {};
    expiryRows.forEach((r) => {
      const wh = r.warehouse_name;
      if (!map[wh]) map[wh] = { name: wh, expired: 0, soon: 0, total: 0 };
      map[wh].total++;
      if (r._status === 'Expired') map[wh].expired++;
      if (r._status === 'Expiring Soon') map[wh].soon++;
    });
    return Object.values(map).sort((a, b) => (b.expired + b.soon) - (a.expired + a.soon));
  }, [expiryRows]);

  const hasFilter = statusFilter || searchQ || warehouseFilter;

  const STATUS_PILLS = [
    { key: '', label: 'All', count: expiryRows.length },
    { key: 'expired', label: 'Expired', count: summary.expired, color: 'text-red-600 dark:text-red-400' },
    { key: 'soon', label: 'Expiring Soon', count: summary.expiring_soon, color: 'text-amber-600 dark:text-amber-400' },
    { key: '30d', label: 'Expiring (30d)', count: summary.expiring_30d, color: 'text-orange-500 dark:text-orange-400' },
    { key: 'safe', label: 'Safe', count: summary.safe, color: 'text-emerald-600 dark:text-emerald-400' },
  ];

  return (
    <div className="space-y-4 px-1">

      {/* ── Header ── */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-lg font-bold text-foreground">Expiry & Risk Intelligence</h1>
          <p className="text-xs text-muted-foreground">Inventory expiry monitoring & stock risk analysis · {summary.total} tracked items</p>
        </div>
      </div>

      {/* ── KPI Cards ── */}
      <div className="grid grid-cols-3 gap-2 sm:grid-cols-6">
        <KpiMini label="Expired" value={summary.expired} icon={ShieldAlert} color="text-red-600 dark:text-red-400" bg="bg-red-50 dark:bg-red-500/10" active={statusFilter === 'expired'} onClick={() => { setStatusFilter(statusFilter === 'expired' ? '' : 'expired'); }} />
        <KpiMini label="Expiring Soon" value={summary.expiring_soon} icon={Timer} color="text-amber-600 dark:text-amber-400" bg="bg-amber-50 dark:bg-amber-500/10" active={statusFilter === 'soon'} onClick={() => { setStatusFilter(statusFilter === 'soon' ? '' : 'soon'); }} />
        <KpiMini label="Expiring 30d" value={summary.expiring_30d} icon={Clock} color="text-orange-500 dark:text-orange-400" bg="bg-orange-50 dark:bg-orange-500/10" active={statusFilter === '30d'} onClick={() => { setStatusFilter(statusFilter === '30d' ? '' : '30d'); }} />
        <KpiMini label="Safe" value={summary.safe} icon={ShieldCheck} color="text-emerald-600 dark:text-emerald-400" bg="bg-emerald-50 dark:bg-emerald-500/10" active={statusFilter === 'safe'} onClick={() => { setStatusFilter(statusFilter === 'safe' ? '' : 'safe'); }} />
        <KpiMini label="Qty at Risk" value={fmt(summary.total_qty_at_risk)} icon={AlertTriangle} color="text-red-600 dark:text-red-400" bg="bg-red-50 dark:bg-red-500/10" />
        <KpiMini label="Tracked" value={summary.total} icon={Package} color="text-sky-600 dark:text-sky-400" bg="bg-sky-50 dark:bg-sky-500/10" />
      </div>

      {/* ── Insight Strips ── */}
      {(summary.expired > 0 || summary.expiring_soon > 0 || warehouseRisk.length > 0) && (
        <div className="flex flex-wrap gap-2">
          {summary.expired > 0 && (
            <InsightChip icon={ShieldAlert} color="text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-500/10 border-red-200 dark:border-red-500/20" text={`${summary.expired} product${summary.expired !== 1 ? 's' : ''} expired — ${fmt(summary.total_qty_at_risk)} units at risk`} onClick={() => setStatusFilter('expired')} />
          )}
          {summary.expiring_soon > 0 && (
            <InsightChip icon={Timer} color="text-amber-600 dark:text-amber-400 bg-amber-50 dark:bg-amber-500/10 border-amber-200 dark:border-amber-500/20" text={`${summary.expiring_soon} product${summary.expiring_soon !== 1 ? 's' : ''} expiring within 7 days`} onClick={() => setStatusFilter('soon')} />
          )}
          {warehouseRisk.length > 0 && warehouseRisk[0].expired + warehouseRisk[0].soon > 0 && (
            <InsightChip icon={Warehouse} color="text-sky-600 dark:text-sky-400 bg-sky-50 dark:bg-sky-500/10 border-sky-200 dark:border-sky-500/20" text={`${warehouseRisk[0].name} has highest expiry risk (${warehouseRisk[0].expired + warehouseRisk[0].soon} items)`} />
          )}
        </div>
      )}

      {/* ── Search + Filters ── */}
      <div className="flex items-center gap-2">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
          <input type="text" value={searchQ} onChange={(e) => setSearchQ(e.target.value)} placeholder="Search product, SKU, batch, warehouse…" className="wms-input h-8 w-full pl-8 text-xs" />
        </div>
        <button type="button" onClick={() => setShowFilters(!showFilters)} className={`inline-flex items-center gap-1 rounded-md border px-2 py-1.5 text-[11px] font-medium transition ${showFilters ? 'border-accent bg-accent/5 text-accent' : 'border-border text-muted-foreground hover:bg-muted hover:text-foreground'}`}>
          <Filter className="h-3 w-3" /> Filters
        </button>
        {hasFilter && (
          <button type="button" onClick={() => { setStatusFilter(''); setSearchQ(''); setWarehouseFilter(''); }} className="inline-flex items-center gap-1 rounded-md border border-border px-2 py-1.5 text-[11px] font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground">
            <X className="h-3 w-3" /> Clear
          </button>
        )}
      </div>

      {/* Advanced filters */}
      {showFilters && (
        <div className="flex flex-wrap gap-3 rounded-lg border border-border/60 bg-muted/10 px-3 py-2.5">
          <div className="flex items-center gap-1">
            <span className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground mr-1">Status:</span>
            {STATUS_PILLS.map((p) => (
              <button key={p.key} type="button" onClick={() => setStatusFilter(p.key)} className={`rounded-md px-2 py-1 text-[10px] font-semibold transition ${statusFilter === p.key ? 'bg-accent text-white' : 'bg-card border border-border text-muted-foreground hover:text-foreground'}`}>
                {p.label} <span className="ml-0.5 tabular-nums">({p.count})</span>
              </button>
            ))}
          </div>
          <div className="w-px self-stretch bg-border/60 hidden sm:block" />
          <div className="flex items-center gap-1">
            <span className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground mr-1">Warehouse:</span>
            <select value={warehouseFilter} onChange={(e) => setWarehouseFilter(e.target.value)} className="rounded-md border border-border bg-card px-2 py-1 text-[10px] font-medium text-foreground">
              <option value="">All Warehouses</option>
              {warehouses.map((w) => <option key={w.id || w._id} value={w.id || w._id}>{w.name}</option>)}
            </select>
          </div>
        </div>
      )}

      {/* ── Main Content ── */}
      {isLoading ? (
        <LoadingSkeleton />
      ) : isError ? (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-3 text-xs text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">Failed to load expiry data.</div>
      ) : expiryRows.length === 0 ? (
        <div className="flex flex-col items-center gap-3 rounded-xl border border-dashed border-border bg-muted/10 py-14 text-center">
          <ShieldCheck className="h-10 w-10 text-muted-foreground/15" />
          <div>
            <p className="text-sm font-medium text-muted-foreground">No expiry data available</p>
            <p className="mt-0.5 text-[11px] text-muted-foreground/70">Add expiry dates to inventory items to start tracking.</p>
          </div>
        </div>
      ) : (
        <div className="grid gap-4 xl:grid-cols-[1fr_280px]">
          {/* ── Table ── */}
          <div className="space-y-3">
            <div className="rounded-lg border border-border bg-card overflow-x-auto">
              <table className="min-w-full text-left text-[11px]">
                <thead>
                  <tr className="border-b border-border bg-muted/30">
                    <th className="w-8 px-2 py-2.5" />
                    <SortTh label="Product" field="product" sortField={sortField} sortDir={sortDir} onSort={toggleSort} />
                    <SortTh label="Warehouse" field="warehouse" sortField={sortField} sortDir={sortDir} onSort={toggleSort} className="hidden sm:table-cell" />
                    <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden md:table-cell">Batch</th>
                    <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden lg:table-cell">Mfg Date</th>
                    <SortTh label="Expiry" field="expiry" sortField={sortField} sortDir={sortDir} onSort={toggleSort} />
                    <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground text-center">Status</th>
                    <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground text-center">Remaining</th>
                    <SortTh label="Qty" field="quantity" sortField={sortField} sortDir={sortDir} onSort={toggleSort} className="text-right" />
                  </tr>
                </thead>
                <tbody className="divide-y divide-border/40">
                  {filteredRows.length ? filteredRows.map((row) => {
                    const isExpanded = expanded === (row.id || row._id);
                    const isRisk = row._status === 'Expired' || row._status === 'Expiring Soon';
                    return (
                      <ExpiryRow key={row.id || row._id} row={row} isExpanded={isExpanded} isRisk={isRisk} onToggle={() => setExpanded(isExpanded ? null : (row.id || row._id))} />
                    );
                  }) : (
                    <tr>
                      <td colSpan={9} className="px-4 py-10 text-center text-xs text-muted-foreground">
                        {hasFilter ? 'No items match your filters' : 'No expiry-tracked items'}
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            {/* Footer */}
            {filteredRows.length > 0 && (
              <p className="text-[10px] text-muted-foreground">
                {filteredRows.length === expiryRows.length ? `${expiryRows.length} tracked items` : `${filteredRows.length} of ${expiryRows.length} (filtered)`}
                {summary.expired > 0 && <> · <span className="text-red-500">{summary.expired} expired</span></>}
                {summary.expiring_soon > 0 && <> · <span className="text-amber-500">{summary.expiring_soon} expiring soon</span></>}
              </p>
            )}
          </div>

          {/* ── Risk Sidebar ── */}
          <div className="space-y-3">
            {/* Warehouse Risk */}
            <div className="rounded-lg border border-border bg-card">
              <div className="border-b border-border/60 px-3 py-2">
                <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Warehouse Risk</p>
              </div>
              {warehouseRisk.length ? (
                <div className="divide-y divide-border/40">
                  {warehouseRisk.map((wh) => {
                    const risk = wh.expired + wh.soon;
                    const pct = wh.total ? Math.round((risk / wh.total) * 100) : 0;
                    return (
                      <div key={wh.name} className="px-3 py-2">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-1.5">
                            <Warehouse className="h-3 w-3 text-sky-500" />
                            <span className="text-[11px] font-semibold text-foreground">{wh.name}</span>
                          </div>
                          <span className={`text-[10px] font-bold tabular-nums ${risk > 0 ? 'text-red-500' : 'text-emerald-500'}`}>{risk > 0 ? `${risk} at risk` : 'Safe'}</span>
                        </div>
                        <div className="mt-1 h-1 overflow-hidden rounded-full bg-muted">
                          <div className={`h-full rounded-full ${pct >= 50 ? 'bg-red-500' : pct > 0 ? 'bg-amber-500' : 'bg-emerald-500'}`} style={{ width: `${Math.max(pct, 2)}%` }} />
                        </div>
                        <div className="mt-0.5 flex items-center justify-between text-[9px] text-muted-foreground tabular-nums">
                          <span>{wh.total} items tracked</span>
                          <span>{wh.expired} expired · {wh.soon} soon</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <p className="px-3 py-4 text-[11px] text-muted-foreground text-center">No warehouse data</p>
              )}
            </div>

            {/* Expiry Distribution */}
            <div className="rounded-lg border border-border bg-card">
              <div className="border-b border-border/60 px-3 py-2">
                <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Risk Distribution</p>
              </div>
              <div className="px-3 py-3 space-y-2">
                <DistributionBar label="Expired" count={summary.expired} total={summary.total} color="bg-red-500" textColor="text-red-600 dark:text-red-400" />
                <DistributionBar label="Expiring Soon" count={summary.expiring_soon} total={summary.total} color="bg-amber-500" textColor="text-amber-600 dark:text-amber-400" />
                <DistributionBar label="Expiring (30d)" count={summary.expiring_30d} total={summary.total} color="bg-orange-400" textColor="text-orange-500 dark:text-orange-400" />
                <DistributionBar label="Safe" count={summary.safe} total={summary.total} color="bg-emerald-500" textColor="text-emerald-600 dark:text-emerald-400" />
              </div>
            </div>

            {/* Quick Links */}
            <div className="rounded-lg border border-border bg-card">
              <div className="border-b border-border/60 px-3 py-2">
                <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Quick Actions</p>
              </div>
              <div className="divide-y divide-border/40">
                <QuickLink icon={Package} label="Inventory Control" to="/inventory-tracking" />
                <QuickLink icon={ArrowRightLeft} label="Stock Movements" to="/stock-movements" />
                <QuickLink icon={Warehouse} label="Warehouses" to="/warehouses" />
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   EXPIRY TABLE ROW
   ═══════════════════════════════════════════════════════════════ */

function ExpiryRow({ row, isExpanded, isRisk, onToggle }) {
  const days = row._days;
  const daysLabel = days === null ? '—' : days <= 0 ? `${Math.abs(days)}d overdue` : `${days}d`;
  const daysColor = days === null ? 'text-muted-foreground' : days <= 0 ? 'text-red-600 dark:text-red-400 font-bold' : days <= 7 ? 'text-amber-600 dark:text-amber-400 font-bold' : days <= 30 ? 'text-orange-500 dark:text-orange-400' : 'text-emerald-600 dark:text-emerald-400';

  return (
    <>
      <tr className={`transition hover:bg-muted/20 cursor-pointer ${isRisk ? 'bg-red-50/30 dark:bg-red-500/[0.03]' : ''}`} onClick={onToggle}>
        <td className="px-2 py-2">
          <ChevronRight className={`h-3 w-3 text-muted-foreground transition-transform ${isExpanded ? 'rotate-90' : ''}`} />
        </td>
        <td className="px-3 py-2">
          <p className="text-xs font-semibold text-foreground truncate max-w-[180px]">{row.product_name || DELETED_PRODUCT}</p>
          <p className="text-[10px] text-muted-foreground font-mono">{row.sku || '—'}</p>
        </td>
        <td className="px-3 py-2 text-xs text-muted-foreground hidden sm:table-cell">{row.warehouse_name || DELETED_WAREHOUSE}</td>
        <td className="px-3 py-2 text-[10px] text-muted-foreground font-mono hidden md:table-cell">{row.batch_number || '—'}</td>
        <td className="px-3 py-2 text-[10px] text-muted-foreground hidden lg:table-cell">{fmtDate(row.manufacture_date)}</td>
        <td className="px-3 py-2 text-[10px] text-muted-foreground tabular-nums">{fmtDate(row.expiry_date)}</td>
        <td className="px-3 py-2 text-center"><ExpiryStatusBadge status={row._status} /></td>
        <td className={`px-3 py-2 text-center text-[10px] tabular-nums ${daysColor}`}>{daysLabel}</td>
        <td className="px-3 py-2 text-right font-semibold tabular-nums text-foreground">{fmt(row.current_quantity)}</td>
      </tr>
      {isExpanded && (
        <tr>
          <td colSpan={9} className="bg-muted/10 px-4 py-3">
            <div className="grid grid-cols-2 gap-x-6 gap-y-2 text-[11px] sm:grid-cols-4">
              <DetailField label="Product" value={row.product_name || DELETED_PRODUCT} />
              <DetailField label="SKU" value={row.sku || '—'} />
              <DetailField label="Warehouse" value={row.warehouse_name || DELETED_WAREHOUSE} />
              <DetailField label="Batch" value={row.batch_number || '—'} />
              <DetailField label="Manufacture Date" value={fmtDate(row.manufacture_date)} />
              <DetailField label="Expiry Date" value={fmtDate(row.expiry_date)} />
              <DetailField label="Days Remaining" value={formatRemainingDays(days)} />
              <DetailField label="Quantity" value={fmt(row.current_quantity)} />
              <DetailField label="Stock Status" value={row.stock_status || '—'} />
              <DetailField label="Min Threshold" value={fmt(row.min_stock_threshold)} />
              {row.good_qty !== undefined && <DetailField label="Good Qty" value={fmt(row.good_qty)} />}
              {row.damaged_qty !== undefined && <DetailField label="Damaged Qty" value={fmt(row.damaged_qty)} />}
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

function InsightChip({ icon: Icon, text, color, onClick }) {
  const Wrapper = onClick ? 'button' : 'div';
  return (
    <Wrapper type={onClick ? 'button' : undefined} onClick={onClick} className={`inline-flex items-center gap-1.5 rounded-md border px-2.5 py-1 text-[10px] font-medium transition hover:opacity-80 ${color}`}>
      <Icon className="h-3 w-3 shrink-0" /> {text}
    </Wrapper>
  );
}

function SortTh({ label, field, sortField, sortDir, onSort, className = '' }) {
  const active = sortField === field;
  return (
    <th className={`px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground cursor-pointer select-none transition hover:text-foreground ${className}`} onClick={() => onSort(field)}>
      <span className="inline-flex items-center gap-1">
        {label}
        {active ? (sortDir === 'asc' ? '↑' : '↓') : ''}
      </span>
    </th>
  );
}

function DistributionBar({ label, count, total, color, textColor }) {
  const pct = total ? Math.round((count / total) * 100) : 0;
  return (
    <div>
      <div className="flex items-center justify-between text-[10px]">
        <span className="text-muted-foreground">{label}</span>
        <span className={`font-bold tabular-nums ${textColor}`}>{count} ({pct}%)</span>
      </div>
      <div className="mt-0.5 h-1 overflow-hidden rounded-full bg-muted">
        <div className={`h-full rounded-full ${color}`} style={{ width: `${Math.max(pct, 1)}%` }} />
      </div>
    </div>
  );
}

function QuickLink({ icon: Icon, label, to }) {
  return (
    <Link to={to} className="flex items-center gap-2 px-3 py-2 text-[11px] font-medium text-muted-foreground transition hover:bg-muted/30 hover:text-foreground">
      <Icon className="h-3 w-3" /> {label} <ChevronRight className="ml-auto h-3 w-3 opacity-30" />
    </Link>
  );
}

function DetailField({ label, value }) {
  const display = value == null || value === '' ? '—' : value;
  return (
    <div>
      <p className="text-[9px] font-semibold uppercase tracking-wider text-muted-foreground">{label}</p>
      <p className="text-xs text-foreground">{display}</p>
    </div>
  );
}

function LoadingSkeleton() {
  return (
    <div className="space-y-3">
      <div className="grid grid-cols-3 gap-2 sm:grid-cols-6">
        {Array.from({ length: 6 }).map((_, i) => <div key={i} className="h-14 animate-pulse rounded-lg bg-muted/30" />)}
      </div>
      <div className="h-80 animate-pulse rounded-lg bg-muted/30" />
    </div>
  );
}
