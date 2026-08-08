import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { api } from '../api/client';
import { fetchTaskList } from '../api/taskList';
import { useAuth } from '../context/AuthContext';
import { UserAvatar } from '../components/profile/UserAvatar';
import { TaskPriorityBadge, TaskStatusBadge, TaskOverdueBadge, DueDateBadge, TASK_KPI_ITEMS } from '../components/tasks/TaskBadges';
import { dueDateInfo } from '../utils/dueDate';
import { TaskFormModal } from '../components/tasks/TaskFormModal';
import { Button } from '../components/ui/button';
import {
  canCreateTasks,
  canManageTasks,
  getStatusActions,
  ACTION_LABELS,
} from '../utils/taskPermissions';
import { taskTypeLabel, statusLabel } from '../utils/taskLabels';
import {
  filterTasksByStatus,
  isTaskOverdue,
  resolveTaskStats,
  taskWorkflowStatus,
} from '../utils/taskOverdue';
import {
  ArrowRight,
  ArrowRightLeft,
  CheckCircle2,
  ClipboardList,
  Loader2,
  Pencil,
  Play,
  Plus,
  RotateCcw,
  Search,
  Send,
  ThumbsUp,
  XCircle,
} from 'lucide-react';

/* ─── Helpers ─── */

function formatDue(iso) {
  if (!iso) return '—';
  try { return new Date(iso).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' }); } catch { return '—'; }
}

/* ─── Constants ─── */

const ACTION_ICONS = {
  Accepted: ThumbsUp,
  'In Progress': Play,
  'Waiting Confirmation': Send,
  Completed: CheckCircle2,
  Rejected: XCircle,
  Pending: RotateCcw,
};

const ACTION_STYLES = {
  sky: 'border-sky-200 bg-sky-50 text-sky-700 hover:bg-sky-100 dark:border-sky-500/30 dark:bg-sky-500/10 dark:text-sky-300 dark:hover:bg-sky-500/20',
  blue: 'border-blue-200 bg-blue-50 text-blue-700 hover:bg-blue-100 dark:border-blue-500/30 dark:bg-blue-500/10 dark:text-blue-300 dark:hover:bg-blue-500/20',
  amber: 'border-amber-200 bg-amber-50 text-amber-700 hover:bg-amber-100 dark:border-amber-500/30 dark:bg-amber-500/10 dark:text-amber-300 dark:hover:bg-amber-500/20',
  emerald: 'border-emerald-200 bg-emerald-50 text-emerald-700 hover:bg-emerald-100 dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-300 dark:hover:bg-emerald-500/20',
  red: 'border-red-200 bg-red-50 text-red-700 hover:bg-red-100 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300 dark:hover:bg-red-500/20',
  slate: 'border-slate-200 bg-slate-50 text-slate-700 hover:bg-slate-100 dark:border-slate-600 dark:bg-slate-700 dark:text-slate-300 dark:hover:bg-slate-600',
};

const ALL_STATUSES = ['', 'Pending', 'Accepted', 'In Progress', 'Overdue', 'Completed', 'Rejected'];

/* ═══════════════════════════════════════════════════════════════
   TasksPage
   ═══════════════════════════════════════════════════════════════ */

export function TasksPage() {
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const { user } = useAuth();
  const isStaff = user?.role === 'Staff';
  const canManage = canManageTasks(user?.role);
  const canCreate = canCreateTasks(user?.role);

  const [statusFilter, setStatusFilter] = useState('');
  const [searchQ, setSearchQ] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [priorityFilter, setPriorityFilter] = useState('');
  const [modal, setModal] = useState(null);

  const { data, isLoading, isError, error, refetch } = useQuery({
    queryKey: ['tasks', 'list'],
    queryFn: fetchTaskList,
  });

  const allTasks = Array.isArray(data?.tasks) ? data.tasks : [];

  /* ── Search / type / priority (shared by KPIs + table) ── */
  const baseTasks = useMemo(() => {
    let list = allTasks;
    if (searchQ.trim()) {
      const q = searchQ.trim().toLowerCase();
      list = list.filter((t) =>
        (t.title || '').toLowerCase().includes(q)
        || (t.description || '').toLowerCase().includes(q)
        || (t.warehouse?.name || '').toLowerCase().includes(q)
        || (t.related_product?.name || '').toLowerCase().includes(q)
        || (t.assigned_to?.full_name || '').toLowerCase().includes(q)
      );
    }
    if (typeFilter) list = list.filter((t) => t.task_type === typeFilter);
    if (priorityFilter) list = list.filter((t) => t.priority === priorityFilter);
    return list;
  }, [allTasks, searchQ, typeFilter, priorityFilter]);

  const stats = useMemo(() => {
    const computed = resolveTaskStats(baseTasks, data?.stats);
    if (!searchQ.trim() && !typeFilter && !priorityFilter && data?.stats) {
      return computed;
    }
    return resolveTaskStats(baseTasks);
  }, [baseTasks, data?.stats, searchQ, typeFilter, priorityFilter]);

  const tasks = useMemo(
    () => filterTasksByStatus(baseTasks, statusFilter),
    [baseTasks, statusFilter]
  );

  /* ── Unique task types for filter ── */
  const taskTypes = useMemo(() => [...new Set(allTasks.map((t) => t.task_type))].sort(), [allTasks]);

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['tasks', 'list'] });
    queryClient.invalidateQueries({ queryKey: ['notifications'] });
    queryClient.invalidateQueries({ queryKey: ['dashboard', 'widgets'] });
    queryClient.invalidateQueries({ queryKey: ['inventory'] });
    queryClient.invalidateQueries({ queryKey: ['movements'] });
  };

  const statusMutation = useMutation({
    mutationFn: ({ id, status }) => api.patch(`/tasks/${id}/status`, { status }),
    onSuccess: () => invalidate(),
  });


  /* ═══════════════════════════════════════════════════
     Render
     ═══════════════════════════════════════════════════ */

  return (
    <div className="space-y-4 px-1">

      {/* ── Header ── */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-lg font-semibold tracking-tight text-foreground sm:text-xl">
            {isStaff ? 'My Tasks' : 'Task Workflow'}
          </h1>
          <p className="mt-0.5 text-xs text-muted-foreground">
            {isStaff
              ? 'Execute and complete assigned warehouse operations.'
              : 'Create, assign, and monitor warehouse task workflows.'}
          </p>
        </div>
        {canCreate && (
          <Button onClick={() => setModal({ mode: 'create' })} size="sm">
            <Plus className="h-3.5 w-3.5" />
            New Task
          </Button>
        )}
      </div>

      {/* ── KPI Strip ── */}
      <div className="grid grid-cols-2 gap-2 sm:grid-cols-4 lg:grid-cols-7">
        {TASK_KPI_ITEMS.map((kpi) => {
          const val = stats[kpi.statKey] ?? stats[kpi.key] ?? 0;
          const active = kpi.key === 'total' ? !statusFilter : statusFilter === kpi.key;
          return (
            <button
              key={kpi.key}
              type="button"
              onClick={() => setStatusFilter(kpi.key === 'total' ? '' : (active ? '' : kpi.key))}
              className={`group flex items-center gap-2 rounded-lg border px-2.5 py-2 text-left transition ${
                active
                  ? `${kpi.bg} ${kpi.ring} ring-1`
                  : 'border-border bg-card hover:bg-muted/40'
              }`}
            >
              <span className={`text-base font-bold tabular-nums leading-none ${kpi.color}`}>{val}</span>
              <span className="text-[10px] font-medium text-muted-foreground">{kpi.label}</span>
            </button>
          );
        })}
      </div>

      {/* ── Filters Bar ── */}
      <div className="flex flex-wrap items-center gap-2">
        <div className="relative flex-1 sm:max-w-xs">
          <Search className="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            value={searchQ}
            onChange={(e) => setSearchQ(e.target.value)}
            placeholder="Search tasks, products, warehouses…"
            className="wms-input h-8 pl-8 text-xs"
          />
        </div>

        {/* Status pills */}
        <div className="flex items-center gap-1">
          <button
            type="button"
            onClick={() => setStatusFilter('')}
            className={`rounded-md px-2 py-1 text-[10px] font-semibold transition ${
              !statusFilter ? 'bg-accent text-white' : 'bg-muted/50 text-muted-foreground hover:text-foreground'
            }`}
          >
            All ({stats._total})
          </button>
          {ALL_STATUSES.filter(Boolean).map((s) => {
            const c = stats[s] || 0;
            if (c === 0 && statusFilter !== s) return null;
            return (
              <button
                key={s}
                type="button"
                onClick={() => setStatusFilter(statusFilter === s ? '' : s)}
                className={`rounded-md px-2 py-1 text-[10px] font-semibold transition ${
                  statusFilter === s ? 'bg-accent text-white' : 'bg-muted/50 text-muted-foreground hover:text-foreground'
                }`}
              >
                {s === 'Waiting Confirmation' ? 'Awaiting Confirm' : statusLabel(s)} ({c})
              </button>
            );
          })}
        </div>

        {/* Type + Priority filters */}
        <div className="flex items-center gap-1.5 ml-auto">
          <select
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
            className="wms-input h-8 w-auto min-w-0 py-0 text-[10px] font-medium"
          >
            <option value="">All Types</option>
            {taskTypes.map((t) => <option key={t} value={t}>{taskTypeLabel(t)}</option>)}
          </select>
          <select
            value={priorityFilter}
            onChange={(e) => setPriorityFilter(e.target.value)}
            className="wms-input h-8 w-auto min-w-0 py-0 text-[10px] font-medium"
          >
            <option value="">All Priorities</option>
            <option value="low">Low</option>
            <option value="medium">Medium</option>
            <option value="high">High</option>
            <option value="critical">Critical</option>
          </select>
        </div>
      </div>

      {/* ── Tasks Table ── */}
      {isLoading ? (
        <div className="flex items-center gap-2 py-12 justify-center text-muted-foreground">
          <Loader2 className="h-4 w-4 animate-spin" />
          <span className="text-sm">Loading tasks…</span>
        </div>
      ) : isError ? (
        <div className="py-12 text-center text-sm text-red-600">
          {error?.response?.data?.message || error?.message || 'Failed to load tasks.'}
          <button type="button" onClick={() => refetch()} className="ml-2 font-semibold underline">
            Retry
          </button>
        </div>
      ) : tasks.length === 0 ? (
        <div className="flex flex-col items-center gap-2 py-16 text-center">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-muted">
            <ClipboardList className="h-5 w-5 text-muted-foreground" />
          </div>
          <p className="text-sm font-medium text-foreground">
            {searchQ || typeFilter || priorityFilter ? 'No tasks match your filters' : isStaff ? 'No tasks assigned to you' : 'No tasks created yet'}
          </p>
          <p className="text-xs text-muted-foreground">
            {searchQ || typeFilter || priorityFilter
              ? 'Adjust your search or clear filters.'
              : isStaff ? 'Tasks will appear here when assigned by a supervisor.' : 'Create a task to assign warehouse operations.'}
          </p>
          {canCreate && !searchQ && !typeFilter && !priorityFilter && (
            <Button size="sm" variant="secondary" className="mt-2" onClick={() => setModal({ mode: 'create' })}>
              <Plus className="h-3.5 w-3.5" /> Create Task
            </Button>
          )}
        </div>
      ) : (
        <div className="rounded-lg border border-border bg-card">
          <div className="overflow-x-auto">
            <table className="min-w-full text-left text-sm">
              <thead>
                <tr className="border-b border-border text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">
                  <th className="px-3 py-2.5">Task</th>
                  <th className="px-3 py-2.5">Type</th>
                  <th className="px-3 py-2.5">Status</th>
                  <th className="px-3 py-2.5 hidden sm:table-cell">Priority</th>
                  <th className="px-3 py-2.5 hidden md:table-cell">Warehouse</th>
                  <th className="px-3 py-2.5 hidden lg:table-cell">Assigned By</th>
                  {!isStaff && <th className="px-3 py-2.5 hidden lg:table-cell">Assigned To</th>}
                  <th className="px-3 py-2.5 hidden lg:table-cell">Due</th>
                  <th className="px-3 py-2.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/60">
                {tasks.map((task) => {
                  const closed = ['Completed', 'Rejected'].includes(task.status);
                  const overdue = isTaskOverdue(task);
                  // Shared urgency helper — same thresholds as the task detail page.
                  const due = dueDateInfo(task);
                  const meta = task.task_type_meta;
                  const isOp = Boolean(meta?.movement_type);

                  return (
                    <tr
                      key={task.id}
                      className="group cursor-pointer transition hover:bg-muted/30"
                      onClick={() => navigate(`/tasks/${task.id}`)}
                    >
                      {/* Task info */}
                      <td className="px-3 py-2.5">
                        <div className="flex items-start gap-2.5">
                          {/* Type indicator */}
                          <div className={`mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-md ${isOp ? 'bg-violet-100 text-violet-600 dark:bg-violet-500/15 dark:text-violet-300' : 'bg-slate-100 text-slate-500 dark:bg-slate-700/50 dark:text-slate-400'}`}>
                            {isOp ? <ArrowRightLeft className="h-3.5 w-3.5" /> : <ClipboardList className="h-3.5 w-3.5" />}
                          </div>
                          <div className="min-w-0 flex-1">
                            <p className="text-[13px] font-semibold leading-tight text-foreground group-hover:text-accent transition">{task.title}</p>
                            <div className="mt-0.5 flex flex-wrap items-center gap-x-2 gap-y-0.5 text-[10px] text-muted-foreground">
                              {task.related_product && (
                                <span className="font-medium text-foreground/70">{task.related_product.name}</span>
                              )}
                            </div>
                            {/* Operational context */}
                            {isOp && (
                              <div className="mt-1 flex items-center gap-1.5">
                                <span className="inline-flex items-center gap-0.5 rounded border border-violet-200 bg-violet-50 px-1 py-px text-[8px] font-bold uppercase text-violet-600 dark:border-violet-500/30 dark:bg-violet-500/10 dark:text-violet-300">
                                  {meta.movement_type}
                                </span>
                                {task.quantity > 0 && (
                                  <span className="text-[10px] font-semibold tabular-nums text-violet-600 dark:text-violet-300">{task.quantity} units</span>
                                )}
                                {meta.movement_type === 'TRANSFER' && task.warehouse?.name && task.to_warehouse?.name && (
                                  <span className="flex items-center gap-0.5 text-[10px] text-muted-foreground">
                                    {task.warehouse.name}
                                    <ArrowRight className="h-2.5 w-2.5" />
                                    {task.to_warehouse.name}
                                  </span>
                                )}
                              </div>
                            )}
                          </div>
                        </div>
                      </td>

                      <td className="px-3 py-2.5">
                        <span className="text-xs font-medium text-foreground">{task.task_type_label || taskTypeLabel(task.task_type)}</span>
                      </td>

                      {/* Status */}
                      <td className="px-3 py-2.5">
                        <div className="flex flex-wrap items-center gap-1">
                          <TaskStatusBadge status={task.status} workflowStatus={task.workflow_status} />
                          {(task.is_overdue || overdue) && <TaskOverdueBadge />}
                        </div>
                      </td>

                      {/* Priority */}
                      <td className="px-3 py-2.5 hidden sm:table-cell">
                        <TaskPriorityBadge priority={task.priority} />
                      </td>

                      {/* Warehouse */}
                      <td className="px-3 py-2.5 hidden md:table-cell">
                        <span className="text-xs text-muted-foreground">{task.warehouse?.name || '—'}</span>
                      </td>

                      {/* Assigned By */}
                      <td className="px-3 py-2.5 hidden lg:table-cell">
                        <span className="text-[11px] text-muted-foreground">
                          {task.assigned_by?.full_name || task.assigned_by?.username || '—'}
                        </span>
                      </td>

                      {/* Assigned To */}
                      {!isStaff && (
                        <td className="px-3 py-2.5 hidden lg:table-cell">
                          <div className="flex items-center gap-1.5">
                            <UserAvatar
                              user={{ fullName: task.assigned_to?.full_name, username: task.assigned_to?.username, email: task.assigned_to?.email, avatar: task.assigned_to?.avatar }}
                              size="sm"
                            />
                            <span className="text-[11px] font-medium text-foreground">{task.assigned_to?.full_name || task.assigned_to?.username}</span>
                          </div>
                        </td>
                      )}

                      {/* Due */}
                      <td className="px-3 py-2.5 hidden lg:table-cell whitespace-nowrap">
                        {overdue || due.isUrgent ? (
                          <DueDateBadge task={task} />
                        ) : (
                          <span className="text-[11px] text-muted-foreground">{formatDue(task.due_date)}</span>
                        )}
                      </td>

                      {/* Actions */}
                      <td className="px-3 py-2.5 text-right" onClick={(e) => e.stopPropagation()}>
                        <div className="flex items-center justify-end gap-1">
                          {getStatusActions(taskWorkflowStatus(task), user?.role).slice(0, 2).map((nextStatus) => {
                            const cfg = ACTION_LABELS[nextStatus];
                            if (!cfg) return null;
                            const AIcon = ACTION_ICONS[nextStatus] || Play;
                            return (
                              <button
                                key={nextStatus}
                                type="button"
                                disabled={statusMutation.isPending}
                                onClick={() => statusMutation.mutate({ id: task.id, status: nextStatus })}
                                title={cfg.label}
                                className={`inline-flex items-center gap-1 rounded-md border px-1.5 py-1 text-[10px] font-semibold transition disabled:opacity-50 ${ACTION_STYLES[cfg.variant] || ACTION_STYLES.slate}`}
                              >
                                <AIcon className="h-3 w-3" />
                                <span className="hidden sm:inline">{cfg.label}</span>
                              </button>
                            );
                          })}
                          {canManage && (
                            <button
                              type="button"
                              title="Edit"
                              className="rounded-md p-1 text-muted-foreground transition hover:bg-muted hover:text-foreground"
                              onClick={() => setModal({ mode: 'edit', task })}
                            >
                              <Pencil className="h-3 w-3" />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* Results count */}
          <div className="border-t border-border/60 px-3 py-2 text-[10px] text-muted-foreground">
            {tasks.length} task{tasks.length !== 1 && 's'}
            {(searchQ || typeFilter || priorityFilter || statusFilter) && ` (filtered from ${allTasks.length})`}
            {stats._operational > 0 && !searchQ && !typeFilter && !priorityFilter && (
              <> · <span className="text-violet-600 dark:text-violet-400">{stats._operational} operational</span></>
            )}
          </div>
        </div>
      )}

      {/* ──── Create/Edit Modal ──── */}
      {modal && canManage && (
        <TaskFormModal
          mode={modal.mode}
          editTask={modal.task || null}
          onClose={() => setModal(null)}
          onSaved={() => { invalidate(); setModal(null); }}
        />
      )}
    </div>
  );
}

