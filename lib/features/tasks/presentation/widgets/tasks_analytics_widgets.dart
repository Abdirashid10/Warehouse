import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_chart_theme.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/task_workflow_utils.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_dashboard_section.dart';
import 'package:logisticsmobile/widgets/wms/wms_badges.dart';

class TasksAnalyticsSection extends StatelessWidget {
  const TasksAnalyticsSection({super.key, required this.tasks});

  final List<WarehouseTask> tasks;

  @override
  Widget build(BuildContext context) {
    return WmsDashboardSection(
      title: 'Task Analytics',
      child: AppCard(
        elevated: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Task Status Distribution',
              style: WmsDesignTokens.cardTitle(context).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TaskStatusDistributionChart(tasks: tasks),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Priority Distribution',
              style: WmsDesignTokens.cardTitle(context).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TaskPriorityDistributionChart(tasks: tasks),
          ],
        ),
      ),
    );
  }
}

class TaskStatusDistributionChart extends StatelessWidget {
  const TaskStatusDistributionChart({super.key, required this.tasks});

  final List<WarehouseTask> tasks;

  static const chartHeight = 160.0;

  @override
  Widget build(BuildContext context) {
    final chart = WmsChartTheme.of(context);
    final summary = TaskWorkflowUtils.summarize(tasks);

    final series = [
      ('Awaiting', summary.awaiting, WmsTaskStatuses.pending),
      ('Accepted', summary.accepted, WmsTaskStatuses.accepted),
      ('In Progress', summary.inProgress, WmsTaskStatuses.inProgress),
      ('Completed', summary.completed, WmsTaskStatuses.completed),
      ('Rejected', summary.rejected, WmsTaskStatuses.rejected),
      ('Overdue', summary.overdue, WmsTaskStatuses.overdue),
    ].where((e) => e.$2 > 0).toList();

    if (series.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text('No status data available', style: chart.emptyMessageStyle),
        ),
      );
    }

    final maxY = series.fold<double>(0, (m, e) => math.max(m, e.$2.toDouble()));

    return SizedBox(
      height: chartHeight,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 4 : maxY * 1.15,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: chart.colors.chartGrid,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: chart.axisLabelStyle,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= series.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      series[i].$1,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: chart.axisLabelStyle,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < series.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: series[i].$2.toDouble(),
                    width: series.length > 5 ? 12 : 16,
                    borderRadius: BorderRadius.circular(4),
                    color: WmsTaskStatusBadge.foregroundFor(series[i].$3),
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class TaskPriorityDistributionChart extends StatelessWidget {
  const TaskPriorityDistributionChart({super.key, required this.tasks});

  final List<WarehouseTask> tasks;

  static const chartHeight = 140.0;

  @override
  Widget build(BuildContext context) {
    final chart = WmsChartTheme.of(context);
    final counts = <String, int>{};
    for (final p in WmsTaskPriorities.all) {
      counts[p] = 0;
    }
    for (final task in tasks) {
      counts[task.priority] = (counts[task.priority] ?? 0) + 1;
    }

    final series = WmsTaskPriorities.all
        .where((p) => (counts[p] ?? 0) > 0)
        .map((p) => (WmsTaskPriorityBadge.labelFor(p), counts[p]!, p))
        .toList();

    if (series.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'No priority data available',
            style: chart.emptyMessageStyle,
          ),
        ),
      );
    }

    final maxY = series.fold<double>(0, (m, e) => math.max(m, e.$2.toDouble()));

    return SizedBox(
      height: chartHeight,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 4 : maxY * 1.15,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: chart.colors.chartGrid,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: chart.axisLabelStyle,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= series.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      series[i].$1,
                      style: chart.axisLabelStyle,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < series.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: series[i].$2.toDouble(),
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                    color: WmsTaskPriorityBadge.foregroundFor(series[i].$3),
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class TasksPerformanceSection extends StatelessWidget {
  const TasksPerformanceSection({super.key, required this.metrics});

  final TaskPerformanceMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Task Performance',
          style: WmsDesignTokens.sectionTitle(context).copyWith(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          elevated: true,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _MetricRow(
                icon: Icons.check_circle_outline,
                label: 'Completion Rate',
                value: '${metrics.completionRate}%',
              ),
              const Divider(height: AppSpacing.lg),
              _MetricRow(
                icon: Icons.timer_outlined,
                label: 'Average Completion Time',
                value: metrics.averageCompletionHours <= 0
                    ? '—'
                    : '${metrics.averageCompletionHours.toStringAsFixed(1)} hrs',
              ),
              const Divider(height: AppSpacing.lg),
              _MetricRow(
                icon: Icons.event_busy_outlined,
                label: 'Overdue Percentage',
                value: '${metrics.overduePercentage}%',
              ),
              const Divider(height: AppSpacing.lg),
              _MetricRow(
                icon: Icons.warehouse_outlined,
                label: 'Most Active Warehouse',
                value: metrics.mostActiveWarehouse ?? '—',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Row(
      children: [
        Icon(icon, size: WmsIconSizes.kpi, color: colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: WmsDesignTokens.supporting(context).copyWith(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: WmsDesignTokens.body(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class TasksActivitySection extends StatelessWidget {
  const TasksActivitySection({super.key, required this.activity});

  final List<TaskActivityItem> activity;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Recent Workflow Activity',
          style: WmsDesignTokens.sectionTitle(context).copyWith(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          elevated: true,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: activity.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    'No recent workflow activity',
                    style: WmsDesignTokens.supporting(context).copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < activity.length; i++) ...[
                      if (i > 0) const Divider(height: AppSpacing.lg),
                      _ActivityRow(item: activity[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final TaskActivityItem item;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final icon = switch (item.type) {
      TaskActivityType.created => Icons.add_task,
      TaskActivityType.assigned => Icons.person_add_outlined,
      TaskActivityType.started => Icons.play_circle_outline,
      TaskActivityType.completed => Icons.check_circle_outline,
      TaskActivityType.approved => Icons.verified_outlined,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: WmsIconSizes.kpi, color: colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: WmsDesignTokens.body(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.taskTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WmsDesignTokens.supporting(context).copyWith(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
              if (item.actorName != null) ...[
                const SizedBox(height: 2),
                Text(
                  item.actorName!,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: colors.textTertiary,
                        fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          _formatTime(item.timestamp),
          style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: colors.textTertiary,
                        fontSize: 12,
          ),
        ),
      ],
    );
  }

  static String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
