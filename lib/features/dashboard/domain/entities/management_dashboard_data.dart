import 'package:equatable/equatable.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';

/// KPI snapshot from GET /api/dashboard/stats for Admin / Supervisor home.
class ManagementDashboardData extends Equatable {
  const ManagementDashboardData({
    required this.totalStockValue,
    required this.totalUnitsOnHand,
    required this.lowStockLineCount,
    required this.outOfStockLineCount,
    required this.activeWarehousesCount,
    required this.todayMovementsCount,
    required this.totalOrders,
    required this.pendingOrders,
    required this.overdueTasks,
    required this.highPriorityTasks,
    this.pendingTasks = 0,
    this.inProgressTasks = 0,
    this.completedTasks = 0,
    this.alerts = const DashboardAlerts(),
    this.warehouseStats = const [],
  });

  final num totalStockValue;
  final num totalUnitsOnHand;
  final int lowStockLineCount;
  final int outOfStockLineCount;
  final int activeWarehousesCount;
  final int todayMovementsCount;
  final int totalOrders;
  final int pendingOrders;
  final int overdueTasks;
  final int highPriorityTasks;
  final int pendingTasks;
  final int inProgressTasks;
  final int completedTasks;
  final DashboardAlerts alerts;
  final List<WarehouseStat> warehouseStats;

  @override
  List<Object?> get props => [
        totalStockValue,
        totalUnitsOnHand,
        lowStockLineCount,
        outOfStockLineCount,
        activeWarehousesCount,
        todayMovementsCount,
        totalOrders,
        pendingOrders,
        overdueTasks,
        highPriorityTasks,
        pendingTasks,
        inProgressTasks,
        completedTasks,
        alerts,
        warehouseStats,
      ];
}
