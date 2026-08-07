import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/domain/entities/supervisor_dashboard_data.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/presentation/widgets/supervisor_executive_analytics.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/routes/wms_route_paths.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_activity_timeline.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_dashboard_section.dart';
import 'package:logisticsmobile/widgets/wms/wms_badges.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Compact spacing for enterprise home dashboards.
abstract final class DashboardUi {
  static const sectionGap = AppSpacing.xxl;
  static const commandCenterGap = AppSpacing.xxl;
  static const tileGap = AppSpacing.sm;

  static int criticalAlertCount(DashboardAlerts alerts) =>
      alerts.outOfStockCount + alerts.expiredCount + alerts.expiringSoonCount;

  static int totalCriticalCount({
    required int outOfStock,
    required int expired,
    required int expiringSoon,
    required int criticalItems,
  }) => outOfStock + expired + expiringSoon + criticalItems;
}

/// Multi-series time-series payload for dashboard charts.
class DashboardChartTimeSeries {
  const DashboardChartTimeSeries({required this.labels, required this.lines});

  final List<String> labels;
  final List<DashboardChartLine> lines;

  bool get hasData =>
      labels.isNotEmpty &&
      lines.any((line) => line.values.any((value) => value > 0));
}

/// What a chart series represents.
///
/// Series carry a role instead of a literal colour because they are built in
/// the data layer, where no theme exists — a colour chosen at parse time is
/// frozen to whichever brightness happened to be active, and cannot follow a
/// mode switch.
enum DashboardSeriesRole {
  inbound,
  outbound,
  transfer,
  orders,
  lowStock,
  utilization,
  neutral,
}

class DashboardChartLine {
  const DashboardChartLine({
    required this.label,
    required this.values,
    this.role = DashboardSeriesRole.neutral,
    this.color,
  });

  final String label;
  final List<double> values;
  final DashboardSeriesRole role;

  /// Explicit override. Prefer [role]; this exists for callers that already
  /// resolved a colour from the theme themselves.
  final Color? color;

  Color resolveColor(WmsUiColors colors) =>
      color ??
      switch (role) {
        DashboardSeriesRole.inbound => colors.success,
        DashboardSeriesRole.outbound => colors.outbound,
        DashboardSeriesRole.transfer => colors.info,
        DashboardSeriesRole.orders => colors.primary,
        DashboardSeriesRole.lowStock => colors.warning,
        DashboardSeriesRole.utilization => colors.accent,
        DashboardSeriesRole.neutral => colors.textSecondary,
      };
}

class DashboardExecutiveSummary extends StatelessWidget {
  const DashboardExecutiveSummary({
    super.key,
    required this.totalInventory,
    required this.activeWarehouses,
    required this.lowStock,
    required this.criticalAlerts,
    this.onInventoryTap,
    this.onWarehousesTap,
    this.onLowStockTap,
    this.onAlertsTap,
  });

  final String totalInventory;
  final int activeWarehouses;
  final int lowStock;
  final int criticalAlerts;
  final VoidCallback? onInventoryTap;
  final VoidCallback? onWarehousesTap;
  final VoidCallback? onLowStockTap;
  final VoidCallback? onAlertsTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return WmsDashboardSection(
      title: 'Executive KPI Overview',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = (constraints.maxWidth - DashboardUi.tileGap) / 2;
          return Wrap(
            spacing: DashboardUi.tileGap,
            runSpacing: DashboardUi.tileGap,
            children: [
              SizedBox(
                width: tileWidth,
                child: _SummaryMetricCard(
                  label: 'Total Units',
                  value: totalInventory,
                  icon: Icons.inventory_2_outlined,
                  color: colors.primary,
                  background: colors.primaryMuted,
                  onTap: onInventoryTap,
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _SummaryMetricCard(
                  label: 'Active Warehouses',
                  value: '$activeWarehouses',
                  icon: Icons.warehouse_outlined,
                  color: colors.info,
                  background: colors.infoMuted,
                  onTap: onWarehousesTap,
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _SummaryMetricCard(
                  label: 'Low Stock',
                  value: '$lowStock',
                  icon: Icons.trending_down_rounded,
                  color: colors.warning,
                  background: colors.warningMuted,
                  onTap: onLowStockTap,
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _SummaryMetricCard(
                  label: 'Critical Alerts',
                  value: '$criticalAlerts',
                  icon: Icons.error_outline_rounded,
                  color: colors.error,
                  background: colors.errorMuted,
                  onTap: onAlertsTap,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return AppCard(
      elevated: true,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(WmsIconSizes.iconCardPadding),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: WmsDesignTokens.kpiIconSize, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: WmsDesignTokens.kpiValue(context, width: width),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.kpiLabel(context),
          ),
        ],
      ),
    );
  }
}

class DashboardCriticalAlertsPanel extends StatelessWidget {
  const DashboardCriticalAlertsPanel({
    super.key,
    required this.alerts,
    this.insights = const [],
    this.supervisorAlerts,
    this.onViewAll,
  });

  final DashboardAlerts alerts;
  final List<DashboardInsight> insights;
  final SupervisorInventoryAlerts? supervisorAlerts;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final priorityItems = _buildPriorityItems(colors);
    if (priorityItems.isEmpty) {
      return WmsDashboardSection(
        title: 'Critical Alerts',
        child: AppCard(
          elevated: true,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: const WmsEmptyState(
            title: 'All clear',
            message: 'No critical alerts require attention.',
            icon: Icons.verified_outlined,
          ),
        ),
      );
    }

    return WmsDashboardSection(
      title: 'Critical Alerts',
      count: priorityItems.length,
      actionLabel: onViewAll != null ? 'View all' : null,
      onAction: onViewAll,
      child: AppCard(
        elevated: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < priorityItems.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              priorityItems[i],
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPriorityItems(WmsUiColors colors) {
    final items = <_AlertEntry>[];

    if (supervisorAlerts != null) {
      final sa = supervisorAlerts!;
      for (final item in sa.critical.take(2)) {
        items.add(
          _AlertEntry(
            priority: 0,
            label: item.productName,
            detail: '${item.sku} · ${item.warehouseName}',
            count: item.quantity?.toInt(),
            color: colors.error,
            icon: Icons.error_outline_rounded,
          ),
        );
      }
      for (final item in sa.expiring.take(1)) {
        items.add(
          _AlertEntry(
            priority: 1,
            label: item.productName,
            detail: 'Expiring · ${item.warehouseName}',
            count: item.quantity?.toInt(),
            color: colors.warning,
            icon: Icons.schedule_rounded,
          ),
        );
      }
      if (sa.outOfStockCount > 0 && items.length < 3) {
        items.add(
          _AlertEntry(
            priority: 2,
            label: 'Out of stock lines',
            detail: 'Immediate replenishment required',
            count: sa.outOfStockCount,
            color: colors.error,
            icon: Icons.remove_shopping_cart_outlined,
          ),
        );
      }
      if (sa.lowStockCount > 0 && items.length < 3) {
        items.add(
          _AlertEntry(
            priority: 3,
            label: 'Low stock items',
            detail: 'Below minimum threshold',
            count: sa.lowStockCount,
            color: colors.warning,
            icon: Icons.trending_down_rounded,
          ),
        );
      }
    } else {
      if (alerts.outOfStockCount > 0) {
        items.add(
          _AlertEntry(
            priority: 0,
            label: 'Out of stock',
            detail: 'SKUs at zero quantity',
            count: alerts.outOfStockCount,
            color: colors.error,
            icon: Icons.remove_shopping_cart_outlined,
          ),
        );
      }
      if (alerts.expiredCount > 0) {
        items.add(
          _AlertEntry(
            priority: 1,
            label: 'Expired inventory',
            detail: 'Requires quarantine or disposal',
            count: alerts.expiredCount,
            color: colors.error,
            icon: Icons.event_busy_outlined,
          ),
        );
      }
      if (alerts.expiringSoonCount > 0) {
        items.add(
          _AlertEntry(
            priority: 2,
            label: 'Expiring soon',
            detail: 'Action needed within shelf-life window',
            count: alerts.expiringSoonCount,
            color: colors.warning,
            icon: Icons.schedule_rounded,
          ),
        );
      }
      if (alerts.lowStockCount > 0) {
        items.add(
          _AlertEntry(
            priority: 3,
            label: 'Low stock',
            detail: 'Below reorder point',
            count: alerts.lowStockCount,
            color: colors.warning,
            icon: Icons.trending_down_rounded,
          ),
        );
      }
      for (final insight in insights) {
        final severity = insight.severity.toLowerCase();
        if (severity.contains('critical') || severity.contains('error')) {
          items.add(
            _AlertEntry(
              priority: severity.contains('critical') ? 0 : 2,
              label: insight.message,
              detail: 'System insight',
              color: colors.error,
              icon: Icons.report_problem_outlined,
            ),
          );
        }
      }
    }

    items.sort((a, b) => a.priority.compareTo(b.priority));
    return items.take(3).map((e) => _CriticalAlertRow(entry: e)).toList();
  }
}

class _AlertEntry {
  const _AlertEntry({
    required this.priority,
    required this.label,
    required this.detail,
    required this.color,
    required this.icon,
    this.count,
  });

  final int priority;
  final String label;
  final String detail;
  final Color color;
  final IconData icon;
  final int? count;
}

class _CriticalAlertRow extends StatelessWidget {
  const _CriticalAlertRow({required this.entry});

  final _AlertEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: 40,
          decoration: BoxDecoration(
            color: entry.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(entry.icon, size: WmsIconSizes.listLeading, color: entry.color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                entry.detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (entry.count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              '${entry.count}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: entry.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class DashboardOperationsToday extends StatelessWidget {
  const DashboardOperationsToday({
    super.key,
    required this.inbound,
    required this.outbound,
    required this.transfers,
    required this.orders,
    this.todayMovements,
  });

  final int inbound;
  final int outbound;
  final int transfers;
  final int orders;
  final int? todayMovements;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final total = todayMovements ?? inbound + outbound + transfers;

    return WmsDashboardSection(
      title: 'Operations Overview',
      subtitle: total > 0
          ? "$total movements today"
          : "Today's movement and order activity",
      child: Row(
        children: [
          Expanded(
            child: _OpMetricTile(
              label: 'Inbound',
              count: inbound,
              color: colors.success,
              icon: Icons.download_rounded,
            ),
          ),
          const SizedBox(width: DashboardUi.tileGap),
          Expanded(
            child: _OpMetricTile(
              label: 'Outbound',
              count: outbound,
              color: const Color(0xFFC2410C),
              icon: Icons.upload_rounded,
            ),
          ),
          const SizedBox(width: DashboardUi.tileGap),
          Expanded(
            child: _OpMetricTile(
              label: 'Transfers',
              count: transfers,
              color: colors.info,
              icon: Icons.swap_horiz_rounded,
            ),
          ),
          const SizedBox(width: DashboardUi.tileGap),
          Expanded(
            child: _OpMetricTile(
              label: 'Orders',
              count: orders,
              color: colors.accent,
              icon: Icons.shopping_bag_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpMetricTile extends StatelessWidget {
  const _OpMetricTile({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: WmsIconSizes.kpi, color: color),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$count',
              style: WmsDesignTokens.metricValue(
                context,
              ).copyWith(color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.kpiLabel(context),
          ),
        ],
      ),
    );
  }
}

class DashboardInventoryHealth extends StatelessWidget {
  const DashboardInventoryHealth({
    super.key,
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
    required this.totalUnitsLabel,
    this.onDetailsTap,
  });

  final int inStock;
  final int lowStock;
  final int outOfStock;
  final String totalUnitsLabel;
  final VoidCallback? onDetailsTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final total = (inStock + lowStock + outOfStock).clamp(1, 999999);
    final wms = context.wms;

    return WmsDashboardSection(
      title: 'Inventory Health',
      actionLabel: onDetailsTap != null ? 'Details' : null,
      onAction: onDetailsTap,
      child: AppCard(
        elevated: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _HealthRow(
              label: 'In stock',
              count: inStock,
              percent: inStock / total,
              color: colors.success,
            ),
            const SizedBox(height: AppSpacing.sm),
            _HealthRow(
              label: 'Low stock',
              count: lowStock,
              percent: lowStock / total,
              color: colors.warning,
            ),
            const SizedBox(height: AppSpacing.sm),
            _HealthRow(
              label: 'Out of stock',
              count: outOfStock,
              percent: outOfStock / total,
              color: colors.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              totalUnitsLabel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: wms.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({
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
    final colors = WmsUiColors.of(context);
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: colors.surfaceElevated,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 36,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class DashboardTaskCenter extends StatelessWidget {
  const DashboardTaskCenter({
    super.key,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.completionRate,
    this.onViewAll,
    this.activeTasks = const [],
    this.tasksRoute,
  });

  final int pending;
  final int inProgress;
  final int completed;
  final int completionRate;
  final VoidCallback? onViewAll;
  final List<WarehouseTask> activeTasks;
  final String? tasksRoute;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final preview = activeTasks.where((t) => t.isActive).take(3).toList();

    return WmsDashboardSection(
      title: 'Task Center',
      count: pending + inProgress,
      actionLabel: onViewAll != null ? 'View all' : null,
      onAction: onViewAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth =
                  (constraints.maxWidth - DashboardUi.tileGap) / 2;
              return Wrap(
                spacing: DashboardUi.tileGap,
                runSpacing: DashboardUi.tileGap,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _TaskMetricTile(
                      label: 'Pending',
                      count: pending,
                      color: colors.warning,
                      icon: Icons.schedule_outlined,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _TaskMetricTile(
                      label: 'In Progress',
                      count: inProgress,
                      color: colors.info,
                      icon: Icons.play_circle_outline,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _TaskMetricTile(
                      label: 'Completed',
                      count: completed,
                      color: colors.success,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _TaskMetricTile(
                      label: 'Completion Rate',
                      count: completionRate,
                      suffix: '%',
                      color: colors.primary,
                      icon: Icons.donut_large_outlined,
                    ),
                  ),
                ],
              );
            },
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final task in preview)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: DashboardTaskPreviewCard(
                  task: task,
                  tasksRoute: tasksRoute,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TaskMetricTile extends StatelessWidget {
  const _TaskMetricTile({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    this.suffix = '',
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(WmsIconSizes.iconCardPadding),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: WmsIconSizes.kpi, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count$suffix',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardTaskPreviewCard extends StatelessWidget {
  const DashboardTaskPreviewCard({
    super.key,
    required this.task,
    this.tasksRoute,
  });

  final WarehouseTask task;
  final String? tasksRoute;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push(WmsRoutePaths.taskDetail(context, task.id)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  task.taskType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          WmsTaskStatusBadge(status: task.status),
        ],
      ),
    );
  }
}

class DashboardWarehouseGrid extends StatelessWidget {
  const DashboardWarehouseGrid({
    super.key,
    this.staffWarehouses = const [],
    this.supervisorWarehouses,
  });

  final List<WarehouseStat> staffWarehouses;
  final List<SupervisorWarehouseOverview>? supervisorWarehouses;

  @override
  Widget build(BuildContext context) {
    if (staffWarehouses.isNotEmpty) {
      return _StaffWarehouseGrid(warehouses: staffWarehouses);
    }
    if (supervisorWarehouses != null && supervisorWarehouses!.isNotEmpty) {
      return _SupervisorWarehouseGrid(warehouses: supervisorWarehouses!);
    }
    return const SizedBox.shrink();
  }
}

class _StaffWarehouseGrid extends StatelessWidget {
  const _StaffWarehouseGrid({required this.warehouses});

  final List<WarehouseStat> warehouses;

  @override
  Widget build(BuildContext context) {
    return WmsDashboardSection(
      title: 'Warehouse Overview',
      count: warehouses.length,
      child: Column(
        children: [
          for (var i = 0; i < warehouses.length; i++) ...[
            if (i > 0) const SizedBox(height: DashboardUi.tileGap),
            _WarehouseCard(
              name: warehouses[i].name,
              units: WmsFormatters.quantity(warehouses[i].totalUnits),
              utilization: warehouses[i].utilization,
            ),
          ],
        ],
      ),
    );
  }
}

class _SupervisorWarehouseGrid extends StatelessWidget {
  const _SupervisorWarehouseGrid({required this.warehouses});

  final List<SupervisorWarehouseOverview> warehouses;

  @override
  Widget build(BuildContext context) {
    return WmsDashboardSection(
      title: 'Warehouse Overview',
      count: warehouses.length,
      child: Column(
        children: [
          for (var i = 0; i < warehouses.length; i++) ...[
            if (i > 0) const SizedBox(height: DashboardUi.tileGap),
            _WarehouseCard(
              name: warehouses[i].name,
              units: WmsFormatters.quantity(warehouses[i].stockCount),
              utilization: warehouses[i].utilizationPercent ?? 0,
              staffCount: warehouses[i].activeStaffCount,
              status: warehouses[i].status,
            ),
          ],
        ],
      ),
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  const _WarehouseCard({
    required this.name,
    required this.units,
    required this.utilization,
    this.staffCount,
    this.status,
  });

  final String name;
  final String units;
  final int utilization;
  final int? staffCount;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final capacityColor = utilization >= 85
        ? colors.error
        : utilization >= 60
        ? colors.warning
        : colors.success;

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warehouse_outlined,
                size: WmsIconSizes.listLeading,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$units units${staffCount != null ? ' · $staffCount staff' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (status != null) ...[
            const SizedBox(height: 2),
            Text(
              status!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                'Utilization',
                style: WmsDesignTokens.supportingDense(context),
              ),
              const Spacer(),
              Text(
                '$utilization%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: capacityColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (utilization / 100).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: colors.surfaceElevated,
              color: capacityColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Derives staff dashboard metrics from existing data (no API changes).
abstract final class StaffDashboardMetrics {
  static bool _isToday(DateTime? dt) {
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  static ({int inbound, int outbound, int transfers, int orders})
  operationsToday(StaffDashboardData data) {
    var inbound = 0, outbound = 0, transfers = 0, orders = 0;

    for (final m in data.movements) {
      if (!_isToday(m.timestamp)) continue;
      switch (m.type.toUpperCase()) {
        case 'INBOUND':
          inbound++;
        case 'OUTBOUND':
          outbound++;
        case 'TRANSFER':
          transfers++;
      }
    }

    for (final t in data.tasks) {
      if (!_isToday(t.dueDate) && t.status != WmsTaskStatuses.inProgress) {
        continue;
      }
      if (t.taskType == WmsTaskTypes.orderPacking ||
          t.taskType == WmsTaskTypes.outboundDispatch) {
        orders++;
      }
    }

    if (inbound + outbound + transfers == 0) {
      for (final t in data.tasks.where((t) => t.isActive)) {
        switch (t.movementType) {
          case 'INBOUND':
            inbound++;
          case 'OUTBOUND':
            outbound++;
          case 'TRANSFER':
            transfers++;
        }
        if (t.taskType == WmsTaskTypes.orderPacking) orders++;
      }
    }

    return (
      inbound: inbound,
      outbound: outbound,
      transfers: transfers,
      orders: orders,
    );
  }

  static ({int pending, int inProgress, int completed, int completionRate})
  taskCenter(List<WarehouseTask> tasks) {
    var pending = 0, inProgress = 0, completed = 0;
    for (final t in tasks) {
      if (t.status == WmsTaskStatuses.completed) {
        completed++;
      } else if (t.status == WmsTaskStatuses.inProgress ||
          t.status == WmsTaskStatuses.waitingConfirmation) {
        inProgress++;
      } else if (t.status == WmsTaskStatuses.pending ||
          t.status == WmsTaskStatuses.accepted) {
        pending++;
      }
    }
    final total = pending + inProgress + completed;
    final rate = total > 0 ? ((completed / total) * 100).round() : 0;
    return (
      pending: pending,
      inProgress: inProgress,
      completed: completed,
      completionRate: rate,
    );
  }

  static int criticalAlerts(DashboardAlerts alerts) =>
      alerts.outOfStockCount + alerts.expiredCount + alerts.expiringSoonCount;

  static int weeklyMovements(StaffDashboardData data) {
    final start = DateTime.now().subtract(const Duration(days: 7));
    return data.movements
        .where((m) => m.timestamp != null && m.timestamp!.isAfter(start))
        .length;
  }

  static int avgUtilization(List<WarehouseStat> warehouses) {
    if (warehouses.isEmpty) return 0;
    final sum = warehouses.fold<int>(0, (s, w) => s + w.utilization);
    return (sum / warehouses.length).round();
  }

  static List<MapEntry<String, double>> last7DayBuckets() {
    final now = DateTime.now();
    return [
      for (var i = 6; i >= 0; i--)
        MapEntry(
          '${now.subtract(Duration(days: i)).month}/${now.subtract(Duration(days: i)).day}',
          0,
        ),
    ];
  }

  static List<String> last7DayLabels() =>
      last7DayBuckets().map((e) => e.key).toList();

  static int _dayIndexInLast7(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff < 0 || diff > 6) return -1;
    return 6 - diff;
  }

  static void _incrementSeries(List<double> series, DateTime? dt) {
    if (dt == null) return;
    final index = _dayIndexInLast7(dt);
    if (index < 0 || index >= series.length) return;
    series[index] = series[index] + 1;
  }

  static DashboardChartTimeSeries inventoryInboundOutboundSeries(
    StaffDashboardData data,
  ) {
    final labels = last7DayLabels();
    final inbound = List<double>.filled(7, 0);
    final outbound = List<double>.filled(7, 0);

    for (final m in data.movements) {
      final index = _dayIndexInLast7(m.timestamp ?? DateTime.now());
      if (index < 0) continue;
      switch (m.type.toUpperCase()) {
        case 'INBOUND':
          inbound[index] = inbound[index] + 1;
        case 'OUTBOUND':
          outbound[index] = outbound[index] + 1;
      }
    }

    return DashboardChartTimeSeries(
      labels: labels,
      lines: [
        DashboardChartLine(
          label: 'Inbound',
          role: DashboardSeriesRole.inbound,
          values: inbound,
        ),
        DashboardChartLine(
          label: 'Outbound',
          role: DashboardSeriesRole.outbound,
          values: outbound,
        ),
      ],
    );
  }

  static DashboardChartTimeSeries orderPipelineSeries(StaffDashboardData data) {
    final labels = last7DayLabels();
    final created = List<double>.filled(7, 0);
    final processing = List<double>.filled(7, 0);
    final completed = List<double>.filled(7, 0);

    for (final t in data.tasks) {
      if (t.taskType != WmsTaskTypes.orderPacking &&
          t.taskType != WmsTaskTypes.outboundDispatch) {
        continue;
      }

      _incrementSeries(created, t.createdAt ?? t.dueDate);

      if (t.status == WmsTaskStatuses.completed) {
        _incrementSeries(completed, t.updatedAt ?? t.createdAt ?? t.dueDate);
      } else if (t.status == WmsTaskStatuses.inProgress ||
          t.status == WmsTaskStatuses.waitingConfirmation ||
          t.status == WmsTaskStatuses.accepted) {
        _incrementSeries(processing, t.updatedAt ?? t.createdAt ?? t.dueDate);
      }
    }

    final todayIndex = 6;
    for (final insight in data.insights) {
      if (!insight.message.toLowerCase().contains('order')) continue;
      created[todayIndex] = created[todayIndex] + 1;
    }

    return DashboardChartTimeSeries(
      labels: labels,
      lines: [
        DashboardChartLine(
          label: 'Created',
          role: DashboardSeriesRole.orders,
          values: created,
        ),
        DashboardChartLine(
          label: 'Processing',
          role: DashboardSeriesRole.transfer,
          values: processing,
        ),
        DashboardChartLine(
          label: 'Completed',
          role: DashboardSeriesRole.inbound,
          values: completed,
        ),
      ],
    );
  }

  static DashboardChartTimeSeries lowStockTrendSeries(StaffDashboardData data) {
    final labels = last7DayLabels();
    final risk = List<double>.filled(7, 0);
    final todayIndex = 6;

    risk[todayIndex] = data.alerts.lowStockCount.toDouble();

    for (final insight in data.insights) {
      final lower = insight.message.toLowerCase();
      if (!lower.contains('low stock') &&
          !lower.contains('out of stock') &&
          !lower.contains('expir')) {
        continue;
      }
      risk[todayIndex] = risk[todayIndex] + 1;
    }

    for (final t in data.tasks) {
      if (t.taskType != WmsTaskTypes.stockAdjustment &&
          t.taskType != WmsTaskTypes.inventoryCount) {
        continue;
      }
      _incrementSeries(risk, t.updatedAt ?? t.createdAt ?? t.dueDate);
    }

    for (final m in data.movements) {
      if (m.type.toUpperCase() != 'ADJUSTMENT') continue;
      _incrementSeries(risk, m.timestamp);
    }

    return DashboardChartTimeSeries(
      labels: labels,
      lines: [
        DashboardChartLine(
          label: 'Low Stock Risk',
          role: DashboardSeriesRole.lowStock,
          values: risk,
        ),
      ],
    );
  }

  static List<MapEntry<String, double>> dailyMovementSeries(
    StaffDashboardData data,
  ) {
    final buckets = {for (final e in last7DayBuckets()) e.key: 0.0};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final m in data.movements) {
      final ts = m.timestamp;
      if (ts == null) continue;
      final day = DateTime(ts.year, ts.month, ts.day);
      final diff = today.difference(day).inDays;
      if (diff < 0 || diff > 6) continue;
      final key = '${day.month}/${day.day}';
      buckets[key] = (buckets[key] ?? 0) + 1;
    }
    return buckets.entries.toList();
  }

  static List<MapEntry<String, double>> dailyOrderSeries(
    StaffDashboardData data,
  ) {
    final buckets = {for (final e in last7DayBuckets()) e.key: 0.0};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final t in data.tasks) {
      if (t.taskType != WmsTaskTypes.orderPacking &&
          t.taskType != WmsTaskTypes.outboundDispatch) {
        continue;
      }
      final ts = t.updatedAt ?? t.createdAt ?? t.dueDate;
      if (ts == null) continue;
      final day = DateTime(ts.year, ts.month, ts.day);
      final diff = today.difference(day).inDays;
      if (diff < 0 || diff > 6) continue;
      final key = '${day.month}/${day.day}';
      buckets[key] = (buckets[key] ?? 0) + 1;
    }

    for (final insight in data.insights) {
      if (!insight.message.toLowerCase().contains('order')) continue;
      final key = '${today.month}/${today.day}';
      buckets[key] = (buckets[key] ?? 0) + 1;
    }

    return buckets.entries.toList();
  }

  static List<MapEntry<String, double>> warehouseUtilizationSeries(
    List<WarehouseStat> warehouses,
  ) {
    if (warehouses.isEmpty) return const [];
    return [
      for (final w in warehouses)
        MapEntry(
          w.name.length > 10 ? '${w.name.substring(0, 10)}…' : w.name,
          w.utilization.toDouble(),
        ),
    ];
  }

  static int weeklyOrderActivity(StaffDashboardData data) {
    final start = DateTime.now().subtract(const Duration(days: 7));
    var count = 0;
    for (final t in data.tasks) {
      if (t.taskType != WmsTaskTypes.orderPacking &&
          t.taskType != WmsTaskTypes.outboundDispatch) {
        continue;
      }
      final ts = t.updatedAt ?? t.createdAt;
      if (ts != null && ts.isAfter(start)) count++;
    }
    return count;
  }
}

/// Presentation-layer command-center metrics derived from staff dashboard data.
class StaffExecutiveAnalytics {
  const StaffExecutiveAnalytics({
    required this.totalUnits,
    required this.activeWarehouses,
    required this.lowStockItems,
    required this.criticalAlerts,
    required this.openTasks,
    required this.weeklyMovements,
    required this.weeklyTrend,
    required this.warehousePerformanceTrend,
    required this.inventoryTrend,
    required this.operationalTrend,
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
    required this.expired,
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.todayInbound,
    required this.todayOutbound,
    required this.todayTransfers,
    required this.todayOrders,
    required this.executiveCriticalAlerts,
    required this.executiveExpiredProducts,
    required this.executiveLowStockProducts,
    required this.avgCapacityUsed,
    required this.totalUnitsStored,
    required this.warehouses,
    required this.weeklyOrderActivity,
    required this.inventoryWeeklyTrend,
    required this.orderTrend,
    required this.lowStockTrend,
    required this.warehouseUtilizationTrend,
    required this.inventoryTrendSeries,
    required this.orderPipelineSeries,
    required this.lowStockTrendSeries,
    required this.warehouseUtilizationSeries,
  });

  final num totalUnits;
  final int activeWarehouses;
  final int lowStockItems;
  final int criticalAlerts;
  final int openTasks;
  final int weeklyMovements;
  final ExecutiveMetricTrend weeklyTrend;
  final ExecutiveMetricTrend warehousePerformanceTrend;
  final ExecutiveMetricTrend inventoryTrend;
  final ExecutiveMetricTrend operationalTrend;
  final int inStock;
  final int lowStock;
  final int outOfStock;
  final int expired;
  final int pendingTasks;
  final int inProgressTasks;
  final int completedTasks;
  final int completionRate;
  final int todayInbound;
  final int todayOutbound;
  final int todayTransfers;
  final int todayOrders;
  final int executiveCriticalAlerts;
  final int executiveExpiredProducts;
  final int executiveLowStockProducts;
  final int avgCapacityUsed;
  final int totalUnitsStored;
  final List<WarehouseStat> warehouses;
  final int weeklyOrderActivity;
  final ExecutiveMetricTrend inventoryWeeklyTrend;
  final ExecutiveMetricTrend orderTrend;
  final ExecutiveMetricTrend lowStockTrend;
  final ExecutiveMetricTrend warehouseUtilizationTrend;
  final DashboardChartTimeSeries inventoryTrendSeries;
  final DashboardChartTimeSeries orderPipelineSeries;
  final DashboardChartTimeSeries lowStockTrendSeries;
  final List<MapEntry<String, double>> warehouseUtilizationSeries;

  factory StaffExecutiveAnalytics.from(
    StaffDashboardData data,
    WmsUiColors colors,
  ) {
    final s = data.inventorySummary;
    final alerts = data.alerts;
    final tasks = StaffDashboardMetrics.taskCenter(data.tasks);
    final ops = StaffDashboardMetrics.operationsToday(data);
    final weekly = StaffDashboardMetrics.weeklyMovements(data);
    final weeklyOrders = StaffDashboardMetrics.weeklyOrderActivity(data);
    final avgCap = StaffDashboardMetrics.avgUtilization(data.warehouseStats);
    final movementSeries = StaffDashboardMetrics.inventoryInboundOutboundSeries(
      data,
    );
    final orderSeries = StaffDashboardMetrics.orderPipelineSeries(data);
    final lowStockSeries = StaffDashboardMetrics.lowStockTrendSeries(data);
    final utilizationSeries = StaffDashboardMetrics.warehouseUtilizationSeries(
      data.warehouseStats,
    );
    final totalStored = data.warehouseStats.fold<num>(
      0,
      (sum, w) => sum + w.totalUnits,
    );
    final inStock = s.inStock;
    final lowStock = s.lowStock;
    final outOfStock = s.outOfStock;
    final expired = alerts.expiredCount;
    final critical = StaffDashboardMetrics.criticalAlerts(alerts);
    final openTasks = tasks.pending + tasks.inProgress;
    final skuTotal = inStock + lowStock + outOfStock;
    final inStockPct = skuTotal > 0 ? ((inStock / skuTotal) * 100).round() : 0;
    final todayOps = ops.inbound + ops.outbound + ops.transfers + ops.orders;

    return StaffExecutiveAnalytics(
      totalUnits: s.totalUnits,
      activeWarehouses: data.warehouseStats.length,
      lowStockItems: alerts.lowStockCount,
      criticalAlerts: critical,
      openTasks: openTasks,
      weeklyMovements: weekly,
      weeklyTrend: _weeklyTrend(weekly),
      warehousePerformanceTrend: _warehouseTrend(avgCap),
      inventoryTrend: _inventoryTrend(inStockPct, lowStock, outOfStock),
      operationalTrend: _operationalTrend(todayOps, openTasks),
      inStock: inStock,
      lowStock: lowStock,
      outOfStock: outOfStock,
      expired: expired,
      pendingTasks: tasks.pending,
      inProgressTasks: tasks.inProgress,
      completedTasks: tasks.completed,
      completionRate: tasks.completionRate,
      todayInbound: ops.inbound,
      todayOutbound: ops.outbound,
      todayTransfers: ops.transfers,
      todayOrders: ops.orders,
      executiveCriticalAlerts: critical,
      executiveExpiredProducts: expired,
      executiveLowStockProducts: alerts.lowStockCount,
      avgCapacityUsed: avgCap,
      totalUnitsStored: totalStored > 0
          ? totalStored.toInt()
          : s.totalUnits.toInt(),
      warehouses: data.warehouseStats,
      weeklyOrderActivity: weeklyOrders,
      inventoryWeeklyTrend: _weeklyTrend(weekly),
      orderTrend: _orderTrend(weeklyOrders),
      lowStockTrend: _lowStockTrend(alerts.lowStockCount),
      warehouseUtilizationTrend: _warehouseTrend(avgCap),
      inventoryTrendSeries: movementSeries,
      orderPipelineSeries: orderSeries,
      lowStockTrendSeries: lowStockSeries,
      warehouseUtilizationSeries: utilizationSeries,
    );
  }

  static ExecutiveMetricTrend _orderTrend(int weeklyOrders) {
    if (weeklyOrders == 0) {
      return const ExecutiveMetricTrend(
        direction: ExecutiveTrendDirection.stable,
        label: 'No orders',
      );
    }
    return ExecutiveMetricTrend(
      direction: ExecutiveTrendDirection.up,
      label: '$weeklyOrders this week',
    );
  }

  static ExecutiveMetricTrend _lowStockTrend(int lowStock) {
    if (lowStock == 0) {
      return const ExecutiveMetricTrend(
        direction: ExecutiveTrendDirection.up,
        label: 'Stock healthy',
      );
    }
    if (lowStock >= 5) {
      return ExecutiveMetricTrend(
        direction: ExecutiveTrendDirection.down,
        label: '$lowStock SKUs at risk',
      );
    }
    return ExecutiveMetricTrend(
      direction: ExecutiveTrendDirection.stable,
      label: '$lowStock SKUs flagged',
    );
  }

  static ExecutiveMetricTrend _weeklyTrend(int weekly) {
    if (weekly == 0) {
      return const ExecutiveMetricTrend(
        direction: ExecutiveTrendDirection.stable,
        label: 'No activity',
      );
    }
    return ExecutiveMetricTrend(
      direction: ExecutiveTrendDirection.up,
      label: '$weekly this week',
    );
  }

  static ExecutiveMetricTrend _warehouseTrend(int avgCap) {
    if (avgCap >= 85) {
      return ExecutiveMetricTrend(
        direction: ExecutiveTrendDirection.up,
        label: '$avgCap% avg load',
      );
    }
    if (avgCap >= 50) {
      return ExecutiveMetricTrend(
        direction: ExecutiveTrendDirection.stable,
        label: '$avgCap% utilized',
      );
    }
    return ExecutiveMetricTrend(
      direction: ExecutiveTrendDirection.stable,
      label: '$avgCap% capacity',
    );
  }

  static ExecutiveMetricTrend _inventoryTrend(
    int inStockPct,
    int lowStock,
    int outOfStock,
  ) {
    if (outOfStock > 0) {
      return ExecutiveMetricTrend(
        direction: ExecutiveTrendDirection.down,
        label: '$outOfStock out',
      );
    }
    if (lowStock > 0) {
      return ExecutiveMetricTrend(
        direction: ExecutiveTrendDirection.stable,
        label: '$inStockPct% in stock',
      );
    }
    return ExecutiveMetricTrend(
      direction: ExecutiveTrendDirection.up,
      label: '$inStockPct% healthy',
    );
  }

  static ExecutiveMetricTrend _operationalTrend(int todayOps, int openTasks) {
    if (todayOps == 0 && openTasks == 0) {
      return const ExecutiveMetricTrend(
        direction: ExecutiveTrendDirection.stable,
        label: 'Quiet',
      );
    }
    return ExecutiveMetricTrend(
      direction: ExecutiveTrendDirection.up,
      label: '$todayOps ops · $openTasks tasks',
    );
  }
}

/// Horizontal executive insight tiles — weekly, warehouse, inventory, ops.
class DashboardExecutiveInsights extends StatelessWidget {
  const DashboardExecutiveInsights({super.key, required this.analytics});

  final StaffExecutiveAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final columns = MobileUi.kpiColumns(width);

    final tiles = [
      _DashboardInsightTile(
        label: 'Weekly Inventory',
        value: '${analytics.weeklyMovements}',
        icon: Icons.trending_up_rounded,
        color: colors.primary,
        trend: analytics.inventoryWeeklyTrend,
      ),
      _DashboardInsightTile(
        label: 'Order Trend',
        value: '${analytics.weeklyOrderActivity}',
        icon: Icons.shopping_cart_outlined,
        color: colors.accent,
        trend: analytics.orderTrend,
      ),
      _DashboardInsightTile(
        label: 'Low Stock Trend',
        value: '${analytics.lowStockItems}',
        icon: Icons.warning_amber_rounded,
        color: colors.warning,
        trend: analytics.lowStockTrend,
      ),
      _DashboardInsightTile(
        label: 'Warehouse Util.',
        value: '${analytics.avgCapacityUsed}%',
        icon: Icons.warehouse_outlined,
        color: colors.info,
        trend: analytics.warehouseUtilizationTrend,
      ),
    ];

    return WmsDashboardSection(
      title: 'Executive Insights',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth =
              (constraints.maxWidth - DashboardUi.tileGap * (columns - 1)) /
              columns;
          return Wrap(
            spacing: DashboardUi.tileGap,
            runSpacing: DashboardUi.tileGap,
            children: [
              for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardInsightTile extends StatelessWidget {
  const _DashboardInsightTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ExecutiveMetricTrend trend;

  @override
  Widget build(BuildContext context) {
    final trendIcon = switch (trend.direction) {
      ExecutiveTrendDirection.up => Icons.arrow_upward_rounded,
      ExecutiveTrendDirection.down => Icons.arrow_downward_rounded,
      ExecutiveTrendDirection.stable => Icons.remove_rounded,
    };
    final colors = WmsUiColors.of(context);
    final trendColor = switch (trend.direction) {
      ExecutiveTrendDirection.up => colors.success,
      ExecutiveTrendDirection.down => colors.error,
      ExecutiveTrendDirection.stable => Theme.of(
        context,
      ).colorScheme.onSurfaceVariant,
    };

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: WmsIconSizes.kpi, color: color),
              const Spacer(),
              Icon(trendIcon, size: WmsIconSizes.status - 6, color: trendColor),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.metricValue(context),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.kpiLabel(context),
          ),
          Text(
            trend.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.supportingDense(
              context,
            ).copyWith(color: trendColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Inventory breakdown with expired SKU lines.
class DashboardInventoryAnalytics extends StatelessWidget {
  const DashboardInventoryAnalytics({
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
      title: 'Inventory Analytics',
      child: AppCard(
        elevated: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _AnalyticsStatusRow(
              label: 'In Stock',
              count: inStock,
              color: colors.success,
              icon: Icons.check_circle_outline,
              fraction: inStock / total,
            ),
            const SizedBox(height: AppSpacing.sm),
            _AnalyticsStatusRow(
              label: 'Low Stock',
              count: lowStock,
              color: colors.warning,
              icon: Icons.warning_amber_rounded,
              fraction: lowStock / total,
            ),
            const SizedBox(height: AppSpacing.sm),
            _AnalyticsStatusRow(
              label: 'Out of Stock',
              count: outOfStock,
              color: colors.error,
              icon: Icons.remove_shopping_cart_outlined,
              fraction: outOfStock / total,
            ),
            const SizedBox(height: AppSpacing.sm),
            _AnalyticsStatusRow(
              label: 'Expired',
              count: expired,
              color: const Color(0xFF7C3AED),
              icon: Icons.event_busy_outlined,
              fraction: expired / total,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsStatusRow extends StatelessWidget {
  const _AnalyticsStatusRow({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.fraction,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Row(
      children: [
        Icon(icon, size: WmsIconSizes.status, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: count > 0 ? fraction.clamp(0.05, 1.0) : 0,
                  minHeight: 4,
                  backgroundColor: colors.surfaceElevated,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact task pipeline metrics.
class DashboardTaskAnalytics extends StatelessWidget {
  const DashboardTaskAnalytics({
    super.key,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.completionRate,
  });

  final int pending;
  final int inProgress;
  final int completed;
  final int completionRate;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return WmsDashboardSection(
      title: 'Task Analytics',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = (constraints.maxWidth - DashboardUi.tileGap) / 2;
          return Wrap(
            spacing: DashboardUi.tileGap,
            runSpacing: DashboardUi.tileGap,
            children: [
              SizedBox(
                width: tileWidth,
                child: _TaskMetricTile(
                  label: 'Pending',
                  count: pending,
                  color: colors.warning,
                  icon: Icons.schedule_outlined,
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _TaskMetricTile(
                  label: 'In Progress',
                  count: inProgress,
                  color: colors.info,
                  icon: Icons.play_circle_outline,
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _TaskMetricTile(
                  label: 'Completed',
                  count: completed,
                  color: colors.success,
                  icon: Icons.check_circle_outline,
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _TaskMetricTile(
                  label: 'Completion Rate',
                  count: completionRate,
                  suffix: '%',
                  color: colors.primary,
                  icon: Icons.donut_large_outlined,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Today's operational totals strip.
class DashboardActivitySummary extends StatelessWidget {
  const DashboardActivitySummary({
    super.key,
    required this.transfers,
    required this.inbound,
    required this.outbound,
    required this.orders,
  });

  final int transfers;
  final int inbound;
  final int outbound;
  final int orders;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return WmsDashboardSection(
      title: 'Activity Summary',
      subtitle: "Today's operational totals",
      child: AppCard(
        elevated: true,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: _ActivitySummaryTile(
                label: 'Transfers',
                value: '$transfers',
                icon: Icons.swap_horiz_rounded,
                color: colors.info,
              ),
            ),
            Expanded(
              child: _ActivitySummaryTile(
                label: 'Inbound',
                value: '$inbound',
                icon: Icons.download_rounded,
                color: colors.success,
              ),
            ),
            Expanded(
              child: _ActivitySummaryTile(
                label: 'Outbound',
                value: '$outbound',
                icon: Icons.upload_rounded,
                color: colors.outbound,
              ),
            ),
            Expanded(
              child: _ActivitySummaryTile(
                label: 'Orders',
                value: '$orders',
                icon: Icons.shopping_cart_outlined,
                color: colors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitySummaryTile extends StatelessWidget {
  const _ActivitySummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: WmsIconSizes.kpi, color: color),
        const SizedBox(height: 4),
        Text(value, style: WmsDesignTokens.metricValue(context)),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: WmsDesignTokens.kpiLabel(context),
        ),
      ],
    );
  }
}

/// Executive alert rollup — critical, expired, low stock.
class DashboardAlertsSummary extends StatelessWidget {
  const DashboardAlertsSummary({
    super.key,
    required this.criticalAlerts,
    required this.expiredProducts,
    required this.lowStockItems,
    this.onTap,
  });

  final int criticalAlerts;
  final int expiredProducts;
  final int lowStockItems;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final total = criticalAlerts + expiredProducts + lowStockItems;

    return WmsDashboardSection(
      title: 'Alerts Summary',
      count: total > 0 ? total : null,
      child: AppCard(
        elevated: true,
        onTap: onTap,
        accentColor: total > 0 ? colors.error : null,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: _AlertSummaryTile(
                label: 'Critical',
                count: criticalAlerts,
                icon: Icons.priority_high_rounded,
                color: colors.error,
              ),
            ),
            Container(
              width: 1,
              height: 44,
              color: colors.border.withValues(alpha: 0.5),
            ),
            Expanded(
              child: _AlertSummaryTile(
                label: 'Expired',
                count: expiredProducts,
                icon: Icons.event_busy_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ),
            Container(
              width: 1,
              height: 44,
              color: colors.border.withValues(alpha: 0.5),
            ),
            Expanded(
              child: _AlertSummaryTile(
                label: 'Low Stock',
                count: lowStockItems,
                icon: Icons.trending_down_rounded,
                color: colors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertSummaryTile extends StatelessWidget {
  const _AlertSummaryTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: WmsIconSizes.kpi, color: color),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: WmsDesignTokens.metricValue(context).copyWith(color: color),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: WmsDesignTokens.kpiLabel(context),
        ),
      ],
    );
  }
}

/// Warehouse performance with utilization and status.
class DashboardWarehousePerformance extends StatelessWidget {
  const DashboardWarehousePerformance({
    super.key,
    required this.warehouses,
    required this.avgCapacityUsed,
    required this.totalUnitsStored,
  });

  final List<WarehouseStat> warehouses;
  final int avgCapacityUsed;
  final int totalUnitsStored;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    if (warehouses.isEmpty) return const SizedBox.shrink();

    return WmsDashboardSection(
      title: 'Warehouse Performance Overview',
      count: warehouses.length,
      child: AppCard(
        elevated: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _WhPerformanceMetric(
                    label: 'Units',
                    value: WmsFormatters.quantity(totalUnitsStored),
                    icon: Icons.inventory_2_outlined,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _WhPerformanceMetric(
                    label: 'Capacity',
                    value: '$avgCapacityUsed%',
                    icon: Icons.pie_chart_outline_rounded,
                    color: colors.info,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _WhPerformanceMetric(
                    label: 'Sites',
                    value: '${warehouses.length}',
                    icon: Icons.warehouse_outlined,
                    color: colors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final wh in warehouses.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _WarehousePerformanceRow(warehouse: wh),
              ),
          ],
        ),
      ),
    );
  }
}

class _WhPerformanceMetric extends StatelessWidget {
  const _WhPerformanceMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Icon(icon, size: WmsIconSizes.status, color: color),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.metricValue(context).copyWith(fontSize: 18),
          ),
          Text(label, style: WmsDesignTokens.supportingDense(context)),
        ],
      ),
    );
  }
}

class _WarehousePerformanceRow extends StatelessWidget {
  const _WarehousePerformanceRow({required this.warehouse});

  final WarehouseStat warehouse;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final util = warehouse.utilization;
    final status = util >= 85
        ? 'High Load'
        : util >= 60
        ? 'Operational'
        : 'Available';
    final statusColor = util >= 85
        ? colors.error
        : util >= 60
        ? colors.warning
        : colors.success;
    final barColor = util >= 85
        ? colors.error
        : util >= 60
        ? colors.warning
        : colors.success;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            warehouse.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (util / 100).clamp(0.0, 1.0),
              minHeight: 4,
              color: barColor,
              backgroundColor: colors.surfaceElevated,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          width: 52,
          child: Text(
            status,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.supportingDense(
              context,
            ).copyWith(color: statusColor, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Builds a mixed activity feed from movements, tasks, and insights.
List<WmsTimelineEntry> buildStaffActivityFeed(StaffDashboardData data) {
  final items = <({DateTime? time, WmsTimelineEntry entry})>[];

  for (final m in data.movements) {
    final location = m.fromLocation?.isNotEmpty == true
        ? m.fromLocation!
        : (m.toLocation ?? '');
    items.add((
      time: m.timestamp,
      entry: WmsTimelineMapper.fromMovement(
        type: m.type,
        productName: m.productName,
        quantityLabel: location.isNotEmpty
            ? '${WmsFormatters.quantity(m.quantity)} units · $location'
            : '${WmsFormatters.quantity(m.quantity)} units',
        relativeTime: WmsFormatters.relativeTime(m.timestamp),
      ),
    ));
  }

  for (final t in data.tasks) {
    final time = t.updatedAt ?? t.createdAt ?? t.dueDate;
    items.add((time: time, entry: _taskActivityEntry(t, time)));
  }

  for (final insight in data.insights) {
    items.add((time: DateTime.now(), entry: _insightActivityEntry(insight)));
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

WmsTimelineEntry _insightActivityEntry(DashboardInsight insight) {
  final lower = insight.message.toLowerCase();
  final severity = insight.severity.toLowerCase();

  if (lower.contains('order')) {
    return WmsTimelineEntry(
      title: lower.contains('deliver') ? 'Order Delivered' : 'Order Created',
      description: insight.message,
      relativeTime: 'Recent',
      icon: lower.contains('deliver')
          ? Icons.local_shipping_outlined
          : Icons.shopping_bag_outlined,
      tone: lower.contains('deliver')
          ? WmsTimelineTone.success
          : WmsTimelineTone.accent,
    );
  }
  if (lower.contains('expir')) {
    return WmsTimelineEntry(
      title: 'Expiry Alert',
      description: insight.message,
      relativeTime: 'Recent',
      icon: Icons.event_busy_outlined,
      tone: WmsTimelineTone.expired,
    );
  }
  if (lower.contains('low stock') || lower.contains('out of stock')) {
    return WmsTimelineEntry(
      title: 'Low Stock Alert',
      description: insight.message,
      relativeTime: 'Recent',
      icon: Icons.trending_down_rounded,
      tone: WmsTimelineTone.warning,
    );
  }
  if (lower.contains('warehouse')) {
    return WmsTimelineEntry(
      title: 'Warehouse Update',
      description: insight.message,
      relativeTime: 'Recent',
      icon: Icons.warehouse_outlined,
      tone: WmsTimelineTone.info,
    );
  }
  if (lower.contains('task')) {
    return WmsTimelineEntry(
      title: 'Task Update',
      description: insight.message,
      relativeTime: 'Recent',
      icon: Icons.assignment_outlined,
      tone: WmsTimelineTone.primary,
    );
  }
  if (lower.contains('transfer')) {
    return WmsTimelineEntry(
      title: 'Stock Transfer',
      description: insight.message,
      relativeTime: 'Recent',
      icon: Icons.swap_horiz_rounded,
      tone: WmsTimelineTone.info,
    );
  }
  if (severity.contains('critical') || severity.contains('high')) {
    return WmsTimelineEntry(
      title: 'Critical Alert',
      description: insight.message,
      relativeTime: 'Recent',
      icon: Icons.priority_high_rounded,
      tone: WmsTimelineTone.error,
    );
  }
  return WmsTimelineEntry(
    title: 'Inventory Notice',
    description: insight.message,
    relativeTime: 'Recent',
    icon: Icons.inventory_2_outlined,
    tone: WmsTimelineTone.primary,
  );
}

WmsTimelineEntry _taskActivityEntry(WarehouseTask task, DateTime? time) {
  final status = WmsTaskStatuses.displayLabel(task.status);
  final warehouse = task.warehouseName?.trim();
  final context = warehouse?.isNotEmpty == true ? ' · $warehouse' : '';
  final product = task.productName?.trim();
  final detail = product?.isNotEmpty == true
      ? '$product · $status$context'
      : '${task.title} · $status$context';

  final completed = task.status == WmsTaskStatuses.completed;
  final rejected = task.status == WmsTaskStatuses.rejected;

  switch (task.taskType) {
    case WmsTaskTypes.orderPacking:
      return WmsTimelineEntry(
        title: completed ? 'Order Packed' : 'Order Packing',
        description: detail,
        relativeTime: WmsFormatters.relativeTime(time),
        icon: Icons.inventory_2_outlined,
        tone: WmsTimelineTone.info,
      );
    case WmsTaskTypes.outboundDispatch:
      return WmsTimelineEntry(
        title: completed ? 'Outbound Dispatched' : 'Outbound Dispatch',
        description: detail,
        relativeTime: WmsFormatters.relativeTime(time),
        icon: Icons.local_shipping_outlined,
        tone: WmsTimelineTone.outbound,
      );
    case WmsTaskTypes.inventoryReceive:
      return WmsTimelineEntry(
        title: completed ? 'Inbound Received' : 'Inbound Receive',
        description: detail,
        relativeTime: WmsFormatters.relativeTime(time),
        icon: Icons.download_rounded,
        tone: WmsTimelineTone.success,
      );
    case WmsTaskTypes.stockTransfer:
      return WmsTimelineEntry(
        title: completed ? 'Stock Transferred' : 'Stock Transfer',
        description: detail,
        relativeTime: WmsFormatters.relativeTime(time),
        icon: Icons.swap_horiz_rounded,
        tone: WmsTimelineTone.info,
      );
    case WmsTaskTypes.inventoryCount:
      return WmsTimelineEntry(
        title: completed ? 'Cycle Count Done' : 'Cycle Count',
        description: detail,
        relativeTime: WmsFormatters.relativeTime(time),
        icon: Icons.fact_check_outlined,
        tone: WmsTimelineTone.primary,
      );
    case WmsTaskTypes.stockAdjustment:
      return WmsTimelineEntry(
        title: completed ? 'Stock Adjusted' : 'Stock Adjustment',
        description: detail,
        relativeTime: WmsFormatters.relativeTime(time),
        icon: Icons.tune_rounded,
        tone: WmsTimelineTone.accent,
      );
    case WmsTaskTypes.inspection:
      return WmsTimelineEntry(
        title: completed ? 'Inspection Complete' : 'Quality Inspection',
        description: detail,
        relativeTime: WmsFormatters.relativeTime(time),
        icon: Icons.verified_outlined,
        tone: WmsTimelineTone.success,
      );
    default:
      final verb = rejected
          ? 'Task Rejected'
          : completed
          ? 'Task Completed'
          : 'Task Updated';
      return WmsTimelineEntry(
        title: verb,
        description: detail,
        relativeTime: WmsFormatters.relativeTime(time),
        icon: completed ? Icons.task_alt_rounded : Icons.assignment_outlined,
        tone: completed ? WmsTimelineTone.success : WmsTimelineTone.accent,
      );
  }
}

/// Derives admin dashboard metrics from management data + widgets fields.
abstract final class AdminDashboardMetrics {
  static ({int inbound, int outbound, int transfers, int orders})
  operationsToday({required int todayMovements, required int pendingOrders}) {
    if (todayMovements <= 0) {
      return (inbound: 0, outbound: 0, transfers: 0, orders: pendingOrders);
    }
    final inbound = (todayMovements * 0.45).round();
    final outbound = (todayMovements * 0.35).round();
    final transfers = todayMovements - inbound - outbound;
    return (
      inbound: inbound,
      outbound: outbound,
      transfers: transfers,
      orders: pendingOrders,
    );
  }

  static int completionRate({
    required int pending,
    required int inProgress,
    required int completed,
  }) {
    final total = pending + inProgress + completed;
    return total > 0 ? ((completed / total) * 100).round() : 0;
  }
}

/// Maps supervisor data through existing analytics derivation.
DashboardOperationsToday supervisorOperationsToday(
  SupervisorDashboardData data,
) {
  final a = SupervisorExecutiveAnalytics.from(data);
  return DashboardOperationsToday(
    inbound: a.todayInbound,
    outbound: a.todayOutbound,
    transfers: a.todayTransfers,
    orders: a.todayOrders,
  );
}

DashboardExecutiveSummary supervisorExecutiveSummary(
  SupervisorDashboardData data, {
  VoidCallback? onInventoryTap,
  VoidCallback? onWarehousesTap,
  VoidCallback? onLowStockTap,
  VoidCallback? onAlertsTap,
}) {
  final a = SupervisorExecutiveAnalytics.from(data);
  return DashboardExecutiveSummary(
    totalInventory: WmsFormatters.quantity(a.totalUnits),
    activeWarehouses: a.activeWarehouses,
    lowStock: a.lowStockItems,
    criticalAlerts: DashboardUi.totalCriticalCount(
      outOfStock: a.outOfStock,
      expired: a.expired,
      expiringSoon: data.inventoryAlerts.expiringCount,
      criticalItems: a.executiveCriticalAlerts,
    ),
    onInventoryTap: onInventoryTap,
    onWarehousesTap: onWarehousesTap,
    onLowStockTap: onLowStockTap,
    onAlertsTap: onAlertsTap,
  );
}

DashboardInventoryHealth supervisorInventoryHealth(
  SupervisorDashboardData data, {
  VoidCallback? onDetailsTap,
}) {
  final a = SupervisorExecutiveAnalytics.from(data);
  return DashboardInventoryHealth(
    inStock: a.inStock,
    lowStock: a.lowStock,
    outOfStock: a.outOfStock,
    totalUnitsLabel:
        '${WmsFormatters.quantity(a.totalUnits)} units across ${a.activeWarehouses} warehouses',
    onDetailsTap: onDetailsTap,
  );
}

DashboardTaskCenter supervisorTaskCenter(
  SupervisorDashboardData data, {
  VoidCallback? onViewAll,
}) {
  final tasks = data.taskMonitoring;
  final rate = tasks.total > 0
      ? ((tasks.completed / tasks.total) * 100).round()
      : 0;
  return DashboardTaskCenter(
    pending: tasks.pending,
    inProgress: tasks.inProgress + tasks.waitingConfirmation,
    completed: tasks.completed,
    completionRate: rate,
    onViewAll: onViewAll,
  );
}
