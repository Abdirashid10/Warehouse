const mongoose = require('mongoose');

const MOVEMENT_TYPES = ['INBOUND', 'OUTBOUND', 'ADJUSTMENT', 'TRANSFER', 'RETURN'];

const movementSchema = new mongoose.Schema(
  {
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: true,
    },
    warehouseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Warehouse',
      required: true,
    },
    /** Destination site for TRANSFER movements (source is warehouseId). */
    toWarehouseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Warehouse',
      default: null,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      index: true,
    },
    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Task',
      default: null,
      index: true,
    },
    type: {
      type: String,
      enum: MOVEMENT_TYPES,
      required: true,
    },
    quantity: {
      type: Number,
      required: true,
      min: 1,
    },
    /** Signed change applied to inventory (+ inbound, − outbound, ± adjustment). */
    delta: {
      type: Number,
      default: null,
    },
    reason: {
      type: String,
      trim: true,
      maxlength: 500,
      default: '',
    },
    /** Human-readable origin (supplier, warehouse name, etc.). */
    source_location: {
      type: String,
      trim: true,
      maxlength: 200,
      default: '',
    },
    /** Human-readable destination (warehouse name, customer, etc.). */
    destination_location: {
      type: String,
      trim: true,
      maxlength: 200,
      default: '',
    },
    timestamp: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

movementSchema.index({ timestamp: -1 });
movementSchema.index({ productId: 1, warehouseId: 1, timestamp: -1 });

module.exports = {
  Movement: mongoose.model('Movement', movementSchema),
  MOVEMENT_TYPES,
};
