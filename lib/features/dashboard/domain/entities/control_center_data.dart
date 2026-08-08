import 'package:equatable/equatable.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/dashboard_enterprise_widgets.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/domain/entities/supervisor_dashboard_data.dart';

/// Unified warehouse control center payload — mirrors web dashboard sections.
class ControlCenterData extends Equatable {
  const ControlCenterData({
    required this.supervisor,
    required this.insights,
    required this.recentOrders,
    required this.recentNotifications,
    required this.recentMovements,
    required this.orderStatusCounts,
    required this.pendingOrders,
    required this.movementTrend,
    required this.orderTrend,
  });

  final SupervisorDashboardData supervisor;
  final List<DashboardInsight> insights;
  final List<WarehouseOrder> recentOrders;
  final List<AppNotification> recentNotifications;
  final List<StockMovement> recentMovements;
  final List<ControlCenterOrderStatus> orderStatusCounts;
  final int pendingOrders;
  final DashboardChartTimeSeries movementTrend;
  final DashboardChartTimeSeries orderTrend;

  SupervisorKpiSummary get kpis => supervisor.kpis;
  SupervisorInventoryAlerts get inventoryAlerts => supervisor.inventoryAlerts;
  SupervisorTaskMonitoring get tasks => supervisor.taskMonitoring;
  List<SupervisorWarehouseOverview> get warehouses => supervisor.warehouses;
  List<SupervisorTeamActivity> get teamActivities => supervisor.teamActivities;

  @override
  List<Object?> get props => [
        supervisor,
        insights,
        recentOrders,
        recentNotifications,
        recentMovements,
        orderStatusCounts,
        pendingOrders,
        movementTrend,
        orderTrend,
      ];
}

class ControlCenterOrderStatus extends Equatable {
  const ControlCenterOrderStatus({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  List<Object?> get props => [label, count];
}
