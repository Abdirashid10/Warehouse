import 'package:logisticsmobile/core/utils/task_workflow_utils.dart';
import 'package:logisticsmobile/features/dashboard/data/mappers/control_center_mapper.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/control_center_data.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';
import 'package:logisticsmobile/features/inventory/presentation/utils/inventory_metrics.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/domain/entities/supervisor_dashboard_data.dart';

/// Maps staff dashboard payload into web-parity [ControlCenterData].
abstract final class StaffControlCenterMapper {
  static ControlCenterData fromStaffData(StaffDashboardData data) {
    final taskSummary = TaskWorkflowUtils.summarize(data.tasks);
    final orderMonitoring = _orderMonitoring(data.allOrders);
    final stockValue = _stockValue(data);

    final supervisor = SupervisorDashboardData(
      profile: const SupervisorProfileSummary(
        fullName: 'Staff',
        email: '',
        role: 'Staff',
      ),
      kpis: SupervisorKpiSummary(
        totalStockValue: stockValue,
        totalUnitsOnHand: data.inventorySummary.totalUnits,
        lowStockProducts: data.inventorySummary.lowStock,
        totalOrders: data.allOrders.length,
        stockMovementsToday: _todayMovements(data.movements),
        overdueTasks: taskSummary.overdue,
        inStockLines: data.inventorySummary.inStock,
        outOfStockLines: data.inventorySummary.outOfStock,
      ),
      warehouses: data.warehouseStats
          .map(
            (w) => SupervisorWarehouseOverview(
              id: w.id,
              name: w.name,
              stockCount: w.totalUnits.toInt(),
              activeStaffCount: 0,
              status: 'Operational',
              location: w.location,
              utilizationPercent: w.utilization,
            ),
          )
          .toList(growable: false),
      teamActivities: data.auditActivities
          .map(
            (a) => SupervisorTeamActivity(
              id: a.id,
              userName: a.userName,
              action: a.action,
              occurredAt: a.occurredAt,
            ),
          )
          .toList(growable: false),
      taskMonitoring: SupervisorTaskMonitoring(
        pending: taskSummary.awaiting,
        inProgress: taskSummary.inProgress,
        waitingConfirmation: taskSummary.accepted,
        completed: taskSummary.completed,
      ),
      orderMonitoring: orderMonitoring,
      inventoryAlerts: _inventoryAlerts(data),
    );

    return ControlCenterData(
      supervisor: supervisor,
      insights: data.insights,
      recentOrders: data.recentOrders,
      recentNotifications: data.recentNotifications,
      recentMovements: data.movements,
      orderStatusCounts: ControlCenterMapper.orderStatusCountsFromOrders(
        data.allOrders,
      ),
      pendingOrders: data.pendingOrdersCount,
      movementTrend: ControlCenterMapper.movementTrendFrom(data.movements),
      orderTrend: ControlCenterMapper.orderTrendFrom(data.allOrders),
    );
  }

  static SupervisorOrderMonitoring _orderMonitoring(
    List<WarehouseOrder> orders,
  ) {
    var processing = 0;
    var packed = 0;
    var shipped = 0;
    var delivered = 0;

    for (final order in orders) {
      final status = order.status.toLowerCase();
      if (status.contains('deliver')) {
        delivered++;
      } else if (status.contains('ship')) {
        shipped++;
      } else if (status.contains('pack')) {
        packed++;
      } else if (status.contains('process') || status.contains('pending')) {
        processing++;
      }
    }

    return SupervisorOrderMonitoring(
      processing: processing,
      packed: packed,
      shipped: shipped,
      delivered: delivered,
    );
  }

  static SupervisorInventoryAlerts _inventoryAlerts(StaffDashboardData data) {
    final critical = data.inventoryItems
        .where(InventoryMetrics.isExpired)
        .take(5)
        .map(
          (item) => SupervisorInventoryAlertItem(
            productName: item.productName,
            sku: item.sku,
            warehouseName: item.warehouseName,
            quantity: item.quantity,
            severity: SupervisorAlertSeverity.critical,
          ),
        )
        .toList(growable: false);

    return SupervisorInventoryAlerts(
      lowStockCount: data.alerts.lowStockCount,
      expiringCount: data.alerts.expiringSoonCount,
      criticalCount: data.alerts.expiredCount,
      outOfStockCount: data.alerts.outOfStockCount,
      expiredCount: data.alerts.expiredCount,
      critical: critical,
    );
  }

  static int _todayMovements(List<StockMovement> movements) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var count = 0;
    for (final m in movements) {
      final ts = m.timestamp;
      if (ts == null) continue;
      final day = DateTime(ts.year, ts.month, ts.day);
      if (day == today) count++;
    }
    return count;
  }

  static num _stockValue(StaffDashboardData data) {
    num total = 0;
    for (final item in data.inventoryItems) {
      final product = data.productsBySku[item.sku];
      final price = product?.unitPrice ?? 0;
      total += item.quantity * price;
    }
    return total;
  }
}
