import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { OrderStatusBadge } from '../components/OrderStatusBadge';
import { canAdvanceOrderStatus } from '../utils/roles';
import { getNextOrderStatus, orderMatchesSearchQuery } from '../utils/orderHelpers';
import {
  ArrowRight,
  CheckCircle2,
  Clock,
  Loader2,
  Package,
  Search,
  ShoppingCart,
  Truck,
} from 'lucide-react';

async function fetchOrders(status) {
  const params = {};
  if (status) params.status = status;
  const { data } = await api.get('/orders', { params });
  return data;
}

function money(v) {
  return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(Number(v || 0));
}

function relTime(d) {
  if (!d) return '';
  const diff = Date.now() - new Date(d).getTime();
  const m = Math.floor(diff / 60_000);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  return `${Math.floor(h / 24)}d ago`;
}

const STAFF_STATUSES = ['Processing', 'Packed', 'Shipped'];
const STATUS_ICONS = { Processing: Package, Packed: Package, Shipped: Truck, Delivered: CheckCircle2 };

/* ═══════════════════════════════════════════════════════════════
   MAIN EXPORT
   ═══════════════════════════════════════════════════════════════ */
export function StaffOrdersPage() {
  const queryClient = useQueryClient();
  const { user } = useAuth();

  const [statusFilter, setStatusFilter] = useState('');
  const [searchQ, setSearchQ] = useState('');

  const { data, isLoading, isError } = useQuery({
    queryKey: ['orders', statusFilter],
    queryFn: () => fetchOrders(statusFilter),
  });

  const statusMutation = useMutation({
    mutationFn: ({ id, status }) => api.put(`/orders/${id}/status`, { status }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard', 'widgets'] });
    },
  });

  const allOrders = data?.orders || [];

  const orders = useMemo(() => {
    if (!searchQ) return allOrders;
    const qLower = searchQ.toLowerCase();
    return allOrders.filter(
      (o) =>
        orderMatchesSearchQuery(o, searchQ) ||
        (o.customer_name || '').toLowerCase().includes(qLower) ||
        (o.status || '').toLowerCase().includes(qLower)
    );
  }, [allOrders, searchQ]);

  const stats = useMemo(() => {
    const s = { Processing: 0, Packed: 0, Shipped: 0, Delivered: 0, total: allOrders.length };
    allOrders.forEach((o) => { if (s[o.status] !== undefined) s[o.status]++; });
    s.actionable = s.Processing + s.Packed + s.Shipped;
    return s;
  }, [allOrders]);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-24 text-muted-foreground">
        <Loader2 className="mr-2 h-5 w-5 animate-spin" /> Loading orders…
      </div>
    );
  }

  return (
    <div className="space-y-4 px-1">
      {/* Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-lg font-bold text-foreground">My Orders</h1>
          <p className="text-xs text-muted-foreground">Pack, ship, and dispatch assigned orders</p>
        </div>
      </div>

      {/* KPI strip */}
      <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
        {[
          { label: 'Actionable', value: stats.actionable, color: 'text-blue-700 dark:text-blue-300', bg: 'bg-blue-50 dark:bg-blue-500/10', icon: Clock },
          { label: 'Processing', value: stats.Processing, color: 'text-blue-600 dark:text-blue-400', bg: 'bg-blue-50 dark:bg-blue-500/10', icon: Package },
          { label: 'Packed', value: stats.Packed, color: 'text-violet-600 dark:text-violet-400', bg: 'bg-violet-50 dark:bg-violet-500/10', icon: Package },
          { label: 'Shipped', value: stats.Shipped, color: 'text-orange-600 dark:text-orange-400', bg: 'bg-orange-50 dark:bg-orange-500/10', icon: Truck },
        ].map(({ label, value, color, bg, icon: Icon }) => (
          <div key={label} className="rounded-lg border border-border bg-card px-3 py-2">
            <div className="flex items-center gap-1.5">
              <div className={`flex h-5 w-5 items-center justify-center rounded ${bg}`}><Icon className={`h-3 w-3 ${color}`} /></div>
              <span className="text-[10px] font-medium text-muted-foreground">{label}</span>
            </div>
            <p className={`mt-0.5 text-lg font-bold tabular-nums leading-tight ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-2">
        <div className="relative flex-1 max-w-xs">
          <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            value={searchQ}
            onChange={(e) => setSearchQ(e.target.value)}
            placeholder="Search ORD-2026-001, customer…"
            className="wms-input h-8 w-full pl-8 text-xs"
          />
        </div>
        <div className="flex items-center gap-1">
          <button type="button" onClick={() => setStatusFilter('')} className={`rounded-md px-2.5 py-1 text-[11px] font-semibold transition ${!statusFilter ? 'bg-accent text-white' : 'bg-muted/50 text-muted-foreground hover:text-foreground'}`}>All</button>
          {STAFF_STATUSES.map((s) => (
            <button key={s} type="button" onClick={() => setStatusFilter(statusFilter === s ? '' : s)} className={`rounded-md px-2.5 py-1 text-[11px] font-semibold transition ${statusFilter === s ? 'bg-accent text-white' : 'bg-muted/50 text-muted-foreground hover:text-foreground'}`}>{s}</button>
          ))}
        </div>
      </div>

      {/* Orders list */}
      {isError ? (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-3 text-sm text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">Failed to load orders.</div>
      ) : orders.length === 0 ? (
        <div className="flex flex-col items-center gap-2 rounded-xl border border-dashed border-border bg-muted/10 py-12 text-center">
          <ShoppingCart className="h-8 w-8 text-muted-foreground/30" />
          <p className="text-sm font-medium text-muted-foreground">{searchQ || statusFilter ? 'No matching orders' : 'No orders found'}</p>
        </div>
      ) : (
        <div className="space-y-1.5">
          {orders.map((order) => {
            const nextStatus = getNextOrderStatus(order.status);
            const canAdvance = nextStatus && canAdvanceOrderStatus(user?.role, nextStatus);
            const isUpdating = statusMutation.isPending && statusMutation.variables?.id === order._id;
            const NIcon = STATUS_ICONS[nextStatus] || ArrowRight;

            return (
              <div
                key={order._id}
                className="group flex items-center gap-3 rounded-lg border border-border bg-card px-3 py-2.5 transition hover:border-border hover:shadow-sm"
              >
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-[13px] font-bold text-foreground tabular-nums">{order.order_number}</span>
                    <OrderStatusBadge status={order.status} />
                  </div>
                  <div className="mt-0.5 flex flex-wrap items-center gap-x-3 text-[11px] text-muted-foreground">
                    <span className="font-medium text-foreground">{order.customer_name}</span>
                    <span>{order.items?.length || 0} items</span>
                    <span className="font-semibold tabular-nums">{money(order.total_amount)}</span>
                    <span>{relTime(order.createdAt || order.created_at)}</span>
                  </div>
                </div>

                <div className="flex shrink-0 items-center gap-1.5" onClick={(e) => e.stopPropagation()}>
                  {canAdvance && (
                    <button
                      type="button"
                      disabled={isUpdating}
                      onClick={() => statusMutation.mutate({ id: order._id, status: nextStatus })}
                      className="inline-flex items-center gap-1 rounded-md border border-blue-200 bg-blue-50 px-2.5 py-1 text-[11px] font-semibold text-blue-700 transition hover:bg-blue-100 disabled:opacity-50 dark:border-blue-500/30 dark:bg-blue-500/10 dark:text-blue-300 dark:hover:bg-blue-500/20"
                    >
                      {isUpdating ? <Loader2 className="h-3 w-3 animate-spin" /> : <NIcon className="h-3 w-3" />}
                      {nextStatus === 'Packed' ? 'Pack' : nextStatus === 'Shipped' ? 'Ship' : nextStatus === 'Delivered' ? 'Deliver' : nextStatus}
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Footer */}
      {orders.length > 0 && (
        <p className="text-[11px] text-muted-foreground">
          Showing {orders.length} of {allOrders.length} orders
          {stats.actionable > 0 && <> · <span className="font-semibold text-blue-600 dark:text-blue-400">{stats.actionable} actionable</span></>}
        </p>
      )}
    </div>
  );
}
