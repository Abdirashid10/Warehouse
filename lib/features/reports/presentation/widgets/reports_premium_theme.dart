import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/features/reports/presentation/cubit/reports_trends.dart';

/// Reserved status roles. Never reused as a chart series colour — a status
/// hue must always mean the same thing wherever it appears.
enum ReportsStatus { good, warning, serious, critical, info }

/// Accent identities for KPI tiles and section chrome.
enum ReportsAccent { indigo, sky, emerald, amber, coral, violet, slate }

/// Premium visual language for the Reports & Analytics module.
///
/// Deep midnight/slate chrome, frosted glass surfaces, royal indigo gradients,
/// and a **validated** categorical chart palette.
///
/// ## Chart palette provenance
///
/// [seriesColor] is an Okabe-Ito derived 5-hue set, checked with the dataviz
/// validator in light and dark mode over all pairs:
///
/// * lightness band, chroma floor, normal-vision separation, contrast — pass
/// * worst CVD pair (pink↔green, ΔE 7.6 deutan) sits in the 6–8 floor band, so
///   it is only legal **with secondary encoding**; every chart in this module
///   therefore ships a text legend and direct value labels, never colour alone
/// * amber and pink warn on contrast against the light chart surface, which the
///   same labelled legend relieves
///
/// The set stops at five. A sixth category folds into an explicit "Other"
/// bucket ([otherSeriesColor]) rather than inventing a cycled hue.
@immutable
class ReportsPalette {
  const ReportsPalette._(this.colors);

  factory ReportsPalette.of(BuildContext context) =>
      ReportsPalette._(WmsUiColors.of(context));

  final WmsUiColors colors;

  bool get isDark => colors.isDark;

  // ── Geometry ─────────────────────────────────────────────────────────────

  static const double radiusHero = 28;
  static const double radiusCard = 20;
  static const double radiusControl = 14;
  static const double radiusPill = 999;

  // ── Brand chrome ─────────────────────────────────────────────────────────

  /// Midnight slate → royal indigo → violet. The hero banner gradient.
  LinearGradient get heroGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0B1120),
          Color(0xFF1E2A78),
          Color(0xFF4338CA),
        ],
        stops: [0.0, 0.55, 1.0],
      );

  /// Royal blue → electric indigo, for buttons and active pills.
  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF2563EB), Color(0xFF6D28D9)]
            : const [Color(0xFF1D4ED8), Color(0xFF6366F1)],
      );

  Color get brand => isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA);

  /// Glow blooms painted behind the hero banner content.
  List<Color> get heroMeshColors => const [
        Color(0xFF6366F1),
        Color(0xFF0EA5E9),
        Color(0xFFA855F7),
      ];

  /// Ambient page wash.
  LinearGradient get pageGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF101A2E), colors.background, colors.background]
            : [const Color(0xFFEEF2FF), colors.background, colors.background],
        stops: const [0.0, 0.28, 1.0],
      );

  // ── Glass surfaces ───────────────────────────────────────────────────────

  LinearGradient get surfaceGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF162034), Color(0xFF111A2B)]
            : const [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
      );

  Color get insetFill => isDark
      ? Colors.white.withValues(alpha: 0.04)
      : const Color(0xFF0F172A).withValues(alpha: 0.035);

  Color get hairline => isDark
      ? Colors.white.withValues(alpha: 0.07)
      : const Color(0xFF0F172A).withValues(alpha: 0.06);

  Border glassBorder({Color? tint, double width = 1}) {
    final base = tint ?? (isDark ? Colors.white : const Color(0xFF0F172A));
    return Border.all(
      color: base.withValues(alpha: isDark ? 0.08 : 0.06),
      width: width,
    );
  }

  /// The surface charts are drawn on — the validator's reference background.
  Color get chartSurface =>
      isDark ? const Color(0xFF141D30) : const Color(0xFFFFFFFF);

  // ── Elevation ────────────────────────────────────────────────────────────

  List<BoxShadow> get cardShadow {
    final base = isDark ? Colors.black : const Color(0xFF1E293B);
    return [
      BoxShadow(
        color: base.withValues(alpha: isDark ? 0.34 : 0.04),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: base.withValues(alpha: isDark ? 0.28 : 0.06),
        blurRadius: 16,
        offset: const Offset(0, 6),
        spreadRadius: -4,
      ),
      BoxShadow(
        color: base.withValues(alpha: isDark ? 0.24 : 0.05),
        blurRadius: 34,
        offset: const Offset(0, 16),
        spreadRadius: -10,
      ),
    ];
  }

  List<BoxShadow> glow(
    Color color, {
    double opacity = 0.32,
    double blur = 22,
    double dy = 10,
    double spread = -6,
  }) =>
      [
        BoxShadow(
          color: color.withValues(alpha: isDark ? opacity : opacity * 0.85),
          blurRadius: blur,
          offset: Offset(0, dy),
          spreadRadius: spread,
        ),
      ];

  Color tint(Color color, [double alpha = 0.14]) =>
      color.withValues(alpha: isDark ? alpha : alpha * 0.9);

  // ── Accents ──────────────────────────────────────────────────────────────

  Color accent(ReportsAccent accent) => switch (accent) {
        ReportsAccent.indigo =>
          isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
        ReportsAccent.sky =>
          isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
        ReportsAccent.emerald =>
          isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
        ReportsAccent.amber =>
          isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
        ReportsAccent.coral =>
          isDark ? const Color(0xFFFB7185) : const Color(0xFFDC2626),
        ReportsAccent.violet =>
          isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
        ReportsAccent.slate =>
          isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
      };

  /// Reserved status colours — always paired with an icon and a label.
  Color status(ReportsStatus status) => switch (status) {
        ReportsStatus.good => accent(ReportsAccent.emerald),
        ReportsStatus.warning => accent(ReportsAccent.amber),
        ReportsStatus.serious => accent(ReportsAccent.coral),
        ReportsStatus.critical =>
          isDark ? const Color(0xFFF43F5E) : const Color(0xFFB91C1C),
        ReportsStatus.info => accent(ReportsAccent.sky),
      };

  /// Trend colour. [inverted] flips the semantics for metrics where a rise is
  /// bad (low stock, overdue tasks) — the arrow direction still shows the
  /// actual movement, so colour never contradicts the glyph.
  Color trendColor(TrendDirection direction, {bool inverted = false}) {
    switch (direction) {
      case TrendDirection.flat:
        return colors.textTertiary;
      case TrendDirection.up:
        return inverted ? status(ReportsStatus.serious) : status(ReportsStatus.good);
      case TrendDirection.down:
        return inverted ? status(ReportsStatus.good) : status(ReportsStatus.serious);
    }
  }

  // ── Categorical chart palette ────────────────────────────────────────────

  /// Fixed hue order. Never cycled — see the class docs.
  static const List<Color> _series = [
    Color(0xFF0072B2), // blue
    Color(0xFFE69F00), // amber
    Color(0xFF009E73), // green
    Color(0xFFCC79A7), // pink
    Color(0xFFD55E00), // vermillion
  ];

  /// Maximum categorical slots before folding into "Other".
  static const int maxSeries = 5;

  /// Colour for the explicit overflow bucket. Deliberately low-chroma so it
  /// never reads as one of the identities above.
  Color get otherSeriesColor =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  Color seriesColor(int index) {
    if (index < 0 || index >= _series.length) return otherSeriesColor;
    return _series[index];
  }

  /// Vertical gradient for a bar/area mark of the given series.
  List<Color> seriesGradient(int index) {
    final base = seriesColor(index);
    return [base.withValues(alpha: 0.85), base];
  }

  /// Grid and axis chrome — recessive by design.
  Color get chartGrid => hairline;

  Color get chartAxisLabel => colors.textTertiary;

  /// Tooltip surface — a raised slab, readable over any mark.
  Color get tooltipSurface =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A);
}
