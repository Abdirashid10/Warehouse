import 'package:logisticsmobile/core/constants/wms/order_constants.dart';
import 'package:logisticsmobile/features/audit/domain/repositories/audit_repository.dart';
import 'package:logisticsmobile/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/management_dashboard_data.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';
import 'package:logisticsmobile/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:logisticsmobile/features/inventory/data/datasources/inventory_remote_data_source.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/orders/domain/repositories/orders_repository.dart';
import 'package:logisticsmobile/features/products/domain/repositories/products_repository.dart';
import 'package:logisticsmobile/features/stock_operations/data/datasources/movements_remote_data_source.dart';
import 'package:logisticsmobile/features/tasks/data/datasources/tasks_remote_data_source.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';
import 'package:logisticsmobile/features/warehouses/domain/repositories/warehouses_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required DashboardRemoteDataSource dashboardRemote,
    required TasksRemoteDataSource tasksRemote,
    required InventoryRemoteDataSource inventoryRemote,
    required MovementsRemoteDataSource movementsRemote,
    required ProductsRepository productsRepository,
    required OrdersRepository ordersRepository,
    required NotificationsRepository notificationsRepository,
    required AuditRepository auditRepository,
    required WarehousesRepository warehousesRepository,
  })  : _dashboardRemote = dashboardRemote,
        _tasksRemote = tasksRemote,
        _inventoryRemote = inventoryRemote,
        _movementsRemote = movementsRemote,
        _productsRepository = productsRepository,
        _ordersRepository = ordersRepository,
        _notificationsRepository = notificationsRepository,
        _auditRepository = auditRepository,
        _warehousesRepository = warehousesRepository;

  final DashboardRemoteDataSource _dashboardRemote;
  final TasksRemoteDataSource _tasksRemote;
  final InventoryRemoteDataSource _inventoryRemote;
  final MovementsRemoteDataSource _movementsRemote;
  final ProductsRepository _productsRepository;
  final OrdersRepository _ordersRepository;
  final NotificationsRepository _notificationsRepository;
  final AuditRepository _auditRepository;
  final WarehousesRepository _warehousesRepository;

  @override
  Future<StaffDashboardData> loadStaffDashboard() async {
    final widgets = await _dashboardRemote.fetchWidgets();
    final ordersFuture = _safeOrders();
    final notificationsFuture = _safeNotifications();
    final auditFuture = _safeAudit();
    final warehousesFuture = _safeWarehouses();

    final taskModels = await _tasksRemote.fetchTasks();
    final inventory = await _inventoryRemote.fetchTracking();
    final movementModels = await _movementsRemote.fetchMovements(limit: 15);
    final products = await _productsRepository.getProducts();
    final orders = await ordersFuture;
    final notifications = await notificationsFuture;
    final auditActivities = await auditFuture;
    final warehouses = await warehousesFuture;

    final inventoryItems =
        inventory.items.map((m) => m.toEntity()).toList(growable: false);
    final warehouseStats = _enrichWarehouseStats(
      _dashboardRemote.parseWarehouseStats(widgets),
      warehouses,
      inventoryItems,
    );

    return StaffDashboardData(
      tasks: taskModels.map((m) => m.toEntity()).toList(),
      inventorySummary: inventory.summary.toEntity(),
      inventoryItems: inventoryItems,
      products: products,
      movements: movementModels.map((m) => m.toEntity()).toList(),
      alerts: _dashboardRemote.parseAlerts(widgets),
      warehouseStats: warehouseStats,
      insights: _dashboardRemote.parseInsights(widgets),
      recentOrders: _sortedOrders(orders),
      recentNotifications: _sortedNotifications(notifications),
      auditActivities: auditActivities,
      pendingOrdersCount: orders
          .where((o) => o.status == WmsOrderStatuses.pending)
          .length,
      allOrders: orders,
    );
  }

  @override
  Future<ManagementDashboardData> loadManagementDashboard() async {
    final stats = await _dashboardRemote.fetchStats();
    final widgets = await _dashboardRemote.fetchWidgets();

    final ordersByStatus = stats['ordersByStatus'];
    var pendingOrders = 0;
    if (ordersByStatus is Map) {
      for (final entry in ordersByStatus.entries) {
        final key = entry.key.toString();
        if (key == 'Pending' || key == 'Processing') {
          pendingOrders += (entry.value as num?)?.toInt() ?? 0;
        }
      }
    }

    final taskSummary = widgets['taskSummary'] ?? widgets['task_summary'];
    var overdue = 0;
    var highPriority = 0;
    var pendingTasks = 0;
    var inProgressTasks = 0;
    var completedTasks = 0;
    if (taskSummary is Map<String, dynamic>) {
      overdue = _asInt(taskSummary['overdue'] ?? taskSummary['overdueCount']);
      highPriority = _asInt(taskSummary['highPriorityPending'] ??
          taskSummary['high_priority_pending']);
      pendingTasks = _asInt(taskSummary['pending'] ?? taskSummary['pendingCount']);
      inProgressTasks = _asInt(taskSummary['inProgress'] ??
          taskSummary['in_progress'] ??
          taskSummary['active']);
      completedTasks =
          _asInt(taskSummary['completed'] ?? taskSummary['completedCount']);
    } else {
      overdue =
          _asInt(widgets['overdueTaskCount'] ?? widgets['overdue_task_count']);
      highPriority = _asInt(widgets['highPriorityPendingTasks'] ??
          widgets['high_priority_pending_tasks']);
    }

    return ManagementDashboardData(
      totalStockValue: stats['totalStockValue'] ?? stats['total_stock_value'] ?? 0,
      totalUnitsOnHand: stats['totalUnitsOnHand'] ?? stats['total_units_on_hand'] ?? 0,
      lowStockLineCount:
          stats['lowStockLineCount'] ?? stats['low_stock_line_count'] ?? 0,
      outOfStockLineCount:
          stats['outOfStockLineCount'] ?? stats['out_of_stock_line_count'] ?? 0,
      activeWarehousesCount:
          stats['activeWarehousesCount'] ?? stats['active_warehouses_count'] ?? 0,
      todayMovementsCount:
          stats['todayMovementsCount'] ?? stats['today_movements_count'] ?? 0,
      totalOrders: stats['totalOrders'] ?? stats['total_orders'] ?? 0,
      pendingOrders: pendingOrders,
      overdueTasks: overdue,
      highPriorityTasks: highPriority,
      pendingTasks: pendingTasks,
      inProgressTasks: inProgressTasks,
      completedTasks: completedTasks,
      alerts: _dashboardRemote.parseAlerts(widgets),
      warehouseStats: _dashboardRemote.parseWarehouseStats(widgets),
    );
  }

  List<WarehouseStat> _enrichWarehouseStats(
    List<WarehouseStat> stats,
    List<Warehouse> warehouses,
    List<InventoryItem> inventoryItems,
  ) {
    if (stats.isEmpty && warehouses.isNotEmpty) {
      return warehouses
          .map(
            (w) => WarehouseStat(
              id: w.id,
              name: w.name,
              totalUnits: w.totalUnits,
              utilization: w.utilizationPercent,
              location: w.location,
              productCount: _productCountForWarehouse(w.name, inventoryItems),
            ),
          )
          .toList(growable: false);
    }

    return stats
        .map((stat) {
          Warehouse? match;
          for (final w in warehouses) {
            if (w.id == stat.id ||
                w.name.toLowerCase() == stat.name.toLowerCase()) {
              match = w;
              break;
            }
          }

          return WarehouseStat(
            id: stat.id,
            name: stat.name,
            totalUnits: match?.totalUnits ?? stat.totalUnits,
            utilization: match?.utilizationPercent ?? stat.utilization,
            location: match?.location ?? stat.location,
            productCount: match?.lineCount ??
                _productCountForWarehouse(stat.name, inventoryItems),
          );
        })
        .toList(growable: false);
  }

  int _productCountForWarehouse(
    String warehouseName,
    List<InventoryItem> items,
  ) {
    final normalized = warehouseName.toLowerCase();
    return items
        .where((i) => i.warehouseName.toLowerCase() == normalized)
        .map((i) => i.sku)
        .toSet()
        .length;
  }

  List<WarehouseOrder> _sortedOrders(List<WarehouseOrder> orders) {
    final sorted = List<WarehouseOrder>.from(orders)
      ..sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
    return sorted.take(8).toList(growable: false);
  }

  List<AppNotification> _sortedNotifications(
    List<AppNotification> notifications,
  ) {
    final sorted = List<AppNotification>.from(notifications)
      ..sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
    return sorted.take(6).toList(growable: false);
  }

  Future<List<WarehouseOrder>> _safeOrders() async {
    try {
      return (await _ordersRepository.getOrders()).orders;
    } catch (_) {
      return const [];
    }
  }

  Future<List<AppNotification>> _safeNotifications() async {
    try {
      return (await _notificationsRepository.getNotifications()).items;
    } catch (_) {
      return const [];
    }
  }

  Future<List<StaffAuditActivity>> _safeAudit() async {
    try {
      final page = await _auditRepository.getActivities(limit: 6);
      return page.activities
          .map(
            (a) => StaffAuditActivity(
              id: a.id,
              userName: a.userName,
              action: a.action,
              occurredAt: a.occurredAt,
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<Warehouse>> _safeWarehouses() async {
    try {
      return await _warehousesRepository.getWarehouses();
    } catch (_) {
      return const [];
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
