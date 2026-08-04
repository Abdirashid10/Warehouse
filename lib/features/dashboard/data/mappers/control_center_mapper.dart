import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/constants/wms/order_constants.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/control_center_data.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/dashboard_enterprise_widgets.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/domain/entities/supervisor_dashboard_data.dart';

abstract final class ControlCenterMapper {
  static ControlCenterData map({
    required SupervisorDashboardData supervisor,
    required List<DashboardInsight> insights,
    required List<WarehouseOrder> orders,
    required List<AppNotification> notifications,
    required List<StockMovement> movements,
    DashboardChartTimeSeries? orderTrendFromApi,
    DashboardChartTimeSeries? movementTrendFromApi,
  }) {
    final sortedOrders = List<WarehouseOrder>.from(orders)
      ..sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });

    final sortedNotifications = List<AppNotification>.from(notifications)
      ..sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });

    final sortedMovements = List<StockMovement>.from(movements)
      ..sort((a, b) {
        final at = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });

    return ControlCenterData(
      supervisor: supervisor,
      insights: insights,
      recentOrders: sortedOrders.take(8).toList(),
      recentNotifications: sortedNotifications.take(6).toList(),
      recentMovements: sortedMovements.take(10).toList(),
      orderStatusCounts: _orderStatusCounts(supervisor, orders),
      pendingOrders: _pendingOrderCount(supervisor, orders),
      movementTrend: movementTrendFromApi ?? movementTrendFrom(movements),
      orderTrend: orderTrendFromApi ?? orderTrendFrom(orders),
    );
  }

  static int _pendingOrderCount(
    SupervisorDashboardData supervisor,
    List<WarehouseOrder> orders,
  ) {
    var pending = 0;
    for (final order in orders) {
      final status = order.status.toLowerCase();
      if (status.contains('pending')) pending++;
    }
    if (pending > 0) return pending;
    return supervisor.orderMonitoring.processing;
  }

  static DashboardChartTimeSeries movementTrendFrom(
    List<StockMovement> movements,
  ) =>
      _movementTrend(movements);

  static DashboardChartTimeSeries orderTrendFrom(List<WarehouseOrder> orders) =>
      _orderTrend(orders);

  static List<ControlCenterOrderStatus> orderStatusCountsFromOrders(
    List<WarehouseOrder> orders,
  ) {
    final counts = <String, int>{};
    for (final order in orders) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }

    const order = [
      WmsOrderStatuses.pending,
      WmsOrderStatuses.processing,
      WmsOrderStatuses.packed,
      WmsOrderStatuses.shipped,
      WmsOrderStatuses.delivered,
    ];

    final result = <ControlCenterOrderStatus>[];
    for (final status in order) {
      final match = counts.entries.where(
        (e) => e.key.toLowerCase() == status.toLowerCase(),
      );
      if (match.isEmpty) {
        result.add(ControlCenterOrderStatus(label: status, count: 0));
      } else {
        result.add(
          ControlCenterOrderStatus(label: status, count: match.first.value),
        );
      }
    }

    for (final entry in counts.entries) {
      if (order.any((s) => s.toLowerCase() == entry.key.toLowerCase())) {
        continue;
      }
      result.add(ControlCenterOrderStatus(label: entry.key, count: entry.value));
    }
    return result;
  }

  static List<ControlCenterOrderStatus> _orderStatusCounts(
    SupervisorDashboardData supervisor,
    List<WarehouseOrder> orders,
  ) {
    final counts = orderStatusCountsFromOrders(orders);
    if (counts.any((c) => c.count > 0)) return counts;

    final m = supervisor.orderMonitoring;
    return [
      const ControlCenterOrderStatus(
        label: WmsOrderStatuses.pending,
        count: 0,
      ),
      ControlCenterOrderStatus(
        label: WmsOrderStatuses.processing,
        count: m.processing,
      ),
      ControlCenterOrderStatus(
        label: WmsOrderStatuses.packed,
        count: m.packed,
      ),
      ControlCenterOrderStatus(
        label: WmsOrderStatuses.shipped,
        count: m.shipped,
      ),
      ControlCenterOrderStatus(
        label: WmsOrderStatuses.delivered,
        count: m.delivered,
      ),
    ];
  }

  static DashboardChartTimeSeries _movementTrend(List<StockMovement> movements) {
    final labels = StaffDashboardMetrics.last7DayLabels();
    final inbound = List<double>.filled(7, 0);
    final outbound = List<double>.filled(7, 0);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final m in movements) {
      final ts = m.timestamp;
      if (ts == null) continue;
      final day = DateTime(ts.year, ts.month, ts.day);
      final diff = today.difference(day).inDays;
      if (diff < 0 || diff > 6) continue;
      final index = 6 - diff;
      final type = m.type.toUpperCase();
      if (type.contains('IN') || type == 'RECEIVE' || type == 'INBOUND') {
        inbound[index] += m.quantity.toDouble().abs();
      } else if (type.contains('OUT') ||
          type == 'DISPATCH' ||
          type == 'OUTBOUND') {
        outbound[index] += m.quantity.toDouble().abs();
      }
    }

    return DashboardChartTimeSeries(
      labels: labels,
      lines: [
        DashboardChartLine(
          label: 'Inbound',
          color: AppColors.success,
          values: inbound,
        ),
        DashboardChartLine(
          label: 'Outbound',
          color: const Color(0xFFC2410C),
          values: outbound,
        ),
      ],
    );
  }

  static DashboardChartTimeSeries _orderTrend(List<WarehouseOrder> orders) {
    final labels = StaffDashboardMetrics.last7DayLabels();
    final created = List<double>.filled(7, 0);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final order in orders) {
      final ts = order.createdAt;
      if (ts == null) continue;
      final day = DateTime(ts.year, ts.month, ts.day);
      final diff = today.difference(day).inDays;
      if (diff < 0 || diff > 6) continue;
      created[6 - diff] += 1;
    }

    return DashboardChartTimeSeries(
      labels: labels,
      lines: [
        DashboardChartLine(
          label: 'Orders',
          color: AppColors.primary,
          values: created,
        ),
      ],
    );
  }
}
