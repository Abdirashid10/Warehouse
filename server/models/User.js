const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const ROLES = ['Admin', 'Supervisor', 'Staff'];
const USER_STATUSES = ['Active', 'Archived', 'Suspended'];

const userSchema = new mongoose.Schema(
  {
    username: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      minlength: 2,
      maxlength: 64,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      lowercase: true,
      maxlength: 255,
    },
    password: {
      type: String,
      required: true,
      minlength: 8,
      select: false,
    },
    role: {
      type: String,
      enum: ROLES,
      default: 'Staff',
    },
    archived: {
      type: Boolean,
      default: false,
      index: true,
    },
    archivedAt: {
      type: Date,
      default: null,
    },
    status: {
      type: String,
      enum: USER_STATUSES,
      default: 'Active',
      index: true,
    },
    suspendedAt: {
      type: Date,
      default: null,
    },
    lastLoginAt: {
      type: Date,
      default: null,
    },
    lastActiveAt: {
      type: Date,
      default: null,
    },
    forcePasswordChange: {
      type: Boolean,
      default: false,
    },
    fullName: {
      type: String,
      trim: true,
      maxlength: 120,
      default: '',
    },
    phone: {
      type: String,
      trim: true,
      maxlength: 30,
      default: '',
    },
    avatar: {
      type: String,
      default: '',
    },
    preferences: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
    assignedWarehouseIds: {
      type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Warehouse' }],
      default: [],
    },
  },
  { timestamps: true }
);

userSchema.index({ assignedWarehouseIds: 1 });

userSchema.pre('save', async function hashPassword(next) {
  if (!this.isModified('password')) {
    return next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

userSchema.methods.comparePassword = function comparePassword(candidate) {
  return bcrypt.compare(candidate, this.password);
};

module.exports = {
  User: mongoose.model('User', userSchema),
  ROLES,
  USER_STATUSES,
};
