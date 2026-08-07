import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';

/// Status semantics used across the Administration console.
///
/// Reserved: a status colour always means the same thing, and is never reused
/// as decoration for an unrelated chip.
enum AdminStatus {
  /// Active users, healthy capacity, verified accounts.
  active,

  /// Supervisors, warnings, capacity pressure.
  warning,

  /// Unread alerts, suspended accounts, destructive events.
  critical,

  /// Admin-role identity and system-level activity.
  admin,

  /// Neutral / archived / not-assigned.
  neutral,
}

/// Access tiers recognised by the console.
enum AdminRoleTier { admin, supervisor, staff, unknown }

abstract final class AdminRoles {
  /// Normalises free-text role strings from the directory onto a tier.
  static AdminRoleTier tierOf(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized.contains('admin')) return AdminRoleTier.admin;
    if (normalized.contains('supervisor') || normalized.contains('manager')) {
      return AdminRoleTier.supervisor;
    }
    if (normalized.contains('staff') ||
        normalized.contains('operator') ||
        normalized.contains('picker')) {
      return AdminRoleTier.staff;
    }
    return AdminRoleTier.unknown;
  }

  static IconData iconFor(AdminRoleTier tier) => switch (tier) {
        AdminRoleTier.admin => Icons.admin_panel_settings_rounded,
        AdminRoleTier.supervisor => Icons.supervisor_account_rounded,
        AdminRoleTier.staff => Icons.engineering_rounded,
        AdminRoleTier.unknown => Icons.person_rounded,
      };
}

/// Premium visual language for the Administration Center.
///
/// Deep indigo/midnight chrome, frosted glass cards, slate accents, and a
/// reserved status palette: emerald for active, amber for supervisor and
/// warning states, coral for unread and error states, violet for admin.
@immutable
class AdminPalette {
  const AdminPalette._(this.colors);

  factory AdminPalette.of(BuildContext context) =>
      AdminPalette._(WmsUiColors.of(context));

  final WmsUiColors colors;

  bool get isDark => colors.isDark;

  // ── Geometry ─────────────────────────────────────────────────────────────

  static const double radiusHero = 28;
  static const double radiusCard = 20;
  static const double radiusControl = 14;
  static const double radiusPill = 999;

  /// Fixed row height for the bento metric grid, sized for a 1.2× text scale.
  static const double bentoExtent = 132;

  // ── Brand ────────────────────────────────────────────────────────────────

  /// Midnight → deep indigo → cobalt. The console's header banner.
  LinearGradient get heroGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0B1120),
          Color(0xFF1E1B78),
          Color(0xFF3730A3),
        ],
        stops: [0.0, 0.52, 1.0],
      );

  /// Blooms painted behind the banner content.
  List<Color> get heroMeshColors => const [
        Color(0xFF6366F1),
        Color(0xFF0EA5E9),
        Color(0xFFA855F7),
      ];

  /// Indigo → cobalt for active pills, primary actions and identity tiles.
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
        stops: const [0.0, 0.28, 1.0],
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
        blurRadius: 15,
        offset: const Offset(0, 5),
        spreadRadius: -4,
      ),
      BoxShadow(
        color: base.withValues(alpha: isDark ? 0.22 : 0.045),
        blurRadius: 32,
        offset: const Offset(0, 15),
        spreadRadius: -10,
      ),
    ];
  }

  List<BoxShadow> glow(
    Color color, {
    double opacity = 0.30,
    double blur = 20,
    double dy = 8,
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

  // ── Status palette ───────────────────────────────────────────────────────

  Color get emerald => isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
  Color get amber => isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  Color get coral => isDark ? const Color(0xFFFB7185) : const Color(0xFFDC2626);
  Color get violet => isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
  Color get cobalt => isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
  Color get slate => isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

  Color status(AdminStatus status) => switch (status) {
        AdminStatus.active => emerald,
        AdminStatus.warning => amber,
        AdminStatus.critical => coral,
        AdminStatus.admin => violet,
        AdminStatus.neutral => slate,
      };

  /// Identity colour for a role tier — violet marks elevated privilege,
  /// amber marks supervisory scope, cobalt marks operational staff.
  Color roleColor(AdminRoleTier tier) => switch (tier) {
        AdminRoleTier.admin => violet,
        AdminRoleTier.supervisor => amber,
        AdminRoleTier.staff => cobalt,
        AdminRoleTier.unknown => slate,
      };

  /// Capacity ramp for warehouse fill levels.
  Color capacityColor(int percent) {
    if (percent >= 90) return coral;
    if (percent >= 70) return amber;
    if (percent >= 40) return brand;
    return emerald;
  }
}
