import { useMemo, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { OrderStatusBadge } from '../components/OrderStatusBadge';
import { canManageOperations, canAdvanceOrderStatus } from '../utils/roles';
import { isLowStock, isOutOfStock } from '../utils/stockStatus';
import { formatOrderDateTime, getNextOrderStatus, ORDER_STATUSES, orderMatchesSearchQuery } from '../utils/orderHelpers';
import {
  AlertTriangle,
  ArrowRight,
  Box,
  Calendar,
  CheckCircle2,
  ChevronRight,
  Clock,
  Loader2,
  MapPin,
  Package,
  Phone,
  Plus,
  Search,
  ShoppingCart,
  Trash2,
  Truck,
  User,
  X,
} from 'lucide-react';

/* ─── API ─── */

async function fetchProducts() {
  const { data } = await api.get('/products');
  return data;
}
async function fetchWarehouses() {
  const { data } = await api.get('/inventory/warehouses');
  return data;
}
async function fetchInventoryLines() {
  const { data } = await api.get('/inventory');
  return data;
}

/* ─── Helpers ─── */

function money(value) {
  return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(Number(value || 0));
}

function relDate(iso) {
  if (!iso) return '—';
  const diff = Date.now() - new Date(iso).getTime();
  const m = Math.floor(diff / 60_000);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  if (d < 7) return `${d}d ago`;
  return new Date(iso).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

const STATUS_COLORS = {
  Pending: { color: 'text-amber-600 dark:text-amber-400', bg: 'bg-amber-50 dark:bg-amber-500/10', icon: Clock },
  Processing: { color: 'text-blue-600 dark:text-blue-400', bg: 'bg-blue-50 dark:bg-blue-500/10', icon: Package },
  Packed: { color: 'text-violet-600 dark:text-violet-400', bg: 'bg-violet-50 dark:bg-violet-500/10', icon: Box },
  Shipped: { color: 'text-orange-600 dark:text-orange-400', bg: 'bg-orange-50 dark:bg-orange-500/10', icon: Truck },
  Delivered: { color: 'text-emerald-600 dark:text-emerald-400', bg: 'bg-emerald-50 dark:bg-emerald-500/10', icon: CheckCircle2 },
};

const emptyLine = { product_id: '', warehouse_id: '', quantity: 1 };

/* ═══════════════════════════════════════════════════════════════
   MAIN EXPORT
   ═══════════════════════════════════════════════════════════════ */

export function OrdersPage() {
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const { user } = useAuth();
  const canManage = canManageOperations(user?.role);

  /* ── State ── */
  const [modalOpen, setModalOpen] = useState(false);
  const [customerName, setCustomerName] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [deliveryAddress, setDeliveryAddress] = useState('');
  const [notes, setNotes] = useState('');
  const [priority, setPriority] = useState('Normal');
  const [expectedDeliveryDate, setExpectedDeliveryDate] = useState('');
  const [lines, setLines] = useState([{ ...emptyLine }]);
  const [formError, setFormError] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [searchQ, setSearchQ] = useState('');

  /* ── Queries ── */
  const { data, isLoading, isError } = useQuery({
    queryKey: ['orders', statusFilter],
    queryFn: () => api.get('/orders', { params: statusFilter ? { status: statusFilter } : {} }).then((r) => r.data),
  });

  const { data: productsData } = useQuery({ queryKey: ['products', 'for-orders'], queryFn: fetchProducts, enabled: modalOpen });
  const { data: whData } = useQuery({ queryKey: ['warehouses', 'for-orders'], queryFn: fetchWarehouses, enabled: modalOpen });
  const { data: invData } = useQuery({ queryKey: ['inventory', 'for-orders'], queryFn: fetchInventoryLines, enabled: modalOpen });
  const { data: nextRefData } = useQuery({ queryKey: ['orders', 'next-number'], queryFn: () => api.get('/orders/next-number').then((r) => r.data), enabled: modalOpen && canManage });

  const products = productsData?.products || [];
  const warehouses = whData?.warehouses || [];
  const inventoryLines = invData?.lines || [];
  const allOrders = data?.orders || [];

  /* ── Status advance mutation ── */
  const statusMutation = useMutation({
    mutationFn: ({ id, status }) => api.put(`/orders/${id}/status`, { status }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard', 'stats'] });
      queryClient.invalidateQueries({ queryKey: ['inventory'] });
      queryClient.invalidateQueries({ queryKey: ['movements', 'list'] });
    },
  });

  /* ── Derived data ── */
  const orders = useMemo(() => {
    if (!searchQ) return allOrders;
    return allOrders.filter(
      (o) =>
        orderMatchesSearchQuery(o, searchQ) ||
        (o.customer_name || '').toLowerCase().includes(searchQ.toLowerCase()) ||
        (o.delivery_address || '').toLowerCase().includes(searchQ.toLowerCase()) ||
        (o.status || '').toLowerCase().includes(searchQ.toLowerCase())
    );
  }, [allOrders, searchQ]);

  const stats = useMemo(() => {
    const s = { total: allOrders.length, Pending: 0, Processing: 0, Packed: 0, Shipped: 0, Delivered: 0 };
    allOrders.forEach((o) => { if (s[o.status] !== undefined) s[o.status]++; });
    s.fulfillment = s.Processing + s.Packed;
    return s;
  }, [allOrders]);

  /* ── Create-order helpers ── */
  const availableMap = useMemo(() => {
    const map = new Map();
    for (const line of inventoryLines) {
      if (line.condition !== 'Available / Good') continue;
      const pid = line.product?.id || line.product?._id || line.productId;
      const wid = line.warehouse?.id || line.warehouseId;
      if (!pid || !wid) continue;
      const key = `${pid}::${wid}`;
      map.set(key, (map.get(key) || 0) + Number(line.quantity || 0));
    }
    return map;
  }, [inventoryLines]);

  const productMap = useMemo(() => new Map(products.map((p) => [p.id || p._id, p])), [products]);

  const enrichedLines = useMemo(
    () => lines.map((line) => {
      const key = `${line.product_id}::${line.warehouse_id}`;
      const available = availableMap.get(key) || 0;
      const qty = Math.max(1, parseInt(String(line.quantity || 1), 10) || 1);
      const product = productMap.get(line.product_id);
      const unitPrice = Number(product?.unitPrice || 0);
      const minThreshold = Number(product?.min_stock_threshold ?? product?.minStockThreshold ?? 0);
      return { ...line, available, qty, unitPrice, lineTotal: qty * unitPrice, isLowStock: isLowStock(available, minThreshold), isOutOfStock: isOutOfStock(available) };
    }),
    [lines, availableMap, productMap]
  );

  const formSummary = useMemo(() => ({
    totalItems: enrichedLines.length,
    totalQuantity: enrichedLines.reduce((s, l) => s + (l.qty || 0), 0),
    grandTotal: enrichedLines.reduce((s, l) => s + (l.lineTotal || 0), 0),
  }), [enrichedLines]);

  const createMutation = useMutation({
    mutationFn: (body) => api.post('/orders', body),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard', 'stats'] });
      setModalOpen(false);
      resetForm();
    },
    onError: (err) => setFormError(err.response?.data?.message || 'Failed to create order'),
  });

  function resetForm() {
    setCustomerName(''); setPhoneNumber(''); setDeliveryAddress('');
    setNotes(''); setPriority('Normal'); setExpectedDeliveryDate('');
    setLines([{ ...emptyLine }]); setFormError('');
  }

  function submitCreate(e) {
    e.preventDefault();
    setFormError('');
    if (!customerName.trim()) { setFormError('Customer name is required'); return; }
    if (!deliveryAddress.trim()) { setFormError('Delivery address is required'); return; }
    const items = [];
    for (let idx = 0; idx < lines.length; idx++) {
      const line = lines[idx];
      if (!line.product_id) { setFormError(`Line ${idx + 1}: Select a product`); return; }
      if (!line.warehouse_id) { setFormError(`Line ${idx + 1}: Select a warehouse`); return; }
      const qty = parseInt(String(line.quantity), 10);
      if (!Number.isFinite(qty) || qty < 1) { setFormError(`Line ${idx + 1}: Quantity must be at least 1`); return; }
      const available = availableMap.get(`${line.product_id}::${line.warehouse_id}`) || 0;
      if (qty > available) { setFormError(`Line ${idx + 1}: Exceeds available stock (${available})`); return; }
      items.push({ product_id: line.product_id, warehouse_id: line.warehouse_id, quantity: qty });
    }
    if (!items.length) { setFormError('Add at least one line item'); return; }
    createMutation.mutate({
      customer_name: customerName.trim(), phone_number: phoneNumber.trim(),
      delivery_address: deliveryAddress.trim(), notes: notes.trim(),
      priority, expected_delivery_date: expectedDeliveryDate || null, items,
    });
  }

  /* ═══ Render ═══ */
  return (
    <div className="space-y-4 px-1">

      {/* ── Header ── */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-lg font-bold text-foreground">Order Operations</h1>
          <p className="text-xs text-muted-foreground">Warehouse fulfillment pipeline · {stats.total} total orders</p>
        </div>
        {canManage && (
          <button type="button" onClick={() => setModalOpen(true)} className="inline-flex items-center gap-1.5 rounded-lg border border-accent bg-accent px-3 py-1.5 text-xs font-semibold text-white shadow-sm transition hover:bg-accent/90 active:scale-[0.97] shrink-0">
            <Plus className="h-3.5 w-3.5" /> New Order
          </button>
        )}
      </div>

      {/* ── KPI Strip ── */}
      <div className="grid grid-cols-3 gap-2 sm:grid-cols-5">
        {ORDER_STATUSES.map((s) => {
          const cfg = STATUS_COLORS[s] || STATUS_COLORS.Pending;
          const Icon = cfg.icon;
          const active = statusFilter === s;
          return (
            <button key={s} type="button" onClick={() => setStatusFilter(active ? '' : s)} className={`rounded-lg border px-2.5 py-2 text-left transition ${active ? 'border-accent bg-accent/5 ring-1 ring-accent/20' : 'border-border bg-card hover:shadow-sm'}`}>
              <div className="flex items-center gap-1.5">
                <div className={`flex h-5 w-5 items-center justify-center rounded ${cfg.bg}`}>
                  <Icon className={`h-3 w-3 ${cfg.color}`} strokeWidth={2.2} />
                </div>
                <span className="text-[9px] font-semibold uppercase tracking-wider text-muted-foreground">{s}</span>
              </div>
              <p className={`mt-0.5 text-lg font-bold tabular-nums leading-tight ${cfg.color}`}>{stats[s] || 0}</p>
            </button>
          );
        })}
      </div>

      {/* ── Filters Bar ── */}
      <div className="flex flex-wrap items-center gap-2">
        <div className="relative flex-1 min-w-[180px] max-w-sm">
          <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
          <input type="text" value={searchQ} onChange={(e) => setSearchQ(e.target.value)} placeholder="Search ORD-2026-001, customer…" className="wms-input h-8 w-full pl-8 text-xs" />
        </div>
        <div className="flex items-center gap-1">
          <button type="button" onClick={() => setStatusFilter('')} className={`rounded-md px-2 py-1 text-[11px] font-semibold transition ${!statusFilter ? 'bg-accent text-white' : 'bg-muted/50 text-muted-foreground hover:text-foreground'}`}>All</button>
          {ORDER_STATUSES.map((s) => {
            const count = stats[s] || 0;
            if (count === 0 && statusFilter !== s) return null;
            return (
              <button key={s} type="button" onClick={() => setStatusFilter(statusFilter === s ? '' : s)} className={`rounded-md px-2 py-1 text-[11px] font-semibold transition ${statusFilter === s ? 'bg-accent text-white' : 'bg-muted/50 text-muted-foreground hover:text-foreground'}`}>{s} {count}</button>
            );
          })}
        </div>
      </div>

      {/* ── Orders Table ── */}
      {isLoading ? (
        <LoadingSkeleton />
      ) : isError ? (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-3 text-xs text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">Failed to load orders.</div>
      ) : orders.length === 0 ? (
        <div className="flex flex-col items-center gap-3 rounded-xl border border-dashed border-border bg-muted/10 py-14 text-center">
          <ShoppingCart className="h-10 w-10 text-muted-foreground/20" />
          <div>
            <p className="text-sm font-medium text-muted-foreground">{searchQ || statusFilter ? 'No orders match your filters' : 'No orders yet'}</p>
            <p className="mt-0.5 text-[11px] text-muted-foreground/70">
              {searchQ || statusFilter ? 'Try adjusting your search or filter criteria.' : 'Create your first order to begin fulfillment tracking.'}
            </p>
          </div>
          {canManage && !searchQ && !statusFilter && (
            <button type="button" onClick={() => setModalOpen(true)} className="mt-1 inline-flex items-center gap-1 rounded-md border border-accent bg-accent/5 px-3 py-1.5 text-xs font-semibold text-accent transition hover:bg-accent/10">
              <Plus className="h-3 w-3" /> Create First Order
            </button>
          )}
        </div>
      ) : (
        <div className="overflow-hidden rounded-lg border border-border">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Order</th>
                  <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Customer</th>
                  <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden sm:table-cell">Items</th>
                  <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden md:table-cell">Amount</th>
                  <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Status</th>
                  <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden md:table-cell">Priority</th>
                  <th className="px-3 py-2.5 text-[10px] font-bold uppercase tracking-wider text-muted-foreground hidden lg:table-cell">Created</th>
                  <th className="px-3 py-2.5 text-right text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40">
                {orders.map((o) => {
                  const nextStatus = getNextOrderStatus(o.status);
                  const canAdvance = nextStatus && canAdvanceOrderStatus(user?.role, nextStatus);
                  const isUpdating = statusMutation.isPending && statusMutation.variables?.id === (o.id || o._id);
                  const itemCount = o.items?.length || 0;
                  const isPriority = o.priority === 'Urgent' || o.priority === 'High Priority';

                  return (
                    <tr key={o.id || o._id} className="group cursor-pointer transition hover:bg-muted/20" onClick={() => navigate(`/orders/${o.id || o._id}`)}>
                      {/* Order number */}
                      <td className="px-3 py-2.5">
                        <span className="text-[13px] font-bold tabular-nums text-accent">{o.order_number}</span>
                      </td>

                      {/* Customer */}
                      <td className="px-3 py-2.5">
                        <p className="font-semibold text-foreground leading-tight">{o.customer_name}</p>
                        {o.delivery_address && (
                          <p className="mt-0.5 flex items-center gap-1 text-[10px] text-muted-foreground truncate max-w-[200px]">
                            <MapPin className="h-2.5 w-2.5 shrink-0" /> {o.delivery_address}
                          </p>
                        )}
                      </td>

                      {/* Items */}
                      <td className="px-3 py-2.5 hidden sm:table-cell">
                        <span className="inline-flex items-center gap-1 text-muted-foreground">
                          <Package className="h-3 w-3" />
                          <span className="font-medium text-foreground tabular-nums">{itemCount}</span>
                          <span className="text-[10px]">item{itemCount !== 1 ? 's' : ''}</span>
                        </span>
                      </td>

                      {/* Amount */}
                      <td className="px-3 py-2.5 hidden md:table-cell">
                        <span className="font-semibold tabular-nums text-foreground">{money(o.total_amount)}</span>
                      </td>

                      {/* Status */}
                      <td className="px-3 py-2.5">
                        <OrderStatusBadge status={o.status} />
                      </td>

                      {/* Priority */}
                      <td className="px-3 py-2.5 hidden md:table-cell">
                        {isPriority ? (
                          <span className="inline-flex items-center gap-0.5 rounded border border-red-200 bg-red-50 px-1.5 py-px text-[9px] font-bold text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
                            <AlertTriangle className="h-2.5 w-2.5" /> {o.priority}
                          </span>
                        ) : (
                          <span className="text-[10px] text-muted-foreground">{o.priority || 'Normal'}</span>
                        )}
                      </td>

                      {/* Created */}
                      <td className="px-3 py-2.5 hidden lg:table-cell">
                        <span className="text-[10px] text-muted-foreground tabular-nums">{relDate(o.createdAt || o.created_at)}</span>
                      </td>

                      {/* Actions */}
                      <td className="px-3 py-2.5 text-right" onClick={(e) => e.stopPropagation()}>
                        <div className="flex items-center justify-end gap-1">
                          {canAdvance && (
                            <button
                              type="button"
                              disabled={isUpdating}
                              onClick={() => statusMutation.mutate({ id: o.id || o._id, status: nextStatus })}
                              className="inline-flex items-center gap-1 rounded-md border border-blue-200 bg-blue-50 px-2 py-1 text-[11px] font-semibold text-blue-700 transition hover:bg-blue-100 disabled:opacity-50 dark:border-blue-500/30 dark:bg-blue-500/10 dark:text-blue-300 dark:hover:bg-blue-500/20"
                            >
                              {isUpdating ? <Loader2 className="h-3 w-3 animate-spin" /> : <ArrowRight className="h-3 w-3" />}
                              <span className="hidden sm:inline">{nextStatus}</span>
                            </button>
                          )}
                          <Link
                            to={`/orders/${o.id || o._id}`}
                            className="rounded-md border border-border p-1.5 text-muted-foreground opacity-0 transition group-hover:opacity-100 hover:bg-muted hover:text-foreground focus:opacity-100"
                            onClick={(e) => e.stopPropagation()}
                          >
                            <ChevronRight className="h-3 w-3" />
                          </Link>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ── Footer ── */}
      {orders.length > 0 && (
        <div className="flex flex-wrap items-center justify-between gap-2 text-[11px] text-muted-foreground">
          <p>
            {orders.length === allOrders.length
              ? `${orders.length} order${orders.length !== 1 ? 's' : ''}`
              : `${orders.length} of ${allOrders.length} orders (filtered)`}
          </p>
          <div className="flex items-center gap-3">
            {stats.fulfillment > 0 && <span className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-blue-500" /> {stats.fulfillment} in fulfillment</span>}
            {stats.Shipped > 0 && <span className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-orange-500" /> {stats.Shipped} shipped</span>}
            {stats.Delivered > 0 && <span className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-emerald-500" /> {stats.Delivered} delivered</span>}
          </div>
        </div>
      )}

      {/* ═══════════════════════════════════════════════════════════════
         CREATE ORDER MODAL
         ═══════════════════════════════════════════════════════════════ */}
      {modalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/20 p-4 backdrop-blur-[2px]">
          <div className="max-h-[92vh] w-full max-w-5xl overflow-y-auto rounded-xl border border-border bg-card shadow-2xl">
            {/* Modal header */}
            <div className="sticky top-0 z-10 flex items-center justify-between border-b border-border bg-card px-5 py-3">
              <div>
                <h2 className="text-sm font-bold text-foreground">Create New Order</h2>
                <p className="mt-0.5 text-[11px] text-muted-foreground">
                  Order ID: <span className="font-mono font-semibold text-accent">{nextRefData?.order_number || '…'}</span>
                </p>
              </div>
              <button type="button" onClick={() => { setModalOpen(false); resetForm(); }} className="rounded-md p-1 text-muted-foreground transition hover:bg-muted hover:text-foreground">
                <X className="h-4 w-4" />
              </button>
            </div>

            <form onSubmit={submitCreate} className="space-y-4 px-5 py-4">
              {/* Customer info */}
              <div className="rounded-lg border border-border bg-muted/10 p-3">
                <p className="mb-2 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Customer Information</p>
                <div className="grid gap-3 sm:grid-cols-2">
                  <label className="block text-xs">
                    <span className="flex items-center gap-1 font-medium text-foreground"><User className="h-3 w-3 text-muted-foreground" /> Customer Name <span className="text-red-500">*</span></span>
                    <input required value={customerName} onChange={(e) => setCustomerName(e.target.value)} className="wms-input mt-1 h-8 text-xs" placeholder="Enter customer name" />
                  </label>
                  <label className="block text-xs">
                    <span className="flex items-center gap-1 font-medium text-foreground"><Phone className="h-3 w-3 text-muted-foreground" /> Phone Number</span>
                    <input value={phoneNumber} onChange={(e) => setPhoneNumber(e.target.value)} className="wms-input mt-1 h-8 text-xs" placeholder="Optional" />
                  </label>
                  <label className="block text-xs sm:col-span-2">
                    <span className="flex items-center gap-1 font-medium text-foreground"><MapPin className="h-3 w-3 text-muted-foreground" /> Delivery Address <span className="text-red-500">*</span></span>
                    <input required value={deliveryAddress} onChange={(e) => setDeliveryAddress(e.target.value)} className="wms-input mt-1 h-8 text-xs" placeholder="Full delivery address" />
                  </label>
                </div>
              </div>

              {/* Order settings */}
              <div className="grid gap-3 sm:grid-cols-2">
                <label className="block text-xs">
                  <span className="font-medium text-foreground">Priority</span>
                  <select value={priority} onChange={(e) => setPriority(e.target.value)} className="wms-input mt-1 h-8 text-xs">
                    <option>Normal</option>
                    <option>Urgent</option>
                    <option>High Priority</option>
                  </select>
                </label>
                <label className="block text-xs">
                  <span className="flex items-center gap-1 font-medium text-foreground"><Calendar className="h-3 w-3 text-muted-foreground" /> Expected Delivery</span>
                  <input type="date" value={expectedDeliveryDate} onChange={(e) => setExpectedDeliveryDate(e.target.value)} className="wms-input mt-1 h-8 text-xs" />
                </label>
              </div>

              {/* Line items */}
              <div className="rounded-lg border border-border bg-muted/10 p-3">
                <div className="flex items-center justify-between">
                  <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Line Items</p>
                  <button type="button" onClick={() => setLines((l) => [...l, { ...emptyLine }])} className="inline-flex items-center gap-1 rounded-md border border-accent/40 bg-accent/5 px-2 py-0.5 text-[11px] font-semibold text-accent transition hover:bg-accent/10">
                    <Plus className="h-3 w-3" /> Add Line
                  </button>
                </div>
                <div className="mt-2 overflow-x-auto">
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="border-b border-border/60 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
                        <th className="px-2 py-1.5 text-left">Product</th>
                        <th className="px-2 py-1.5 text-left">Warehouse</th>
                        <th className="px-2 py-1.5 text-left">Stock</th>
                        <th className="px-2 py-1.5 text-left w-20">Qty</th>
                        <th className="px-2 py-1.5 text-right">Price</th>
                        <th className="px-2 py-1.5 text-right">Total</th>
                        <th className="px-2 py-1.5 w-8" />
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border/30">
                      {enrichedLines.map((line, idx) => (
                        <tr key={idx}>
                          <td className="px-2 py-1.5">
                            <select required value={line.product_id} onChange={(e) => { const next = [...lines]; next[idx] = { ...next[idx], product_id: e.target.value }; setLines(next); }} className="wms-input h-7 text-[11px] min-w-[140px]">
                              <option value="">Select product…</option>
                              {products.map((p) => <option key={p.id || p._id} value={p.id || p._id}>{p.sku} — {p.name}</option>)}
                            </select>
                          </td>
                          <td className="px-2 py-1.5">
                            <select required value={line.warehouse_id} onChange={(e) => { const next = [...lines]; next[idx] = { ...next[idx], warehouse_id: e.target.value }; setLines(next); }} className="wms-input h-7 text-[11px] min-w-[120px]">
                              <option value="">Select…</option>
                              {warehouses.map((w) => <option key={w._id} value={w._id}>{w.name}</option>)}
                            </select>
                          </td>
                          <td className="px-2 py-1.5">
                            <span className={`inline-flex items-center gap-1 rounded px-1.5 py-px text-[10px] font-semibold tabular-nums ${line.isOutOfStock ? 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-300' : line.isLowStock ? 'bg-amber-100 text-amber-700 dark:bg-amber-500/20 dark:text-amber-300' : 'bg-muted text-muted-foreground'}`}>
                              {line.isOutOfStock && <AlertTriangle className="h-2.5 w-2.5" />}
                              {line.available}
                            </span>
                          </td>
                          <td className="px-2 py-1.5">
                            <input type="number" min={1} max={line.available || undefined} required value={line.quantity} onChange={(e) => { const next = [...lines]; next[idx] = { ...next[idx], quantity: e.target.value }; setLines(next); }} className="wms-input h-7 w-16 text-[11px] tabular-nums" />
                          </td>
                          <td className="px-2 py-1.5 text-right font-medium text-muted-foreground tabular-nums">{money(line.unitPrice)}</td>
                          <td className="px-2 py-1.5 text-right font-semibold text-foreground tabular-nums">{money(line.lineTotal)}</td>
                          <td className="px-2 py-1.5 text-right">
                            <button type="button" disabled={lines.length === 1} onClick={() => setLines((prev) => prev.filter((_, i) => i !== idx))} className="rounded border border-red-200 p-1 text-red-500 transition hover:bg-red-50 disabled:opacity-30 dark:border-red-500/30 dark:hover:bg-red-500/10">
                              <Trash2 className="h-3 w-3" />
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Notes */}
              <label className="block text-xs">
                <span className="font-medium text-foreground">Order Notes</span>
                <textarea rows={2} value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="Delivery notes, special instructions…" className="wms-input mt-1 text-xs" />
              </label>

              {/* Summary */}
              <div className="flex items-center gap-4 rounded-lg border border-border bg-muted/10 px-4 py-2.5">
                <div className="text-center">
                  <p className="text-[9px] font-bold uppercase text-muted-foreground">Items</p>
                  <p className="text-sm font-bold text-foreground tabular-nums">{formSummary.totalItems}</p>
                </div>
                <div className="h-6 w-px bg-border" />
                <div className="text-center">
                  <p className="text-[9px] font-bold uppercase text-muted-foreground">Quantity</p>
                  <p className="text-sm font-bold text-foreground tabular-nums">{formSummary.totalQuantity}</p>
                </div>
                <div className="h-6 w-px bg-border" />
                <div className="text-center">
                  <p className="text-[9px] font-bold uppercase text-muted-foreground">Total</p>
                  <p className="text-sm font-bold text-emerald-700 dark:text-emerald-400 tabular-nums">{money(formSummary.grandTotal)}</p>
                </div>
                <div className="ml-auto flex items-center gap-2">
                  <button type="button" onClick={() => { setModalOpen(false); resetForm(); }} className="rounded-md border border-border px-3 py-1.5 text-[11px] font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground">Cancel</button>
                  <button type="submit" disabled={createMutation.isPending} className="inline-flex items-center gap-1 rounded-md bg-accent px-4 py-1.5 text-[11px] font-semibold text-white transition hover:bg-accent/90 disabled:opacity-50">
                    {createMutation.isPending ? <><Loader2 className="h-3 w-3 animate-spin" /> Creating…</> : 'Create Order'}
                  </button>
                </div>
              </div>

              {formError && (
                <div className="flex items-start gap-2 rounded-md border border-red-200 bg-red-50 px-3 py-2 text-[11px] font-medium text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
                  <AlertTriangle className="mt-0.5 h-3 w-3 shrink-0" /> {formError}
                </div>
              )}
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   Sub-components
   ═══════════════════════════════════════════════════════════════ */

function LoadingSkeleton() {
  return (
    <div className="space-y-2">
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} className="h-12 animate-pulse rounded-lg bg-muted/30" />
      ))}
    </div>
  );
}
