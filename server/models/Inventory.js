const mongoose = require('mongoose');
const { CONDITION_AVAILABLE, INVENTORY_CONDITIONS } = require('../constants/inventoryConditions');

const inventorySchema = new mongoose.Schema(
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
    condition: {
      type: String,
      enum: INVENTORY_CONDITIONS,
      default: CONDITION_AVAILABLE,
      required: true,
    },
    quantity: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },
    binLocation: {
      type: String,
      trim: true,
      maxlength: 120,
      default: '',
    },
    batchNumber: {
      type: String,
      trim: true,
      maxlength: 100,
      default: '',
    },
    manufactureDate: {
      type: Date,
      default: null,
    },
    expiryDate: {
      type: Date,
      default: null,
      index: true,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      index: true,
    },
  },
  { timestamps: true }
);

inventorySchema.index({ productId: 1, warehouseId: 1, condition: 1 }, { unique: true });
inventorySchema.index({ expiryDate: 1, quantity: 1 });

module.exports = mongoose.model('Inventory', inventorySchema);
