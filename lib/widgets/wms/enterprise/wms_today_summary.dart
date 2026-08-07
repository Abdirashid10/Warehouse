import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/widgets/app_card.dart';

/// Today's task summary — pending, in progress, completed.
class WmsTodaySummary extends StatelessWidget {
  const WmsTodaySummary({
    super.key,
    required this.pending,
    required this.inProgress,
    required this.completed,
    this.title = "Today's Summary",
    this.showSubtitle = true,
    this.overdue,
    this.premium = false,
  });

  final int pending;
  final int inProgress;
  final int completed;
  final String title;
  final bool showSubtitle;
  final int? overdue;
  final bool premium;

  static WmsTodaySummary fromTasks(
    List<WarehouseTask> tasks, {
    String title = "Today's Summary",
  }) {
    var pending = 0;
    var inProgress = 0;
    var completed = 0;
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
    return WmsTodaySummary(
      pending: pending,
      inProgress: inProgress,
      completed: completed,
      title: title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final wms = context.wms;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
            ),
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Task status overview for today',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: wms.textSecondary,
                ),
          ),
        ],
        if (overdue != null && overdue! > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: colors.errorMuted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: WmsIconSizes.status, color: colors.error),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    '$overdue overdue task${overdue == 1 ? '' : 's'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: showSubtitle ? AppSpacing.md : AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth =
                (constraints.maxWidth - AppSpacing.sm * 2) / 3;
            final useShortLabels = tileWidth < 112;

            return Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: useShortLabels ? 'Pending' : 'Pending Tasks',
                    count: pending,
                    icon: Icons.schedule_outlined,
                    color: colors.warning,
                    background: colors.warningMuted,
                    premium: premium,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SummaryTile(
                    label: useShortLabels ? 'Active' : 'In Progress',
                    count: inProgress,
                    icon: Icons.play_circle_outline,
                    color: premium ? colors.info : primary,
                    background:
                        premium ? colors.infoMuted : colors.primaryMuted,
                    premium: premium,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SummaryTile(
                    label: useShortLabels ? 'Done' : 'Completed',
                    count: completed,
                    icon: Icons.check_circle_outline,
                    color: colors.success,
                    background: colors.successMuted,
                    premium: premium,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.background,
    this.premium = false,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color background;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 108;
        final verticalPadding = isNarrow ? AppSpacing.sm : AppSpacing.md;
        final horizontalPadding = isNarrow ? AppSpacing.xs : AppSpacing.sm;

        return AppCard(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          elevated: premium,
          child: DecoratedBox(
            decoration: premium
                ? BoxDecoration(
                    border: Border(
                      top: BorderSide(color: color, width: 3),
                    ),
                  )
                : const BoxDecoration(),
            child: Padding(
              padding: premium
                  ? const EdgeInsets.only(top: AppSpacing.xs)
                  : EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(WmsIconSizes.iconCardPadding),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: premium
                          ? Border.all(color: color.withValues(alpha: 0.2))
                          : null,
                    ),
                    child: Icon(icon, size: WmsIconSizes.kpi, color: color),
                  ),
                  SizedBox(height: isNarrow ? AppSpacing.xs : AppSpacing.sm),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$count',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: color,
                            height: 1,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: isNarrow ? 10 : 11,
                            fontWeight:
                                premium ? FontWeight.w600 : FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.1,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
