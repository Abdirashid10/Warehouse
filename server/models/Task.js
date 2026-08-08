const mongoose = require('mongoose');
const { TASK_TYPES, TASK_STATUSES, TASK_PRIORITIES } = require('../constants/tasks');

const taskStatusHistorySchema = new mongoose.Schema(
  {
    status: {
      type: String,
      enum: TASK_STATUSES,
      required: true,
    },
    changed_at: {
      type: Date,
      required: true,
      default: Date.now,
    },
    changed_by: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    note: {
      type: String,
      trim: true,
      maxlength: 500,
      default: '',
    },
    action: {
      type: String,
      trim: true,
      maxlength: 100,
      default: '',
    },
  },
  { _id: true }
);

const taskNoteSchema = new mongoose.Schema(
  {
    text: { type: String, trim: true, maxlength: 2000, required: true },
    created_by: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    created_at: { type: Date, default: Date.now },
  },
  { _id: true }
);

const taskSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
    },
    description: {
      type: String,
      trim: true,
      maxlength: 4000,
      default: '',
    },
    taskType: {
      type: String,
      enum: TASK_TYPES,
      required: true,
      index: true,
    },
    priority: {
      type: String,
      enum: TASK_PRIORITIES,
      default: 'medium',
      index: true,
    },
    status: {
      type: String,
      enum: TASK_STATUSES,
      default: 'Pending',
      index: true,
    },
    assignedToId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    assignedById: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    createdById: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    warehouseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Warehouse',
      required: true,
      index: true,
    },
    toWarehouseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Warehouse',
      default: null,
    },
    dueDate: {
      type: Date,
      required: true,
      index: true,
    },
    relatedOrderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order',
      default: null,
    },
    relatedProductId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      default: null,
    },
    quantity: {
      type: Number,
      default: null,
      min: 0,
    },
    executedQuantity: {
      type: Number,
      default: null,
      min: 0,
    },
    movementId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Movement',
      default: null,
    },
    /** Receive Task — supplier name */
    supplierName: {
      type: String,
      trim: true,
      maxlength: 200,
      default: '',
    },
    /** Dispatch Task — customer / destination */
    destinationClient: {
      type: String,
      trim: true,
      maxlength: 200,
      default: '',
    },
    /** Return Task — reason for return */
    returnReason: {
      type: String,
      trim: true,
      maxlength: 500,
      default: '',
    },
    completedAt: {
      type: Date,
      default: null,
    },
    acceptedAt: {
      type: Date,
      default: null,
    },
    startedAt: {
      type: Date,
      default: null,
    },
    statusHistory: {
      type: [taskStatusHistorySchema],
      default: [],
    },
    notes: {
      type: [taskNoteSchema],
      default: [],
    },
  },
  { timestamps: true }
);

taskSchema.index({ assignedToId: 1, status: 1, dueDate: 1 });
taskSchema.index({ warehouseId: 1, status: 1 });

module.exports = mongoose.model('Task', taskSchema);
