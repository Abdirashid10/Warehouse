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
import 'package:logisticsmobile/features/dashboard/presentation/widgets/dashboard_enterprise_widgets.dart';
import 'package:logisticsmobile/features/inventory/presentation/widgets/inventory_analytics_widgets.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/domain/entities/supervisor_dashboard_data.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_activity_timeline.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_dashboard_section.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_quick_actions.dart';
import 'package:logisticsmobile/widgets/wms/wms_badges.dart';
import 'package:logisticsmobile/widgets/wms/wms_premium_cards.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Web-parity warehouse control center scroll body.
class WarehouseControlCenterBody extends StatelessWidget {
  const WarehouseControlCenterBody({
    super.key,
    required this.data,
    required this.inventoryRoute,
    required this.tasksRoute,
    required this.ordersRoute,
    required this.notificationsRoute,
    required this.stockOpsRoute,
    this.reportsRoute,
    this.auditRoute,
    this.showAdminShortcuts = false,
    this.adminShortcuts,
    this.webParityStacked = false,
  });

  final ControlCenterData data;
  final String inventoryRoute;
  final String tasksRoute;
  final String ordersRoute;
  final String notificationsRoute;
  final String stockOpsRoute;
  final String? reportsRoute;
  final String? auditRoute;
  final bool showAdminShortcuts;
  final Widget? adminShortcuts;
  final bool webParityStacked;

  static const gap = AppSpacing.xxl;
  static const chartHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: buildSections(context),
    );
  }

  /// Flat section list for [CustomScrollView] / [SliverList] dashboard layout.
  List<Widget> buildSections(BuildContext context) {
    final alerts = data.inventoryAlerts;
    final kpis = data.kpis;
    final safeSkuCount = (kpis.inStockLines - alerts.expiredCount)
        .clamp(0, kpis.inStockLines);

    return [
      ControlCenterOperationsRow(
        activeWarehouses: data.warehouses.length,
        todayMovements: kpis.stockMovementsToday,
        totalOrders: kpis.totalOrders,
        delivered: data.supervisor.orderMonitoring.delivered,
      ),
      ControlCenterInventoryOverview(
        unitsOnHand: kpis.totalUnitsOnHand,
        inStockLines: kpis.inStockLines,
        lowStock: kpis.lowStockProducts,
        outOfStock: kpis.outOfStockLines,
        stockValue: kpis.totalStockValue,
        onTap: () => context.go(inventoryRoute),
      ),
      ControlCenterExpiryTracking(
        alerts: alerts,
        safeCount: safeSkuCount,
        onViewAll: () => context.go(inventoryRoute),
      ),
      ControlCenterOperationalAlerts(
        outOfStock: alerts.outOfStockCount,
        lowStock: alerts.lowStockCount,
        expired: alerts.expiredCount,
        expiringSoon: alerts.expiringCount,
        pendingOrders: data.pendingOrders,
        urgentTasks: kpis.overdueTasks,
        onTap: () => context.go(inventoryRoute),
      ),
      ControlCenterWarehousePerformance(
        warehouses: data.warehouses,
        onManage: () => context.go(inventoryRoute),
      ),
      ControlCenterOrdersByStatusSection(
        statusCounts: data.orderStatusCounts,
      ),
      ControlCenterStockMovementTrendSection(
        movementTrend: data.movementTrend,
      ),
      ControlCenterRecentActivity(movements: data.recentMovements),
      ControlCenterQuickActions(
        stockOpsRoute: stockOpsRoute,
        tasksRoute: tasksRoute,
        ordersRoute: ordersRoute,
        reportsRoute: reportsRoute,
      ),
      if (data.insights.isNotEmpty)
        ControlCenterSmartInsights(insights: data.insights),
    ];
  }
}

class ControlCenterQuickActions extends StatelessWidget {
  const ControlCenterQuickActions({
    super.key,
    required this.stockOpsRoute,
    required this.tasksRoute,
    required this.ordersRoute,
    this.reportsRoute,
  });

  final String stockOpsRoute;
  final String tasksRoute;
  final String ordersRoute;
  final String? reportsRoute;

  @override
  Widget build(BuildContext context) {
    return WmsQuickActionsSection(
      title: 'Quick Actions',
      compact: true,
      premium: true,
      showSubtitle: false,
      actions: [
        WmsQuickAction(
          label: 'Receive',
          icon: Icons.download_rounded,
          onTap: () => context.push(stockOpsRoute),
        ),
        WmsQuickAction(
          label: 'Dispatch',
          icon: Icons.upload_rounded,
          onTap: () => context.push(stockOpsRoute),
        ),
        WmsQuickAction(
          label: 'Transfer',
          icon: Icons.swap_horiz_rounded,
          onTap: () => context.push(stockOpsRoute),
        ),
        WmsQuickAction(
          label: 'Tasks',
          icon: Icons.assignment_outlined,
          onTap: () => context.push(tasksRoute),
        ),
        WmsQuickAction(
          label: 'Orders',
          icon: Icons.shopping_cart_outlined,
          onTap: () => context.go(ordersRoute),
        ),
        if (reportsRoute != null)
          WmsQuickAction(
            label: 'Reports',
            icon: Icons.assessment_outlined,
            onTap: () => context.push(reportsRoute!),
          ),
      ],
    );
  }
}

class ControlCenterOperationalAlerts extends StatelessWidget {
  const ControlCenterOperationalAlerts({
    super.key,
    required this.outOfStock,
    required this.lowStock,
    required this.expired,
    required this.expiringSoon,
    required this.pendingOrders,
    required this.urgentTasks,
    this.onTap,
    this.forceSingleColumn = false,
  });

  final int outOfStock;
  final int lowStock;
  final int expired;
  final int expiringSoon;
  final int pendingOrders;
  final int urgentTasks;
  final VoidCallback? onTap;
  final bool forceSingleColumn;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final chips = [
      _AlertChipData(
        'Out Of Stock',
        outOfStock,
        colors.error,
        Icons.remove_shopping_cart_outlined,
      ),
      _AlertChipData(
        'Low Stock',
        lowStock,
        colors.warning,
        Icons.trending_down_rounded,
      ),
      _AlertChipData(
        'Expired',
        expired,
        colors.expired,
        Icons.event_busy_outlined,
      ),
      _AlertChipData(
        'Expiring Soon',
        expiringSoon,
        colors.accent,
        Icons.schedule_rounded,
      ),
      _AlertChipData(
        'Pending Orders',
        pendingOrders,
        colors.primary,
        Icons.shopping_cart_outlined,
      ),
      _AlertChipData(
        'Urgent Tasks',
        urgentTasks,
        colors.error,
        Icons.access_time_filled,
      ),
    ];

    final compact =
        MobileUi.isCompactPhone(MediaQuery.sizeOf(context).width);

    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Operational Alerts',
      wrapInCard: false,
      child: _MetricCardGrid(
        forceSingleColumn: forceSingleColumn,
        cards: [
          for (final chip in chips)
            _OperationalAlertTile(data: chip, onTap: onTap, compact: compact),
        ],
      ),
    );
  }
}

/// Responsive metric grid — 1-up when forced, 2-up on phones, 3-up on tablets.
///
/// Every tile is given an identical fixed height so metric values, labels and
/// status pills stay baseline-aligned across a row, the way they do on the web
/// dashboard. Tile widths are floored to whole pixels so sub-pixel rounding can
/// never push the last column onto a new run.
class _MetricCardGrid extends StatelessWidget {
  const _MetricCardGrid({
    required this.cards,
    this.forceSingleColumn = false,
  });

  final List<Widget> cards;
  final bool forceSingleColumn;

  static const double _spacing = AppSpacing.md;
  static const double _extent = WmsPremiumMetricCard.gridExtent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        if (forceSingleColumn || !maxWidth.isFinite) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: _spacing),
                SizedBox(height: _extent, child: cards[i]),
              ],
            ],
          );
        }

        final columns = MobileUi.isTablet(maxWidth) ? 3 : 2;
        final tileWidth =
            ((maxWidth - _spacing * (columns - 1)) / columns).floorToDouble();

        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final card in cards)
              SizedBox(width: tileWidth, height: _extent, child: card),
          ],
        );
      },
    );
  }
}

class _AlertChipData {
  const _AlertChipData(
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

class _OperationalAlertTile extends StatelessWidget {
  const _OperationalAlertTile({
    required this.data,
    this.onTap,
    this.compact = false,
  });

  final _AlertChipData data;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final hasAlert = data.count > 0;

    // In a centered layout the metric number already carries the count, so the
    // old top-right counter chip was pure duplication. It is replaced by a
    // status pill that says something the number does not.
    return WmsMetricCard(
      icon: data.icon,
      color: data.color,
      value: data.count > 999 ? '999+' : '${data.count}',
      label: data.label,
      status: hasAlert ? 'Attention' : 'Clear',
      statusColor: hasAlert ? data.color : colors.success,
      emphasizeValue: true,
      highlighted: hasAlert,
      compact: compact,
      onTap: onTap,
    );
  }
}

class ControlCenterExpiryTracking extends StatelessWidget {
  const ControlCenterExpiryTracking({
    super.key,
    required this.alerts,
    this.safeCount = 0,
    this.onViewAll,
  });

  final SupervisorInventoryAlerts alerts;
  final int safeCount;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final expiredFromList = alerts.critical;
    final expiringSoon = alerts.expiringCount;
    final expired = alerts.expiredCount;
    final safe = safeCount;

    final statsLegend = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ExpiryStatRow(label: 'Expired', count: expired, color: colors.error),
        _ExpiryStatRow(
          label: 'Expiring Soon',
          count: expiringSoon,
          color: colors.warning,
        ),
        _ExpiryStatRow(
          label: 'Expiring (30D)',
          count: expiringSoon,
          color: colors.accent,
        ),
        _ExpiryStatRow(label: 'Safe', count: safe, color: colors.success),
      ],
    );

    final chartColumn = SizedBox(
      width: MobileUi.expiryChartSize,
      height: MobileUi.expiryChartSize,
      child: InventoryDistributionDonut(
        inStock: safe,
        lowStock: expiringSoon,
        outOfStock: 0,
        expired: math.max(
          expired,
          expired + expiringSoon + safe > 0 ? 0 : 1,
        ),
        compact: true,
        showLegend: false,
      ),
    );

    final listColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Expired Items', style: WmsDesignTokens.cardTitle(context)),
        const SizedBox(height: AppSpacing.sm),
        if (expiredFromList.isEmpty)
          const WmsEmptyState(
            title: 'No expired items',
            message: 'Tracked shelf-life items are within safe windows.',
            icon: Icons.verified_outlined,
          )
        else
          for (final item in expiredFromList.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.errorMuted,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      Icons.event_busy_outlined,
                      size: WmsIconSizes.status,
                      color: colors.error,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.body(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      item.sku,
                      style: WmsDesignTokens.supportingDense(context),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );

    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Expiry Tracking',
      actionLabel: onViewAll != null ? 'View all' : null,
      onAction: onViewAll,
      showAccentBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          statsLegend,
          const SizedBox(height: AppSpacing.md),
          Center(child: chartColumn),
          const SizedBox(height: AppSpacing.lg),
          listColumn,
        ],
      ),
    );
  }
}

class _ExpiryStatRow extends StatelessWidget {
  const _ExpiryStatRow({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              '$count',
              style: WmsDesignTokens.metricValue(context).copyWith(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class ControlCenterInventoryOverview extends StatelessWidget {
  const ControlCenterInventoryOverview({
    super.key,
    required this.unitsOnHand,
    required this.inStockLines,
    required this.lowStock,
    required this.outOfStock,
    required this.stockValue,
    this.onTap,
    this.forceSingleColumn = false,
  });

  final num unitsOnHand;
  final int inStockLines;
  final int lowStock;
  final int outOfStock;
  final num stockValue;
  final VoidCallback? onTap;
  final bool forceSingleColumn;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    Widget kpiCard({
      required String label,
      required String value,
      required String subtitle,
      required IconData icon,
      required Color color,
      String? badge,
    }) {
      return _OverviewKpiCard(
        label: label,
        value: value,
        subtitle: subtitle,
        icon: icon,
        color: color,
        badge: badge,
        onTap: onTap,
      );
    }

    final cards = [
      kpiCard(
        label: 'Units On Hand',
        value: WmsFormatters.quantity(unitsOnHand),
        subtitle: 'Total quantity',
        icon: Icons.inventory_2_outlined,
        color: colors.primary,
      ),
      kpiCard(
        label: 'In Stock Lines',
        value: '$inStockLines',
        subtitle: 'Above threshold',
        icon: Icons.check_circle_outline,
        color: colors.success,
      ),
      kpiCard(
        label: 'Low Stock',
        value: '$lowStock',
        subtitle: 'At or below minimum',
        icon: Icons.warning_amber_rounded,
        color: colors.warning,
        badge: lowStock > 0 ? 'Needs attention' : null,
      ),
      kpiCard(
        label: 'Out Of Stock',
        value: '$outOfStock',
        subtitle: 'Zero quantity',
        icon: Icons.remove_shopping_cart_outlined,
        color: colors.error,
        badge: outOfStock > 0 ? 'Critical' : null,
      ),
      kpiCard(
        label: 'Stock Value',
        value: WmsFormatters.currency(stockValue),
        subtitle: 'Σ qty × cost',
        icon: Icons.trending_up_rounded,
        color: colors.accent,
      ),
    ];

    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Inventory Overview',
      wrapInCard: false,
      child: _MetricCardGrid(
        forceSingleColumn: forceSingleColumn,
        cards: cards,
      ),
    );
  }
}

class _OverviewKpiCard extends StatelessWidget {
  const _OverviewKpiCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
    this.onTap,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // The status pill takes the footer line when present, so every card in a
    // row keeps the same number of lines and stays baseline-aligned.
    return WmsMetricCard(
      icon: icon,
      color: color,
      value: value,
      label: label,
      subtitle: subtitle,
      status: badge,
      highlighted: badge != null,
      onTap: onTap,
    );
  }
}

class ControlCenterOperationsRow extends StatelessWidget {
  const ControlCenterOperationsRow({
    super.key,
    required this.activeWarehouses,
    required this.todayMovements,
    required this.totalOrders,
    required this.delivered,
    this.forceSingleColumn = false,
  });

  final int activeWarehouses;
  final int todayMovements;
  final int totalOrders;
  final int delivered;
  final bool forceSingleColumn;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Operations',
      wrapInCard: false,
      child: _MetricCardGrid(
        forceSingleColumn: forceSingleColumn,
        cards: [
          _OverviewKpiCard(
            label: 'Active Warehouses',
            value: '$activeWarehouses',
            subtitle: 'Holding stock',
            icon: Icons.warehouse_outlined,
            color: colors.primary,
          ),
          _OverviewKpiCard(
            label: "Today's Movements",
            value: '$todayMovements',
            subtitle: 'Since midnight',
            icon: Icons.show_chart_rounded,
            color: colors.info,
          ),
          _OverviewKpiCard(
            label: 'Total Orders',
            value: '$totalOrders',
            subtitle: 'Pipeline',
            icon: Icons.shopping_cart_outlined,
            color: colors.accent,
          ),
          _OverviewKpiCard(
            label: 'Delivered',
            value: '$delivered',
            subtitle: 'Completed',
            icon: Icons.local_shipping_outlined,
            color: colors.success,
          ),
        ],
      ),
    );
  }
}

class ControlCenterOrderAnalytics extends StatelessWidget {
  const ControlCenterOrderAnalytics({
    super.key,
    required this.statusCounts,
    required this.orderTrend,
  });

  final List<ControlCenterOrderStatus> statusCounts;
  final DashboardChartTimeSeries orderTrend;

  @override
  Widget build(BuildContext context) {
    final statusCard = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Orders by status',
          style: WmsDesignTokens.cardTitle(context),
        ),
        Text(
          'Pipeline distribution',
          style: WmsDesignTokens.supportingDense(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        AspectRatio(
          aspectRatio: MobileUi.chartAspectRatio(
            MediaQuery.sizeOf(context).width,
          ),
          child: _OrdersByStatusChart(statusCounts: statusCounts),
        ),
        const SizedBox(height: AppSpacing.sm),
        _OrderStatusLegend(statusCounts: statusCounts),
      ],
    );

    final trendCard = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Order creation trend',
          style: WmsDesignTokens.cardTitle(context),
        ),
        Text(
          'Last 7 days',
          style: WmsDesignTokens.supportingDense(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        AspectRatio(
          aspectRatio: MobileUi.chartAspectRatio(
            MediaQuery.sizeOf(context).width,
          ),
          child: DashboardCompactMovementChart(series: orderTrend),
        ),
      ],
    );

    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Order Analytics',
      showAccentBorder: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          statusCard,
          const SizedBox(height: AppSpacing.lg),
          trendCard,
        ],
      ),
    );
  }
}

class _OrdersByStatusChart extends StatelessWidget {
  const _OrdersByStatusChart({required this.statusCounts});

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
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 24),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= statusCounts.length) {
                  return const SizedBox.shrink();
                }
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

class _OrderStatusLegend extends StatelessWidget {
  const _OrderStatusLegend({required this.statusCounts});

  final List<ControlCenterOrderStatus> statusCounts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final s in statusCounts)
          Text(
            '${s.label} ${s.count}',
            style: WmsDesignTokens.supportingDense(context),
          ),
      ],
    );
  }
}

class ControlCenterMovementAndHealth extends StatelessWidget {
  const ControlCenterMovementAndHealth({
    super.key,
    required this.movementTrend,
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
    required this.expired,
  });

  final DashboardChartTimeSeries movementTrend;
  final int inStock;
  final int lowStock;
  final int outOfStock;
  final int expired;

  @override
  Widget build(BuildContext context) {
    final movementCard = StockMovementTrendChart(series: movementTrend);

    final healthCard = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Inventory health',
          style: WmsDesignTokens.cardTitle(context),
        ),
        Text(
          'Stock status distribution',
          style: WmsDesignTokens.supportingDense(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        InventoryDistributionDonut(
          inStock: inStock,
          lowStock: lowStock,
          outOfStock: outOfStock,
          expired: expired,
          compact: !MobileUi.isTablet(MediaQuery.sizeOf(context).width),
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        movementCard,
        const SizedBox(height: AppSpacing.md),
        AppCard(
          elevated: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: healthCard,
        ),
      ],
    );
  }
}

/// Web dashboard section — orders by status bar chart.
class ControlCenterOrdersByStatusSection extends StatelessWidget {
  const ControlCenterOrdersByStatusSection({
    super.key,
    required this.statusCounts,
  });

  final List<ControlCenterOrderStatus> statusCounts;

  @override
  Widget build(BuildContext context) {
    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Orders By Status',
      showAccentBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pipeline distribution',
            style: WmsDesignTokens.supportingDense(context),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: WarehouseControlCenterBody.chartHeight,
            child: _OrdersByStatusChart(statusCounts: statusCounts),
          ),
          const SizedBox(height: AppSpacing.sm),
          _OrderStatusLegend(statusCounts: statusCounts),
        ],
      ),
    );
  }
}

/// Web dashboard section — order creation trend line chart.
class ControlCenterOrderCreationTrendSection extends StatelessWidget {
  const ControlCenterOrderCreationTrendSection({
    super.key,
    required this.orderTrend,
  });

  final DashboardChartTimeSeries orderTrend;

  @override
  Widget build(BuildContext context) {
    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Order Creation Trend',
      showAccentBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Last 7 days',
            style: WmsDesignTokens.supportingDense(context),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: WarehouseControlCenterBody.chartHeight,
            child: DashboardCompactMovementChart(series: orderTrend),
          ),
        ],
      ),
    );
  }
}

/// Web dashboard section — stock movement trend chart.
class ControlCenterStockMovementTrendSection extends StatelessWidget {
  const ControlCenterStockMovementTrendSection({
    super.key,
    required this.movementTrend,
  });

  final DashboardChartTimeSeries movementTrend;

  @override
  Widget build(BuildContext context) {
    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Stock Movement Summary',
      showAccentBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Recent inbound, outbound and transfer activity',
            style: WmsDesignTokens.supportingDense(context),
          ),
          const SizedBox(height: AppSpacing.md),
          // Chart is fully responsive and sizes itself — avoid fixed height.
          StockMovementTrendChart(series: movementTrend),
        ],
      ),
    );
  }
}

/// Web dashboard section — inventory health donut.
class ControlCenterInventoryHealthSection extends StatelessWidget {
  const ControlCenterInventoryHealthSection({
    super.key,
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
    required this.expired,
  });

  final int inStock;
  final int lowStock;
  final int outOfStock;
  final int expired;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final total = (inStock + lowStock + outOfStock + expired).clamp(1, 999999);

    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Inventory Health',
      showAccentBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Stock status distribution',
            style: WmsDesignTokens.supportingDense(context),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (inStock > 0)
                    Expanded(
                      flex: inStock,
                      child: ColoredBox(color: colors.success),
                    ),
                  if (lowStock > 0)
                    Expanded(
                      flex: lowStock,
                      child: ColoredBox(color: colors.warning),
                    ),
                  if (outOfStock > 0)
                    Expanded(
                      flex: outOfStock,
                      child: ColoredBox(color: colors.error),
                    ),
                  if (expired > 0)
                    Expanded(
                      flex: expired,
                      child: ColoredBox(color: colors.expired),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _InventoryHealthStatRow(
            label: 'In Stock',
            count: inStock,
            percent: inStock / total,
            color: colors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          _InventoryHealthStatRow(
            label: 'Low Stock',
            count: lowStock,
            percent: lowStock / total,
            color: colors.warning,
          ),
          const SizedBox(height: AppSpacing.sm),
          _InventoryHealthStatRow(
            label: 'Out Of Stock',
            count: outOfStock,
            percent: outOfStock / total,
            color: colors.error,
          ),
          const SizedBox(height: AppSpacing.sm),
          _InventoryHealthStatRow(
            label: 'Expired',
            count: expired,
            percent: expired / total,
            color: colors.expired,
          ),
          const SizedBox(height: AppSpacing.md),
          InventoryDistributionDonut(
            inStock: inStock,
            lowStock: lowStock,
            outOfStock: outOfStock,
            expired: expired,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _InventoryHealthStatRow extends StatelessWidget {
  const _InventoryHealthStatRow({
    required this.label,
    required this.count,
    required this.percent,
    required this.color,
  });

  final String label;
  final int count;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.kpiLabel(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$count',
          style: WmsDesignTokens.kpiValue(context).copyWith(
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}

class ControlCenterWarehousePerformance extends StatelessWidget {
  const ControlCenterWarehousePerformance({
    super.key,
    required this.warehouses,
    this.onManage,
  });

  final List<SupervisorWarehouseOverview> warehouses;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    if (warehouses.isEmpty) return const SizedBox.shrink();

    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Warehouse Performance',
      count: warehouses.length,
      actionLabel: onManage != null ? 'Manage →' : null,
      onAction: onManage,
      wrapInCard: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final columns = maxWidth < 360 ? 1 : 2;
          const crossAxisSpacing = AppSpacing.md;
          const mainAxisSpacing = AppSpacing.md;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: warehouses.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              mainAxisExtent: columns == 1 ? 148 : 168,
            ),
            itemBuilder: (context, index) {
              return _WarehousePerfCard(warehouse: warehouses[index]);
            },
          );
        },
      ),
    );
  }
}

class _WarehousePerfCard extends StatelessWidget {
  const _WarehousePerfCard({required this.warehouse});

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
    final status = util >= 85
        ? 'High Load'
        : util >= 60
            ? 'Operational'
            : 'Available';

    return AppCard(
      elevated: true,
      padding: WmsPremiumMetricCard.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              WmsPremiumIconBadge(
                icon: Icons.warehouse_outlined,
                color: color,
                size: 36,
                iconSize: 18,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Text(
                  status,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            warehouse.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.body(context).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (warehouse.location != null)
            Text(
              warehouse.location!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context),
            ),
          const Spacer(),
          Row(
            children: [
              Text(
                '${warehouse.stockCount} units',
                style: WmsDesignTokens.supportingDense(context),
              ),
              const Spacer(),
              Text(
                '$util%',
                style: WmsDesignTokens.supportingDense(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: util > 0 ? (util / 100).clamp(0.05, 1.0) : 0,
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class ControlCenterTaskOverview extends StatelessWidget {
  const ControlCenterTaskOverview({
    super.key,
    required this.tasks,
    required this.overdue,
    this.onViewAll,
  });

  final SupervisorTaskMonitoring tasks;
  final int overdue;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final chips = [
      _TaskStatChip(label: 'Total', value: tasks.total),
      _TaskStatChip(label: 'Awaiting', value: tasks.pending),
      _TaskStatChip(label: 'Accepted', value: tasks.waitingConfirmation),
      _TaskStatChip(label: 'In Progress', value: tasks.inProgress),
      _TaskStatChip(label: 'Completed', value: tasks.completed),
      _TaskStatChip(label: 'Rejected', value: 0),
      _TaskStatChip(label: 'Overdue', value: overdue, color: colors.error),
    ];

    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Task Overview',
      actionLabel: onViewAll != null ? 'All tasks' : null,
      onAction: onViewAll,
      showAccentBorder: false,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              SizedBox(width: 76, child: chips[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskStatChip extends StatelessWidget {
  const _TaskStatChip({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final c = color ?? colors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: WmsDesignTokens.metricValue(context).copyWith(
                fontSize: 18,
                color: c,
              ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: WmsDesignTokens.supportingDense(context),
        ),
      ],
    );
  }
}

class ControlCenterSmartInsights extends StatelessWidget {
  const ControlCenterSmartInsights({
    super.key,
    required this.insights,
  });

  final List<DashboardInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Smart Insights',
      showAccentBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < insights.length && i < 8; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _InsightRow(insight: insights[i]),
          ],
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});

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
        Expanded(
          child: Text(
            insight.message,
            style: WmsDesignTokens.body(context),
          ),
        ),
      ],
    );
  }
}

class ControlCenterRecentNotifications extends StatelessWidget {
  const ControlCenterRecentNotifications({
    super.key,
    required this.notifications,
    this.onViewAll,
  });

  final List<AppNotification> notifications;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Recent Notifications',
      actionLabel: onViewAll != null ? 'View all' : null,
      onAction: onViewAll,
      showAccentBorder: false,
      child: notifications.isEmpty
          ? const WmsEmptyState(
              title: 'No notifications',
              message: 'System alerts will appear here.',
              icon: Icons.notifications_outlined,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < notifications.length; i++) ...[
                  if (i > 0)
                    Divider(height: AppSpacing.lg, color: context.wms.divider),
                  _NotificationRow(notification: notifications[i]),
                ],
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
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: WmsDesignTokens.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (!notification.read)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.infoMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: colors.info.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  'UNREAD',
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: colors.info,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
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

class ControlCenterRecentAudit extends StatelessWidget {
  const ControlCenterRecentAudit({
    super.key,
    required this.activities,
    this.onViewAll,
  });

  final List<SupervisorTeamActivity> activities;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Recent Audit Activity',
      actionLabel: onViewAll != null ? 'View all' : null,
      onAction: onViewAll,
      showAccentBorder: false,
      child: activities.isEmpty
          ? const WmsEmptyState(
              title: 'No audit activity',
              message: 'System audit logs will appear here.',
              icon: Icons.history,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < activities.length && i < 6; i++) ...[
                  if (i > 0)
                    Divider(height: AppSpacing.lg, color: context.wms.divider),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activities[i].action,
                              style: WmsDesignTokens.body(context).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              activities[i].userName,
                              style: WmsDesignTokens.supportingDense(context),
                            ),
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
            ),
    );
  }
}

class ControlCenterRecentOrders extends StatelessWidget {
  const ControlCenterRecentOrders({
    super.key,
    required this.orders,
    this.onViewAll,
  });

  final List<WarehouseOrder> orders;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Recent Orders',
      actionLabel: onViewAll != null ? 'View all' : null,
      onAction: onViewAll,
      showAccentBorder: false,
      child: orders.isEmpty
          ? const WmsEmptyState(
              title: 'No recent orders',
              message: 'Orders will appear as they are created.',
              icon: Icons.shopping_cart_outlined,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < orders.length && i < 6; i++) ...[
                  if (i > 0)
                    Divider(height: AppSpacing.lg, color: context.wms.divider),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          orders[i].orderNumber,
                          style: WmsDesignTokens.body(context).copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
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
            ),
    );
  }
}

class ControlCenterRecentActivity extends StatelessWidget {
  const ControlCenterRecentActivity({
    super.key,
    required this.movements,
  });

  static const _listHeight = 320.0;

  final List<StockMovement> movements;

  @override
  Widget build(BuildContext context) {
    final entries = movements
        .map(
          (m) => WmsTimelineMapper.fromActionText(
            action:
                '${m.type} · ${WmsFormatters.quantity(m.quantity)} · ${m.productName}',
            userName: m.performedBy,
            relativeTime: WmsFormatters.relativeTime(m.timestamp),
          ),
        )
        .toList();

    return WmsDashboardSection(
      style: WmsSectionStyle.webParity,
      title: 'Recent Activity',
      showAccentBorder: false,
      child: entries.isEmpty
          ? const SizedBox(
              height: _listHeight,
              child: Center(
                child: WmsEmptyState(
                  title: 'No recent activity',
                  message: 'Operations and updates will appear here.',
                  icon: Icons.timeline_outlined,
                ),
              ),
            )
          : SizedBox(
              height: _listHeight,
              child: SingleChildScrollView(
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
            ),
    );
  }
}
