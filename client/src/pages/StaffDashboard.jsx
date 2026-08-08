import { useEffect, useMemo, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  AlertTriangle,
  ArrowDownToLine,
  ArrowRight,
  ArrowRightLeft,
  ArrowUpFromLine,
  Box,
  CheckCircle2,
  ChevronRight,
  Clock,
  ClipboardCheck,
  ClipboardList,
  Info,
  Loader2,
  Package,
  PackageMinus,
  PackagePlus,
  Play,
  ShieldAlert,
  ShoppingCart,
  Timer,
  Warehouse,
  Zap,
} from 'lucide-react';
import { api } from '../api/client';
import { fetchTaskList } from '../api/taskList';
import { useAuth } from '../context/AuthContext';
import { TaskPriorityBadge, TaskStatusBadge, TaskOverdueBadge, TASK_KPI_ITEMS } from '../components/tasks/TaskBadges';
import { getStatusActions, ACTION_LABELS } from '../utils/taskPermissions';
import { isTaskOverdue, resolveTaskStats, taskWorkflowStatus } from '../utils/taskOverdue';

const fetchWidgets = async () => (await api.get('/dashboard/widgets')).data;
const fetchInventory = async () => (await api.get('/inventory/tracking')).data;
const fetchMovements = async () => (await api.get('/inventory/movements', { params: { limit: 15 } })).data;

function relTime(d) {
  if (!d) return '';
  const diff = new Date(d).getTime() - Date.now();
  const absDiff = Math.abs(diff);
  const past = diff < 0;
  const m = Math.floor(absDiff / 60_000);
  if (m < 60) return past ? `${m}m ago` : `in ${m}m`;
  const h = Math.floor(m / 60);
  if (h < 24) return past ? `${h}h ago` : `in ${h}h`;
  const days = Math.floor(h / 24);
  return past ? `${days}d ago` : `in ${days}d`;
}

function fmt(n) {
  if (n == null || Number.isNaN(n)) return '—';
  return Number(n).toLocaleString();
}

const STATUS_ORDER = { Overdue: 0, 'In Progress': 1, 'Waiting Confirmation': 2, Accepted: 3, Pending: 4, Completed: 5, Rejected: 6 };

const MOVEMENT_ICONS = { INBOUND: ArrowDownToLine, OUTBOUND: ArrowUpFromLine, TRANSFER: ArrowRightLeft, ADJUSTMENT: Box, RETURN: ArrowDownToLine };
const MOVEMENT_COLORS = {
  INBOUND: 'text-emerald-600 dark:text-emerald-400',
  OUTBOUND: 'text-orange-600 dark:text-orange-400',
  TRANSFER: 'text-sky-600 dark:text-sky-400',
  ADJUSTMENT: 'text-violet-600 dark:text-violet-400',
  RETURN: 'text-teal-600 dark:text-teal-400',
};

const ACTION_STYLES = {
  sky: 'border-sky-200 bg-sky-50 text-sky-700 hover:bg-sky-100 dark:border-sky-500/30 dark:bg-sky-500/10 dark:text-sky-300',
  blue: 'border-blue-200 bg-blue-50 text-blue-700 hover:bg-blue-100 dark:border-blue-500/30 dark:bg-blue-500/10 dark:text-blue-300',
  amber: 'border-amber-200 bg-amber-50 text-amber-700 hover:bg-amber-100 dark:border-amber-500/30 dark:bg-amber-500/10 dark:text-amber-300',
  emerald: 'border-emerald-200 bg-emerald-50 text-emerald-700 hover:bg-emerald-100 dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-300',
  red: 'border-red-200 bg-red-50 text-red-700 hover:bg-red-100 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300',
  slate: 'border-slate-200 bg-slate-50 text-slate-700 hover:bg-slate-100 dark:border-slate-600 dark:bg-slate-700 dark:text-slate-300',
};
const ACTION_ICONS = { Accepted: CheckCircle2, 'In Progress': Play, 'Waiting Confirmation': Clock, Completed: CheckCircle2, Rejected: AlertTriangle, Pending: Clock };

/* ═══════════════════════════════════════════════════════════════
   HEADER — compact with quick actions
   ═══════════════════════════════════════════════════════════════ */
function StaffHeader() {
  const { user } = useAuth();
  const [now, setNow] = useState(new Date());
  useEffect(() => { const id = setInterval(() => setNow(new Date()), 30_000); return () => clearInterval(id); }, []);

  const greeting = useMemo(() => { const h = now.getHours(); return h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening'; }, [now]);
  const dateStr = now.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' });
  const timeStr = now.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });

  return (
    <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
      <div className="flex items-center gap-3">
        <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-sky-500/10 dark:bg-sky-500/15">
          <Zap className="h-4.5 w-4.5 text-sky-600 dark:text-sky-400" strokeWidth={2.2} />
        </div>
        <div>
          <h1 className="text-base font-bold text-slate-900 dark:text-slate-100 sm:text-lg">
            {greeting}, {user?.fullName || user?.username || 'Operator'}
          </h1>
          <p className="text-[11px] text-slate-500 dark:text-slate-400">{dateStr} · {timeStr} · Warehouse Operations</p>
        </div>
      </div>
      <QuickActionBar />
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   QUICK ACTION BAR
   ═══════════════════════════════════════════════════════════════ */
const QA = [
  { icon: PackagePlus, label: 'Receive', to: '/staff/inventory', tip: 'Receive inventory' },
  { icon: ShoppingCart, label: 'Orders', to: '/staff/orders', tip: 'My orders' },
  { icon: ArrowRightLeft, label: 'Transfer', to: '/staff/inventory', tip: 'Transfer stock' },
  { icon: ClipboardList, label: 'Tasks', to: '/tasks', tip: 'My tasks' },
];

function QuickActionBar() {
  return (
    <div className="flex items-center gap-1">
      {QA.map(({ icon: Icon, label, to, tip }) => (
        <Link
          key={label}
          to={to}
          title={tip}
          className="flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-[11px] font-semibold text-slate-600 transition-all hover:border-slate-300 hover:bg-slate-50 hover:text-slate-900 active:scale-[0.97] dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:border-slate-600 dark:hover:bg-slate-700 dark:hover:text-slate-100"
        >
          <Icon className="h-3.5 w-3.5" strokeWidth={2} />
          <span className="hidden sm:inline">{label}</span>
        </Link>
      ))}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   KPI ROW — 6 compact cards
   ═══════════════════════════════════════════════════════════════ */
function KpiRow({ tasks, taskSummary }) {
  const stats = useMemo(() => {
    if (taskSummary && typeof taskSummary.total === 'number') {
      return resolveTaskStats(tasks, {
        total: taskSummary.total,
        awaiting: taskSummary.awaiting ?? taskSummary.pending,
        accepted: taskSummary.accepted,
        inProgress: taskSummary.inProgress,
        completed: taskSummary.completed,
        rejected: taskSummary.rejected,
        overdue: taskSummary.overdue,
      });
    }
    return resolveTaskStats(tasks);
  }, [tasks, taskSummary]);

  return (
    <div className="grid grid-cols-2 gap-2 sm:grid-cols-4 lg:grid-cols-7">
      {TASK_KPI_ITEMS.map((kpi) => (
        <div key={kpi.key} className="rounded-lg border border-slate-200/80 bg-white px-3 py-2 dark:border-slate-700/70 dark:bg-slate-800/80">
          <span className="text-[10px] font-medium text-slate-500 dark:text-slate-400">{kpi.label}</span>
          <p className={`mt-0.5 text-lg font-bold tabular-nums leading-tight ${kpi.color}`}>
            {stats[kpi.statKey] ?? stats[kpi.key] ?? 0}
          </p>
        </div>
      ))}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   TODAY'S OPERATIONS PANEL — operational breakdown
   ═══════════════════════════════════════════════════════════════ */
function TodayOpsPanel({ tasks }) {
  const ops = useMemo(() => {
    const todayStart = new Date(); todayStart.setHours(0, 0, 0, 0);
    const active = (tasks || []).filter((t) => !['Completed', 'Rejected'].includes(t.status));
    const types = [
      { key: 'INBOUND', label: 'Inbound', icon: ArrowDownToLine, cls: 'text-emerald-600 dark:text-emerald-400', bg: 'bg-emerald-50 dark:bg-emerald-500/10' },
      { key: 'OUTBOUND', label: 'Outbound', icon: ArrowUpFromLine, cls: 'text-orange-600 dark:text-orange-400', bg: 'bg-orange-50 dark:bg-orange-500/10' },
      { key: 'TRANSFER', label: 'Transfer', icon: ArrowRightLeft, cls: 'text-sky-600 dark:text-sky-400', bg: 'bg-sky-50 dark:bg-sky-500/10' },
      { key: 'COUNT', label: 'Count', icon: ClipboardCheck, cls: 'text-violet-600 dark:text-violet-400', bg: 'bg-violet-50 dark:bg-violet-500/10' },
    ];
    return types.map((t) => ({
      ...t,
      count: active.filter((tk) => {
        if (t.key === 'COUNT') return tk.task_type === 'Inventory Count';
        return tk.task_type_meta?.movement_type === t.key;
      }).length,
    }));
  }, [tasks]);

  return (
    <SectionCard title="Today's Operations" icon={Zap} iconColor="text-sky-500">
      <div className="grid grid-cols-2 gap-1.5 sm:grid-cols-4">
        {ops.map(({ key, label, icon: Icon, cls, bg, count }) => (
          <div key={key} className="flex items-center gap-2 rounded-lg border border-slate-200/80 bg-white px-2.5 py-2 dark:border-slate-700/60 dark:bg-slate-800/60">
            <div className={`flex h-6 w-6 items-center justify-center rounded-md ${bg}`}><Icon className={`h-3 w-3 ${cls}`} /></div>
            <div>
              <p className={`text-base font-bold tabular-nums ${cls}`}>{count}</p>
              <p className="text-[9px] font-medium text-slate-500 dark:text-slate-400">{label}</p>
            </div>
          </div>
        ))}
      </div>
    </SectionCard>
  );
}

/* ═══════════════════════════════════════════════════════════════
   TASK CARD — compact with navigation to detail page
   ═══════════════════════════════════════════════════════════════ */
function TaskCard({ task, onStatusChange, isUpdating }) {
  const navigate = useNavigate();
  const actions = getStatusActions(taskWorkflowStatus(task), 'Staff');
  const dueDate = task.due_date ? new Date(task.due_date) : null;
  const isOverdue = isTaskOverdue(task);
  const meta = task.task_type_meta;
  const isOp = Boolean(meta?.movement_type);

  return (
    <div
      className="group flex items-center gap-3 rounded-lg border border-slate-200/80 bg-white px-3 py-2.5 transition-colors hover:border-slate-300 hover:shadow-sm cursor-pointer dark:border-slate-700/70 dark:bg-slate-800/80 dark:hover:border-slate-600"
      onClick={() => navigate(`/tasks/${task._id || task.id}`)}
    >
      {/* Left indicator */}
      {isOp && (
        <div className={`h-8 w-1 shrink-0 rounded-full ${meta.movement_type === 'TRANSFER' ? 'bg-sky-400' : meta.movement_type === 'INBOUND' ? 'bg-emerald-400' : meta.movement_type === 'OUTBOUND' ? 'bg-orange-400' : 'bg-violet-400'}`} />
      )}

      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <h3 className="truncate text-[13px] font-semibold text-slate-900 dark:text-slate-100">{task.title}</h3>
          <TaskPriorityBadge priority={task.priority} />
        </div>
        <div className="mt-0.5 flex flex-wrap items-center gap-x-3 gap-y-0.5 text-[11px] text-slate-500 dark:text-slate-400">
          <span>{task.task_type}</span>
          {isOp && task.related_product?.name && (
            <span className="font-medium text-slate-700 dark:text-slate-300">{task.related_product.name}</span>
          )}
          {isOp && task.quantity > 0 && (
            <span className="font-semibold text-violet-600 dark:text-violet-400">{task.quantity} units</span>
          )}
          {task.warehouse?.name && (
            <span className="inline-flex items-center gap-0.5"><Warehouse className="h-2.5 w-2.5" /> {task.warehouse.name}</span>
          )}
          {dueDate && (
            <span className={isOverdue ? 'font-semibold text-red-600 dark:text-red-400' : ''}>
              {relTime(task.due_date)}
            </span>
          )}
        </div>
      </div>

      <div className="flex shrink-0 items-center gap-1.5" onClick={(e) => e.stopPropagation()}>
        <TaskStatusBadge status={task.status} workflowStatus={task.workflow_status} />
        {isOverdue && <TaskOverdueBadge className="hidden sm:inline-flex" />}
        {actions.slice(0, 2).map((nextStatus) => {
          const cfg = ACTION_LABELS[nextStatus];
          if (!cfg) return null;
          const AIcon = ACTION_ICONS[nextStatus] || Play;
          return (
            <button
              key={nextStatus}
              type="button"
              disabled={isUpdating}
              onClick={() => onStatusChange(task._id || task.id, nextStatus)}
              className={`inline-flex items-center gap-1 rounded-md border px-2 py-1 text-[11px] font-semibold transition disabled:opacity-50 ${ACTION_STYLES[cfg.variant] || ACTION_STYLES.slate}`}
            >
              <AIcon className="h-3 w-3" /> <span className="hidden sm:inline">{cfg.label}</span>
            </button>
          );
        })}
        {isUpdating && <Loader2 className="h-3 w-3 animate-spin text-slate-400" />}
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   TASKS PANEL — active tasks list
   ═══════════════════════════════════════════════════════════════ */
function TasksPanel({ tasks, onStatusChange, updatingId }) {
  const sorted = useMemo(() => {
    if (!tasks?.length) return [];
    return [...tasks]
      .filter((t) => !['Completed', 'Rejected'].includes(taskWorkflowStatus(t)))
      .sort((a, b) => (STATUS_ORDER[taskWorkflowStatus(a)] ?? 99) - (STATUS_ORDER[taskWorkflowStatus(b)] ?? 99));
  }, [tasks]);

  return (
    <SectionCard title="My Active Tasks" icon={ClipboardList} iconColor="text-sky-500" count={sorted.length} link="/tasks" linkLabel="View all">
      {sorted.length === 0 ? (
        <div className="flex items-center gap-3 rounded-lg border border-dashed border-slate-200 bg-slate-50/50 px-4 py-5 dark:border-slate-700 dark:bg-slate-800/40">
          <CheckCircle2 className="h-5 w-5 shrink-0 text-emerald-400 opacity-60" />
          <div>
            <p className="text-[13px] font-medium text-slate-600 dark:text-slate-300">All caught up</p>
            <p className="text-[11px] text-slate-400 dark:text-slate-500">No active tasks assigned to you right now.</p>
          </div>
        </div>
      ) : (
        <div className="space-y-1.5">
          {sorted.slice(0, 10).map((task) => (
            <TaskCard key={task._id || task.id} task={task} onStatusChange={onStatusChange} isUpdating={updatingId === (task._id || task.id)} />
          ))}
          {sorted.length > 10 && (
            <Link to="/tasks" className="block pt-1 text-center text-[11px] font-medium text-sky-600 hover:text-sky-700 dark:text-sky-400 dark:hover:text-sky-300">
              +{sorted.length - 10} more tasks <ChevronRight className="inline h-3 w-3" />
            </Link>
          )}
        </div>
      )}
    </SectionCard>
  );
}

/* ═══════════════════════════════════════════════════════════════
   ALERTS PANEL
   ═══════════════════════════════════════════════════════════════ */
function AlertsPanel({ alerts, insights }) {
  const alertItems = useMemo(() => {
    if (!alerts) return [];
    return [
      { icon: AlertTriangle, label: 'Low Stock', count: alerts.lowStockCount || 0, cls: 'text-amber-600 dark:text-amber-400' },
      { icon: PackageMinus, label: 'Out of Stock', count: alerts.outOfStockCount || 0, cls: 'text-red-600 dark:text-red-400' },
      { icon: ShieldAlert, label: 'Expired', count: alerts.expiredCount || 0, cls: 'text-red-600 dark:text-red-400' },
      { icon: Timer, label: 'Expiring Soon', count: alerts.expiringSoonCount || 0, cls: 'text-amber-600 dark:text-amber-400' },
    ].filter((a) => a.count > 0);
  }, [alerts]);

  const topInsights = (insights || []).filter((i) => i.severity === 'critical' || i.severity === 'warning').slice(0, 4);

  if (!alertItems.length && !topInsights.length) {
    return (
      <SectionCard title="Operational Alerts" icon={AlertTriangle} iconColor="text-amber-500">
        <div className="flex items-center gap-3 rounded-lg border border-dashed border-emerald-200 bg-emerald-50/50 px-4 py-3 dark:border-emerald-500/20 dark:bg-emerald-500/5">
          <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-500 opacity-60" />
          <p className="text-[12px] font-medium text-emerald-700 dark:text-emerald-300">All clear — no critical alerts</p>
        </div>
      </SectionCard>
    );
  }

  return (
    <SectionCard title="Operational Alerts" icon={AlertTriangle} iconColor="text-amber-500">
      {alertItems.length > 0 && (
        <div className="grid grid-cols-2 gap-1.5">
          {alertItems.map(({ icon: Icon, label, count, cls }) => (
            <div key={label} className="flex items-center gap-2 rounded-lg border border-slate-200/80 bg-white px-2.5 py-2 dark:border-slate-700/60 dark:bg-slate-800/60">
              <Icon className={`h-3.5 w-3.5 shrink-0 ${cls}`} />
              <span className={`text-sm font-bold tabular-nums ${cls}`}>{count}</span>
              <span className="text-[10px] text-slate-500 dark:text-slate-400">{label}</span>
            </div>
          ))}
        </div>
      )}
      {topInsights.length > 0 && (
        <div className="mt-2 space-y-1">
          {topInsights.map((ins, i) => (
            <div key={i} className={`flex items-start gap-2 rounded-md px-2.5 py-1.5 text-[11px] ${ins.severity === 'critical' ? 'bg-red-50 text-red-700 dark:bg-red-500/10 dark:text-red-300' : 'bg-amber-50 text-amber-700 dark:bg-amber-500/10 dark:text-amber-300'}`}>
              <Info className="mt-px h-3 w-3 shrink-0 opacity-70" />
              <span className="font-medium leading-tight">{ins.message}</span>
            </div>
          ))}
        </div>
      )}
    </SectionCard>
  );
}

/* ═══════════════════════════════════════════════════════════════
   WAREHOUSE PANEL
   ═══════════════════════════════════════════════════════════════ */
function WarehousePanel({ warehouseStats }) {
  if (!warehouseStats?.length) return null;
  return (
    <SectionCard title="My Warehouses" icon={Warehouse} iconColor="text-sky-500">
      <div className="space-y-1.5">
        {warehouseStats.map((wh) => {
          const barColor = wh.utilization >= 85 ? 'bg-red-500' : wh.utilization >= 60 ? 'bg-amber-500' : 'bg-emerald-500';
          const utColor = wh.utilization >= 85 ? 'text-red-600 dark:text-red-400' : wh.utilization >= 60 ? 'text-amber-600 dark:text-amber-400' : 'text-emerald-600 dark:text-emerald-400';
          return (
            <div key={wh.id} className="flex items-center gap-3 rounded-lg border border-slate-200/80 bg-white px-3 py-2 dark:border-slate-700/60 dark:bg-slate-800/60">
              <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-md bg-sky-50 dark:bg-sky-500/10">
                <Warehouse className="h-3.5 w-3.5 text-sky-600 dark:text-sky-400" />
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex items-baseline justify-between">
                  <p className="truncate text-[12px] font-semibold text-slate-800 dark:text-slate-100">{wh.name}</p>
                  <span className="ml-2 text-xs font-bold tabular-nums text-slate-700 dark:text-slate-200">{fmt(wh.totalUnits)} <span className="font-normal text-slate-400">units</span></span>
                </div>
                <div className="mt-1 flex items-center gap-2">
                  <div className="h-1 flex-1 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-700">
                    <div className={`h-full rounded-full ${barColor}`} style={{ width: `${Math.min(wh.utilization, 100)}%` }} />
                  </div>
                  <span className={`text-[10px] font-bold tabular-nums ${utColor}`}>{wh.utilization}%</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </SectionCard>
  );
}

/* ═══════════════════════════════════════════════════════════════
   ACTIVITY FEED
   ═══════════════════════════════════════════════════════════════ */
function ActivityFeed({ movements }) {
  const items = movements?.movements || movements || [];
  if (!items.length) return null;
  return (
    <SectionCard title="Recent Activity" icon={Zap} iconColor="text-violet-500" link="/stock-movements" linkLabel="All movements">
      <div className="space-y-0.5">
        {items.slice(0, 10).map((m, i) => {
          const MIcon = MOVEMENT_ICONS[m.type] || Box;
          const mColor = MOVEMENT_COLORS[m.type] || 'text-slate-500';
          const ts = m.timestamp || m.createdAt || m.created_at;
          return (
            <div key={m.id || m._id || i} className="flex items-center gap-2.5 rounded-md px-2 py-1.5 transition-colors hover:bg-slate-50 dark:hover:bg-slate-800/60">
              <MIcon className={`h-3.5 w-3.5 shrink-0 ${mColor}`} />
              <div className="min-w-0 flex-1">
                <p className="truncate text-[11px] text-slate-700 dark:text-slate-300">
                  <span className="font-semibold">{m.type}</span>
                  {m.product?.name && <> · {m.product.name}</>}
                  {m.quantity != null && <> · <span className="tabular-nums">{m.quantity}</span> units</>}
                </p>
              </div>
              <span className="shrink-0 text-[10px] tabular-nums text-slate-400 dark:text-slate-500">{relTime(ts)}</span>
            </div>
          );
        })}
      </div>
    </SectionCard>
  );
}

/* ═══════════════════════════════════════════════════════════════
   INVENTORY HEALTH BAR
   ═══════════════════════════════════════════════════════════════ */
function InventoryHealth({ summary }) {
  if (!summary) return null;
  const total = Math.max(1, (summary.in_stock || 0) + (summary.low_stock || 0) + (summary.out_of_stock || 0));
  const pIn = ((summary.in_stock || 0) / total * 100).toFixed(1);
  const pLow = ((summary.low_stock || 0) / total * 100).toFixed(1);
  const pOut = ((summary.out_of_stock || 0) / total * 100).toFixed(1);

  return (
    <SectionCard title="Inventory Health" icon={Package} iconColor="text-violet-500" link="/staff/inventory" linkLabel="Details">
      <div className="flex items-center gap-3 rounded-lg border border-slate-200/80 bg-white px-3 py-2.5 dark:border-slate-700/60 dark:bg-slate-800/60">
        <div className="min-w-0 flex-1">
          <div className="flex h-2 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-700">
            <div className="bg-emerald-500" style={{ width: `${pIn}%` }} />
            <div className="bg-amber-500" style={{ width: `${pLow}%` }} />
            <div className="bg-red-500" style={{ width: `${pOut}%` }} />
          </div>
          <div className="mt-1.5 flex items-center gap-3 text-[10px]">
            <span className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-emerald-500" /> In Stock <b className="tabular-nums text-slate-700 dark:text-slate-200">{summary.in_stock}</b></span>
            <span className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-amber-500" /> Low <b className="tabular-nums text-slate-700 dark:text-slate-200">{summary.low_stock}</b></span>
            <span className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-red-500" /> Out <b className="tabular-nums text-slate-700 dark:text-slate-200">{summary.out_of_stock}</b></span>
          </div>
        </div>
        <div className="text-right">
          <p className="text-base font-bold tabular-nums text-slate-800 dark:text-slate-100">{fmt(summary.total_units)}</p>
          <p className="text-[9px] font-medium uppercase tracking-wider text-slate-400">total units</p>
        </div>
      </div>
    </SectionCard>
  );
}

/* ═══════════════════════════════════════════════════════════════
   SECTION CARD
   ═══════════════════════════════════════════════════════════════ */
function SectionCard({ title, icon: Icon, iconColor, count, link, linkLabel, children }) {
  return (
    <div className="rounded-xl border border-slate-200/80 bg-slate-50/40 dark:border-slate-700/60 dark:bg-slate-900/30">
      <div className="flex items-center justify-between border-b border-slate-200/60 px-3 py-2 dark:border-slate-700/40">
        <div className="flex items-center gap-2">
          <Icon className={`h-3.5 w-3.5 ${iconColor || 'text-slate-400'}`} />
          <h3 className="text-[12px] font-semibold text-slate-800 dark:text-slate-200">{title}</h3>
          {count != null && count > 0 && (
            <span className="rounded-full bg-slate-200/80 px-1.5 py-px text-[10px] font-bold tabular-nums text-slate-600 dark:bg-slate-700 dark:text-slate-300">{count}</span>
          )}
        </div>
        {link && (
          <Link to={link} className="flex items-center gap-0.5 text-[10px] font-medium text-sky-600 transition hover:text-sky-700 dark:text-sky-400 dark:hover:text-sky-300">
            {linkLabel || 'View'} <ChevronRight className="h-3 w-3" />
          </Link>
        )}
      </div>
      <div className="p-2.5">{children}</div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   LOADING SKELETON
   ═══════════════════════════════════════════════════════════════ */
function LoadingSkeleton() {
  return (
    <div className="space-y-3 px-3 py-4 sm:px-4">
      <div className="h-10 w-56 animate-pulse rounded-lg bg-slate-100 dark:bg-slate-800" />
      <div className="grid grid-cols-2 gap-2 sm:grid-cols-4 lg:grid-cols-7">
        {Array.from({ length: 7 }).map((_, i) => <div key={i} className="h-16 animate-pulse rounded-lg bg-slate-100 dark:bg-slate-800" />)}
      </div>
      <div className="grid gap-3 lg:grid-cols-5">
        <div className="h-64 animate-pulse rounded-xl bg-slate-100 dark:bg-slate-800 lg:col-span-3" />
        <div className="h-64 animate-pulse rounded-xl bg-slate-100 dark:bg-slate-800 lg:col-span-2" />
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   MAIN EXPORT
   ═══════════════════════════════════════════════════════════════ */
export function StaffDashboard() {
  const queryClient = useQueryClient();

  const { data: taskData, isLoading: tasksLoading, isError: tasksError } = useQuery({
    queryKey: ['tasks', 'list'],
    queryFn: fetchTaskList,
    refetchOnWindowFocus: true,
    staleTime: 30_000,
  });
  const { data: widgets } = useQuery({ queryKey: ['dashboard', 'widgets'], queryFn: fetchWidgets, refetchOnWindowFocus: true, staleTime: 45_000 });
  const { data: inventory } = useQuery({ queryKey: ['inventory', 'tracking'], queryFn: fetchInventory, refetchOnWindowFocus: true, staleTime: 60_000 });
  const { data: movementData } = useQuery({ queryKey: ['movements', 'recent'], queryFn: fetchMovements, refetchOnWindowFocus: true, staleTime: 60_000 });

  const [updatingId, setUpdatingId] = useState(null);

  const statusMutation = useMutation({
    mutationFn: ({ id, status }) => api.patch(`/tasks/${id}/status`, { status }),
    onMutate: ({ id }) => setUpdatingId(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tasks', 'list'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard', 'widgets'] });
      queryClient.invalidateQueries({ queryKey: ['inventory'] });
      queryClient.invalidateQueries({ queryKey: ['movements'] });
    },
    onSettled: () => setUpdatingId(null),
  });

  const handleStatusChange = (id, status) => statusMutation.mutate({ id, status });
  const tasks = Array.isArray(taskData?.tasks) ? taskData.tasks : [];

  if (tasksLoading) return <LoadingSkeleton />;
  if (tasksError) {
    return (
      <div className="py-4">
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2.5 text-[13px] text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
          Could not load dashboard. Please try again.
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <StaffHeader />
      <KpiRow tasks={tasks} taskSummary={widgets?.taskSummary} />

      {/* Operations breakdown */}
      <TodayOpsPanel tasks={tasks} />

      {/* Tasks + Alerts */}
      <div className="grid gap-3 lg:grid-cols-5">
        <div className="lg:col-span-3">
          <TasksPanel tasks={tasks} onStatusChange={handleStatusChange} updatingId={updatingId} />
        </div>
        <div className="space-y-3 lg:col-span-2">
          <AlertsPanel alerts={widgets?.alerts} insights={widgets?.insights} />
          <InventoryHealth summary={inventory?.summary} />
        </div>
      </div>

      {/* Warehouses + Activity */}
      <div className="grid gap-3 lg:grid-cols-5">
        <div className="lg:col-span-2">
          <WarehousePanel warehouseStats={widgets?.warehouseStats} />
        </div>
        <div className="lg:col-span-3">
          <ActivityFeed movements={movementData} />
        </div>
      </div>
    </div>
  );
}
