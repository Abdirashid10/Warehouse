import 'package:flutter/foundation.dart';
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
import 'package:logisticsmobile/features/reports/presentation/cubit/reports_sample_data.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';

enum AnalyticsDatePreset { today, week, month, year, custom }

class ReportsAnalyticsCubit extends Cubit<ResourceState<ReportsAnalyticsBundle>> {
  ReportsAnalyticsCubit(this._repos) : super(const ResourceState.initial());

  final StaffRepositories _repos;

  /// Loads each analytics source independently.
  ///
  /// These eight endpoints do not share a permission level: `/api/users` is
  /// Admin-only, and reports / inventory-tracking require Supervisor or above,
  /// yet this screen is reachable by every role. Loading them in a single
  /// `Future.wait` meant one 403 rejected the whole batch, so a Supervisor saw
  /// "Failed to load analytics data" even though seven of eight calls had
  /// succeeded. Each source now degrades to an empty slice on its own.
  Future<void> load() async {
    emit(const ResourceState.loading());

    final unavailable = <String>[];

    Future<T> guard<T>(
      String label,
      Future<T> Function() fetch,
      T fallback,
    ) async {
      try {
        return await fetch();
      } on ApiException catch (e) {
        _log(label, ErrorMessageMapper.fromApiException(e));
        unavailable.add(label);
        return fallback;
      } catch (e) {
        _log(label, e.toString());
        unavailable.add(label);
        return fallback;
      }
    }

    final results = await Future.wait([
      guard('Reports', _repos.reports.loadReports, WmsReportsData.empty),
      guard('Products', _repos.products.getProducts, const <Product>[]),
      guard(
        'Inventory',
        _repos.inventory.getTracking,
        (items: const <InventoryItem>[], summary: _emptyInventorySummary),
      ),
      guard('Warehouses', _repos.warehouses.getWarehouses, const <Warehouse>[]),
      guard(
        'Orders',
        _repos.orders.getOrders,
        (orders: const <WarehouseOrder>[], stats: _emptyOrderStats),
      ),
      guard('Users', _repos.users.getUsers, const <WmsUser>[]),
      guard('Tasks', _repos.tasks.getTasks, const <WarehouseTask>[]),
      guard(
        'Movements',
        _repos.movements.getMovements,
        (movements: const <StockMovement>[], stats: _emptyMovementStats),
      ),
    ]);

    final bundle = ReportsAnalyticsBundle(
      reports: results[0] as WmsReportsData,
      products: results[1] as List<Product>,
      inventoryTracking: results[2]
          as ({List<InventoryItem> items, InventorySummary summary}),
      warehouses: results[3] as List<Warehouse>,
      orders: results[4] as ({List<WarehouseOrder> orders, OrderStats stats}),
      users: results[5] as List<WmsUser>,
      tasks: results[6] as List<WarehouseTask>,
      movements: results[7]
          as ({List<StockMovement> movements, MovementStats stats}),
      unavailableSources: List.unmodifiable(unavailable),
    );

    // Anything short of a total wipeout renders what did load, with a notice
    // naming the sections that are missing.
    if (unavailable.length < _sourceCount) {
      emit(ResourceState.success(bundle));
      return;
    }

    // Every source failed — the backend is unreachable rather than merely
    // permission-limited. Fall back to sample figures so the charts still
    // render, flagged so the UI can label them as not-real.
    if (useSampleDataWhenOffline) {
      emit(ResourceState.success(ReportsSampleData.build()));
      return;
    }

    emit(
      const ResourceState.failure(
        'Could not reach the analytics service. Pull to retry.',
      ),
    );
  }

  /// Whether to substitute sample figures when *every* source fails.
  ///
  /// Deliberately not silent: [ReportsAnalyticsBundle.isSampleData] is set so
  /// the screen shows a banner. Analytics that look real but are invented would
  /// be worse than an error card — someone could reorder stock against them.
  static const useSampleDataWhenOffline = bool.fromEnvironment(
    'REPORTS_SAMPLE_FALLBACK',
    defaultValue: true,
  );

  static const _sourceCount = 8;

  void _log(String label, String message) {
    if (kDebugMode) {
      debugPrint('[ReportsAnalytics] $label unavailable: $message');
    }
  }

  static const _emptyInventorySummary = InventorySummary(
    totalUnits: 0,
    inStock: 0,
    lowStock: 0,
    outOfStock: 0,
  );

  static const _emptyOrderStats = OrderStats(
    actionable: 0,
    processing: 0,
    packed: 0,
    shipped: 0,
  );

  static const _emptyMovementStats = MovementStats(
    total: 0,
    inbound: 0,
    outbound: 0,
    transfers: 0,
    adjustments: 0,
  );

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
    this.unavailableSources = const [],
    this.isSampleData = false,
  });

  /// Human-readable names of the slices that could not be loaded — usually
  /// because the signed-in role lacks access to that endpoint.
  final List<String> unavailableSources;

  /// True when these figures are illustrative rather than live. The screen
  /// must surface this to the user; see [ReportsSampleData].
  final bool isSampleData;

  bool get isPartial => unavailableSources.isNotEmpty;

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
