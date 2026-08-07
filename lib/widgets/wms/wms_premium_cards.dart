import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/widgets/app_card.dart';

/// Fixed visual grammar for the enterprise metric card.
///
/// Every number here is a design token — the card, the grids that host it and
/// the sections that frame it all derive their geometry from this class so the
/// mobile dashboard stays pixel-aligned with the web dashboard.
abstract final class WmsPremiumMetricCard {
  // --- Icon badge ---------------------------------------------------------

  /// Preferred outer size of the rounded icon badge.
  static const double badgeSize = 46;

  /// Smallest the badge may shrink to before the card starts scaling text.
  static const double badgeSizeMin = 32;

  /// Icon glyph size inside the badge (≈52% of the badge for optical balance).
  static const double badgeIconSize = 24;

  // --- Typography ---------------------------------------------------------

  /// Metric number size.
  static const double metricFontSize = 24;

  /// Compact metric number size (tight 2-column phone grids).
  static const double metricFontSizeCompact = 21;

  /// Metric label size.
  static const double labelFontSize = 13;

  /// Supporting caption size — never below the global readable minimum.
  static const double subtitleFontSize = 12;

  /// Status pill size.
  static const double statusFontSize = 10;

  static const double metricHeightFactor = 1.1;
  static const double labelHeightFactor = 1.25;
  static const double subtitleHeightFactor = 1.25;

  // --- Rhythm -------------------------------------------------------------

  /// Internal card padding for premium metric cards.
  static const EdgeInsets cardPadding = EdgeInsets.all(14);

  /// Vertical gap between the icon badge and the metric value.
  static const double iconToMetricGap = 10;

  /// Vertical gap between the metric value and its label.
  static const double metricToLabelGap = 3;

  /// Vertical gap between the label and the footer (subtitle or status pill).
  static const double labelToFooterGap = 3;

  /// Extra vertical box around the status pill text (padding + hairline).
  static const double statusPillChrome = 8;

  /// Width assumed when the card is laid out with unbounded width
  /// (e.g. as a direct child of a [Wrap]).
  static const double fallbackContentWidth = 168;

  // --- Grid geometry ------------------------------------------------------

  /// Row height for a metric grid whose cards carry a footer line.
  ///
  /// Derived from the token budget above with headroom for a 1.2× text scale.
  static const double gridExtent = 168;

  /// Row height for a metric grid without footer lines.
  static const double gridExtentCompact = 150;

  /// Shared soft tint helper for building preview/placeholder tints.
  static Color tint(Color color) => color.withValues(alpha: 0.10);
}

/// Shared premium icon badge — soft tinted rounded square with a matching
/// hairline ring and an optically centered glyph (web-dashboard parity).
class WmsPremiumIconBadge extends StatelessWidget {
  const WmsPremiumIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = WmsPremiumMetricCard.badgeSize,
    this.iconSize,
    this.showRing = true,
  });

  final IconData icon;
  final Color color;

  /// Outer size of the badge container.
  final double size;

  /// Optional explicit icon glyph size. Defaults to 52% of [size], which keeps
  /// a balanced ring of tint around the glyph at every badge size.
  final double? iconSize;

  /// Whether to draw the subtle matching-colored border around the badge.
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final glyphSize = iconSize ?? size * 0.52;
    final radius = BorderRadius.circular(size * 0.30);

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.16),
              color.withValues(alpha: 0.07),
            ],
          ),
          borderRadius: radius,
          border: showRing
              ? Border.all(color: color.withValues(alpha: 0.16), width: 1)
              : null,
        ),
        // Center + FittedBox guarantee the glyph is perfectly centered and can
        // never overflow its container, whatever badge size is resolved.
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Icon(icon, size: glyphSize, color: color),
          ),
        ),
      ),
    );
  }
}

/// Compact, professional status pill — the badge vocabulary shared by the
/// metric cards and the section headers.
class WmsStatusPill extends StatelessWidget {
  const WmsStatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: WmsDesignTokens.supportingDense(context).copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: WmsPremiumMetricCard.statusFontSize,
          height: 1.1,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Elite centered metric card — the single building block behind every KPI,
/// overview and alert tile on the dashboard.
///
/// Layout is a strict vertical rhythm, centered on the card's axis:
///
/// ```text
///        ┌────────┐
///        │  icon  │   soft-tinted badge, glyph optically centered
///        └────────┘
///          1,284       metric value  (Poppins 24 / w700)
///        Units On Hand  label        (Inter 13 / w700)
///        Total quantity footer       (caption or status pill)
/// ```
///
/// Overflow safety is layered, so the card is safe inside fixed-height grids
/// at any accessibility text scale:
///  1. every text run is single-line with ellipsis,
///  2. the badge shrinks first when vertical room is tight,
///  3. a final `BoxFit.scaleDown` proportionally scales the whole stack.
class WmsMetricCard extends StatelessWidget {
  const WmsMetricCard({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.subtitle,
    this.status,
    this.statusColor,
    this.onTap,
    this.emphasizeValue = false,
    this.highlighted = false,
    this.compact = false,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  /// Supporting caption shown on the footer line when [status] is absent.
  final String? subtitle;

  /// Status pill shown on the footer line. Takes precedence over [subtitle]
  /// so every card in a grid keeps exactly one footer line — and therefore a
  /// perfectly aligned baseline across the row.
  final String? status;

  /// Pill color. Defaults to [color].
  final Color? statusColor;

  final VoidCallback? onTap;

  /// Tint the metric number with [color] — used by alert tiles where the
  /// number itself carries the severity.
  final bool emphasizeValue;

  /// Draw a colored hairline border to mark a tile that needs attention.
  final bool highlighted;

  /// Slightly denser type scale for tight 2-column phone grids.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metricSize = compact
        ? WmsPremiumMetricCard.metricFontSizeCompact
        : WmsPremiumMetricCard.metricFontSize;

    final valueStyle = WmsDesignTokens.kpiValue(context).copyWith(
      fontSize: metricSize,
      fontWeight: FontWeight.w700,
      height: WmsPremiumMetricCard.metricHeightFactor,
      letterSpacing: -0.5,
      color: emphasizeValue ? color : null,
      // Web parity with `tabular-nums`: fixed-advance digits so metric values
      // stay optically aligned down a column instead of shimmering.
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final labelStyle = WmsDesignTokens.kpiLabel(context).copyWith(
      fontSize: WmsPremiumMetricCard.labelFontSize,
      fontWeight: FontWeight.w700,
      height: WmsPremiumMetricCard.labelHeightFactor,
      letterSpacing: -0.1,
      color: scheme.onSurface,
    );

    final subtitleStyle = WmsDesignTokens.supportingDense(context).copyWith(
      fontSize: WmsPremiumMetricCard.subtitleFontSize,
      height: WmsPremiumMetricCard.subtitleHeightFactor,
      fontWeight: FontWeight.w500,
    );

    return AppCard(
      elevated: true,
      onTap: onTap,
      padding: WmsPremiumMetricCard.cardPadding,
      borderColor: highlighted ? color.withValues(alpha: 0.24) : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scaler = MediaQuery.textScalerOf(context);

          // --- Vertical budget -------------------------------------------
          final valueHeight =
              scaler.scale(metricSize) * WmsPremiumMetricCard.metricHeightFactor;
          final labelHeight =
              scaler.scale(WmsPremiumMetricCard.labelFontSize) *
                  WmsPremiumMetricCard.labelHeightFactor;

          final double footerHeight;
          if (status != null) {
            footerHeight =
                scaler.scale(WmsPremiumMetricCard.statusFontSize) * 1.1 +
                    WmsPremiumMetricCard.statusPillChrome;
          } else if (subtitle != null) {
            footerHeight =
                scaler.scale(WmsPremiumMetricCard.subtitleFontSize) *
                    WmsPremiumMetricCard.subtitleHeightFactor;
          } else {
            footerHeight = 0;
          }
          final hasFooter = footerHeight > 0;

          final gaps = WmsPremiumMetricCard.iconToMetricGap +
              WmsPremiumMetricCard.metricToLabelGap +
              (hasFooter ? WmsPremiumMetricCard.labelToFooterGap : 0.0);

          // The badge absorbs tight vertical space before any text scales.
          var badgeSize = WmsPremiumMetricCard.badgeSize;
          if (constraints.maxHeight.isFinite) {
            final room = constraints.maxHeight -
                (valueHeight + labelHeight + footerHeight + gaps);
            badgeSize = math.max(
              WmsPremiumMetricCard.badgeSizeMin,
              math.min(WmsPremiumMetricCard.badgeSize, room),
            );
          }

          final contentWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : WmsPremiumMetricCard.fallbackContentWidth;

          final stack = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              WmsPremiumIconBadge(icon: icon, color: color, size: badgeSize),
              const SizedBox(height: WmsPremiumMetricCard.iconToMetricGap),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: valueStyle,
                  ),
                ),
              ),
              const SizedBox(height: WmsPremiumMetricCard.metricToLabelGap),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: labelStyle,
              ),
              if (hasFooter) ...[
                const SizedBox(height: WmsPremiumMetricCard.labelToFooterGap),
                if (status != null)
                  WmsStatusPill(label: status!, color: statusColor ?? color)
                else
                  Text(
                    subtitle!,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: subtitleStyle,
                  ),
              ],
            ],
          );

          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(width: contentWidth, child: stack),
            ),
          );
        },
      ),
    );
  }
}
