import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/constants/wms/movement_constants.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';

/// The four stock operations, plus a neutral fallback.
///
/// The kind drives the accent colour, icon and badge of every surface that
/// represents a movement, so an inbound receipt looks the same in the bento
/// grid, the form header and the history feed.
enum StockOpsKind { inbound, outbound, transfer, returned, adjustment }

/// Presentation facts for a [StockOpsKind].
@immutable
class StockOpsKindSpec {
  const StockOpsKindSpec({
    required this.kind,
    required this.label,
    required this.icon,
  });

  final StockOpsKind kind;
  final String label;
  final IconData icon;
}

abstract final class StockOpsKinds {
  static const inbound = StockOpsKindSpec(
    kind: StockOpsKind.inbound,
    label: 'Inbound',
    icon: Icons.call_received_rounded,
  );
  static const outbound = StockOpsKindSpec(
    kind: StockOpsKind.outbound,
    label: 'Outbound',
    icon: Icons.call_made_rounded,
  );
  static const transfer = StockOpsKindSpec(
    kind: StockOpsKind.transfer,
    label: 'Transfer',
    icon: Icons.swap_horiz_rounded,
  );
  static const returned = StockOpsKindSpec(
    kind: StockOpsKind.returned,
    label: 'Return',
    icon: Icons.undo_rounded,
  );
  static const adjustment = StockOpsKindSpec(
    kind: StockOpsKind.adjustment,
    label: 'Adjustment',
    icon: Icons.tune_rounded,
  );

  /// Resolves a backend movement type onto a kind.
  static StockOpsKindSpec fromType(String type) {
    switch (type) {
      case WmsMovementTypes.inbound:
        return inbound;
      case WmsMovementTypes.outbound:
        return outbound;
      case WmsMovementTypes.transfer:
        return transfer;
      case WmsMovementTypes.returnType:
        return returned;
      default:
        return adjustment;
    }
  }
}

/// Premium visual language for the Stock Operations workspace.
///
/// Slate/midnight chrome, frosted glass containers, indigo brand gradients and
/// a reserved operation palette: emerald inbound, amber outbound, cobalt
/// transfer, violet return.
@immutable
class StockOpsPalette {
  const StockOpsPalette._(this.colors);

  factory StockOpsPalette.of(BuildContext context) =>
      StockOpsPalette._(WmsUiColors.of(context));

  final WmsUiColors colors;

  bool get isDark => colors.isDark;

  // ── Geometry ─────────────────────────────────────────────────────────────

  static const double radiusHero = 26;
  static const double radiusCard = 18;
  static const double radiusControl = 14;
  static const double radiusPill = 999;

  /// Fixed row height for the 2×2 bento grid, sized for a 1.3× text scale.
  static const double bentoExtent = 104;

  // ── Brand ────────────────────────────────────────────────────────────────

  LinearGradient get heroGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0B1120),
          Color(0xFF1E2A78),
          Color(0xFF3730A3),
        ],
        stops: [0.0, 0.55, 1.0],
      );

  List<Color> get heroMeshColors => const [
        Color(0xFF6366F1),
        Color(0xFF0EA5E9),
        Color(0xFF22D3EE),
      ];

  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF4F46E5), Color(0xFF0284C7)]
            : const [Color(0xFF4338CA), Color(0xFF0369A1)],
      );

  Color get brand => isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA);

  LinearGradient get pageGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF101A2E), colors.background, colors.background]
            : [const Color(0xFFEEF2FF), colors.background, colors.background],
        stops: const [0.0, 0.26, 1.0],
      );

  // ── Glass surfaces ───────────────────────────────────────────────────────

  LinearGradient get surfaceGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF161F32), Color(0xFF111828)]
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

  // ── Elevation ────────────────────────────────────────────────────────────

  List<BoxShadow> get cardShadow {
    final base = isDark ? Colors.black : const Color(0xFF1E293B);
    return [
      BoxShadow(
        color: base.withValues(alpha: isDark ? 0.32 : 0.04),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: base.withValues(alpha: isDark ? 0.26 : 0.055),
        blurRadius: 14,
        offset: const Offset(0, 5),
        spreadRadius: -4,
      ),
      BoxShadow(
        color: base.withValues(alpha: isDark ? 0.22 : 0.045),
        blurRadius: 30,
        offset: const Offset(0, 14),
        spreadRadius: -10,
      ),
    ];
  }

  List<BoxShadow> glow(
    Color color, {
    double opacity = 0.30,
    double blur = 18,
    double dy = 7,
    double spread = -5,
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

  // ── Operation palette ────────────────────────────────────────────────────

  Color get emerald => isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
  Color get amber => isDark ? const Color(0xFFFBBF24) : const Color(0xFFC2410C);
  Color get cobalt => isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
  Color get violet => isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
  Color get coral => isDark ? const Color(0xFFFB7185) : const Color(0xFFDC2626);
  Color get slate => isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

  /// Accent for an operation kind — the single source of colour for a movement.
  Color accentFor(StockOpsKind kind) => switch (kind) {
        StockOpsKind.inbound => emerald,
        StockOpsKind.outbound => amber,
        StockOpsKind.transfer => cobalt,
        StockOpsKind.returned => violet,
        StockOpsKind.adjustment => slate,
      };

  Color accentForType(String type) =>
      accentFor(StockOpsKinds.fromType(type).kind);

  /// Severity ramp for the alerts feed.
  Color get severityCritical => coral;
  Color get severityWarning => amber;
  Color get severityInfo => cobalt;
}
