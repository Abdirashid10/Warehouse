const mongoose = require('mongoose');

const userActivityLogSchema = new mongoose.Schema(
  {
    actorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    targetUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },
    action: {
      type: String,
      required: true,
      trim: true,
      maxlength: 120,
      index: true,
    },
    module: {
      type: String,
      required: true,
      trim: true,
      maxlength: 80,
      index: true,
    },
    details: {
      type: String,
      trim: true,
      maxlength: 1000,
      default: '',
    },
    actorRole: {
      type: String,
      trim: true,
      maxlength: 40,
      default: '',
    },
    entityType: {
      type: String,
      trim: true,
      maxlength: 60,
      default: '',
      index: true,
    },
    entityId: {
      type: String,
      trim: true,
      maxlength: 80,
      default: '',
      index: true,
    },
    entityLabel: {
      type: String,
      trim: true,
      maxlength: 200,
      default: '',
    },
    beforeValue: {
      type: String,
      trim: true,
      maxlength: 2000,
      default: '',
    },
    afterValue: {
      type: String,
      trim: true,
      maxlength: 2000,
      default: '',
    },
    ipAddress: {
      type: String,
      trim: true,
      maxlength: 64,
      default: '',
    },
    warehouseIds: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Warehouse',
      index: true,
    }],
  },
  { timestamps: true }
);

userActivityLogSchema.index({ createdAt: -1 });
userActivityLogSchema.index({ warehouseIds: 1, createdAt: -1 });
userActivityLogSchema.index({ entityType: 1, entityId: 1, createdAt: -1 });

module.exports = mongoose.model('UserActivityLog', userActivityLogSchema);
