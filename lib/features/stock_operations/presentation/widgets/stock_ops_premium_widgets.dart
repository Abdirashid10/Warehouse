import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/widgets/stock_ops_premium_theme.dart';

/// Premium surfaces for the Stock Operations workspace: the executive banner
/// and bento grid, the history timeline, and the categorised alerts feed.
///
/// Every widget here is theme-aware, overflow-safe at 320dp and free of
/// feature logic.

// ═══════════════════════════════════════════════════════════════════════════
// Shared surfaces
// ═══════════════════════════════════════════════════════════════════════════

/// Frosted-glass card with an optional colour-coded leading strip.
class StockOpsGlassCard extends StatelessWidget {
  const StockOpsGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md + 2),
    this.radius = StockOpsPalette.radiusCard,
    this.accentStrip,
    this.onTap,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? accentStrip;
  final VoidCallback? onTap;
  final bool elevated;

  static const double stripWidth = 3.5;

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: elevated ? palette.cardShadow : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: palette.surfaceGradient,
          borderRadius: borderRadius,
          border: palette.glassBorder(tint: accentStrip),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: (accentStrip ?? palette.brand).withValues(alpha: 0.08),
            // Positioned rather than stretched: a stretched flex child would
            // demand a bounded height, which a card in a scroll view lacks.
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
class StockOpsIconWell extends StatelessWidget {
  const StockOpsIconWell({
    super.key,
    required this.icon,
    required this.color,
    this.size = 36,
    this.onDarkSurface = false,
  });

  final IconData icon;
  final Color color;
  final double size;

  /// Tunes the well for the indigo hero banner, where the surrounding surface
  /// is already dark regardless of the app theme.
  final bool onDarkSurface;

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);
    final radius = BorderRadius.circular(size * 0.32);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: onDarkSurface
            ? null
            : palette.glow(color, opacity: 0.26, blur: 14, dy: 5, spread: -4),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: onDarkSurface || palette.isDark ? 0.32 : 0.20),
              color.withValues(alpha: onDarkSurface || palette.isDark ? 0.14 : 0.08),
            ],
          ),
          borderRadius: radius,
          border: Border.all(color: color.withValues(alpha: 0.28)),
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

/// Compact tonal pill — the workspace's badge vocabulary.
class StockOpsTonePill extends StatelessWidget {
  const StockOpsTonePill({
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
    final palette = StockOpsPalette.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 9,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: palette.tint(color, 0.14),
        borderRadius: BorderRadius.circular(StockOpsPalette.radiusPill),
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

// ═══════════════════════════════════════════════════════════════════════════
// Filters
// ═══════════════════════════════════════════════════════════════════════════

/// Recessed search field with a vector prefix and a one-tap clear.
class StockOpsSearchField extends StatelessWidget {
  const StockOpsSearchField({
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
    final palette = StockOpsPalette.of(context);
    final colors = palette.colors;

    return Container(
      decoration: BoxDecoration(
        color: palette.insetFill,
        borderRadius: BorderRadius.circular(StockOpsPalette.radiusControl),
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
class StockOpsFilterPill extends StatelessWidget {
  const StockOpsFilterPill({
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
  final Color? accent;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);
    final colors = palette.colors;
    final radius = BorderRadius.circular(StockOpsPalette.radiusPill);
    final foreground = selected ? Colors.white : colors.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: selected
            ? palette.glow(accent ?? palette.brand,
                opacity: 0.30, blur: 12, dy: 4, spread: -3)
            : null,
      ),
      child: Material(
        color: selected ? Colors.transparent : palette.insetFill,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: accent == null
                        ? [
                            palette.brandGradient.colors.first,
                            palette.brandGradient.colors.last,
                          ]
                        : [accent!, accent!.withValues(alpha: 0.72)],
                  )
                : null,
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
                        borderRadius: radius,
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

// ═══════════════════════════════════════════════════════════════════════════
// Executive header + bento grid
// ═══════════════════════════════════════════════════════════════════════════

/// One tile of the operations bento grid.
class StockOpsBentoMetric {
  const StockOpsBentoMetric({
    required this.label,
    required this.value,
    required this.spec,
    required this.accent,
  });

  final String label;
  final String value;
  final StockOpsKindSpec spec;
  final Color accent;
}

/// Indigo operations banner carrying the 2×2 metric bento.
class StockOpsHeroBanner extends StatelessWidget {
  const StockOpsHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.metrics,
  });

  final String title;
  final String subtitle;
  final List<StockOpsBentoMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(StockOpsPalette.radiusHero),
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
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.sync_alt_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
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
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
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
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                StockOpsBentoGrid(metrics: metrics),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 2×2 frosted metric grid. Widens to a single row when the box is wide
/// enough to keep each tile legible.
class StockOpsBentoGrid extends StatelessWidget {
  const StockOpsBentoGrid({super.key, required this.metrics});

  final List<StockOpsBentoMetric> metrics;

  /// Minimum box width before the grid unfolds into one row.
  ///
  /// Measured from the grid's own constraints, not the window: the banner pads
  /// this widget, and on a tablet in a split pane the screen can be wide while
  /// this box is not.
  static const double _singleRowBreakpoint = 620;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= _singleRowBreakpoint ? 4 : 2;

        return GridView.builder(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.sm + 2,
            crossAxisSpacing: AppSpacing.sm + 2,
            mainAxisExtent: StockOpsPalette.bentoExtent,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) => _BentoTile(metric: metrics[index]),
        );
      },
    );
  }
}

class _BentoTile extends StatelessWidget {
  const _BentoTile({required this.metric});

  final StockOpsBentoMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        // Frosted glass over the indigo banner: a translucent white face with
        // a hairline rim, rather than an opaque card that would punch a hole
        // in the gradient.
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(StockOpsPalette.radiusCard),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StockOpsIconWell(
            icon: metric.spec.icon,
            color: metric.accent,
            size: 30,
            onDarkSurface: true,
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              maxLines: 1,
              style: WmsDesignTokens.cardNumber(context).copyWith(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                height: 1.1,
                letterSpacing: -0.6,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.supportingDense(context).copyWith(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
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
        center: Offset(size.width * 0.90, size.height * 0.08),
        radius: size.width * 0.42,
        color: colors[0],
      ),
      (
        center: Offset(size.width * 0.04, size.height * 0.96),
        radius: size.width * 0.36,
        color: colors[1],
      ),
      (
        center: Offset(size.width * 0.52, size.height * -0.18),
        radius: size.width * 0.32,
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
              bloom.color.withValues(alpha: 0.34),
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

// ═══════════════════════════════════════════════════════════════════════════
// History timeline
// ═══════════════════════════════════════════════════════════════════════════

/// A movement rendered as a timeline card: status badge, route and quantity.
class StockOpsHistoryCard extends StatelessWidget {
  const StockOpsHistoryCard({
    super.key,
    required this.movement,
    this.onTap,
  });

  final StockMovement movement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);
    final colors = palette.colors;
    final spec = StockOpsKinds.fromType(movement.type);
    final accent = palette.accentFor(spec.kind);

    final from = movement.fromLocation?.trim() ?? '';
    final to = movement.toLocation?.trim() ?? '';
    final hasRoute = from.isNotEmpty || to.isNotEmpty;

    return StockOpsGlassCard(
      accentStrip: accent,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StockOpsIconWell(icon: spec.icon, color: accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.cardTitle(context).copyWith(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      movement.sku,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: colors.textTertiary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _QuantityPill(quantity: movement.quantity, accent: accent),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Row(
            children: [
              StockOpsTonePill(
                label: spec.label,
                color: accent,
                icon: spec.icon,
                dense: true,
              ),
              if (hasRoute) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: StockOpsRouteChip(
                    origin: from.isEmpty ? '—' : from,
                    destination: to.isEmpty ? '—' : to,
                    accent: accent,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Divider(height: 1, thickness: 1, color: palette.hairline),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 12,
                color: colors.textTertiary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  movement.performedBy.isEmpty ? 'System' : movement.performedBy,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.schedule_rounded,
                size: 12,
                color: colors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                movement.timestamp == null
                    ? 'No timestamp'
                    : WmsFormatters.relativeTime(movement.timestamp),
                maxLines: 1,
                style: WmsDesignTokens.supportingDense(context).copyWith(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `Madiina → Bakaaro` route indicator.
class StockOpsRouteChip extends StatelessWidget {
  const StockOpsRouteChip({
    super.key,
    required this.origin,
    required this.destination,
    required this.accent,
  });

  final String origin;
  final String destination;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);
    final style = WmsDesignTokens.supportingDense(context).copyWith(
      color: palette.colors.textPrimary,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.insetFill,
        borderRadius: BorderRadius.circular(StockOpsPalette.radiusPill),
        border: palette.glassBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              origin,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Icon(Icons.arrow_forward_rounded, size: 11, color: accent),
          ),
          Flexible(
            child: Text(
              destination,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityPill extends StatelessWidget {
  const _QuantityPill({required this.quantity, required this.accent});

  final num quantity;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: palette.isDark ? 0.26 : 0.16),
            accent.withValues(alpha: palette.isDark ? 0.12 : 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(StockOpsPalette.radiusPill),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Text(
        WmsFormatters.quantity(quantity),
        maxLines: 1,
        style: WmsDesignTokens.cardNumber(context).copyWith(
          color: accent,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.15,
          letterSpacing: -0.2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Alerts feed
// ═══════════════════════════════════════════════════════════════════════════

/// Severity of an alerts category.
enum StockAlertSeverity { critical, warning, info }

/// One line inside a [StockOpsAlertSection].
class StockOpsAlertEntry {
  const StockOpsAlertEntry({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;

  /// Right-aligned value, e.g. remaining quantity.
  final String? trailing;
}

/// A categorised alert group: header, count badge, and divided rows.
class StockOpsAlertSection extends StatelessWidget {
  const StockOpsAlertSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.severity,
    required this.entries,
    this.emptyMessage,
    this.maxEntries = 8,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final StockAlertSeverity severity;
  final List<StockOpsAlertEntry> entries;

  /// Shown in place of rows when [entries] is empty.
  final String? emptyMessage;

  /// Rows rendered before the list is summarised with a "+n more" footer.
  final int maxEntries;

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);
    final colors = palette.colors;

    final accent = switch (severity) {
      StockAlertSeverity.critical => palette.severityCritical,
      StockAlertSeverity.warning => palette.severityWarning,
      StockAlertSeverity.info => palette.severityInfo,
    };

    final visible = entries.take(maxEntries).toList();
    final overflowCount = entries.length - visible.length;

    return StockOpsGlassCard(
      accentStrip: entries.isEmpty ? null : accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StockOpsIconWell(icon: icon, color: accent, size: 34),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.cardTitle(context).copyWith(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: colors.textTertiary,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StockOpsTonePill(
                label: '${entries.length}',
                color: entries.isEmpty ? palette.slate : accent,
              ),
            ],
          ),
          if (visible.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 14,
                  color: palette.emerald,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    emptyMessage ?? 'Nothing needs attention here.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: colors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm + 2),
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: palette.hairline),
              _AlertRow(entry: visible[i], accent: accent),
            ],
            if (overflowCount > 0) ...[
              Divider(height: 1, thickness: 1, color: palette.hairline),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  '+$overflowCount more',
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.textTertiary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.entry, required this.accent});

  final StockOpsAlertEntry entry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);
    final colors = palette.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                if (entry.subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    entry.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: colors.textTertiary,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (entry.trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              entry.trailing!,
              maxLines: 1,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.3,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section heading & empty state
// ═══════════════════════════════════════════════════════════════════════════

class StockOpsSectionIntro extends StatelessWidget {
  const StockOpsSectionIntro({
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
    final palette = StockOpsPalette.of(context);
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
                  fontSize: 17,
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

/// Enterprise empty state with a duotone mark.
class StockOpsEmptyState extends StatelessWidget {
  const StockOpsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);
    final colors = palette.colors;

    return StockOpsGlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: 72,
              height: 72,
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.tint(palette.brand, 0.12),
                      border: Border.all(
                        color: palette.brand.withValues(alpha: 0.24),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 24, color: palette.brand),
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
              fontSize: 16,
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
        ],
      ),
    );
  }
}
