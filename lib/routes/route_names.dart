abstract final class RouteNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String settings = 'settings';

  static const String adminDashboard = 'adminDashboard';
  static const String adminOrders = 'adminOrders';
  static const String adminTasks = 'adminTasks';
  static const String adminNotifications = 'adminNotifications';
  static const String adminProfile = 'adminProfile';
  static const String adminProducts = 'adminProducts';
  static const String adminInventory = 'adminInventory';
  static const String adminStockMovements = 'adminStockMovements';
  static const String adminStockOperations = 'adminStockOperations';
  static const String adminWarehouses = 'adminWarehouses';
  static const String adminReports = 'adminReports';
  static const String adminAudit = 'adminAudit';
  static const String adminUsers = 'adminUsers';
  static const String adminUserDetail = 'adminUserDetail';
  static const String adminAdministration = 'adminAdministration';
  static const String adminTaskDetail = 'adminTaskDetail';
  static const String adminOrderDetail = 'adminOrderDetail';

  static const String supervisorDashboard = 'supervisorDashboard';
  static const String supervisorTasks = 'supervisorTasks';
  static const String supervisorInventory = 'supervisorInventory';
  static const String supervisorOrders = 'supervisorOrders';
  static const String supervisorProfile = 'supervisorProfile';
  static const String supervisorStockOperations = 'supervisorStockOperations';
  static const String supervisorStockMovements = 'supervisorStockMovements';
  static const String supervisorProducts = 'supervisorProducts';
  static const String supervisorInventoryTracking = 'supervisorInventoryTracking';
  static const String supervisorWarehouses = 'supervisorWarehouses';
  static const String supervisorExpiryRisk = 'supervisorExpiryRisk';
  static const String supervisorAudit = 'supervisorAudit';
  static const String supervisorReports = 'supervisorReports';
  static const String supervisorTaskDetail = 'supervisorTaskDetail';
  static const String supervisorOrderDetail = 'supervisorOrderDetail';

  static const String staffDashboard = 'staffDashboard';
  static const String staffTasks = 'staffTasks';
  static const String staffTaskDetail = 'staffTaskDetail';
  static const String staffInventory = 'staffInventory';
  static const String staffStockOperations = 'staffStockOperations';
  static const String staffOrders = 'staffOrders';
  static const String staffOrderDetail = 'staffOrderDetail';
  static const String staffNotifications = 'staffNotifications';
  static const String staffReports = 'staffReports';
  static const String staffProfile = 'staffProfile';
  static const String supervisorNotifications = 'supervisorNotifications';
}

abstract final class RoutePaths {
  static const String splash = '/';
  static const String login = '/login';
  static const String settings = '/settings';

  static const String adminRoot = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminOrders = '/admin/orders';
  static const String adminTasks = '/admin/tasks';
  static const String adminNotifications = '/admin/notifications';
  static const String adminProfile = '/admin/profile';
  static const String adminProducts = '/admin/products';
  static const String adminInventory = '/admin/inventory';
  static const String adminStockMovements = '/admin/stock-movements';
  static const String adminStockOperations = '/admin/stock-operations';
  static const String adminWarehouses = '/admin/warehouses';
  static const String adminReports = '/admin/reports';
  static const String adminAudit = '/admin/audit';
  static const String adminUsers = '/admin/users';
  static String adminUserDetail(String id) => '/admin/users/$id';
  static const String adminAdministration = '/admin/administration';

  static const String supervisorRoot = '/supervisor';
  static const String supervisorDashboard = '/supervisor/dashboard';
  static const String supervisorTasks = '/supervisor/tasks';
  static const String supervisorInventory = '/supervisor/inventory';
  static const String supervisorOrders = '/supervisor/orders';
  static const String supervisorProfile = '/supervisor/profile';
  static const String supervisorStockOperations = '/supervisor/stock-operations';
  static const String supervisorStockMovements = '/supervisor/stock-movements';
  static const String supervisorProducts = '/supervisor/products';
  static const String supervisorInventoryTracking = '/supervisor/inventory-tracking';
  static const String supervisorWarehouses = '/supervisor/warehouses';
  static const String supervisorExpiryRisk = '/supervisor/expiry-risk';
  static const String supervisorAudit = '/supervisor/audit';
  static const String supervisorReports = '/supervisor/reports';

  static const String staffRoot = '/staff';
  static const String staffDashboard = '/staff/dashboard';
  static const String staffTasks = '/staff/tasks';
  static const String staffInventory = '/staff/inventory';
  static const String staffStockOperations = '/staff/stock-operations';
  static const String staffOrders = '/staff/orders';
  static const String staffNotifications = '/staff/notifications';
  static const String staffReports = '/staff/reports';
  static const String staffProfile = '/staff/profile';
  static const String supervisorNotifications = '/supervisor/notifications';

  static String staffTaskDetail(String id) => '/staff/tasks/$id';
  static String staffOrderDetail(String id) => '/staff/orders/$id';
  static String supervisorTaskDetail(String id) => '/supervisor/tasks/$id';
  static String supervisorOrderDetail(String id) => '/supervisor/orders/$id';
  static String adminTaskDetail(String id) => '/admin/tasks/$id';
  static String adminOrderDetail(String id) => '/admin/orders/$id';

  static bool isStaffShellRoute(String location) {
    return location.startsWith('/staff/') &&
        !location.contains('/staff/tasks/') &&
        !location.contains('/staff/orders/') &&
        location != staffStockOperations;
  }

  static bool isSupervisorShellRoute(String location) {
    if (_isSupervisorPushedRoute(location)) return false;
    return location.startsWith('/supervisor/') &&
        !location.contains('/supervisor/tasks/') &&
        !location.contains('/supervisor/orders/');
  }

  static bool _isSupervisorPushedRoute(String location) {
    const pushed = [
      supervisorStockOperations,
      supervisorStockMovements,
      supervisorProducts,
      supervisorInventoryTracking,
      supervisorWarehouses,
      supervisorExpiryRisk,
      supervisorReports,
      supervisorAudit,
      supervisorNotifications,
    ];
    return pushed.any((p) => location == p || location.startsWith('$p/'));
  }

  static bool isAdminShellRoute(String location) {
    return location.startsWith('/admin/') &&
        !location.contains('/admin/tasks/') &&
        !location.contains('/admin/orders/') &&
        !_isAdminPushedRoute(location);
  }

  static bool _isAdminPushedRoute(String location) {
    const pushed = [
      adminProducts,
      adminStockMovements,
      adminStockOperations,
      adminWarehouses,
      adminReports,
      adminAudit,
      adminUsers,
      adminAdministration,
      adminNotifications,
    ];
    return pushed.any((p) => location == p || location.startsWith('$p/'));
  }

  static bool isAdminUserDetailRoute(String location) {
    return location.startsWith('$adminUsers/') && location != adminUsers;
  }

  static bool isStaffArea(String location) => location.startsWith('/staff');
  static bool isSupervisorArea(String location) =>
      location.startsWith('/supervisor');
  static bool isAdminArea(String location) => location.startsWith('/admin');
}
