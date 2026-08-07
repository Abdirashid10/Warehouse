import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';

/// Elevated enterprise surface — crisp card face, hairline border and a
/// layered, ultra-soft Material 3 shadow.
///
/// The shadow is built from three stacked layers rather than a single blur:
/// a tight *contact* shadow that anchors the card to the background, a *key*
/// shadow that carries the elevation, and a wide, negatively-spread *ambient*
/// shadow that dissolves into the page. That is what separates a premium
/// enterprise surface from a flat box with a drop shadow.
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

  /// Draws a colored rail on the leading edge of the card.
  final Color? accentColor;

  /// Raises the card onto the full elevation shadow stack.
  final bool elevated;

  /// Width of the accent rail drawn when [accentColor] is set.
  static const double _accentRailWidth = 3.5;

  /// Minimum distance kept between the card's left edge and its content when
  /// an accent rail is drawn.
  ///
  /// The rail is painted as a `foregroundDecoration` — on top of the content
  /// and outside the padding box — so the caller's own padding is the only
  /// thing holding text off it. Compact callers pass as little as 4dp, which
  /// leaves copy visually glued to a 3.5dp rail. This floor guarantees the
  /// gap without inflating cards that already pad generously.
  static const double _accentContentClearance = 12;

  /// Base shadow color — near-black slate in light mode, true black in dark
  /// mode where slate-on-slate would read as a muddy halo.
  static Color _shadowBase(bool isDark) =>
      isDark ? const Color(0xFF000000) : const Color(0xFF0F172A);

  static List<BoxShadow> _shadows({
    required bool isDark,
    required bool elevated,
  }) {
    final base = _shadowBase(isDark);

    if (!elevated) {
      return [
        BoxShadow(
          color: base.withValues(alpha: isDark ? 0.24 : 0.03),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: base.withValues(alpha: isDark ? 0.20 : 0.035),
          blurRadius: 10,
          offset: const Offset(0, 3),
          spreadRadius: -2,
        ),
      ];
    }

    return [
      // Contact — keeps the edge crisp against the page.
      BoxShadow(
        color: base.withValues(alpha: isDark ? 0.30 : 0.035),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
      // Key — the readable elevation.
      BoxShadow(
        color: base.withValues(alpha: isDark ? 0.26 : 0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
        spreadRadius: -1,
      ),
      // Ambient — wide and negatively spread so it fades, never smudges.
      BoxShadow(
        color: base.withValues(alpha: isDark ? 0.22 : 0.045),
        blurRadius: 28,
        offset: const Offset(0, 12),
        spreadRadius: -6,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppSpacing.radiusLg);

    final effectiveBackground = backgroundColor ?? wms.cardBackground;
    final effectiveBorderColor =
        borderColor ?? wms.border.withValues(alpha: isDark ? 0.55 : 0.7);

    final effectivePadding =
        padding ?? const EdgeInsets.all(AppSpacing.cardPadding);

    // Top up the leading inset only when the caller's own padding leaves the
    // content too close to the accent rail.
    final railInset = accentColor == null
        ? 0.0
        : math.max(
            0.0,
            _accentContentClearance -
                effectivePadding.resolve(Directionality.of(context)).left,
          );

    // Border and padding only — the background lives on the layer below so an
    // ink ripple can render between the two and stay visible.
    final content = Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: effectiveBorderColor,
          width: elevated ? 1.0 : 0.8,
        ),
      ),
      foregroundDecoration: accentColor != null
          ? BoxDecoration(
              borderRadius: radius,
              border: Border(
                left: BorderSide(color: accentColor!, width: _accentRailWidth),
              ),
            )
          : null,
      child: railInset > 0
          // Physical left: the rail is drawn with Border(left:), which is not
          // direction-aware, so the compensating inset must not be either.
          ? Padding(
              padding: EdgeInsets.only(left: railInset),
              child: child,
            )
          : child,
    );

    // The shadow must live outside the clip — a ClipRRect would crop it.
    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: radius,
        boxShadow: _shadows(isDark: isDark, elevated: elevated),
      ),
      child: onTap == null
          ? ClipRRect(borderRadius: radius, child: content)
          // InkWell wraps the content rather than overlaying it, so any
          // interactive child still wins the gesture arena.
          : Material(
              color: effectiveBackground,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(onTap: onTap, child: content),
            ),
    );

    return margin != null ? Padding(padding: margin!, child: surface) : surface;
  }
}
