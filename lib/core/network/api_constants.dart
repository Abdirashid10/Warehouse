import 'package:logisticsmobile/core/config/api_config.dart';

/// Logistics WMS REST paths (base URL includes `/api`).
abstract final class ApiConstants {
  static String get baseUrl => ApiConfig.baseUrl;

  // Auth — POST /api/auth/login
  static const String login = '/auth/login';

  // Profile — GET /api/profile/me (user-facing "profile")
  static const String profile = '/profile';
  static const String profileMe = '/profile/me';

  // Dashboard — GET /api/dashboard/stats, /api/dashboard/widgets
  static const String dashboard = '/dashboard';
  static const String dashboardStats = '/dashboard/stats';
  static const String dashboardWidgets = '/dashboard/widgets';

  // Tasks — GET/POST/PATCH /api/tasks
  static const String tasks = '/tasks';
  static const String tasksMetaOptions = '/tasks/meta/options';
  static const String tasksMetaAssignees = '/tasks/meta/assignees';

  // Inventory — GET /api/inventory, GET /api/inventory/tracking
  static const String inventory = '/inventory';
  static const String inventoryTracking = '/inventory/tracking';
  static const String inventoryWarehouses = '/inventory/warehouses';
  static const String inventoryMovements = '/inventory/movements';

  // Products — GET/POST /api/products
  static const String products = '/products';
  static const String productsNextSku = '/products/next-sku';
  static const String categories = '/categories';

  // Orders — GET /api/orders, PUT /api/orders/:id/status
  static const String orders = '/orders';

  // Notifications — GET /api/notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';

  // Users — GET/POST/PATCH /api/users (Admin)
  static const String users = '/users';

  // Reports — GET /api/reports/* (Admin & Supervisor)
  static const String reportsValuation = '/reports/valuation';
  static const String reportsInventoryAudit = '/reports/inventory-audit';

  // Audit — GET /api/audit/activities (Supervisor / Admin)
  static const String auditActivities = '/audit/activities';

  static Duration get connectTimeout => ApiConfig.connectTimeout;
  static Duration get receiveTimeout => ApiConfig.receiveTimeout;
}
