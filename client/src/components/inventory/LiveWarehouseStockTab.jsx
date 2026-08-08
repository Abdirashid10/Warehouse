import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../../api/client';
import { useAuth } from '../../context/AuthContext';
import { Search, ArrowRightLeft, Sparkles, Plus } from 'lucide-react';
import { ConditionBadge } from '../ConditionBadge';
import { ConditionSelect } from './ConditionSelect';
import {
  EMPTY_MOVEMENT_FORM,
  formatOutboundReason,
  formatTransferReason,
  movementTypeBadgeClass,
} from '../../utils/movementHelpers';
import { productCategoryName } from '../../utils/productHelpers';
import {
  CONDITION_AVAILABLE,
  isOutboundAllowed,
  normalizeCondition,
  OUTBOUND_CONDITION_DENIED,
} from '../../utils/inventoryConditions';
import {
  formatInsufficientStockMessage,
  validateTransferQuantity,
} from '../../utils/stockValidation';

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

export function LiveWarehouseStockTab() {
  const queryClient = useQueryClient();
  const { user } = useAuth();
  const canManage = user?.role === 'Admin' || user?.role === 'Supervisor';

  const [q, setQ] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [selected, setSelected] = useState(null);
  const [form, setForm] = useState({ ...EMPTY_MOVEMENT_FORM });
  const [formError, setFormError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { data, isLoading, isError, error, refetch } = useQuery({
    queryKey: ['inventory'],
    queryFn: fetchInventory,
  });

  const { data: whData } = useQuery({
    queryKey: ['warehouses'],
    queryFn: fetchWarehouses,
  });

  const { data: productsData } = useQuery({
    queryKey: ['products', ''],
    queryFn: fetchProducts,
  });

  const catalogProducts = productsData?.products || [];
  const lines = data?.lines || [];
  const items = data?.items || [];
  const warehouses = whData?.warehouses || [];

  const productId = selected?.product?.id || selected?.product?._id;

  const productLines = useMemo(() => {
    if (!productId) return [];
    return lines.filter((line) => {
      const pid = line.product?.id || line.product?._id;
      return pid === productId;
    });
  }, [lines, productId]);

  const warehousesWithStock = useMemo(() => {
    const ids = new Set(
      productLines
        .filter(
          (line) =>
            line.quantity > 0 &&
            normalizeCondition(line.condition) === CONDITION_AVAILABLE
        )
        .map((line) => line.warehouse?.id || line.warehouse?._id)
        .filter(Boolean)
    );
    return warehouses.filter((w) => ids.has(w._id));
  }, [productLines, warehouses]);

  const availableAtSource = useMemo(() => {
    if (!form.fromWarehouseId) return 0;
    const line = productLines.find(
      (l) =>
        (l.warehouse?.id || l.warehouse?._id) === form.fromWarehouseId &&
        normalizeCondition(l.condition) === normalizeCondition(form.condition)
    );
    return line?.quantity ?? 0;
  }, [productLines, form.fromWarehouseId, form.condition]);

  const transferValidation = useMemo(() => {
    if (form.type !== 'TRANSFER') return { valid: true };
    return validateTransferQuantity({
      quantity: form.quantity,
      availableQuantity: availableAtSource,
      fromWarehouseId: form.fromWarehouseId,
      toWarehouseId: form.toWarehouseId,
    });
  }, [form.type, form.quantity, availableAtSource, form.fromWarehouseId, form.toWarehouseId]);

  const availableAtWarehouse = useMemo(() => {
    if (!form.warehouseId || form.type !== 'OUTBOUND') return 0;
    const line = productLines.find(
      (l) =>
        (l.warehouse?.id || l.warehouse?._id) === form.warehouseId &&
        normalizeCondition(l.condition) === CONDITION_AVAILABLE
    );
    return line?.quantity ?? 0;
  }, [productLines, form.warehouseId, form.type]);

  const filtered = useMemo(() => {
    const s = q.trim().toLowerCase();
    if (!s) return lines;
    return lines.filter((line) => {
      const p = line.product || {};
      const w = line.warehouse || {};
      const hay = [
        p.sku,
        p.name,
        productCategoryName(p),
        w.name,
        line.bin_location,
        line.condition,
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();
      return hay.includes(s);
    });
  }, [lines, q]);

  function invalidateMovementCaches() {
    queryClient.invalidateQueries({ queryKey: ['inventory'] });
    queryClient.invalidateQueries({ queryKey: ['movements', 'list'] });
    queryClient.invalidateQueries({ queryKey: ['dashboard', 'stats'] });
    queryClient.invalidateQueries({ queryKey: ['reports', 'valuation'] });
  }

  const seedMutation = useMutation({
    mutationFn: () => api.post('/inventory/seed-sample'),
    onSuccess: invalidateMovementCaches,
  });

  const movementMutation = useMutation({
    mutationFn: (body) => api.post('/inventory/movements', body),
    onSuccess: () => {
      invalidateMovementCaches();
      setModalOpen(false);
      setSelected(null);
      setForm({ ...EMPTY_MOVEMENT_FORM });
      setFormError('');
    },
    onError: (err) => {
      const msg = err.response?.data?.message || err.message || 'Movement failed';
      setFormError(msg);
    },
  });

  function openModalFromLine(line) {
    setSelected({
      product: line.product,
      totalQuantity: line.quantity,
    });
    const whId = line.warehouse?.id || line.warehouse?._id || '';
    const lineCondition = normalizeCondition(line.condition);
    setForm({
      ...EMPTY_MOVEMENT_FORM,
      warehouseId: whId || warehouses[0]?._id || '',
      fromWarehouseId: whId,
      toWarehouseId: '',
      binLocation: line.bin_location || '',
      condition: lineCondition,
      type: 'INBOUND',
    });
    setFormError('');
    setModalOpen(true);
  }

  function openGlobalMoveStock() {
    setSelected({ product: null });
    setForm({ ...EMPTY_MOVEMENT_FORM, type: 'INBOUND' });
    setFormError('');
    setModalOpen(true);
  }

  function setMovementType(type) {
    setForm((f) => ({ ...f, type }));
  }

  function openModalFromItem(row) {
    setSelected(row);
    setForm({
      ...EMPTY_MOVEMENT_FORM,
      warehouseId: warehouses[0]?._id || '',
    });
    setFormError('');
    setModalOpen(true);
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
    const pid = selected?.product?.id || selected?.product?._id;
    if (!pid) {
      setFormError('Select a product');
      return;
    }

    if (!form.condition) {
      setFormError('Condition is required');
      return;
    }

    if (form.type === 'OUTBOUND' && !isOutboundAllowed(form.condition)) {
      setFormError(OUTBOUND_CONDITION_DENIED);
      return;
    }
    const qty = parseInt(String(form.quantity), 10);
    if (!Number.isFinite(qty) || qty < 1) {
      setFormError('Quantity must be a positive integer');
      return;
    }

    if (form.type === 'TRANSFER') {
      if (!form.fromWarehouseId) {
        setFormError('Select a source warehouse');
        return;
      }
      if (!form.toWarehouseId) {
        setFormError('Select a destination warehouse');
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
      });
      return;
    }

    if (!form.warehouseId) {
      setFormError('Select a warehouse');
      return;
    }

    const ref = form.referenceNumber.trim();
    const dest = form.destinationClient.trim();

    if (form.type === 'OUTBOUND') {
      if (!ref) {
        setFormError('Reference number is required for outbound shipments');
        return;
      }
      if (!dest) {
        setFormError('Destination / client is required for outbound shipments');
        return;
      }
      if (qty > availableAtWarehouse) {
        setFormError(
          availableAtWarehouse === 0
            ? 'No Available / Good stock at this warehouse'
            : `Only ${availableAtWarehouse} Available / Good unit(s) on hand`
        );
        return;
      }
    }

    const payload = {
      type: form.type,
      productId: pid,
      warehouseId: form.warehouseId,
      quantity: qty,
      condition: form.condition,
      binLocation: form.type === 'INBOUND' ? form.binLocation : undefined,
    };

    if (form.type === 'OUTBOUND') {
      payload.referenceNumber = ref;
      payload.destinationClient = dest;
      payload.reason = formatOutboundReason(ref, dest);
    } else {
      payload.reason = form.reason.trim();
    }

    runMovement(payload);
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="text-sm text-slate-400">
            Physical stock by warehouse, bin, and quality condition. Use inbound movements to
            receive new quantity.
          </p>
          {data?.counts ? (
            <p className="mt-2 text-xs text-slate-500">
              {data.counts.lines} stock line(s) · {data.counts.products} product(s)
            </p>
          ) : null}
        </div>
        <div className="flex flex-wrap gap-2">
          {canManage ? (
            <button
              type="button"
              onClick={openGlobalMoveStock}
              className="inline-flex items-center gap-2 rounded-lg bg-sky-600 px-4 py-2 text-sm font-semibold text-white hover:bg-sky-500"
            >
              <Plus className="h-4 w-4" />
              Move stock
            </button>
          ) : null}
          {canManage && lines.length === 0 ? (
            <button
              type="button"
              disabled={seedMutation.isPending}
              onClick={() => seedMutation.mutate()}
              className="inline-flex items-center gap-2 rounded-lg border border-sky-600/50 bg-sky-950/40 px-4 py-2 text-sm font-medium text-sky-300 hover:bg-sky-900/40 disabled:opacity-50"
            >
              <Sparkles className="h-4 w-4" />
              {seedMutation.isPending ? 'Creating sample…' : 'Create sample stock'}
            </button>
          ) : null}
        </div>
      </div>

      <div className="relative max-w-md">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-500" />
        <input
          type="search"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search SKU, warehouse, bin…"
          className="w-full rounded-lg border border-slate-700 bg-slate-900 py-2.5 pl-10 pr-3 text-sm text-white outline-none focus:ring-2 focus:ring-sky-500/50"
        />
      </div>

      {seedMutation.isError ? (
        <p className="text-sm text-red-400">
          {seedMutation.error?.response?.data?.message || 'Could not create sample data.'}
        </p>
      ) : null}

      {isLoading ? (
        <div className="text-slate-400">Loading inventory…</div>
      ) : isError ? (
        <div className="text-red-400">
          {error?.response?.data?.message || 'Failed to load inventory.'}
          <button type="button" onClick={() => refetch()} className="ml-2 underline">
            Retry
          </button>
        </div>
      ) : (
        <div className="overflow-hidden rounded-xl border border-slate-800 bg-slate-900/40 shadow-xl ring-1 ring-white/5">
          <div className="overflow-x-auto">
            <table className="min-w-full text-left text-sm">
              <thead>
                <tr className="border-b border-slate-800 bg-slate-950/90 text-[11px] font-semibold uppercase tracking-wider text-slate-500">
                  <th className="px-4 py-3.5">SKU</th>
                  <th className="px-4 py-3.5">Product</th>
                  <th className="px-4 py-3.5">Warehouse</th>
                  <th className="px-4 py-3.5">Category</th>
                  <th className="px-4 py-3.5 text-right">Qty</th>
                  <th className="px-4 py-3.5">Bin</th>
                  <th className="px-4 py-3.5">Condition</th>
                  <th className="px-4 py-3.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/90">
                {filtered.map((line) => {
                  const p = line.product || {};
                  const threshold = p.minStockThreshold ?? p.min_stock_threshold ?? 0;
                  const qty = Number(line.quantity) || 0;
                  const alert = qty <= 0 || (qty > 0 && qty <= (Number(threshold) || 0));
                  return (
                    <tr key={line.id} className="hover:bg-slate-800/30">
                      <td className="px-4 py-3 font-mono text-sky-300/90">{p.sku}</td>
                      <td className="px-4 py-3 font-medium text-slate-100">{p.name}</td>
                      <td className="px-4 py-3 text-slate-400">
                        {line.warehouse?.name || '—'}
                      </td>
                      <td className="px-4 py-3 text-slate-500">{productCategoryName(p)}</td>
                      <td
                        className={`px-4 py-3 text-right font-medium tabular-nums ${
                          alert ? 'text-red-400' : 'text-slate-200'
                        }`}
                      >
                        {line.quantity}
                      </td>
                      <td className="px-4 py-3 font-mono text-xs text-slate-500">
                        {line.bin_location || '—'}
                      </td>
                      <td className="px-4 py-3">
                        <ConditionBadge condition={line.condition} />
                      </td>
                      <td className="px-4 py-3 text-right">
                        <button
                          type="button"
                          onClick={() => openModalFromLine(line)}
                          className="inline-flex items-center gap-1 rounded-md border border-slate-600 bg-slate-800/50 px-2 py-1 text-xs font-medium text-slate-200 hover:border-sky-500/40"
                        >
                          <ArrowRightLeft className="h-3.5 w-3.5" />
                          Move stock
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          {filtered.length === 0 ? (
            <div className="px-6 py-12 text-center text-sm text-slate-500">
              <p>No inventory records yet.</p>
              {canManage ? (
                <p className="mt-2">
                  Add products and warehouses, then click{' '}
                  <strong className="text-slate-300">Create sample stock</strong> or record an
                  inbound movement using Move stock.
                </p>
              ) : null}
            </div>
          ) : null}
        </div>
      )}

      {items.length > 0 ? (
        <div className="rounded-xl border border-slate-800/60 bg-slate-900/20 p-4">
          <h2 className="text-sm font-semibold text-slate-300">Quick movement by product</h2>
          <div className="mt-3 flex flex-wrap gap-2">
            {items.map((row) => (
              <button
                key={row.product?.id || row.product?._id}
                type="button"
                onClick={() => openModalFromItem(row)}
                className="rounded-lg border border-slate-700 bg-slate-800/50 px-3 py-1.5 text-xs text-slate-200 hover:border-sky-500/40"
              >
                {row.product?.sku} · qty {row.totalQuantity}
              </button>
            ))}
          </div>
        </div>
      ) : null}

      {modalOpen ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-xl border border-slate-700 bg-slate-900 p-6 shadow-2xl">
            <h2 className="text-lg font-semibold text-white">Move stock</h2>
            {selected?.product ? (
              <p className="mt-1 text-sm text-slate-400">
                {selected.product.sku} — {selected.product.name}
              </p>
            ) : null}
            <form onSubmit={submitMovement} className="mt-6 space-y-4">
              {!selected?.product ? (
                <label className="block text-sm text-slate-300">
                  Product <span className="text-sky-400">*</span>
                  <select
                    required
                    value={productId || ''}
                    onChange={(e) => {
                      const p = catalogProducts.find((x) => x.id === e.target.value);
                      if (p) setSelected({ product: p });
                    }}
                    className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white"
                  >
                    <option value="">Select product…</option>
                    {catalogProducts.map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.sku} — {p.name}
                      </option>
                    ))}
                  </select>
                </label>
              ) : null}
              <div className="flex flex-wrap gap-3">
                <label
                  className={`flex cursor-pointer items-center gap-2 rounded-lg border px-3 py-2 text-sm font-medium transition ${
                    form.type === 'INBOUND'
                      ? movementTypeBadgeClass('INBOUND')
                      : 'border-slate-700 text-slate-400 hover:border-slate-600'
                  }`}
                >
                  <input
                    type="radio"
                    className="sr-only"
                    checked={form.type === 'INBOUND'}
                    onChange={() => setMovementType('INBOUND')}
                  />
                  Inbound (+)
                </label>
                <label
                  className={`flex cursor-pointer items-center gap-2 rounded-lg border px-3 py-2 text-sm font-medium transition ${
                    form.type === 'OUTBOUND'
                      ? movementTypeBadgeClass('OUTBOUND')
                      : 'border-slate-700 text-slate-400 hover:border-slate-600'
                  }`}
                >
                  <input
                    type="radio"
                    className="sr-only"
                    checked={form.type === 'OUTBOUND'}
                    onChange={() => setMovementType('OUTBOUND')}
                  />
                  Outbound (−)
                </label>
                <label
                  className={`flex cursor-pointer items-center gap-2 rounded-lg border px-3 py-2 text-sm font-medium transition ${
                    form.type === 'TRANSFER'
                      ? movementTypeBadgeClass('TRANSFER')
                      : 'border-slate-700 text-slate-400 hover:border-slate-600'
                  }`}
                >
                  <input
                    type="radio"
                    className="sr-only"
                    checked={form.type === 'TRANSFER'}
                    onChange={() => setMovementType('TRANSFER')}
                  />
                  Transfer
                </label>
              </div>

              {form.type === 'TRANSFER' ? (
                <div className="space-y-4 rounded-lg border border-sky-500/25 bg-sky-500/5 p-4">
                  <p className="text-xs font-semibold uppercase tracking-wider text-sky-300/90">
                    Inter-warehouse transfer
                  </p>
                  <label className="block text-sm text-slate-300">
                    Product
                    <input
                      readOnly
                      value={selected.product?.name || ''}
                      className="mt-1 w-full cursor-not-allowed rounded-lg border border-slate-700 bg-slate-950/80 px-3 py-2 text-slate-300"
                    />
                  </label>
                  <label className="block text-sm text-slate-300">
                    From warehouse (source) <span className="text-sky-400">*</span>
                    <select
                      required
                      value={form.fromWarehouseId}
                      onChange={(e) =>
                        setForm((f) => ({ ...f, fromWarehouseId: e.target.value }))
                      }
                      className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white"
                    >
                      <option value="">Select source…</option>
                      {warehousesWithStock.map((w) => {
                        const line = productLines.find(
                          (l) =>
                            (l.warehouse?.id || l.warehouse?._id) === w._id &&
                            normalizeCondition(l.condition) === normalizeCondition(form.condition)
                        );
                        return (
                          <option key={w._id} value={w._id}>
                            {w.name} ({line?.quantity ?? 0} available)
                          </option>
                        );
                      })}
                    </select>
                  </label>
                  <label className="block text-sm text-slate-300">
                    To warehouse (destination) <span className="text-sky-400">*</span>
                    <select
                      required
                      value={form.toWarehouseId}
                      onChange={(e) =>
                        setForm((f) => ({ ...f, toWarehouseId: e.target.value }))
                      }
                      className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white"
                    >
                      <option value="">Select destination…</option>
                      {warehouses
                        .filter((w) => w._id !== form.fromWarehouseId)
                        .map((w) => (
                          <option key={w._id} value={w._id}>
                            {w.name}
                          </option>
                        ))}
                    </select>
                  </label>
                  <ConditionSelect
                    movementType="TRANSFER"
                    value={form.condition}
                    onChange={(c) => setForm((f) => ({ ...f, condition: c }))}
                  />
                  <label className="block text-sm text-slate-300">
                    Quantity <span className="text-sky-400">*</span>
                    <input
                      type="number"
                      min={1}
                      max={availableAtSource > 0 ? availableAtSource : undefined}
                      required
                      value={form.quantity}
                      onChange={(e) => setForm((f) => ({ ...f, quantity: e.target.value }))}
                      className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white"
                    />
                    {form.fromWarehouseId ? (
                      <span className="mt-1 block text-xs text-slate-500">
                        Available at source:{' '}
                        <strong className="text-slate-300">{availableAtSource}</strong>
                      </span>
                    ) : null}
                    {form.fromWarehouseId && !transferValidation.valid && form.quantity ? (
                      <span className="mt-1 block text-xs font-semibold text-red-400">
                        {transferValidation.error}
                      </span>
                    ) : null}
                  </label>
                  <label className="block text-sm text-slate-300">
                    Reference / reason <span className="text-slate-500">(optional)</span>
                    <input
                      value={form.reason}
                      onChange={(e) => setForm((f) => ({ ...f, reason: e.target.value }))}
                      placeholder="Internal relocation between branches"
                      className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white placeholder:text-slate-600"
                    />
                  </label>
                  {form.fromWarehouseId && form.toWarehouseId && selected?.product?.name ? (
                    <p className="text-xs text-slate-500">
                      Logged as:{' '}
                      <span className="font-mono text-slate-400">
                        {formatTransferReason(
                          parseInt(String(form.quantity), 10) || 0,
                          selected?.product?.name,
                          warehouses.find((w) => w._id === form.fromWarehouseId)?.name || '…',
                          warehouses.find((w) => w._id === form.toWarehouseId)?.name || '…',
                          form.reason
                        )}
                      </span>
                    </p>
                  ) : null}
                </div>
              ) : selected?.product ? (
                <>
              <ConditionSelect
                movementType={form.type}
                value={form.condition}
                onChange={(c) => setForm((f) => ({ ...f, condition: c }))}
              />
              <label className="block text-sm text-slate-300">
                Warehouse
                <select
                  required
                  value={form.warehouseId}
                  onChange={(e) => setForm((f) => ({ ...f, warehouseId: e.target.value }))}
                  className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white"
                >
                  <option value="">Select…</option>
                  {warehouses.map((w) => (
                    <option key={w._id} value={w._id}>
                      {w.name}
                    </option>
                  ))}
                </select>
              </label>
              <label className="block text-sm text-slate-300">
                Quantity
                <input
                  type="number"
                  min={1}
                  required
                  value={form.quantity}
                  onChange={(e) => setForm((f) => ({ ...f, quantity: e.target.value }))}
                  className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white"
                />
                {form.type === 'OUTBOUND' && form.warehouseId ? (
                  <span className="mt-1 block text-xs text-slate-500">
                    Available / Good on hand:{' '}
                    <strong className="text-slate-300">{availableAtWarehouse}</strong>
                  </span>
                ) : null}
              </label>
              {form.type === 'INBOUND' ? (
                <>
                  <label className="block text-sm text-slate-300">
                    Bin location
                    <input
                      value={form.binLocation}
                      onChange={(e) => setForm((f) => ({ ...f, binLocation: e.target.value }))}
                      className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white"
                    />
                  </label>
                  <label className="block text-sm text-slate-300">
                    Reason <span className="text-slate-500">(optional)</span>
                    <input
                      value={form.reason}
                      onChange={(e) => setForm((f) => ({ ...f, reason: e.target.value }))}
                      placeholder="e.g. PO receipt, return from customer"
                      className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white placeholder:text-slate-600"
                    />
                  </label>
                </>
              ) : form.type === 'OUTBOUND' ? (
                <div className="space-y-4 rounded-lg border border-red-500/25 bg-red-500/5 p-4">
                  <p className="text-xs font-semibold uppercase tracking-wider text-red-300/90">
                    Shipment details
                  </p>
                  <label className="block text-sm text-slate-300">
                    Reference number <span className="text-red-400">*</span>
                    <input
                      required
                      value={form.referenceNumber}
                      onChange={(e) =>
                        setForm((f) => ({ ...f, referenceNumber: e.target.value }))
                      }
                      placeholder='Invoice or Order # (e.g., SO-1024)'
                      className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white placeholder:text-slate-600"
                    />
                  </label>
                  <label className="block text-sm text-slate-300">
                    Destination / client <span className="text-red-400">*</span>
                    <input
                      required
                      value={form.destinationClient}
                      onChange={(e) =>
                        setForm((f) => ({ ...f, destinationClient: e.target.value }))
                      }
                      placeholder="Customer Name or Store Location"
                      className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-white placeholder:text-slate-600"
                    />
                  </label>
                  <p className="text-xs text-slate-500">
                    Saved as:{' '}
                    <span className="font-mono text-slate-400">
                      {form.referenceNumber.trim() && form.destinationClient.trim()
                        ? formatOutboundReason(
                            form.referenceNumber,
                            form.destinationClient
                          )
                        : '[OUTBOUND] Order #… - Shipped to …'}
                    </span>
                  </p>
                </div>
              ) : null}
                </>
              ) : null}
              {formError ? <p className="text-sm text-red-400">{formError}</p> : null}
              <div className="flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setModalOpen(false)}
                  className="text-slate-400"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={
                    isSubmitting ||
                    movementMutation.isPending ||
                    (form.type === 'TRANSFER' && !transferValidation.valid)
                  }
                  className="rounded-lg bg-sky-600 px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
                >
                  {movementMutation.isPending || isSubmitting ? 'Saving…' : 'Submit'}
                </button>
              </div>
            </form>
          </div>
        </div>
      ) : null}
    </div>
  );
}
