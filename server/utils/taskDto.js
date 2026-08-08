const { getTaskTypeMeta, getTaskTypeLabel, getStatusLabel } = require('../constants/tasks');
const { isTaskOverdue, workflowBucket } = require('./taskStats');

function formatUserRef(user) {
  if (!user || typeof user !== 'object') return null;
  return {
    id: user._id?.toString(),
    username: user.username,
    full_name: user.fullName || '',
    email: user.email,
    role: user.role,
    avatar: user.avatar || '',
  };
}

function formatWarehouseRef(wh) {
  if (!wh || typeof wh !== 'object') return null;
  return {
    id: wh._id?.toString(),
    name: wh.name,
    location: wh.location,
  };
}

function formatOrderRef(order) {
  if (!order || typeof order !== 'object') return null;
  return {
    id: order._id?.toString(),
    order_number: order.order_number,
    customer_name: order.customer_name,
    status: order.status,
  };
}

function formatProductRef(product) {
  if (!product || typeof product !== 'object') return null;
  return {
    id: product._id?.toString(),
    sku: product.sku,
    name: product.name,
  };
}

function findAuditActor(history, statuses, action) {
  const entries = (history || []).filter(
    (h) =>
      (Array.isArray(statuses) ? statuses.includes(h.status) : h.status === statuses) ||
      (action && h.action === action)
  );
  const entry = entries.length ? entries[entries.length - 1] : null;
  return entry
    ? {
        user: formatUserRef(entry.changed_by),
        at: entry.changed_at,
        note: entry.note || '',
      }
    : null;
}

function buildAuditTrail(row) {
  const history = row.statusHistory || [];
  return {
    created_by: formatUserRef(row.createdById),
    created_at: row.createdAt,
    assigned_by: formatUserRef(row.assignedById),
    accepted: findAuditActor(history, 'Accepted', 'task_accepted'),
    started: findAuditActor(history, 'In Progress', 'task_started'),
    completed: findAuditActor(history, 'Completed', 'task_completed'),
    rejected: findAuditActor(history, 'Rejected', 'task_rejected'),
  };
}

function formatTask(doc) {
  if (!doc) return null;
  const row = doc.toObject ? doc.toObject() : doc;
  const meta = getTaskTypeMeta(row.taskType);

  return {
    id: row._id?.toString(),
    title: row.title,
    description: row.description || '',
    task_type: row.taskType,
    task_type_label: getTaskTypeLabel(row.taskType),
    task_type_meta: meta
      ? {
          movement_type: meta.movementType,
          requires_stock: meta.requiresStock,
          requires_quantity: meta.requiresQuantity,
          requires_product: meta.requiresProduct,
          operational: meta.operational,
        }
      : null,
    priority: row.priority,
    status: row.status,
    workflow_status: workflowBucket(row),
    is_overdue: isTaskOverdue(row),
    status_label: getStatusLabel(workflowBucket(row)),
    due_date: row.dueDate,
    completed_at: row.completedAt || null,
    accepted_at: row.acceptedAt || null,
    started_at: row.startedAt || null,
    created_at: row.createdAt,
    updated_at: row.updatedAt,
    quantity: row.quantity,
    executed_quantity: row.executedQuantity,
    movement_id: row.movementId?.toString() || null,
    supplier_name: row.supplierName || '',
    destination_client: row.destinationClient || '',
    return_reason: row.returnReason || '',
    assigned_to: formatUserRef(row.assignedToId),
    assigned_by: formatUserRef(row.assignedById),
    created_by: formatUserRef(row.createdById),
    warehouse: formatWarehouseRef(row.warehouseId),
    to_warehouse: formatWarehouseRef(row.toWarehouseId),
    related_order: formatOrderRef(row.relatedOrderId),
    related_product: formatProductRef(row.relatedProductId),
    audit_trail: buildAuditTrail(row),
    status_history: (row.statusHistory || []).map((h) => ({
      id: h._id?.toString(),
      status: h.status,
      status_label: getStatusLabel(h.status),
      changed_at: h.changed_at,
      note: h.note || '',
      action: h.action || '',
      changed_by: formatUserRef(h.changed_by),
    })),
    notes: (row.notes || []).map((n) => ({
      id: n._id?.toString(),
      text: n.text,
      created_at: n.created_at,
      created_by: formatUserRef(n.created_by),
    })),
  };
}

module.exports = {
  formatTask,
  formatUserRef,
  formatWarehouseRef,
  buildAuditTrail,
};
