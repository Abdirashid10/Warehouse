import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { StockStatusBadge } from '../components/StockStatusBadge';
import { ExpiryStatusBadge } from '../components/ExpiryStatusBadge';
import { enrichInventoryRows, resolveQuantity, summarizeInventoryRows } from '../utils/stockStatus';
import { formatRemainingDays } from '../utils/expiryStatus';
import {
  AlertTriangle,
  Box,
  ClipboardList,
  Loader2,
  Package,
  PackageMinus,
  Search,
  Warehouse,
} from 'lucide-react';

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

export function StaffInventoryPage() {
  const { user } = useAuth();

  const [searchQ, setSearchQ] = useState('');
  const [warehouseFilter, setWarehouseFilter] = useState('');
  const [stockFilter, setStockFilter] = useState('');
  const [expiryFilter, setExpiryFilter] = useState('');

  const tasksPath = '/tasks';

  const { data: rawData, isLoading, isError } = useQuery({
    queryKey: ['inventory', 'tracking', searchQ, warehouseFilter, expiryFilter],
    queryFn: () => fetchTracking(searchQ, warehouseFilter, expiryFilter),
    keepPreviousData: true,
  });

  const { data: warehouseData } = useQuery({
    queryKey: ['warehouses'],
    queryFn: fetchWarehouses,
    staleTime: 120_000,
  });
  const warehouses = warehouseData?.warehouses || [];

  const allRows = useMemo(() => enrichInventoryRows(rawData?.rows || []), [rawData?.rows]);

  const rows = useMemo(() => {
    if (!stockFilter) return allRows;
    return allRows.filter((r) => {
      if (stockFilter === 'low') return r.stock_status === 'Low Stock';
      if (stockFilter === 'out') return r.stock_status === 'Out of Stock';
      if (stockFilter === 'in') return r.stock_status === 'In Stock';
      return true;
    });
  }, [allRows, stockFilter]);

  const summary = useMemo(() => {
    if (!stockFilter && rawData?.summary) return rawData.summary;
    return summarizeInventoryRows(allRows);
  }, [allRows, rawData?.summary, stockFilter]);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-24 text-muted-foreground">
        <Loader2 className="mr-2 h-5 w-5 animate-spin" /> Loading inventory…
      </div>
    );
  }

  return (
    <div className="space-y-4 px-1">
      {/* Header */}
      <div>
        <h1 className="text-lg font-bold text-foreground">Inventory</h1>
        <p className="text-xs text-muted-foreground">
          View stock levels in your assigned warehouses. Operations are completed through assigned tasks.
        </p>
      </div>

      {/* KPI strip */}
      <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
        {[
          { label: 'Total Units', value: summary.total_units?.toLocaleString() || '0', icon: Box, color: 'text-blue-700 dark:text-blue-300', bg: 'bg-blue-50 dark:bg-blue-500/10' },
          { label: 'In Stock', value: summary.in_stock || 0, icon: Package, color: 'text-emerald-600 dark:text-emerald-400', bg: 'bg-emerald-50 dark:bg-emerald-500/10' },
          { label: 'Low Stock', value: summary.low_stock || 0, icon: AlertTriangle, color: 'text-amber-600 dark:text-amber-400', bg: 'bg-amber-50 dark:bg-amber-500/10' },
          { label: 'Out of Stock', value: summary.out_of_stock || 0, icon: PackageMinus, color: 'text-red-600 dark:text-red-400', bg: 'bg-red-50 dark:bg-red-500/10' },
        ].map(({ label, value, icon: Icon, color, bg }) => (
          <div key={label} className="rounded-lg border border-border bg-card px-3 py-2">
            <div className="flex items-center gap-1.5">
              <div className={`flex h-5 w-5 items-center justify-center rounded ${bg}`}><Icon className={`h-3 w-3 ${color}`} /></div>
              <span className="text-[10px] font-medium text-muted-foreground">{label}</span>
            </div>
            <p className={`mt-0.5 text-lg font-bold tabular-nums leading-tight ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      {/* Filters + Quick Actions */}
      <div className="flex flex-wrap items-center gap-2">
        <div className="relative flex-1 max-w-xs">
          <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
          <input type="text" value={searchQ} onChange={(e) => setSearchQ(e.target.value)} placeholder="Search products, SKUs…" className="wms-input h-8 w-full pl-8 text-xs" />
        </div>

        <select value={warehouseFilter} onChange={(e) => setWarehouseFilter(e.target.value)} className="wms-input h-8 text-xs min-w-[120px]">
          <option value="">All Warehouses</option>
          {warehouses.map((w) => <option key={w._id} value={w._id}>{w.name}</option>)}
        </select>

        <div className="flex items-center gap-1">
          {[
            { key: '', label: 'All' },
            { key: 'in', label: 'In Stock' },
            { key: 'low', label: 'Low' },
            { key: 'out', label: 'Out' },
          ].map(({ key, label }) => (
            <button key={key} type="button" onClick={() => setStockFilter(key)} className={`rounded-md px-2 py-1 text-[11px] font-semibold transition ${stockFilter === key ? 'bg-accent text-white' : 'bg-muted/50 text-muted-foreground hover:text-foreground'}`}>{label}</button>
          ))}
        </div>

        <Link
          to={tasksPath}
          className="ml-auto inline-flex items-center gap-1 rounded-md border border-violet-200 bg-violet-50 px-2.5 py-1.5 text-[11px] font-semibold text-violet-700 transition hover:bg-violet-100 dark:border-violet-500/30 dark:bg-violet-500/10 dark:text-violet-300 dark:hover:bg-violet-500/20"
        >
          <ClipboardList className="h-3 w-3" /> My Tasks
        </Link>
      </div>

      {/* Inventory Table */}
      {isError ? (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-3 text-sm text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">Failed to load inventory.</div>
      ) : rows.length === 0 ? (
        <div className="flex flex-col items-center gap-2 rounded-xl border border-dashed border-border bg-muted/10 py-12 text-center">
          <Package className="h-8 w-8 text-muted-foreground/30" />
          <p className="text-sm font-medium text-muted-foreground">{searchQ || warehouseFilter || stockFilter ? 'No matching inventory' : 'No inventory records'}</p>
        </div>
      ) : (
        <div className="overflow-x-auto rounded-lg border border-border">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-border bg-muted/30 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
                <th className="px-3 py-2.5">Product</th>
                <th className="px-3 py-2.5">Warehouse</th>
                <th className="px-3 py-2.5 text-right">Quantity</th>
                <th className="px-3 py-2.5">Status</th>
                <th className="px-3 py-2.5 hidden md:table-cell">Expiry</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/50">
              {rows.map((row) => {
                const product = row.product || {};
                const warehouse = row.warehouse || {};
                return (
                  <tr key={row._id || row.id} className="transition hover:bg-muted/20">
                    <td className="px-3 py-2">
                      <p className="font-semibold text-foreground">{product.name || '—'}</p>
                      <p className="text-[10px] text-muted-foreground">{product.sku || '—'}</p>
                    </td>
                    <td className="px-3 py-2">
                      <span className="inline-flex items-center gap-1 text-muted-foreground">
                        <Warehouse className="h-3 w-3" /> {warehouse.name || '—'}
                      </span>
                    </td>
                    <td className="px-3 py-2 text-right">
                      <span className="font-bold tabular-nums text-foreground">
                        {resolveQuantity(row).toLocaleString()}
                      </span>
                      {row.available_stock > 0 && row.available_stock !== resolveQuantity(row) ? (
                        <p className="text-[9px] text-emerald-600 dark:text-emerald-400">
                          {row.available_stock} available
                        </p>
                      ) : null}
                      {row.min_stock_threshold > 0 ? (
                        <p className="text-[9px] text-muted-foreground">min: {row.min_stock_threshold}</p>
                      ) : null}
                    </td>
                    <td className="px-3 py-2"><StockStatusBadge status={row.stock_status} /></td>
                    <td className="px-3 py-2 hidden md:table-cell">
                      {row.expiry_date ? (
                        <div className="flex items-center gap-1.5">
                          <ExpiryStatusBadge status={row.expiry_status} />
                          <span className="text-[10px] text-muted-foreground">
                            {formatRemainingDays(row.days_until_expiry)}
                          </span>
                        </div>
                      ) : (
                        <span className="text-[10px] text-muted-foreground">—</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Footer */}
      {rows.length > 0 && (
        <p className="text-[11px] text-muted-foreground">
          Showing {rows.length} inventory lines
          {stockFilter && ` (filtered from ${allRows.length})`}
        </p>
      )}

    </div>
  );
}
