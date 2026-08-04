import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';

enum StatusType { success, warning, error, info, neutral, pending }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusType.neutral,
  });

  final String label;
  final StatusType type;

  (Color background, Color foreground) _colors(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (type) {
      case StatusType.success:
        return (AppColors.successLight, AppColors.success);
      case StatusType.warning:
        return (AppColors.warningLight, AppColors.warning);
      case StatusType.error:
        return (AppColors.errorLight, AppColors.error);
      case StatusType.info:
        return (AppColors.infoLight, AppColors.info);
      case StatusType.pending:
        return (AppColors.accentLight, AppColors.accent);
      case StatusType.neutral:
        return (AppColors.surfaceVariant, scheme.onSurfaceVariant);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
