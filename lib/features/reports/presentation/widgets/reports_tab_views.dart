import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/constants/wms/movement_constants.dart';
import 'package:logisticsmobile/core/constants/wms/order_constants.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/features/reports/presentation/cubit/reports_analytics_cubit.dart';
import 'package:logisticsmobile/features/reports/presentation/widgets/reports_premium_atoms.dart';
import 'package:logisticsmobile/features/reports/presentation/widgets/reports_premium_charts.dart';
import 'package:logisticsmobile/features/reports/presentation/widgets/reports_premium_theme.dart';

/// Actions an analytics tab can offer when it has nothing to show.
class ReportsTabActions {
  const ReportsTabActions({
    required this.onWidenPeriod,
    required this.onRefresh,
  });

  /// Broadens the reporting window to the full year.
  final VoidCallback onWidenPeriod;
  final Future<void> Function() onRefresh;
}

/// Turns `in_stock` / `IN-PROGRESS` into `In Stock` / `In Progress`.
String humanizeKey(String raw) {
  if (raw.trim().isEmpty) return 'Unknown';
  final words = raw.replaceAll(RegExp(r'[_\-]+'), ' ').trim().split(' ');
  return [
    for (final word in words)
      if (word.isNotEmpty)
        '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
  ].join(' ');
}

/// Scrollable body shared by every analytics tab.
class ReportsTabScroll extends StatelessWidget {
  const ReportsTabScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xxxl,
      ),
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => children[index],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inventory
// ─────────────────────────────────────────────────────────────────────────────

class ReportsInventoryTab extends StatelessWidget {
  const ReportsInventoryTab({
    super.key,
    required this.computed,
    required this.actions,
  });

  final AnalyticsComputed computed;
  final ReportsTabActions actions;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final items = computed.bundle.inventoryTracking.items;

    if (items.isEmpty) {
      return ReportsEmptyState(
        title: 'No inventory analytics',
        message:
            'Stock lines will appear here as soon as inventory is recorded '
            'against your warehouses.',
        actions: [
          ReportsEmptyAction(
            label: 'Refresh data',
            icon: Icons.refresh_rounded,
            onPressed: actions.onRefresh,
            primary: true,
          ),
        ],
      );
    }

    final byWarehouse = <String, double>{};
    final byStatus = <String, double>{};
    for (final item in items) {
      byWarehouse[item.warehouseName] =
          (byWarehouse[item.warehouseName] ?? 0) + item.quantity.toDouble();
      final status = humanizeKey(item.stockStatus);
      byStatus[status] = (byStatus[status] ?? 0) + 1;
    }

    final byCategory = <String, double>{};
    for (final product in computed.bundle.products) {
      final key = product.category?.isNotEmpty == true
          ? product.category!
          : 'Uncategorized';
      byCategory[key] = (byCategory[key] ?? 0) + 1;
    }

    final summary = computed.bundle.inventoryTracking.summary;

    return ReportsTabScroll(
      children: [
        ReportsChartCard(
          title: 'Stock by Warehouse',
          subtitle: 'Units on hand per facility',
          icon: Icons.warehouse_rounded,
          accent: palette.accent(ReportsAccent.sky),
          child: ReportsRankedBars(
            data: ReportsSeries.fold(byWarehouse.entries),
          ),
        ),
        ReportsChartCard(
          title: 'Inventory Distribution',
          subtitle: 'Stock lines by status',
          icon: Icons.donut_large_rounded,
          accent: palette.accent(ReportsAccent.indigo),
          child: ReportsDonutChart(
            data: ReportsSeries.fold(byStatus.entries),
            centerLabel: 'stock lines',
          ),
        ),
        ReportsChartCard(
          title: 'Stock by Category',
          subtitle: 'Product catalogue mix',
          icon: Icons.category_rounded,
          accent: palette.accent(ReportsAccent.violet),
          child: ReportsDonutChart(
            data: ReportsSeries.fold(byCategory.entries),
            centerLabel: 'products',
          ),
        ),
        ReportsChartCard(
          title: 'Low Stock Exposure',
          subtitle: 'Replenishment pressure across the catalogue',
          icon: Icons.warning_amber_rounded,
          accent: palette.accent(ReportsAccent.amber),
          child: ReportsRankedBars(
            data: [
              ReportsDatum(
                label: 'In stock',
                value: summary.inStock.toDouble(),
              ),
              ReportsDatum(
                label: 'Low stock',
                value: summary.lowStock.toDouble(),
              ),
              ReportsDatum(
                label: 'Out of stock',
                value: summary.outOfStock.toDouble(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Orders
// ─────────────────────────────────────────────────────────────────────────────

class ReportsOrdersTab extends StatelessWidget {
  const ReportsOrdersTab({
    super.key,
    required this.computed,
    required this.actions,
  });

  final AnalyticsComputed computed;
  final ReportsTabActions actions;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final orders = computed.filteredOrders;

    if (orders.isEmpty) {
      return ReportsEmptyState(
        title: 'No orders in ${computed.rangeLabel}',
        message:
            'Nothing was created inside the selected reporting window. Widen '
            'the period or refresh to pull the latest activity.',
        actions: [
          ReportsEmptyAction(
            label: 'Widen to this year',
            icon: Icons.calendar_month_rounded,
            onPressed: actions.onWidenPeriod,
            primary: true,
          ),
          ReportsEmptyAction(
            label: 'Refresh',
            icon: Icons.refresh_rounded,
            onPressed: actions.onRefresh,
          ),
        ],
      );
    }

    final byStatus = <String, double>{};
    final byMonth = <DateTime, double>{};
    final byDay = <DateTime, double>{};
    for (final order in orders) {
      final status = humanizeKey(order.status);
      byStatus[status] = (byStatus[status] ?? 0) + 1;
      final createdAt = order.createdAt;
      if (createdAt != null) {
        final month = _monthBucket(createdAt);
        final day = _dayBucket(createdAt);
        byMonth[month] = (byMonth[month] ?? 0) + 1;
        byDay[day] = (byDay[day] ?? 0) + 1;
      }
    }

    final delivered = byStatus[humanizeKey(WmsOrderStatuses.delivered)] ?? 0;
    final pending = orders.length - delivered;

    return ReportsTabScroll(
      children: [
        ReportsChartCard(
          title: 'Orders by Status',
          subtitle: 'Pipeline composition for ${computed.rangeLabel}',
          icon: Icons.donut_large_rounded,
          accent: palette.accent(ReportsAccent.indigo),
          child: ReportsDonutChart(
            data: ReportsSeries.fold(byStatus.entries),
            centerLabel: 'orders',
          ),
        ),
        ReportsChartCard(
          title: 'Daily Throughput',
          subtitle: 'Orders created per day',
          icon: Icons.show_chart_rounded,
          accent: palette.accent(ReportsAccent.sky),
          child: ReportsTrendLine(
            data: _timeSeries(byDay, _dayLabel),
            seriesLabel: 'orders',
          ),
        ),
        ReportsChartCard(
          title: 'Monthly Volume',
          subtitle: 'Order counts by month',
          icon: Icons.stacked_line_chart_rounded,
          accent: palette.accent(ReportsAccent.emerald),
          child: ReportsTrendLine(
            data: _timeSeries(byMonth, _monthLabel),
            seriesLabel: 'orders',
          ),
        ),
        ReportsChartCard(
          title: 'Fulfilment Ratio',
          subtitle: 'Delivered against everything still open',
          icon: Icons.local_shipping_rounded,
          accent: palette.accent(ReportsAccent.emerald),
          child: ReportsDonutChart(
            data: [
              ReportsDatum(label: 'Delivered', value: delivered),
              ReportsDatum(label: 'Open', value: pending.toDouble()),
            ],
            centerLabel: 'orders',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Warehouse
// ─────────────────────────────────────────────────────────────────────────────

class ReportsWarehouseTab extends StatelessWidget {
  const ReportsWarehouseTab({
    super.key,
    required this.computed,
    required this.actions,
  });

  final AnalyticsComputed computed;
  final ReportsTabActions actions;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final warehouses = computed.bundle.warehouses;

    if (warehouses.isEmpty) {
      return ReportsEmptyState(
        title: 'No warehouse analytics',
        message:
            'Capacity, staffing and activity metrics appear once warehouse '
            'records are available to your account.',
        actions: [
          ReportsEmptyAction(
            label: 'Refresh data',
            icon: Icons.refresh_rounded,
            onPressed: actions.onRefresh,
            primary: true,
          ),
        ],
      );
    }

    final inventoryByWarehouse = <String, double>{};
    for (final item in computed.bundle.inventoryTracking.items) {
      inventoryByWarehouse[item.warehouseName] =
          (inventoryByWarehouse[item.warehouseName] ?? 0) +
              item.quantity.toDouble();
    }

    final capacityUsage = <String, double>{};
    for (final warehouse in warehouses) {
      final used = inventoryByWarehouse[warehouse.name] ?? 0;
      capacityUsage[warehouse.name] = warehouse.capacity > 0
          ? (used / warehouse.capacity * 100).clamp(0, 100).toDouble()
          : 0;
    }

    final staffDistribution = {
      for (final warehouse in warehouses)
        warehouse.name: warehouse.staffCount.toDouble(),
    };

    final activity = <String, double>{
      for (final warehouse in warehouses) warehouse.name: 0,
    };
    for (final movement in computed.filteredMovements) {
      for (final location in [movement.fromLocation, movement.toLocation]) {
        if (location != null && activity.containsKey(location)) {
          activity[location] = activity[location]! + 1;
        }
      }
    }

    return ReportsTabScroll(
      children: [
        ReportsChartCard(
          title: 'Capacity Usage',
          subtitle: 'Share of each facility already filled',
          icon: Icons.speed_rounded,
          accent: palette.accent(ReportsAccent.amber),
          child: ReportsRankedBars(
            data: ReportsSeries.fold(capacityUsage.entries),
            valueSuffix: '%',
            maxValueOverride: 100,
          ),
        ),
        ReportsChartCard(
          title: 'Inventory per Warehouse',
          subtitle: 'Units held by facility',
          icon: Icons.inventory_2_rounded,
          accent: palette.accent(ReportsAccent.sky),
          child: ReportsRankedBars(
            data: ReportsSeries.fold(inventoryByWarehouse.entries),
          ),
        ),
        ReportsChartCard(
          title: 'Staff Distribution',
          subtitle: 'Assigned head-count by facility',
          icon: Icons.groups_rounded,
          accent: palette.accent(ReportsAccent.violet),
          child: ReportsDonutChart(
            data: ReportsSeries.fold(staffDistribution.entries),
            centerLabel: 'staff',
          ),
        ),
        ReportsChartCard(
          title: 'Warehouse Activity',
          subtitle: 'Movements touching each facility · ${computed.rangeLabel}',
          icon: Icons.sync_alt_rounded,
          accent: palette.accent(ReportsAccent.emerald),
          child: ReportsRankedBars(
            data: ReportsSeries.fold(activity.entries),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stock movements
// ─────────────────────────────────────────────────────────────────────────────

class ReportsMovementsTab extends StatelessWidget {
  const ReportsMovementsTab({
    super.key,
    required this.computed,
    required this.actions,
  });

  final AnalyticsComputed computed;
  final ReportsTabActions actions;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final movements = computed.filteredMovements;

    if (movements.isEmpty) {
      return ReportsEmptyState(
        title: 'No movements in ${computed.rangeLabel}',
        message:
            'No stock moved inside the selected window. Widen the period to '
            'see historical inbound, outbound and transfer activity.',
        actions: [
          ReportsEmptyAction(
            label: 'Widen to this year',
            icon: Icons.calendar_month_rounded,
            onPressed: actions.onWidenPeriod,
            primary: true,
          ),
          ReportsEmptyAction(
            label: 'Refresh',
            icon: Icons.refresh_rounded,
            onPressed: actions.onRefresh,
          ),
        ],
      );
    }

    final byType = <String, double>{};
    final daily = <DateTime, double>{};
    final monthly = <DateTime, double>{};
    final transferDaily = <DateTime, double>{};
    for (final movement in movements) {
      byType[movement.type] = (byType[movement.type] ?? 0) + 1;
      final timestamp = movement.timestamp;
      if (timestamp == null) continue;
      final day = _dayBucket(timestamp);
      final month = _monthBucket(timestamp);
      daily[day] = (daily[day] ?? 0) + 1;
      monthly[month] = (monthly[month] ?? 0) + 1;
      if (movement.type == WmsMovementTypes.transfer) {
        transferDaily[day] = (transferDaily[day] ?? 0) + 1;
      }
    }

    return ReportsTabScroll(
      children: [
        ReportsChartCard(
          title: 'Flow Direction',
          subtitle: 'Inbound against outbound for ${computed.rangeLabel}',
          icon: Icons.swap_vert_rounded,
          accent: palette.accent(ReportsAccent.indigo),
          child: ReportsDonutChart(
            data: [
              ReportsDatum(
                label: 'Inbound',
                value: byType[WmsMovementTypes.inbound] ?? 0,
              ),
              ReportsDatum(
                label: 'Outbound',
                value: byType[WmsMovementTypes.outbound] ?? 0,
              ),
              ReportsDatum(
                label: 'Transfers',
                value: byType[WmsMovementTypes.transfer] ?? 0,
              ),
            ].where((d) => d.value > 0).toList(),
            centerLabel: 'movements',
          ),
        ),
        ReportsChartCard(
          title: 'Daily Movements',
          subtitle: 'All stock movements per day',
          icon: Icons.show_chart_rounded,
          accent: palette.accent(ReportsAccent.sky),
          child: ReportsTrendLine(
            data: _timeSeries(daily, _dayLabel),
            seriesLabel: 'movements',
          ),
        ),
        ReportsChartCard(
          title: 'Transfer Activity',
          subtitle: 'Inter-warehouse transfers per day',
          icon: Icons.compare_arrows_rounded,
          accent: palette.accent(ReportsAccent.emerald),
          child: ReportsTrendLine(
            data: _timeSeries(transferDaily, _dayLabel),
            seriesLabel: 'transfers',
          ),
        ),
        ReportsChartCard(
          title: 'Monthly Trend',
          subtitle: 'Movement volume by month',
          icon: Icons.stacked_line_chart_rounded,
          accent: palette.accent(ReportsAccent.violet),
          child: ReportsTrendLine(
            data: _timeSeries(monthly, _monthLabel),
            seriesLabel: 'movements',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tasks
// ─────────────────────────────────────────────────────────────────────────────

class ReportsTasksTab extends StatelessWidget {
  const ReportsTasksTab({
    super.key,
    required this.computed,
    required this.actions,
  });

  final AnalyticsComputed computed;
  final ReportsTabActions actions;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final tasks = computed.filteredTasks;

    if (tasks.isEmpty) {
      return ReportsEmptyState(
        title: 'No tasks in ${computed.rangeLabel}',
        message:
            'Task analytics cover work created, updated or due inside the '
            'selected window.',
        actions: [
          ReportsEmptyAction(
            label: 'Widen to this year',
            icon: Icons.calendar_month_rounded,
            onPressed: actions.onWidenPeriod,
            primary: true,
          ),
          ReportsEmptyAction(
            label: 'Refresh',
            icon: Icons.refresh_rounded,
            onPressed: actions.onRefresh,
          ),
        ],
      );
    }

    final byStatus = <String, double>{};
    final staffPerformance = <String, double>{};
    var completed = 0.0;
    var overdue = 0.0;

    for (final task in tasks) {
      final status = humanizeKey(task.status);
      byStatus[status] = (byStatus[status] ?? 0) + 1;
      if (task.status == WmsTaskStatuses.completed) {
        completed += 1;
        final assignee = task.assignedToName?.isNotEmpty == true
            ? task.assignedToName!
            : 'Unassigned';
        staffPerformance[assignee] = (staffPerformance[assignee] ?? 0) + 1;
      }
      if (task.status == WmsTaskStatuses.overdue) overdue += 1;
    }

    return ReportsTabScroll(
      children: [
        ReportsChartCard(
          title: 'Tasks by Status',
          subtitle: 'Workload composition for ${computed.rangeLabel}',
          icon: Icons.donut_large_rounded,
          accent: palette.accent(ReportsAccent.indigo),
          child: ReportsDonutChart(
            data: ReportsSeries.fold(byStatus.entries),
            centerLabel: 'tasks',
          ),
        ),
        ReportsChartCard(
          title: 'Completion vs Overdue',
          subtitle: 'Delivery health for the period',
          icon: Icons.fact_check_rounded,
          accent: palette.accent(ReportsAccent.emerald),
          child: ReportsRankedBars(
            data: [
              ReportsDatum(label: 'Completed', value: completed),
              ReportsDatum(label: 'Overdue', value: overdue),
            ],
          ),
        ),
        ReportsChartCard(
          title: 'Staff Performance',
          subtitle: 'Tasks completed per assignee',
          icon: Icons.emoji_events_rounded,
          accent: palette.accent(ReportsAccent.amber),
          child: ReportsRankedBars(
            data: ReportsSeries.fold(staffPerformance.entries),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Users
// ─────────────────────────────────────────────────────────────────────────────

class ReportsUsersTab extends StatelessWidget {
  const ReportsUsersTab({
    super.key,
    required this.computed,
    required this.actions,
  });

  final AnalyticsComputed computed;
  final ReportsTabActions actions;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final users = computed.bundle.users.where((u) => !u.archived).toList();

    if (users.isEmpty) {
      return ReportsEmptyState(
        title: 'No user analytics',
        message:
            'Workforce segmentation is admin-only. Sign in with an account '
            'that can read the directory, or refresh to try again.',
        actions: [
          ReportsEmptyAction(
            label: 'Refresh data',
            icon: Icons.refresh_rounded,
            onPressed: actions.onRefresh,
            primary: true,
          ),
        ],
      );
    }

    final byRole = <String, double>{};
    final byStatus = <String, double>{};
    for (final user in users) {
      byRole[humanizeKey(user.role)] = (byRole[humanizeKey(user.role)] ?? 0) + 1;
      byStatus[humanizeKey(user.status)] =
          (byStatus[humanizeKey(user.status)] ?? 0) + 1;
    }

    final assignments = {
      for (final warehouse in computed.bundle.warehouses)
        warehouse.name: warehouse.staffCount.toDouble(),
    };

    return ReportsTabScroll(
      children: [
        ReportsChartCard(
          title: 'Users by Role',
          subtitle: 'Directory segmentation',
          icon: Icons.badge_rounded,
          accent: palette.accent(ReportsAccent.indigo),
          child: ReportsDonutChart(
            data: ReportsSeries.fold(byRole.entries),
            centerLabel: 'users',
          ),
        ),
        ReportsChartCard(
          title: 'Activation Status',
          subtitle: 'Active against suspended accounts',
          icon: Icons.verified_user_rounded,
          accent: palette.accent(ReportsAccent.emerald),
          child: ReportsRankedBars(
            data: ReportsSeries.fold(byStatus.entries),
          ),
        ),
        ReportsChartCard(
          title: 'Warehouse Assignments',
          subtitle: 'Staff attached to each facility',
          icon: Icons.hub_rounded,
          accent: palette.accent(ReportsAccent.sky),
          child: ReportsRankedBars(
            data: ReportsSeries.fold(assignments.entries),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Export centre
// ─────────────────────────────────────────────────────────────────────────────

class ReportsExportTab extends StatelessWidget {
  const ReportsExportTab({super.key, required this.rangeLabel});

  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);

    void notifyPending(String format) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          content: Text(
            '$format is queued for $rangeLabel — connect the export endpoint '
            'to generate the file.',
          ),
        ),
      );
    }

    return ReportsTabScroll(
      children: [
        ReportsNoticeChip(
          icon: Icons.cloud_sync_outlined,
          headline: 'Export delivery is not wired up yet',
          detail:
              'The formats below are ready in the client. Generating a file '
              'needs the backend export endpoint; until then, selecting a '
              'format confirms the request rather than downloading a document.',
          status: ReportsStatus.info,
        ),
        ReportsExportCard(
          title: 'PDF Executive Summary',
          description:
              'Board-ready pack: KPI headline, charts and period commentary.',
          specs: const ['.pdf', 'A4 portrait', 'Charts included'],
          icon: Icons.picture_as_pdf_rounded,
          accent: palette.accent(ReportsAccent.coral),
          onTap: () => notifyPending('PDF Executive Summary'),
        ),
        ReportsExportCard(
          title: 'Excel Workbook',
          description:
              'Multi-sheet workbook with inventory, orders, tasks and movements.',
          specs: const ['.xlsx', '6 sheets', 'Formulas preserved'],
          icon: Icons.table_chart_rounded,
          accent: palette.accent(ReportsAccent.emerald),
          onTap: () => notifyPending('Excel Workbook'),
        ),
        ReportsExportCard(
          title: 'Raw CSV Tables',
          description:
              'Flat, unformatted extracts for your own BI pipeline.',
          specs: const ['.csv', 'UTF-8', 'One file per dataset'],
          icon: Icons.description_rounded,
          accent: palette.accent(ReportsAccent.sky),
          onTap: () => notifyPending('CSV Tables'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Chronological series from a date-keyed map.
///
/// Buckets are keyed by [DateTime] rather than by a formatted string: `3/5`
/// and `3/15` sort the wrong way round lexicographically, which silently
/// scrambles the x-axis of every daily chart.
List<ReportsDatum> _timeSeries(
  Map<DateTime, double> source,
  String Function(DateTime bucket) label,
) {
  final keys = source.keys.toList()..sort();
  return [
    for (final key in keys)
      ReportsDatum(label: label(key), value: source[key] ?? 0),
  ];
}

DateTime _dayBucket(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

DateTime _monthBucket(DateTime dt) => DateTime(dt.year, dt.month);

String _dayLabel(DateTime dt) => '${dt.day}/${dt.month}';

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _monthLabel(DateTime dt) => _monthNames[dt.month - 1];
