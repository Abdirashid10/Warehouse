/**
 * Warehouse access scope for RBAC (Staff restrictions prepared, not enforced globally yet).
 */

function hasGlobalWarehouseAccess(role) {
  return role === 'Admin' || role === 'Supervisor';
}

/**
 * @param {{ role: string, assignedWarehouseIds?: string[] }} user
 * @returns {{ unrestricted: boolean, warehouseIds: string[] }}
 */
function getWarehouseAccessScope(user) {
  if (!user) return { unrestricted: false, warehouseIds: [] };
  if (hasGlobalWarehouseAccess(user.role)) {
    return { unrestricted: true, warehouseIds: [] };
  }
  const ids = (user.assignedWarehouseIds || []).map((id) => String(id));
  return { unrestricted: false, warehouseIds: ids };
}

function canAccessWarehouse(user, warehouseId) {
  const scope = getWarehouseAccessScope(user);
  if (scope.unrestricted) return true;
  if (!warehouseId) return false;
  return scope.warehouseIds.includes(String(warehouseId));
}

/**
 * Optional filter for list queries — returns undefined when unrestricted (no filter).
 */
function buildWarehouseIdFilter(user) {
  const scope = getWarehouseAccessScope(user);
  if (scope.unrestricted) return undefined;
  if (scope.warehouseIds.length === 0) return { _id: { $in: [] } };
  return { _id: { $in: scope.warehouseIds } };
}

module.exports = {
  hasGlobalWarehouseAccess,
  getWarehouseAccessScope,
  canAccessWarehouse,
  buildWarehouseIdFilter,
};
