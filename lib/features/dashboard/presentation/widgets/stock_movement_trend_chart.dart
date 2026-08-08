import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/dashboard_enterprise_widgets.dart';

/// Enterprise grouped bar chart — inbound vs outbound over the last 7 days.
class StockMovementTrendChart extends StatelessWidget {
  const StockMovementTrendChart({
    super.key,
    required this.series,
    this.embedded = false,
  });

  final DashboardChartTimeSeries series;

  /// When true, renders chart content only (no outer card shell).
  final bool embedded;

  static const Color inboundColor = Color(0xFF22C55E);
  static const Color outboundColor = Color(0xFFEF4444);

  static double chartHeightFor(double width) {
    if (width >= 1024) return 320;
    if (width >= MobileUi.tabletWidth) return 300;
    return 260;
  }

  static String _mmDdLabel(int dayIndex) {
    final day = DateTime.now().subtract(Duration(days: 6 - dayIndex));
    final mm = day.month.toString().padLeft(2, '0');
    final dd = day.day.toString().padLeft(2, '0');
    return '$mm-$dd';
  }

  static List<double> _lineValues(
    DashboardChartTimeSeries series,
    String keyword,
  ) {
    for (final line in series.lines) {
      if (line.label.toLowerCase().contains(keyword)) {
        return line.values;
      }
    }
    return List<double>.filled(series.labels.length.clamp(1, 7), 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final chartHeight = chartHeightFor(width);
    final content = _StockMovementTrendChartBody(
      series: series,
      chartHeight: chartHeight,
      textPrimary: colors.textPrimary,
      textSecondary: colors.textSecondary,
      gridColor: colors.border.withValues(alpha: 0.55),
    );

    if (embedded) return content;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: content,
    );
  }
}

class _StockMovementTrendChartBody extends StatelessWidget {
  const _StockMovementTrendChartBody({
    required this.series,
    required this.chartHeight,
    required this.textPrimary,
    required this.textSecondary,
    required this.gridColor,
  });

  final DashboardChartTimeSeries series;
  final double chartHeight;
  final Color textPrimary;
  final Color textSecondary;
  final Color gridColor;

  TextStyle get _titleStyle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: textPrimary,
      );

  TextStyle get _subtitleStyle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: textSecondary,
      );

  TextStyle get _axisStyle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: textSecondary,
      );

  TextStyle get _legendStyle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: textPrimary,
      );

  @override
  Widget build(BuildContext context) {
    final inbound = StockMovementTrendChart._lineValues(series, 'inbound');
    final outbound = StockMovementTrendChart._lineValues(series, 'outbound');
    final inboundPadded = _padTo(inbound, 7);
    final outboundPadded = _padTo(outbound, 7);

    final totalIn = inboundPadded.fold<double>(0, (s, v) => s + v).round();
    final totalOut = outboundPadded.fold<double>(0, (s, v) => s + v).round();
    final hasData = series.hasData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stock Movement Trend', style: _titleStyle),
                  const SizedBox(height: 4),
                  Text(
                    'Inbound vs Outbound · Last 7 days',
                    style: _subtitleStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _SummaryBadge(
                  label: '↘ $totalIn In',
                  color: StockMovementTrendChart.inboundColor,
                ),
                const SizedBox(height: 6),
                _SummaryBadge(
                  label: '↗ $totalOut Out',
                  color: StockMovementTrendChart.outboundColor,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!hasData)
          SizedBox(
            height: chartHeight,
            child: _StockMovementEmptyState(textSecondary: textSecondary),
          )
        else ...[
          _MovementLegend(style: _legendStyle),
          const SizedBox(height: 12),
          SizedBox(
            height: chartHeight,
            child: _GroupedMovementBarChart(
              inbound: inboundPadded.take(7).toList(),
              outbound: outboundPadded.take(7).toList(),
              axisStyle: _axisStyle,
              gridColor: gridColor,
            ),
          ),
        ],
      ],
    );
  }

  List<double> _padTo(List<double> values, int length) {
    if (values.length >= length) return values;
    return [...values, ...List.filled(length - values.length, 0)];
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}

class _MovementLegend extends StatelessWidget {
  const _MovementLegend({required this.style});

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        _LegendDot(
          color: StockMovementTrendChart.inboundColor,
          label: 'Inbound',
          style: style,
        ),
        _LegendDot(
          color: StockMovementTrendChart.outboundColor,
          label: 'Outbound',
          style: style,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.style,
  });

  final Color color;
  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }
}

class _GroupedMovementBarChart extends StatelessWidget {
  const _GroupedMovementBarChart({
    required this.inbound,
    required this.outbound,
    required this.axisStyle,
    required this.gridColor,
  });

  final List<double> inbound;
  final List<double> outbound;
  final TextStyle axisStyle;
  final Color gridColor;

  @override
  Widget build(BuildContext context) {
    final count = math.min(7, math.min(inbound.length, outbound.length));
    final maxValue = [
      for (var i = 0; i < count; i++) ...[inbound[i], outbound[i]],
    ].fold<double>(0, math.max);

    final maxY = maxValue == 0 ? 6.0 : math.max(4.0, maxValue * 1.2);
    final yInterval = _niceInterval(maxY);

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        groupsSpace: 10,
        barTouchData: const BarTouchData(enabled: false),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: gridColor,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: yInterval,
              getTitlesWidget: (value, _) {
                if (value < 0 || value > maxY) {
                  return const SizedBox.shrink();
                }
                if (value != value.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    value.toInt().toString(),
                    style: axisStyle,
                    maxLines: 1,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= count) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    StockMovementTrendChart._mmDdLabel(i),
                    style: axisStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < count; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: inbound[i],
                  color: StockMovementTrendChart.inboundColor,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: outbound[i],
                  color: StockMovementTrendChart.outboundColor,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  double _niceInterval(double maxY) {
    if (maxY <= 6) return 1;
    if (maxY <= 12) return 2;
    if (maxY <= 30) return 5;
    if (maxY <= 60) return 10;
    return (maxY / 5).ceilToDouble();
  }
}

class _StockMovementEmptyState extends StatelessWidget {
  const _StockMovementEmptyState({required this.textSecondary});

  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_horiz_rounded,
            size: WmsIconSizes.emptyState,
            color: textSecondary.withValues(alpha: 0.65),
          ),
          const SizedBox(height: 12),
          Text(
            'No stock movements in the last 7 days',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
