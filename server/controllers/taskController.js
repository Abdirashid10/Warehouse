const mongoose = require('mongoose');
const { Warehouse, Order, Product } = require('../models');
const { formatTask } = require('../utils/taskDto');
const { summarizeTaskStats } = require('../utils/taskStats');
const {
  canManageTasks,
  canDeleteTasks,
  canCreateTasks,
} = require('../utils/taskPermissions');
const {
  listTasksForUser,
  getTaskById,
  createTask,
  updateTask,
  updateTaskStatus,
  addTaskNote,
  deleteTask,
  getWarehouseAssignees,
} = require('../services/taskService');
const { TASK_TYPES, TASK_PRIORITIES, TASK_STATUSES, TASK_TYPE_META, TASK_STATUS_FLOW, STAFF_STATUS_ACTIONS, MANAGER_STATUS_ACTIONS, OPERATION_TASK_TYPES, TASK_TYPE_LABELS, STATUS_LABELS } = require('../constants/tasks');
const { logAudit } = require('../utils/activityLogger');
const { taskStatusActionLabel } = require('../constants/audit');

async function listTasks(req, res) {
  try {
    const rows = await listTasksForUser(req.user, req.query);
    const tasks = rows.map(formatTask);
    const stats = summarizeTaskStats(tasks);
    return res.json({
      tasks,
      stats,
      scope: req.user.role === 'Staff' ? 'my' : 'all',
    });
  } catch (err) {
    console.error('listTasks error:', err.message);
    return res.status(err.status || 500).json({ message: err.message || 'Failed to load tasks' });
  }
}

async function getTask(req, res) {
  try {
    const task = await getTaskById(req.params.id, req.user);
    if (!task) return res.status(404).json({ message: 'Task not found' });
    return res.json({ task: formatTask(task) });
  } catch (err) {
    console.error('getTask error:', err.message);
    return res.status(err.status || 500).json({ message: err.message || 'Failed to load task' });
  }
}

async function getTaskMeta(req, res) {
  try {
    const [warehouses, orders, products] = await Promise.all([
      Warehouse.find().select('name location assignedStaffIds').sort({ name: 1 }).lean(),
      Order.find().select('order_number customer_name status').sort({ createdAt: -1 }).limit(100).lean(),
      Product.find().select('sku name').sort({ name: 1 }).limit(200).lean(),
    ]);

    return res.json({
      task_types: TASK_TYPES,
      operation_task_types: OPERATION_TASK_TYPES,
      task_type_labels: TASK_TYPE_LABELS,
      status_labels: STATUS_LABELS,
      task_type_meta: TASK_TYPE_META,
      priorities: TASK_PRIORITIES,
      statuses: TASK_STATUSES,
      status_flow: TASK_STATUS_FLOW,
      staff_status_actions: STAFF_STATUS_ACTIONS,
      manager_status_actions: MANAGER_STATUS_ACTIONS,
      warehouses: warehouses.map((w) => ({
        id: w._id.toString(),
        name: w.name,
        location: w.location,
        staff_count: (w.assignedStaffIds || []).length,
      })),
      orders: orders.map((o) => ({
        id: o._id.toString(),
        order_number: o.order_number,
        customer_name: o.customer_name,
        status: o.status,
      })),
      products: products.map((p) => ({
        id: p._id.toString(),
        sku: p.sku,
        name: p.name,
      })),
    });
  } catch (err) {
    console.error('getTaskMeta error:', err.message);
    return res.status(500).json({ message: 'Failed to load task options' });
  }
}

/**
 * GET /tasks/meta/assignees?warehouse_id=…&to_warehouse_id=…
 *
 * Staff eligible for a task at the given warehouse(s). A transfer may pass its destination
 * too, so staff mapped to either end of the route are offered.
 */
async function getTaskAssignees(req, res) {
  try {
    const { warehouse_id: warehouseId, to_warehouse_id: toWarehouseId } = req.query;
    if (!warehouseId || !mongoose.Types.ObjectId.isValid(warehouseId)) {
      return res.status(400).json({ message: 'warehouse_id is required' });
    }

    const { staff, fallback, warehouses } = await getWarehouseAssignees([warehouseId, toWarehouseId]);
    const warehouseNames = new Map(warehouses.map((w) => [w._id.toString(), w.name]));

    return res.json({
      warehouse_id: warehouseId,
      to_warehouse_id: toWarehouseId && mongoose.Types.ObjectId.isValid(toWarehouseId) ? toWarehouseId : null,
      // true → none of these warehouses has mapped staff, so every active staff member is listed
      fallback,
      staff: staff.map((u) => ({
        id: u._id.toString(),
        username: u.username,
        full_name: u.fullName || '',
        email: u.email,
        role: u.role,
        avatar: u.avatar || '',
        warehouse_ids: u.matchedWarehouseIds || [],
        warehouse_names: (u.matchedWarehouseIds || []).map((id) => warehouseNames.get(id)).filter(Boolean),
      })),
    });
  } catch (err) {
    console.error('getTaskAssignees error:', err.message);
    return res.status(500).json({ message: 'Failed to load warehouse staff' });
  }
}

async function createTaskHandler(req, res) {
  try {
    if (!canCreateTasks(req.user.role)) {
      return res.status(403).json({ message: 'You cannot create tasks' });
    }

    const task = await createTask(req.body, req.user);

    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      action: 'Created',
      module: 'Tasks',
      entityType: 'task',
      entityId: task._id.toString(),
      entityLabel: task.title,
      afterValue: { status: 'Pending', assignedTo: task.assignedToId?.username || task.assignedToId },
      details: `Assigned to ${task.assignedToId?.username || task.assignedToId?.fullName || 'staff'}`,
      warehouseIds: [task.warehouseId?._id || task.warehouseId].filter(Boolean),
    });

    return res.status(201).json({ task: formatTask(task) });
  } catch (err) {
    console.error('createTask error:', err.message);
    return res.status(err.status || 500).json({ message: err.message || 'Failed to create task' });
  }
}

async function updateTaskHandler(req, res) {
  try {
    if (!canManageTasks(req.user.role)) {
      return res.status(403).json({ message: 'You cannot edit tasks' });
    }

    const task = await updateTask(req.params.id, req.body, req.user);

    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      action: 'Update',
      module: 'Tasks',
      entityType: 'task',
      entityId: task._id.toString(),
      entityLabel: task.title,
      details: task.title,
      warehouseIds: [task.warehouseId?._id || task.warehouseId].filter(Boolean),
    });

    return res.json({ task: formatTask(task) });
  } catch (err) {
    console.error('updateTask error:', err.message);
    return res.status(err.status || 500).json({ message: err.message || 'Failed to update task' });
  }
}

async function updateTaskStatusHandler(req, res) {
  try {
    const { status, note, executed_quantity } = req.body;
    if (!status) return res.status(400).json({ message: 'status is required' });

    const beforeTask = await getTaskById(req.params.id, req.user);
    const previousStatus = beforeTask?.status;

    const task = await updateTaskStatus(req.params.id, { status, note, executed_quantity }, req.user);

    // Every transition (Accepted → In Progress → Completed) lands in the audit log with the
    // acting user, both statuses, and the row's own timestamp.
    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      action: taskStatusActionLabel(status),
      module: 'Tasks',
      entityType: 'task',
      entityId: task._id.toString(),
      entityLabel: task.title,
      beforeValue: { status: previousStatus },
      afterValue: {
        status: task.status,
        changed_at: new Date().toISOString(),
        ...(task.executedQuantity != null ? { executed_quantity: task.executedQuantity } : {}),
        ...(task.movementId ? { movement_id: task.movementId.toString() } : {}),
      },
      details: `${task.title}: ${previousStatus} → ${status}${note ? ` (${note})` : ''}`,
      warehouseIds: [
        task.warehouseId?._id || task.warehouseId,
        task.toWarehouseId?._id || task.toWarehouseId,
      ].filter(Boolean),
    });

    return res.json({ task: formatTask(task) });
  } catch (err) {
    console.error('updateTaskStatus error:', err.message);
    if (err.task) {
      return res.status(err.status || 400).json({ message: err.message, task: formatTask(err.task) });
    }
    return res.status(err.status || 500).json({ message: err.message || 'Failed to update status' });
  }
}

async function addTaskNoteHandler(req, res) {
  try {
    const task = await addTaskNote(req.params.id, req.body, req.user);

    return res.status(201).json({ task: formatTask(task) });
  } catch (err) {
    console.error('addTaskNote error:', err.message);
    return res.status(err.status || 500).json({ message: err.message || 'Failed to add note' });
  }
}

async function deleteTaskHandler(req, res) {
  try {
    if (!canDeleteTasks(req.user.role)) {
      return res.status(403).json({ message: 'Only Admin can delete tasks' });
    }

    const task = await getTaskById(req.params.id, req.user);
    const warehouseIds = [task.warehouseId?._id || task.warehouseId, task.toWarehouseId?._id || task.toWarehouseId]
      .filter(Boolean);

    await deleteTask(req.params.id);

    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      action: 'Delete',
      module: 'Tasks',
      entityType: 'task',
      entityId: req.params.id,
      entityLabel: task.title,
      details: task.title || req.params.id,
      warehouseIds,
    });

    return res.json({ message: 'Task deleted' });
  } catch (err) {
    console.error('deleteTask error:', err.message);
    return res.status(err.status || 500).json({ message: err.message || 'Failed to delete task' });
  }
}

module.exports = {
  listTasks,
  getTask,
  getTaskMeta,
  getTaskAssignees,
  createTaskHandler,
  updateTaskHandler,
  updateTaskStatusHandler,
  addTaskNoteHandler,
  deleteTaskHandler,
};
