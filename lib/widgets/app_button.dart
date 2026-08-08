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

    // The app's TextTheme is built with `.apply(bodyColor: onSurface)`, which
    // stamps a dark slate color onto labelLarge. Handing that style straight to
    // Text() overrides the button's own foregroundColor — so a filled button
    // rendered dark-on-blue no matter what foregroundColor said. Filled
    // variants therefore state their label color explicitly.
    Widget buildChild(Color foreground) {
      if (isLoading) {
        return LoadingIndicator(size: 21, color: foreground);
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: WmsIconSizes.actionButton, color: foreground),
            const SizedBox(width: AppSpacing.sm),
          ],
          // Flexible so a long label ellipsizes inside a narrow button instead
          // of overflowing the row.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textStyle?.copyWith(color: foreground),
            ),
          ),
        ],
      );
    }

    /// Label color for filled buttons — pure white for maximum contrast
    /// against the primary blue and the accent fill.
    const onFilled = Color(0xFFFFFFFF);

    // A disabled filled button paints a pale grey fill, so the label must fall
    // back to the Material disabled color. Forcing white there would swap one
    // contrast failure for another. Text.style.color beats the button's own
    // disabledForegroundColor, so this has to be resolved here.
    final isEnabled = onPressed != null && !isLoading;
    final filledForeground = isEnabled
        ? onFilled
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);

    /// Unfilled variants sit on a light surface, so they keep the themed
    /// on-surface color they have always rendered with.
    final onUnfilled = textStyle?.color ?? colors.textPrimary;

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
            foregroundColor: onFilled,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: buildChild(filledForeground),
        );
      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: minimumSize,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            backgroundColor: colors.accent,
            foregroundColor: onFilled,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: buildChild(filledForeground),
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
              : buildChild(onUnfilled),
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
          child: isLoading
              ? LoadingIndicator(size: 21, color: onUnfilled)
              : buildChild(onUnfilled),
        );
    }
  }
}
