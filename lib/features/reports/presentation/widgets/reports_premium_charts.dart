import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/features/reports/presentation/widgets/reports_premium_atoms.dart';
import 'package:logisticsmobile/features/reports/presentation/widgets/reports_premium_theme.dart';

/// Chart vocabulary for the Reports module.
///
/// Three forms, each matched to the job the data does:
///
/// * [ReportsRankedBars] — magnitude across named categories. Horizontal, so
///   long warehouse names read left-to-right instead of being rotated.
/// * [ReportsDonutChart] — composition of a whole (status mix, role split).
/// * [ReportsTrendLine] — change over time.
///
/// Every form ships a labelled legend or inline values. That is not decoration:
/// the validated categorical palette carries one adjacent pair in the 6–8 ΔE
/// CVD band, which is only legal alongside a non-colour encoding.

/// One labelled quantity in a chart.
class ReportsDatum {
  const ReportsDatum({required this.label, required this.value});

  final String label;
  final double value;
}

abstract final class ReportsSeries {
  /// Sorts descending, keeps the top [max] identities and folds the remainder
  /// into a single explicit "Other" bucket.
  ///
  /// A cycled 6th hue would imply an identity the palette cannot distinguish,
  /// so the overflow is named instead of coloured.
  static List<ReportsDatum> fold(
    Iterable<MapEntry<String, double>> entries, {
    int max = ReportsPalette.maxSeries,
  }) {
    final sorted = entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.length <= max) {
      return [
        for (final e in sorted) ReportsDatum(label: e.key, value: e.value),
      ];
    }

    final kept = sorted.take(max - 1);
    final rest = sorted.skip(max - 1);
    final otherTotal = rest.fold<double>(0, (sum, e) => sum + e.value);

    return [
      for (final e in kept) ReportsDatum(label: e.key, value: e.value),
      ReportsDatum(label: 'Other (${rest.length})', value: otherTotal),
    ];
  }

  /// Compact numeric label — `1.2k` past a thousand, plain integers below.
  static String compact(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000) {
      final scaled = value / 1000;
      return '${scaled.toStringAsFixed(scaled.abs() >= 10 ? 0 : 1)}k';
    }
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart card
// ─────────────────────────────────────────────────────────────────────────────

/// Frosted card that frames a chart with its title and an optional caption.
class ReportsChartCard extends StatelessWidget {
  const ReportsChartCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.accent,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final colors = palette.colors;
    final tint = accent ?? palette.brand;

    return ReportsGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                ReportsGlowBadge(icon: icon!, color: tint, size: 32),
                const SizedBox(width: AppSpacing.sm + 2),
              ],
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            WmsDesignTokens.supportingDense(context).copyWith(
                          color: colors.textTertiary,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ranked horizontal bars
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontal ranked bars with rounded caps and inline values.
///
/// Built from widgets rather than a plotting library: on a phone the label
/// belongs beside the bar, and this keeps the cap radius, the 2px inter-bar
/// gap and the entry animation under direct control.
class ReportsRankedBars extends StatelessWidget {
  const ReportsRankedBars({
    super.key,
    required this.data,
    this.valueSuffix,
    this.maxValueOverride,
    this.animate = true,
  });

  final List<ReportsDatum> data;

  /// Appended to each value label, e.g. `%`.
  final String? valueSuffix;

  /// Fixes the scale (e.g. 100 for percentages) instead of using the max datum.
  final double? maxValueOverride;
  final bool animate;

  static const double _barHeight = 10;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final colors = palette.colors;

    if (data.isEmpty) return const ReportsChartPlaceholder();

    final maxValue = maxValueOverride ??
        data.fold<double>(0, (m, d) => math.max(m, d.value));
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < data.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: palette.seriesColor(i),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      data[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${ReportsSeries.compact(data[i].value)}${valueSuffix ?? ''}',
                    maxLines: 1,
                    style: WmsDesignTokens.cardNumber(context).copyWith(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _BarTrack(
                fraction: (data[i].value / safeMax).clamp(0.0, 1.0),
                color: palette.seriesColor(i),
                animate: animate,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BarTrack extends StatelessWidget {
  const _BarTrack({
    required this.fraction,
    required this.color,
    required this.animate,
  });

  final double fraction;
  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);

    return SizedBox(
      height: ReportsRankedBars._barHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: palette.insetFill,
                  borderRadius:
                      BorderRadius.circular(ReportsRankedBars._barHeight / 2),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: animate ? 0 : fraction,
                  end: fraction,
                ),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  if (value <= 0) return const SizedBox.shrink();
                  final width = math.min(
                    maxWidth,
                    math.max(ReportsRankedBars._barHeight, maxWidth * value),
                  );
                  return Container(
                    width: width,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.75), color],
                      ),
                      borderRadius: BorderRadius.circular(
                        ReportsRankedBars._barHeight / 2,
                      ),
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
// Donut
// ─────────────────────────────────────────────────────────────────────────────

/// Donut with an interactive legend and a live centre readout.
///
/// Tapping a legend row or a segment selects it: the segment lifts, and the
/// centre switches from the total to that slice's label, value and share.
class ReportsDonutChart extends StatefulWidget {
  const ReportsDonutChart({
    super.key,
    required this.data,
    required this.centerLabel,
    this.valueSuffix,
  });

  final List<ReportsDatum> data;

  /// Caption under the centre total, e.g. `orders`.
  final String centerLabel;
  final String? valueSuffix;

  @override
  State<ReportsDonutChart> createState() => _ReportsDonutChartState();
}

class _ReportsDonutChartState extends State<ReportsDonutChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final colors = palette.colors;
    final data = widget.data;

    if (data.isEmpty) return const ReportsChartPlaceholder();

    final total = data.fold<double>(0, (sum, d) => sum + d.value);
    final selected = _selected;
    final headlineValue =
        selected == null ? total : data[selected].value;
    final headlineLabel =
        selected == null ? widget.centerLabel : data[selected].label;
    final share = total <= 0 || selected == null
        ? null
        : (data[selected].value / total) * 100;

    return Column(
      children: [
        SizedBox(
          height: 176,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  // A 2px surface gap keeps adjacent slices from bleeding into
                  // one another for readers who can't separate the hues.
                  sectionsSpace: 2,
                  centerSpaceRadius: 52,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions) return;
                      final index =
                          response?.touchedSection?.touchedSectionIndex;
                      setState(() {
                        _selected =
                            (index == null || index < 0 || index == _selected)
                                ? null
                                : index;
                      });
                    },
                  ),
                  sections: [
                    for (var i = 0; i < data.length; i++)
                      PieChartSectionData(
                        value: data[i].value,
                        color: palette.seriesColor(i),
                        radius: _selected == i ? 30 : 24,
                        showTitle: false,
                        borderSide: BorderSide(
                          color: palette.chartSurface,
                          width: _selected == i ? 2 : 0,
                        ),
                      ),
                  ],
                ),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ReportsSeries.compact(headlineValue) +
                        (widget.valueSuffix ?? ''),
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
                  const SizedBox(height: 2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 88),
                    child: Text(
                      share == null
                          ? headlineLabel
                          : '$headlineLabel · ${share.toStringAsFixed(0)}%',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: colors.textTertiary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ReportsChartLegend(
          data: data,
          total: total,
          selected: _selected,
          onSelect: (index) => setState(
            () => _selected = _selected == index ? null : index,
          ),
        ),
      ],
    );
  }
}

/// Interactive legend — the non-colour encoding every chart here relies on.
class ReportsChartLegend extends StatelessWidget {
  const ReportsChartLegend({
    super.key,
    required this.data,
    required this.total,
    this.selected,
    this.onSelect,
  });

  final List<ReportsDatum> data;
  final double total;
  final int? selected;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final colors = palette.colors;

    return Column(
      children: [
        for (var i = 0; i < data.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
            child: Material(
              color: selected == i ? palette.insetFill : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onSelect == null ? null : () => onSelect!(i),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: palette.seriesColor(i),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              WmsDesignTokens.supportingDense(context).copyWith(
                            color: selected == i
                                ? colors.textPrimary
                                : colors.textSecondary,
                            fontSize: 12,
                            fontWeight:
                                selected == i ? FontWeight.w700 : FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        ReportsSeries.compact(data[i].value),
                        maxLines: 1,
                        style: WmsDesignTokens.cardNumber(context).copyWith(
                          color: colors.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (total > 0) ...[
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 38,
                          child: Text(
                            '${((data[i].value / total) * 100).toStringAsFixed(0)}%',
                            maxLines: 1,
                            textAlign: TextAlign.end,
                            style: WmsDesignTokens.supportingDense(context)
                                .copyWith(
                              color: colors.textTertiary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
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
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trend line
// ─────────────────────────────────────────────────────────────────────────────

/// Smooth area line for change over time, with a touch crosshair and tooltip.
class ReportsTrendLine extends StatelessWidget {
  const ReportsTrendLine({
    super.key,
    required this.data,
    required this.seriesLabel,
    this.accent,
  });

  final List<ReportsDatum> data;

  /// Names the single series — a lone series needs no legend box.
  final String seriesLabel;
  final Color? accent;

  static const double height = 190;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);

    if (data.length < 2) return const ReportsChartPlaceholder();

    final color = accent ?? palette.seriesColor(0);
    final maxValue = data.fold<double>(0, (m, d) => math.max(m, d.value));
    final maxY = maxValue <= 0 ? 10.0 : maxValue * 1.25;

    // Show at most five x labels; denser than that and they collide on a phone.
    final labelStride = math.max(1, (data.length / 5).ceil());

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 3,
            getDrawingHorizontalLine: (_) => FlLine(
              color: palette.chartGrid,
              strokeWidth: 1,
              dashArray: const [4, 6],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY / 3,
                reservedSize: 36,
                getTitlesWidget: (value, _) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    ReportsSeries.compact(value),
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: palette.chartAxisLabel,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, _) {
                  final i = value.round();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  if (i % labelStride != 0 && i != data.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: palette.chartAxisLabel,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            getTouchedSpotIndicator: (barData, indexes) => [
              for (final _ in indexes)
                TouchedSpotIndicatorData(
                  FlLine(color: color.withValues(alpha: 0.45), strokeWidth: 1.5),
                  FlDotData(
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 4.5,
                      color: color,
                      strokeWidth: 2,
                      strokeColor: palette.chartSurface,
                    ),
                  ),
                ),
            ],
            touchTooltipData: LineTouchTooltipData(
              tooltipBorderRadius: BorderRadius.circular(12),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => palette.tooltipSurface,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    data[spot.x.round().clamp(0, data.length - 1)].label,
                    WmsDesignTokens.supportingDense(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text:
                            '\n${ReportsSeries.compact(spot.y)} $seriesLabel',
                        style:
                            WmsDesignTokens.supportingDense(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              curveSmoothness: 0.28,
              preventCurveOverShooting: true,
              barWidth: 2,
              isStrokeCapRound: true,
              color: color,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.26),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
              spots: [
                for (var i = 0; i < data.length; i++)
                  FlSpot(i.toDouble(), data[i].value),
              ],
            ),
          ],
        ),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

/// Inline placeholder for a chart slot with nothing to draw.
class ReportsChartPlaceholder extends StatelessWidget {
  const ReportsChartPlaceholder({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);

    return SizedBox(
      height: 96,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 16,
              color: palette.colors.textTertiary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message ?? 'Not enough data for this period',
                maxLines: 2,
                textAlign: TextAlign.center,
                style: WmsDesignTokens.supportingDense(context).copyWith(
                  color: palette.colors.textTertiary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
