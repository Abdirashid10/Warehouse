import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/widgets/loading_indicator.dart';

enum AppButtonVariant { primary, secondary, outline, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );

    final child = isLoading
        ? LoadingIndicator(size: 21, color: colors.onPrimary)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: WmsIconSizes.actionButton),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: textStyle),
            ],
          );

    final minimumSize = fullWidth
        ? const Size(double.infinity, 50)
        : const Size(0, 50);

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: minimumSize,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: child,
        );
      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: minimumSize,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            backgroundColor: colors.accent,
            foregroundColor: colors.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: child,
        );
      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: minimumSize,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            side: BorderSide(color: colors.border, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: isLoading
              ? LoadingIndicator(size: 21, color: colors.primary)
              : child,
        );
      case AppButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: minimumSize,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: child,
        );
    }
  }
}
