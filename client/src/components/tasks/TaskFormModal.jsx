import { useEffect, useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../../api/client';
import { StaffCombobox } from './StaffCombobox';
import { Button } from '../ui/button';
import { Field, Input } from '../ui/input';
import {
  AlertTriangle,
  ArrowRight,
  CheckCircle2,
  Info,
  Loader2,
  Package,
  Warehouse as WarehouseIcon,
  X,
} from 'lucide-react';

/* ─── API helpers ─── */

async function fetchTaskMeta() {
  const { data } = await api.get('/tasks/meta/options');
  return data;
}

/** Staff eligible for the task — transfers also count staff at the destination warehouse. */
async function fetchAssignees(warehouseId, toWarehouseId) {
  const { data } = await api.get('/tasks/meta/assignees', {
    params: { warehouse_id: warehouseId, ...(toWarehouseId ? { to_warehouse_id: toWarehouseId } : {}) },
  });
  return data;
}

async function fetchWarehouseProducts(warehouseId) {
  const { data } = await api.get('/inventory/stock-lookup', { params: { warehouse_id: warehouseId } });
  return data;
}

async function fetchProductStock(warehouseId, productId) {
  const { data } = await api.get('/inventory/stock-lookup', { params: { warehouse_id: warehouseId, product_id: productId } });
  return data;
}

async function fetchProductAvailability(productId) {
  const { data } = await api.get('/inventory/product-availability', { params: { product_id: productId } });
  return data;
}

/* ─── Utilities ─── */

function toDatetimeLocal(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

const ASSIGNEE_REQUIRED_ERROR = 'Assign a staff member.';

/** Option label for a staff member — name first, username as the fallback identity. */
function staffLabel(staff) {
  const name = staff?.full_name?.trim();
  if (name && staff.username && name.toLowerCase() !== staff.username.toLowerCase()) {
    return `${name} (${staff.username})`;
  }
  return name || staff?.username || '';
}

const EMPTY_FORM = {
  title: '',
  description: '',
  task_type: 'Stock Transfer',
  priority: 'medium',
  warehouse_id: '',
  to_warehouse_id: '',
  assigned_to_id: '',
  due_date: '',
  related_order_id: '',
  related_product_id: '',
  quantity: '',
  supplier_name: '',
  destination_client: '',
  return_reason: '',
};

/* ═══════════════════════════════════════════════════════════════
   Main Component
   ═══════════════════════════════════════════════════════════════ */

export function TaskFormModal({ mode = 'create', editTask = null, onClose, onSaved }) {
  const queryClient = useQueryClient();
  const [form, setForm] = useState(EMPTY_FORM);
  const [formError, setFormError] = useState('');

  const { data: meta } = useQuery({ queryKey: ['tasks', 'meta'], queryFn: fetchTaskMeta });

  useEffect(() => {
    if (mode === 'edit' && editTask) {
      setForm({
        title: editTask.title || '',
        description: editTask.description || '',
        task_type: editTask.task_type || 'Inventory Receive',
        priority: editTask.priority || 'medium',
        warehouse_id: editTask.warehouse?.id || '',
        to_warehouse_id: editTask.to_warehouse?.id || '',
        assigned_to_id: editTask.assigned_to?.id || '',
        due_date: toDatetimeLocal(editTask.due_date),
        related_order_id: editTask.related_order?.id || '',
        related_product_id: editTask.related_product?.id || '',
        quantity: editTask.quantity ?? '',
        supplier_name: editTask.supplier_name || '',
        destination_client: editTask.destination_client || '',
        return_reason: editTask.return_reason || '',
      });
    } else if (meta) {
      setForm((f) => ({
        ...f,
        task_type: meta.operation_task_types?.[0] || meta.task_types?.[0] || 'Stock Transfer',
        due_date: toDatetimeLocal(new Date(Date.now() + 86400000).toISOString()),
      }));
    }
  }, [mode, editTask, meta]);

  /* ── Derived type flags ── */
  const typeMeta = useMemo(() => meta?.task_type_meta?.[form.task_type] || null, [meta, form.task_type]);
  const isTransfer = typeMeta?.movementType === 'TRANSFER';
  const isInbound = typeMeta?.movementType === 'INBOUND';
  const isOutbound = typeMeta?.movementType === 'OUTBOUND';
  const isReturn = form.task_type === 'Return Task';
  const isAdjustment = typeMeta?.movementType === 'ADJUSTMENT';
  const isOrderPacking = form.task_type === 'Order Packing';
  const isInventoryCount = form.task_type === 'Inventory Count';
  const isInspection = form.task_type === 'Inspection';
  const isCleaning = form.task_type === 'Cleaning';
  const isOperational = typeMeta?.operational && typeMeta?.movementType;
  const needsQuantity = typeMeta?.requiresQuantity;
  const needsProduct = typeMeta?.requiresProduct;
  const needsStockValidation = isTransfer || isOutbound;
  const operationTypes = meta?.operation_task_types || meta?.task_types || [];
  const typeLabels = meta?.task_type_labels || {};

  /* ─── Transfer: product-first availability ─── */
  const { data: productAvail, isLoading: availLoading } = useQuery({
    queryKey: ['product-availability', form.related_product_id],
    queryFn: () => fetchProductAvailability(form.related_product_id),
    enabled: isTransfer && Boolean(form.related_product_id),
    staleTime: 20_000,
  });

  const availableWarehouses = useMemo(() => {
    if (!isTransfer || !productAvail?.warehouses) return [];
    return productAvail.warehouses.filter((w) => w.available > 0);
  }, [isTransfer, productAvail]);

  const transferReady = isTransfer && availableWarehouses.length > 0;

  const sourceAvail = useMemo(() => {
    if (!form.warehouse_id || !productAvail?.warehouses) return null;
    return productAvail.warehouses.find((w) => w.warehouse_id === form.warehouse_id) || null;
  }, [form.warehouse_id, productAvail]);

  /* ─── Outbound/Adjustment: warehouse-first product lookup ─── */
  const { data: whProducts, isLoading: whProductsLoading } = useQuery({
    queryKey: ['stock-lookup', 'products', form.warehouse_id],
    queryFn: () => fetchWarehouseProducts(form.warehouse_id),
    enabled: Boolean(form.warehouse_id) && (isOutbound || isAdjustment),
    staleTime: 30_000,
  });

  const { data: stockDetail, isLoading: stockLoading } = useQuery({
    queryKey: ['stock-lookup', 'detail', form.warehouse_id, form.related_product_id],
    queryFn: () => fetchProductStock(form.warehouse_id, form.related_product_id),
    enabled: Boolean(form.warehouse_id) && Boolean(form.related_product_id) && (isOutbound || isAdjustment),
    staleTime: 15_000,
  });

  /* ─── Assignees ─── */
  const { data: assigneeData, isLoading: assigneesLoading } = useQuery({
    queryKey: ['tasks', 'assignees', form.warehouse_id, form.to_warehouse_id || null],
    queryFn: () => fetchAssignees(form.warehouse_id, form.to_warehouse_id),
    enabled: Boolean(form.warehouse_id),
  });

  const assignees = assigneeData?.staff || [];
  const assigneeFallback = Boolean(assigneeData?.fallback);

  const inventoryProducts = whProducts?.products || [];
  const allProducts = meta?.products || [];

  const qtyNum = Number(form.quantity) || 0;
  const maxAvailable = isTransfer
    ? (sourceAvail?.available ?? Infinity)
    : (stockDetail?.available ?? Infinity);
  const qtyExceedsStock = needsStockValidation && qtyNum > maxAvailable && maxAvailable !== Infinity;

  /* ── Save mutation ── */
  const saveMutation = useMutation({
    mutationFn: ({ id, body }) => (id ? api.patch(`/tasks/${id}`, body) : api.post('/tasks', body)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tasks'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard', 'widgets'] });
      onSaved?.();
    },
    onError: (err) => setFormError(err.response?.data?.message || 'Save failed'),
  });

  /* ── Handlers ── */

  function handleTypeChange(newType) {
    setForm((f) => ({ ...f, task_type: newType, related_product_id: '', warehouse_id: '', to_warehouse_id: '', assigned_to_id: '', quantity: '', related_order_id: '' }));
    setFormError('');
  }

  function handleTransferProductChange(productId) {
    setForm((f) => ({ ...f, related_product_id: productId, warehouse_id: '', to_warehouse_id: '', assigned_to_id: '', quantity: '' }));
    setFormError('');
  }

  function handleTransferSourceChange(whId) {
    setForm((f) => ({ ...f, warehouse_id: whId, to_warehouse_id: f.to_warehouse_id === whId ? '' : f.to_warehouse_id, assigned_to_id: '', quantity: '' }));
    setFormError('');
  }

  function handleWarehouseChange(whId) {
    setForm((f) => ({ ...f, warehouse_id: whId, assigned_to_id: '', related_product_id: '', quantity: '' }));
    setFormError('');
  }

  /* ── Staff assignment ── */

  /**
   * Writes the chosen staff id into the form and drops the "assign a staff member"
   * error immediately, so the user can submit without a second round-trip.
   * Receives the staff object from the combobox (or null when cleared).
   */
  function handleAssigneeSelect(staff) {
    const staffId = staff?.id || '';
    setForm((f) => ({ ...f, assigned_to_id: staffId }));
    if (staffId) setFormError((e) => (e === ASSIGNEE_REQUIRED_ERROR ? '' : e));
  }

  const staffPicker = {
    warehouseId: form.warehouse_id,
    assignees,
    loading: assigneesLoading,
    fallback: assigneeFallback,
    selectedId: form.assigned_to_id,
    error: formError === ASSIGNEE_REQUIRED_ERROR ? formError : '',
    onSelect: handleAssigneeSelect,
  };

  /* ── Validation + submit ── */

  function buildBody() {
    if (!form.title.trim()) { setFormError('Task title is required.'); return null; }
    if (!form.warehouse_id) { setFormError('Select a warehouse.'); return null; }
    if (!form.assigned_to_id) { setFormError(ASSIGNEE_REQUIRED_ERROR); return null; }
    if (!form.due_date) { setFormError('Due date is required.'); return null; }

    if (needsProduct && !form.related_product_id) {
      setFormError('Product is required for this task type.'); return null;
    }
    if (needsQuantity && (!form.quantity || qtyNum < 1)) {
      setFormError('Quantity must be at least 1.'); return null;
    }
    if (qtyExceedsStock) {
      setFormError(`Quantity exceeds available stock (${maxAvailable} units available).`); return null;
    }
    if (isTransfer && !form.to_warehouse_id) {
      setFormError('Destination warehouse is required for transfers.'); return null;
    }
    if (isTransfer && form.to_warehouse_id === form.warehouse_id) {
      setFormError('Source and destination must be different warehouses.'); return null;
    }
    if (isInbound && !form.supplier_name.trim()) {
      setFormError('Supplier is required for receive tasks.'); return null;
    }
    if (isOutbound && !form.destination_client.trim()) {
      setFormError('Destination / customer is required for dispatch tasks.'); return null;
    }
    if (isReturn && !form.return_reason.trim() && !form.description.trim()) {
      setFormError('Return reason is required.'); return null;
    }

    return {
      title: form.title.trim(),
      description: form.description,
      task_type: form.task_type,
      priority: form.priority,
      warehouse_id: form.warehouse_id,
      assigned_to_id: form.assigned_to_id,
      due_date: new Date(form.due_date).toISOString(),
      related_order_id: form.related_order_id || null,
      related_product_id: needsProduct ? form.related_product_id : null,
      quantity: needsQuantity ? qtyNum : null,
      to_warehouse_id: isTransfer ? form.to_warehouse_id : null,
      supplier_name: isInbound ? form.supplier_name.trim() : '',
      destination_client: isOutbound ? form.destination_client.trim() : '',
      return_reason: isReturn ? form.return_reason.trim() : '',
    };
  }

  function submitForm(e) {
    e.preventDefault();
    setFormError('');
    const body = buildBody();
    if (body) saveMutation.mutate({ id: mode === 'edit' ? editTask?.id : null, body });
  }

  /* ── Resolved references for preview ── */
  const selectedProduct = useMemo(() => {
    if (!form.related_product_id) return null;
    if (isTransfer && productAvail) return { product_name: productAvail.product_name, product_sku: productAvail.product_sku };
    return inventoryProducts.find((p) => p.product_id === form.related_product_id) || allProducts.find((p) => p.id === form.related_product_id);
  }, [form.related_product_id, isTransfer, productAvail, inventoryProducts, allProducts]);

  const sourceWarehouse = isTransfer
    ? (sourceAvail ? { name: sourceAvail.warehouse_name } : null)
    : meta?.warehouses?.find((w) => w.id === form.warehouse_id);
  const destWarehouse = meta?.warehouses?.find((w) => w.id === form.to_warehouse_id) || (isTransfer && productAvail?.warehouses?.find((w) => w.warehouse_id === form.to_warehouse_id));
  const destWarehouseName = destWarehouse?.name || destWarehouse?.warehouse_name;
  const assignedStaff = assignees.find((s) => s.id === form.assigned_to_id);

  /* ═══════════════════════════════════════════════════
     Render
     ═══════════════════════════════════════════════════ */

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/20 p-3 backdrop-blur-sm">
      <div className="flex max-h-[92vh] w-full max-w-3xl flex-col overflow-hidden rounded-xl border border-border bg-card shadow-2xl">

        {/* Header */}
        <div className="flex items-center justify-between border-b border-border px-5 py-3.5">
          <div>
            <h2 className="text-base font-semibold text-foreground">
              {mode === 'create' ? 'Create Task' : 'Edit Task'}
            </h2>
            <p className="mt-0.5 text-[11px] text-muted-foreground">
              {isOperational
                ? `Operational — auto-creates ${typeMeta.movementType} movement on completion`
                : isOrderPacking || isInventoryCount
                  ? 'Operational task — no stock movement'
                  : 'Non-operational — no stock movement will be created'}
            </p>
          </div>
          <button type="button" onClick={onClose} className="text-muted-foreground hover:text-foreground">
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={submitForm} className="flex-1 overflow-y-auto">
          <div className="space-y-4 px-5 py-4">

            {/* ── Section: Task Information (shared) ── */}
            <div className="space-y-3">
              <SectionLabel>Task Information</SectionLabel>
              <Field label="Task title" required>
                <Input value={form.title} onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))} placeholder={TITLE_PLACEHOLDERS[form.task_type] || 'Task title…'} />
              </Field>
              <div className="grid gap-3 sm:grid-cols-3">
                <Field label="Task type" required>
                  <select value={form.task_type} onChange={(e) => handleTypeChange(e.target.value)} className="wms-input mt-1">
                    {(operationTypes.length ? operationTypes : meta?.task_types || []).map((t) => (
                      <option key={t} value={t}>{typeLabels[t] || t}</option>
                    ))}
                  </select>
                </Field>
                <Field label="Priority" required>
                  <select value={form.priority} onChange={(e) => setForm((f) => ({ ...f, priority: e.target.value }))} className="wms-input mt-1">
                    {(meta?.priorities || []).map((p) => <option key={p} value={p}>{p}</option>)}
                  </select>
                </Field>
                <Field label="Due date" required>
                  <Input type="datetime-local" value={form.due_date} onChange={(e) => setForm((f) => ({ ...f, due_date: e.target.value }))} className="mt-1" />
                </Field>
              </div>
              <Field label="Description">
                <textarea rows={2} value={form.description} onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))} className="wms-input mt-1" placeholder="Optional details…" />
              </Field>
            </div>

            {/* ═══════════════════════════════════════════════════
               TRANSFER — Product-first inventory workflow
               ═══════════════════════════════════════════════════ */}
            {isTransfer && <TransferWorkflow
              form={form} setForm={setForm} meta={meta}
              allProducts={allProducts} productAvail={productAvail}
              availLoading={availLoading} availableWarehouses={availableWarehouses}
              sourceAvail={sourceAvail} maxAvailable={maxAvailable} qtyExceedsStock={qtyExceedsStock}
              staffPicker={staffPicker}
              handleTransferProductChange={handleTransferProductChange}
              handleTransferSourceChange={handleTransferSourceChange}
            />}

            {/* ═══════════════════════════════════════════════════
               INVENTORY RECEIVE — Warehouse-first inbound workflow
               ═══════════════════════════════════════════════════ */}
            {isInbound && <InboundWorkflow
              form={form} setForm={setForm} meta={meta} allProducts={allProducts}
              staffPicker={staffPicker}
              handleWarehouseChange={handleWarehouseChange}
            />}

            {/* ═══════════════════════════════════════════════════
               OUTBOUND DISPATCH — Stock-validated outbound workflow
               ═══════════════════════════════════════════════════ */}
            {isOutbound && <OutboundWorkflow
              form={form} setForm={setForm} meta={meta}
              inventoryProducts={inventoryProducts} whProductsLoading={whProductsLoading} allProducts={allProducts}
              stockDetail={stockDetail} stockLoading={stockLoading}
              maxAvailable={maxAvailable} qtyExceedsStock={qtyExceedsStock}
              staffPicker={staffPicker}
              handleWarehouseChange={handleWarehouseChange}
            />}

            {isReturn && <InboundWorkflow
              form={form} setForm={setForm} meta={meta} allProducts={allProducts}
              staffPicker={staffPicker}
              handleWarehouseChange={handleWarehouseChange}
              isReturn
            />}

            {/* ═══════════════════════════════════════════════════
               STOCK ADJUSTMENT — Warehouse-first correction workflow
               ═══════════════════════════════════════════════════ */}
            {isAdjustment && <AdjustmentWorkflow
              form={form} setForm={setForm} meta={meta}
              inventoryProducts={inventoryProducts} whProductsLoading={whProductsLoading} allProducts={allProducts}
              stockDetail={stockDetail} stockLoading={stockLoading}
              staffPicker={staffPicker}
              handleWarehouseChange={handleWarehouseChange}
            />}

            {/* ═══════════════════════════════════════════════════
               ORDER PACKING — Order-first fulfillment workflow
               ═══════════════════════════════════════════════════ */}
            {isOrderPacking && <OrderPackingWorkflow
              form={form} setForm={setForm} meta={meta}
              staffPicker={staffPicker}
              handleWarehouseChange={handleWarehouseChange}
            />}

            {/* ═══════════════════════════════════════════════════
               INVENTORY COUNT — Warehouse-first counting workflow
               ═══════════════════════════════════════════════════ */}
            {isInventoryCount && <CountWorkflow
              form={form} setForm={setForm} meta={meta} allProducts={allProducts}
              staffPicker={staffPicker}
              handleWarehouseChange={handleWarehouseChange}
            />}

            {/* ═══════════════════════════════════════════════════
               INSPECTION — Warehouse-first inspection workflow
               ═══════════════════════════════════════════════════ */}
            {isInspection && <SimpleWarehouseWorkflow
              label="Inspection"
              form={form} meta={meta}
              staffPicker={staffPicker}
              handleWarehouseChange={handleWarehouseChange}
            />}

            {/* ═══════════════════════════════════════════════════
               CLEANING — Warehouse-first cleaning workflow
               ═══════════════════════════════════════════════════ */}
            {isCleaning && <SimpleWarehouseWorkflow
              label="Cleaning"
              form={form} meta={meta}
              staffPicker={staffPicker}
              handleWarehouseChange={handleWarehouseChange}
            />}

            {/* ── Operation Preview ── */}
            {isOperational && form.warehouse_id && form.related_product_id && qtyNum > 0 && (!isTransfer || (transferReady && form.warehouse_id)) && (
              <OperationPreview
                typeMeta={typeMeta}
                productName={selectedProduct?.product_name || selectedProduct?.name || '—'}
                productSku={selectedProduct?.product_sku || selectedProduct?.sku || '—'}
                quantity={qtyNum}
                sourceWarehouse={sourceWarehouse?.name || sourceWarehouse?.warehouse_name}
                destWarehouse={destWarehouseName}
                assignee={assignedStaff?.full_name || assignedStaff?.username}
              />
            )}

            {formError && (
              <div className="flex items-start gap-2 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm font-medium text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
                <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" /> {formError}
              </div>
            )}
          </div>

          <div className="flex items-center justify-end gap-2 border-t border-border px-5 py-3">
            <Button type="button" variant="secondary" onClick={onClose}>Cancel</Button>
            <Button type="submit" disabled={saveMutation.isPending}>
              {saveMutation.isPending ? 'Saving…' : mode === 'create' ? 'Create Task' : 'Save Changes'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   WORKFLOW: Stock Transfer (product → availability → source → dest → qty → staff)
   ═══════════════════════════════════════════════════════════════ */

function TransferWorkflow({ form, setForm, meta, allProducts, productAvail, availLoading, availableWarehouses, sourceAvail, maxAvailable, qtyExceedsStock, staffPicker, handleTransferProductChange, handleTransferSourceChange }) {
  return (
    <>
      <div className="space-y-3">
        <SectionLabel><StepBadge n={1} active />Product Selection</SectionLabel>
        <Field label="Product to transfer" required>
          <select value={form.related_product_id} onChange={(e) => handleTransferProductChange(e.target.value)} className="wms-input mt-1">
            <option value="">Select product…</option>
            {allProducts.map((p) => <option key={p.id} value={p.id}>{p.sku} — {p.name}</option>)}
          </select>
        </Field>
      </div>

      {form.related_product_id && (
        <div className="space-y-2">
          <SectionLabel><StepBadge n={2} active={!availLoading} />Inventory Availability</SectionLabel>
          {availLoading ? (
            <LoadingBar text="Checking warehouse inventory…" />
          ) : availableWarehouses.length === 0 ? (
            <CompactWarning title="No inventory available" sub="Add stock to a warehouse before creating a transfer task." />
          ) : (
            <>
              <div className="grid gap-1.5 sm:grid-cols-2 lg:grid-cols-3">
                {(productAvail?.warehouses || []).map((wh) => {
                  const isSource = form.warehouse_id === wh.warehouse_id;
                  const isDest = form.to_warehouse_id === wh.warehouse_id;
                  const noStock = wh.available === 0;
                  return (
                    <button key={wh.warehouse_id} type="button" disabled={noStock} onClick={() => { if (!noStock && !isSource) handleTransferSourceChange(wh.warehouse_id); }}
                      className={`group relative rounded-lg border px-2.5 py-2 text-left transition ${isSource ? 'border-blue-300 bg-blue-50/80 ring-1 ring-blue-200 dark:border-blue-500/40 dark:bg-blue-500/10 dark:ring-blue-500/30' : isDest ? 'border-emerald-300 bg-emerald-50/80 ring-1 ring-emerald-200 dark:border-emerald-500/40 dark:bg-emerald-500/10 dark:ring-emerald-500/30' : noStock ? 'cursor-not-allowed border-border bg-muted/20 opacity-40' : 'border-border bg-muted/20 hover:border-blue-200 hover:bg-blue-50/40 dark:hover:border-blue-500/30 dark:hover:bg-blue-500/5'}`}>
                      {isSource && <span className="absolute -top-1.5 right-1.5 rounded bg-blue-600 px-1 py-px text-[7px] font-bold uppercase leading-none text-white">Source</span>}
                      {isDest && <span className="absolute -top-1.5 right-1.5 rounded bg-emerald-600 px-1 py-px text-[7px] font-bold uppercase leading-none text-white">Dest</span>}
                      <div className="flex items-center justify-between gap-2">
                        <div className="flex items-center gap-1.5 min-w-0">
                          <WarehouseIcon className="h-3 w-3 shrink-0 text-muted-foreground" />
                          <span className="truncate text-[11px] font-semibold text-foreground">{wh.warehouse_name}</span>
                        </div>
                        <div className="flex items-center gap-1.5 shrink-0">
                          <span className={`text-sm font-bold tabular-nums leading-none ${noStock ? 'text-slate-400 dark:text-slate-500' : wh.low_stock ? 'text-amber-600 dark:text-amber-400' : 'text-emerald-700 dark:text-emerald-300'}`}>{wh.available}</span>
                          {wh.low_stock && !noStock && <span className="rounded bg-amber-100 px-1 py-px text-[7px] font-bold leading-none text-amber-700 dark:bg-amber-500/20 dark:text-amber-300">LOW</span>}
                          {noStock && <span className="text-[8px] font-medium text-slate-400 dark:text-slate-500">empty</span>}
                        </div>
                      </div>
                    </button>
                  );
                })}
              </div>
              {!form.warehouse_id && <p className="text-[10px] text-muted-foreground">Select a warehouse as the <span className="font-semibold text-blue-600 dark:text-blue-400">transfer source</span>.</p>}
            </>
          )}
        </div>
      )}

      {form.related_product_id && form.warehouse_id && availableWarehouses.length > 0 && (
        <>
          <div className="space-y-2">
            <SectionLabel><StepBadge n={3} active />Transfer Route</SectionLabel>
            <div className="flex items-center gap-2 rounded-lg border border-border bg-muted/20 px-3 py-2">
              <div className="flex items-center gap-1.5 rounded border border-blue-200 bg-blue-50/80 px-2 py-1 dark:border-blue-500/30 dark:bg-blue-500/10">
                <WarehouseIcon className="h-3 w-3 text-blue-500" />
                <span className="text-[11px] font-semibold text-blue-800 dark:text-blue-200">{sourceAvail?.warehouse_name}</span>
                <span className="text-[9px] font-medium tabular-nums text-blue-500 dark:text-blue-400">{sourceAvail?.available}</span>
              </div>
              <ArrowRight className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
              <div className="flex-1">
                <select value={form.to_warehouse_id} onChange={(e) => setForm((f) => ({ ...f, to_warehouse_id: e.target.value }))} className="wms-input h-8 py-0 text-[11px]">
                  <option value="">Destination…</option>
                  {(meta?.warehouses || []).filter((w) => w.id !== form.warehouse_id).map((w) => <option key={w.id} value={w.id}>{w.name}</option>)}
                </select>
              </div>
            </div>
          </div>

          <div className="space-y-2">
            <SectionLabel><StepBadge n={4} active />Transfer Quantity</SectionLabel>
            <div className="flex items-center gap-3">
              <div className="flex-1">
                <Input type="number" min={1} max={maxAvailable !== Infinity ? maxAvailable : undefined} value={form.quantity} onChange={(e) => setForm((f) => ({ ...f, quantity: e.target.value }))} placeholder="Qty" />
              </div>
              {maxAvailable !== Infinity && <span className="shrink-0 text-[10px] text-muted-foreground">of <span className="font-semibold tabular-nums text-emerald-600 dark:text-emerald-400">{maxAvailable}</span> available</span>}
            </div>
            {qtyExceedsStock && <p className="flex items-center gap-1 text-[11px] font-medium text-red-600 dark:text-red-400"><AlertTriangle className="h-3 w-3" /> Cannot exceed {maxAvailable} units</p>}
          </div>

          <div className="space-y-2">
            <SectionLabel><StepBadge n={5} active />Staff Assignment</SectionLabel>
            <StaffPicker {...staffPicker} />
          </div>
        </>
      )}
    </>
  );
}

/* ═══════════════════════════════════════════════════════════════
   WORKFLOW: Inventory Receive (warehouse → product → qty → staff)
   ═══════════════════════════════════════════════════════════════ */

function InboundWorkflow({ form, setForm, meta, allProducts, staffPicker, handleWarehouseChange, isReturn = false }) {
  return (
    <>
      <div className="space-y-3">
        <SectionLabel><StepBadge n={1} active />{isReturn ? 'Return Warehouse' : 'Receiving Warehouse'}</SectionLabel>
        <Field label={isReturn ? 'Warehouse' : 'Destination warehouse'} required>
          <select value={form.warehouse_id} onChange={(e) => handleWarehouseChange(e.target.value)} className="wms-input mt-1">
            <option value="">Select warehouse…</option>
            {(meta?.warehouses || []).map((w) => <option key={w.id} value={w.id}>{w.name}</option>)}
          </select>
        </Field>
        {!isReturn && (
          <Field label="Supplier" required>
            <Input value={form.supplier_name} onChange={(e) => setForm((f) => ({ ...f, supplier_name: e.target.value }))} className="mt-1" placeholder="Supplier / vendor name" />
          </Field>
        )}
        {isReturn && (
          <Field label="Return reason" required>
            <Input value={form.return_reason} onChange={(e) => setForm((f) => ({ ...f, return_reason: e.target.value }))} className="mt-1" placeholder="Why is stock being returned?" />
          </Field>
        )}
      </div>

      {form.warehouse_id && (
        <div className="space-y-3">
          <SectionLabel><StepBadge n={2} active />Product & Quantity</SectionLabel>
          <Field label={isReturn ? 'Product' : 'Product to receive'} required>
            <select value={form.related_product_id} onChange={(e) => setForm((f) => ({ ...f, related_product_id: e.target.value, quantity: '' }))} className="wms-input mt-1">
              <option value="">Select product…</option>
              {allProducts.map((p) => <option key={p.id} value={p.id}>{p.sku} — {p.name}</option>)}
            </select>
          </Field>
          {form.related_product_id && (
            <Field label={isReturn ? 'Return quantity' : 'Receive quantity'} required>
              <Input type="number" min={1} value={form.quantity} onChange={(e) => setForm((f) => ({ ...f, quantity: e.target.value }))} className="mt-1" placeholder="Units to receive" />
            </Field>
          )}
        </div>
      )}

      {form.warehouse_id && (
        <div className="space-y-3">
          <SectionLabel><StepBadge n={3} active />Staff Assignment</SectionLabel>
          <StaffPicker {...staffPicker} />
        </div>
      )}
    </>
  );
}

/* ═══════════════════════════════════════════════════════════════
   WORKFLOW: Outbound Dispatch (warehouse → product(stock-validated) → qty → staff)
   ═══════════════════════════════════════════════════════════════ */

function OutboundWorkflow({ form, setForm, meta, inventoryProducts, whProductsLoading, allProducts, stockDetail, stockLoading, maxAvailable, qtyExceedsStock, staffPicker, handleWarehouseChange }) {
  return (
    <>
      <div className="space-y-3">
        <SectionLabel><StepBadge n={1} active />Dispatch Warehouse</SectionLabel>
        <Field label="Warehouse" required>
          <select value={form.warehouse_id} onChange={(e) => handleWarehouseChange(e.target.value)} className="wms-input mt-1">
            <option value="">Select dispatch warehouse…</option>
            {(meta?.warehouses || []).map((w) => <option key={w.id} value={w.id}>{w.name}</option>)}
          </select>
        </Field>
        <Field label="Destination / customer" required>
          <Input value={form.destination_client} onChange={(e) => setForm((f) => ({ ...f, destination_client: e.target.value }))} className="mt-1" placeholder="Customer or destination name" />
        </Field>
      </div>

      {form.warehouse_id && (
        <div className="space-y-3">
          <SectionLabel><StepBadge n={2} active />Product & Stock Validation</SectionLabel>
          <Field label="Product to dispatch" required>
            {whProductsLoading ? (
              <LoadingBar text="Loading warehouse products…" />
            ) : inventoryProducts.length > 0 ? (
              <select value={form.related_product_id} onChange={(e) => setForm((f) => ({ ...f, related_product_id: e.target.value, quantity: '' }))} className="wms-input mt-1">
                <option value="">Select product…</option>
                {inventoryProducts.map((p) => <option key={p.product_id} value={p.product_id}>{p.product_sku} — {p.product_name} ({p.available} available)</option>)}
              </select>
            ) : (
              <p className="mt-1 text-xs text-amber-600 dark:text-amber-400">No inventory found at this warehouse.</p>
            )}
          </Field>

          {form.related_product_id && form.warehouse_id && (
            <StockPreview stock={stockDetail} loading={stockLoading} isOutbound />
          )}

          {form.related_product_id && (
            <Field label="Dispatch quantity" required>
              <Input type="number" min={1} max={maxAvailable !== Infinity ? maxAvailable : undefined} value={form.quantity} onChange={(e) => setForm((f) => ({ ...f, quantity: e.target.value }))} className="mt-1" placeholder="Units to dispatch" />
              {qtyExceedsStock && <p className="mt-1 flex items-center gap-1 text-xs font-semibold text-red-600 dark:text-red-400"><AlertTriangle className="h-3 w-3" /> Exceeds available stock ({maxAvailable} units)</p>}
            </Field>
          )}
        </div>
      )}

      {form.warehouse_id && (
        <div className="space-y-3">
          <SectionLabel><StepBadge n={3} active />Staff Assignment</SectionLabel>
          <StaffPicker {...staffPicker} />
        </div>
      )}
    </>
  );
}

/* ═══════════════════════════════════════════════════════════════
   WORKFLOW: Stock Adjustment (warehouse → product → adjustment → staff)
   ═══════════════════════════════════════════════════════════════ */

function AdjustmentWorkflow({ form, setForm, meta, inventoryProducts, whProductsLoading, allProducts, stockDetail, stockLoading, staffPicker, handleWarehouseChange }) {
  return (
    <>
      <div className="space-y-3">
        <SectionLabel><StepBadge n={1} active />Warehouse</SectionLabel>
        <Field label="Warehouse" required>
          <select value={form.warehouse_id} onChange={(e) => handleWarehouseChange(e.target.value)} className="wms-input mt-1">
            <option value="">Select warehouse…</option>
            {(meta?.warehouses || []).map((w) => <option key={w.id} value={w.id}>{w.name}</option>)}
          </select>
        </Field>
      </div>

      {form.warehouse_id && (
        <div className="space-y-3">
          <SectionLabel><StepBadge n={2} active />Product & Adjustment</SectionLabel>
          <Field label="Product" required>
            {whProductsLoading ? (
              <LoadingBar text="Loading products…" />
            ) : inventoryProducts.length > 0 ? (
              <select value={form.related_product_id} onChange={(e) => setForm((f) => ({ ...f, related_product_id: e.target.value, quantity: '' }))} className="wms-input mt-1">
                <option value="">Select product…</option>
                {inventoryProducts.map((p) => <option key={p.product_id} value={p.product_id}>{p.product_sku} — {p.product_name} ({p.available} available)</option>)}
              </select>
            ) : (
              <>
                <select value={form.related_product_id} onChange={(e) => setForm((f) => ({ ...f, related_product_id: e.target.value, quantity: '' }))} className="wms-input mt-1">
                  <option value="">Select product…</option>
                  {allProducts.map((p) => <option key={p.id} value={p.id}>{p.sku} — {p.name}</option>)}
                </select>
                <p className="mt-1 text-[10px] text-amber-600 dark:text-amber-400">No inventory found. Showing all products for adjustment.</p>
              </>
            )}
          </Field>

          {form.related_product_id && form.warehouse_id && (
            <StockPreview stock={stockDetail} loading={stockLoading} isOutbound={false} />
          )}

          {form.related_product_id && (
            <Field label="Adjustment quantity" required>
              <Input type="number" min={1} value={form.quantity} onChange={(e) => setForm((f) => ({ ...f, quantity: e.target.value }))} className="mt-1" placeholder="Quantity to adjust" />
            </Field>
          )}
        </div>
      )}

      {form.warehouse_id && (
        <div className="space-y-3">
          <SectionLabel><StepBadge n={3} active />Staff Assignment</SectionLabel>
          <StaffPicker {...staffPicker} />
        </div>
      )}
    </>
  );
}

/* ═══════════════════════════════════════════════════════════════
   WORKFLOW: Order Packing (order → warehouse → staff)
   ═══════════════════════════════════════════════════════════════ */

function OrderPackingWorkflow({ form, setForm, meta, staffPicker, handleWarehouseChange }) {
  return (
    <>
      <div className="space-y-3">
        <SectionLabel><StepBadge n={1} active />Related Order</SectionLabel>
        <Field label="Order to pack" required>
          <select value={form.related_order_id} onChange={(e) => setForm((f) => ({ ...f, related_order_id: e.target.value }))} className="wms-input mt-1">
            <option value="">Select order…</option>
            {(meta?.orders || []).map((o) => <option key={o.id} value={o.id}>{o.order_number} — {o.customer_name}</option>)}
          </select>
        </Field>
      </div>

      <div className="space-y-3">
        <SectionLabel><StepBadge n={2} active />Warehouse</SectionLabel>
        <Field label="Packing warehouse" required>
          <select value={form.warehouse_id} onChange={(e) => handleWarehouseChange(e.target.value)} className="wms-input mt-1">
            <option value="">Select warehouse…</option>
            {(meta?.warehouses || []).map((w) => <option key={w.id} value={w.id}>{w.name}</option>)}
          </select>
        </Field>
      </div>

      {form.warehouse_id && (
        <div className="space-y-3">
          <SectionLabel><StepBadge n={3} active />Staff Assignment</SectionLabel>
          <StaffPicker {...staffPicker} />
        </div>
      )}
    </>
  );
}

/* ═══════════════════════════════════════════════════════════════
   WORKFLOW: Inventory Count (warehouse → optional product → staff)
   ═══════════════════════════════════════════════════════════════ */

function CountWorkflow({ form, setForm, meta, allProducts, staffPicker, handleWarehouseChange }) {
  return (
    <>
      <div className="space-y-3">
        <SectionLabel><StepBadge n={1} active />Count Location</SectionLabel>
        <Field label="Warehouse to count" required>
          <select value={form.warehouse_id} onChange={(e) => handleWarehouseChange(e.target.value)} className="wms-input mt-1">
            <option value="">Select warehouse…</option>
            {(meta?.warehouses || []).map((w) => <option key={w.id} value={w.id}>{w.name}</option>)}
          </select>
        </Field>
      </div>

      {form.warehouse_id && (
        <div className="space-y-3">
          <SectionLabel><StepBadge n={2} active />Count Scope (optional)</SectionLabel>
          <Field label="Product (leave blank for full warehouse count)">
            <select value={form.related_product_id} onChange={(e) => setForm((f) => ({ ...f, related_product_id: e.target.value }))} className="wms-input mt-1">
              <option value="">Full warehouse count</option>
              {allProducts.map((p) => <option key={p.id} value={p.id}>{p.sku} — {p.name}</option>)}
            </select>
          </Field>
        </div>
      )}

      {form.warehouse_id && (
        <div className="space-y-3">
          <SectionLabel><StepBadge n={3} active />Staff Assignment</SectionLabel>
          <StaffPicker {...staffPicker} />
        </div>
      )}
    </>
  );
}

/* ═══════════════════════════════════════════════════════════════
   WORKFLOW: Inspection / Cleaning (warehouse → staff only)
   ═══════════════════════════════════════════════════════════════ */

function SimpleWarehouseWorkflow({ label, form, meta, staffPicker, handleWarehouseChange }) {
  return (
    <>
      <div className="space-y-3">
        <SectionLabel><StepBadge n={1} active />{label} Location</SectionLabel>
        <Field label="Warehouse" required>
          <select value={form.warehouse_id} onChange={(e) => handleWarehouseChange(e.target.value)} className="wms-input mt-1">
            <option value="">Select warehouse…</option>
            {(meta?.warehouses || []).map((w) => <option key={w.id} value={w.id}>{w.name}</option>)}
          </select>
        </Field>
      </div>

      {form.warehouse_id && (
        <div className="space-y-3">
          <SectionLabel><StepBadge n={2} active />Staff Assignment</SectionLabel>
          <StaffPicker {...staffPicker} />
        </div>
      )}
    </>
  );
}

/* ═══════════════════════════════════════════════════════════════
   Shared Sub-components
   ═══════════════════════════════════════════════════════════════ */

const TITLE_PLACEHOLDERS = {
  'Inventory Receive': 'e.g. Receive rice shipment at Bakaaro',
  'Stock Transfer': 'e.g. Transfer rice from Bakaaro to Madiina',
  'Outbound Dispatch': 'e.g. Dispatch 10 units from warehouse',
  'Order Packing': 'e.g. Pack order #ORD-001',
  'Inventory Count': 'e.g. Full stock count at Bakaaro',
  'Stock Adjustment': 'e.g. Adjust damaged goods at warehouse',
  'Inspection': 'e.g. Monthly inspection at Bakaaro',
  'Cleaning': 'e.g. Clean storage area B',
};

function SectionLabel({ children }) {
  return <p className="flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">{children}</p>;
}

function StepBadge({ n, active = false }) {
  return (
    <span className={`mr-1 inline-flex h-4 w-4 items-center justify-center rounded-full text-[9px] font-bold leading-none ${active ? 'bg-accent text-white' : 'bg-muted text-muted-foreground'}`}>{n}</span>
  );
}

function LoadingBar({ text }) {
  return (
    <div className="flex items-center gap-2 rounded-lg border border-border bg-muted/30 px-3 py-2.5">
      <Loader2 className="h-3.5 w-3.5 animate-spin text-muted-foreground" />
      <span className="text-xs text-muted-foreground">{text}</span>
    </div>
  );
}

function CompactWarning({ title, sub }) {
  return (
    <div className="flex items-start gap-2.5 rounded-lg border border-amber-200/80 bg-amber-50/60 px-3 py-2.5 dark:border-amber-500/20 dark:bg-amber-500/5">
      <Package className="mt-0.5 h-4 w-4 shrink-0 text-amber-500 dark:text-amber-400" />
      <div>
        <p className="text-xs font-semibold text-amber-800 dark:text-amber-200">{title}</p>
        <p className="mt-0.5 text-[10px] text-amber-600/80 dark:text-amber-400/70">{sub}</p>
      </div>
    </div>
  );
}

/**
 * Staff assignment field — a searchable combobox filtered to the warehouse(s) this task
 * touches. The server resolves eligibility (source + destination for transfers) and falls
 * back to the full active-staff pool when neither warehouse has a mapping, so the control is
 * never empty. Selecting writes `assigned_to_id` and clears the validation error at once.
 */
function StaffPicker({ warehouseId, assignees, loading, fallback, selectedId, error, onSelect }) {
  const selectedStaff = assignees.find((s) => s.id === selectedId) || null;

  return (
    <Field label="Assign to" required error={error}>
      <StaffCombobox
        staff={assignees}
        selectedId={selectedId}
        onSelect={onSelect}
        loading={loading}
        fallback={fallback}
        disabled={!warehouseId}
      />

      {selectedStaff && (
        <p className="mt-1.5 flex items-center gap-1.5 text-[11px] text-muted-foreground">
          <CheckCircle2 className="h-3.5 w-3.5 text-accent" />
          Assigned to <span className="font-semibold text-foreground">{staffLabel(selectedStaff)}</span>
          {selectedStaff.warehouse_names?.length > 0 && (
            <span className="text-[10px]">· {selectedStaff.warehouse_names.join(', ')}</span>
          )}
        </p>
      )}
    </Field>
  );
}

function StockPreview({ stock, loading, isOutbound }) {
  if (loading) return <LoadingBar text="Loading stock data…" />;
  if (!stock) return null;
  const outOfStock = stock.out_of_stock;
  const lowStock = stock.low_stock;
  return (
    <div className={`rounded-lg border px-3 py-2.5 ${outOfStock ? 'border-red-200 bg-red-50 dark:border-red-500/30 dark:bg-red-500/10' : lowStock ? 'border-amber-200 bg-amber-50 dark:border-amber-500/30 dark:bg-amber-500/10' : 'border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-800/60'}`}>
      <div className="flex items-center gap-2">
        <Package className="h-3.5 w-3.5 text-slate-500 dark:text-slate-400" />
        <span className="text-[10px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Stock at Warehouse</span>
        {outOfStock && <span className="rounded bg-red-100 px-1.5 py-px text-[9px] font-bold text-red-700 dark:bg-red-500/20 dark:text-red-300">OUT OF STOCK</span>}
        {lowStock && !outOfStock && <span className="rounded bg-amber-100 px-1.5 py-px text-[9px] font-bold text-amber-700 dark:bg-amber-500/20 dark:text-amber-300">LOW STOCK</span>}
      </div>
      <div className="mt-1.5 flex items-center gap-4 text-xs">
        <StockStat label="Available" value={stock.available} color={outOfStock ? 'text-red-700 dark:text-red-300' : 'text-emerald-700 dark:text-emerald-300'} bold />
        {stock.damaged > 0 && <StockStat label="Damaged" value={stock.damaged} color="text-orange-600 dark:text-orange-400" />}
        {stock.inspection > 0 && <StockStat label="Inspection" value={stock.inspection} color="text-amber-600 dark:text-amber-400" />}
        <StockStat label="Total" value={stock.total} color="text-slate-700 dark:text-slate-200" />
      </div>
      {isOutbound && outOfStock && <p className="mt-1.5 flex items-center gap-1 text-[11px] font-semibold text-red-600 dark:text-red-400"><AlertTriangle className="h-3 w-3" /> Cannot dispatch — no available stock</p>}
    </div>
  );
}

function StockStat({ label, value, color, bold }) {
  return (
    <div className="text-center">
      <p className={`tabular-nums ${bold ? 'text-base font-bold' : 'text-sm font-semibold'} ${color}`}>{value}</p>
      <p className="text-[9px] text-slate-500 dark:text-slate-400">{label}</p>
    </div>
  );
}

function OperationPreview({ typeMeta, productName, productSku, quantity, sourceWarehouse, destWarehouse, assignee }) {
  return (
    <div className="rounded-lg border border-violet-200 bg-violet-50/80 px-4 py-3 dark:border-violet-500/30 dark:bg-violet-500/10">
      <div className="flex items-center gap-2">
        <Info className="h-3.5 w-3.5 text-violet-500" />
        <span className="text-[10px] font-bold uppercase tracking-wider text-violet-600 dark:text-violet-300">Operation Preview</span>
      </div>
      <div className="mt-2 space-y-1.5">
        <div className="flex flex-wrap items-center gap-2 text-sm text-violet-800 dark:text-violet-200">
          <span className="rounded border border-violet-300 bg-violet-100 px-1.5 py-0.5 text-[10px] font-bold dark:border-violet-500/40 dark:bg-violet-500/20">{typeMeta.movementType}</span>
          <span className="font-bold tabular-nums">{quantity}</span>
          <span>units of</span>
          <span className="font-semibold">{productName}</span>
          <span className="text-[10px] text-violet-500">({productSku})</span>
        </div>
        {typeMeta.movementType === 'TRANSFER' && sourceWarehouse && destWarehouse ? (
          <div className="flex items-center gap-1.5 text-xs text-violet-700 dark:text-violet-300">
            <WarehouseIcon className="h-3 w-3" />
            <span className="font-semibold">{sourceWarehouse}</span>
            <ArrowRight className="h-3 w-3 text-violet-400" />
            <span className="font-semibold">{destWarehouse}</span>
          </div>
        ) : sourceWarehouse ? (
          <div className="flex items-center gap-1.5 text-xs text-violet-700 dark:text-violet-300">
            <WarehouseIcon className="h-3 w-3" /> <span className="font-semibold">{sourceWarehouse}</span>
          </div>
        ) : null}
        {assignee && <p className="text-xs text-violet-600 dark:text-violet-300">Assigned to <span className="font-semibold">{assignee}</span></p>}
      </div>
    </div>
  );
}
