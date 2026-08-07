import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/theme/app_theme_colors.dart';
import 'package:logisticsmobile/core/theme/app_typography.dart';
import 'package:logisticsmobile/core/utils/task_workflow_utils.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/dashboard_enterprise_widgets.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/staff_dashboard_header.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/features/tasks/presentation/cubit/tasks_cubit.dart';
import 'package:logisticsmobile/routes/wms_route_paths.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_premium_cards.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_activity_timeline.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_dashboard_section.dart';
import 'package:logisticsmobile/widgets/wms/wms_badges.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Row height for the dashboard's KPI grids.
///
/// A fixed extent was the root of the "BOTTOM OVERFLOWED" banners: the tiles
/// grow with the user's text scale while the row did not. This tracks both the
/// device width and the accessibility text scale, so the row always has room
/// for the tile it hosts.
double staffKpiGridExtent(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final scale = MediaQuery.textScalerOf(context).scale(100) / 100;
  final base = MobileUi.kpiGridMainAxisExtentFor(width);
  return base * scale.clamp(1.0, 1.35);
}

/// Staff-only operations dashboard — mobile-first layout (≤430dp).
class StaffOperationsDashboardBody extends StatelessWidget {
  const StaffOperationsDashboardBody({
    super.key,
    required this.data,
    required this.assignedWarehouseName,
    required this.stockOpsRoute,
    required this.ordersRoute,
    required this.tasksRoute,
    required this.inventoryRoute,
    required this.reportsRoute,
    required this.notificationsRoute,
    required this.onTaskAction,
    this.selectedKpiFilter,
    this.onKpiFilterTap,
  });

  final StaffDashboardData data;
  final String? assignedWarehouseName;
  final String stockOpsRoute;
  final String ordersRoute;
  final String tasksRoute;
  final String inventoryRoute;
  final String reportsRoute;
  final String notificationsRoute;
  final void Function(WarehouseTask task, TaskWorkflowAction action)
  onTaskAction;
  final String? selectedKpiFilter;
  final ValueChanged<String?>? onKpiFilterTap;

  static const _sectionGap = MobileUi.dashboardSectionGap;

  /// Card face for this dashboard — the themed surface, so the portal follows
  /// a mode switch instead of holding a hardcoded white.
  Color _cardColor(WmsUiColors colors) => colors.surface;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final cardColor = _cardColor(colors);
    final allWarehouses = data.warehouseStats;
    final assignedWarehouses = _assignedWarehouses(data.warehouseStats);
    final summary = _inventorySummaryForStaff(data, assignedWarehouseName);
    final tasks = data.tasks;
    final taskSummary = TaskWorkflowUtils.summarize(tasks);
    final ops = StaffDashboardMetrics.operationsToday(data);
    final countTasks = _countTasksToday(tasks);
    final activeTasks = tasks
        .where((t) => t.isActive)
        .take(5)
        .toList(growable: false);
    final activityEntries = buildStaffOperationsActivityFeed(data);
    final overviewTasks = tasks
        .where((t) => t.isActive)
        .take(5)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Header
        StaffDashboardHeader(
          assignedWarehouseName: assignedWarehouseName,
          stockOpsRoute: stockOpsRoute,
          ordersRoute: ordersRoute,
          tasksRoute: tasksRoute,
          reportsRoute: reportsRoute,
          onNavigate: (route, {replace = false}) {
            if (replace) {
              context.go(route);
            } else {
              context.push(route);
            }
          },
        ),
        const SizedBox(height: _sectionGap),

        // 2. Task Statistics
        WmsDashboardSection(
          title: 'Task Statistics',
          actionLabel: 'View all',
          onAction: () => context.push(tasksRoute),
          child: _StaffTaskStatisticsGrid(
            summary: taskSummary,
            cardColor: cardColor,
            selectedFilter: selectedKpiFilter,
            onFilterTap: onKpiFilterTap ?? (_) => context.push(tasksRoute),
          ),
        ),
        const SizedBox(height: _sectionGap),

        // 3. Today's Operations
        WmsDashboardSection(
          title: "Today's Operations",
          child: _StaffOperationsGrid(
            inbound: ops.inbound,
            outbound: ops.outbound,
            transfers: ops.transfers,
            countTasks: countTasks,
            cardColor: cardColor,
          ),
        ),
        const SizedBox(height: _sectionGap),

        // 4. My Active Tasks
        WmsDashboardSection(
          title: 'My Active Tasks',
          count: activeTasks.length,
          actionLabel: activeTasks.isNotEmpty ? 'View all' : null,
          onAction: activeTasks.isNotEmpty
              ? () => context.push(tasksRoute)
              : null,
          child: activeTasks.isEmpty
              ? AppCard(
                  elevated: true,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  backgroundColor: cardColor,
                  child: const WmsEmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No active tasks',
                    message: 'Assigned tasks will appear here.',
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < activeTasks.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      StaffActiveTaskCard(
                        key: ValueKey(activeTasks[i].id),
                        task: activeTasks[i],
                        cardColor: cardColor,
                        onView: () => context.push(
                          WmsRoutePaths.taskDetail(context, activeTasks[i].id),
                        ),
                        onAction: (action) =>
                            onTaskAction(activeTasks[i], action),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: _sectionGap),

        // 5. Operational Alerts
        WmsDashboardSection(
          title: 'Operational Alerts',
          child: _StaffOperationalAlertsCard(
            outOfStock: data.alerts.outOfStockCount,
            lowStock: data.alerts.lowStockCount,
            expired: data.alerts.expiredCount,
            expiringSoon: data.alerts.expiringSoonCount,
            pendingOrders: data.pendingOrdersCount,
            urgentTasks: taskSummary.overdue,
            cardColor: cardColor,
            onTap: () => context.go(inventoryRoute),
          ),
        ),
        const SizedBox(height: _sectionGap),

        // 6. Inventory Health
        _StaffInventoryHealthSection(
          inStock: summary.inStock,
          lowStock: summary.lowStock,
          outOfStock: summary.outOfStock,
          expired: data.alerts.expiredCount,
          cardColor: cardColor,
          onDetailsTap: () => context.go(inventoryRoute),
        ),
        const SizedBox(height: _sectionGap),

        // 7. Warehouse Performance
        WmsDashboardSection(
          title: 'Warehouse Performance',
          actionLabel: allWarehouses.isNotEmpty ? 'Manage →' : null,
          onAction: allWarehouses.isNotEmpty
              ? () => context.go(inventoryRoute)
              : null,
          child: allWarehouses.isEmpty
              ? AppCard(
                  elevated: true,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  backgroundColor: cardColor,
                  child: const WmsEmptyState(
                    icon: Icons.warehouse_outlined,
                    title: 'No warehouses',
                    message:
                        'Warehouse utilization will appear when sites are configured.',
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allWarehouses.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    return _StaffWarehousePerformanceCard(
                      key: ValueKey('perf-${allWarehouses[index].id}'),
                      stat: allWarehouses[index],
                    );
                  },
                ),
        ),
        const SizedBox(height: _sectionGap),

        // 8. Task Overview
        WmsDashboardSection(
          title: 'Task Overview',
          actionLabel: 'All tasks',
          onAction: () => context.push(tasksRoute),
          child: _StaffTaskOverviewSection(
            summary: taskSummary,
            tasks: overviewTasks,
            cardColor: cardColor,
            onViewTask: (task) =>
                context.push(WmsRoutePaths.taskDetail(context, task.id)),
            onTaskAction: onTaskAction,
          ),
        ),
        const SizedBox(height: _sectionGap),

        // 9. Smart Insights
        WmsDashboardSection(
          title: 'Smart Insights',
          child: data.insights.isEmpty
              ? AppCard(
                  elevated: true,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  backgroundColor: cardColor,
                  child: const WmsEmptyState(
                    icon: Icons.lightbulb_outline,
                    title: 'No insights',
                    message: 'AI-driven operational insights will appear here.',
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < data.insights.length && i < 8; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _StaffInsightCard(
                        insight: data.insights[i],
                        cardColor: cardColor,
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: _sectionGap),

        // 10. My Warehouses
        WmsDashboardSection(
          title: 'My Warehouses',
          subtitle: assignedWarehouseName != null
              ? 'Showing warehouses assigned to you'
              : 'Your assigned warehouse locations',
          child: assignedWarehouses.isEmpty
              ? AppCard(
                  elevated: true,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  backgroundColor: cardColor,
                  child: const WmsEmptyState(
                    icon: Icons.warehouse_outlined,
                    title: 'No assigned warehouses',
                    message: 'Contact your supervisor to get warehouse access.',
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < assignedWarehouses.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      StaffWarehouseCard(
                        key: ValueKey(assignedWarehouses[i].id),
                        stat: assignedWarehouses[i],
                        cardColor: cardColor,
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: _sectionGap),

        // 11. Recent Notifications
        WmsDashboardSection(
          title: 'Recent Notifications',
          actionLabel: 'View all',
          onAction: () => context.go(notificationsRoute),
          child: data.recentNotifications.isEmpty
              ? AppCard(
                  elevated: true,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  backgroundColor: cardColor,
                  child: const WmsEmptyState(
                    icon: Icons.notifications_outlined,
                    title: 'No notifications',
                    message: 'System alerts will appear here.',
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (
                      var i = 0;
                      i < data.recentNotifications.length;
                      i++
                    ) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _StaffNotificationCard(
                        key: ValueKey(data.recentNotifications[i].id),
                        notification: data.recentNotifications[i],
                        cardColor: cardColor,
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: _sectionGap),

        // 12. Recent Audit Activity
        WmsDashboardSection(
          title: 'Recent Audit Activity',
          child: data.auditActivities.isEmpty
              ? AppCard(
                  elevated: true,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  backgroundColor: cardColor,
                  child: const WmsEmptyState(
                    icon: Icons.history,
                    title: 'No audit activity',
                    message: 'System audit logs will appear here.',
                  ),
                )
              : AppCard(
                  elevated: true,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  backgroundColor: cardColor,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < data.auditActivities.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i < data.auditActivities.length - 1
                                ? AppSpacing.md
                                : 0,
                          ),
                          child: _StaffAuditTimelineTile(
                            activity: data.auditActivities[i],
                            showConnector: i < data.auditActivities.length - 1,
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: _sectionGap),

        // 13. Recent Orders
        WmsDashboardSection(
          title: 'Recent Orders',
          actionLabel: 'View all',
          onAction: () => context.go(ordersRoute),
          child: data.recentOrders.isEmpty
              ? AppCard(
                  elevated: true,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  backgroundColor: cardColor,
                  child: const WmsEmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'No recent orders',
                    message: 'Orders will appear as they are created.',
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < data.recentOrders.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _StaffOrderCard(
                        key: ValueKey(data.recentOrders[i].id),
                        order: data.recentOrders[i],
                        cardColor: cardColor,
                        onTap: () => context.go(ordersRoute),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: _sectionGap),

        // 14. Recent Activity Timeline
        WmsDashboardSection(
          title: 'Recent Activity Timeline',
          child: _StaffRecentActivityList(
            entries: activityEntries,
            cardColor: cardColor,
          ),
        ),
      ],
    );
  }

  List<WarehouseStat> _assignedWarehouses(List<WarehouseStat> stats) {
    final assigned = assignedWarehouseName?.trim();
    if (assigned == null || assigned.isEmpty) return stats;
    final filtered = stats
        .where((w) => w.name.toLowerCase() == assigned.toLowerCase())
        .toList();
    return filtered.isNotEmpty ? filtered : stats;
  }

  static InventorySummary _inventorySummaryForStaff(
    StaffDashboardData data,
    String? warehouseName,
  ) {
    final assigned = warehouseName?.trim();
    if (assigned == null || assigned.isEmpty) return data.inventorySummary;

    final items = data.inventoryItems
        .where((i) => i.warehouseName.toLowerCase() == assigned.toLowerCase())
        .toList();
    if (items.isEmpty) return data.inventorySummary;
    return _summaryFromItems(items);
  }

  static InventorySummary _summaryFromItems(List<InventoryItem> items) {
    var inStock = 0;
    var lowStock = 0;
    var outOfStock = 0;
    num totalUnits = 0;

    for (final item in items) {
      totalUnits += item.quantity;
      final status = item.stockStatus.toLowerCase();
      if (status.contains('out')) {
        outOfStock++;
      } else if (status.contains('low')) {
        lowStock++;
      } else {
        inStock++;
      }
    }

    return InventorySummary(
      totalUnits: totalUnits,
      inStock: inStock,
      lowStock: lowStock,
      outOfStock: outOfStock,
    );
  }

  static int _countTasksToday(List<WarehouseTask> tasks) {
    final now = DateTime.now();
    bool isToday(DateTime? dt) =>
        dt != null &&
        dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;

    return tasks.where((t) {
      final isCount =
          t.taskType == WmsTaskTypes.inventoryCount || t.taskType == 'Audit';
      if (!isCount) return false;
      return isToday(t.updatedAt) || isToday(t.createdAt) || isToday(t.dueDate);
    }).length;
  }
}

class _StaffTaskStatisticsGrid extends StatelessWidget {
  const _StaffTaskStatisticsGrid({
    required this.summary,
    required this.cardColor,
    required this.selectedFilter,
    required this.onFilterTap,
  });

  final TasksSummary summary;
  final Color cardColor;
  final String? selectedFilter;
  final ValueChanged<String?> onFilterTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatTile('Total Tasks', '${summary.total}', Icons.list_alt, null, null),
      _StatTile(
        'Awaiting',
        '${summary.awaiting}',
        Icons.schedule_outlined,
        WmsTaskStatuses.pending,
        TaskKpiFilter.awaiting,
      ),
      _StatTile(
        'Accepted',
        '${summary.accepted}',
        Icons.thumb_up_alt_outlined,
        WmsTaskStatuses.accepted,
        TaskKpiFilter.accepted,
      ),
      _StatTile(
        'In Progress',
        '${summary.inProgress}',
        Icons.play_circle_outline,
        WmsTaskStatuses.inProgress,
        TaskKpiFilter.inProgress,
      ),
      _StatTile(
        'Completed',
        '${summary.completed}',
        Icons.check_circle_outline,
        WmsTaskStatuses.completed,
        TaskKpiFilter.completed,
      ),
      _StatTile(
        'Rejected',
        '${summary.rejected}',
        Icons.cancel_outlined,
        WmsTaskStatuses.rejected,
        TaskKpiFilter.rejected,
      ),
      _StatTile(
        'Overdue',
        '${summary.overdue}',
        Icons.event_busy_outlined,
        WmsTaskStatuses.overdue,
        TaskKpiFilter.overdue,
      ),
    ];

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: MobileUi.phoneKpiGridDelegate(
        spacing: AppSpacing.sm,
        mainAxisExtent: staffKpiGridExtent(context),
      ),
      children: [
        for (final item in items)
          _StaffStatCard(
            item: item,
            cardColor: cardColor,
            isSelected:
                item.filterKey != null && selectedFilter == item.filterKey,
            onTap: () {
              if (item.filterKey == null) {
                onFilterTap(null);
              } else {
                onFilterTap(
                  selectedFilter == item.filterKey ? null : item.filterKey,
                );
              }
            },
          ),
      ],
    );
  }
}

class _StaffOperationsGrid extends StatelessWidget {
  const _StaffOperationsGrid({
    required this.inbound,
    required this.outbound,
    required this.transfers,
    required this.countTasks,
    required this.cardColor,
  });

  final int inbound;
  final int outbound;
  final int transfers;
  final int countTasks;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final items = [
      _OpsTile(
        'Inbound',
        inbound,
        Icons.move_to_inbox_outlined,
        colors.success,
      ),
      _OpsTile(
        'Outbound',
        outbound,
        Icons.local_shipping_outlined,
        const Color(0xFFC2410C),
      ),
      _OpsTile('Transfers', transfers, Icons.swap_horiz_rounded, colors.info),
      _OpsTile(
        'Count Tasks',
        countTasks,
        Icons.fact_check_outlined,
        colors.accent,
      ),
    ];

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: MobileUi.phoneKpiGridDelegate(
        spacing: AppSpacing.sm,
        mainAxisExtent: staffKpiGridExtent(context),
      ),
      children: [
        for (final item in items)
          AppCard(
            elevated: true,
            padding: const EdgeInsets.all(AppSpacing.lg),
            backgroundColor: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: WmsIconSizes.kpi, color: item.color),
                const SizedBox(height: AppSpacing.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${item.value}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.kpiValue(context, width: width),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.kpiLabel(context),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StaffOperationalAlertsCard extends StatelessWidget {
  const _StaffOperationalAlertsCard({
    required this.outOfStock,
    required this.lowStock,
    required this.expired,
    required this.expiringSoon,
    required this.pendingOrders,
    required this.urgentTasks,
    required this.cardColor,
    required this.onTap,
  });

  static const _compactBreakpoint = 600.0;
  static const _gridSpacing = 12.0;

  final int outOfStock;
  final int lowStock;
  final int expired;
  final int expiringSoon;
  final int pendingOrders;
  final int urgentTasks;
  final Color cardColor;
  final VoidCallback onTap;

  List<_StaffOperationalAlertData> _itemsFor(WmsUiColors colors) => [
    _StaffOperationalAlertData(
      'Out Of Stock',
      outOfStock,
      colors.error,
      Icons.remove_shopping_cart_outlined,
    ),
    _StaffOperationalAlertData(
      'Low Stock',
      lowStock,
      colors.warning,
      Icons.trending_down_rounded,
    ),
    _StaffOperationalAlertData(
      'Expired',
      expired,
      const Color(0xFF7C3AED),
      Icons.event_busy_outlined,
    ),
    _StaffOperationalAlertData(
      'Expiring Soon',
      expiringSoon,
      colors.info,
      Icons.schedule_rounded,
    ),
    _StaffOperationalAlertData(
      'Pending Orders',
      pendingOrders,
      colors.primary,
      Icons.shopping_cart_outlined,
    ),
    _StaffOperationalAlertData(
      'Urgent Tasks',
      urgentTasks,
      colors.error,
      Icons.access_time_filled,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colors = WmsUiColors.of(context);
        final width = constraints.maxWidth;
        final isCompact = width < _compactBreakpoint;

        if (isCompact) {
          return GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: _gridSpacing,
              mainAxisSpacing: _gridSpacing,
              mainAxisExtent: MobileUi.kpiGridMainAxisExtentFor(width),
            ),
            children: [
              for (final item in _itemsFor(colors))
                _StaffOperationalAlertTile(
                  data: item,
                  cardColor: cardColor,
                  onTap: onTap,
                ),
            ],
          );
        }

        final columns = MobileUi.isTablet(width) ? 3 : 2;
        final tileWidth = (width - _gridSpacing * (columns - 1)) / columns;

        return Wrap(
          spacing: _gridSpacing,
          runSpacing: _gridSpacing,
          children: [
            for (final item in _itemsFor(colors))
              SizedBox(
                width: tileWidth,
                child: _StaffOperationalAlertTile(
                  data: item,
                  cardColor: cardColor,
                  onTap: onTap,
                  expanded: true,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StaffOperationalAlertData {
  const _StaffOperationalAlertData(
    this.label,
    this.count,
    this.color,
    this.icon,
  );

  final String label;
  final int count;
  final Color color;
  final IconData icon;
}

class _StaffOperationalAlertTile extends StatelessWidget {
  const _StaffOperationalAlertTile({
    required this.data,
    required this.cardColor,
    required this.onTap,
    this.expanded = false,
  });

  final _StaffOperationalAlertData data;
  final Color cardColor;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    // Same tile as the task grids, so Operational Alerts stops being a third
    // card style on one screen. `highlighted` draws the severity hairline when
    // the count is non-zero, which is the only state worth pulling the eye.
    return WmsMetricCard(
      icon: data.icon,
      color: data.color,
      value: '${data.count}',
      label: data.label,
      onTap: onTap,
      emphasizeValue: true,
      highlighted: data.count > 0,
      compact: true,
    );
  }
}

class _StaffInventoryHealthSection extends StatelessWidget {
  const _StaffInventoryHealthSection({
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
    required this.expired,
    required this.cardColor,
    this.onDetailsTap,
  });

  final int inStock;
  final int lowStock;
  final int outOfStock;
  final int expired;
  final Color cardColor;
  final VoidCallback? onDetailsTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    return WmsDashboardSection(
      title: 'Inventory Health',
      actionLabel: onDetailsTap != null ? 'Details' : null,
      onAction: onDetailsTap,
      child: AppCard(
        elevated: true,
        padding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Stock status distribution',
              textAlign: TextAlign.center,
              style: WmsDesignTokens.supporting(
                context,
              ).copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 12),
            _StaffMobileInventoryDonut(
              inStock: inStock,
              lowStock: lowStock,
              outOfStock: outOfStock,
              expired: expired,
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffMobileInventoryDonut extends StatelessWidget {
  const _StaffMobileInventoryDonut({
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
    required this.expired,
  });

  final int inStock;
  final int lowStock;
  final int outOfStock;
  final int expired;

  static const _chartSize = 180.0;

  /// Segment palette, resolved per brightness.
  ///
  /// Was a `static const` list, which pinned the light-mode swatches into
  /// every theme — a static field has no context to resolve against.
  static List<({String label, Color color})> _segmentsFor(WmsUiColors colors) =>
      [
        (label: 'In Stock', color: colors.success),
        (label: 'Low Stock', color: colors.warning),
        (label: 'Out Of Stock', color: colors.error),
        (label: 'Expired', color: colors.expired),
      ];

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final values = [inStock, lowStock, outOfStock, expired];
    final totalLines = values.fold<int>(0, (sum, value) => sum + value);

    if (totalLines <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          'No inventory distribution data',
          textAlign: TextAlign.center,
          style: WmsDesignTokens.supporting(
            context,
          ).copyWith(color: colors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: SizedBox(
            width: _chartSize,
            height: _chartSize,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = constraints.maxWidth;
                final centerSpace = side * 0.28;
                final ringWidth = (side / 2 - 6) - centerSpace;

                final sections = <PieChartSectionData>[];
                for (var i = 0; i < values.length; i++) {
                  final value = values[i].toDouble();
                  if (value <= 0) continue;
                  sections.add(
                    PieChartSectionData(
                      value: value,
                      color: _segmentsFor(colors)[i].color,
                      radius: ringWidth.clamp(16, 40),
                      showTitle: false,
                    ),
                  );
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: centerSpace,
                        startDegreeOffset: -90,
                        sections: sections,
                      ),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$totalLines',
                          style: WmsDesignTokens.metricValue(context).copyWith(
                            fontSize: 28,
                            height: 1,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'LINES',
                          style: WmsDesignTokens.supportingDense(context)
                              .copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _segmentsFor(colors).length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _segmentsFor(colors)[i].color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    _segmentsFor(colors)[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.supporting(
                      context,
                    ).copyWith(color: colors.textPrimary),
                  ),
                ),
                Text(
                  '${values[i]} SKUs',
                  style: WmsDesignTokens.supporting(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StaffWarehousePerformanceCard extends StatelessWidget {
  const _StaffWarehousePerformanceCard({super.key, required this.stat});

  final WarehouseStat stat;

  static Color _cardBackground(WmsUiColors colors) =>
      colors.isDark ? const Color(0xFF1F2937) : Colors.white;

  static Color _primaryText(WmsUiColors colors) =>
      colors.isDark ? Colors.white : AppTypographyColors.primaryText;

  static Color _secondaryText(WmsUiColors colors) => colors.isDark
      ? AppThemeColors.darkTextSecondary
      : AppTypographyColors.secondaryText;

  static Color _progressTrack(WmsUiColors colors) =>
      colors.isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0);

  static Color _capacityColor(int utilization, WmsUiColors colors) {
    if (utilization <= 30) return colors.success;
    if (utilization <= 70) return colors.warning;
    return colors.error;
  }

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final utilization = stat.utilization.clamp(0, 100);
    final primaryText = _primaryText(colors);
    final secondaryText = _secondaryText(colors);
    final barColor = _capacityColor(utilization, colors);

    return AppCard(
      elevated: true,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: _cardBackground(colors),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stat.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryText,
                height: 1.25,
              ),
            ),
            if (stat.location != null && stat.location!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                stat.location!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryText,
                  height: 1.3,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              '${WmsFormatters.quantity(stat.totalUnits)} Units',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: primaryText,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${stat.productCount} Products',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: primaryText,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$utilization% Capacity Used',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: barColor,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: utilization / 100,
                minHeight: 6,
                backgroundColor: _progressTrack(colors),
                color: barColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffPerfMetaRow extends StatelessWidget {
  const _StaffPerfMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      StaffMetaRow(label: label, value: value);
}

/// One labelled metadata line: `Customer: Fakhrudiin`.
///
/// The label and value used to be adjacent `Text` runs with no punctuation or
/// gap, so they painted as a single word ("CustomerFakhrudiin"). The label now
/// carries its colon and owns a fixed column, which both separates the pair and
/// aligns every value down the card.
class StaffMetaRow extends StatelessWidget {
  const StaffMetaRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;

  /// Renders the value in the error colour — used for overdue dates.
  final bool highlight;

  /// Width of the label column. Wide enough for "Warehouse:" at 1.3× scale
  /// before the label itself starts to ellipsize.
  static const double labelWidth = 96;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              '$label:',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.body(context).copyWith(
                color: highlight ? colors.error : colors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffTaskOverviewSection extends StatelessWidget {
  const _StaffTaskOverviewSection({
    required this.summary,
    required this.tasks,
    required this.cardColor,
    required this.onViewTask,
    required this.onTaskAction,
  });

  final TasksSummary summary;
  final List<WarehouseTask> tasks;
  final Color cardColor;
  final void Function(WarehouseTask task) onViewTask;
  final void Function(WarehouseTask task, TaskWorkflowAction action)
  onTaskAction;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatTile('Total', '${summary.total}', Icons.list_alt, null, null),
      _StatTile(
        'Awaiting',
        '${summary.awaiting}',
        Icons.schedule_outlined,
        WmsTaskStatuses.pending,
        null,
      ),
      _StatTile(
        'Accepted',
        '${summary.accepted}',
        Icons.thumb_up_alt_outlined,
        WmsTaskStatuses.accepted,
        null,
      ),
      _StatTile(
        'In Progress',
        '${summary.inProgress}',
        Icons.play_circle_outline,
        WmsTaskStatuses.inProgress,
        null,
      ),
      _StatTile(
        'Completed',
        '${summary.completed}',
        Icons.check_circle_outline,
        WmsTaskStatuses.completed,
        null,
      ),
      _StatTile(
        'Rejected',
        '${summary.rejected}',
        Icons.cancel_outlined,
        WmsTaskStatuses.rejected,
        null,
      ),
      _StatTile(
        'Overdue',
        '${summary.overdue}',
        Icons.event_busy_outlined,
        WmsTaskStatuses.overdue,
        null,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppCard(
          elevated: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          backgroundColor: cardColor,
          child: GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: MobileUi.phoneKpiGridDelegate(
              spacing: AppSpacing.sm,
              mainAxisExtent: staffKpiGridExtent(context),
            ),
            children: [
              for (final item in stats)
                _StaffOverviewStatTile(item: item, cardColor: cardColor),
            ],
          ),
        ),
        if (tasks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < tasks.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            StaffActiveTaskCard(
              key: ValueKey('overview-${tasks[i].id}'),
              task: tasks[i],
              cardColor: cardColor,
              onView: () => onViewTask(tasks[i]),
              onAction: (action) => onTaskAction(tasks[i], action),
            ),
          ],
        ],
      ],
    );
  }
}

class _StaffOverviewStatTile extends StatelessWidget {
  const _StaffOverviewStatTile({required this.item, required this.cardColor});

  final _StatTile item;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final accent = item.status != null
        ? WmsTaskStatusBadge.foregroundFor(item.status!, context)
        : colors.primary;

    // Same tile as the statistics grid, so the two task sections read as one
    // system rather than two similar-but-different card styles.
    return WmsMetricCard(
      icon: item.icon,
      color: accent,
      value: item.value,
      label: item.label,
      emphasizeValue: true,
      compact: true,
    );
  }
}

class _StaffInsightCard extends StatelessWidget {
  const _StaffInsightCard({required this.insight, required this.cardColor});

  final DashboardInsight insight;
  final Color cardColor;

  Color _colorFor(String severity, WmsUiColors colors) {
    return switch (severity.toLowerCase()) {
      'critical' || 'error' => colors.error,
      'warning' => colors.warning,
      _ => colors.info,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final color = _colorFor(insight.severity, colors);

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: cardColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              insight.message,
              style: WmsDesignTokens.body(
                context,
              ).copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffNotificationCard extends StatelessWidget {
  const _StaffNotificationCard({
    super.key,
    required this.notification,
    required this.cardColor,
  });

  final AppNotification notification;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  notification.title,
                  style: WmsDesignTokens.body(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!notification.read)
                WmsToneBadge(
                  label: 'Unread',
                  color: colors.info,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            notification.message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.supporting(
              context,
            ).copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            WmsFormatters.relativeTime(notification.createdAt),
            style: WmsDesignTokens.supportingDense(
              context,
            ).copyWith(color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _StaffAuditTimelineTile extends StatelessWidget {
  const _StaffAuditTimelineTile({
    required this.activity,
    required this.showConnector,
  });

  final StaffAuditActivity activity;
  final bool showConnector;

  ({IconData icon, Color color, Color background}) _presentationFor(
    String action,
    WmsUiColors colors,
  ) {
    final lower = action.toLowerCase();
    if (lower.contains('creat')) {
      return (
        icon: Icons.add_circle_outline,
        color: colors.primary,
        background: colors.primaryMuted,
      );
    }
    if (lower.contains('start')) {
      return (
        icon: Icons.play_circle_outline,
        color: colors.info,
        background: colors.infoMuted,
      );
    }
    if (lower.contains('receiv') || lower.contains('inbound')) {
      return (
        icon: Icons.move_to_inbox_outlined,
        color: colors.success,
        background: colors.successMuted,
      );
    }
    if (lower.contains('status') || lower.contains('change')) {
      return (
        icon: Icons.change_circle_outlined,
        color: colors.warning,
        background: colors.warningMuted,
      );
    }
    return (
      icon: Icons.history,
      color: colors.accent,
      background: colors.accentMuted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final presentation = _presentationFor(
      activity.action,
      WmsUiColors.of(context),
    );
    const iconSize = 32.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: iconSize,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: presentation.background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  presentation.icon,
                  color: presentation.color,
                  size: WmsIconSizes.status,
                ),
              ),
              if (showConnector)
                Container(
                  width: 2,
                  height: 20,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                activity.action,
                style: WmsDesignTokens.body(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                activity.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WmsDesignTokens.supporting(
                  context,
                ).copyWith(color: colors.textSecondary),
              ),
              Text(
                WmsFormatters.relativeTime(activity.occurredAt),
                style: WmsDesignTokens.supportingDense(
                  context,
                ).copyWith(color: colors.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StaffOrderCard extends StatelessWidget {
  const _StaffOrderCard({
    super.key,
    required this.order,
    required this.cardColor,
    required this.onTap,
  });

  final WarehouseOrder order;
  final Color cardColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    return AppCard(
      elevated: true,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            order.orderNumber,
            style: WmsDesignTokens.body(
              context,
            ).copyWith(color: colors.primary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          _StaffPerfMetaRow(label: 'Customer', value: order.customerName),
          _StaffPerfMetaRow(label: 'Status', value: order.status),
          _StaffPerfMetaRow(
            label: 'Date',
            value: WmsFormatters.dateTimeShort(order.createdAt),
          ),
        ],
      ),
    );
  }
}

class _StaffRecentActivityList extends StatelessWidget {
  const _StaffRecentActivityList({
    required this.entries,
    required this.cardColor,
  });

  final List<WmsTimelineEntry> entries;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return AppCard(
        elevated: true,
        padding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: cardColor,
        child: const WmsEmptyState(
          title: 'No recent activity',
          message: 'Operations and updates will appear here.',
          icon: Icons.timeline_outlined,
        ),
      );
    }

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: cardColor,
      child: SizedBox(
        height: 300,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < entries.length - 1 ? AppSpacing.md : 0,
              ),
              child: WmsTimelineEntryTile(
                entry: entries[index],
                showConnector: index < entries.length - 1,
                dense: true,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Task-statistics tile.
///
/// Built on [WmsMetricCard] — the same tile the Supervisor control centre
/// uses — so the three portals share one KPI grammar. It also removes this
/// grid's overflow at the root: the old hand-rolled column stacked a 66dp icon
/// well, a 26dp number and a two-line label into a fixed 148dp row (~170dp of
/// content), and grew further with the user's text scale. [WmsMetricCard]
/// shrinks its badge first and scales the whole stack as a last resort, so it
/// cannot overflow at any scale.
class _StaffStatCard extends StatelessWidget {
  const _StaffStatCard({
    required this.item,
    required this.cardColor,
    required this.isSelected,
    required this.onTap,
  });

  final _StatTile item;
  final Color cardColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final accent = item.status != null
        ? WmsTaskStatusBadge.foregroundFor(item.status!, context)
        : colors.primary;

    return WmsMetricCard(
      icon: item.icon,
      color: accent,
      value: item.value,
      label: item.label,
      onTap: onTap,
      emphasizeValue: true,
      highlighted: isSelected,
      compact: true,
    );
  }
}

class _StatTile {
  const _StatTile(
    this.label,
    this.value,
    this.icon,
    this.status,
    this.filterKey,
  );

  final String label;
  final String value;
  final IconData icon;
  final String? status;
  final String? filterKey;
}

class _OpsTile {
  const _OpsTile(this.label, this.value, this.icon, this.color);
  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

/// Compact task card for staff dashboard with operational fields.
class StaffActiveTaskCard extends StatelessWidget {
  const StaffActiveTaskCard({
    super.key,
    required this.task,
    required this.onView,
    required this.onAction,
    this.cardColor,
  });

  final WarehouseTask task;
  final VoidCallback onView;
  final void Function(TaskWorkflowAction action) onAction;
  final Color? cardColor;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final displayStatus = task.effectiveStatus;
    final actions = TaskWorkflowUtils.getCardActions(task, isManager: false);

    return AppCard(
      elevated: true,
      onTap: onView,
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  task.title,
                  style: WmsDesignTokens.cardTitle(
                    context,
                  ).copyWith(color: colors.textPrimary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              WmsTaskStatusBadge(
                status: displayStatus,
                compact: true,
                useFullLabel: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (task.productName != null)
            _StaffTaskMeta(label: 'Product', value: task.productName!),
          if (task.quantity != null)
            _StaffTaskMeta(
              label: 'Quantity',
              value: WmsFormatters.quantity(task.quantity),
            ),
          if (task.warehouseName != null)
            _StaffTaskMeta(label: 'Warehouse', value: task.warehouseName!),
          if (task.dueDate != null)
            _StaffTaskMeta(
              label: 'Due Date',
              value: WmsFormatters.dateTimeShort(task.dueDate),
              highlight: task.isOverdue,
            ),
          const SizedBox(height: AppSpacing.xs),
          WmsTaskPriorityBadge(priority: task.priority, compact: true),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final action in actions)
                  ActionChip(
                    label: Text(action.label),
                    onPressed: () => onAction(action),
                    backgroundColor: action.destructive
                        ? colors.error.withValues(alpha: 0.08)
                        : colors.primaryMuted,
                    labelStyle: WmsDesignTokens.supporting(context).copyWith(
                      color: action.destructive ? colors.error : colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StaffTaskMeta extends StatelessWidget {
  const _StaffTaskMeta({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) =>
      StaffMetaRow(label: label, value: value, highlight: highlight);
}

class StaffWarehouseCard extends StatelessWidget {
  const StaffWarehouseCard({super.key, required this.stat, this.cardColor});

  final WarehouseStat stat;
  final Color? cardColor;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final utilization = stat.utilization.clamp(0, 100);

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.warehouse_outlined,
                size: WmsIconSizes.listLeading,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  stat.name,
                  style: WmsDesignTokens.cardTitle(
                    context,
                  ).copyWith(color: colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${WmsFormatters.quantity(stat.totalUnits)} units',
            style: WmsDesignTokens.body(
              context,
            ).copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Capacity used',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.supporting(
                    context,
                  ).copyWith(color: colors.textSecondary),
                ),
              ),
              Text(
                '$utilization%',
                style: WmsDesignTokens.supporting(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: utilization / 100,
              minHeight: 8,
              backgroundColor: colors.border,
              color: utilization >= 90
                  ? colors.error
                  : utilization >= 75
                  ? colors.warning
                  : colors.success,
            ),
          ),
        ],
      ),
    );
  }
}

/// Recent activity filtered to operational movement types.
List<WmsTimelineEntry> buildStaffOperationsActivityFeed(
  StaffDashboardData data,
) {
  final items = <({DateTime? time, WmsTimelineEntry entry})>[];

  for (final m in data.movements) {
    final type = m.type.toUpperCase();
    if (!_isOperationalMovement(type)) continue;
    final title = _movementTitle(type);
    items.add((
      time: m.timestamp,
      entry: WmsTimelineEntry(
        title: title,
        description:
            '${m.productName} · ${WmsFormatters.quantity(m.quantity)} units',
        relativeTime: WmsFormatters.relativeTime(m.timestamp),
        icon: _movementIcon(type),
        tone: _movementTone(type),
      ),
    ));
  }

  for (final t in data.tasks) {
    if (!_isCountTask(t)) continue;
    final time = t.updatedAt ?? t.createdAt ?? t.dueDate;
    items.add((
      time: time,
      entry: WmsTimelineEntry(
        title: 'Stock Count',
        description: t.title,
        relativeTime: WmsFormatters.relativeTime(time),
        icon: Icons.fact_check_outlined,
        tone: WmsTimelineTone.accent,
      ),
    ));
  }

  items.sort((a, b) {
    final ta = a.time;
    final tb = b.time;
    if (ta == null && tb == null) return 0;
    if (ta == null) return 1;
    if (tb == null) return -1;
    return tb.compareTo(ta);
  });

  return items.take(8).map((e) => e.entry).toList();
}

bool _isOperationalMovement(String type) =>
    type == 'INBOUND' ||
    type == 'OUTBOUND' ||
    type == 'TRANSFER' ||
    type == 'ADJUSTMENT';

String _movementTitle(String type) => switch (type) {
  'INBOUND' => 'Receive',
  'OUTBOUND' => 'Dispatch',
  'TRANSFER' => 'Transfer',
  'ADJUSTMENT' => 'Stock Count',
  _ => type,
};

IconData _movementIcon(String type) => switch (type) {
  'INBOUND' => Icons.move_to_inbox_outlined,
  'OUTBOUND' => Icons.local_shipping_outlined,
  'TRANSFER' => Icons.swap_horiz_rounded,
  _ => Icons.fact_check_outlined,
};

WmsTimelineTone _movementTone(String type) => switch (type) {
  'INBOUND' => WmsTimelineTone.success,
  'OUTBOUND' => WmsTimelineTone.outbound,
  'TRANSFER' => WmsTimelineTone.info,
  _ => WmsTimelineTone.accent,
};

bool _isCountTask(WarehouseTask task) =>
    task.taskType == WmsTaskTypes.inventoryCount || task.taskType == 'Audit';
