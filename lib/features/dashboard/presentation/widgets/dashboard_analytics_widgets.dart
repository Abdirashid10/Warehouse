import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/dashboard_enterprise_widgets.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/stock_movement_trend_chart.dart';
import 'package:logisticsmobile/features/inventory/presentation/utils/inventory_metrics.dart';
import 'package:logisticsmobile/features/inventory/presentation/widgets/inventory_analytics_widgets.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_dashboard_section.dart';

/// Inventory distribution donut + category bar chart (moved from Inventory screen).
class DashboardInventoryDistributionCharts extends StatelessWidget {
  const DashboardInventoryDistributionCharts({super.key, required this.data});

  final StaffDashboardData data;

  @override
  Widget build(BuildContext context) {
    final breakdown = InventoryMetrics.breakdownFor(data.inventoryItems);

    return WmsDashboardSection(
      title: 'Inventory Analytics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            elevated: true,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory Distribution',
                  style: WmsDesignTokens.cardTitle(context),
                ),
                Text(
                  'Stock status breakdown',
                  style: WmsDesignTokens.supportingDense(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 168,
                  child: InventoryDistributionDonut(
                    inStock: breakdown.inStock,
                    lowStock: breakdown.low,
                    outOfStock: breakdown.out,
                    expired: breakdown.expired,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            elevated: true,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Distribution',
                  style: WmsDesignTokens.cardTitle(context),
                ),
                Text(
                  'Products by category',
                  style: WmsDesignTokens.supportingDense(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                InventoryCategoryChart.fromCatalog(
                  items: data.inventoryItems,
                  productsBySku: data.productsBySku,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact enterprise analytics placed between KPI overview and task center.
class DashboardKpiAnalyticsCharts extends StatelessWidget {
  const DashboardKpiAnalyticsCharts({super.key, required this.analytics});

  final StaffExecutiveAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return StockMovementTrendChart(series: analytics.inventoryTrendSeries);
  }
}

/// Donut chart for in-stock / low-stock / out-of-stock SKU counts.
class DashboardInventoryHealthDonut extends StatelessWidget {
  const DashboardInventoryHealthDonut({
    super.key,
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
  });

  final int inStock;
  final int lowStock;
  final int outOfStock;

  /// Segment palette, resolved per brightness.
  ///
  /// Previously a `static const` list, which forced the light-mode swatches
  /// into every theme — a static field has no context to resolve against.
  static List<({String label, Color color})> _segmentsFor(WmsUiColors colors) =>
      [
        (label: 'In Stock', color: colors.success),
        (label: 'Low Stock', color: colors.warning),
        (label: 'Out Of Stock', color: colors.error),
      ];

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final values = [
      inStock.toDouble(),
      lowStock.toDouble(),
      outOfStock.toDouble(),
    ];
    final total = values.fold<double>(0, (sum, value) => sum + value);

    if (total <= 0) {
      return const _ChartEmptyState(message: 'No inventory SKU data');
    }

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value <= 0) continue;
      final pct = ((value / total) * 100).round();
      sections.add(
        PieChartSectionData(
          value: value,
          color: _segmentsFor(colors)[i].color,
          radius: 52,
          title: '$pct%',
          titleStyle: WmsDesignTokens.supportingDense(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 34,
              sections: sections,
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _segmentsFor(colors).length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _DonutLegendRow(
                    color: _segmentsFor(colors)[i].color,
                    label: _segmentsFor(colors)[i].label,
                    value: values[i].toInt(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutLegendRow extends StatelessWidget {
  const _DonutLegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WmsDesignTokens.supportingDense(context),
              ),
              Text(
                '$value SKUs',
                style: WmsDesignTokens.kpiLabel(
                  context,
                ).copyWith(fontSize: 13, height: 1.2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact dual-line chart for inbound vs outbound movement.
class DashboardCompactMovementChart extends StatelessWidget {
  const DashboardCompactMovementChart({super.key, required this.series});

  final DashboardChartTimeSeries series;

  @override
  Widget build(BuildContext context) {
    if (!series.hasData) {
      return const _ChartEmptyState(
        message: 'No movement data in the last 7 days',
      );
    }

    final maxY = series.lines.fold<double>(0, (max, line) {
      for (final value in line.values) {
        if (value > max) max = value;
      }
      return max;
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final colors = WmsUiColors.of(context);
        const legendReserve = 32.0;
        final chartHeight = constraints.maxHeight.isFinite
            ? math.max(80.0, constraints.maxHeight - legendReserve)
            : 160.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _ChartLegend(lines: series.lines),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: chartHeight,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY == 0 ? 6 : math.max(4, maxY * 1.2),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        interval: 1,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 18,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= series.labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            series.labels[i],
                            style: WmsDesignTokens.chartAxis(context),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    for (final line in series.lines)
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < line.values.length; i++)
                            FlSpot(i.toDouble(), line.values[i]),
                        ],
                        isCurved: true,
                        color: line.resolveColor(colors),
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.lines});

  final List<DashboardChartLine> lines;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final line in lines)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 3,
                decoration: BoxDecoration(
                  color: line.resolveColor(colors),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(line.label, style: WmsDesignTokens.supportingDense(context)),
            ],
          ),
      ],
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({this.message = 'No chart data yet'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: WmsDesignTokens.supporting(context),
      ),
    );
  }
}
