import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_theme.dart';
import 'package:logisticsmobile/widgets/wms/wms_pill_tab_bar.dart';

/// Reusable premium building blocks for the Administration console.
///
/// Every atom is theme-aware, overflow-safe at 320dp and free of feature logic.

// ─────────────────────────────────────────────────────────────────────────────
// Surfaces
// ─────────────────────────────────────────────────────────────────────────────

/// Frosted-glass surface with an optional colour-coded leading strip.
class AdminGlassCard extends StatelessWidget {
  const AdminGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md + 2),
    this.radius = AdminPalette.radiusCard,
    this.accentStrip,
    this.borderTint,
    this.glowColor,
    this.onTap,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Colour of the leading strip. Null draws no strip.
  final Color? accentStrip;
  final Color? borderTint;
  final Color? glowColor;
  final VoidCallback? onTap;
  final bool elevated;

  static const double stripWidth = 3.5;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          if (elevated) ...palette.cardShadow,
          if (glowColor != null)
            ...palette.glow(glowColor!, opacity: 0.16, blur: 26, dy: 12),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: palette.surfaceGradient,
          borderRadius: borderRadius,
          border: palette.glassBorder(tint: borderTint ?? accentStrip),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: (accentStrip ?? palette.brand).withValues(alpha: 0.08),
            // The strip is positioned rather than stretched: a stretched flex
            // child demands a bounded height, which a card inside a scroll
            // view never has.
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: accentStrip == null ? 0 : stripWidth,
                  ),
                  child: Padding(padding: padding, child: child),
                ),
                if (accentStrip != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: stripWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentStrip!,
                            accentStrip!.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Duotone icon inside a glowing, gradient-tinted well.
class AdminGlowBadge extends StatelessWidget {
  const AdminGlowBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 38,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final radius = BorderRadius.circular(size * 0.32);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow:
            palette.glow(color, opacity: 0.26, blur: 14, dy: 5, spread: -4),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: palette.isDark ? 0.30 : 0.20),
              color.withValues(alpha: palette.isDark ? 0.12 : 0.08),
            ],
          ),
          borderRadius: radius,
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Icon(icon, size: size * 0.48, color: color),
        ),
      ),
    );
  }
}

/// Compact status chip — the console's badge vocabulary.
class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({
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
    final palette = AdminPalette.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 9,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: palette.tint(color, 0.14),
        borderRadius: BorderRadius.circular(AdminPalette.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: dense ? 10.5 : 11,
                height: 1.15,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero banner
// ─────────────────────────────────────────────────────────────────────────────

/// Deep indigo console banner with a soft background mesh of colour blooms.
class AdminHeroBanner extends StatelessWidget {
  const AdminHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.shield_moon_rounded,
    this.trailing,
    this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// Optional badge docked to the right of the title block.
  final Widget? trailing;

  /// Content docked under the title — typically the bento metric grid.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AdminPalette.radiusHero),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.heroGradient),
        child: CustomPaint(
          painter: _HeroMeshPainter(colors: palette.heroMeshColors),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.lg,
              AppSpacing.screenPadding,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                WmsDesignTokens.sectionTitle(context).copyWith(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: WmsDesignTokens.supporting(context).copyWith(
                              color: Colors.white.withValues(alpha: 0.80),
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      trailing!,
                    ],
                  ],
                ),
                if (child != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  child!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroMeshPainter extends CustomPainter {
  const _HeroMeshPainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final blooms = <({Offset center, double radius, Color color})>[
      (
        center: Offset(size.width * 0.88, size.height * 0.10),
        radius: size.width * 0.44,
        color: colors[0],
      ),
      (
        center: Offset(size.width * 0.06, size.height * 0.94),
        radius: size.width * 0.38,
        color: colors[1],
      ),
      (
        center: Offset(size.width * 0.48, size.height * -0.20),
        radius: size.width * 0.34,
        color: colors[2],
      ),
    ];

    for (final bloom in blooms) {
      final rect = Rect.fromCircle(center: bloom.center, radius: bloom.radius);
      canvas.drawCircle(
        bloom.center,
        bloom.radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              bloom.color.withValues(alpha: 0.36),
              bloom.color.withValues(alpha: 0.0),
            ],
          ).createShader(rect),
      );
    }

    final sheenRect = Rect.fromLTWH(0, 0, size.width, 1.5);
    canvas.drawRect(
      sheenRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(sheenRect),
    );
  }

  @override
  bool shouldRepaint(covariant _HeroMeshPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

// ─────────────────────────────────────────────────────────────────────────────
// Bento metric grid
// ─────────────────────────────────────────────────────────────────────────────

/// One tile of the console's bento metric grid.
///
/// Where a metric has a meaningful denominator ([share]) the tile draws a
/// micro-bar for that ratio. Ratios are computed from the loaded directory —
/// the console holds no history, so no tile ever claims a period-over-period
/// delta it cannot substantiate.
class AdminBentoCard extends StatelessWidget {
  const AdminBentoCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.caption,
    this.share,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  /// Supporting line under the label.
  final String? caption;

  /// 0..1 ratio of this metric against its natural whole.
  final double? share;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;

    return AdminGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderTint: accent,
      glowColor: accent,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminGlowBadge(icon: icon, color: accent, size: 34),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: WmsDesignTokens.cardNumber(context).copyWith(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.1,
                letterSpacing: -0.6,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.kpiLabel(context).copyWith(
              color: colors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              height: 1.25,
            ),
          ),
          if (share != null) ...[
            const SizedBox(height: 7),
            AdminMicroBar(fraction: share!, color: accent),
          ],
          if (caption != null) ...[
            const SizedBox(height: 5),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textTertiary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Thin animated ratio bar used inside bento tiles and capacity cards.
class AdminMicroBar extends StatelessWidget {
  const AdminMicroBar({
    super.key,
    required this.fraction,
    required this.color,
    this.height = 5,
    this.animate = true,
  });

  final double fraction;
  final Color color;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final target = fraction.clamp(0.0, 1.0);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: palette.insetFill,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: animate ? 0 : target,
                  end: target,
                ),
                duration: const Duration(milliseconds: 680),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  if (value <= 0) return const SizedBox.shrink();
                  return Container(
                    width: math.min(maxWidth, math.max(height, maxWidth * value)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.72), color],
                      ),
                      borderRadius: BorderRadius.circular(height),
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

// ─────────────────────────────────────────────────────────────────────────────
// Identity
// ─────────────────────────────────────────────────────────────────────────────

/// Circular avatar with a role-tinted ring and an optional status dot.
class AdminAvatar extends StatelessWidget {
  const AdminAvatar({
    super.key,
    required this.initials,
    required this.accent,
    this.size = 46,
    this.statusColor,
  });

  final String initials;
  final Color accent;
  final double size;

  /// Draws a badge dot on the avatar's lower-right corner when set.
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: palette.glow(
                accent,
                opacity: 0.30,
                blur: 14,
                dy: 5,
                spread: -4,
              ),
            ),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: palette.isDark ? 0.34 : 0.22),
                    accent.withValues(alpha: palette.isDark ? 0.14 : 0.10),
                  ],
                ),
                border: Border.all(color: accent.withValues(alpha: 0.34)),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  initials,
                  style: WmsDesignTokens.cardNumber(context).copyWith(
                    color: accent,
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
          if (statusColor != null)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.colors.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Structured metadata row — icon, label, value.
class AdminInfoRow extends StatelessWidget {
  const AdminInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.dense = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 3 : 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: colors.textTertiary),
          const SizedBox(width: 8),
          SizedBox(
            width: dense ? 74 : 92,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textTertiary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: valueColor ?? colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chrome
// ─────────────────────────────────────────────────────────────────────────────

/// Recessed search field with a vector prefix and a one-tap clear.
class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hint,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;

    return Container(
      decoration: BoxDecoration(
        color: palette.insetFill,
        borderRadius: BorderRadius.circular(AdminPalette.radiusControl),
        border: palette.glassBorder(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: palette.tint(palette.brand, 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.search_rounded, size: 17, color: palette.brand),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: palette.brand,
              style: WmsDesignTokens.body(context).copyWith(
                color: colors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: WmsDesignTokens.body(context).copyWith(
                  color: colors.textTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox(width: 4);
              return IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                tooltip: 'Clear search',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(width: 32, height: 32),
                icon: Icon(
                  Icons.cancel_rounded,
                  size: 17,
                  color: colors.textTertiary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Filter pill with an optional icon and badge counter.
class AdminFilterPill extends StatelessWidget {
  const AdminFilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// Identity colour used for the icon when the pill is inactive.
  final Color? accent;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;
    final radius = BorderRadius.circular(AdminPalette.radiusPill);
    final foreground = selected ? Colors.white : colors.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: selected
            ? palette.glow(palette.brand,
                opacity: 0.30, blur: 12, dy: 4, spread: -3)
            : null,
      ),
      child: Material(
        color: selected ? Colors.transparent : palette.insetFill,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: selected ? palette.brandGradient : null,
            borderRadius: radius,
            border: selected ? null : palette.glassBorder(),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 14,
                      color: selected ? Colors.white : (accent ?? foreground),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 12.5,
                        height: 1.15,
                      ),
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 7),
                    Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.22)
                            : palette.tint(accent ?? palette.brand, 0.13),
                        borderRadius:
                            BorderRadius.circular(AdminPalette.radiusPill),
                      ),
                      child: Text(
                        '$count',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style:
                            WmsDesignTokens.supportingDense(context).copyWith(
                          color: selected
                              ? Colors.white
                              : (accent ?? palette.brand),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section heading with an eyebrow and optional trailing slot.
class AdminSectionIntro extends StatelessWidget {
  const AdminSectionIntro({
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
    final palette = AdminPalette.of(context);
    final colors = palette.colors;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                  fontSize: 17.5,
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
                    fontSize: 12.5,
                    height: 1.45,
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

/// Pill tab selector wearing the Administration palette.
class AdminPillTabBar extends StatelessWidget {
  const AdminPillTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  final TabController controller;
  final List<WmsPillTabSpec> tabs;

  static const double height = WmsPillTabBar.height;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);

    return WmsPillTabBar(
      controller: controller,
      tabs: tabs,
      style: WmsPillTabStyle(
        activeGradient: palette.brandGradient,
        trackColor: palette.insetFill,
        trackBorder: palette.glassBorder(),
        activeLabel: Colors.white,
        inactiveLabel: palette.colors.textSecondary,
        activeGlow: palette.glow(
          palette.brand,
          opacity: 0.34,
          blur: 14,
          dy: 4,
          spread: -3,
        ),
      ),
    );
  }
}

/// Compact gradient action button with a soft glow.
class AdminGradientButton extends StatelessWidget {
  const AdminGradientButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.expanded = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final radius = BorderRadius.circular(AdminPalette.radiusPill);

    final button = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: palette.glow(palette.brand, opacity: 0.36, blur: 18, dy: 8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: palette.brandGradient,
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            splashColor: Colors.white.withValues(alpha: 0.16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              child: Row(
                mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.buttonLabel(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
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

/// Enterprise empty state with a duotone mark and an optional action.
class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon = Icons.refresh_rounded,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: AdminGlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              palette.brand.withValues(alpha: 0.22),
                              palette.brand.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.tint(palette.brand, 0.12),
                          border: Border.all(
                            color: palette.brand.withValues(alpha: 0.24),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, size: 25, color: palette.brand),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: WmsDesignTokens.sectionTitle(context).copyWith(
                  color: colors.textPrimary,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: WmsDesignTokens.supporting(context).copyWith(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: AdminGradientButton(
                    icon: actionIcon,
                    label: actionLabel!,
                    onPressed: onAction!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Scrollable body shared by every console tab.
class AdminTabScroll extends StatelessWidget {
  const AdminTabScroll({
    super.key,
    required this.children,
    this.padding = false,
  });

  final List<Widget> children;

  /// Applies horizontal screen padding. The console insets its tab view, so
  /// panels default to vertical padding only.
  final bool padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding
          ? const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.xxxl,
            )
          : const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.xxxl,
            ),
      children: children,
    );
  }
}
