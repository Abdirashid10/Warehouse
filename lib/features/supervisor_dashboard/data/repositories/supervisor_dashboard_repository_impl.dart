import 'package:logisticsmobile/core/constants/wms/order_constants.dart';
import 'package:logisticsmobile/core/utils/warehouse_staff_count.dart';
import 'package:logisticsmobile/features/profile/domain/entities/user_profile.dart';
import 'package:logisticsmobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/data/datasources/supervisor_dashboard_remote_data_source.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/domain/entities/supervisor_dashboard_data.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/domain/repositories/supervisor_dashboard_repository.dart';

class SupervisorDashboardRepositoryImpl implements SupervisorDashboardRepository {
  SupervisorDashboardRepositoryImpl({
    required SupervisorDashboardRemoteDataSource remote,
    required ProfileRepository profileRepository,
  })  : _remote = remote,
        _profileRepository = profileRepository;

  final SupervisorDashboardRemoteDataSource _remote;
  final ProfileRepository _profileRepository;

  @override
  Future<SupervisorDashboardData> loadDashboard() async {
    final results = await Future.wait([
      _remote.fetchStats(),
      _remote.fetchWidgets(),
      _profileRepository.getProfile(),
      _remote.fetchWarehouses(),
      _remote.fetchTeamActivities(limit: 20),
    ]);

    final stats = results[0] as Map<String, dynamic>;
    final widgets = results[1] as Map<String, dynamic>;
    final profile = results[2] as UserProfile;
    final warehouseMaps = results[3] as List<Map<String, dynamic>>;
    final auditActivities = results[4] as List<Map<String, dynamic>>;

    return SupervisorDashboardData(
      profile: _mapProfile(profile),
      kpis: _mapKpis(stats, widgets),
      warehouses: _mapWarehouses(
        warehouseMaps,
        widgets,
        profile.assignedWarehouses,
      ),
      teamActivities: _mapTeamActivities(auditActivities, stats),
      taskMonitoring: _mapTaskMonitoring(widgets),
      orderMonitoring: _mapOrderMonitoring(stats),
      inventoryAlerts: _mapInventoryAlerts(widgets),
    );
  }

  SupervisorProfileSummary _mapProfile(UserProfile profile) {
    return SupervisorProfileSummary(
      fullName: profile.fullName,
      email: profile.email,
      role: profile.role,
      assignedWarehouses: profile.assignedWarehouses,
    );
  }

  SupervisorKpiSummary _mapKpis(
    Map<String, dynamic> stats,
    Map<String, dynamic> widgets,
  ) {
    final taskSummary = widgets['taskSummary'] ?? widgets['task_summary'];
    final alerts = widgets['alerts'];
    var overdue = 0;
    if (taskSummary is Map<String, dynamic>) {
      overdue = _asInt(taskSummary['overdue']);
    }
    if (overdue == 0 && alerts is Map<String, dynamic>) {
      overdue = _asInt(alerts['overdueTaskCount'] ?? alerts['overdue_task_count']);
    }

    final inventorySummary =
        stats['inventorySummary'] ?? stats['inventory_summary'];
    var inStockLines = 0;
    var outOfStockLines = 0;
    if (inventorySummary is Map<String, dynamic>) {
      inStockLines = _asInt(
        inventorySummary['in_stock'] ?? inventorySummary['inStock'],
      );
      outOfStockLines = _asInt(
        inventorySummary['out_of_stock'] ?? inventorySummary['outOfStock'],
      );
    }
    if (inStockLines == 0) {
      inStockLines = _asInt(
        stats['inStockLineCount'] ?? stats['in_stock_line_count'],
      );
    }
    if (outOfStockLines == 0) {
      outOfStockLines = _asInt(
        stats['outOfStockLineCount'] ?? stats['out_of_stock_line_count'],
      );
    }

    return SupervisorKpiSummary(
      totalStockValue:
          stats['totalStockValue'] ?? stats['total_stock_value'] ?? 0,
      totalUnitsOnHand:
          stats['totalUnitsOnHand'] ?? stats['total_units_on_hand'] ?? 0,
      lowStockProducts: _asInt(
        stats['lowStockProductCount'] ??
            stats['lowStockLineCount'] ??
            stats['low_stock_line_count'],
      ),
      totalOrders: _asInt(stats['totalOrders'] ?? stats['total_orders']),
      stockMovementsToday: _asInt(
        stats['todayMovementsCount'] ?? stats['today_movements_count'],
      ),
      overdueTasks: overdue,
      inStockLines: inStockLines,
      outOfStockLines: outOfStockLines,
    );
  }

  List<SupervisorWarehouseOverview> _mapWarehouses(
    List<Map<String, dynamic>> warehouseMaps,
    Map<String, dynamic> widgets,
    List<String> assignedNames,
  ) {
    final statsById = <String, Map<String, dynamic>>{};
    final rawStats = widgets['warehouseStats'] ?? widgets['warehouse_stats'];
    if (rawStats is List) {
      for (final w in rawStats.whereType<Map<String, dynamic>>()) {
        final id = (w['id'] ?? w['_id'] ?? '').toString();
        if (id.isNotEmpty) statsById[id] = w;
      }
    }

    final assigned = assignedNames.map((n) => n.trim().toLowerCase()).toSet();
    final filterByAssignment = assigned.isNotEmpty;

    final overviews = <SupervisorWarehouseOverview>[];
    for (final w in warehouseMaps) {
      final id = (w['_id'] ?? w['id'] ?? '').toString();
      final name = (w['name'] ?? '').toString();
      if (name.isEmpty) continue;
      if (filterByAssignment && !assigned.contains(name.trim().toLowerCase())) {
        continue;
      }

      final perf = statsById[id];
      final stockCount = _asInt(perf?['totalUnits'] ?? perf?['total_units']);
      final utilization = _asInt(perf?['utilization']);
      final staffCount = resolveWarehouseStaffCount(
        staffCountFromApi: w['staff_count'] ?? w['staffCount'],
        assignedStaffRaw: w['assigned_staff'] ?? w['assignedStaff'],
      );
      overviews.add(
        SupervisorWarehouseOverview(
          id: id,
          name: name,
          stockCount: stockCount,
          activeStaffCount: staffCount,
          status: _warehouseStatus(utilization),
          location: (w['location'] ?? perf?['location'])?.toString(),
          utilizationPercent: utilization > 0 ? utilization : null,
        ),
      );
    }

    if (overviews.isEmpty && rawStats is List) {
      for (final w in rawStats.whereType<Map<String, dynamic>>()) {
        final name = (w['name'] ?? '').toString();
        if (name.isEmpty) continue;
        if (filterByAssignment && !assigned.contains(name.trim().toLowerCase())) {
          continue;
        }
        final utilization = _asInt(w['utilization']);
        overviews.add(
          SupervisorWarehouseOverview(
            id: (w['id'] ?? w['_id'] ?? name).toString(),
            name: name,
            stockCount: _asInt(w['totalUnits'] ?? w['total_units']),
            activeStaffCount: 0,
            status: _warehouseStatus(utilization),
            location: w['location']?.toString(),
            utilizationPercent: utilization > 0 ? utilization : null,
          ),
        );
      }
    }

    overviews.sort((a, b) => b.stockCount.compareTo(a.stockCount));
    return overviews;
  }

  String _warehouseStatus(int utilization) {
    if (utilization >= 85) return 'High load';
    if (utilization >= 50) return 'Active';
    return 'Active';
  }

  List<SupervisorTeamActivity> _mapTeamActivities(
    List<Map<String, dynamic>> auditLogs,
    Map<String, dynamic> stats,
  ) {
    final activities = <SupervisorTeamActivity>[];
    final seen = <String>{};

    for (final log in auditLogs) {
      final id = (log['id'] ?? log['_id'] ?? '').toString();
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);

      final actor = log['actor'];
      var userName = 'Staff';
      if (actor is Map) {
        userName = (actor['fullName'] ??
                actor['full_name'] ??
                actor['username'] ??
                'Staff')
            .toString();
      }

      final module = (log['module'] ?? '').toString();
      final action = (log['action'] ?? '').toString();
      final details = (log['details'] ?? '').toString();
      final actionText = [
        if (module.isNotEmpty) module,
        if (action.isNotEmpty) action,
        if (details.isNotEmpty) details,
      ].join(' · ');

      activities.add(
        SupervisorTeamActivity(
          id: id,
          userName: userName,
          action: actionText.isEmpty ? 'Activity logged' : actionText,
          occurredAt: DateTime.tryParse(
            (log['createdAt'] ?? log['created_at'] ?? '').toString(),
          ),
        ),
      );
    }

    final feed = stats['activityFeed'] ?? stats['activity_feed'];
    if (feed is List) {
      for (final item in feed.whereType<Map<String, dynamic>>()) {
        if (activities.length >= 20) break;
        final id = (item['id'] ?? item['_id'] ?? '').toString();
        if (id.isEmpty || seen.contains('m-$id')) continue;
        seen.add('m-$id');

        final createdBy = item['created_by'] ?? item['createdBy'];
        var userName = 'Staff';
        if (createdBy is Map) {
          userName = (createdBy['name'] ??
                  createdBy['fullName'] ??
                  createdBy['username'] ??
                  'Staff')
              .toString();
        }

        final type = (item['type'] ?? '').toString();
        final qty = item['quantity'] ?? item['signed_quantity'];
        final product = item['product'];
        var productName = '';
        if (product is Map) {
          productName = (product['name'] ?? '').toString();
        }
        final action = [
          if (type.isNotEmpty) type,
          if (qty != null) '$qty units',
          if (productName.isNotEmpty) productName,
        ].join(' · ');

        activities.add(
          SupervisorTeamActivity(
            id: 'm-$id',
            userName: userName,
            action: action.isEmpty ? 'Stock movement' : action,
            occurredAt: DateTime.tryParse(
              (item['timestamp'] ??
                      item['createdAt'] ??
                      item['created_at'] ??
                      '')
                  .toString(),
            ),
          ),
        );
      }
    }

    activities.sort((a, b) {
      final at = a.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });

    return activities.take(20).toList();
  }

  SupervisorTaskMonitoring _mapTaskMonitoring(Map<String, dynamic> widgets) {
    final taskSummary = widgets['taskSummary'] ?? widgets['task_summary'];
    if (taskSummary is! Map<String, dynamic>) {
      return const SupervisorTaskMonitoring(
        pending: 0,
        inProgress: 0,
        waitingConfirmation: 0,
        completed: 0,
      );
    }

    final pending = _asInt(taskSummary['pending']) +
        _asInt(taskSummary['accepted']);
    return SupervisorTaskMonitoring(
      pending: pending,
      inProgress: _asInt(taskSummary['inProgress'] ?? taskSummary['in_progress']),
      waitingConfirmation: _asInt(
        taskSummary['waitingConfirmation'] ??
            taskSummary['waiting_confirmation'],
      ),
      completed: _asInt(taskSummary['completed']),
    );
  }

  SupervisorOrderMonitoring _mapOrderMonitoring(Map<String, dynamic> stats) {
    final raw = stats['ordersByStatus'] ?? stats['orders_by_status'];
    if (raw is! Map) {
      return const SupervisorOrderMonitoring(
        processing: 0,
        packed: 0,
        shipped: 0,
        delivered: 0,
      );
    }

    int countFor(String status) {
      final value = raw[status];
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return SupervisorOrderMonitoring(
      processing: countFor(WmsOrderStatuses.processing),
      packed: countFor(WmsOrderStatuses.packed),
      shipped: countFor(WmsOrderStatuses.shipped),
      delivered: countFor(WmsOrderStatuses.delivered),
    );
  }

  SupervisorInventoryAlerts _mapInventoryAlerts(Map<String, dynamic> widgets) {
    final alerts = widgets['alerts'];
    if (alerts is! Map<String, dynamic>) {
      return const SupervisorInventoryAlerts();
    }

    final lowStock = _mapAlertItems(
      alerts['lowStockItems'] ?? alerts['low_stock_items'],
      SupervisorAlertSeverity.warning,
    );
    final expiring = _mapAlertItems(
      alerts['expiringSoonItems'] ?? alerts['expiring_soon_items'],
      SupervisorAlertSeverity.warning,
      detailKey: 'daysLeft',
    );
    final critical = <SupervisorInventoryAlertItem>[
      ..._mapAlertItems(
        alerts['outOfStockItems'] ?? alerts['out_of_stock_items'],
        SupervisorAlertSeverity.critical,
      ),
      ..._mapAlertItems(
        alerts['expiredItems'] ?? alerts['expired_items'],
        SupervisorAlertSeverity.critical,
        detailKey: 'expiryDate',
      ),
    ];

    final outOfStockCount =
        _asInt(alerts['outOfStockCount'] ?? alerts['out_of_stock_count']);
    final expiredCount =
        _asInt(alerts['expiredCount'] ?? alerts['expired_count']);

    return SupervisorInventoryAlerts(
      lowStock: lowStock,
      expiring: expiring,
      critical: critical,
      lowStockCount: _asInt(alerts['lowStockCount'] ?? alerts['low_stock_count']),
      expiringCount:
          _asInt(alerts['expiringSoonCount'] ?? alerts['expiring_soon_count']),
      criticalCount: outOfStockCount + expiredCount,
      outOfStockCount: outOfStockCount,
      expiredCount: expiredCount,
    );
  }

  List<SupervisorInventoryAlertItem> _mapAlertItems(
    dynamic raw,
    SupervisorAlertSeverity severity, {
    String? detailKey,
  }) {
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map((item) {
      final detail = detailKey != null ? item[detailKey]?.toString() : null;
      return SupervisorInventoryAlertItem(
        productName: (item['product'] ?? '—').toString(),
        sku: (item['sku'] ?? '—').toString(),
        warehouseName: (item['warehouse'] ?? '—').toString(),
        quantity: item['quantity'] as num?,
        detail: detail,
        severity: severity,
      );
    }).toList();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
