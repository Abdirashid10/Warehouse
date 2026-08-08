import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/features/warehouses/presentation/widgets/warehouse_premium_theme.dart';

/// Reusable premium building blocks for the Warehouses module.
///
/// Each atom is theme-aware, overflow-safe and free of feature logic, so the
/// composed screens stay declarative and every surface shares one visual
/// grammar.

// ─────────────────────────────────────────────────────────────────────────────
// Surfaces
// ─────────────────────────────────────────────────────────────────────────────

/// Frosted-glass surface — gradient face, hairline ring and layered shadow.
class WarehouseGlassPanel extends StatelessWidget {
  const WarehouseGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = WarehousePalette.radiusPanel,
    this.borderTint,
    this.onTap,
    this.elevated = true,
    this.glowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Tints the frosted hairline — used to mark a card by capacity band.
  final Color? borderTint;
  final VoidCallback? onTap;
  final bool elevated;

  /// Optional coloured halo cast beneath the surface.
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          if (elevated) ...palette.cardShadow,
          if (glowColor != null)
            ...palette.glow(glowColor!, opacity: 0.18, blur: 30, dy: 14),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: palette.surfaceGradient,
          borderRadius: borderRadius,
          border: palette.glassBorder(tint: borderTint),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: palette.brand.withValues(alpha: 0.08),
            highlightColor: palette.brand.withValues(alpha: 0.04),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Buttons & actions
// ─────────────────────────────────────────────────────────────────────────────

/// Signature call-to-action — royal blue → indigo gradient with a soft glow.
class WarehouseGradientButton extends StatelessWidget {
  const WarehouseGradientButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.expanded = true,
    this.height = 54,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final radius = BorderRadius.circular(AppSpacing.radiusLg);

    final button = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: palette.glow(palette.brand, opacity: 0.42, blur: 26, dy: 12),
      ),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: palette.brandGradient,
          borderRadius: radius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            splashColor: Colors.white.withValues(alpha: 0.16),
            highlightColor: Colors.white.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.buttonLabel(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Soft-fill action — tinted well, no heavy border, icon plus optional label.
class WarehouseSoftAction extends StatelessWidget {
  const WarehouseSoftAction({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
    this.tooltip,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  /// When null the action renders as a square icon button.
  final String? label;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final radius = BorderRadius.circular(WarehousePalette.radiusControl);
    final hasLabel = label != null;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        if (hasLabel) ...[
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.1,
              ),
            ),
          ),
        ],
      ],
    );

    final button = Material(
      color: palette.tint(color, 0.13),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: color.withValues(alpha: 0.14),
        child: Container(
          height: size,
          width: hasLabel ? null : size,
          constraints: BoxConstraints(minWidth: hasLabel ? 0 : size),
          padding: hasLabel
              ? const EdgeInsets.symmetric(horizontal: AppSpacing.md)
              : EdgeInsets.zero,
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    final semantic = tooltip ?? label;
    return semantic == null
        ? button
        : Tooltip(message: semantic, child: button);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badges & pills
// ─────────────────────────────────────────────────────────────────────────────

/// Icon inside a glowing, gradient-tinted well.
class WarehouseGlowBadge extends StatelessWidget {
  const WarehouseGlowBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 42,
    this.iconSize,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final radius = BorderRadius.circular(size * 0.32);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: palette.glow(color, opacity: 0.30, blur: 16, dy: 6, spread: -4),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: palette.isDark ? 0.28 : 0.18),
              color.withValues(alpha: palette.isDark ? 0.12 : 0.08),
            ],
          ),
          borderRadius: radius,
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Icon(icon, size: iconSize ?? size * 0.48, color: color),
        ),
      ),
    );
  }
}

/// Gradient identity tile carrying a warehouse's initials.
class WarehouseGradientTile extends StatelessWidget {
  const WarehouseGradientTile({
    super.key,
    required this.initials,
    this.size = 54,
    this.gradientColors,
  });

  final String initials;
  final double size;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final ramp = gradientColors;
    final radius = BorderRadius.circular(size * 0.32);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: palette.glow(
          ramp?.last ?? palette.brand,
          opacity: 0.34,
          blur: 18,
          dy: 8,
          spread: -4,
        ),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: ramp == null
              ? palette.brandGradient
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: ramp,
                ),
          borderRadius: radius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            initials,
            style: WmsDesignTokens.cardNumber(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.34,
              letterSpacing: 0.2,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact tonal pill — the module's badge vocabulary.
class WarehouseTonePill extends StatelessWidget {
  const WarehouseTonePill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: palette.tint(color, 0.14),
        borderRadius: BorderRadius.circular(WarehousePalette.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.supportingDense(context).copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 11 : 12,
              height: 1.15,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Breadcrumb rendered as a single frosted badge instead of loose text.
class WarehouseBreadcrumbBadge extends StatelessWidget {
  const WarehouseBreadcrumbBadge({
    super.key,
    required this.icon,
    required this.parent,
    required this.current,
  });

  final IconData icon;
  final String parent;
  final String current;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.insetFill,
        borderRadius: BorderRadius.circular(WarehousePalette.radiusPill),
        border: palette.glassBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.brand),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              parent.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                height: 1.2,
                letterSpacing: 0.7,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: colors.textTertiary,
            ),
          ),
          Flexible(
            child: Text(
              current.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: palette.brand,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                height: 1.2,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data display
// ─────────────────────────────────────────────────────────────────────────────

/// Animated, gradient capacity meter with a recessed track.
class WarehouseCapacityMeter extends StatelessWidget {
  const WarehouseCapacityMeter({
    super.key,
    required this.percent,
    this.height = WarehousePalette.meterHeight,
    this.animate = true,
  });

  final int percent;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final ramp = palette.capacityGradient(percent);
    final fraction = (percent / 100).clamp(0.0, 1.0);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;

          return Stack(
            children: [
              // Track.
              Container(
                decoration: BoxDecoration(
                  color: palette.insetFill,
                  borderRadius: BorderRadius.circular(WarehousePalette.radiusPill),
                  border: palette.glassBorder(),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: animate ? 0 : fraction, end: fraction),
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  if (value <= 0) return const SizedBox.shrink();
                  // Never collapse below one cap width, so a sliver of fill
                  // stays legible at very low utilisation.
                  final width = math.max(height, maxWidth * value);
                  return Container(
                    width: math.min(width, maxWidth),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: ramp),
                      borderRadius:
                          BorderRadius.circular(WarehousePalette.radiusPill),
                      boxShadow: palette.glow(
                        ramp.last,
                        opacity: 0.45,
                        blur: 10,
                        dy: 2,
                        spread: -2,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Minimalist metric box — recessed fill, crisp numeric hierarchy.
class WarehouseMetricBox extends StatelessWidget {
  const WarehouseMetricBox({
    super.key,
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
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: palette.insetFill,
        borderRadius: BorderRadius.circular(WarehousePalette.radiusControl),
        border: palette.glassBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scales down rather than truncating, so a long label such as
          // "AVAILABLE" stays whole inside a 3-up grid on a 320dp phone.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 5),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: WmsDesignTokens.cardNumber(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.15,
                letterSpacing: -0.2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading with an eyebrow, sleek title and optional trailing slot.
class WarehouseSectionHeading extends StatelessWidget {
  const WarehouseSectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: WmsDesignTokens.supportingDense(context).copyWith(
                  color: palette.brand,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: WmsDesignTokens.sectionTitle(context).copyWith(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1.25,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: WmsDesignTokens.supporting(context).copyWith(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}
