import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';

/// Capacity severity bands used across every warehouse surface.
///
/// The bands are the single source of truth for the colour language of the
/// module: meters, chart rods, status pills and legends all resolve their
/// colours through [WarehousePalette] so a warehouse reads identically
/// wherever it appears.
enum WarehouseCapacityBand {
  /// Under 40% — plenty of room.
  low,

  /// 40–69% — healthy, actively used.
  moderate,

  /// 70–89% — approaching capacity.
  high,

  /// 90%+ — effectively full.
  critical;

  static WarehouseCapacityBand fromPercent(int percent) {
    if (percent >= 90) return WarehouseCapacityBand.critical;
    if (percent >= 70) return WarehouseCapacityBand.high;
    if (percent >= 40) return WarehouseCapacityBand.moderate;
    return WarehouseCapacityBand.low;
  }

  String get label => switch (this) {
        WarehouseCapacityBand.low => 'Low',
        WarehouseCapacityBand.moderate => 'Moderate',
        WarehouseCapacityBand.high => 'High',
        WarehouseCapacityBand.critical => 'Critical',
      };
}

/// Premium visual language for the Warehouses module.
///
/// Everything here is derived from the app-wide [WmsUiColors] so the module
/// stays theme-aware (light *and* dark) while layering on the richer
/// treatments the module needs — brand gradients, frosted glass borders,
/// coloured glows and the capacity colour ramp.
@immutable
class WarehousePalette {
  const WarehousePalette._(this.colors);

  factory WarehousePalette.of(BuildContext context) =>
      WarehousePalette._(WmsUiColors.of(context));

  final WmsUiColors colors;

  bool get isDark => colors.isDark;

  // ── Geometry ─────────────────────────────────────────────────────────────

  /// Warehouse card / hero surfaces.
  static const double radiusCard = 22;

  /// Floating panels (search bar, analytics cards).
  static const double radiusPanel = 20;

  /// Inputs, soft-fill buttons and metric boxes.
  static const double radiusControl = 14;

  /// Fully rounded pills and meters.
  static const double radiusPill = 999;

  /// Height of the capacity meter.
  static const double meterHeight = 10;

  // ── Brand ────────────────────────────────────────────────────────────────

  /// Deep royal blue → electric indigo. The module's signature gradient.
  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF2563EB), Color(0xFF6D28D9)]
            : const [Color(0xFF1D4ED8), Color(0xFF6366F1)],
      );

  /// The mid-tone of [brandGradient] — used for glows and tinted accents.
  Color get brand => isDark ? const Color(0xFF6366F1) : const Color(0xFF4338CA);

  /// Ambient page wash behind the scroll view.
  LinearGradient get pageGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF131C31),
                colors.background,
                colors.background,
              ]
            : [
                const Color(0xFFEEF2FF),
                colors.background,
                colors.background,
              ],
        stops: const [0.0, 0.32, 1.0],
      );

  // ── Surfaces ─────────────────────────────────────────────────────────────

  /// Subtle top-lit gradient for elevated card faces.
  LinearGradient get surfaceGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF162034), Color(0xFF111A2B)]
            : const [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
      );

  /// Recessed fill for metric boxes and inputs sitting inside a card.
  Color get insetFill => isDark
      ? Colors.white.withValues(alpha: 0.04)
      : const Color(0xFF0F172A).withValues(alpha: 0.035);

  /// Frosted-glass hairline. Light and bright at the top edge, so surfaces
  /// read as glass rather than as outlined boxes.
  Border glassBorder({Color? tint, double width = 1}) {
    final base = tint ??
        (isDark ? Colors.white : const Color(0xFF0F172A));
    return Border.all(
      color: base.withValues(alpha: isDark ? 0.08 : 0.06),
      width: width,
    );
  }

  /// Hairline divider tuned for glass surfaces.
  Color get hairline => isDark
      ? Colors.white.withValues(alpha: 0.07)
      : const Color(0xFF0F172A).withValues(alpha: 0.06);

  // ── Elevation ────────────────────────────────────────────────────────────

  /// Layered, ultra-soft card shadow — contact + key + ambient.
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

  /// Softer variant for floating panels (search bar, filter tray).
  List<BoxShadow> get panelShadow {
    final base = isDark ? Colors.black : const Color(0xFF1E293B);
    return [
      BoxShadow(
        color: base.withValues(alpha: isDark ? 0.30 : 0.05),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: -6,
      ),
    ];
  }

  /// Coloured glow used under gradient buttons and icon badges.
  List<BoxShadow> glow(
    Color color, {
    double opacity = 0.34,
    double blur = 24,
    double dy = 10,
    double spread = -6,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: isDark ? opacity : opacity * 0.85),
        blurRadius: blur,
        offset: Offset(0, dy),
        spreadRadius: spread,
      ),
    ];
  }

  // ── Capacity ramp ────────────────────────────────────────────────────────

  /// Gradient for a capacity band — green (low) → indigo (moderate) →
  /// amber (high) → red (critical).
  List<Color> bandGradient(WarehouseCapacityBand band) => switch (band) {
        WarehouseCapacityBand.low => isDark
            ? const [Color(0xFF34D399), Color(0xFF059669)]
            : const [Color(0xFF22C55E), Color(0xFF15803D)],
        WarehouseCapacityBand.moderate => isDark
            ? const [Color(0xFF60A5FA), Color(0xFF6366F1)]
            : const [Color(0xFF3B82F6), Color(0xFF4338CA)],
        WarehouseCapacityBand.high => isDark
            ? const [Color(0xFFFBBF24), Color(0xFFF97316)]
            : const [Color(0xFFF59E0B), Color(0xFFEA580C)],
        WarehouseCapacityBand.critical => isDark
            ? const [Color(0xFFFB7185), Color(0xFFE11D48)]
            : const [Color(0xFFEF4444), Color(0xFFBE123C)],
      };

  /// Readable solid colour for a band — the bright end on dark backgrounds,
  /// the deep end on light ones, so text always clears contrast minimums.
  Color bandColor(WarehouseCapacityBand band) {
    final ramp = bandGradient(band);
    return isDark ? ramp.first : ramp.last;
  }

  List<Color> capacityGradient(int percent) =>
      bandGradient(WarehouseCapacityBand.fromPercent(percent));

  Color capacityColor(int percent) =>
      bandColor(WarehouseCapacityBand.fromPercent(percent));

  /// Soft tint of [color] for icon wells and pill backgrounds.
  Color tint(Color color, [double alpha = 0.14]) =>
      color.withValues(alpha: isDark ? alpha : alpha * 0.9);

  // ── Accents ──────────────────────────────────────────────────────────────

  /// Distinct accents for the four summary metrics and the row actions, so
  /// each affordance carries its own identity instead of a wall of blue.
  Color get accentBlue => isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
  Color get accentIndigo => isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);
  Color get accentViolet => isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
  Color get accentTeal => isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
  Color get accentAmber => isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  Color get accentEmerald => isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
}
