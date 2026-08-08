import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useNavigate, useParams } from 'react-router-dom';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { UserAvatar } from '../components/profile/UserAvatar';
import { TaskPriorityBadge, TaskStatusBadge, TaskOverdueBadge } from '../components/tasks/TaskBadges';
import { isTaskOverdue, taskWorkflowStatus } from '../utils/taskOverdue';
import { TaskFormModal } from '../components/tasks/TaskFormModal';
import { Button } from '../components/ui/button';
import {
  canManageTasks,
  canDeleteTasks,
  getStatusActions,
  ACTION_LABELS,
} from '../utils/taskPermissions';
import {
  AlertTriangle,
  ArrowLeft,
  ArrowRight,
  ArrowRightLeft,
  CheckCircle2,
  Clock,
  ClipboardList,
  Loader2,
  MessageSquarePlus,
  Package,
  Pencil,
  Play,
  RotateCcw,
  Send,
  ThumbsUp,
  Trash2,
  User,
  Warehouse,
  X,
  XCircle,
} from 'lucide-react';

/* ─── API ─── */

async function fetchTask(id) {
  const { data } = await api.get(`/tasks/${id}`);
  return data.task;
}

async function fetchProductStock(warehouseId, productId) {
  const { data } = await api.get('/inventory/stock-lookup', {
    params: { warehouse_id: warehouseId, product_id: productId },
  });
  return data;
}

/* ─── Helpers ─── */

function fmtDate(iso) {
  if (!iso) return '—';
  try { return new Date(iso).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' }); } catch { return '—'; }
}

function fmtShort(iso) {
  if (!iso) return '—';
  try { return new Date(iso).toLocaleDateString(undefined, { month: 'short', day: 'numeric' }); } catch { return '—'; }
}

function duration(from, to) {
  if (!from || !to) return null;
  const ms = new Date(to) - new Date(from);
  if (ms < 0) return null;
  const m = Math.floor(ms / 60000);
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ${m % 60}m`;
  return `${Math.floor(h / 24)}d ${h % 24}h`;
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

const MOVEMENT_LABELS = { INBOUND: 'Inbound', OUTBOUND: 'Outbound', TRANSFER: 'Transfer', ADJUSTMENT: 'Adjustment' };

const TIMELINE_COLORS = {
  Pending: 'bg-slate-400',
  Accepted: 'bg-sky-500',
  'In Progress': 'bg-blue-500',
  'Waiting Confirmation': 'bg-amber-500',
  Completed: 'bg-emerald-500',
  Rejected: 'bg-red-500',
  Overdue: 'bg-red-500',
};

/* ═══════════════════════════════════════════════════════════════
   TaskDetailPage
   ═══════════════════════════════════════════════════════════════ */

export function TaskDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { user } = useAuth();
  const canManage = canManageTasks(user?.role);
  const canDelete = canDeleteTasks(user?.role);

  const [noteText, setNoteText] = useState('');
  const [actionError, setActionError] = useState('');
  const [editModal, setEditModal] = useState(false);

  const { data: task, isLoading, isError } = useQuery({
    queryKey: ['tasks', 'detail', id],
    queryFn: () => fetchTask(id),
    refetchInterval: 30_000,
  });

  const meta = task?.task_type_meta;
  const isOp = Boolean(meta?.movement_type);
  const isTransfer = meta?.movement_type === 'TRANSFER';
  const isOutbound = meta?.movement_type === 'OUTBOUND';
  const isInbound = meta?.movement_type === 'INBOUND';
  const closed = task && ['Completed', 'Rejected'].includes(task.status);

  const { data: stock } = useQuery({
    queryKey: ['stock-lookup', 'detail', task?.warehouse?.id, task?.related_product?.id],
    queryFn: () => fetchProductStock(task.warehouse.id, task.related_product.id),
    enabled: Boolean(task?.warehouse?.id) && Boolean(task?.related_product?.id) && isOp && !closed,
    staleTime: 30_000,
  });

  const actions = task ? getStatusActions(taskWorkflowStatus(task), user?.role) : [];

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['tasks'] });
    queryClient.invalidateQueries({ queryKey: ['notifications'] });
    queryClient.invalidateQueries({ queryKey: ['dashboard', 'widgets'] });
    queryClient.invalidateQueries({ queryKey: ['inventory'] });
    queryClient.invalidateQueries({ queryKey: ['movements'] });
  };

  const statusMutation = useMutation({
    mutationFn: ({ status, note, executed_quantity }) => api.patch(`/tasks/${id}/status`, { status, note, executed_quantity }),
    onSuccess: () => { invalidate(); setActionError(''); },
    onError: (err) => setActionError(err.response?.data?.message || 'Action failed'),
  });

  const noteMutation = useMutation({
    mutationFn: (text) => api.post(`/tasks/${id}/notes`, { text }),
    onSuccess: () => { invalidate(); setNoteText(''); },
    onError: (err) => setActionError(err.response?.data?.message || 'Failed to add note'),
  });

  const deleteMutation = useMutation({
    mutationFn: () => api.delete(`/tasks/${id}`),
    onSuccess: () => { invalidate(); navigate('/tasks'); },
  });

  /* ── Derived data ── */
  const due = task?.due_date ? new Date(task.due_date) : null;
  const isOverdue = task ? (task.is_overdue ?? isTaskOverdue(task)) : false;
  const completionTime = duration(task?.created_at, task?.completed_at);

  /* ═══ Loading / Error ═══ */
  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-24 text-muted-foreground">
        <Loader2 className="mr-2 h-5 w-5 animate-spin" /> Loading task…
      </div>
    );
  }
  if (isError || !task) {
    return (
      <div className="flex flex-col items-center gap-3 py-24 text-center">
        <p className="text-sm text-red-600">Task not found or failed to load.</p>
        <Button variant="secondary" size="sm" onClick={() => navigate('/tasks')}>
          <ArrowLeft className="mr-1 h-3.5 w-3.5" /> Back to Tasks
        </Button>
      </div>
    );
  }

  /* ═══ Render ═══ */
  return (
    <div className="space-y-4 px-1">

      {/* ── Breadcrumb & Back ── */}
      <div className="flex items-center gap-2 text-xs text-muted-foreground">
        <button type="button" onClick={() => navigate('/tasks')} className="inline-flex items-center gap-1 rounded-md px-1.5 py-0.5 font-medium transition hover:bg-muted hover:text-foreground">
          <ArrowLeft className="h-3 w-3" /> Tasks
        </button>
        <span>/</span>
        <span className="font-medium text-foreground truncate max-w-xs">{task.title}</span>
      </div>

      {/* ── Header Card ── */}
      <div className="rounded-lg border border-border bg-card px-4 py-3.5">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-1.5">
              <TaskStatusBadge status={task.status} workflowStatus={task.workflow_status} />
              <TaskPriorityBadge priority={task.priority} />
              {isOp && (
                <span className="inline-flex items-center gap-0.5 rounded border border-violet-200 bg-violet-50 px-1.5 py-px text-[9px] font-bold uppercase text-violet-600 dark:border-violet-500/30 dark:bg-violet-500/10 dark:text-violet-300">
                  {meta.movement_type}
                </span>
              )}
              {isOverdue && <TaskOverdueBadge />}
            </div>
            <h1 className="mt-2 text-lg font-semibold leading-snug text-foreground sm:text-xl">{task.title}</h1>
            {task.description && <p className="mt-1 text-xs text-muted-foreground leading-relaxed max-w-2xl">{task.description}</p>}
          </div>
          <div className="flex items-center gap-1.5 shrink-0">
            {canManage && (
              <button type="button" onClick={() => setEditModal(true)} className="rounded-md border border-border px-2.5 py-1.5 text-[11px] font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground">
                <Pencil className="mr-1 inline h-3 w-3" /> Edit
              </button>
            )}
            {canDelete && (
              <button type="button" disabled={deleteMutation.isPending} onClick={() => deleteMutation.mutate()} className="rounded-md border border-red-200 px-2.5 py-1.5 text-[11px] font-medium text-red-600 transition hover:bg-red-50 dark:border-red-500/30 dark:hover:bg-red-500/10 disabled:opacity-50">
                <Trash2 className="mr-1 inline h-3 w-3" /> Delete
              </button>
            )}
          </div>
        </div>

        {/* Info strip */}
        <div className="mt-3 flex flex-wrap items-center gap-x-5 gap-y-2 border-t border-border/60 pt-3 text-xs text-muted-foreground">
          <InfoChip icon={<ClipboardList className="h-3 w-3" />} label={task.task_type} />
          <InfoChip icon={<Warehouse className="h-3 w-3" />} label={task.warehouse?.name || '—'} />
          {task.assigned_to && (
            <div className="flex items-center gap-1.5">
              <UserAvatar user={{ fullName: task.assigned_to.full_name, username: task.assigned_to.username, email: task.assigned_to.email, avatar: task.assigned_to.avatar }} size="sm" />
              <span className="font-medium text-foreground">{task.assigned_to.full_name || task.assigned_to.username}</span>
            </div>
          )}
          <InfoChip icon={<Clock className="h-3 w-3" />} label={fmtDate(task.due_date)} className={isOverdue ? 'text-red-600 dark:text-red-400 font-semibold' : ''} />
          {completionTime && <InfoChip icon={<CheckCircle2 className="h-3 w-3 text-emerald-500" />} label={`Done in ${completionTime}`} />}
        </div>
      </div>

      {/* ── Main Grid ── */}
      <div className="grid gap-4 lg:grid-cols-5">

        {/* ──────── LEFT: Details ──────── */}
        <div className="space-y-4 lg:col-span-3">

          {/* Operational Context */}
          {isOp && (
            <Section title="Operational Context">
              <div className="space-y-3">
                {/* Movement type header */}
                <div className="flex items-center gap-2">
                  <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-violet-100 text-violet-600 dark:bg-violet-500/15 dark:text-violet-300">
                    <ArrowRightLeft className="h-4 w-4" />
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-foreground">{MOVEMENT_LABELS[meta.movement_type] || meta.movement_type}</p>
                    <p className="text-[10px] text-muted-foreground">
                      {meta.movement_type === 'TRANSFER' ? 'Warehouse-to-warehouse transfer' : `${MOVEMENT_LABELS[meta.movement_type]} operation`}
                      {task.movement_id && ' · Movement created'}
                    </p>
                  </div>
                  {task.movement_id && <CheckCircle2 className="ml-auto h-4 w-4 text-emerald-500" />}
                </div>

                {/* Product & Route */}
                <div className="grid gap-2 sm:grid-cols-2">
                  {task.related_product && (
                    <MiniCard label="Product" value={task.related_product.name} sub={task.related_product.sku} icon={<Package className="h-3.5 w-3.5" />} />
                  )}
                  <MiniCard label="Quantity" value={`${task.quantity || '—'} units`} sub={task.executed_quantity != null && task.executed_quantity !== task.quantity ? `Executed: ${task.executed_quantity}` : null} icon={<Package className="h-3.5 w-3.5" />} />
                </div>

                {/* Transfer route visualization */}
                {isTransfer && (
                  <div className="flex items-center gap-2 rounded-lg border border-border bg-muted/20 px-3 py-2.5">
                    <div className="flex items-center gap-1.5 rounded border border-blue-200 bg-blue-50/80 px-2 py-1 dark:border-blue-500/30 dark:bg-blue-500/10">
                      <Warehouse className="h-3 w-3 text-blue-500" />
                      <span className="text-[11px] font-semibold text-blue-800 dark:text-blue-200">{task.warehouse?.name}</span>
                    </div>
                    <ArrowRight className="h-4 w-4 text-muted-foreground" />
                    <div className="flex items-center gap-1.5 rounded border border-emerald-200 bg-emerald-50/80 px-2 py-1 dark:border-emerald-500/30 dark:bg-emerald-500/10">
                      <Warehouse className="h-3 w-3 text-emerald-500" />
                      <span className="text-[11px] font-semibold text-emerald-800 dark:text-emerald-200">{task.to_warehouse?.name || '—'}</span>
                    </div>
                  </div>
                )}

                {/* Stock preview (only for non-closed operational tasks) */}
                {stock && !closed && (
                  <div className={`rounded-lg border px-3 py-2.5 ${stock.out_of_stock ? 'border-red-200 bg-red-50/60 dark:border-red-500/20 dark:bg-red-500/5' : stock.low_stock ? 'border-amber-200 bg-amber-50/60 dark:border-amber-500/20 dark:bg-amber-500/5' : 'border-border bg-muted/20'}`}>
                    <div className="flex items-center gap-2">
                      <span className="text-[9px] font-bold uppercase tracking-wider text-muted-foreground">Current Stock at {task.warehouse?.name}</span>
                      {stock.out_of_stock && <span className="rounded bg-red-100 px-1 py-px text-[7px] font-bold text-red-700 dark:bg-red-500/20 dark:text-red-300">OUT</span>}
                      {stock.low_stock && !stock.out_of_stock && <span className="rounded bg-amber-100 px-1 py-px text-[7px] font-bold text-amber-700 dark:bg-amber-500/20 dark:text-amber-300">LOW</span>}
                    </div>
                    <div className="mt-1.5 flex items-center gap-4 text-xs">
                      <StatBlock label="Available" value={stock.available} color={stock.out_of_stock ? 'text-red-600' : 'text-emerald-600 dark:text-emerald-400'} />
                      {stock.damaged > 0 && <StatBlock label="Damaged" value={stock.damaged} color="text-orange-600 dark:text-orange-400" />}
                      <StatBlock label="Total" value={stock.total} color="text-foreground" />
                    </div>
                    {(isOutbound || isTransfer) && stock.available < (task.quantity || 0) && (
                      <p className="mt-1.5 flex items-center gap-1 text-[10px] font-semibold text-red-600 dark:text-red-400">
                        <AlertTriangle className="h-3 w-3" /> Insufficient stock for this operation ({stock.available} available, {task.quantity} required)
                      </p>
                    )}
                  </div>
                )}
              </div>
            </Section>
          )}

          {/* Task Details */}
          <Section title="Details">
            <div className="grid gap-x-6 gap-y-3 sm:grid-cols-2 text-xs">
              <DetailRow label="Assigned to" value={task.assigned_to?.full_name || task.assigned_to?.username} />
              <DetailRow label="Assigned by" value={task.assigned_by?.full_name || task.assigned_by?.username} />
              <DetailRow label="Warehouse" value={task.warehouse?.name} />
              {task.to_warehouse && <DetailRow label="Destination" value={task.to_warehouse.name} />}
              {task.related_product && <DetailRow label="Product" value={`${task.related_product.sku} — ${task.related_product.name}`} />}
              {task.related_order && <DetailRow label="Order" value={`${task.related_order.order_number} — ${task.related_order.customer_name}`} />}
              {task.supplier_name && <DetailRow label="Supplier" value={task.supplier_name} />}
              {task.destination_client && <DetailRow label="Dispatch destination" value={task.destination_client} />}
              {task.return_reason && <DetailRow label="Return reason" value={task.return_reason} />}
              <DetailRow label="Created" value={fmtDate(task.created_at)} />
              <DetailRow label="Due" value={fmtDate(task.due_date)} />
              {task.accepted_at && <DetailRow label="Accepted" value={fmtDate(task.accepted_at)} />}
              {task.started_at && <DetailRow label="Started" value={fmtDate(task.started_at)} />}
              {task.completed_at && <DetailRow label="Completed" value={fmtDate(task.completed_at)} />}
            </div>
            {task.audit_trail && (
              <div className="mt-4 rounded-lg border border-border/60 bg-muted/10 p-3">
                <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Audit trail</p>
                <div className="mt-2 grid gap-2 sm:grid-cols-2 text-[11px]">
                  <DetailRow label="Created by" value={task.audit_trail.created_by?.full_name || task.audit_trail.created_by?.username} />
                  {task.audit_trail.accepted?.user && (
                    <DetailRow label="Accepted by" value={task.audit_trail.accepted.user.full_name || task.audit_trail.accepted.user.username} />
                  )}
                  {task.audit_trail.started?.user && (
                    <DetailRow label="Started by" value={task.audit_trail.started.user.full_name || task.audit_trail.started.user.username} />
                  )}
                  {task.audit_trail.completed?.user && (
                    <DetailRow label="Completed by" value={task.audit_trail.completed.user.full_name || task.audit_trail.completed.user.username} />
                  )}
                </div>
              </div>
            )}
          </Section>

          {/* Notes */}
          <Section title="Notes">
            <div className="flex gap-1.5">
              <input
                type="text"
                value={noteText}
                onChange={(e) => setNoteText(e.target.value)}
                onKeyDown={(e) => { if (e.key === 'Enter' && noteText.trim()) noteMutation.mutate(noteText.trim()); }}
                placeholder="Add an operational note…"
                className="wms-input h-8 flex-1 text-xs"
              />
              <button
                type="button"
                disabled={!noteText.trim() || noteMutation.isPending}
                onClick={() => noteText.trim() && noteMutation.mutate(noteText.trim())}
                className="inline-flex h-8 items-center rounded-md border border-border bg-card px-2.5 text-muted-foreground transition hover:bg-muted hover:text-foreground disabled:opacity-40"
              >
                <MessageSquarePlus className="h-3.5 w-3.5" />
              </button>
            </div>
            {(task.notes || []).length > 0 ? (
              <ul className="mt-2 space-y-1">
                {task.notes.slice().reverse().map((n) => (
                  <li key={n.id} className="rounded-md border border-border/50 bg-muted/15 px-3 py-2 text-[11px]">
                    <p className="text-foreground leading-relaxed">{n.text}</p>
                    <p className="mt-1 text-[9px] text-muted-foreground">{n.created_by?.full_name || n.created_by?.username || 'System'} · {fmtDate(n.created_at)}</p>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="mt-2 text-[11px] text-muted-foreground">No notes yet.</p>
            )}
          </Section>
        </div>

        {/* ──────── RIGHT: Actions & Timeline ──────── */}
        <div className="space-y-4 lg:col-span-2">

          {/* Workflow Actions */}
          {actions.length > 0 && (
            <Section title="Workflow Actions">
              {actionError && (
                <div className="mb-2 flex items-start gap-2 rounded-md border border-red-200 bg-red-50 px-2.5 py-1.5 text-[11px] font-medium text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
                  <AlertTriangle className="mt-0.5 h-3 w-3 shrink-0" />
                  {actionError}
                </div>
              )}
              <div className="space-y-1.5">
                {actions.map((nextStatus) => {
                  const cfg = ACTION_LABELS[nextStatus];
                  if (!cfg) return null;
                  const AIcon = ACTION_ICONS[nextStatus] || Play;
                  return (
                    <button
                      key={nextStatus}
                      type="button"
                      disabled={statusMutation.isPending}
                      onClick={() => statusMutation.mutate({ status: nextStatus })}
                      className={`flex w-full items-center gap-2 rounded-lg border px-3 py-2 text-xs font-semibold transition disabled:opacity-50 ${ACTION_STYLES[cfg.variant] || ACTION_STYLES.slate}`}
                    >
                      <AIcon className="h-3.5 w-3.5" />
                      {cfg.label}
                    </button>
                  );
                })}
              </div>
            </Section>
          )}

          {/* Completion summary for closed tasks */}
          {closed && (
            <div className={`rounded-lg border px-3 py-3 ${task.status === 'Completed' ? 'border-emerald-200 bg-emerald-50/60 dark:border-emerald-500/20 dark:bg-emerald-500/5' : 'border-red-200 bg-red-50/60 dark:border-red-500/20 dark:bg-red-500/5'}`}>
              <div className="flex items-center gap-2">
                {task.status === 'Completed' ? <CheckCircle2 className="h-4 w-4 text-emerald-500" /> : <XCircle className="h-4 w-4 text-red-500" />}
                <span className="text-sm font-semibold text-foreground">{task.status}</span>
              </div>
              {completionTime && <p className="mt-1 text-[10px] text-muted-foreground">Total duration: {completionTime}</p>}
              {task.movement_id && (
                <p className="mt-1 flex items-center gap-1 text-[10px] text-emerald-600 dark:text-emerald-400">
                  <ArrowRightLeft className="h-3 w-3" /> Movement created successfully
                </p>
              )}
            </div>
          )}

          {/* Activity Timeline */}
          <Section title="Timeline">
            <div className="relative space-y-0">
              {/* Vertical line */}
              <div className="absolute left-[7px] top-2 bottom-2 w-px bg-border" />

              {(task.status_history || []).slice().reverse().map((h, i) => (
                <div key={h.id} className="relative flex gap-3 pb-3">
                  <div className={`relative z-10 mt-1 h-[15px] w-[15px] shrink-0 rounded-full border-2 border-card ${TIMELINE_COLORS[h.status] || 'bg-slate-400'}`} />
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center justify-between gap-2">
                      <div className="flex items-center gap-1.5">
                        <TaskStatusBadge status={h.status} />
                        <span className="text-[11px] font-medium text-foreground">{h.changed_by?.full_name || h.changed_by?.username || 'System'}</span>
                      </div>
                      <span className="shrink-0 text-[9px] tabular-nums text-muted-foreground">{fmtDate(h.changed_at)}</span>
                    </div>
                    {h.note && <p className="mt-0.5 text-[10px] text-muted-foreground leading-relaxed">{h.note}</p>}
                    {h.action && h.action !== 'status_change' && (
                      <p className="mt-0.5 text-[9px] font-medium text-violet-600 dark:text-violet-400">{h.action}</p>
                    )}
                  </div>
                </div>
              ))}

              {(task.status_history || []).length === 0 && (
                <p className="py-3 pl-7 text-[11px] text-muted-foreground">No activity recorded yet.</p>
              )}
            </div>
          </Section>

          {/* Supervisor Insights */}
          {canManage && (
            <Section title="Supervision">
              <div className="space-y-2 text-[11px]">
                <InsightRow label="Created by" value={task.created_by?.full_name || task.created_by?.username || task.assigned_by?.username} />
                <InsightRow label="Created" value={fmtDate(task.created_at)} />
                {task.accepted_at && <InsightRow label="Time to accept" value={duration(task.created_at, task.accepted_at)} />}
                {task.started_at && <InsightRow label="Time to start" value={duration(task.accepted_at || task.created_at, task.started_at)} />}
                {task.completed_at && <InsightRow label="Execution time" value={duration(task.started_at || task.created_at, task.completed_at)} />}
                <InsightRow label="Status changes" value={`${(task.status_history || []).length}`} />
                <InsightRow label="Notes" value={`${(task.notes || []).length}`} />
              </div>
            </Section>
          )}
        </div>
      </div>

      {/* ── Edit Modal ── */}
      {editModal && canManage && (
        <TaskFormModal
          mode="edit"
          editTask={task}
          onClose={() => setEditModal(false)}
          onSaved={() => { invalidate(); setEditModal(false); }}
        />
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   Sub-components
   ═══════════════════════════════════════════════════════════════ */

function Section({ title, children }) {
  return (
    <div className="rounded-lg border border-border bg-card">
      <div className="border-b border-border/60 px-3.5 py-2">
        <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">{title}</p>
      </div>
      <div className="px-3.5 py-3">{children}</div>
    </div>
  );
}

function InfoChip({ icon, label, className = '' }) {
  return (
    <div className={`flex items-center gap-1.5 ${className}`}>
      {icon}
      <span>{label}</span>
    </div>
  );
}

function MiniCard({ label, value, sub, icon }) {
  return (
    <div className="rounded-lg border border-border bg-muted/20 px-3 py-2">
      <p className="text-[9px] font-bold uppercase tracking-wider text-muted-foreground">{label}</p>
      <div className="mt-1 flex items-center gap-1.5">
        <span className="text-muted-foreground">{icon}</span>
        <span className="text-sm font-semibold text-foreground">{value}</span>
      </div>
      {sub && <p className="mt-0.5 text-[10px] text-muted-foreground">{sub}</p>}
    </div>
  );
}

function StatBlock({ label, value, color }) {
  return (
    <div className="text-center">
      <p className={`text-base font-bold tabular-nums ${color}`}>{value}</p>
      <p className="text-[8px] text-muted-foreground">{label}</p>
    </div>
  );
}

function DetailRow({ label, value }) {
  if (!value) return null;
  return (
    <div>
      <p className="text-[9px] font-semibold uppercase text-muted-foreground">{label}</p>
      <p className="mt-0.5 font-medium text-foreground">{value}</p>
    </div>
  );
}

function InsightRow({ label, value }) {
  return (
    <div className="flex items-center justify-between gap-2">
      <span className="text-muted-foreground">{label}</span>
      <span className="font-medium text-foreground tabular-nums">{value || '—'}</span>
    </div>
  );
}
