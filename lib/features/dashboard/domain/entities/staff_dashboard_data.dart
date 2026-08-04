import 'package:equatable/equatable.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';

class StaffDashboardData extends Equatable {
  const StaffDashboardData({
    required this.tasks,
    required this.inventorySummary,
    required this.inventoryItems,
    required this.products,
    required this.movements,
    required this.alerts,
    required this.warehouseStats,
    required this.insights,
    this.recentOrders = const [],
    this.recentNotifications = const [],
    this.auditActivities = const [],
    this.pendingOrdersCount = 0,
    this.allOrders = const [],
  });

  final List<WarehouseTask> tasks;
  final InventorySummary inventorySummary;
  final List<InventoryItem> inventoryItems;
  final List<Product> products;
  final List<StockMovement> movements;
  final DashboardAlerts alerts;
  final List<WarehouseStat> warehouseStats;
  final List<DashboardInsight> insights;
  final List<WarehouseOrder> recentOrders;
  final List<AppNotification> recentNotifications;
  final List<StaffAuditActivity> auditActivities;
  final int pendingOrdersCount;
  final List<WarehouseOrder> allOrders;

  Map<String, Product> get productsBySku => {for (final p in products) p.sku: p};

  @override
  List<Object?> get props => [
        tasks,
        inventorySummary,
        inventoryItems,
        products,
        movements,
        alerts,
        warehouseStats,
        insights,
        recentOrders,
        recentNotifications,
        auditActivities,
        pendingOrdersCount,
        allOrders,
      ];
}

class StaffAuditActivity extends Equatable {
  const StaffAuditActivity({
    required this.id,
    required this.userName,
    required this.action,
    required this.occurredAt,
  });

  final String id;
  final String userName;
  final String action;
  final DateTime? occurredAt;

  @override
  List<Object?> get props => [id, userName, action, occurredAt];
}

class DashboardAlerts extends Equatable {
  const DashboardAlerts({
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.expiredCount = 0,
    this.expiringSoonCount = 0,
  });

  final int lowStockCount;
  final int outOfStockCount;
  final int expiredCount;
  final int expiringSoonCount;

  bool get hasAlerts =>
      lowStockCount > 0 ||
      outOfStockCount > 0 ||
      expiredCount > 0 ||
      expiringSoonCount > 0;

  @override
  List<Object?> get props =>
      [lowStockCount, outOfStockCount, expiredCount, expiringSoonCount];
}

class WarehouseStat extends Equatable {
  const WarehouseStat({
    required this.id,
    required this.name,
    required this.totalUnits,
    required this.utilization,
    this.location,
    this.productCount = 0,
  });

  final String id;
  final String name;
  final num totalUnits;
  final int utilization;
  final String? location;
  final int productCount;

  @override
  List<Object?> get props =>
      [id, name, totalUnits, utilization, location, productCount];
}

class DashboardInsight extends Equatable {
  const DashboardInsight({
    required this.message,
    required this.severity,
  });

  final String message;
  final String severity;

  @override
  List<Object?> get props => [message, severity];
}
