import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/reports/domain/entities/wms_reports_data.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';

enum AnalyticsDatePreset { today, week, month, year, custom }

class ReportsAnalyticsCubit extends Cubit<ResourceState<ReportsAnalyticsBundle>> {
  ReportsAnalyticsCubit(this._repos) : super(const ResourceState.initial());

  final StaffRepositories _repos;

  Future<void> load() async {
    emit(const ResourceState.loading());
    try {
      final results = await Future.wait([
        _repos.reports.loadReports(),
        _repos.products.getProducts(),
        _repos.inventory.getTracking(),
        _repos.warehouses.getWarehouses(),
        _repos.orders.getOrders(),
        _repos.users.getUsers(),
        _repos.tasks.getTasks(),
        _repos.movements.getMovements(),
      ]);

      emit(
        ResourceState.success(
          ReportsAnalyticsBundle(
            reports: results[0] as WmsReportsData,
            products: results[1] as List<Product>,
            inventoryTracking: results[2]
                as ({List<InventoryItem> items, InventorySummary summary}),
            warehouses: results[3] as List<Warehouse>,
            orders: results[4]
                as ({List<WarehouseOrder> orders, OrderStats stats}),
            users: results[5] as List<WmsUser>,
            tasks: results[6] as List<WarehouseTask>,
            movements: results[7]
                as ({List<StockMovement> movements, MovementStats stats}),
          ),
        ),
      );
    } on ApiException catch (e) {
      emit(ResourceState.failure(ErrorMessageMapper.fromApiException(e)));
    } catch (_) {
      emit(const ResourceState.failure('Failed to load analytics data'));
    }
  }

  Future<void> refresh() => load();
}

class ReportsAnalyticsBundle {
  const ReportsAnalyticsBundle({
    required this.reports,
    required this.products,
    required this.inventoryTracking,
    required this.warehouses,
    required this.orders,
    required this.users,
    required this.tasks,
    required this.movements,
  });

  final WmsReportsData reports;
  final List<Product> products;
  final ({List<InventoryItem> items, InventorySummary summary}) inventoryTracking;
  final List<Warehouse> warehouses;
  final ({List<WarehouseOrder> orders, OrderStats stats}) orders;
  final List<WmsUser> users;
  final List<WarehouseTask> tasks;
  final ({List<StockMovement> movements, MovementStats stats}) movements;

  int get expiringSoonCount {
    final threshold = DateTime.now().add(const Duration(days: 30));
    return inventoryTracking.items
        .where((i) => i.expiryDate != null && i.expiryDate!.isBefore(threshold))
        .length;
  }

  int get activeUsersCount =>
      users.where((u) => !u.archived && u.status.toLowerCase() == 'active').length;
}

class AnalyticsComputed {
  const AnalyticsComputed({
    required this.bundle,
    required this.filteredOrders,
    required this.filteredTasks,
    required this.filteredMovements,
    required this.rangeLabel,
    required this.rangeStart,
    required this.rangeEnd,
  });

  final ReportsAnalyticsBundle bundle;
  final List<WarehouseOrder> filteredOrders;
  final List<WarehouseTask> filteredTasks;
  final List<StockMovement> filteredMovements;
  final String rangeLabel;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  bool get hasAnyData =>
      bundle.products.isNotEmpty ||
      bundle.inventoryTracking.items.isNotEmpty ||
      bundle.warehouses.isNotEmpty ||
      bundle.orders.orders.isNotEmpty ||
      bundle.users.isNotEmpty ||
      bundle.tasks.isNotEmpty ||
      bundle.movements.movements.isNotEmpty;
}

abstract final class AnalyticsComputer {
  static AnalyticsComputed compute({
    required ReportsAnalyticsBundle bundle,
    required AnalyticsDatePreset preset,
    required DateTimeRange? customRange,
  }) {
    final now = DateTime.now();
    late DateTime start;
    var end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    late String label;

    switch (preset) {
      case AnalyticsDatePreset.today:
        start = DateTime(now.year, now.month, now.day);
        label = 'Today';
      case AnalyticsDatePreset.week:
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        label = 'This Week';
      case AnalyticsDatePreset.month:
        start = DateTime(now.year, now.month, 1);
        label = 'This Month';
      case AnalyticsDatePreset.year:
        start = DateTime(now.year, 1, 1);
        label = 'This Year';
      case AnalyticsDatePreset.custom:
        final range = customRange ??
            DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: end,
            );
        start = DateTime(range.start.year, range.start.month, range.start.day);
        end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
        label =
            '${AnalyticsDateFormatters.shortDate(start)} – ${AnalyticsDateFormatters.shortDate(end)}';
    }

    bool inRange(DateTime? dt) {
      if (dt == null) return false;
      return !dt.isBefore(start) && !dt.isAfter(end);
    }

    final filteredOrders =
        bundle.orders.orders.where((o) => inRange(o.createdAt)).toList();
    final filteredTasks = bundle.tasks
        .where((t) => inRange(t.createdAt ?? t.updatedAt ?? t.dueDate))
        .toList();
    final filteredMovements =
        bundle.movements.movements.where((m) => inRange(m.timestamp)).toList();

    return AnalyticsComputed(
      bundle: bundle,
      filteredOrders: filteredOrders,
      filteredTasks: filteredTasks,
      filteredMovements: filteredMovements,
      rangeLabel: label,
      rangeStart: start,
      rangeEnd: end,
    );
  }
}

abstract final class AnalyticsDateFormatters {
  static String shortDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  static String monthKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

  static String dayKey(DateTime dt) => '${dt.month}/${dt.day}';
}
