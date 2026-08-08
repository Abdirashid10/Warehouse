const mongoose = require('mongoose');
const { Task, User, Warehouse, Order, Product } = require('../models');
const {
  TASK_STATUSES,
  TASK_TYPES,
  TASK_PRIORITIES,
  isOperationalTaskType,
  getTaskTypeMeta,
  normalizeLegacyTaskType,
} = require('../constants/tasks');
const { isValidStatusTransition, getAllowedActions, canConfirmTask } = require('../utils/taskPermissions');
const {
  notifyTaskAssigned,
  notifyTaskAccepted,
  notifyTaskStarted,
  notifyTaskCompleted,
  notifyTaskRejected,
  notifyTaskStatusUpdated,
  notifyTaskOverdue,
} = require('./taskNotificationService');
const { isTaskOverdue } = require('../utils/taskStats');

const USER_SELECT = 'username email role fullName avatar assignedWarehouseIds';
const TASK_POPULATE = [
  { path: 'assignedToId', select: USER_SELECT },
  { path: 'assignedById', select: USER_SELECT },
  { path: 'createdById', select: USER_SELECT },
  { path: 'warehouseId', select: 'name location' },
  { path: 'toWarehouseId', select: 'name location' },
  { path: 'relatedOrderId', select: 'order_number customer_name status' },
  { path: 'relatedProductId', select: 'sku name' },
  { path: 'statusHistory.changed_by', select: USER_SELECT },
  { path: 'notes.created_by', select: USER_SELECT },
];

async function ensureStaffAssignedToWarehouse(userId, warehouseId) {
  if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
    const err = new Error('Assigned staff is required');
    err.status = 400;
    throw err;
  }

  const user = await User.findOne({
    _id: userId,
    role: 'Staff',
    archived: { $ne: true },
    status: 'Active',
  }).lean();

  if (!user) {
    const err = new Error('Assigned user must be an active Staff member');
    err.status = 400;
    throw err;
  }

  // Fast path: the user doc already maps to this warehouse.
  const assigned = (user.assignedWarehouseIds || []).map((id) => id.toString());
  if (assigned.includes(String(warehouseId))) return user;

  // Otherwise mirror exactly what the assignee picker offered: when the warehouse has
  // no mapped staff we fall back to the full active-staff pool, so any of them is valid.
  const { staff, fallback } = await getWarehouseAssignees(warehouseId);
  if (fallback) return user;
  if (staff.some((s) => String(s._id) === String(user._id))) return user;

  const err = new Error('Staff member is not assigned to the selected warehouse');
  err.status = 400;
  throw err;
}

/** Overdue is computed at read time — notify only, never mutate workflow status. */
async function applyOverdueStatus(task) {
  if (!task || !isTaskOverdue(task)) return task;
  await notifyTaskOverdue({ task });
  return task;
}

async function syncOverdueTasks(query = {}) {
  const now = new Date();
  const overdueCandidates = await Task.find({
    ...query,
    status: { $nin: ['Completed', 'Rejected'] },
    dueDate: { $lt: now },
  }).populate(TASK_POPULATE);

  for (const task of overdueCandidates) {
    if (isTaskOverdue(task, now)) {
      await notifyTaskOverdue({ task });
    }
  }
}

function appendStatusHistory(task, status, userId, note = '', action = '') {
  task.statusHistory = task.statusHistory || [];
  task.statusHistory.push({
    status,
    changed_at: new Date(),
    changed_by: userId,
    note: String(note || '').trim(),
    action: String(action || '').trim(),
  });
  task.status = status;

  if (status === 'Completed') {
    task.completedAt = new Date();
  } else if (status === 'Accepted') {
    task.acceptedAt = new Date();
  } else if (status === 'In Progress') {
    task.startedAt = task.startedAt || new Date();
  }

  if (status !== 'Completed') {
    task.completedAt = null;
  }
}

async function listTasksForUser(user, filters = {}) {
  const query = {};

  if (user.role === 'Staff') {
    query.assignedToId = user.id;
  }

  if (filters.status && TASK_STATUSES.includes(filters.status)) {
    query.status = filters.status;
  }
  if (filters.warehouse_id && mongoose.Types.ObjectId.isValid(filters.warehouse_id)) {
    query.warehouseId = filters.warehouse_id;
  }
  if (filters.assigned_to && mongoose.Types.ObjectId.isValid(filters.assigned_to)) {
    query.assignedToId = filters.assigned_to;
  }
  if (filters.priority) {
    query.priority = filters.priority;
  }

  try {
    await syncOverdueTasks(query);
  } catch (syncErr) {
    console.error('syncOverdueTasks warning:', syncErr.message);
  }

  const rows = await Task.find(query)
    .populate(TASK_POPULATE)
    .sort({ dueDate: 1, priority: -1, createdAt: -1 })
    .lean();

  return rows;
}

async function getTaskById(id, user) {
  if (!mongoose.Types.ObjectId.isValid(id)) return null;

  const task = await Task.findById(id).populate(TASK_POPULATE);
  if (!task) return null;

  if (user.role === 'Staff' && String(task.assignedToId._id || task.assignedToId) !== String(user.id)) {
    const err = new Error('You do not have access to this task');
    err.status = 403;
    throw err;
  }

  await applyOverdueStatus(task);
  return task;
}

async function createTask(payload, actor) {
  const {
    title,
    description,
    task_type: rawTaskType,
    priority,
    assigned_to_id: assignedToId,
    warehouse_id: warehouseId,
    to_warehouse_id: toWarehouseId,
    due_date: dueDate,
    related_order_id: relatedOrderId,
    related_product_id: relatedProductId,
    quantity,
    supplier_name: supplierName,
    destination_client: destinationClient,
    return_reason: returnReason,
  } = payload;

  const taskType = normalizeLegacyTaskType(rawTaskType) || rawTaskType;

  if (!title?.trim()) {
    const err = new Error('Task title is required');
    err.status = 400;
    throw err;
  }
  if (!warehouseId || !mongoose.Types.ObjectId.isValid(warehouseId)) {
    const err = new Error('Valid warehouse is required');
    err.status = 400;
    throw err;
  }
  if (!assignedToId || !mongoose.Types.ObjectId.isValid(assignedToId)) {
    const err = new Error('Assigned staff is required');
    err.status = 400;
    throw err;
  }

  const warehouse = await Warehouse.findById(warehouseId);
  if (!warehouse) {
    const err = new Error('Warehouse not found');
    err.status = 404;
    throw err;
  }

  await ensureStaffAssignedToWarehouse(assignedToId, warehouseId);

  if (!TASK_TYPES.includes(taskType)) {
    const err = new Error('Invalid task type');
    err.status = 400;
    throw err;
  }
  if (priority && !TASK_PRIORITIES.includes(priority)) {
    const err = new Error('Invalid priority');
    err.status = 400;
    throw err;
  }

  const meta = getTaskTypeMeta(taskType);
  if (meta?.requiresQuantity && (quantity == null || Number(quantity) < 1)) {
    const err = new Error('Quantity is required for this task type');
    err.status = 400;
    throw err;
  }
  if (meta?.requiresProduct && !relatedProductId) {
    const err = new Error('Product is required for this task type');
    err.status = 400;
    throw err;
  }
  if (meta?.requiresSupplier && !String(supplierName || '').trim()) {
    const err = new Error('Supplier is required for receive tasks');
    err.status = 400;
    throw err;
  }
  if (meta?.requiresDestination && !String(destinationClient || '').trim()) {
    const err = new Error('Destination / customer is required for dispatch tasks');
    err.status = 400;
    throw err;
  }
  if (meta?.requiresReturnReason && !String(returnReason || description || '').trim()) {
    const err = new Error('Return reason is required for return tasks');
    err.status = 400;
    throw err;
  }
  if (meta?.movementType === 'TRANSFER' && (!toWarehouseId || !mongoose.Types.ObjectId.isValid(toWarehouseId))) {
    const err = new Error('Destination warehouse is required for transfer tasks');
    err.status = 400;
    throw err;
  }

  const due = new Date(dueDate);
  if (!dueDate || Number.isNaN(due.getTime())) {
    const err = new Error('Valid due date is required');
    err.status = 400;
    throw err;
  }

  if (relatedOrderId && mongoose.Types.ObjectId.isValid(relatedOrderId)) {
    const order = await Order.findById(relatedOrderId);
    if (!order) {
      const err = new Error('Related order not found');
      err.status = 400;
      throw err;
    }
  }

  if (relatedProductId && mongoose.Types.ObjectId.isValid(relatedProductId)) {
    const product = await Product.findById(relatedProductId);
    if (!product) {
      const err = new Error('Related product not found');
      err.status = 400;
      throw err;
    }
  }

  const task = await Task.create({
    title: title.trim(),
    description: description != null ? String(description).trim() : '',
    taskType,
    priority: priority || 'medium',
    status: 'Pending',
    assignedToId,
    assignedById: actor.id,
    createdById: actor.id,
    warehouseId,
    toWarehouseId: toWarehouseId || null,
    dueDate: due,
    relatedOrderId: relatedOrderId || null,
    relatedProductId: relatedProductId || null,
    quantity: quantity != null ? Number(quantity) : null,
    supplierName: String(supplierName || '').trim(),
    destinationClient: String(destinationClient || '').trim(),
    returnReason: String(returnReason || '').trim(),
    statusHistory: [
      {
        status: 'Pending',
        changed_at: new Date(),
        changed_by: actor.id,
        note: 'Task created',
        action: 'task_created',
      },
    ],
  });

  const populated = await Task.findById(task._id).populate(TASK_POPULATE);
  await notifyTaskAssigned({ task: populated, actor });
  return populated;
}

async function updateTask(id, payload, actor) {
  const task = await Task.findById(id);
  if (!task) {
    const err = new Error('Task not found');
    err.status = 404;
    throw err;
  }

  if (payload.title !== undefined) task.title = String(payload.title).trim();
  if (payload.description !== undefined) task.description = String(payload.description).trim();
  if (payload.task_type !== undefined) {
    const normalized = normalizeLegacyTaskType(payload.task_type) || payload.task_type;
    task.taskType = normalized;
  }
  if (payload.priority !== undefined) task.priority = payload.priority;
  if (payload.quantity !== undefined) task.quantity = payload.quantity != null ? Number(payload.quantity) : null;

  if (payload.warehouse_id !== undefined) {
    if (!mongoose.Types.ObjectId.isValid(payload.warehouse_id)) {
      const err = new Error('Invalid warehouse');
      err.status = 400;
      throw err;
    }
    task.warehouseId = payload.warehouse_id;
  }

  if (payload.to_warehouse_id !== undefined) {
    task.toWarehouseId = payload.to_warehouse_id || null;
  }

  let assigneeChanged = false;
  const previousAssignee = task.assignedToId?.toString();

  if (payload.assigned_to_id !== undefined) {
    await ensureStaffAssignedToWarehouse(payload.assigned_to_id, task.warehouseId);
    assigneeChanged = previousAssignee !== String(payload.assigned_to_id);
    task.assignedToId = payload.assigned_to_id;
    if (assigneeChanged) task.assignedById = actor.id;
  } else if (payload.warehouse_id !== undefined) {
    await ensureStaffAssignedToWarehouse(task.assignedToId, task.warehouseId);
  }

  if (payload.due_date !== undefined) {
    const due = new Date(payload.due_date);
    if (Number.isNaN(due.getTime())) {
      const err = new Error('Invalid due date');
      err.status = 400;
      throw err;
    }
    task.dueDate = due;
    if (task.status === 'Overdue' && due >= new Date()) {
      appendStatusHistory(task, 'Pending', actor.id, 'Due date extended', 'due_date_extended');
    }
  }

  if (payload.related_order_id !== undefined) {
    task.relatedOrderId = payload.related_order_id || null;
  }
  if (payload.related_product_id !== undefined) {
    task.relatedProductId = payload.related_product_id || null;
  }
  if (payload.supplier_name !== undefined) {
    task.supplierName = String(payload.supplier_name || '').trim();
  }
  if (payload.destination_client !== undefined) {
    task.destinationClient = String(payload.destination_client || '').trim();
  }
  if (payload.return_reason !== undefined) {
    task.returnReason = String(payload.return_reason || '').trim();
  }

  const previousStatus = task.status;
  if (payload.status !== undefined && payload.status !== task.status) {
    if (!isValidStatusTransition(task.status, payload.status) && task.status !== 'Overdue') {
      const err = new Error(`Cannot change status from ${task.status} to ${payload.status}`);
      err.status = 400;
      throw err;
    }
    appendStatusHistory(task, payload.status, actor.id, payload.status_note || 'Status updated', 'status_change');
  }

  await task.save();
  const populated = await Task.findById(task._id).populate(TASK_POPULATE);

  if (assigneeChanged) {
    await notifyTaskAssigned({ task: populated, actor });
  }
  if (payload.status !== undefined && payload.status !== previousStatus) {
    if (payload.status === 'Completed') {
      await notifyTaskCompleted({ task: populated, actor });
    } else {
      await notifyTaskStatusUpdated({
        task: populated,
        previousStatus,
        newStatus: payload.status,
        actor,
      });
    }
  }

  return populated;
}

async function executeOperationalCompletion(task, actor) {
  const meta = getTaskTypeMeta(task.taskType);
  if (!meta?.movementType) return null;

  const { recordMovement, recordTransfer } = require('../utils/movementService');
  const { afterInventoryChange } = require('./notificationService');
  const { logActivity } = require('../utils/activityLogger');
  const { emitInventoryChanged } = require('../realtime/inventoryEmitter');
  const { CONDITION_AVAILABLE } = require('../constants/inventoryConditions');
  const { INBOUND_SOURCE_LOCATION } = require('../constants/movementLocations');

  const productId = task.relatedProductId?._id || task.relatedProductId;
  const warehouseId = task.warehouseId?._id || task.warehouseId;
  const toWarehouseId = task.toWarehouseId?._id || task.toWarehouseId;
  const qty = task.executedQuantity || task.quantity;
  const fromWhName = task.warehouseId?.name || '';
  const toWhName = task.toWarehouseId?.name || '';
  const userId = actor.id;

  if (!productId || !warehouseId || !qty || qty < 1) {
    return null;
  }

  let movement;
  const baseReason = `Task: ${task.title}`;

  if (meta.movementType === 'TRANSFER') {
    if (!toWarehouseId) return null;
    const transferResult = await recordTransfer({
      productId,
      fromWarehouseId: warehouseId,
      toWarehouseId,
      userId,
      quantity: qty,
      reason: task.description?.trim() || baseReason,
      condition: CONDITION_AVAILABLE,
      source_location: fromWhName,
      destination_location: toWhName,
    });
    movement = transferResult.movement || transferResult;
  } else if (meta.movementType === 'OUTBOUND') {
    const customer = String(task.destinationClient || task.title || 'Customer').trim();
    movement = await recordMovement({
      productId,
      warehouseId,
      userId,
      type: 'OUTBOUND',
      quantity: qty,
      reason: task.description?.trim() || baseReason,
      condition: CONDITION_AVAILABLE,
      source_location: fromWhName,
      destination_location: customer,
    });
  } else if (meta.movementType === 'INBOUND') {
    const supplier = String(task.supplierName || INBOUND_SOURCE_LOCATION).trim();
    movement = await recordMovement({
      productId,
      warehouseId,
      userId,
      type: 'INBOUND',
      quantity: qty,
      reason: task.description?.trim() || `${baseReason} — Supplier: ${supplier}`,
      condition: CONDITION_AVAILABLE,
      source_location: supplier,
      destination_location: fromWhName,
    });
  } else if (meta.movementType === 'RETURN') {
    const returnNote = String(task.returnReason || task.description || baseReason).trim();
    movement = await recordMovement({
      productId,
      warehouseId,
      userId,
      type: 'RETURN',
      quantity: qty,
      reason: returnNote,
      condition: CONDITION_AVAILABLE,
      source_location: 'Customer Return',
      destination_location: fromWhName,
    });
  } else {
    movement = await recordMovement({
      productId,
      warehouseId,
      userId,
      type: meta.movementType,
      quantity: qty,
      reason: task.description?.trim() || baseReason,
      condition: CONDITION_AVAILABLE,
    });
  }

  if (movement) {
    const { Movement } = require('../models');
    await Movement.findByIdAndUpdate(movement._id, { taskId: task._id });
    task.movementId = movement._id;
    task.executedQuantity = qty;
    await task.save();

    await logActivity({
      actorId: userId,
      action: 'Completed task operation',
      module: 'Tasks',
      entityType: 'task',
      entityId: task._id.toString(),
      entityLabel: task.title,
      details: `${task.taskType}: ${task.title} (qty ${qty})`,
      warehouseIds: [warehouseId, toWarehouseId].filter(Boolean),
    });

    try {
      await afterInventoryChange({
        productId,
        warehouseId,
        fromWarehouseId: meta.movementType === 'TRANSFER' ? warehouseId : undefined,
        toWarehouseId: meta.movementType === 'TRANSFER' ? toWarehouseId : undefined,
        type: meta.movementType,
        quantity: qty,
        actorId: userId,
        movementId: movement._id,
      });
      emitInventoryChanged({
        type: meta.movementType,
        productId,
        warehouseId,
        toWarehouseId: meta.movementType === 'TRANSFER' ? toWarehouseId : undefined,
      });
    } catch (_) { /* non-critical */ }
  }

  return movement;
}

async function updateTaskStatus(id, { status, note, executed_quantity }, actor) {
  const task = await Task.findById(id);
  if (!task) {
    const err = new Error('Task not found');
    err.status = 404;
    throw err;
  }

  if (actor.role === 'Staff' && String(task.assignedToId) !== String(actor.id)) {
    const err = new Error('You can only update your assigned tasks');
    err.status = 403;
    throw err;
  }

  const allowed = getAllowedActions(task.status, actor.role);
  const current = task.status;

  if (!allowed.includes(status) && !isValidStatusTransition(current, status)) {
    const err = new Error(`Cannot change status from ${task.status} to ${status}`);
    err.status = 400;
    throw err;
  }

  if (status === 'Waiting Confirmation' && actor.role === 'Staff') {
    const meta = getTaskTypeMeta(task.taskType);
    if (meta?.requiresQuantity && executed_quantity != null) {
      task.executedQuantity = Number(executed_quantity);
    }
  }

  if (status === 'Completed' && task.status === 'Waiting Confirmation') {
    if (!canConfirmTask(actor.role)) {
      const err = new Error('Only Admin or Supervisor can confirm completion of tasks awaiting confirmation');
      err.status = 403;
      throw err;
    }
  }

  const actionLabel = status === 'Accepted' ? 'task_accepted'
    : status === 'In Progress' ? 'task_started'
    : status === 'Waiting Confirmation' ? 'task_awaiting_confirmation'
    : status === 'Completed' ? 'task_completed'
    : status === 'Rejected' ? 'task_rejected'
    : 'status_change';

  const previousStatus = task.status;
  appendStatusHistory(task, status, actor.id, note || `Status changed to ${status}`, actionLabel);

  if (status === 'Completed') {
    if (executed_quantity != null) {
      task.executedQuantity = Number(executed_quantity);
    }

    try {
      await task.populate(TASK_POPULATE);
      await executeOperationalCompletion(task, actor);
    } catch (movErr) {
      console.error('Task movement execution failed:', movErr.message);
      appendStatusHistory(task, 'In Progress', actor.id, `Movement failed: ${movErr.message}`, 'movement_failed');
      await task.save();
      const populatedErr = await Task.findById(task._id).populate(TASK_POPULATE);
      const err = new Error(`Task completion failed: ${movErr.message}`);
      err.status = 400;
      err.task = populatedErr;
      throw err;
    }
  }

  await task.save();

  const populated = await Task.findById(task._id).populate(TASK_POPULATE);
  if (status === 'Completed') {
    await notifyTaskCompleted({ task: populated, actor });
  } else if (status === 'Accepted') {
    await notifyTaskAccepted({ task: populated, actor });
  } else if (status === 'In Progress' && previousStatus !== 'In Progress') {
    await notifyTaskStarted({ task: populated, actor });
  } else if (status === 'Rejected') {
    await notifyTaskRejected({ task: populated, actor });
  } else if (status !== previousStatus) {
    await notifyTaskStatusUpdated({
      task: populated,
      previousStatus,
      newStatus: status,
      actor,
    });
  }
  return populated;
}

async function addTaskNote(id, { text }, actor) {
  const task = await Task.findById(id);
  if (!task) {
    const err = new Error('Task not found');
    err.status = 404;
    throw err;
  }

  if (actor.role === 'Staff' && String(task.assignedToId) !== String(actor.id)) {
    const err = new Error('You can only add notes to your assigned tasks');
    err.status = 403;
    throw err;
  }

  if (!text?.trim()) {
    const err = new Error('Note text is required');
    err.status = 400;
    throw err;
  }

  task.notes.push({
    text: text.trim(),
    created_by: actor.id,
    created_at: new Date(),
  });

  await task.save();
  return Task.findById(task._id).populate(TASK_POPULATE);
}

async function deleteTask(id) {
  const deleted = await Task.findByIdAndDelete(id);
  if (!deleted) {
    const err = new Error('Task not found');
    err.status = 404;
    throw err;
  }
  return deleted;
}

/**
 * Staff eligible for assignment at a warehouse.
 *
 * Mapped staff are resolved from both sides of the relation (warehouse.assignedStaffIds and
 * user.assignedWarehouseIds) so a half-synced mapping still resolves. When the warehouse has
 * no mapped active staff at all, we fall back to every active staff member instead of
 * returning an empty list — an unmapped warehouse must never block task creation.
 *
 * @returns {Promise<{ staff: object[], fallback: boolean }>} fallback=true when the full
 *   active-staff pool is returned because the warehouse has no mapping of its own.
 */
async function getWarehouseAssignees(warehouseId) {
  const empty = { staff: [], fallback: false };
  if (!mongoose.Types.ObjectId.isValid(warehouseId)) return empty;
  const warehouse = await Warehouse.findById(warehouseId).select('assignedStaffIds name').lean();
  if (!warehouse) return empty;

  const activeStaff = { role: 'Staff', archived: { $ne: true }, status: 'Active' };
  const staffIds = (warehouse.assignedStaffIds || []).filter(Boolean);

  const mapped = await User.find({
    ...activeStaff,
    $or: [
      ...(staffIds.length ? [{ _id: { $in: staffIds } }] : []),
      { assignedWarehouseIds: warehouse._id },
    ],
  })
    .select(USER_SELECT)
    .sort({ username: 1 })
    .lean();

  if (mapped.length) return { staff: mapped, fallback: false };

  const all = await User.find(activeStaff).select(USER_SELECT).sort({ username: 1 }).lean();
  return { staff: all, fallback: true };
}

module.exports = {
  TASK_POPULATE,
  listTasksForUser,
  getTaskById,
  createTask,
  updateTask,
  updateTaskStatus,
  addTaskNote,
  deleteTask,
  getWarehouseAssignees,
  syncOverdueTasks,
};
