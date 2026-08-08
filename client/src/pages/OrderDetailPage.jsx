import { Link, useParams } from 'react-router-dom';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { api } from '../api/client';

import { useAuth } from '../context/AuthContext';

import { OrderStatusBadge } from '../components/OrderStatusBadge';

import { OrderStatusTimeline } from '../components/OrderStatusTimeline';

import { canManageOperations, canAdvanceOrderStatus } from '../utils/roles';

import {

  formatOrderDateTime,

  getAllowedTransitions,

  getNextOrderStatus,

  orderStatusBadgeClass,

} from '../utils/orderHelpers';

import { ArrowLeft, ChevronRight } from 'lucide-react';



function money(value) {

  return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(Number(value || 0));

}



async function fetchOrder(id) {

  const { data } = await api.get(`/orders/${id}`);

  return data;

}



export function OrderDetailPage() {

  const { id } = useParams();

  const queryClient = useQueryClient();

  const { user } = useAuth();

  const canManage = canManageOperations(user?.role);



  const { data, isLoading, isError, error } = useQuery({

    queryKey: ['orders', id],

    queryFn: () => fetchOrder(id),

    enabled: Boolean(id),

  });



  const statusMutation = useMutation({

    mutationFn: (status) => api.put(`/orders/${id}/status`, { status }),

    onSuccess: () => {

      queryClient.invalidateQueries({ queryKey: ['orders'] });

      queryClient.invalidateQueries({ queryKey: ['orders', id] });

      queryClient.invalidateQueries({ queryKey: ['dashboard', 'stats'] });

      queryClient.invalidateQueries({ queryKey: ['inventory'] });

      queryClient.invalidateQueries({ queryKey: ['movements', 'list'] });

      queryClient.invalidateQueries({ queryKey: ['reports', 'valuation'] });

    },

  });



  const order = data?.order;

  const nextStatus = order ? getNextOrderStatus(order.status) : null;



  if (isLoading) {

    return <p className="text-muted-foreground">Loading order…</p>;

  }



  if (isError || !order) {

    return (

      <div className="space-y-4">

        <p className="text-red-600">{error?.response?.data?.message || 'Order not found'}</p>

        <Link to="/orders" className="text-accent hover:underline">

          Back to orders

        </Link>

      </div>

    );

  }



  return (

    <div className="space-y-6">

      <Link to="/orders" className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground">

        <ArrowLeft className="h-4 w-4" />

        Back to orders

      </Link>



      <div className="flex flex-col gap-4 border-b border-border pb-5 lg:flex-row lg:items-start lg:justify-between">

        <div>

          <p className="font-mono text-sm text-accent">{order.order_number}</p>

          <h1 className="mt-1 text-2xl font-semibold text-foreground">{order.customer_name}</h1>

          <p className="mt-2 text-sm text-muted-foreground">Created {formatOrderDateTime(order.createdAt)}</p>

          <p className="mt-2 text-sm text-muted-foreground">

            Priority: <span className="font-medium text-foreground">{order.priority || 'Normal'}</span>

          </p>

        </div>

        <div className="flex flex-col items-start gap-3">

          <OrderStatusBadge status={order.status} />

          {nextStatus && canAdvanceOrderStatus(user?.role, nextStatus) ? (

            <button

              type="button"

              disabled={statusMutation.isPending}

              onClick={() => statusMutation.mutate(nextStatus)}

              className={`inline-flex items-center gap-2 rounded-lg px-4 py-2.5 text-sm font-semibold ring-1 ${orderStatusBadgeClass(nextStatus)} hover:opacity-90 disabled:opacity-50`}

            >

              Advance to {nextStatus}

              <ChevronRight className="h-4 w-4" />

            </button>

          ) : null}

          {statusMutation.isError ? (

            <p className="max-w-xs text-sm text-red-600">

              {statusMutation.error?.response?.data?.message || 'Status update failed'}

            </p>

          ) : null}

          {order.status !== 'Delivered' && getAllowedTransitions(order.status).some((s) => canAdvanceOrderStatus(user?.role, s)) ? (

            <label className="block text-sm font-medium text-foreground">

              Or set status

              <select

                disabled={statusMutation.isPending}

                value=""

                onChange={(e) => {

                  if (e.target.value) statusMutation.mutate(e.target.value);

                }}

                className="wms-select mt-1 min-w-[12rem]"

              >

                <option value="">Choose status…</option>

                {getAllowedTransitions(order.status).filter((s) => canAdvanceOrderStatus(user?.role, s)).map((s) => (

                  <option key={s} value={s}>

                    {s}

                  </option>

                ))}

              </select>

            </label>

          ) : null}

        </div>

      </div>



      <div className="grid gap-6 lg:grid-cols-2">

        <div className="wms-card p-6">

          <h2 className="text-lg font-semibold text-foreground">Products</h2>

          <ul className="mt-4 divide-y divide-border">

            {order.items.map((line, i) => (

              <li key={i} className="flex justify-between gap-4 py-3 text-sm">

                <div>

                  <p className="wms-cell-name">

                    {line.product?.sku || '—'} — {line.product?.name}

                  </p>

                  <p className="wms-cell-meta">{line.warehouse?.name}</p>

                </div>

                <div className="text-right">

                  <span className="tabular-nums font-semibold text-foreground">× {line.quantity}</span>

                  <p className="wms-cell-meta">

                    {money(line.unit_price)} ea • {money(line.line_total)}

                  </p>

                </div>

              </li>

            ))}

          </ul>

          <div className="mt-4 grid gap-2 rounded-lg border border-border bg-muted/30 p-3 text-sm">

            <p className="text-muted-foreground">

              Total items: <span className="font-medium text-foreground">{order.total_items}</span>

            </p>

            <p className="text-muted-foreground">

              Total quantity: <span className="font-medium text-foreground">{order.total_quantity}</span>

            </p>

            <p className="font-semibold text-emerald-700">Grand total: {money(order.grand_total)}</p>

          </div>

          <p className="mt-3 wms-cell-meta">

            Stock is reserved when this order is created and synchronized through movement logs.

          </p>

        </div>



        <div className="wms-card p-6">

          <h2 className="text-lg font-semibold text-foreground">Status timeline</h2>

          <p className="mt-1 text-sm text-muted-foreground">Granular audit log to the minute</p>

          <div className="mt-4 space-y-1 rounded-lg border border-border bg-muted/30 p-3 text-sm">

            <p className="text-muted-foreground">

              Phone: <span className="text-foreground">{order.phone_number || '—'}</span>

            </p>

            <p className="text-muted-foreground">

              Delivery address: <span className="text-foreground">{order.delivery_address || '—'}</span>

            </p>

            <p className="text-muted-foreground">

              Expected delivery: <span className="text-foreground">{formatOrderDateTime(order.expected_delivery_date)}</span>

            </p>

            <p className="text-muted-foreground">

              Notes: <span className="text-foreground">{order.notes || '—'}</span>

            </p>

          </div>

          <div className="mt-6">

            <OrderStatusTimeline history={order.status_history} />

          </div>

        </div>

      </div>

    </div>

  );

}


