import 'package:equatable/equatable.dart';

/// Aggregated supervisor home data from Logistics WMS APIs.
class SupervisorDashboardData extends Equatable {
  const SupervisorDashboardData({
    required this.profile,
    required this.kpis,
    required this.warehouses,
    required this.teamActivities,
    required this.taskMonitoring,
    required this.orderMonitoring,
    required this.inventoryAlerts,
  });

  final SupervisorProfileSummary profile;
  final SupervisorKpiSummary kpis;
  final List<SupervisorWarehouseOverview> warehouses;
  final List<SupervisorTeamActivity> teamActivities;
  final SupervisorTaskMonitoring taskMonitoring;
  final SupervisorOrderMonitoring orderMonitoring;
  final SupervisorInventoryAlerts inventoryAlerts;

  bool get isEffectivelyEmpty =>
      warehouses.isEmpty &&
      teamActivities.isEmpty &&
      !inventoryAlerts.hasAlerts &&
      kpis.totalOrders == 0;

  @override
  List<Object?> get props => [
        profile,
        kpis,
        warehouses,
        teamActivities,
        taskMonitoring,
        orderMonitoring,
        inventoryAlerts,
      ];
}

class SupervisorProfileSummary extends Equatable {
  const SupervisorProfileSummary({
    required this.fullName,
    required this.email,
    required this.role,
    this.assignedWarehouses = const [],
  });

  final String fullName;
  final String email;
  final String role;
  final List<String> assignedWarehouses;

  String get assignedWarehousesLabel {
    if (assignedWarehouses.isEmpty) return 'All warehouses';
    if (assignedWarehouses.length == 1) return assignedWarehouses.first;
    return assignedWarehouses.join(', ');
  }

  @override
  List<Object?> get props => [fullName, email, role, assignedWarehouses];
}

class SupervisorKpiSummary extends Equatable {
  const SupervisorKpiSummary({
    required this.totalStockValue,
    required this.totalUnitsOnHand,
    required this.lowStockProducts,
    required this.totalOrders,
    required this.stockMovementsToday,
    required this.overdueTasks,
    this.inStockLines = 0,
    this.outOfStockLines = 0,
  });

  final num totalStockValue;
  final num totalUnitsOnHand;
  final int lowStockProducts;
  final int totalOrders;
  final int stockMovementsToday;
  final int overdueTasks;
  final int inStockLines;
  final int outOfStockLines;

  @override
  List<Object?> get props => [
        totalStockValue,
        totalUnitsOnHand,
        lowStockProducts,
        totalOrders,
        stockMovementsToday,
        overdueTasks,
        inStockLines,
        outOfStockLines,
      ];
}

class SupervisorWarehouseOverview extends Equatable {
  const SupervisorWarehouseOverview({
    required this.id,
    required this.name,
    required this.stockCount,
    required this.activeStaffCount,
    required this.status,
    this.location,
    this.utilizationPercent,
  });

  final String id;
  final String name;
  final int stockCount;
  final int activeStaffCount;
  final String status;
  final String? location;
  final int? utilizationPercent;

  @override
  List<Object?> get props =>
      [id, name, stockCount, activeStaffCount, status, location, utilizationPercent];
}

class SupervisorTeamActivity extends Equatable {
  const SupervisorTeamActivity({
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

class SupervisorTaskMonitoring extends Equatable {
  const SupervisorTaskMonitoring({
    required this.pending,
    required this.inProgress,
    required this.waitingConfirmation,
    required this.completed,
  });

  final int pending;
  final int inProgress;
  final int waitingConfirmation;
  final int completed;

  int get total => pending + inProgress + waitingConfirmation + completed;

  @override
  List<Object?> get props => [pending, inProgress, waitingConfirmation, completed];
}

class SupervisorOrderMonitoring extends Equatable {
  const SupervisorOrderMonitoring({
    required this.processing,
    required this.packed,
    required this.shipped,
    required this.delivered,
  });

  final int processing;
  final int packed;
  final int shipped;
  final int delivered;

  int get total => processing + packed + shipped + delivered;

  @override
  List<Object?> get props => [processing, packed, shipped, delivered];
}

class SupervisorInventoryAlertItem extends Equatable {
  const SupervisorInventoryAlertItem({
    required this.productName,
    required this.sku,
    required this.warehouseName,
    this.quantity,
    this.detail,
    this.severity = SupervisorAlertSeverity.warning,
  });

  final String productName;
  final String sku;
  final String warehouseName;
  final num? quantity;
  final String? detail;
  final SupervisorAlertSeverity severity;

  @override
  List<Object?> get props =>
      [productName, sku, warehouseName, quantity, detail, severity];
}

enum SupervisorAlertSeverity { warning, critical, info }

class SupervisorInventoryAlerts extends Equatable {
  const SupervisorInventoryAlerts({
    this.lowStock = const [],
    this.expiring = const [],
    this.critical = const [],
    this.lowStockCount = 0,
    this.expiringCount = 0,
    this.criticalCount = 0,
    this.outOfStockCount = 0,
    this.expiredCount = 0,
  });

  final List<SupervisorInventoryAlertItem> lowStock;
  final List<SupervisorInventoryAlertItem> expiring;
  final List<SupervisorInventoryAlertItem> critical;
  final int lowStockCount;
  final int expiringCount;
  final int criticalCount;
  final int outOfStockCount;
  final int expiredCount;

  bool get hasAlerts =>
      lowStock.isNotEmpty || expiring.isNotEmpty || critical.isNotEmpty;

  @override
  List<Object?> get props => [
        lowStock,
        expiring,
        critical,
        lowStockCount,
        expiringCount,
        criticalCount,
        outOfStockCount,
        expiredCount,
      ];
}
