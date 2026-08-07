import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/features/reports/presentation/cubit/reports_trends.dart';
import 'package:logisticsmobile/features/reports/presentation/widgets/reports_premium_theme.dart';
import 'package:logisticsmobile/widgets/wms/wms_pill_tab_bar.dart';

/// Reusable premium building blocks for the Reports & Analytics module.
///
/// Every atom is theme-aware, overflow-safe at 320dp and free of feature logic.

// ─────────────────────────────────────────────────────────────────────────────
// Surfaces
// ─────────────────────────────────────────────────────────────────────────────

/// Frosted-glass surface — gradient face, hairline ring, layered shadow.
class ReportsGlassCard extends StatelessWidget {
  const ReportsGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = ReportsPalette.radiusCard,
    this.borderTint,
    this.glowColor,
    this.onTap,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderTint;
  final Color? glowColor;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          if (elevated) ...palette.cardShadow,
          if (glowColor != null)
            ...palette.glow(glowColor!, opacity: 0.16, blur: 28, dy: 14),
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

/// Icon in a glowing, gradient-tinted well.
class ReportsGlowBadge extends StatelessWidget {
  const ReportsGlowBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.iconSize,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final radius = BorderRadius.circular(size * 0.32);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow:
            palette.glow(color, opacity: 0.28, blur: 16, dy: 6, spread: -4),
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

// ─────────────────────────────────────────────────────────────────────────────
// Hero banner
// ─────────────────────────────────────────────────────────────────────────────

/// Gradient analytics banner with a soft background mesh of colour blooms.
class ReportsHeroBanner extends StatelessWidget {
  const ReportsHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon = Icons.insights_rounded,
  });

  final String title;
  final String subtitle;

  /// Content docked under the title — typically the period selector.
  final Widget child;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(ReportsPalette.radiusHero),
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
                            style: WmsDesignTokens.sectionTitle(context).copyWith(
                              color: Colors.white,
                              fontSize: 21,
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
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft radial blooms that give the banner depth without an image asset.
class _HeroMeshPainter extends CustomPainter {
  const _HeroMeshPainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final blooms = <({Offset center, double radius, Color color})>[
      (
        center: Offset(size.width * 0.86, size.height * 0.12),
        radius: size.width * 0.42,
        color: colors[0],
      ),
      (
        center: Offset(size.width * 0.08, size.height * 0.92),
        radius: size.width * 0.38,
        color: colors[1],
      ),
      (
        center: Offset(size.width * 0.52, size.height * -0.18),
        radius: size.width * 0.36,
        color: colors[2],
      ),
    ];

    for (final bloom in blooms) {
      final rect = Rect.fromCircle(center: bloom.center, radius: bloom.radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            bloom.color.withValues(alpha: 0.38),
            bloom.color.withValues(alpha: 0.0),
          ],
        ).createShader(rect);
      canvas.drawCircle(bloom.center, bloom.radius, paint);
    }

    // Hairline sheen along the top edge.
    final sheen = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1.5));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 1.5), sheen);
  }

  @override
  bool shouldRepaint(covariant _HeroMeshPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

// ─────────────────────────────────────────────────────────────────────────────
// Reporting period selector
// ─────────────────────────────────────────────────────────────────────────────

/// One quick-filter option in [ReportsPeriodSelector].
class ReportsPeriodOption<T> {
  const ReportsPeriodOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final T value;
  final String label;
  final IconData icon;
}

/// Tactile reporting-period selector: a summary pill that expands into
/// quick-filter chips with a spring-eased reveal.
class ReportsPeriodSelector<T> extends StatefulWidget {
  const ReportsPeriodSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.rangeLabel,
  });

  final List<ReportsPeriodOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  /// Human-readable resolved range, e.g. `1/3/2026 – 31/3/2026`.
  final String rangeLabel;

  @override
  State<ReportsPeriodSelector<T>> createState() =>
      _ReportsPeriodSelectorState<T>();
}

class _ReportsPeriodSelectorState<T> extends State<ReportsPeriodSelector<T>> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final selectedOption = widget.options.firstWhere(
      (o) => o.value == widget.selected,
      orElse: () => widget.options.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(ReportsPalette.radiusControl + 4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                splashColor: Colors.white.withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedOption.icon,
                        color: Colors.white,
                        size: 17,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REPORTING PERIOD',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WmsDesignTokens.supportingDense(context)
                                  .copyWith(
                                color: Colors.white.withValues(alpha: 0.66),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.9,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${selectedOption.label} · ${widget.rangeLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WmsDesignTokens.body(context).copyWith(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm + 2,
                  0,
                  AppSpacing.sm + 2,
                  AppSpacing.sm + 2,
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final option in widget.options)
                      _PeriodChip(
                        label: option.label,
                        icon: option.icon,
                        selected: option.value == widget.selected,
                        onTap: () => widget.onSelected(option.value),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ReportsPalette.radiusPill);

    return AnimatedScale(
      scale: selected ? 1.0 : 0.98,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Material(
        color: selected
            ? Colors.white
            : Colors.white.withValues(alpha: 0.10),
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected ? const Color(0xFF1E1B4B) : Colors.white,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: selected ? const Color(0xFF1E1B4B) : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.15,
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

// ─────────────────────────────────────────────────────────────────────────────
// Notices
// ─────────────────────────────────────────────────────────────────────────────

/// Collapsible notification chip for permission / data-quality notices.
class ReportsNoticeChip extends StatefulWidget {
  const ReportsNoticeChip({
    super.key,
    required this.icon,
    required this.headline,
    required this.detail,
    required this.status,
    this.initiallyExpanded = false,
  });

  final IconData icon;

  /// Always-visible one-line summary.
  final String headline;

  /// Full text revealed on expand.
  final String detail;
  final ReportsStatus status;
  final bool initiallyExpanded;

  @override
  State<ReportsNoticeChip> createState() => _ReportsNoticeChipState();
}

class _ReportsNoticeChipState extends State<ReportsNoticeChip> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final accent = palette.status(widget.status);
    final radius = BorderRadius.circular(ReportsPalette.radiusControl);

    return Container(
      decoration: BoxDecoration(
        color: palette.tint(accent, 0.11),
        borderRadius: radius,
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(widget.icon, size: 16, color: accent),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          widget.headline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              WmsDesignTokens.supportingDense(context).copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.detail,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: palette.colors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        height: 1.45,
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

// ─────────────────────────────────────────────────────────────────────────────
// KPI bento tile
// ─────────────────────────────────────────────────────────────────────────────

/// Executive KPI tile — glowing duotone icon, large metric, and either a real
/// period-over-period trend or an explicit snapshot marker.
class ReportsKpiCard extends StatelessWidget {
  const ReportsKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.trend,
    this.caption,
    this.invertTrend = false,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final MetricTrend trend;

  /// Optional supporting line, e.g. the comparison window.
  final String? caption;

  /// True for metrics where an increase is bad (low stock, overdue).
  final bool invertTrend;
  final VoidCallback? onTap;

  /// Fixed row height for the bento grid — sized for a 1.2× text scale.
  static const double gridExtent = 148;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final colors = palette.colors;

    return ReportsGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      borderTint: accent,
      glowColor: accent,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ReportsGlowBadge(icon: icon, color: accent, size: 36),
              const Spacer(),
              if (trend.spark.isNotEmpty)
                ReportsSparkline(
                  values: trend.spark,
                  color: palette.trendColor(
                    trend.direction,
                    inverted: invertTrend,
                  ),
                ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: WmsDesignTokens.cardNumber(context).copyWith(
                color: colors.textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w700,
                height: 1.1,
                letterSpacing: -0.7,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.kpiLabel(context).copyWith(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          ReportsTrendChip(
            trend: trend,
            inverted: invertTrend,
            fallbackLabel: caption,
          ),
        ],
      ),
    );
  }
}

/// Compact delta chip. Renders an explicit "Snapshot" marker rather than a
/// fabricated percentage when no prior period exists.
class ReportsTrendChip extends StatelessWidget {
  const ReportsTrendChip({
    super.key,
    required this.trend,
    this.inverted = false,
    this.fallbackLabel,
  });

  final MetricTrend trend;
  final bool inverted;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final colors = palette.colors;

    final (IconData icon, Color color, String label) = switch (trend) {
      MetricTrend(comparable: false) => (
          Icons.circle_outlined,
          colors.textTertiary,
          fallbackLabel ?? 'Snapshot',
        ),
      MetricTrend(isNewActivity: true) => (
          Icons.fiber_new_rounded,
          palette.trendColor(TrendDirection.up, inverted: inverted),
          'New activity',
        ),
      MetricTrend(changeLabel: final String delta) => (
          switch (trend.direction) {
            TrendDirection.up => Icons.trending_up_rounded,
            TrendDirection.down => Icons.trending_down_rounded,
            TrendDirection.flat => Icons.trending_flat_rounded,
          },
          palette.trendColor(trend.direction, inverted: inverted),
          '$delta vs prev.',
        ),
      _ => (
          Icons.trending_flat_rounded,
          colors.textTertiary,
          fallbackLabel ?? 'No change',
        ),
    };

    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.supportingDense(context).copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tiny trend sparkline — gradient stroke with a soft area fill.
class ReportsSparkline extends StatelessWidget {
  const ReportsSparkline({
    super.key,
    required this.values,
    required this.color,
    this.size = const Size(52, 22),
  });

  final List<double> values;
  final Color color;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final normalized = ReportsTrends.normalize(values);
    if (normalized.length < 2) return SizedBox.fromSize(size: size);

    return SizedBox.fromSize(
      size: size,
      child: CustomPaint(
        painter: _SparklinePainter(values: normalized, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 2.0;
    final usableHeight = size.height - strokeWidth;
    final step = size.width / (values.length - 1);

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          i * step,
          strokeWidth / 2 + (1 - values[i]) * usableHeight,
        ),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      // Smooth with a midpoint quadratic so the line reads as a trend, not a
      // sawtooth, without overshooting the data the way a spline would.
      final previous = points[i - 1];
      final current = points[i];
      final mid = Offset(
        (previous.dx + current.dx) / 2,
        (previous.dy + current.dy) / 2,
      );
      path.quadraticBezierTo(previous.dx, previous.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.26),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(points.last, 2.6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.color != color || !listEquals(oldDelegate.values, values);

  static bool listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating pill tab bar
// ─────────────────────────────────────────────────────────────────────────────


/// Tab descriptor for [ReportsPillTabBar].
typedef ReportsTabSpec = WmsPillTabSpec;

/// Pill tab selector wearing the Reports palette.
///
/// The sliding-indicator mechanics live in the shared [WmsPillTabBar]; this
/// wrapper supplies only colours, so Reports and Administration cannot drift.
class ReportsPillTabBar extends StatelessWidget {
  const ReportsPillTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  final TabController controller;
  final List<ReportsTabSpec> tabs;

  static const double height = WmsPillTabBar.height;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);

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

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

/// Action offered alongside an empty state.
class ReportsEmptyAction {
  const ReportsEmptyAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;
}

/// High-end empty state — a drawn chart illustration, a clear explanation and
/// the actions that would actually populate the view.
class ReportsEmptyState extends StatelessWidget {
  const ReportsEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actions = const [],
  });

  final String title;
  final String message;
  final List<ReportsEmptyAction> actions;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final colors = palette.colors;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: ReportsGlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SizedBox(
                  width: 132,
                  height: 84,
                  child: CustomPaint(
                    painter: _EmptyChartPainter(
                      accent: palette.brand,
                      muted: colors.textTertiary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: WmsDesignTokens.sectionTitle(context).copyWith(
                  color: colors.textPrimary,
                  fontSize: 17,
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
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final action in actions)
                      _EmptyActionButton(action: action),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyActionButton extends StatelessWidget {
  const _EmptyActionButton({required this.action});

  final ReportsEmptyAction action;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final radius = BorderRadius.circular(ReportsPalette.radiusPill);
    final foreground =
        action.primary ? Colors.white : palette.colors.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: action.primary
            ? palette.glow(palette.brand,
                opacity: 0.32, blur: 14, dy: 5, spread: -4)
            : null,
      ),
      child: Material(
        color: action.primary ? Colors.transparent : palette.insetFill,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: action.primary ? palette.brandGradient : null,
            borderRadius: radius,
            border: action.primary ? null : palette.glassBorder(),
          ),
          child: InkWell(
            onTap: action.onPressed,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(action.icon, size: 15, color: foreground),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        height: 1.15,
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
  }
}

/// A stylised bar chart with a dashed baseline — the module's empty-state mark.
class _EmptyChartPainter extends CustomPainter {
  const _EmptyChartPainter({required this.accent, required this.muted});

  final Color accent;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    const heights = [0.35, 0.62, 0.44, 0.86, 0.55];
    const gap = 10.0;
    final barWidth = (size.width - gap * (heights.length - 1)) / heights.length;
    final baseline = size.height - 10;

    for (var i = 0; i < heights.length; i++) {
      final height = baseline * heights[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          i * (barWidth + gap),
          baseline - height,
          barWidth,
          height,
        ),
        const Radius.circular(4),
      );
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.42 - i * 0.05),
            accent.withValues(alpha: 0.10),
          ],
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, paint);
    }

    final dash = Paint()
      ..color = muted.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, baseline), Offset(x + 4, baseline), dash);
    }
  }

  @override
  bool shouldRepaint(covariant _EmptyChartPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.muted != muted;
}

// ─────────────────────────────────────────────────────────────────────────────
// Export format card
// ─────────────────────────────────────────────────────────────────────────────

/// Premium export-format card with a tactile press response.
class ReportsExportCard extends StatefulWidget {
  const ReportsExportCard({
    super.key,
    required this.title,
    required this.description,
    required this.specs,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String description;

  /// Short technical facts, e.g. `.xlsx · 4 sheets`.
  final List<String> specs;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<ReportsExportCard> createState() => _ReportsExportCardState();
}

class _ReportsExportCardState extends State<ReportsExportCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final colors = palette.colors;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ReportsPalette.radiusCard),
          boxShadow: _pressed
              ? palette.glow(widget.accent,
                  opacity: 0.26, blur: 18, dy: 6, spread: -6)
              : palette.cardShadow,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: palette.surfaceGradient,
            borderRadius: BorderRadius.circular(ReportsPalette.radiusCard),
            border: palette.glassBorder(tint: widget.accent),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              splashColor: widget.accent.withValues(alpha: 0.10),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md + 2),
                child: Row(
                  children: [
                    ReportsGlowBadge(
                      icon: widget.icon,
                      color: widget.accent,
                      size: 44,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WmsDesignTokens.cardTitle(context).copyWith(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: WmsDesignTokens.supportingDense(context)
                                .copyWith(
                              color: colors.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (final spec in widget.specs)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.insetFill,
                                    borderRadius: BorderRadius.circular(6),
                                    border: palette.glassBorder(),
                                  ),
                                  child: Text(
                                    spec,
                                    style: WmsDesignTokens.supportingDense(
                                      context,
                                    ).copyWith(
                                      color: colors.textTertiary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: widget.accent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section heading
// ─────────────────────────────────────────────────────────────────────────────

class ReportsSectionIntro extends StatelessWidget {
  const ReportsSectionIntro({
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
    final palette = ReportsPalette.of(context);
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
