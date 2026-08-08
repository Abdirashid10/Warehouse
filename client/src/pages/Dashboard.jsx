import { useEffect, useMemo, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  Area,
  AreaChart,
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
  Activity,
  AlertTriangle,
  ArrowDownRight,
  ArrowRight,
  ArrowRightLeft,
  ArrowUpRight,
  BarChart3,
  Box,
  CheckCircle2,
  CircleAlert,
  ClipboardList,
  Clock,
  FileBarChart,
  Layers,
  ListTodo,
  Package,
  PackageMinus,
  PackagePlus,
  PieChart as PieChartIcon,
  Plus,
  RotateCcw,
  ShoppingCart,
  ShieldAlert,
  ShieldCheck,
  Sparkles,
  Timer,
  TrendingDown,
  TrendingUp,
  Truck,
  User as UserIcon,
  Warehouse,
  Wrench,
} from 'lucide-react';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { OrderStatusBadge } from '../components/OrderStatusBadge';
import { MovementQuantityCell } from '../components/MovementQuantityCell';
import { PageShell } from '../components/layout/PageShell';
import { SkeletonCard } from '../components/ui/skeleton';
import {
  useChartTheme,
  chartAxisProps,
  chartLegendProps,
  chartTooltipStyle,
} from '../hooks/useChartTheme';
import { ActivityReportsPanel } from '../components/reports/ActivityReportsPanel';

/* ═══════════════════════════════════════════
   UTILITIES
   ═══════════════════════════════════════════ */
const fetchStats = async () => (await api.get('/dashboard/stats')).data;
const fetchWidgets = async () => (await api.get('/dashboard/widgets')).data;

function fmt(n) {
  if (n == null || Number.isNaN(n)) return '—';
  return Number(n).toLocaleString();
}
function fmtCompact(n) {
  if (n == null) return '—';
  const v = Number(n);
  if (v >= 1e6) return `${(v / 1e6).toFixed(1)}M`;
  if (v >= 1e3) return `${(v / 1e3).toFixed(1)}K`;
  return v.toLocaleString();
}
function fmtMoney(n) {
  if (n == null || Number.isNaN(n)) return '—';
  return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(n);
}
function relTime(d) {
  if (!d) return '';
  const s = Math.floor((Date.now() - new Date(d).getTime()) / 1000);
  if (s < 60) return 'just now';
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  return `${Math.floor(h / 24)}d ago`;
}
function pct(part, total) { return total ? ((part / total) * 100).toFixed(1) : '0'; }

const MV_ICON = { INBOUND: ArrowDownRight, OUTBOUND: ArrowUpRight, TRANSFER: ArrowRightLeft, ADJUSTMENT: Wrench, RETURN: RotateCcw };
const MV_DOT = { INBOUND: 'dash-timeline-dot--inbound', OUTBOUND: 'dash-timeline-dot--outbound', TRANSFER: 'dash-timeline-dot--transfer', ADJUSTMENT: 'dash-timeline-dot--adjustment', RETURN: 'dash-timeline-dot--return' };

/* ═══════════════════════════════════════════
   REUSABLE PRIMITIVES
   ═══════════════════════════════════════════ */
function EmptyChart({ message, icon: Icon = BarChart3 }) {
  return (
    <div className="flex h-full flex-col items-center justify-center gap-2 text-muted-foreground">
      <div className="rounded-xl bg-muted/40 p-3"><Icon className="h-6 w-6 opacity-40" strokeWidth={1.5} /></div>
      <p className="text-xs font-medium">{message}</p>
    </div>
  );
}

function ChartBox({ title, sub, badge, children, className = '' }) {
  return (
    <div className={`dash-chart-wrap ${className}`}>
      <div className="dash-chart-header">
        <div className="min-w-0">
          <h3 className="dash-chart-title">{title}</h3>
          {sub && <p className="dash-chart-sub mt-0.5">{sub}</p>}
        </div>
        {badge}
      </div>
      {children}
    </div>
  );
}

function ChartBadge({ children, variant = 'default' }) {
  const cls = { default: 'bg-muted/60 text-muted-foreground', success: 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400', warning: 'bg-amber-500/10 text-amber-600 dark:text-amber-400', danger: 'bg-red-500/10 text-red-600 dark:text-red-400', info: 'bg-sky-500/10 text-sky-600 dark:text-sky-400' }[variant] || '';
  return <span className={`inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-[10px] font-semibold tabular-nums ${cls}`}>{children}</span>;
}

function DashTooltip({ active, payload, label, chart, suffix = '' }) {
  if (!active || !payload?.length) return null;
  const style = chartTooltipStyle(chart);
  return (
    <div style={style}>
      <p style={{ color: chart.axis, fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 6 }}>{label}</p>
      {payload.map((e) => (
        <div key={e.dataKey} className="flex items-center gap-2" style={{ marginBottom: 2 }}>
          <span className="inline-block h-2 w-2 rounded-full" style={{ backgroundColor: e.fill || e.stroke || e.color }} />
          <span style={{ fontSize: 12, color: chart.tooltipText, opacity: 0.7 }}>{e.name}</span>
          <span style={{ fontSize: 12, fontWeight: 700, color: chart.tooltipText, marginLeft: 'auto', paddingLeft: 12 }}>{fmt(e.value)}{suffix}</span>
        </div>
      ))}
    </div>
  );
}

function Metric({ icon: Icon, value, label, sub, accent = 'sky', trend }) {
  return (
    <div className={`dash-metric dash-metric--${accent}`}>
      <div className="dash-metric__icon"><Icon className="h-4.5 w-4.5" strokeWidth={2} /></div>
      <div className="min-w-0 flex-1">
        <p className="dash-metric__value">{value}</p>
        <p className="dash-metric__label mt-0.5">{label}</p>
        {sub && <p className="dash-metric__sub mt-px">{sub}</p>}
        {trend}
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   QUICK ACCESS MENU (compact dropdown)
   ═══════════════════════════════════════════ */
const QUICK_ACTIONS = [
  { icon: PackagePlus, label: 'Record Stock', to: '/inventory-tracking' },
  { icon: ArrowRightLeft, label: 'Transfer Inventory', to: '/inventory-tracking' },
  { icon: ShoppingCart, label: 'Create Order', to: '/orders' },
  { icon: ClipboardList, label: 'Assign Task', to: '/tasks' },
  { icon: Package, label: 'Add Product', to: '/products' },
  { icon: FileBarChart, label: 'Generate Report', to: '/reports' },
];

function QuickAccessMenu() {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    if (!open) return;
    function close(e) { if (ref.current && !ref.current.contains(e.target)) setOpen(false); }
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, [open]);

  return (
    <div className="relative" ref={ref}>
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="inline-flex items-center gap-1.5 rounded-lg border border-accent/30 bg-accent/5 px-3 py-1.5 text-[11px] font-semibold text-accent transition-all duration-150 hover:border-accent/50 hover:bg-accent/10 active:scale-[0.97]"
      >
        <Plus className="h-3.5 w-3.5" strokeWidth={2.5} />
        Quick Actions
      </button>

      {open && (
        <div className="absolute right-0 top-full z-50 mt-1.5 w-52 origin-top-right animate-in fade-in slide-in-from-top-1 rounded-xl border border-border/70 bg-card p-1.5 shadow-lg dark:border-[rgb(var(--card-border-dark))] dark:bg-[rgb(var(--card-bg-elevated))]"
             style={{ boxShadow: 'var(--card-shadow-dark, 0 8px 32px rgb(0 0 0 / 0.12))' }}>
          {QUICK_ACTIONS.map(({ icon: QIcon, label, to }) => (
            <Link
              key={to + label}
              to={to}
              onClick={() => setOpen(false)}
              className="flex items-center gap-2.5 rounded-lg px-2.5 py-2 text-[12px] font-medium text-foreground/85 transition-colors duration-100 hover:bg-accent/8 hover:text-accent"
            >
              <span className="flex h-6 w-6 items-center justify-center rounded-md bg-muted/50 text-muted-foreground transition-colors group-hover:text-accent dark:bg-muted/25">
                <QIcon className="h-3.5 w-3.5" strokeWidth={2} />
              </span>
              {label}
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════
   DASHBOARD HEADER
   ═══════════════════════════════════════════ */
function DashboardHeader() {
  const { user } = useAuth();
  const [now, setNow] = useState(new Date());

  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 30_000);
    return () => clearInterval(id);
  }, []);

  const greeting = useMemo(() => {
    const h = now.getHours();
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }, [now]);

  const dateStr = now.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' });
  const timeStr = now.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });

  return (
    <div className="dash-header">
      <div>
        <h1 className="dash-header__greeting">{greeting}, {user?.username || 'Admin'}</h1>
        <p className="mt-1 text-sm text-muted-foreground">Warehouse operations overview</p>
      </div>
      <div className="flex items-center gap-2">
        <div className="hidden items-center gap-1.5 rounded-lg border border-border/40 bg-card/80 px-2.5 py-1.5 sm:flex dark:bg-muted/20">
          <Clock className="h-3 w-3 text-muted-foreground/70" />
          <span className="dash-header__clock text-[10px]">{timeStr}</span>
          <span className="text-border/50">·</span>
          <span className="text-[10px] text-muted-foreground/70">{dateStr}</span>
        </div>
        <div className="hidden items-center gap-1.5 rounded-lg border border-border/40 bg-card/80 px-2.5 py-1.5 sm:flex dark:bg-muted/20">
          <UserIcon className="h-3 w-3 text-accent/70" />
          <span className="text-[10px] font-medium text-foreground/80">{user?.username}</span>
          <span className="rounded bg-accent/8 px-1 py-px text-[8px] font-bold uppercase tracking-wide text-accent/80">{user?.role}</span>
        </div>
        <QuickAccessMenu />
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   ALERT PANEL
   ═══════════════════════════════════════════ */
function AlertItem({ icon: Icon, count, label, severity = 'info', to }) {
  const Tag = to ? Link : 'div';
  return (
    <Tag to={to} className={`dash-alert dash-alert--${severity}`}>
      <div className="dash-alert__icon"><Icon className="h-4 w-4" strokeWidth={2} /></div>
      <div className="min-w-0 flex-1">
        <p className="dash-alert__count">{count}</p>
        <p className="dash-alert__label">{label}</p>
      </div>
      {to && <ArrowRight className="h-3.5 w-3.5 text-muted-foreground/50" />}
    </Tag>
  );
}

function AlertsPanel({ alerts }) {
  if (!alerts) return null;
  return (
    <div className="dash-section">
      <div className="mb-3 flex items-center gap-2">
        <CircleAlert className="h-3.5 w-3.5 text-amber-500" />
        <p className="dash-section__title">Operational alerts</p>
      </div>
      <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
        <AlertItem icon={PackageMinus} count={alerts.outOfStockCount} label="Out of Stock" severity="critical" to="/inventory-tracking" />
        <AlertItem icon={AlertTriangle} count={alerts.lowStockCount} label="Low Stock Items" severity="warning" to="/inventory-tracking" />
        <AlertItem icon={ShieldAlert} count={alerts.expiredCount || 0} label="Expired Products" severity={alerts.expiredCount > 0 ? 'critical' : 'info'} to="/expiry-management" />
        <AlertItem icon={Timer} count={alerts.expiringSoonCount || 0} label="Expiring Soon" severity={alerts.expiringSoonCount > 0 ? 'warning' : 'info'} to="/expiry-management" />
        <AlertItem icon={ShoppingCart} count={alerts.pendingOrderCount} label="Pending Orders" severity="info" to="/orders" />
        <AlertItem icon={Timer} count={alerts.overdueTaskCount + alerts.highPriorityTasks} label="Urgent Tasks" severity={alerts.overdueTaskCount > 0 ? 'critical' : 'warning'} to="/tasks" />
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   WAREHOUSE PERFORMANCE
   ═══════════════════════════════════════════ */
function WarehousePerformance({ warehouseStats, chart }) {
  if (!warehouseStats?.length) return null;

  return (
    <div className="dash-section">
      <div className="mb-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Warehouse className="h-3.5 w-3.5 text-sky-500" />
          <p className="dash-section__title">Warehouse performance</p>
        </div>
        <Link to="/warehouses" className="text-[11px] font-medium text-accent hover:underline">Manage →</Link>
      </div>
      <div className="space-y-3">
        {warehouseStats.map((wh) => {
          const color = wh.utilization >= 85 ? chart.critical : wh.utilization >= 60 ? chart.warning : chart.healthy;
          return (
            <div key={wh.id} className="rounded-lg border border-border/30 bg-card/50 p-3 dark:bg-muted/15">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-semibold text-foreground">{wh.name}</p>
                  <p className="text-[10px] text-muted-foreground">{wh.location}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-bold tabular-nums text-foreground">{fmt(wh.totalUnits)} Units</p>
                  <p className="text-[10px] text-muted-foreground">{wh.lineCount} Products</p>
                </div>
              </div>
              <div className="mt-2 flex items-center gap-2">
                <div className="dash-wh-track flex-1">
                  <div className="dash-wh-bar" style={{ width: `${wh.utilization}%`, backgroundColor: color }} />
                </div>
                <span className="text-[10px] font-semibold tabular-nums" style={{ color }}>{wh.utilization}% Capacity Used</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   TASK SUMMARY
   ═══════════════════════════════════════════ */
const PRIORITY_DOT = { critical: 'dash-priority-critical', high: 'dash-priority-high', medium: 'dash-priority-medium', low: 'dash-priority-low' };

function TaskSummary({ taskSummary }) {
  if (!taskSummary) return null;

  const kpis = [
    { label: 'Total', value: taskSummary.total, color: 'text-foreground' },
    { label: 'Awaiting', value: taskSummary.awaiting ?? taskSummary.pending, color: 'text-slate-500' },
    { label: 'Accepted', value: taskSummary.accepted, color: 'text-sky-500' },
    { label: 'In Progress', value: taskSummary.inProgress, color: 'text-orange-500' },
    { label: 'Completed', value: taskSummary.completed, color: 'text-emerald-500' },
    { label: 'Rejected', value: taskSummary.rejected, color: 'text-red-500' },
    { label: 'Overdue', value: taskSummary.overdue, color: 'text-red-800 dark:text-red-400' },
  ];

  return (
    <div className="dash-section">
      <div className="mb-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <ListTodo className="h-3.5 w-3.5 text-violet-500" />
          <p className="dash-section__title">Task overview</p>
        </div>
        <Link to="/tasks" className="text-[11px] font-medium text-accent hover:underline">All tasks →</Link>
      </div>
      <div className="mb-3 grid grid-cols-4 gap-2 sm:grid-cols-7">
        {kpis.map((kpi) => (
          <MiniStat key={kpi.label} label={kpi.label} value={kpi.value ?? 0} color={kpi.color} />
        ))}
      </div>
      {taskSummary.recentTasks?.length > 0 && (
        <div className="space-y-1.5">
          {taskSummary.recentTasks.slice(0, 4).map((t) => (
            <div key={t.id} className="flex items-center gap-2 rounded-md px-2 py-1.5 text-xs transition-colors hover:bg-muted/30">
              <span className={`inline-block h-2 w-2 rounded-full ${PRIORITY_DOT[t.priority] || PRIORITY_DOT.medium}`} />
              <span className="flex-1 truncate font-medium text-foreground">{t.title}</span>
              {t.isOverdue && (
                <span className="shrink-0 text-[9px] font-semibold text-red-800 dark:text-red-400">⚠ Overdue</span>
              )}
              <span className="shrink-0 rounded bg-muted/60 px-1.5 py-0.5 text-[9px] font-semibold uppercase text-muted-foreground">{t.status === 'Pending' ? 'Awaiting' : t.status}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function MiniStat({ label, value, color }) {
  return (
    <div className="rounded-lg bg-muted/30 px-2.5 py-2 text-center dark:bg-muted/15">
      <p className={`text-lg font-bold tabular-nums ${color}`}>{value}</p>
      <p className="text-[9px] font-medium uppercase tracking-wider text-muted-foreground">{label}</p>
    </div>
  );
}

/* ═══════════════════════════════════════════
   SMART INSIGHTS
   ═══════════════════════════════════════════ */
const INSIGHT_COLOR = { critical: 'bg-red-500', warning: 'bg-amber-500', info: 'bg-sky-500' };

function InsightsPanel({ insights }) {
  if (!insights?.length) return null;
  return (
    <div className="dash-section">
      <div className="mb-3 flex items-center gap-2">
        <Sparkles className="h-3.5 w-3.5 text-violet-500" />
        <p className="dash-section__title">Smart insights</p>
      </div>
      <div className="space-y-2">
        {insights.slice(0, 6).map((ins, i) => (
          <div key={i} className="dash-insight">
            <span className={`dash-insight__dot ${INSIGHT_COLOR[ins.severity] || INSIGHT_COLOR.info}`} />
            <span className="text-foreground/80">{ins.message}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   CHART COMPONENTS (unchanged logic, kept lean)
   ═══════════════════════════════════════════ */
function OrdersByStatusChart({ data: sd, total, chart }) {
  if (total === 0) return <EmptyChart message="No orders to display" icon={ShoppingCart} />;
  const ax = chartAxisProps(chart);
  return (
    <ResponsiveContainer width="100%" height="100%">
      <BarChart data={sd} barSize={36} margin={{ top: 8, right: 8, bottom: 0, left: -8 }}>
        <defs>{sd.map((e) => <linearGradient key={`sg_${e.status}`} id={`sg_${e.status}`} x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor={e.color} stopOpacity={0.9} /><stop offset="100%" stopColor={e.color} stopOpacity={0.4} /></linearGradient>)}</defs>
        <CartesianGrid strokeDasharray="3 3" stroke={chart.grid} vertical={false} />
        <XAxis dataKey="status" {...ax} tick={{ fill: chart.axis, fontSize: 10, fontWeight: 600 }} />
        <YAxis {...ax} allowDecimals={false} width={30} />
        <Tooltip content={<DashTooltip chart={chart} />} cursor={{ fill: chart.cursorFill, radius: 4 }} />
        <Bar dataKey="count" name="Orders" radius={[8, 8, 0, 0]} animationDuration={800} animationEasing="ease-out">
          {sd.map((e) => <Cell key={e.status} fill={`url(#sg_${e.status})`} />)}
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  );
}

function NewOrdersChart({ data: od, chart }) {
  if (!od.length) return <EmptyChart message="No orders in the last 7 days" icon={ShoppingCart} />;
  const ax = chartAxisProps(chart);
  return (
    <ResponsiveContainer width="100%" height="100%">
      <AreaChart data={od} margin={{ top: 8, right: 8, bottom: 0, left: -8 }}>
        <defs><linearGradient id="areaOrdG" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor={chart.secondary} stopOpacity={0.3} /><stop offset="100%" stopColor={chart.secondary} stopOpacity={0.02} /></linearGradient></defs>
        <CartesianGrid strokeDasharray="3 3" stroke={chart.grid} vertical={false} />
        <XAxis dataKey="label" {...ax} />
        <YAxis {...ax} allowDecimals={false} width={28} />
        <Tooltip content={<DashTooltip chart={chart} />} cursor={{ stroke: chart.secondary, strokeWidth: 1, strokeDasharray: '4 4' }} />
        <Area type="monotone" dataKey="orders" name="Orders" stroke={chart.secondary} strokeWidth={2.5} fill="url(#areaOrdG)" dot={{ r: 4, fill: chart.tooltipBg, stroke: chart.secondary, strokeWidth: 2 }} activeDot={{ r: 6, fill: chart.secondary, stroke: chart.tooltipBg, strokeWidth: 2 }} animationDuration={1000} />
      </AreaChart>
    </ResponsiveContainer>
  );
}

function MovementTrendChart({ data: mv, chart }) {
  if (!mv.length) return <EmptyChart message="No stock movements in the last 7 days" icon={Activity} />;
  const ax = chartAxisProps(chart);
  const lg = chartLegendProps(chart);
  return (
    <ResponsiveContainer width="100%" height="100%">
      <BarChart data={mv} barSize={16} barGap={3} margin={{ top: 8, right: 8, bottom: 0, left: -8 }}>
        <defs>
          <linearGradient id="mvIG" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor={chart.inbound} stopOpacity={0.9} /><stop offset="100%" stopColor={chart.inbound} stopOpacity={0.35} /></linearGradient>
          <linearGradient id="mvOG" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor={chart.outbound} stopOpacity={0.9} /><stop offset="100%" stopColor={chart.outbound} stopOpacity={0.35} /></linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke={chart.grid} vertical={false} />
        <XAxis dataKey="label" {...ax} /><YAxis {...ax} allowDecimals={false} width={30} />
        <Tooltip content={<DashTooltip chart={chart} suffix=" units" />} cursor={{ fill: chart.cursorFill, radius: 4 }} />
        <Legend {...lg} />
        <Bar dataKey="inbound" name="Inbound" fill="url(#mvIG)" radius={[6, 6, 0, 0]} animationDuration={800} />
        <Bar dataKey="outbound" name="Outbound" fill="url(#mvOG)" radius={[6, 6, 0, 0]} animationDuration={800} />
      </BarChart>
    </ResponsiveContainer>
  );
}

function InventoryHealthChart({ inStock, lowStock, outOfStock, chart: c }) {
  const total = inStock + lowStock + outOfStock;
  if (total === 0) return <EmptyChart message="No inventory data" icon={PieChartIcon} />;
  const segs = useMemo(() => [
    { name: 'In Stock', value: inStock, color: c.healthy, light: c.isDark ? 'rgba(52,211,153,0.15)' : 'rgba(16,185,129,0.1)', textCls: 'text-emerald-600 dark:text-emerald-400' },
    { name: 'Low Stock', value: lowStock, color: c.warning, light: c.isDark ? 'rgba(251,191,36,0.15)' : 'rgba(245,158,11,0.1)', textCls: 'text-amber-600 dark:text-amber-400' },
    { name: 'Out of Stock', value: outOfStock, color: c.critical, light: c.isDark ? 'rgba(248,113,113,0.15)' : 'rgba(239,68,68,0.1)', textCls: 'text-red-600 dark:text-red-400' },
  ], [inStock, lowStock, outOfStock, c]);
  const active = segs.filter((s) => s.value > 0);
  return (
    <div className="flex h-full items-center gap-4">
      <div className="relative h-40 w-40 shrink-0">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart><Pie data={active} cx="50%" cy="50%" innerRadius="62%" outerRadius="88%" paddingAngle={active.length > 1 ? 3 : 0} dataKey="value" strokeWidth={0} animationDuration={1000}>{active.map((s) => <Cell key={s.name} fill={s.color} />)}</Pie></PieChart>
        </ResponsiveContainer>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span className="text-xl font-bold tabular-nums text-foreground">{fmt(total)}</span>
          <span className="text-[9px] font-medium uppercase tracking-wider text-muted-foreground">Lines</span>
        </div>
      </div>
      <div className="flex flex-1 flex-col gap-2.5">
        {segs.map((s) => (
          <div key={s.name}>
            <div className="flex items-center justify-between text-xs">
              <span className="flex items-center gap-1.5"><span className="inline-block h-2.5 w-2.5 rounded-sm" style={{ backgroundColor: s.color }} /><span className="font-medium text-foreground">{s.name}</span></span>
              <span className="tabular-nums font-semibold text-foreground">{fmt(s.value)}</span>
            </div>
            <div className="mt-1 h-1.5 w-full overflow-hidden rounded-full" style={{ backgroundColor: s.light }}>
              <div className="h-full rounded-full transition-all duration-700 ease-out" style={{ width: `${pct(s.value, total)}%`, backgroundColor: s.color, minWidth: s.value > 0 ? '3px' : '0' }} />
            </div>
            <p className="mt-0.5 text-right text-[10px] tabular-nums text-muted-foreground">{pct(s.value, total)}%</p>
          </div>
        ))}
      </div>
    </div>
  );
}

function OrderPipelineStrip({ ordersByStatus, total, chart: c }) {
  if (total === 0) return null;
  const stages = [
    { key: 'Pending', color: c.pending, label: 'Pending' },
    { key: 'Processing', color: c.processing, label: 'Processing' },
    { key: 'Packed', color: c.packed, label: 'Packed' },
    { key: 'Shipped', color: c.shipped, label: 'Shipped' },
    { key: 'Delivered', color: c.delivered, label: 'Delivered' },
  ];
  return (
    <div className="mt-3 space-y-2">
      <div className="flex h-2.5 w-full overflow-hidden rounded-full bg-muted/30">
        {stages.map((s) => { const n = ordersByStatus[s.key] || 0; return n > 0 ? <div key={s.key} className="transition-all duration-700 ease-out first:rounded-l-full last:rounded-r-full" style={{ width: `${pct(n, total)}%`, backgroundColor: s.color, minWidth: '3px' }} title={`${s.label}: ${n}`} /> : null; })}
      </div>
      <div className="flex flex-wrap gap-x-4 gap-y-1">
        {stages.map((s) => <span key={s.key} className="flex items-center gap-1 text-[10px] text-muted-foreground"><span className="inline-block h-1.5 w-1.5 rounded-full" style={{ backgroundColor: s.color }} />{s.label} <span className="font-semibold tabular-nums text-foreground">{ordersByStatus[s.key] || 0}</span></span>)}
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   EXPIRY ANALYTICS
   ═══════════════════════════════════════════ */
function ExpiryOverviewPanel({ alerts, expirySummary, chart: c }) {
  const expired = alerts?.expiredCount ?? expirySummary?.expired ?? 0;
  const soon = alerts?.expiringSoonCount ?? expirySummary?.expiring_soon ?? 0;
  const in30d = alerts?.expiring30dCount ?? expirySummary?.expiring_30d ?? 0;
  const safe = alerts?.safeExpiryCount ?? expirySummary?.safe ?? 0;
  const total = expired + soon + in30d + safe;

  const expiredItems = alerts?.expiredItems || [];
  const expiringSoonItems = alerts?.expiringSoonItems || [];

  if (total === 0 && expiredItems.length === 0 && expiringSoonItems.length === 0) return null;

  const pieData = [
    { name: 'Expired', value: expired, color: c.critical },
    { name: 'Expiring Soon', value: soon, color: c.warning },
    { name: 'Expiring (30d)', value: in30d, color: '#f97316' },
    { name: 'Safe', value: safe, color: c.healthy },
  ].filter((s) => s.value > 0);

  return (
    <div className="dash-section">
      <div className="mb-3 flex items-center gap-2">
        <Timer className="h-3.5 w-3.5 text-amber-500" />
        <p className="dash-section__title">Expiry tracking</p>
        <Link to="/expiry-management" className="ml-auto text-[11px] font-medium text-accent hover:underline">View all →</Link>
      </div>
      <div className="grid gap-4 lg:grid-cols-3">
        {/* KPIs */}
        <div className="grid grid-cols-2 gap-2">
          <MiniStat label="Expired" value={expired} color="text-red-500" />
          <MiniStat label="Expiring Soon" value={soon} color="text-amber-500" />
          <MiniStat label="Expiring (30d)" value={in30d} color="text-orange-400" />
          <MiniStat label="Safe" value={safe} color="text-emerald-500" />
        </div>

        {/* Mini Donut */}
        <div className="flex items-center justify-center">
          {total > 0 ? (
            <div className="relative h-36 w-36">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={pieData} cx="50%" cy="50%" innerRadius="60%" outerRadius="88%" paddingAngle={pieData.length > 1 ? 3 : 0} dataKey="value" strokeWidth={0} animationDuration={900}>
                    {pieData.map((s) => <Cell key={s.name} fill={s.color} />)}
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-lg font-bold tabular-nums text-foreground">{total}</span>
                <span className="text-[8px] font-medium uppercase tracking-wider text-muted-foreground">Items tracked</span>
              </div>
            </div>
          ) : (
            <EmptyChart message="No expiry data" icon={Timer} />
          )}
        </div>

        {/* Expiring items list */}
        <div className="space-y-2">
          {expiredItems.length > 0 && (
            <div>
              <p className="mb-1.5 text-[10px] font-semibold uppercase tracking-wider text-red-500">Expired items</p>
              {expiredItems.slice(0, 3).map((item, i) => (
                <div key={i} className="flex items-center gap-2 rounded-md px-2 py-1 text-xs transition-colors hover:bg-muted/30">
                  <ShieldAlert className="h-3 w-3 shrink-0 text-red-500" />
                  <span className="flex-1 truncate font-medium text-foreground">{item.product}</span>
                  <span className="shrink-0 text-muted-foreground">{item.batch !== '—' ? item.batch : ''}</span>
                </div>
              ))}
            </div>
          )}
          {expiringSoonItems.length > 0 && (
            <div>
              <p className="mb-1.5 text-[10px] font-semibold uppercase tracking-wider text-amber-500">Expiring soon</p>
              {expiringSoonItems.slice(0, 3).map((item, i) => (
                <div key={i} className="flex items-center gap-2 rounded-md px-2 py-1 text-xs transition-colors hover:bg-muted/30">
                  <Timer className="h-3 w-3 shrink-0 text-amber-500" />
                  <span className="flex-1 truncate font-medium text-foreground">{item.product}</span>
                  <span className="shrink-0 text-amber-600 dark:text-amber-400">{item.daysLeft}d left</span>
                </div>
              ))}
            </div>
          )}
          {expiredItems.length === 0 && expiringSoonItems.length === 0 && (
            <div className="flex flex-col items-center justify-center gap-1 py-6 text-muted-foreground">
              <ShieldCheck className="h-5 w-5 opacity-40" />
              <p className="text-xs font-medium">All items safe</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════
   MAIN DASHBOARD
   ═══════════════════════════════════════════ */
export function Dashboard() {
  const chart = useChartTheme();
  const { data, isLoading, isError, error } = useQuery({ queryKey: ['dashboard', 'stats'], queryFn: fetchStats, refetchOnWindowFocus: true, staleTime: 30_000 });
  const { data: widgets } = useQuery({ queryKey: ['dashboard', 'widgets'], queryFn: fetchWidgets, refetchOnWindowFocus: true, staleTime: 45_000 });

  const mvData = useMemo(() => (data?.movementTrend || []).map((r) => ({ ...r, label: r.date?.slice(5) || r.date })), [data?.movementTrend]);
  const hasMv = useMemo(() => mvData.some((r) => r.inbound > 0 || r.outbound > 0), [mvData]);
  const ordData = useMemo(() => (data?.orderTrend || []).map((r) => ({ ...r, label: r.date?.slice(5) || r.date })), [data?.orderTrend]);
  const hasOrd = useMemo(() => ordData.some((r) => r.orders > 0), [ordData]);
  const statData = useMemo(() => {
    if (!data?.ordersByStatus) return [];
    const cm = { Pending: chart.pending, Processing: chart.processing, Packed: chart.packed, Shipped: chart.shipped, Delivered: chart.delivered };
    return Object.entries(data.ordersByStatus).map(([s, c]) => ({ status: s, count: c, color: cm[s] || chart.primary }));
  }, [data?.ordersByStatus, chart]);
  const statTotal = useMemo(() => statData.reduce((a, r) => a + r.count, 0), [statData]);
  const mvTotals = useMemo(() => mvData.reduce((a, r) => ({ inbound: a.inbound + (r.inbound || 0), outbound: a.outbound + (r.outbound || 0) }), { inbound: 0, outbound: 0 }), [mvData]);

  if (isLoading) {
    return (
      <PageShell title="Dashboard" subtitle="Warehouse command center">
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">{Array.from({ length: 10 }).map((_, i) => <SkeletonCard key={i} />)}</div>
      </PageShell>
    );
  }
  if (isError) {
    return (
      <PageShell title="Dashboard">
        <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-500">{error?.response?.data?.message || error?.message || 'Could not load dashboard.'}</div>
      </PageShell>
    );
  }

  return (
    <div className="space-y-5">
      {/* ── Header (includes compact Quick Access dropdown) ── */}
      <DashboardHeader />

      {/* ── Alerts ── */}
      <AlertsPanel alerts={widgets?.alerts} />

      {/* ── Expiry Tracking ── */}
      <ExpiryOverviewPanel alerts={widgets?.alerts} expirySummary={widgets?.expirySummary} chart={chart} />

      {/* ── KPI Row 1: Inventory ── */}
      <div className="dash-section">
        <p className="dash-section__title mb-3">Inventory overview</p>
        <div className="grid gap-2.5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
          <Metric icon={Layers} value={fmt(data.totalUnitsOnHand)} label="Units On Hand" sub="All conditions" accent="sky" />
          <Metric icon={CheckCircle2} value={fmt(data.inStockLineCount)} label="In Stock Lines" sub="Above threshold" accent="emerald" />
          <Metric icon={AlertTriangle} value={fmt(data.lowStockLineCount)} label="Low Stock" sub="At or below minimum" accent="amber"
            trend={data.lowStockLineCount > 0 ? <span className="mt-1 inline-flex items-center gap-0.5 text-[10px] font-semibold text-amber-600 dark:text-amber-400"><AlertTriangle className="h-2.5 w-2.5" /> Needs attention</span> : null} />
          <Metric icon={Package} value={fmt(data.outOfStockLineCount)} label="Out Of Stock" sub="Zero quantity" accent="red"
            trend={data.outOfStockLineCount > 0 ? <span className="mt-1 inline-flex items-center gap-0.5 text-[10px] font-semibold text-red-600 dark:text-red-400"><TrendingDown className="h-2.5 w-2.5" /> Critical</span> : null} />
          <Metric icon={TrendingUp} value={fmtMoney(data.totalStockValue)} label="Stock Value" sub="Σ qty × cost" accent="violet" />
        </div>
      </div>

      {/* ── KPI Row 2: Operations ── */}
      <div className="dash-section">
        <p className="dash-section__title mb-3">Operations</p>
        <div className="grid gap-2.5 sm:grid-cols-2 lg:grid-cols-4">
          <Metric icon={Warehouse} value={fmt(data.activeWarehousesCount)} label="Active Warehouses" sub="Holding stock" accent="sky" />
          <Metric icon={Activity} value={fmt(data.todayMovementsCount)} label="Today's Movements" sub="Since midnight" accent="emerald" />
          <Metric icon={ShoppingCart} value={fmt(data.totalOrders)} label="Total Orders" sub="Pipeline" accent="sky" />
          <Metric icon={Truck} value={fmt(data.ordersByStatus?.Delivered ?? 0)} label="Delivered" sub="Completed" accent="emerald" />
        </div>
      </div>

      {/* ── Charts Row 1 ── */}
      <div className="grid gap-4 lg:grid-cols-2">
        <ChartBox title="Orders by status" sub="Pipeline distribution" badge={<ChartBadge variant="info">{fmt(statTotal)} total</ChartBadge>}>
          <div className="h-56 w-full"><OrdersByStatusChart data={statData} total={statTotal} chart={chart} /></div>
          <OrderPipelineStrip ordersByStatus={data.ordersByStatus || {}} total={statTotal} chart={chart} />
        </ChartBox>
        <ChartBox title="Order creation trend" sub="Last 7 days" badge={hasOrd ? <ChartBadge variant="success">{fmtCompact(ordData.reduce((s, r) => s + r.orders, 0))} this week</ChartBadge> : null}>
          <div className="h-64 w-full"><NewOrdersChart data={hasOrd ? ordData : []} chart={chart} /></div>
        </ChartBox>
      </div>

      {/* ── Charts Row 2 ── */}
      <div className="grid gap-4 lg:grid-cols-5">
        <ChartBox title="Stock movement trend" sub="Inbound vs Outbound — 7 days" className="lg:col-span-3"
          badge={hasMv ? <div className="flex gap-2"><ChartBadge variant="success"><ArrowDownRight className="h-3 w-3" /> {fmtCompact(mvTotals.inbound)} in</ChartBadge><ChartBadge variant="danger"><ArrowUpRight className="h-3 w-3" /> {fmtCompact(mvTotals.outbound)} out</ChartBadge></div> : null}>
          <div className="h-64 w-full"><MovementTrendChart data={hasMv ? mvData : []} chart={chart} /></div>
        </ChartBox>
        <ChartBox title="Inventory health" sub="Stock status distribution" className="lg:col-span-2">
          <div className="h-64 w-full"><InventoryHealthChart inStock={data.inStockLineCount ?? 0} lowStock={data.lowStockLineCount ?? 0} outOfStock={data.outOfStockLineCount ?? 0} chart={chart} /></div>
        </ChartBox>
      </div>

      {/* ── Widgets Row: Warehouse + Tasks + Insights ── */}
      <div className="grid gap-4 lg:grid-cols-3">
        <WarehousePerformance warehouseStats={widgets?.warehouseStats} chart={chart} />
        <TaskSummary taskSummary={widgets?.taskSummary} />
        <InsightsPanel insights={widgets?.insights} />
      </div>

      {/* ── Notifications & Audit Reports ── */}
      <ActivityReportsPanel />

      {/* ── Bottom: Recent Orders + Activity ── */}
      <div className="grid gap-4 lg:grid-cols-5">
        <div className="dash-section lg:col-span-3">
          <div className="mb-3 flex items-center justify-between">
            <p className="dash-section__title">Recent orders</p>
            <Link to="/orders" className="text-[11px] font-medium text-accent hover:underline">View all →</Link>
          </div>
          {!(data.recentOrders?.length) ? (
            <div className="flex flex-col items-center gap-2 py-8 text-muted-foreground"><ShoppingCart className="h-6 w-6 opacity-30" /><p className="text-xs">No orders yet</p></div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-border/50">
                    <th className="pb-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">Order</th>
                    <th className="pb-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">Customer</th>
                    <th className="pb-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">Status</th>
                    <th className="pb-2.5 text-right text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">Updated</th>
                  </tr>
                </thead>
                <tbody>
                  {data.recentOrders.map((o) => (
                    <tr key={o._id} className="group border-b border-border/20 transition-colors hover:bg-muted/30 dark:hover:bg-muted/15">
                      <td className="py-2.5 pr-3"><Link to={`/orders/${o._id}`} className="font-mono text-xs font-semibold text-accent group-hover:underline">{o.order_number}</Link></td>
                      <td className="py-2.5 pr-3 text-sm text-foreground">{o.customer_name}</td>
                      <td className="py-2.5 pr-3"><OrderStatusBadge status={o.status} /></td>
                      <td className="py-2.5 text-right font-mono text-[11px] tabular-nums text-muted-foreground">{relTime(o.updatedAt || o.createdAt)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        <div className="dash-section lg:col-span-2">
          <p className="dash-section__title mb-3">Recent activity</p>
          {!(data.activityFeed?.length) ? (
            <div className="flex flex-col items-center gap-2 py-8 text-muted-foreground"><Activity className="h-6 w-6 opacity-30" /><p className="text-xs">No recent movements</p></div>
          ) : (
            <div className="space-y-0">
              {data.activityFeed.map((row) => {
                const MI = MV_ICON[row.type] || Box;
                return (
                  <div key={row.id || row._id} className="dash-timeline-item">
                    <div className={`dash-timeline-dot ${MV_DOT[row.type] || ''}`}><MI className="h-3.5 w-3.5" strokeWidth={2.2} /></div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-semibold text-foreground">{row.type}</span>
                        <MovementQuantityCell movement={row} />
                      </div>
                      <p className="mt-0.5 truncate text-xs text-muted-foreground">
                        {row.product?.name || row.product?.sku || '—'} · {row.type === 'TRANSFER' ? `${row.warehouse?.name || row.source_location || '?'} → ${row.toWarehouse?.name || row.destination_location || '?'}` : row.warehouse?.name || '—'}
                      </p>
                      <p className="mt-0.5 text-[10px] text-muted-foreground/60">{relTime(row.createdAt || row.timestamp)}</p>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
