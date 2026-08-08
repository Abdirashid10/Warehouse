const mongoose = require('mongoose');
const { User, Warehouse } = require('../models');

const STAFF_SELECT = 'username email role fullName avatar status archived assignedWarehouseIds';

/** MongoDB match for populate / queries — only assignable warehouse staff. */
const ASSIGNABLE_WAREHOUSE_STAFF_MATCH = {
  role: 'Staff',
  status: 'Active',
  archived: { $ne: true },
};

function isAssignableWarehouseStaff(user) {
  if (!user || typeof user !== 'object') return false;
  const row = user.toObject ? user.toObject() : user;
  if (!row.username) return false;
  if (row.role !== 'Staff') return false;
  if (row.status !== 'Active') return false;
  if (row.archived === true) return false;
  return true;
}

function parseStaffIds(raw) {
  if (raw == null) return [];
  const list = Array.isArray(raw) ? raw : [];
  const unique = [];
  const seen = new Set();
  for (const id of list) {
    const value = String(id || '').trim();
    if (!value || !mongoose.Types.ObjectId.isValid(value)) continue;
    if (seen.has(value)) continue;
    seen.add(value);
    unique.push(value);
  }
  return unique;
}

async function resolveStaffUsers(staffIds) {
  if (!staffIds.length) return [];

  const users = await User.find({
    _id: { $in: staffIds },
    role: 'Staff',
    archived: { $ne: true },
    status: 'Active',
  })
    .select(STAFF_SELECT)
    .lean();

  if (users.length !== staffIds.length) {
    const err = new Error('Only active Staff users can be assigned to warehouses');
    err.status = 400;
    throw err;
  }

  return users;
}

/**
 * Sync warehouse.assignedStaffIds and each staff user's assignedWarehouseIds.
 */
async function syncWarehouseStaffAssignments(warehouseId, staffIds) {
  const warehouse = await Warehouse.findById(warehouseId);
  if (!warehouse) {
    const err = new Error('Warehouse not found');
    err.status = 404;
    throw err;
  }

  const nextIds = parseStaffIds(staffIds);
  await resolveStaffUsers(nextIds);

  const previousIds = (warehouse.assignedStaffIds || []).map((id) => id.toString());
  const nextSet = new Set(nextIds);
  const removed = previousIds.filter((id) => !nextSet.has(id));

  warehouse.assignedStaffIds = nextIds.map((id) => new mongoose.Types.ObjectId(id));
  await warehouse.save();

  if (removed.length) {
    await User.updateMany(
      { _id: { $in: removed } },
      { $pull: { assignedWarehouseIds: warehouse._id } }
    );
  }

  if (nextIds.length) {
    await User.updateMany(
      { _id: { $in: nextIds } },
      { $addToSet: { assignedWarehouseIds: warehouse._id } }
    );
  }

  return warehouse;
}

async function listStaffCandidates(search = '') {
  const filter = {
    role: 'Staff',
    archived: { $ne: true },
    status: 'Active',
  };

  const q = String(search || '').trim();
  if (q) {
    const regex = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
    filter.$or = [{ username: regex }, { email: regex }, { fullName: regex }];
  }

  const users = await User.find(filter).select(STAFF_SELECT).sort({ username: 1 }).lean();
  return users;
}

module.exports = {
  parseStaffIds,
  resolveStaffUsers,
  syncWarehouseStaffAssignments,
  listStaffCandidates,
  STAFF_SELECT,
  ASSIGNABLE_WAREHOUSE_STAFF_MATCH,
  isAssignableWarehouseStaff,
};
