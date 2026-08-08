/** Client mirror of server warehouse RBAC scope (restrictions not enforced in UI yet). */

export function hasGlobalWarehouseAccess(role) {
  return role === 'Admin' || role === 'Supervisor';
}

export function getWarehouseAccessScope(user) {
  if (!user) return { unrestricted: false, warehouseIds: [] };
  if (hasGlobalWarehouseAccess(user.role)) {
    return { unrestricted: true, warehouseIds: [] };
  }
  return {
    unrestricted: false,
    warehouseIds: user.assignedWarehouseIds || [],
  };
}

export function canAccessWarehouse(user, warehouseId) {
  const scope = getWarehouseAccessScope(user);
  if (scope.unrestricted) return true;
  return scope.warehouseIds.includes(String(warehouseId));
}
