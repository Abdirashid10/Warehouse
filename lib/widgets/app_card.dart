import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.accentColor,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? accentColor;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final radius = BorderRadius.circular(AppSpacing.radiusLg);
    final effectiveBackground = backgroundColor ?? wms.cardBackground;
    final effectiveBorderColor = borderColor ?? wms.border.withValues(alpha: 0.7);

    final card = ClipRRect(
      borderRadius: radius,
      child: Container(
        margin: margin,
        padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: effectiveBackground,
          borderRadius: radius,
          border: Border.all(
            color: effectiveBorderColor,
            width: elevated ? 1.0 : 0.8,
          ),
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.045),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.035),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        foregroundDecoration: accentColor != null
            ? BoxDecoration(
                borderRadius: radius,
                border: Border(
                  left: BorderSide(color: accentColor!, width: 3.5),
                ),
              )
            : null,
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: card,
        ),
      );
    }

    return card;
  }
}
