const { formatCreatedBy } = require('./createdByDto');
const { isAssignableWarehouseStaff } = require('../services/warehouseStaffService');

function formatStaffMember(user) {
  if (!user) return null;
  const row = user.toObject ? user.toObject() : user;
  return {
    id: row._id?.toString(),
    username: row.username,
    full_name: row.fullName || '',
    email: row.email,
    role: row.role,
    avatar: row.avatar || '',
  };
}

function formatWarehouse(doc, inventoryStats = null) {
  if (!doc) return null;
  const row = doc.toObject ? doc.toObject() : doc;
  const staff = (row.assignedStaffIds || [])
    .filter(isAssignableWarehouseStaff)
    .map(formatStaffMember)
    .filter(Boolean);

  const totalUnits = inventoryStats?.totalUnits ?? 0;
  const lineCount = inventoryStats?.lineCount ?? 0;
  const capacity = row.capacity ?? 0;
  const utilization =
    inventoryStats?.utilization ??
    (capacity > 0 ? Math.min(100, Math.round((totalUnits / capacity) * 100)) : 0);

  return {
    _id: row._id?.toString(),
    id: row._id?.toString(),
    name: row.name,
    location: row.location,
    capacity,
    totalUnits,
    total_units: totalUnits,
    lineCount,
    utilization,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    created_by: formatCreatedBy(row),
    assigned_staff: staff,
    staff_count: staff.length,
  };
}

module.exports = { formatWarehouse, formatStaffMember };
