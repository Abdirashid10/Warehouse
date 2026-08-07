import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/theme/app_theme_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/control_center_data.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/dashboard_analytics_widgets.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/stock_movement_trend_chart.dart';
import 'package:logisticsmobile/features/inventory/presentation/widgets/inventory_analytics_widgets.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/domain/entities/supervisor_dashboard_data.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/presentation/widgets/supervisor_executive_analytics.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_activity_timeline.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_quick_actions.dart';
import 'package:logisticsmobile/widgets/wms/wms_badges.dart';
import 'package:logisticsmobile/widgets/wms/wms_premium_cards.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Navigation targets for command center section actions.
class CommandCenterRoutes {
  const CommandCenterRoutes({
    required this.inventoryRoute,
    required this.tasksRoute,
    required this.ordersRoute,
    required this.notificationsRoute,
    required this.stockOpsRoute,
    this.auditRoute,
    this.reportsRoute,
  });

  final String inventoryRoute;
  final String tasksRoute;
  final String ordersRoute;
  final String notificationsRoute;
  final String stockOpsRoute;
  final String? auditRoute;
  final String? reportsRoute;
}

/// Shared enterprise command center sections — web-parity data, mobile-friendly layout.
class CommandCenterSections {
  CommandCenterSections({
    required this.context,
    required this.data,
    required this.routes,
  });

  final BuildContext context;

  /// Theme-resolved palette for this section tree.
  ///
  /// Exposed as a getter so every section method reads the live theme rather
  /// than a colour captured when the holder was constructed.
  WmsUiColors get colors => WmsUiColors.of(context);
  final ControlCenterData data;
  final CommandCenterRoutes routes;

  static const sectionGap = AppSpacing.xxl;

  SupervisorExecutiveAnalytics get analytics =>
      SupervisorExecutiveAnalytics.from(data.supervisor);

  SupervisorInventoryAlerts get alerts => data.inventoryAlerts;
  SupervisorKpiSummary get kpis => data.kpis;

  /// All 13 sections in web dashboard order (tablet / scroll layout).
  List<Widget> buildAll() => [
        operationalAlerts(),
        kpiOverview(),
        quickActions(),
        inventoryHealthAnalytics(),
        orderAnalytics(),
        stockMovementAnalytics(),
        warehousePerformance(),
        taskOverview(),
        smartInsights(),
        recentNotifications(),
        recentAuditActivity(),
        recentOrders(),
        recentActivityFeed(),
      ];

  /// Tab 1 — critical ops at a glance.
  List<Widget> buildOverviewTab() => [
        operationalAlerts(),
        kpiOverview(),
        quickActions(),
      ];

  /// Tab 2 — inventory & order intelligence.
  List<Widget> buildAnalyticsTab() => [
        inventoryHealthAnalytics(),
        orderAnalytics(),
        stockMovementAnalytics(),
      ];

  /// Tab 3 — warehouse execution.
  List<Widget> buildOperationsTab() => [
        warehousePerformance(),
        taskOverview(),
        smartInsights(),
      ];

  /// Tab 4 — live activity streams.
  List<Widget> buildActivityTab() => [
        recentNotifications(),
        recentAuditActivity(),
        recentOrders(),
        recentActivityFeed(),
      ];

  Widget operationalAlerts() {
    return CommandCenterSectionCard(
      title: 'Operational Alerts',
      child: CommandCenterOperationalAlertsGrid(
        outOfStock: alerts.outOfStockCount,
        lowStock: alerts.lowStockCount,
        expired: alerts.expiredCount,
        expiringSoon: alerts.expiringCount,
        pendingOrders: data.pendingOrders,
        urgentTasks: kpis.overdueTasks,
        onTap: () => context.go(routes.inventoryRoute),
      ),
    );
  }

  Widget kpiOverview() {
    return CommandCenterSectionCard(
      title: 'KPI Overview',
      actionLabel: 'Inventory',
      onAction: () => context.go(routes.inventoryRoute),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Inventory metrics',
            style: WmsDesignTokens.cardTitle(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          CommandCenterKpiGrid(
            tiles: [
              CommandCenterKpiTileData(
                label: 'Units On Hand',
                value: WmsFormatters.quantity(kpis.totalUnitsOnHand),
                subtitle: 'Total quantity',
                icon: Icons.inventory_2_outlined,
                color: colors.primary,
                onTap: () => context.go(routes.inventoryRoute),
              ),
              CommandCenterKpiTileData(
                label: 'In Stock Lines',
                value: '${kpis.inStockLines}',
                subtitle: 'Above threshold',
                icon: Icons.check_circle_outline,
                color: colors.success,
                onTap: () => context.go(routes.inventoryRoute),
              ),
              CommandCenterKpiTileData(
                label: 'Low Stock',
                value: '${kpis.lowStockProducts}',
                subtitle: 'Needs attention',
                icon: Icons.warning_amber_rounded,
                color: colors.warning,
                badge: kpis.lowStockProducts > 0 ? 'Needs attention' : null,
                onTap: () => context.go(routes.inventoryRoute),
              ),
              CommandCenterKpiTileData(
                label: 'Out Of Stock',
                value: '${kpis.outOfStockLines}',
                subtitle: 'Zero quantity',
                icon: Icons.remove_shopping_cart_outlined,
                color: colors.error,
                badge: kpis.outOfStockLines > 0 ? 'Critical' : null,
                onTap: () => context.go(routes.inventoryRoute),
              ),
              CommandCenterKpiTileData(
                label: 'Stock Value',
                value: WmsFormatters.currency(kpis.totalStockValue),
                subtitle: 'Σ qty × cost',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF7C3AED),
                fullWidth: true,
                onTap: () => context.go(routes.inventoryRoute),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Operations metrics',
            style: WmsDesignTokens.cardTitle(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          CommandCenterKpiGrid(
            tiles: [
              CommandCenterKpiTileData(
                label: 'Active Warehouses',
                value: '${data.warehouses.length}',
                subtitle: 'Holding stock',
                icon: Icons.warehouse_outlined,
                color: colors.primary,
              ),
              CommandCenterKpiTileData(
                label: "Today's Movements",
                value: '${kpis.stockMovementsToday}',
                subtitle: 'Since midnight',
                icon: Icons.show_chart_rounded,
                color: colors.info,
              ),
              CommandCenterKpiTileData(
                label: 'Total Orders',
                value: '${kpis.totalOrders}',
                subtitle: 'Pipeline',
                icon: Icons.shopping_cart_outlined,
                color: colors.accent,
              ),
              CommandCenterKpiTileData(
                label: 'Delivered',
                value: '${data.supervisor.orderMonitoring.delivered}',
                subtitle: 'Completed',
                icon: Icons.local_shipping_outlined,
                color: colors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget quickActions() {
    final width = MediaQuery.sizeOf(context).width;
    final crossCount = MobileUi.quickActionColumns(width);
    final tileHeight = MobileUi.quickActionTileHeight(width);
    final actions = [
      WmsQuickAction(
        label: 'Receive',
        icon: Icons.download_rounded,
        onTap: () => context.push(routes.stockOpsRoute),
      ),
      WmsQuickAction(
        label: 'Dispatch',
        icon: Icons.upload_rounded,
        onTap: () => context.push(routes.stockOpsRoute),
      ),
      WmsQuickAction(
        label: 'Transfer',
        icon: Icons.swap_horiz_rounded,
        onTap: () => context.push(routes.stockOpsRoute),
      ),
      WmsQuickAction(
        label: 'Tasks',
        icon: Icons.assignment_outlined,
        onTap: () => context.push(routes.tasksRoute),
      ),
      WmsQuickAction(
        label: 'Orders',
        icon: Icons.shopping_cart_outlined,
        onTap: () => context.go(routes.ordersRoute),
      ),
      if (routes.reportsRoute != null)
        WmsQuickAction(
          label: 'Reports',
          icon: Icons.assessment_outlined,
          onTap: () => context.push(routes.reportsRoute!),
        ),
    ];

    return CommandCenterSectionCard(
      title: 'Quick Actions',
      child: GridView.builder(
        itemCount: actions.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisExtent: tileHeight,
        ),
        itemBuilder: (context, index) => _QuickActionTile(action: actions[index]),
      ),
    );
  }

  Widget inventoryHealthAnalytics() {
    final expired = alerts.expiredCount;
    final expiringSoon = alerts.expiringCount;
    final safe = analytics.inStock;

    return CommandCenterSectionCard(
      title: 'Inventory Health Analytics',
      actionLabel: 'View all',
      onAction: () => context.go(routes.inventoryRoute),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Stock status distribution',
            style: WmsDesignTokens.supportingDense(context),
          ),
          const SizedBox(height: AppSpacing.md),
          InventoryDistributionDonut(
            inStock: analytics.inStock,
            lowStock: analytics.lowStock,
            outOfStock: analytics.outOfStock,
            expired: analytics.expired,
            compact: !MobileUi.isTablet(MediaQuery.sizeOf(context).width),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Expiry breakdown', style: WmsDesignTokens.cardTitle(context)),
          const SizedBox(height: AppSpacing.sm),
          CommandCenterExpiryStats(
            expired: expired,
            expiringSoon: expiringSoon,
            safe: safe,
          ),
          const SizedBox(height: AppSpacing.md),
          CommandCenterAdaptiveChart(
            child: InventoryDistributionDonut(
              inStock: safe,
              lowStock: expiringSoon,
              outOfStock: 0,
              expired: math.max(expired, expired + expiringSoon + safe > 0 ? 0 : 1),
              compact: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Expired items', style: WmsDesignTokens.cardTitle(context)),
          const SizedBox(height: AppSpacing.sm),
          CommandCenterExpiredItemsList(alerts: alerts),
        ],
      ),
    );
  }

  Widget orderAnalytics() {
    return CommandCenterSectionCard(
      title: 'Order Analytics',
      actionLabel: 'View orders',
      onAction: () => context.go(routes.ordersRoute),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Orders by status', style: WmsDesignTokens.cardTitle(context)),
          Text('Pipeline distribution', style: WmsDesignTokens.supportingDense(context)),
          const SizedBox(height: AppSpacing.md),
          CommandCenterAdaptiveChart(
            child: CommandCenterOrdersByStatusChart(statusCounts: data.orderStatusCounts),
          ),
          const SizedBox(height: AppSpacing.sm),
          CommandCenterOrderStatusLegend(statusCounts: data.orderStatusCounts),
          const SizedBox(height: AppSpacing.lg),
          Text('Order creation trend', style: WmsDesignTokens.cardTitle(context)),
          Text('Last 7 days', style: WmsDesignTokens.supportingDense(context)),
          const SizedBox(height: AppSpacing.md),
          CommandCenterAdaptiveChart(
            child: DashboardCompactMovementChart(series: data.orderTrend),
          ),
        ],
      ),
    );
  }

  Widget stockMovementAnalytics() {
    return CommandCenterSectionCard(
      title: 'Stock Movement Analytics',
      actionLabel: 'Stock ops',
      onAction: () => context.push(routes.stockOpsRoute),
      child: StockMovementTrendChart(
        series: data.movementTrend,
        embedded: true,
      ),
    );
  }

  Widget warehousePerformance() {
    if (data.warehouses.isEmpty) {
      return CommandCenterSectionCard(
        title: 'Warehouse Performance',
        child: const WmsEmptyState(
          title: 'No warehouses',
          message: 'Warehouse utilization will appear when sites are configured.',
          icon: Icons.warehouse_outlined,
        ),
      );
    }

    return CommandCenterSectionCard(
      title: 'Warehouse Performance',
      actionLabel: 'Manage',
      onAction: () => context.go(routes.inventoryRoute),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < data.warehouses.length && i < 4; i++) ...[
            if (i > 0) Divider(height: AppSpacing.md, color: context.wms.divider),
            CommandCenterWarehousePerfRow(warehouse: data.warehouses[i]),
          ],
        ],
      ),
    );
  }

  Widget taskOverview() {
    return CommandCenterSectionCard(
      title: 'Task Overview',
      actionLabel: 'All tasks',
      onAction: () => context.push(routes.tasksRoute),
      child: CommandCenterTaskOverviewGrid(
        tasks: data.tasks,
        overdue: kpis.overdueTasks,
      ),
    );
  }

  Widget smartInsights() {
    if (data.insights.isEmpty) {
      return CommandCenterSectionCard(
        title: 'Smart Insights',
        child: const WmsEmptyState(
          title: 'No insights',
          message: 'AI-driven operational insights will appear here.',
          icon: Icons.lightbulb_outline,
        ),
      );
    }

    return CommandCenterSectionCard(
      title: 'Smart Insights',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < data.insights.length && i < 8; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            CommandCenterInsightRow(insight: data.insights[i]),
          ],
        ],
      ),
    );
  }

  Widget recentNotifications() {
    return CommandCenterSectionCard(
      title: 'Recent Notifications',
      actionLabel: 'View all',
      onAction: () => context.go(routes.notificationsRoute),
      child: CommandCenterRecentNotificationsList(
        notifications: data.recentNotifications,
      ),
    );
  }

  Widget recentAuditActivity() {
    return CommandCenterSectionCard(
      title: 'Recent Audit Activity',
      actionLabel: routes.auditRoute != null ? 'View all' : null,
      onAction: routes.auditRoute != null
          ? () => context.push(routes.auditRoute!)
          : null,
      child: CommandCenterRecentAuditList(activities: data.teamActivities),
    );
  }

  Widget recentOrders() {
    return CommandCenterSectionCard(
      title: 'Recent Orders',
      actionLabel: 'View all',
      onAction: () => context.go(routes.ordersRoute),
      child: CommandCenterRecentOrdersList(orders: data.recentOrders),
    );
  }

  Widget recentActivityFeed() {
    return CommandCenterSectionCard(
      title: 'Recent Activity Feed',
      child: CommandCenterRecentActivityFeed(movements: data.recentMovements),
    );
  }
}

/// Enterprise section card shell.
class CommandCenterSectionCard extends StatelessWidget {
  const CommandCenterSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: WmsDesignTokens.sectionAccentBarWidth,
                height: WmsDesignTokens.sectionAccentBarHeight,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.sectionTitle(context),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
          if (title.isNotEmpty) const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class CommandCenterAdaptiveChart extends StatelessWidget {
  const CommandCenterAdaptiveChart({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(aspectRatio: 16 / 10, child: child);
  }
}

double _sectionContentWidth(BuildContext context, BoxConstraints constraints) {
  if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
    return constraints.maxWidth;
  }
  return MediaQuery.sizeOf(context).width - AppSpacing.screenPadding * 2;
}

class CommandCenterOperationalAlertsGrid extends StatelessWidget {
  const CommandCenterOperationalAlertsGrid({
    super.key,
    required this.outOfStock,
    required this.lowStock,
    required this.expired,
    required this.expiringSoon,
    required this.pendingOrders,
    required this.urgentTasks,
    this.onTap,
  });

  final int outOfStock;
  final int lowStock;
  final int expired;
  final int expiringSoon;
  final int pendingOrders;
  final int urgentTasks;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final items = [
      _AlertItem('Out Of Stock', outOfStock, colors.error, Icons.remove_shopping_cart_outlined),
      _AlertItem('Low Stock Items', lowStock, colors.warning, Icons.trending_down_rounded),
      _AlertItem('Expired Products', expired, const Color(0xFF7C3AED), Icons.shield_outlined),
      _AlertItem('Expiring Soon', expiringSoon, colors.info, Icons.schedule_rounded),
      _AlertItem('Pending Orders', pendingOrders, colors.primary, Icons.shopping_cart_outlined),
      _AlertItem('Urgent Tasks', urgentTasks, colors.error, Icons.access_time_filled),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = _sectionContentWidth(context, constraints);
        final columns = maxWidth >= MobileUi.tabletWidth ? 3 : 2;
        final itemWidth = (maxWidth - AppSpacing.md * (columns - 1)) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _AlertTile(item: item, onTap: onTap),
              ),
          ],
        );
      },
    );
  }
}

class CommandCenterKpiTileData {
  const CommandCenterKpiTileData({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
    this.onTap,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback? onTap;
  final bool fullWidth;
}

class CommandCenterKpiGrid extends StatelessWidget {
  const CommandCenterKpiGrid({super.key, required this.tiles});

  final List<CommandCenterKpiTileData> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = _sectionContentWidth(context, constraints);
        final isWide = maxWidth >= MobileUi.tabletWidth;
        final defaultWidth = isWide ? (maxWidth - AppSpacing.sm) / 2 : maxWidth;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: tile.fullWidth ? maxWidth : defaultWidth,
                child: _KpiTile(tile: tile),
              ),
          ],
        );
      },
    );
  }
}

class CommandCenterExpiryStats extends StatelessWidget {
  const CommandCenterExpiryStats({
    super.key,
    required this.expired,
    required this.expiringSoon,
    required this.safe,
  });

  final int expired;
  final int expiringSoon;
  final int safe;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Column(
      children: [
        _ExpiryStatRow(label: 'Expired', count: expired, color: colors.error),
        _ExpiryStatRow(label: 'Expiring Soon', count: expiringSoon, color: colors.warning),
        _ExpiryStatRow(label: 'Expiring (30D)', count: expiringSoon, color: colors.info),
        _ExpiryStatRow(label: 'Safe', count: safe, color: colors.success),
      ],
    );
  }
}

class CommandCenterExpiredItemsList extends StatelessWidget {
  const CommandCenterExpiredItemsList({super.key, required this.alerts});

  final SupervisorInventoryAlerts alerts;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final expiredItems = alerts.critical;
    if (expiredItems.isEmpty) {
      return const WmsEmptyState(
        title: 'No expired items',
        message: 'Tracked shelf-life items are within safe windows.',
        icon: Icons.verified_outlined,
      );
    }

    return Column(
      children: [
        for (final item in expiredItems.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.event_busy_outlined, size: WmsIconSizes.status, color: colors.error),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.body(context).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(item.sku, style: WmsDesignTokens.supportingDense(context)),
              ],
            ),
          ),
      ],
    );
  }
}

class CommandCenterOrdersByStatusChart extends StatelessWidget {
  const CommandCenterOrdersByStatusChart({super.key, required this.statusCounts});

  final List<ControlCenterOrderStatus> statusCounts;

  Color _colorFor(String label, WmsUiColors colors) {
    final lower = label.toLowerCase();
    if (lower.contains('pending')) return AppThemeColors.lightTextSecondary;
    if (lower.contains('process')) return colors.info;
    if (lower.contains('pack')) return const Color(0xFF7C3AED);
    if (lower.contains('ship')) return colors.accent;
    if (lower.contains('deliver')) return colors.success;
    return colors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final display = statusCounts.where((s) => s.count > 0).toList();
    if (display.isEmpty) {
      return const Center(
        child: WmsEmptyState(
          title: 'No orders',
          message: 'Order pipeline data will appear here.',
          icon: Icons.shopping_cart_outlined,
        ),
      );
    }

    final maxY = display.fold<double>(0, (m, e) => math.max(m, e.count.toDouble()));

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 4 : maxY * 1.25,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= statusCounts.length) return const SizedBox.shrink();
                final label = statusCounts[i].label;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label.length > 8 ? '${label.substring(0, 7)}…' : label,
                    style: WmsDesignTokens.chartAxis(context),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < statusCounts.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: statusCounts[i].count.toDouble(),
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  color: _colorFor(statusCounts[i].label, colors),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class CommandCenterOrderStatusLegend extends StatelessWidget {
  const CommandCenterOrderStatusLegend({super.key, required this.statusCounts});

  final List<ControlCenterOrderStatus> statusCounts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final s in statusCounts)
          Text('${s.label} ${s.count}', style: WmsDesignTokens.supportingDense(context)),
      ],
    );
  }
}

class CommandCenterWarehousePerfRow extends StatelessWidget {
  const CommandCenterWarehousePerfRow({super.key, required this.warehouse});

  final SupervisorWarehouseOverview warehouse;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final util = warehouse.utilizationPercent ?? 0;
    final color = util >= 85
        ? colors.error
        : util >= 60
            ? colors.warning
            : colors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                warehouse.name,
                style: WmsDesignTokens.body(context).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text('${warehouse.stockCount} units', style: WmsDesignTokens.supportingDense(context)),
          ],
        ),
        if (warehouse.location != null)
          Text(warehouse.location!, style: WmsDesignTokens.supportingDense(context)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: util > 0 ? (util / 100).clamp(0.05, 1.0) : 0,
            minHeight: 6,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
        const SizedBox(height: 2),
        Text('$util% capacity used', style: WmsDesignTokens.supportingDense(context)),
      ],
    );
  }
}

class CommandCenterTaskOverviewGrid extends StatelessWidget {
  const CommandCenterTaskOverviewGrid({
    super.key,
    required this.tasks,
    required this.overdue,
  });

  final SupervisorTaskMonitoring tasks;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final stats = [
      _TaskStat(label: 'Total', value: tasks.total),
      _TaskStat(label: 'Awaiting', value: tasks.pending),
      _TaskStat(label: 'Accepted', value: tasks.waitingConfirmation),
      _TaskStat(label: 'In Progress', value: tasks.inProgress),
      _TaskStat(label: 'Completed', value: tasks.completed),
      _TaskStat(label: 'Rejected', value: 0),
      _TaskStat(label: 'Overdue', value: overdue, color: colors.error),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = _sectionContentWidth(context, constraints);
        final columns = maxWidth >= MobileUi.tabletWidth ? 3 : 2;
        final itemWidth = (maxWidth - AppSpacing.sm * (columns - 1)) / columns;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final stat in stats)
              SizedBox(width: itemWidth, child: _TaskStatTile(stat: stat)),
          ],
        );
      },
    );
  }
}

class CommandCenterInsightRow extends StatelessWidget {
  const CommandCenterInsightRow({super.key, required this.insight});

  final DashboardInsight insight;

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
    return Row(
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
          child: Text(insight.message, style: WmsDesignTokens.body(context)),
        ),
      ],
    );
  }
}

class CommandCenterRecentNotificationsList extends StatelessWidget {
  const CommandCenterRecentNotificationsList({super.key, required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const WmsEmptyState(
        title: 'No notifications',
        message: 'System alerts will appear here.',
        icon: Icons.notifications_outlined,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < notifications.length; i++) ...[
          if (i > 0) Divider(height: AppSpacing.md, color: context.wms.divider),
          _NotificationRow(notification: notifications[i]),
        ],
      ],
    );
  }
}

class CommandCenterRecentAuditList extends StatelessWidget {
  const CommandCenterRecentAuditList({super.key, required this.activities});

  final List<SupervisorTeamActivity> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const WmsEmptyState(
        title: 'No audit activity',
        message: 'System audit logs will appear here.',
        icon: Icons.history,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < activities.length && i < 6; i++) ...[
          if (i > 0) Divider(height: AppSpacing.md, color: context.wms.divider),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activities[i].action,
                      style: WmsDesignTokens.body(context).copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(activities[i].userName, style: WmsDesignTokens.supportingDense(context)),
                  ],
                ),
              ),
              Text(
                WmsFormatters.relativeTime(activities[i].occurredAt),
                style: WmsDesignTokens.supportingDense(context),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class CommandCenterRecentOrdersList extends StatelessWidget {
  const CommandCenterRecentOrdersList({super.key, required this.orders});

  final List<WarehouseOrder> orders;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    if (orders.isEmpty) {
      return const WmsEmptyState(
        title: 'No recent orders',
        message: 'Orders will appear as they are created.',
        icon: Icons.shopping_cart_outlined,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < orders.length && i < 6; i++) ...[
          if (i > 0) Divider(height: AppSpacing.md, color: context.wms.divider),
          Row(
            children: [
              Flexible(
                flex: 2,
                child: Text(
                  orders[i].orderNumber,
                  style: WmsDesignTokens.body(context).copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                flex: 2,
                child: Text(
                  orders[i].customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.supportingDense(context),
                ),
              ),
              WmsOrderStatusBadge(status: orders[i].status, compact: true),
              const SizedBox(width: 4),
              Text(
                WmsFormatters.relativeTime(orders[i].createdAt),
                style: WmsDesignTokens.supportingDense(context),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class CommandCenterRecentActivityFeed extends StatelessWidget {
  const CommandCenterRecentActivityFeed({super.key, required this.movements});

  final List<StockMovement> movements;

  @override
  Widget build(BuildContext context) {
    final entries = movements
        .map(
          (m) => WmsTimelineMapper.fromActionText(
            action: '${m.type} · ${WmsFormatters.quantity(m.quantity)} · ${m.productName}',
            userName: m.performedBy,
            relativeTime: WmsFormatters.relativeTime(m.timestamp),
          ),
        )
        .toList();

    return SizedBox(
      height: 320,
      child: entries.isEmpty
          ? const Center(
              child: WmsEmptyState(
                title: 'No recent activity',
                message: 'Operations and updates will appear here.',
                icon: Icons.timeline_outlined,
              ),
            )
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < entries.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i < entries.length - 1 ? AppSpacing.md : 0,
                      ),
                      child: WmsTimelineEntryTile(
                        entry: entries[i],
                        showConnector: i < entries.length - 1,
                        dense: true,
                        concise: true,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _AlertItem {
  const _AlertItem(this.label, this.count, this.color, this.icon);
  final String label;
  final int count;
  final Color color;
  final IconData icon;
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.item, this.onTap});

  final _AlertItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: WmsPremiumMetricCard.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              WmsPremiumIconBadge(
                icon: item.icon,
                color: item.color,
                size: WmsPremiumMetricCard.badgeSize,
                iconSize: WmsPremiumMetricCard.badgeIconSize,
              ),
              const SizedBox(height: WmsPremiumMetricCard.iconToMetricGap),
              Text(
                '${item.count}',
                style: WmsDesignTokens.operationalAlertCount(
                  context,
                  color: item.color,
                  fontSize: WmsPremiumMetricCard.metricFontSize,
                ),
              ),
              const SizedBox(height: WmsPremiumMetricCard.metricToLabelGap),
              Text(
                item.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WmsDesignTokens.operationalAlertLabel(
                  context,
                  color: item.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpiryStatRow extends StatelessWidget {
  const _ExpiryStatRow({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$count',
            style: WmsDesignTokens.metricValue(context).copyWith(fontSize: 18, color: color),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.tile});

  final CommandCenterKpiTileData tile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: tile.onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: WmsPremiumMetricCard.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  WmsPremiumIconBadge(
                    icon: tile.icon,
                    color: tile.color,
                    size: WmsPremiumMetricCard.badgeSize,
                    iconSize: WmsPremiumMetricCard.badgeIconSize,
                  ),
                  const Spacer(),
                  if (tile.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tile.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tile.badge!,
                        style: WmsDesignTokens.supportingDense(context).copyWith(
                          color: tile.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: WmsPremiumMetricCard.iconToMetricGap),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  tile.value,
                  style: WmsDesignTokens.kpiValue(context).copyWith(
                    fontSize: WmsPremiumMetricCard.metricFontSize,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: WmsPremiumMetricCard.metricToLabelGap),
              Text(tile.label, style: WmsDesignTokens.kpiLabel(context)),
              const SizedBox(height: 2),
              Text(tile.subtitle, style: WmsDesignTokens.supportingDense(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskStat {
  const _TaskStat({required this.label, required this.value, this.color});
  final String label;
  final int value;
  final Color? color;
}

class _TaskStatTile extends StatelessWidget {
  const _TaskStatTile({required this.stat});

  final _TaskStat stat;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final color = stat.color ?? colors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${stat.value}',
          style: WmsDesignTokens.metricValue(context).copyWith(fontSize: 18, color: color),
        ),
        Text(
          stat.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: WmsDesignTokens.supportingDense(context),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final WmsQuickAction action;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final iconColor = action.iconColor ?? primary;
    final iconBg = action.iconBackground ?? iconColor.withValues(alpha: 0.12);

    return AppCard(
      onTap: action.onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      elevated: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: WmsPremiumMetricCard.badgeSize,
            height: WmsPremiumMetricCard.badgeSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withValues(alpha: 0.10), width: 1),
            ),
            child: Icon(
              action.icon,
              color: iconColor,
              size: WmsPremiumMetricCard.badgeIconSize,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            action.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.supportingDense(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                notification.title,
                style: WmsDesignTokens.body(context).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (!notification.read)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.infoMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'UNREAD',
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.info,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        Text(
          notification.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: WmsDesignTokens.supportingDense(context),
        ),
        Text(
          WmsFormatters.relativeTime(notification.createdAt),
          style: WmsDesignTokens.supportingDense(context),
        ),
      ],
    );
  }
}

/// Spaced vertical list of command center sections.
class CommandCenterSectionList extends StatelessWidget {
  const CommandCenterSectionList({
    super.key,
    required this.sections,
    this.padding,
  });

  final List<Widget> sections;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.lg,
          ),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: CommandCenterSections.sectionGap),
          sections[i],
        ],
      ],
    );
  }
}
