import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import {
  AlertTriangle,
  ArrowDownToLine,
  ArrowRightLeft,
  BarChart3,
  Box,
  ChevronDown,
  ChevronRight,
  DollarSign,
  Download,
  FileBarChart,
  FileSpreadsheet,
  FileText,
  Loader2,
  Package,
  PiggyBank,
  Printer,
  RefreshCw,
  Search,
  TrendingDown,
  TrendingUp,
  Warehouse,
} from 'lucide-react';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { canAccessReports } from '../utils/roles';
import { formatMoney } from '../utils/productHelpers';
import { generateInventoryAuditPdf } from '../utils/inventoryReportPdf';
import { ActivityReportsPanel } from '../components/reports/ActivityReportsPanel';
import { MovementTypeBadge } from '../components/MovementTypeBadge';
import { chartAxisProps, chartLegendProps, chartTooltipStyle, useChartTheme } from '../hooks/useChartTheme';

async function fetchInventoryAudit() {
  const { data } = await api.get('/reports/inventory-audit');
  return data;
}

/* ─── Colors ─── */

const CONDITION_COLORS = {
  available: '#059669',
  damaged: '#dc2626',
  inspection: '#d97706',
};

/* ─── Helpers ─── */

function fmt(n) {
  return Number(n || 0).toLocaleString();
}

function relDate(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  return d.toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

/* ═══════════════════════════════════════════════════════════════
   MAIN EXPORT
   ═══════════════════════════════════════════════════════════════ */

export function ReportsPage() {
  const { user } = useAuth();
  const chart = useChartTheme();
  const axisProps = chartAxisProps(chart);
  const legendProps = chartLegendProps(chart);
  const tooltipStyle = chartTooltipStyle(chart);
  const allowed = canAccessReports(user?.role);
  const [pdfLoading, setPdfLoading] = useState(false);
  const [pdfError, setPdfError] = useState('');
  const [activeTab, setActiveTab] = useState('overview');
  const [searchQ, setSearchQ] = useState('');
  const [expandedAudit, setExpandedAudit] = useState(null);

  const { data, isLoading, isError, error, refetch, isFetching } = useQuery({
    queryKey: ['reports', 'inventory-audit'],
    queryFn: fetchInventoryAudit,
    enabled: allowed,
    staleTime: 0,
    refetchOnMount: 'always',
  });

  const fs = data?.financial_summary;
  const warehouses = data?.warehouse_comparison || [];
  const condition = data?.condition_breakdown;
  const fastMoving = data?.fast_moving_products || [];
  const auditTrail = data?.audit_trail || [];
  const lowStockAlerts = data?.low_stock_alerts || [];
  const inventoryDetail = data?.inventory_detail || [];

  const warehouseChartData = useMemo(
    () => warehouses.map((w) => ({ name: w.warehouse_name, cost_value: w.cost_value, total_units: w.total_units })),
    [warehouses]
  );

  const conditionChartData = useMemo(() => {
    if (!condition) return [];
    return [
      { name: 'Available / Good', key: 'available', value: condition.available_qty, pct: condition.available_pct },
      { name: 'Damaged / Defective', key: 'damaged', value: condition.damaged_qty, pct: condition.damaged_pct },
      { name: 'Under Inspection', key: 'inspection', value: condition.inspection_qty, pct: condition.inspection_pct },
    ].filter((d) => d.value > 0);
  }, [condition]);

  const filteredAlerts = useMemo(() => {
    if (!searchQ) return lowStockAlerts;
    const q = searchQ.toLowerCase();
    return lowStockAlerts.filter((a) =>
      (a.product_name || '').toLowerCase().includes(q) ||
      (a.sku || '').toLowerCase().includes(q) ||
      (a.warehouse || '').toLowerCase().includes(q)
    );
  }, [lowStockAlerts, searchQ]);

  const filteredDetail = useMemo(() => {
    if (!searchQ) return inventoryDetail;
    const q = searchQ.toLowerCase();
    return inventoryDetail.filter((r) =>
      (r.product_name || '').toLowerCase().includes(q) ||
      (r.sku || '').toLowerCase().includes(q) ||
      (r.warehouse_name || '').toLowerCase().includes(q)
    );
  }, [inventoryDetail, searchQ]);

  async function handleDownloadPdf() {
    if (!data) return;
    setPdfError('');
    setPdfLoading(true);
    try {
      generateInventoryAuditPdf(data, { user });
    } catch (err) {
      setPdfError(err.message || 'PDF generation failed');
    } finally {
      setPdfLoading(false);
    }
  }

  function handleExportCSV() {
    if (!inventoryDetail.length) return;
    const headers = ['SKU', 'Product', 'Category', 'Warehouse', 'Qty', 'Status', 'Good', 'Damaged', 'Unit Cost', 'Line Value'];
    const rows = inventoryDetail.map((r) => [r.sku, r.product_name, r.category, r.warehouse_name, r.current_quantity, r.stock_status, r.good_qty, r.damaged_qty, r.unit_cost, r.line_cost_value]);
    const csv = [headers, ...rows].map((r) => r.map((c) => `"${String(c ?? '').replace(/"/g, '""')}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `inventory-report-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  if (!allowed) {
    return (
      <div className="flex flex-col items-center justify-center gap-3 py-20 text-center">
        <FileBarChart className="h-10 w-10 text-muted-foreground/20" />
        <h1 className="text-lg font-bold text-foreground">Access Restricted</h1>
        <p className="text-xs text-muted-foreground">Reports are available to Admin and Supervisor roles only.</p>
      </div>
    );
  }

  const TABS = [
    { id: 'overview', label: 'Overview' },
    { id: 'inventory', label: 'Inventory Detail' },
    { id: 'alerts', label: `Risk Alerts${lowStockAlerts.length ? ` (${lowStockAlerts.length})` : ''}` },
    { id: 'audit', label: 'Audit Trail' },
  ];

  return (
    <div className="space-y-4 px-1">

      {/* ── Header ── */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-lg font-bold text-foreground">Reports & Intelligence</h1>
          <p className="text-xs text-muted-foreground">
            Warehouse analytics, financial metrics & operational intelligence
            {data?.generated_at && (
              <> · Updated {relDate(data.generated_at)}{isFetching ? ' · Refreshing…' : ''}</>
            )}
          </p>
        </div>
        <div className="flex items-center gap-1.5 shrink-0">
          <button type="button" onClick={() => refetch()} disabled={isFetching} className="inline-flex items-center gap-1 rounded-md border border-border px-2 py-1.5 text-[11px] font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground disabled:opacity-50" title="Refresh data">
            <RefreshCw className={`h-3 w-3 ${isFetching ? 'animate-spin' : ''}`} /> Refresh
          </button>
          <ExportMenu
            onPdf={handleDownloadPdf}
            onCsv={handleExportCSV}
            pdfLoading={pdfLoading}
            disabled={!data || isLoading}
          />
        </div>
      </div>

      {pdfError && <ErrorBanner message={pdfError} />}

      {!isLoading && !isError && <ActivityReportsPanel />}

      {isLoading ? (
        <LoadingSkeleton />
      ) : isError ? (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-3 text-xs text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
          {error?.response?.data?.message || 'Could not load report data.'}
          <button type="button" onClick={() => refetch()} className="ml-2 underline">Retry</button>
        </div>
      ) : fs ? (
        <>
          {/* ── KPI Cards ── */}
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
            <KpiCard label="Cost Valuation" value={formatMoney(fs.cost_value)} icon={DollarSign} color="text-sky-600 dark:text-sky-400" bg="bg-sky-50 dark:bg-sky-500/10" sub="Σ qty × unit cost" />
            <KpiCard label="Retail Value" value={formatMoney(fs.retail_value)} icon={TrendingUp} color="text-emerald-600 dark:text-emerald-400" bg="bg-emerald-50 dark:bg-emerald-500/10" sub="Σ qty × unit price" />
            <KpiCard label="Units on Hand" value={fmt(fs.total_units)} icon={Package} color="text-violet-600 dark:text-violet-400" bg="bg-violet-50 dark:bg-violet-500/10" sub={`${fs.inventory_lines} lines · ${fs.product_count} SKUs`} />
            <KpiCard label="Est. Profit" value={formatMoney(fs.estimated_profit)} icon={PiggyBank} color="text-amber-600 dark:text-amber-400" bg="bg-amber-50 dark:bg-amber-500/10" sub="Retail − cost" />
          </div>

          {/* ── Insight Strips ── */}
          {(lowStockAlerts.length > 0 || warehouses.length > 0) && (
            <div className="flex flex-wrap gap-2">
              {lowStockAlerts.length > 0 && (
                <InsightChip icon={AlertTriangle} color="text-amber-600 dark:text-amber-400 bg-amber-50 dark:bg-amber-500/10 border-amber-200 dark:border-amber-500/20" text={`${lowStockAlerts.length} stock risk alert${lowStockAlerts.length !== 1 ? 's' : ''} require attention`} onClick={() => setActiveTab('alerts')} />
              )}
              {warehouses.length > 0 && (() => {
                const top = [...warehouses].sort((a, b) => (b.total_units || 0) - (a.total_units || 0))[0];
                return top ? <InsightChip icon={Warehouse} color="text-sky-600 dark:text-sky-400 bg-sky-50 dark:bg-sky-500/10 border-sky-200 dark:border-sky-500/20" text={`${top.warehouse_name} holds most inventory (${fmt(top.total_units)} units)`} /> : null;
              })()}
              {fastMoving.length > 0 && (
                <InsightChip icon={TrendingDown} color="text-violet-600 dark:text-violet-400 bg-violet-50 dark:bg-violet-500/10 border-violet-200 dark:border-violet-500/20" text={`Top mover: ${fastMoving[0].product_name} (${fmt(fastMoving[0].outbound_units)} outbound)`} />
              )}
            </div>
          )}

          {/* ── Tab Navigation ── */}
          <div className="flex items-center gap-0.5 border-b border-border">
            {TABS.map((tab) => (
              <button key={tab.id} type="button" onClick={() => setActiveTab(tab.id)} className={`relative px-3 py-2 text-[11px] font-semibold transition ${activeTab === tab.id ? 'text-foreground' : 'text-muted-foreground hover:text-foreground'}`}>
                {tab.label}
                {activeTab === tab.id && <span className="absolute inset-x-0 -bottom-px h-0.5 bg-accent rounded-full" />}
              </button>
            ))}
          </div>

          {/* ── Tab Content ── */}
          {activeTab === 'overview' && (
            <OverviewTab
              warehouseChartData={warehouseChartData}
              conditionChartData={conditionChartData}
              condition={condition}
              fastMoving={fastMoving}
              warehouses={warehouses}
              chart={chart}
              axisProps={axisProps}
              legendProps={legendProps}
              tooltipStyle={tooltipStyle}
            />
          )}

          {activeTab === 'inventory' && (
            <InventoryDetailTab
              detail={filteredDetail}
              total={inventoryDetail.length}
              searchQ={searchQ}
              setSearchQ={setSearchQ}
            />
          )}

          {activeTab === 'alerts' && (
            <AlertsTab
              alerts={filteredAlerts}
              total={lowStockAlerts.length}
              searchQ={searchQ}
              setSearchQ={setSearchQ}
            />
          )}

          {activeTab === 'audit' && (
            <AuditTab
              trail={auditTrail}
              expanded={expandedAudit}
              setExpanded={setExpandedAudit}
            />
          )}
        </>
      ) : null}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   OVERVIEW TAB
   ═══════════════════════════════════════════════════════════════ */

function OverviewTab({ warehouseChartData, conditionChartData, condition, fastMoving, warehouses, chart, axisProps, legendProps, tooltipStyle }) {
  return (
    <div className="space-y-4">
      {/* Charts row */}
      <div className="grid gap-3 lg:grid-cols-2">
        {/* Warehouse Comparison */}
        <div className="rounded-lg border border-border bg-card">
          <div className="border-b border-border/60 px-4 py-2.5">
            <h3 className="text-xs font-bold text-foreground">Warehouse Comparison</h3>
            <p className="text-[10px] text-muted-foreground">Cost value and unit volume by site</p>
          </div>
          <div className="h-64 px-2 py-2">
            {warehouseChartData.length ? (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={warehouseChartData} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke={chart.grid} vertical={false} />
                  <XAxis dataKey="name" {...axisProps} tick={{ ...axisProps.tick, fontSize: 10 }} />
                  <YAxis yAxisId="left" {...axisProps} tick={{ ...axisProps.tick, fontSize: 10 }} tickFormatter={(v) => `$${(v / 1000).toFixed(0)}k`} />
                  <YAxis yAxisId="right" orientation="right" {...axisProps} tick={{ ...axisProps.tick, fontSize: 10 }} />
                  <Tooltip contentStyle={tooltipStyle} labelStyle={{ color: chart.tooltipText, fontWeight: 600 }} />
                  <Legend {...legendProps} wrapperStyle={{ ...legendProps.wrapperStyle, fontSize: 10 }} />
                  <Bar yAxisId="left" dataKey="cost_value" name="Cost value ($)" fill="#0ea5e9" radius={[3, 3, 0, 0]} />
                  <Bar yAxisId="right" dataKey="total_units" name="Units on hand" fill="#a78bfa" radius={[3, 3, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <ChartEmpty label="No warehouse stock data" />
            )}
          </div>
        </div>

        {/* Condition Distribution */}
        <div className="rounded-lg border border-border bg-card">
          <div className="border-b border-border/60 px-4 py-2.5">
            <h3 className="text-xs font-bold text-foreground">Inventory Quality</h3>
            <p className="text-[10px] text-muted-foreground">System-wide condition distribution</p>
          </div>
          <div className="flex h-64 items-center px-2 py-2">
            {conditionChartData.length ? (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={conditionChartData}
                    dataKey="value"
                    nameKey="name"
                    cx="50%"
                    cy="50%"
                    innerRadius={45}
                    outerRadius={70}
                    paddingAngle={2}
                    label={({ name, pct }) => `${name.split('/')[0].trim()} ${pct}%`}
                    labelLine={{ stroke: chart.axis }}
                  >
                    {conditionChartData.map((entry) => (
                      <Cell key={entry.key} fill={CONDITION_COLORS[entry.key] || '#64748b'} />
                    ))}
                  </Pie>
                  <Tooltip contentStyle={tooltipStyle} labelStyle={{ color: chart.tooltipText, fontWeight: 600 }} formatter={(value, name) => [`${value} units`, name]} />
                  <Legend {...legendProps} wrapperStyle={{ ...legendProps.wrapperStyle, fontSize: 10 }} />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <ChartEmpty label="No condition data" />
            )}
          </div>
          {condition && (
            <div className="grid grid-cols-3 gap-px border-t border-border/60 text-center">
              <CondStat label="Good" pct={condition.available_pct} color="text-emerald-500" />
              <CondStat label="Damaged" pct={condition.damaged_pct} color="text-red-500" />
              <CondStat label="Inspection" pct={condition.inspection_pct} color="text-amber-500" />
            </div>
          )}
        </div>
      </div>

      {/* Bottom: Fast moving + Warehouse breakdown */}
      <div className="grid gap-3 lg:grid-cols-2">
        {/* Fast Moving */}
        <div className="rounded-lg border border-border bg-card">
          <div className="border-b border-border/60 px-4 py-2.5">
            <h3 className="text-xs font-bold text-foreground">Top Fast-Moving Products</h3>
            <p className="text-[10px] text-muted-foreground">By outbound volume (last {fastMoving[0]?.period_days ?? 90} days)</p>
          </div>
          {fastMoving.length ? (
            <div className="divide-y divide-border/40">
              {fastMoving.map((row) => (
                <div key={row.product_id || row.rank} className="flex items-center gap-3 px-4 py-2 transition hover:bg-muted/30">
                  <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded bg-accent/10 text-[10px] font-bold text-accent">{row.rank}</span>
                  <div className="min-w-0 flex-1">
                    <p className="text-xs font-semibold text-foreground truncate">{row.product_name}</p>
                    <p className="text-[10px] text-muted-foreground">{row.sku} · {row.category}</p>
                  </div>
                  <span className="text-xs font-bold tabular-nums text-accent">{fmt(row.outbound_units)}</span>
                </div>
              ))}
            </div>
          ) : (
            <div className="flex items-center justify-center py-10 text-[11px] text-muted-foreground">No outbound movements in this period</div>
          )}
        </div>

        {/* Warehouse Breakdown */}
        <div className="rounded-lg border border-border bg-card">
          <div className="border-b border-border/60 px-4 py-2.5">
            <h3 className="text-xs font-bold text-foreground">Warehouse Breakdown</h3>
            <p className="text-[10px] text-muted-foreground">Valuation and units by location</p>
          </div>
          {warehouses.length ? (
            <div className="divide-y divide-border/40">
              {warehouses.map((w) => (
                <div key={w.warehouse_id} className="flex items-center gap-3 px-4 py-2 transition hover:bg-muted/30">
                  <div className="flex h-6 w-6 shrink-0 items-center justify-center rounded bg-sky-50 dark:bg-sky-500/10">
                    <Warehouse className="h-3 w-3 text-sky-600 dark:text-sky-400" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-xs font-semibold text-foreground truncate">{w.warehouse_name}</p>
                    <p className="text-[10px] text-muted-foreground">{fmt(w.total_units)} units</p>
                  </div>
                  <div className="text-right">
                    <p className="text-xs font-bold tabular-nums text-foreground">{formatMoney(w.cost_value)}</p>
                    <p className="text-[9px] text-muted-foreground tabular-nums">{formatMoney(w.retail_value)} retail</p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="flex items-center justify-center py-10 text-[11px] text-muted-foreground">No warehouse data</div>
          )}
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   INVENTORY DETAIL TAB
   ═══════════════════════════════════════════════════════════════ */

function InventoryDetailTab({ detail, total, searchQ, setSearchQ }) {
  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2">
        <div className="relative flex-1 max-w-xs">
          <Search className="absolute left-2.5 top-1/2 h-3 w-3 -translate-y-1/2 text-muted-foreground" />
          <input type="text" value={searchQ} onChange={(e) => setSearchQ(e.target.value)} placeholder="Search product, SKU, warehouse…" className="wms-input h-7 w-full pl-7 text-[11px]" />
        </div>
        <span className="text-[10px] text-muted-foreground">{detail.length === total ? `${total} lines` : `${detail.length} of ${total}`}</span>
      </div>

      <div className="rounded-lg border border-border bg-card overflow-x-auto">
        <table className="min-w-full text-left text-[11px]">
          <thead>
            <tr className="border-b border-border bg-muted/30">
              <th className="px-3 py-2 font-semibold text-muted-foreground">SKU</th>
              <th className="px-3 py-2 font-semibold text-muted-foreground">Product</th>
              <th className="px-3 py-2 font-semibold text-muted-foreground hidden sm:table-cell">Category</th>
              <th className="px-3 py-2 font-semibold text-muted-foreground hidden md:table-cell">Warehouse</th>
              <th className="px-3 py-2 font-semibold text-muted-foreground text-right">Qty</th>
              <th className="px-3 py-2 font-semibold text-muted-foreground text-center">Status</th>
              <th className="px-3 py-2 font-semibold text-muted-foreground text-right hidden lg:table-cell">Condition</th>
              <th className="px-3 py-2 font-semibold text-muted-foreground text-right hidden xl:table-cell">Unit Cost</th>
              <th className="px-3 py-2 font-semibold text-muted-foreground text-right">Line Value</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border/40">
            {detail.length ? detail.map((row) => (
              <tr key={row.id} className={`transition hover:bg-muted/20 ${row.stock_status === 'Out of Stock' ? 'bg-red-50/30 dark:bg-red-500/5' : row.stock_status === 'Low Stock' ? 'bg-amber-50/30 dark:bg-amber-500/5' : ''}`}>
                <td className="px-3 py-1.5 font-mono text-[10px] text-muted-foreground">{row.sku}</td>
                <td className="px-3 py-1.5 font-medium text-foreground">{row.product_name}</td>
                <td className="px-3 py-1.5 text-muted-foreground hidden sm:table-cell">{row.category}</td>
                <td className="px-3 py-1.5 text-muted-foreground hidden md:table-cell">{row.warehouse_name}</td>
                <td className="px-3 py-1.5 text-right font-semibold tabular-nums text-foreground">{fmt(row.current_quantity)}</td>
                <td className="px-3 py-1.5 text-center"><StockBadge status={row.stock_status} /></td>
                <td className="px-3 py-1.5 text-right text-[10px] text-muted-foreground hidden lg:table-cell">G:{row.good_qty} D:{row.damaged_qty}</td>
                <td className="px-3 py-1.5 text-right tabular-nums text-muted-foreground hidden xl:table-cell">{formatMoney(row.unit_cost)}</td>
                <td className="px-3 py-1.5 text-right font-semibold tabular-nums text-foreground">{formatMoney(row.line_cost_value)}</td>
              </tr>
            )) : (
              <tr><td colSpan={9} className="px-4 py-10 text-center text-xs text-muted-foreground">{searchQ ? 'No matching inventory lines' : 'No inventory records'}</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   ALERTS TAB
   ═══════════════════════════════════════════════════════════════ */

function AlertsTab({ alerts, total, searchQ, setSearchQ }) {
  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2">
        <div className="relative flex-1 max-w-xs">
          <Search className="absolute left-2.5 top-1/2 h-3 w-3 -translate-y-1/2 text-muted-foreground" />
          <input type="text" value={searchQ} onChange={(e) => setSearchQ(e.target.value)} placeholder="Search alerts…" className="wms-input h-7 w-full pl-7 text-[11px]" />
        </div>
        <span className="text-[10px] text-muted-foreground">{alerts.length === total ? `${total} alerts` : `${alerts.length} of ${total}`}</span>
      </div>

      {alerts.length ? (
        <div className="rounded-lg border border-border bg-card overflow-x-auto">
          <table className="min-w-full text-left text-[11px]">
            <thead>
              <tr className="border-b border-border bg-amber-50/50 dark:bg-amber-500/5">
                <th className="px-3 py-2 font-semibold text-muted-foreground">SKU</th>
                <th className="px-3 py-2 font-semibold text-muted-foreground">Product</th>
                <th className="px-3 py-2 font-semibold text-muted-foreground hidden sm:table-cell">Warehouse</th>
                <th className="px-3 py-2 font-semibold text-muted-foreground text-right">On Hand</th>
                <th className="px-3 py-2 font-semibold text-muted-foreground text-right hidden md:table-cell">Min</th>
                <th className="px-3 py-2 font-semibold text-muted-foreground text-center">Status</th>
                <th className="px-3 py-2 font-semibold text-muted-foreground text-right hidden lg:table-cell">Cost Value</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/40">
              {alerts.map((a, i) => (
                <tr key={`${a.sku}-${a.warehouse}-${i}`} className={`transition hover:bg-muted/20 ${a.stock_status === 'Out of Stock' ? 'bg-red-50/30 dark:bg-red-500/5' : ''}`}>
                  <td className="px-3 py-1.5 font-mono text-[10px] text-muted-foreground">{a.sku}</td>
                  <td className="px-3 py-1.5 font-medium text-foreground">{a.product_name}</td>
                  <td className="px-3 py-1.5 text-muted-foreground hidden sm:table-cell">{a.warehouse}</td>
                  <td className="px-3 py-1.5 text-right font-semibold tabular-nums text-foreground">{a.current_quantity}</td>
                  <td className="px-3 py-1.5 text-right tabular-nums text-muted-foreground hidden md:table-cell">{a.min_stock_threshold}</td>
                  <td className="px-3 py-1.5 text-center"><StockBadge status={a.stock_status} /></td>
                  <td className="px-3 py-1.5 text-right tabular-nums text-muted-foreground hidden lg:table-cell">{formatMoney(a.line_cost_value)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="flex flex-col items-center gap-2 rounded-xl border border-dashed border-border bg-muted/10 py-12 text-center">
          <AlertTriangle className="h-8 w-8 text-muted-foreground/15" />
          <p className="text-xs text-muted-foreground">{searchQ ? 'No matching alerts' : 'All inventory lines are above minimum thresholds'}</p>
        </div>
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   AUDIT TAB
   ═══════════════════════════════════════════════════════════════ */

function AuditTab({ trail, expanded, setExpanded }) {
  return (
    <div className="space-y-3">
      <p className="text-[10px] text-muted-foreground">{trail.length} latest warehouse operations</p>

      {trail.length ? (
        <div className="rounded-lg border border-border bg-card overflow-x-auto">
          <table className="min-w-full text-left text-[11px]">
            <thead>
              <tr className="border-b border-border bg-muted/30">
                <th className="w-8 px-2 py-2" />
                <th className="px-3 py-2 font-semibold text-muted-foreground">Type</th>
                <th className="px-3 py-2 font-semibold text-muted-foreground">Product</th>
                <th className="px-3 py-2 font-semibold text-muted-foreground hidden sm:table-cell">Route</th>
                <th className="px-3 py-2 font-semibold text-muted-foreground hidden md:table-cell">User</th>
                <th className="px-3 py-2 font-semibold text-muted-foreground hidden lg:table-cell">When</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/40">
              {trail.map((row) => {
                const isExpanded = expanded === row.id;
                return (
                  <AuditRow key={row.id} row={row} isExpanded={isExpanded} onToggle={() => setExpanded(isExpanded ? null : row.id)} />
                );
              })}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="flex flex-col items-center gap-2 rounded-xl border border-dashed border-border bg-muted/10 py-12 text-center">
          <ArrowRightLeft className="h-8 w-8 text-muted-foreground/15" />
          <p className="text-xs text-muted-foreground">No movements recorded yet</p>
        </div>
      )}
    </div>
  );
}

function AuditRow({ row, isExpanded, onToggle }) {
  const route = row.source_location && row.destination_location
    ? `${row.source_location} → ${row.destination_location}`
    : row.warehouse_name;
  return (
    <>
      <tr className="transition hover:bg-muted/20 cursor-pointer" onClick={onToggle}>
        <td className="px-2 py-1.5">
          <ChevronRight className={`h-3 w-3 text-muted-foreground transition-transform ${isExpanded ? 'rotate-90' : ''}`} />
        </td>
        <td className="px-3 py-1.5"><MovementTypeBadge type={row.type} /></td>
        <td className="px-3 py-1.5">
          <span className="font-mono text-[10px] text-foreground">{row.product_sku}</span>
        </td>
        <td className="px-3 py-1.5 text-muted-foreground hidden sm:table-cell max-w-[160px] truncate">{route}</td>
        <td className="px-3 py-1.5 hidden md:table-cell">
          <span className="text-xs text-muted-foreground">{row.performed_by}</span>
          {row.performed_by_role && <span className="ml-1 text-[9px] text-muted-foreground/60">{row.performed_by_role}</span>}
        </td>
        <td className="px-3 py-1.5 text-muted-foreground hidden lg:table-cell whitespace-nowrap">{relDate(row.created_at)}</td>
      </tr>
      {isExpanded && (
        <tr>
          <td colSpan={6} className="bg-muted/10 px-4 py-3">
            <div className="grid grid-cols-2 gap-x-6 gap-y-1.5 text-[11px] sm:grid-cols-3">
              <DetailField label="Type" value={row.type} />
              <DetailField label="Product" value={`${row.product_sku} — ${row.product_name}`} />
              <DetailField label="Quantity" value={row.quantity} />
              <DetailField label="Warehouse" value={row.warehouse_name} />
              {row.to_warehouse_name && <DetailField label="Destination" value={row.to_warehouse_name} />}
              <DetailField label="Performed By" value={`${row.performed_by}${row.performed_by_role ? ` (${row.performed_by_role})` : ''}`} />
              <DetailField label="Date & Time" value={relDate(row.created_at)} />
              {row.reason && <DetailField label="Reason/Notes" value={row.reason} />}
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

function KpiCard({ label, value, icon: Icon, color, bg, sub }) {
  return (
    <div className="rounded-lg border border-border bg-card px-3 py-2.5">
      <div className="flex items-center gap-1.5">
        <div className={`flex h-5 w-5 items-center justify-center rounded ${bg}`}>
          <Icon className={`h-3 w-3 ${color}`} strokeWidth={2.2} />
        </div>
        <span className="text-[9px] font-semibold uppercase tracking-wider text-muted-foreground">{label}</span>
      </div>
      <p className={`mt-1 text-base font-bold tabular-nums leading-tight ${color}`}>{value}</p>
      {sub && <p className="mt-0.5 text-[9px] text-muted-foreground">{sub}</p>}
    </div>
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

function ExportMenu({ onPdf, onCsv, pdfLoading, disabled }) {
  const [open, setOpen] = useState(false);
  return (
    <div className="relative">
      <button type="button" onClick={() => setOpen(!open)} disabled={disabled} className="inline-flex items-center gap-1 rounded-lg border border-accent bg-accent px-2.5 py-1.5 text-[11px] font-semibold text-white shadow-sm transition hover:bg-accent/90 active:scale-[0.97] disabled:opacity-50">
        <Download className="h-3 w-3" /> Export <ChevronDown className="h-3 w-3" />
      </button>
      {open && (
        <>
          <div className="fixed inset-0 z-30" onClick={() => setOpen(false)} />
          <div className="absolute right-0 top-full z-40 mt-1 w-44 rounded-lg border border-border bg-card py-1 shadow-xl">
            <ExportOption icon={FileText} label="Download PDF" sub="Executive audit report" onClick={() => { onPdf(); setOpen(false); }} loading={pdfLoading} />
            <ExportOption icon={FileSpreadsheet} label="Export CSV" sub="Inventory detail data" onClick={() => { onCsv(); setOpen(false); }} />
            <ExportOption icon={Printer} label="Print Report" sub="Browser print dialog" onClick={() => { window.print(); setOpen(false); }} />
          </div>
        </>
      )}
    </div>
  );
}

function ExportOption({ icon: Icon, label, sub, onClick, loading }) {
  return (
    <button type="button" onClick={onClick} disabled={loading} className="flex w-full items-center gap-2.5 px-3 py-2 text-left transition hover:bg-muted disabled:opacity-50">
      {loading ? <Loader2 className="h-3.5 w-3.5 animate-spin text-accent" /> : <Icon className="h-3.5 w-3.5 text-muted-foreground" />}
      <div>
        <p className="text-[11px] font-semibold text-foreground">{label}</p>
        <p className="text-[9px] text-muted-foreground">{sub}</p>
      </div>
    </button>
  );
}

function StockBadge({ status }) {
  const cls =
    status === 'Out of Stock' ? 'bg-red-100 text-red-700 dark:bg-red-500/15 dark:text-red-400' :
    status === 'Low Stock' ? 'bg-amber-100 text-amber-700 dark:bg-amber-500/15 dark:text-amber-400' :
    'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/15 dark:text-emerald-400';
  return <span className={`inline-block rounded px-1.5 py-0.5 text-[9px] font-bold ${cls}`}>{status}</span>;
}

function CondStat({ label, pct, color }) {
  return (
    <div className="py-2">
      <span className={`block text-xs font-bold ${color}`}>{pct}%</span>
      <span className="text-[9px] text-muted-foreground">{label}</span>
    </div>
  );
}

function DetailField({ label, value }) {
  return (
    <div>
      <p className="text-[9px] font-semibold uppercase tracking-wider text-muted-foreground">{label}</p>
      <p className="text-xs text-foreground">{value ?? '—'}</p>
    </div>
  );
}

function ChartEmpty({ label }) {
  return (
    <div className="flex h-full flex-col items-center justify-center gap-1">
      <BarChart3 className="h-6 w-6 text-muted-foreground/15" />
      <p className="text-[11px] text-muted-foreground">{label}</p>
    </div>
  );
}

function ErrorBanner({ message }) {
  return (
    <div className="flex items-start gap-2 rounded-md border border-red-200 bg-red-50 px-3 py-2 text-[11px] font-medium text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
      <AlertTriangle className="mt-0.5 h-3 w-3 shrink-0" /> {message}
    </div>
  );
}

function LoadingSkeleton() {
  return (
    <div className="space-y-3">
      <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => <div key={i} className="h-20 animate-pulse rounded-lg bg-muted/30" />)}
      </div>
      <div className="grid gap-3 lg:grid-cols-2">
        <div className="h-72 animate-pulse rounded-lg bg-muted/30" />
        <div className="h-72 animate-pulse rounded-lg bg-muted/30" />
      </div>
    </div>
  );
}
