import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/constants/wms/order_constants.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_theme_colors.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_badges.dart';

/// Visual order fulfillment timeline (web order status flow).
class WmsOrderStatusTimeline extends StatelessWidget {
  const WmsOrderStatusTimeline({super.key, required this.currentStatus});

  final String currentStatus;

  static const _steps = [
    WmsOrderStatuses.pending,
    WmsOrderStatuses.processing,
    WmsOrderStatuses.packed,
    WmsOrderStatuses.shipped,
    WmsOrderStatuses.delivered,
  ];

  int get _currentIndex {
    final i = _steps.indexOf(currentStatus);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status tracking', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < _steps.length; i++) ...[
            _TimelineStep(
              status: _steps[i],
              isComplete: i < _currentIndex,
              isCurrent: i == _currentIndex,
              isLast: i == _steps.length - 1,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          WmsOrderStatusBadge(status: currentStatus),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.isComplete,
    required this.isCurrent,
    required this.isLast,
  });

  final String status;
  final bool isComplete;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = isComplete || isCurrent ? AppColors.primary : AppColors.border;
    final icon = isComplete
        ? Icons.check_circle
        : isCurrent
            ? Icons.radio_button_checked
            : Icons.radio_button_off;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, size: WmsIconSizes.status, color: color),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isComplete ? AppColors.primary : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Text(
                status,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                      color: isCurrent || isComplete
                          ? Theme.of(context).colorScheme.onSurface
                          : (Theme.of(context).brightness == Brightness.light
                              ? AppThemeColors.lightTextSecondary
                              : Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
