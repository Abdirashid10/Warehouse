const mongoose = require('mongoose');

const ORDER_STATUSES = ['Pending', 'Processing', 'Packed', 'Shipped', 'Delivered'];

const statusHistorySchema = new mongoose.Schema(
  {
    status: {
      type: String,
      enum: ORDER_STATUSES,
      required: true,
    },
    changed_at: {
      type: Date,
      required: true,
    },
    changed_by: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  { _id: true }
);

const orderItemSchema = new mongoose.Schema(
  {
    product_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: true,
    },
    quantity: {
      type: Number,
      required: true,
      min: 1,
    },
    unit_price: {
      type: Number,
      required: true,
      min: 0,
    },
    line_total: {
      type: Number,
      required: true,
      min: 0,
    },
    warehouse_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Warehouse',
      required: true,
    },
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    order_number: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      uppercase: true,
    },
    customer_name: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
    },
    phone_number: {
      type: String,
      trim: true,
      maxlength: 40,
      default: '',
    },
    delivery_address: {
      type: String,
      trim: true,
      maxlength: 600,
      default: '',
    },
    notes: {
      type: String,
      trim: true,
      maxlength: 2000,
      default: '',
    },
    priority: {
      type: String,
      enum: ['Normal', 'Urgent', 'High Priority'],
      default: 'Normal',
    },
    expected_delivery_date: {
      type: Date,
      default: null,
    },
    items: {
      type: [orderItemSchema],
      validate: {
        validator(v) {
          return Array.isArray(v) && v.length > 0;
        },
        message: 'Order must include at least one line item',
      },
    },
    total_items: {
      type: Number,
      min: 1,
      default: 1,
    },
    total_quantity: {
      type: Number,
      min: 1,
      default: 1,
    },
    grand_total: {
      type: Number,
      min: 0,
      default: 0,
    },
    status: {
      type: String,
      enum: ORDER_STATUSES,
      default: 'Pending',
    },
    status_history: {
      type: [statusHistorySchema],
      default: [],
    },
    shipped_at: {
      type: Date,
      default: null,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      index: true,
    },
  },
  { timestamps: true }
);

orderSchema.index({ status: 1, createdAt: -1 });
orderSchema.index({ customer_name: 'text', order_number: 'text' });

module.exports = {
  Order: mongoose.model('Order', orderSchema),
  ORDER_STATUSES,
};
