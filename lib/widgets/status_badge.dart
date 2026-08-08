import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';

enum StatusType { success, warning, error, info, neutral, pending }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusType.neutral,
  });

  final String label;
  final StatusType type;

  /// Resolves the badge's fill and ink from the active theme.
  ///
  /// The `*Light` tints in the static palette are light-mode fills (`#DCFCE7`
  /// and friends); painting them in dark mode produced a near-white chip that
  /// then carried mid-tone text. Reading the tint from [WmsUiColors] gives a
  /// dark-mode-appropriate fill for the same semantic role.
  (Color background, Color foreground) _colors(BuildContext context) {
    final colors = WmsUiColors.of(context);
    switch (type) {
      case StatusType.success:
        return (colors.successMuted, colors.success);
      case StatusType.warning:
        return (colors.warningMuted, colors.warning);
      case StatusType.error:
        return (colors.errorMuted, colors.error);
      case StatusType.info:
        return (colors.infoMuted, colors.info);
      case StatusType.pending:
        return (colors.accentMuted, colors.accent);
      case StatusType.neutral:
        return (colors.mutedSurface, colors.textSecondary);
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
