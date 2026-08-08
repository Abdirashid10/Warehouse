import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';

/// Security semantics for an audit entry.
///
/// The kind drives the accent strip, the icon well and the badge on every log
/// card, so one action always looks the same wherever it is rendered.
enum AuditActionKind {
  /// Stock moved between locations.
  transfer,

  /// Goods received / inbound.
  receive,

  /// Goods dispatched / outbound.
  dispatch,

  /// A record was created.
  create,

  /// A record was modified.
  update,

  /// A record was removed — always destructive.
  delete,

  /// Task lifecycle events.
  task,

  /// Authentication and permission events.
  security,

  /// Platform / configuration events.
  system,
}

/// Presentation facts for an [AuditActionKind].
@immutable
class AuditActionSpec {
  const AuditActionSpec({
    required this.kind,
    required this.label,
    required this.icon,
  });

  final AuditActionKind kind;

  /// Short badge label, e.g. `Transfer`.
  final String label;
  final IconData icon;
}

/// Maps free-text audit actions onto the security taxonomy.
///
/// The backend emits human-written action strings (`Stock transferred`,
/// `USER_LOGIN`, `Deleted product`), so classification is keyword-based and
/// deliberately ordered: destructive and security wording wins over generic
/// verbs, because mislabelling a delete as an update would understate it.
abstract final class AuditActionClassifier {
  static const _fallback = AuditActionSpec(
    kind: AuditActionKind.system,
    label: 'Event',
    icon: Icons.bolt_rounded,
  );

  static AuditActionSpec classify(String action, [String module = '']) {
    final text = '$action $module'.toLowerCase();

    bool has(List<String> keywords) =>
        keywords.any((keyword) => text.contains(keyword));

    if (has(['delete', 'remove', 'destroy', 'archiv', 'revoke', 'cancel'])) {
      return const AuditActionSpec(
        kind: AuditActionKind.delete,
        label: 'Delete',
        icon: Icons.delete_outline_rounded,
      );
    }
    if (has(['login', 'logout', 'sign in', 'sign out', 'auth', 'password',
        'permission', 'role', 'access'])) {
      return const AuditActionSpec(
        kind: AuditActionKind.security,
        label: 'Security',
        icon: Icons.shield_outlined,
      );
    }
    if (has(['transfer', 'move', 'relocat'])) {
      return const AuditActionSpec(
        kind: AuditActionKind.transfer,
        label: 'Transfer',
        icon: Icons.swap_horiz_rounded,
      );
    }
    if (has(['receive', 'inbound', 'restock', 'intake', 'goods in'])) {
      return const AuditActionSpec(
        kind: AuditActionKind.receive,
        label: 'Receive',
        icon: Icons.call_received_rounded,
      );
    }
    if (has(['dispatch', 'outbound', 'ship', 'deliver', 'pick', 'pack'])) {
      return const AuditActionSpec(
        kind: AuditActionKind.dispatch,
        label: 'Dispatch',
        icon: Icons.local_shipping_outlined,
      );
    }
    if (has(['task', 'assign'])) {
      return const AuditActionSpec(
        kind: AuditActionKind.task,
        label: 'Task',
        icon: Icons.task_alt_rounded,
      );
    }
    if (has(['create', 'add', 'new', 'register'])) {
      return const AuditActionSpec(
        kind: AuditActionKind.create,
        label: 'Create',
        icon: Icons.add_circle_outline_rounded,
      );
    }
    if (has(['update', 'edit', 'adjust', 'modif', 'change', 'stock',
        'inventory', 'count'])) {
      return const AuditActionSpec(
        kind: AuditActionKind.update,
        label: 'Update',
        icon: Icons.edit_note_rounded,
      );
    }
    return _fallback;
  }
}

/// A `from X to Y` route parsed out of an audit detail line.
@immutable
class AuditRoute {
  const AuditRoute({required this.origin, required this.destination});

  final String origin;
  final String destination;
}

/// Detail text split into an optional route and the remaining prose.
@immutable
class AuditDetail {
  const AuditDetail({required this.text, this.route});

  final String text;
  final AuditRoute? route;

  static final _routePattern = RegExp(
    r'\bfrom\s+(.+?)\s+(?:to|→|->)\s+([^.,;]+)',
    caseSensitive: false,
  );

  /// Extracts an origin→destination pair when the detail describes one.
  ///
  /// Only a genuine match produces a route chip; anything else renders as
  /// plain prose rather than being force-fitted into a route layout.
  factory AuditDetail.parse(String details) {
    final trimmed = details.trim();
    if (trimmed.isEmpty) return const AuditDetail(text: '');

    final match = _routePattern.firstMatch(trimmed);
    if (match == null) return AuditDetail(text: trimmed);

    final origin = match.group(1)?.trim() ?? '';
    final destination = match.group(2)?.trim() ?? '';
    if (origin.isEmpty || destination.isEmpty) {
      return AuditDetail(text: trimmed);
    }

    final remainder = trimmed.replaceRange(match.start, match.end, '').trim();
    return AuditDetail(
      text: remainder.replaceAll(RegExp(r'\s{2,}'), ' '),
      route: AuditRoute(origin: origin, destination: destination),
    );
  }
}

/// Premium visual language for the Audit Logs activity stream.
///
/// Deep slate chrome, frosted glass cards, indigo/cobalt brand gradients and a
/// reserved security palette: emerald for success, amber for transfers and
/// warnings, coral for destructive events, violet for system activity.
@immutable
class AuditPalette {
  const AuditPalette._(this.colors);

  factory AuditPalette.of(BuildContext context) =>
      AuditPalette._(WmsUiColors.of(context));

  final WmsUiColors colors;

  bool get isDark => colors.isDark;

  // ── Geometry ─────────────────────────────────────────────────────────────

  static const double radiusCard = 18;
  static const double radiusControl = 14;
  static const double radiusPill = 999;

  /// Width of the colour-coded strip on a log card.
  static const double accentStripWidth = 3.5;

  /// Width of the timeline gutter to the left of each card.
  static const double railWidth = 26;

  // ── Brand ────────────────────────────────────────────────────────────────

  /// Indigo → cobalt. Active filters, the security badge, primary actions.
  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF4F46E5), Color(0xFF0284C7)]
            : const [Color(0xFF4338CA), Color(0xFF0369A1)],
      );

  Color get brand => isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA);

  /// Ambient page wash — midnight at the top, fading into the app background.
  LinearGradient get pageGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF10182B), colors.background, colors.background]
            : [const Color(0xFFEEF2FF), colors.background, colors.background],
        stops: const [0.0, 0.3, 1.0],
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

  /// Soft inset ring used on the search field, so it reads as a recessed slot
  /// rather than another raised card.
  List<BoxShadow> get innerWellShadow => [
        BoxShadow(
          color: (isDark ? Colors.black : const Color(0xFF0F172A))
              .withValues(alpha: isDark ? 0.30 : 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: -4,
        ),
      ];

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

  // ── Security palette ─────────────────────────────────────────────────────

  Color get emerald => isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
  Color get amber => isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  Color get coral => isDark ? const Color(0xFFFB7185) : const Color(0xFFDC2626);
  Color get violet => isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
  Color get cobalt => isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
  Color get slate => isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

  /// Accent for an audit kind — the single source of colour for a log entry.
  Color accentFor(AuditActionKind kind) => switch (kind) {
        AuditActionKind.transfer => amber,
        AuditActionKind.receive => emerald,
        AuditActionKind.dispatch => cobalt,
        AuditActionKind.create => emerald,
        AuditActionKind.update => brand,
        AuditActionKind.delete => coral,
        AuditActionKind.task => violet,
        AuditActionKind.security => violet,
        AuditActionKind.system => slate,
      };

  // ── Typography ───────────────────────────────────────────────────────────

  /// Monospace face for timestamps and reference ids — fixed advance keeps a
  /// column of stamps optically aligned down the stream.
  TextStyle mono({
    required Color color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w500,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.robotoMono(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: 1.2,
      );
}
