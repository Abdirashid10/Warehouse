const { CREATED_BY_SELECT } = require('./createdByDto');
const { normalizeOrderNumberForDisplay } = require('./orderNumber');

function minuteTimestamp(d = new Date()) {
  const x = new Date(d);
  x.setSeconds(0, 0);
  return x;
}

function formatHistoryEntry(entry, userMap) {
  const uid = entry.changed_by?._id?.toString() || entry.changed_by?.toString();
  const user = entry.changed_by?.username
    ? entry.changed_by
    : userMap?.get(uid);
  return {
    status: entry.status,
    changed_at: entry.changed_at,
    changed_by: user
      ? {
          id: user._id?.toString() || uid,
          name: user.username,
          role: user.role,
        }
      : { id: uid, name: 'Unknown', role: '' },
  };
}

function formatOrderItem(item) {
  const product = item.product_id;
  const warehouse = item.warehouse_id;
  return {
    product_id: product?._id?.toString() || item.product_id?.toString(),
    quantity: item.quantity,
    unit_price: item.unit_price ?? 0,
    line_total: item.line_total ?? 0,
    warehouse_id: warehouse?._id?.toString() || item.warehouse_id?.toString(),
    product: product
      ? { id: product._id.toString(), sku: product.sku, name: product.name }
      : null,
    warehouse: warehouse
      ? { id: warehouse._id.toString(), name: warehouse.name, location: warehouse.location }
      : null,
  };
}

function formatOrder(doc) {
  if (!doc) return null;
  const history = (doc.status_history || []).map((h) => formatHistoryEntry(h));
  return {
    id: doc._id.toString(),
    order_number: normalizeOrderNumberForDisplay(doc.order_number),
    customer_name: doc.customer_name,
    phone_number: doc.phone_number ?? '',
    delivery_address: doc.delivery_address ?? '',
    notes: doc.notes ?? '',
    priority: doc.priority ?? 'Normal',
    expected_delivery_date: doc.expected_delivery_date ?? null,
    status: doc.status,
    items: (doc.items || []).map(formatOrderItem),
    total_items: doc.total_items ?? (doc.items || []).length,
    total_quantity:
      doc.total_quantity ?? (doc.items || []).reduce((sum, x) => sum + (x.quantity || 0), 0),
    grand_total:
      doc.grand_total ?? (doc.items || []).reduce((sum, x) => sum + (x.line_total || 0), 0),
    status_history: history,
    shipped_at: doc.shipped_at,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  };
}

const ORDER_POPULATE = [
  {
    path: 'items.product_id',
    select: 'sku name unitPrice unitCost',
  },
  { path: 'items.warehouse_id', select: 'name location' },
  {
    path: 'status_history.changed_by',
    select: 'username role',
  },
];

module.exports = {
  formatOrder,
  formatOrderItem,
  formatHistoryEntry,
  minuteTimestamp,
  ORDER_POPULATE,
};
