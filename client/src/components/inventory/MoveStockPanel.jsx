import { useEffect, useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../../api/client';
import { useAuth } from '../../context/AuthContext';
import { ConditionSelect } from './ConditionSelect';
import {
  EMPTY_MOVEMENT_FORM,
  INBOUND_SOURCE_LOCATION,
  movementTypeBadgeClass,
} from '../../utils/movementHelpers';
import {
  isOutboundAllowed,
  normalizeCondition,
  OUTBOUND_CONDITION_DENIED,
} from '../../utils/inventoryConditions';
import {
  debugStockMovement,
  getProductId,
  getWarehouseId,
  getWarehouseName,
  normalizeEntityId,
} from '../../utils/inventoryHelpers';
import {
  formatInsufficientStockMessage,
  getAvailableForCondition,
  validateTransferQuantity,
} from '../../utils/stockValidation';

const NOTES_MIN_LENGTH = 10;
const NOTES_REQUIRED_ERROR = 'Notes / reason is required.';
const NOTES_LENGTH_ERROR = 'Enter at least 10 characters.';
const NOTES_HELPER_TEXT = 'Minimum 10 characters.';

function notesTrimmedLength(value) {
  return String(value ?? '').trim().length;
}

/** Length-only: empty → required; under 10 → too short; otherwise valid. */
function validateNotesForModal(notes) {
  const len = notesTrimmedLength(notes);
  if (len === 0) return NOTES_REQUIRED_ERROR;
  if (len < NOTES_MIN_LENGTH) return NOTES_LENGTH_ERROR;
  return null;
}

function isNotesFormError(message) {
  return message === NOTES_REQUIRED_ERROR || message === NOTES_LENGTH_ERROR;
}

async function fetchProducts() {
  const { data } = await api.get('/products');
  return data;
}

async function fetchInventory() {
  const { data } = await api.get('/inventory');
  return data;
}

async function fetchWarehouses() {
  const { data } = await api.get('/inventory/warehouses');
  return data;
}

async function fetchProductAvailability(productId) {
  const { data } = await api.get('/inventory/product-availability', {
    params: { product_id: productId },
  });
  return data;
}

function MovementToast({ message, onDismiss }) {
  useEffect(() => {
    const t = setTimeout(onDismiss, 5000);
    return () => clearTimeout(t);
  }, [onDismiss]);

  if (!message) return null;

  return (
    <div
      role="alert"
      className="fixed bottom-6 left-1/2 z-[60] max-w-md -translate-x-1/2 rounded-lg border border-red-500/40 bg-red-950 px-4 py-3 text-sm font-medium text-red-100 shadow-2xl"
    >
      {message}
    </div>
  );
}

export function MoveStockPanel({ open, onClose, initialProduct, initialType, initialWarehouseId, onSuccess }) {
  const queryClient = useQueryClient();
  const { user } = useAuth();

  if (user?.role === 'Staff') {
    return null;
  }

  const [selected, setSelected] = useState(null);
  const [form, setForm] = useState({ ...EMPTY_MOVEMENT_FORM });
  const [formError, setFormError] = useState('');
  const [toastMessage, setToastMessage] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { data, isError: inventoryError, isLoading: inventoryLoading } = useQuery({
    queryKey: ['inventory'],
    queryFn: fetchInventory,
    enabled: open,
  });

  const { data: whData, isError: warehousesError, isLoading: warehousesLoading } = useQuery({
    queryKey: ['warehouses'],
    queryFn: fetchWarehouses,
    enabled: open,
  });

  const { data: productsData } = useQuery({
    queryKey: ['products', ''],
    queryFn: fetchProducts,
    enabled: open,
  });

  const productId = getProductId(selected?.product);

  const {
    data: availabilityData,
    isError: availabilityError,
    isLoading: availabilityLoading,
  } = useQuery({
    queryKey: ['inventory', 'product-availability', productId],
    queryFn: () => fetchProductAvailability(productId),
    enabled: open && Boolean(productId),
  });

  const catalogProducts = productsData?.products || [];
  const lines = data?.lines || [];
  const warehouses = whData?.warehouses || [];

  useEffect(() => {
    if (open) {
      setForm({
        ...EMPTY_MOVEMENT_FORM,
        type: initialType || 'INBOUND',
        warehouseId: normalizeEntityId(initialWarehouseId),
        fromWarehouseId: normalizeEntityId(initialWarehouseId),
      });
      setFormError('');
      setToastMessage('');
      setIsSubmitting(false);
      setSelected(initialProduct ? { product: initialProduct } : { product: null });
    }
  }, [open, initialProduct, initialType, initialWarehouseId]);

  useEffect(() => {
    if (!open || !initialProduct) return;
    const initialId = getProductId(initialProduct);
    if (!initialId || getProductId(selected?.product) !== initialId) return;
    if (selected?.product?.sku) return;

    const full = catalogProducts.find((p) => getProductId(p) === initialId);
    if (full) {
      setSelected({ product: full });
    }
  }, [open, initialProduct, selected?.product, catalogProducts]);

  const productLines = useMemo(() => {
    if (!productId) return [];
    return lines.filter((line) => getProductId(line.product) === productId);
  }, [lines, productId]);

  const availabilityWarehouses = availabilityData?.warehouses || [];

  const warehousesWithStock = useMemo(() => {
    if (availabilityWarehouses.length > 0) {
      return availabilityWarehouses
        .filter((w) => (w.total ?? w.available ?? w.availableQuantity ?? 0) > 0)
        .map((w) => ({
          id: normalizeEntityId(w.warehouse_id ?? w.warehouseId),
          _id: normalizeEntityId(w.warehouse_id ?? w.warehouseId),
          name: w.warehouse_name ?? w.warehouseName ?? '—',
          location: w.warehouse_location ?? '',
          availableQuantity: w.available ?? w.availableQuantity ?? 0,
          totalQuantity: w.total ?? w.available ?? w.availableQuantity ?? 0,
        }));
    }

    const ids = new Set(
      productLines
        .filter((line) => (line.quantity ?? line.availableQuantity ?? 0) > 0)
        .map((line) => getWarehouseId(line.warehouse) || normalizeEntityId(line.warehouseId))
        .filter(Boolean)
    );

    return warehouses
      .filter((w) => ids.has(getWarehouseId(w)))
      .map((w) => ({
        ...w,
        id: getWarehouseId(w),
        _id: getWarehouseId(w),
        totalQuantity: productLines
          .filter((line) => getWarehouseId(line.warehouse) === getWarehouseId(w))
          .reduce((sum, line) => sum + (line.quantity ?? 0), 0),
        availableQuantity: productLines
          .filter((line) => getWarehouseId(line.warehouse) === getWarehouseId(w))
          .reduce((sum, line) => sum + (line.quantity ?? 0), 0),
      }));
  }, [availabilityWarehouses, productLines, warehouses]);

  useEffect(() => {
    if (!open || !productId) return;
    debugStockMovement('warehouse load state', {
      productId,
      inventoryLines: lines.length,
      productLines: productLines.length,
      warehouses: warehouses.length,
      warehousesWithStock: warehousesWithStock.length,
      availabilityWarehouses: availabilityWarehouses.length,
      inventoryLoading,
      warehousesLoading,
      availabilityLoading,
      inventoryError,
      warehousesError,
      availabilityError,
    });
  }, [
    open,
    productId,
    lines.length,
    productLines.length,
    warehouses.length,
    warehousesWithStock.length,
    availabilityWarehouses.length,
    inventoryLoading,
    warehousesLoading,
    availabilityLoading,
    inventoryError,
    warehousesError,
    availabilityError,
  ]);

  const totalQtyAtWarehouse = (warehouseId) => {
    const wid = normalizeEntityId(warehouseId);
    if (!wid) return 0;

    const fromAvailability = availabilityWarehouses.find(
      (w) => normalizeEntityId(w.warehouse_id ?? w.warehouseId) === wid
    );
    if (fromAvailability) {
      return fromAvailability.available ?? fromAvailability.availableQuantity ?? fromAvailability.total ?? 0;
    }

    return productLines
      .filter((l) => getWarehouseId(l.warehouse) === wid || normalizeEntityId(l.warehouseId) === wid)
      .reduce((sum, l) => sum + (l.quantity ?? l.availableQuantity ?? 0), 0);
  };

  const qtyForConditionAtWarehouse = (warehouseId, condition) => {
    const wid = normalizeEntityId(warehouseId);
    if (!wid) return 0;
    const c = normalizeCondition(condition);

    const fromAvailability = availabilityWarehouses.find(
      (w) => normalizeEntityId(w.warehouse_id ?? w.warehouseId) === wid
    );
    if (fromAvailability) {
      return getAvailableForCondition(fromAvailability, c);
    }

    const line = productLines.find(
      (l) =>
        (getWarehouseId(l.warehouse) === wid || normalizeEntityId(l.warehouseId) === wid) &&
        normalizeCondition(l.condition) === c
    );
    return line?.quantity ?? line?.availableQuantity ?? 0;
  };

  const availableAtSource = useMemo(
    () => qtyForConditionAtWarehouse(form.fromWarehouseId, form.condition),
    [availabilityWarehouses, productLines, form.fromWarehouseId, form.condition]
  );

  const currentWarehouseTotal = useMemo(
    () => totalQtyAtWarehouse(form.warehouseId),
    [productLines, form.warehouseId]
  );

  const currentConditionQty = useMemo(
    () => qtyForConditionAtWarehouse(form.warehouseId, form.condition),
    [productLines, form.warehouseId, form.condition]
  );

  const selectedWarehouseName = useMemo(() => {
    const w = warehouses.find((x) => getWarehouseId(x) === normalizeEntityId(form.warehouseId));
    return getWarehouseName(w);
  }, [warehouses, form.warehouseId]);

  const fromWarehouseName = useMemo(() => {
    const w = warehouses.find((x) => getWarehouseId(x) === normalizeEntityId(form.fromWarehouseId));
    return getWarehouseName(w);
  }, [warehouses, form.fromWarehouseId]);

  const toWarehouseName = useMemo(() => {
    const w = warehouses.find((x) => getWarehouseId(x) === normalizeEntityId(form.toWarehouseId));
    return getWarehouseName(w);
  }, [warehouses, form.toWarehouseId]);

  function invalidateMovementCaches() {
    queryClient.invalidateQueries({ queryKey: ['inventory'] });
    queryClient.invalidateQueries({ queryKey: ['inventory', 'product-availability'] });
    queryClient.invalidateQueries({ queryKey: ['inventory', 'tracking'] });
    queryClient.invalidateQueries({ queryKey: ['movements', 'list'] });
    queryClient.invalidateQueries({ queryKey: ['dashboard', 'stats'] });
    queryClient.invalidateQueries({ queryKey: ['reports', 'valuation'] });
  }

  const isStockDataLoading = inventoryLoading || warehousesLoading || availabilityLoading;

  const transferValidation = useMemo(() => {
    if (form.type !== 'TRANSFER') return { valid: true };
    return validateTransferQuantity({
      quantity: form.quantity,
      availableQuantity: availableAtSource,
      fromWarehouseId: form.fromWarehouseId,
      toWarehouseId: form.toWarehouseId,
    });
  }, [form.type, form.quantity, availableAtSource, form.fromWarehouseId, form.toWarehouseId]);

  function showStockDenied(availableQuantity = availableAtSource) {
    const message = formatInsufficientStockMessage(availableQuantity);
    setFormError(message);
    setToastMessage(message);
  }

  const movementMutation = useMutation({
    mutationFn: (body) => api.post('/inventory/movements', body),
    onSuccess: () => {
      invalidateMovementCaches();
      setForm({ ...EMPTY_MOVEMENT_FORM });
      setFormError('');
      setToastMessage('');
      onSuccess?.();
    },
    onError: (err) => {
      const msg = err.response?.data?.message || err.message || 'Movement failed';
      setFormError(msg);
      if (msg.startsWith('Insufficient stock')) {
        setToastMessage(msg);
      }
    },
  });

  function handleNotesChange(notes) {
    setForm((f) => ({ ...f, reason: notes }));
    if (notesTrimmedLength(notes) >= NOTES_MIN_LENGTH) {
      setFormError((prev) => (isNotesFormError(prev) ? '' : prev));
    }
  }

  function runMovement(payload) {
    if (isSubmitting || movementMutation.isPending) return;
    setIsSubmitting(true);
    movementMutation.mutate(payload, {
      onSettled: () => setIsSubmitting(false),
    });
  }

  function submitMovement(e) {
    e.preventDefault();
    if (isSubmitting || movementMutation.isPending) return;
    setFormError('');
    setToastMessage('');

    const pid = getProductId(selected?.product);
    if (!pid) {
      setFormError('Select a product');
      return;
    }

    if (!form.condition) {
      setFormError('Item condition is required');
      return;
    }

    const notesError = validateNotesForModal(form.reason);
    if (notesError) {
      setFormError(notesError);
      return;
    }

    const qty = parseInt(String(form.quantity), 10);
    if (!Number.isFinite(qty) || qty < 1) {
      setFormError('Quantity must be a positive integer');
      return;
    }

    if (form.type === 'OUTBOUND' && !isOutboundAllowed(form.condition)) {
      setFormError(OUTBOUND_CONDITION_DENIED);
      return;
    }

    if (form.type === 'TRANSFER') {
      if (isStockDataLoading) {
        setFormError('Loading stock availability…');
        return;
      }

      const validation = validateTransferQuantity({
        quantity: qty,
        availableQuantity: availableAtSource,
        fromWarehouseId: form.fromWarehouseId,
        toWarehouseId: form.toWarehouseId,
      });

      if (!validation.valid) {
        setFormError(validation.error);
        if (validation.error?.startsWith('Insufficient stock')) {
          setToastMessage(validation.error);
        }
        return;
      }

      runMovement({
        type: 'TRANSFER',
        productId: pid,
        fromWarehouseId: form.fromWarehouseId,
        toWarehouseId: form.toWarehouseId,
        quantity: qty,
        reason: form.reason.trim(),
        condition: form.condition,
        source_location: fromWarehouseName,
        destination_location: toWarehouseName,
      });
      return;
    }

    if (!form.warehouseId) {
      setFormError(
        form.type === 'INBOUND' || form.type === 'RETURN'
          ? 'Select destination warehouse'
          : 'Select source warehouse'
      );
      return;
    }

    if (form.type === 'OUTBOUND') {
      const customer = form.customerName.trim();
      if (!customer) {
        setFormError('Customer name is required for outbound shipments');
        return;
      }
      const sourceTotal = qtyForConditionAtWarehouse(form.warehouseId, form.condition);
      if (qty > sourceTotal) {
        showStockDenied(sourceTotal);
        return;
      }
      const lineQty = qtyForConditionAtWarehouse(form.warehouseId, form.condition);
      if (qty > lineQty) {
        showStockDenied(lineQty);
        return;
      }

      runMovement({
        type: 'OUTBOUND',
        productId: pid,
        warehouseId: form.warehouseId,
        quantity: qty,
        condition: form.condition,
        reason: form.reason.trim(),
        customerName: customer,
        source_location: selectedWarehouseName,
        destination_location: customer,
      });
      return;
    }

    const body = {
      type: form.type,
      productId: pid,
      warehouseId: form.warehouseId,
      quantity: qty,
      condition: form.condition,
      reason: form.reason.trim(),
      binLocation: form.type === 'INBOUND' || form.type === 'RETURN' ? form.binLocation : '',
      source_location: INBOUND_SOURCE_LOCATION,
      destination_location: selectedWarehouseName,
    };
    if (isInboundLike) {
      if (form.batchNumber) body.batchNumber = form.batchNumber.trim();
      if (form.manufactureDate) body.manufactureDate = form.manufactureDate;
      if (form.expiryDate) body.expiryDate = form.expiryDate;
    }
    runMovement(body);
  }

  if (!open) return null;

  const movementTypes = [
    { id: 'INBOUND', label: 'Inbound (+)' },
    { id: 'OUTBOUND', label: 'Outbound (−)' },
    { id: 'TRANSFER', label: 'Transfer' },
    { id: 'RETURN', label: 'Return' },
  ];

  const isInboundLike = form.type === 'INBOUND' || form.type === 'RETURN';
  const submitDisabled =
    isSubmitting ||
    movementMutation.isPending ||
    !selected?.product ||
    isStockDataLoading ||
    (form.type === 'TRANSFER' && !transferValidation.valid);

  return (
    <>
      <MovementToast message={toastMessage} onDismiss={() => setToastMessage('')} />
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/15 p-4 backdrop-blur-sm dark:bg-slate-900/40">
        <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl border border-slate-200 bg-white p-6 shadow-xl dark:border-slate-700/70 dark:bg-slate-900">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">Move stock</h2>
          {selected?.product ? (
            <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
              {selected.product.sku} — {selected.product.name}
              {availabilityLoading ? ' · Loading stock…' : ''}
            </p>
          ) : null}

          <form onSubmit={submitMovement} noValidate className="mt-6 space-y-4">
            {!selected?.product ? (
              <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200">
                Product <span className="text-sky-600 dark:text-sky-400">*</span>
                <select
                  value={productId || ''}
                  onChange={(e) => {
                    const p = catalogProducts.find((x) => getProductId(x) === e.target.value);
                    if (p) {
                      setSelected({ product: p });
                      setForm((f) => ({
                        ...f,
                        warehouseId: '',
                        fromWarehouseId: '',
                        toWarehouseId: '',
                      }));
                    }
                  }}
                  className="wms-input mt-1"
                >
                  <option value="">Select product…</option>
                  {catalogProducts.map((p) => (
                    <option key={getProductId(p)} value={getProductId(p)}>
                      {p.sku} — {p.name}
                    </option>
                  ))}
                </select>
              </label>
            ) : null}

            <div className="flex flex-wrap gap-2">
              {movementTypes.map((t) => (
                <label
                  key={t.id}
                  className={`flex cursor-pointer items-center gap-2 rounded-lg border px-3 py-2 text-sm font-medium transition ${
                    form.type === t.id
                      ? movementTypeBadgeClass(t.id)
                      : 'border-slate-200 text-slate-500 hover:border-slate-300 hover:text-slate-700 dark:border-slate-700 dark:text-slate-400 dark:hover:border-slate-600 dark:hover:text-slate-300'
                  }`}
                >
                  <input
                    type="radio"
                    className="sr-only"
                    checked={form.type === t.id}
                    onChange={() => {
                      setForm((f) => ({ ...f, type: t.id }));
                      setFormError('');
                    }}
                  />
                  {t.label}
                </label>
              ))}
            </div>

            {selected?.product && form.type === 'TRANSFER' ? (
              <div className="space-y-4 rounded-lg border border-sky-200 bg-sky-50/60 p-4 dark:border-sky-500/25 dark:bg-sky-500/5">
                <p className="text-xs font-semibold uppercase tracking-wider text-sky-700 dark:text-sky-300">
                  Inter-warehouse transfer
                </p>
                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200">
                  From warehouse <span className="text-sky-600 dark:text-sky-400">*</span>
                  <select
                    value={form.fromWarehouseId}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, fromWarehouseId: e.target.value }))
                    }
                    className="wms-input mt-1"
                  >
                    <option value="">Select source…</option>
                    {warehousesWithStock.map((w) => {
                      const wid = getWarehouseId(w);
                      return (
                        <option key={wid} value={wid}>
                          {w.name} ({qtyForConditionAtWarehouse(wid, form.condition)} available)
                        </option>
                      );
                    })}
                  </select>
                  {productId && warehousesWithStock.length === 0 && !availabilityLoading ? (
                    <span className="mt-1 block text-xs text-amber-600 dark:text-amber-400">
                      No warehouse stock found for this product.
                    </span>
                  ) : null}
                </label>
                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200">
                  To warehouse <span className="text-sky-600 dark:text-sky-400">*</span>
                  <select
                    value={form.toWarehouseId}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, toWarehouseId: e.target.value }))
                    }
                    className="wms-input mt-1"
                  >
                    <option value="">Select destination…</option>
                    {warehouses
                      .filter((w) => getWarehouseId(w) !== normalizeEntityId(form.fromWarehouseId))
                      .map((w) => {
                        const wid = getWarehouseId(w);
                        return (
                          <option key={wid} value={wid}>
                            {w.name}
                          </option>
                        );
                      })}
                  </select>
                </label>
                <ConditionSelect
                  movementType="TRANSFER"
                  value={form.condition}
                  onChange={(c) => setForm((f) => ({ ...f, condition: c }))}
                />
                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200">
                  Quantity <span className="text-sky-600 dark:text-sky-400">*</span>
                  <input
                    type="number"
                    min={1}
                    step={1}
                    value={form.quantity}
                    onChange={(e) => setForm((f) => ({ ...f, quantity: e.target.value }))}
                    className="wms-input mt-1"
                  />
                  {form.fromWarehouseId ? (
                    <span className="mt-1 block text-xs font-normal text-slate-500 dark:text-slate-400">
                      Available at source:{' '}
                      <strong className="font-semibold text-slate-900 dark:text-slate-100">
                        {isStockDataLoading ? '…' : availableAtSource}
                      </strong>
                    </span>
                  ) : null}
                  {!isStockDataLoading && form.fromWarehouseId && !transferValidation.valid && form.quantity ? (
                    <span className="mt-1 block text-xs font-semibold text-red-600 dark:text-red-400">
                      {transferValidation.error}
                    </span>
                  ) : null}
                </label>
                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200">
                  Notes / reason <span className="text-sky-600 dark:text-sky-400">*</span>
                  <textarea
                    rows={3}
                    value={form.reason}
                    onChange={(e) => handleNotesChange(e.target.value)}
                    placeholder="Enter notes or reason for this movement..."
                    className="wms-input mt-1"
                  />
                <span className="mt-1 block text-xs font-normal text-slate-400 dark:text-slate-500">{NOTES_HELPER_TEXT}</span>
              </label>
            </div>
          ) : null}

          {selected?.product && form.type !== 'TRANSFER' ? (
              <div className="space-y-4 rounded-lg border border-slate-200 bg-slate-50/70 p-4 dark:border-slate-700/60 dark:bg-slate-800/40">
                {isInboundLike ? (
                  <div className="flex items-start gap-3 rounded-lg border border-emerald-300 bg-emerald-50 px-3.5 py-3 dark:border-emerald-500/30 dark:bg-emerald-500/10">
                    <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-md bg-emerald-100 dark:bg-emerald-500/20">
                      <svg className="h-3.5 w-3.5 text-emerald-600 dark:text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}><path strokeLinecap="round" strokeLinejoin="round" d="M19.5 13.5 12 21m0 0-7.5-7.5M12 21V3" /></svg>
                    </div>
                    <div className="min-w-0">
                      <span className="text-[10px] font-bold uppercase tracking-widest text-emerald-700 dark:text-emerald-400">
                        Source
                      </span>
                      <p className="mt-0.5 text-sm font-semibold text-emerald-900 dark:text-emerald-100">{INBOUND_SOURCE_LOCATION}</p>
                    </div>
                  </div>
                ) : null}

                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200">
                  {isInboundLike ? 'Destination warehouse' : 'Source warehouse'}{' '}
                  <span className="text-sky-600 dark:text-sky-400">*</span>
                  <select
                    value={form.warehouseId}
                    onChange={(e) => setForm((f) => ({ ...f, warehouseId: e.target.value }))}
                    className="wms-input mt-1"
                  >
                    <option value="">Select warehouse…</option>
                    {(isInboundLike ? warehouses : warehousesWithStock).map((w) => {
                      const wid = getWarehouseId(w);
                      return (
                        <option key={wid} value={wid}>
                          {w.name}
                          {!isInboundLike ? ` (${totalQtyAtWarehouse(wid)} on hand)` : ''}
                        </option>
                      );
                    })}
                  </select>
                  {form.warehouseId && !isInboundLike ? (
                    <span className="mt-1 block text-xs font-normal text-slate-500 dark:text-slate-400">
                      Current qty at source:{' '}
                      <strong className="font-semibold text-slate-900 dark:text-slate-100">{currentWarehouseTotal}</strong>
                    </span>
                  ) : null}
                  {productId && !isInboundLike && warehousesWithStock.length === 0 && !availabilityLoading ? (
                    <span className="mt-1 block text-xs text-amber-600 dark:text-amber-400">
                      No warehouse stock found for this product.
                    </span>
                  ) : null}
                </label>

                {form.type === 'OUTBOUND' ? (
                  <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200">
                    Customer Name <span className="text-sky-600 dark:text-sky-400">*</span>
                    <input
                      type="text"
                      value={form.customerName}
                      onChange={(e) =>
                        setForm((f) => ({ ...f, customerName: e.target.value }))
                      }
                      placeholder="e.g. Hassan, Ali"
                      className="wms-input mt-1"
                    />
                    <span className="mt-1 block text-xs font-normal text-slate-500 dark:text-slate-400">
                      Saved as destination for this outbound shipment.
                    </span>
                  </label>
                ) : null}

                <ConditionSelect
                  movementType={form.type}
                  value={form.condition}
                  onChange={(c) => setForm((f) => ({ ...f, condition: c }))}
                />
                {form.warehouseId && form.condition && form.type === 'OUTBOUND' ? (
                  <p className="text-xs text-slate-500 dark:text-slate-400">
                    Qty for this condition:{' '}
                    <strong className="font-semibold text-slate-900 dark:text-slate-100">{currentConditionQty}</strong>
                  </p>
                ) : null}

                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200">
                  Quantity <span className="text-sky-600 dark:text-sky-400">*</span>
                  <input
                    type="number"
                    min={1}
                    step={1}
                    value={form.quantity}
                    onChange={(e) => setForm((f) => ({ ...f, quantity: e.target.value }))}
                    className="wms-input mt-1"
                  />
                </label>

                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200">
                  Notes / reason <span className="text-sky-600 dark:text-sky-400">*</span>
                  <textarea
                    rows={3}
                    value={form.reason}
                    onChange={(e) => handleNotesChange(e.target.value)}
                    placeholder="Enter notes or reason for this movement..."
                    className="wms-input mt-1"
                  />
                  <span className="mt-1 block text-xs font-normal text-slate-400 dark:text-slate-500">{NOTES_HELPER_TEXT}</span>
                </label>

                {isInboundLike ? (
                  <>
                    <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200">
                      Bin location <span className="font-normal text-slate-400 dark:text-slate-500">(optional)</span>
                      <input
                        value={form.binLocation}
                        onChange={(e) => setForm((f) => ({ ...f, binLocation: e.target.value }))}
                        placeholder="e.g. A-01"
                        className="wms-input mt-1"
                      />
                    </label>

                    <div className="space-y-3 rounded-lg border border-dashed border-slate-300 bg-slate-50/50 p-3 dark:border-slate-600/50 dark:bg-slate-800/30">
                      <p className="text-xs font-semibold uppercase tracking-wider text-slate-600 dark:text-slate-400">
                        Expiry tracking <span className="font-normal text-slate-400 dark:text-slate-500">(optional)</span>
                      </p>
                      <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200">
                        Batch number
                        <input
                          value={form.batchNumber || ''}
                          onChange={(e) => setForm((f) => ({ ...f, batchNumber: e.target.value }))}
                          placeholder="e.g. B-2026-001"
                          className="wms-input mt-1"
                        />
                      </label>
                      <div className="grid grid-cols-2 gap-3">
                        <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200">
                          Manufacture date
                          <input
                            type="date"
                            value={form.manufactureDate || ''}
                            onChange={(e) => setForm((f) => ({ ...f, manufactureDate: e.target.value }))}
                            className="wms-input mt-1"
                          />
                        </label>
                        <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200">
                          Expiry date
                          <input
                            type="date"
                            value={form.expiryDate || ''}
                            onChange={(e) => setForm((f) => ({ ...f, expiryDate: e.target.value }))}
                            className="wms-input mt-1"
                          />
                        </label>
                      </div>
                    </div>
                  </>
                ) : null}
              </div>
            ) : null}

            {formError ? (
              <p className="rounded-lg border border-red-300 bg-red-50 px-3 py-2 text-sm font-medium text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-400">
                {formError}
              </p>
            ) : null}

            <div className="flex justify-end gap-3 border-t border-slate-200 pt-4 dark:border-slate-700/60">
              <button
                type="button"
                onClick={onClose}
                className="rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50 hover:text-slate-900 dark:border-slate-700 dark:bg-transparent dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-slate-200"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={submitDisabled}
                className="rounded-lg bg-sky-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-sky-700 disabled:opacity-50 dark:bg-sky-600 dark:hover:bg-sky-500"
              >
                {movementMutation.isPending || isSubmitting ? 'Saving…' : isStockDataLoading ? 'Checking stock…' : 'Submit'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </>
  );
}
