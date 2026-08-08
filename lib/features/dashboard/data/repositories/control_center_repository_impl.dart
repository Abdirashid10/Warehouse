import 'package:flutter/foundation.dart';
import 'package:logisticsmobile/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:logisticsmobile/features/dashboard/data/mappers/control_center_mapper.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/control_center_data.dart';
import 'package:logisticsmobile/features/dashboard/domain/repositories/control_center_repository.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/orders/domain/repositories/orders_repository.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/stock_operations/domain/repositories/movements_repository.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/domain/entities/supervisor_dashboard_data.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/domain/repositories/supervisor_dashboard_repository.dart';

class ControlCenterRepositoryImpl implements ControlCenterRepository {
  ControlCenterRepositoryImpl({
    required SupervisorDashboardRepository supervisorDashboard,
    required DashboardRemoteDataSource dashboardRemote,
    required OrdersRepository orders,
    required NotificationsRepository notifications,
    required MovementsRepository movements,
  })  : _supervisorDashboard = supervisorDashboard,
        _dashboardRemote = dashboardRemote,
        _orders = orders,
        _notifications = notifications,
        _movements = movements;

  final SupervisorDashboardRepository _supervisorDashboard;
  final DashboardRemoteDataSource _dashboardRemote;
  final OrdersRepository _orders;
  final NotificationsRepository _notifications;
  final MovementsRepository _movements;

  @override
  Future<ControlCenterData> load() async {
    final results = await Future.wait([
      _supervisorDashboard.loadDashboard(),
      _safeMap(_dashboardRemote.fetchStats),
      _safeMap(_dashboardRemote.fetchWidgets),
      _safeOrders(),
      _safeNotifications(),
      _safeMovements(),
    ]);

    final supervisor = results[0] as SupervisorDashboardData;
    final stats = results[1] as Map<String, dynamic>;
    final widgets = results[2] as Map<String, dynamic>;
    final orders = results[3] as List<WarehouseOrder>;
    final notifications = results[4] as List<AppNotification>;
    final movements = results[5] as List<StockMovement>;

    final insights = _dashboardRemote.parseInsights(widgets);
    final orderTrendFromApi = _dashboardRemote.parseOrderTrendSeries(stats) ??
        _dashboardRemote.parseOrderTrendSeries(widgets);
    final movementTrendFromApi =
        _dashboardRemote.parseMovementTrendSeries(stats) ??
            _dashboardRemote.parseMovementTrendSeries(widgets);

    if (kDebugMode) {
      debugPrint(
        '[ControlCenter] Backend sync — orders=${orders.length}, '
        'notifications=${notifications.length}, movements=${movements.length}, '
        'insights=${insights.length}, warehouses=${supervisor.warehouses.length}',
      );
    }

    return ControlCenterMapper.map(
      supervisor: supervisor,
      insights: insights,
      orders: orders,
      notifications: notifications,
      movements: movements,
      orderTrendFromApi: orderTrendFromApi,
      movementTrendFromApi: movementTrendFromApi,
    );
  }

  Future<Map<String, dynamic>> _safeMap(
    Future<Map<String, dynamic>> Function() action,
  ) async {
    try {
      return await action();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ControlCenter] Dashboard API section failed: $e\n$st');
      }
      return {};
    }
  }

  Future<List<WarehouseOrder>> _safeOrders() async {
    try {
      return (await _orders.getOrders()).orders;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ControlCenter] Orders API failed: $e\n$st');
      }
      return const [];
    }
  }

  Future<List<AppNotification>> _safeNotifications() async {
    try {
      return (await _notifications.getNotifications()).items;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ControlCenter] Notifications API failed: $e\n$st');
      }
      return const [];
    }
  }

  Future<List<StockMovement>> _safeMovements() async {
    try {
      return (await _movements.getMovements()).movements;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ControlCenter] Movements API failed: $e\n$st');
      }
      return const [];
    }
  }
}
