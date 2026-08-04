import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_chart_theme.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_dashboard_section.dart';

/// Products by category — theme-adaptive enterprise bar chart.
class ProductsCategoryChart extends StatelessWidget {
  const ProductsCategoryChart({super.key, required this.products});

  final List<Product> products;

  static const chartHeight = 140.0;

  @override
  Widget build(BuildContext context) {
    final chart = WmsChartTheme.of(context);
    final counts = <String, int>{};
    for (final p in products) {
      final cat = p.category?.trim().isNotEmpty == true
          ? p.category!.trim()
          : 'Uncategorized';
      counts[cat] = (counts[cat] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return _ProductsChartEmpty(
        message: 'No category data available',
        chart: chart,
      );
    }

    final series = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final display = series.take(8).toList();
    final maxY =
        display.fold<double>(0, (m, e) => math.max(m, e.value.toDouble()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: chartHeight,
          child: BarChart(
            BarChartData(
              maxY: maxY == 0 ? 4 : maxY * 1.2,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: chart.colors.chartGrid,
                  strokeWidth: 1,
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
                    reservedSize: 26,
                    getTitlesWidget: (value, _) => Text(
                      value.toInt().toString(),
                      style: chart.axisLabelStyle,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= display.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          display[i].key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: chart.axisLabelStyle,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < display.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: display[i].value.toDouble(),
                        width: display.length > 5 ? 14 : 18,
                        borderRadius: BorderRadius.circular(4),
                        color: WmsChartTheme.categoryColor(
                          i,
                          isDark: chart.colors.isDark,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 400),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            for (var i = 0; i < display.length; i++)
              _LegendRow(
                color: WmsChartTheme.categoryColor(
                  i,
                  isDark: chart.colors.isDark,
                ),
                label: display[i].key,
                value: display[i].value,
                compact: true,
                chart: chart,
              ),
          ],
        ),
      ],
    );
  }
}

/// Stock status distribution donut — theme-adaptive.
class ProductsStockStatusChart extends StatelessWidget {
  const ProductsStockStatusChart({super.key, required this.products});

  final List<Product> products;

  static const chartHeight = 168.0;

  @override
  Widget build(BuildContext context) {
    final chart = WmsChartTheme.of(context);
    final segments = WmsChartTheme.stockStatusSegments(chart.colors);

    final counts = <String, int>{
      for (final s in segments) s.label: 0,
    };
    for (final p in products) {
      final label = p.stockStatusLabel;
      counts[label] = (counts[label] ?? 0) + 1;
    }

    final values = segments.map((s) => counts[s.label]!.toDouble()).toList();
    final total = values.fold<double>(0, (sum, v) => sum + v);

    if (total <= 0) {
      return _ProductsChartEmpty(
        message: 'No stock status data available',
        chart: chart,
      );
    }

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value <= 0) continue;
      final pct = ((value / total) * 100).round();
      sections.add(
        PieChartSectionData(
          value: value,
          color: segments[i].color,
          radius: 44,
          title: '$pct%',
          titleStyle: WmsDesignTokens.supportingDense(context).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    }

    return SizedBox(
      height: chartHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 26,
                sections: sections,
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < segments.length; i++)
                  if (values[i] > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _LegendRow(
                        color: segments[i].color,
                        label: segments[i].label,
                        value: values[i].toInt(),
                        chart: chart,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.chart,
    this.compact = false,
  });

  final Color color;
  final String label;
  final int value;
  final WmsChartTheme chart;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Container(
          width: compact ? 8 : 10,
          height: compact ? 8 : 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        if (compact)
          Text(
            '$label ($value)',
            style: chart.legendLabelStyle,
          )
        else ...[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: chart.legendLabelStyle,
            ),
          ),
          Text('$value', style: chart.legendValueStyle),
        ],
      ],
    );
  }
}

class _ProductsChartEmpty extends StatelessWidget {
  const _ProductsChartEmpty({
    required this.message,
    required this.chart,
  });

  final String message;
  final WmsChartTheme chart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: chart.emptyMessageStyle,
        ),
      ),
    );
  }
}

/// Analytics block — category bar chart + stock status donut.
class ProductsAnalyticsSection extends StatelessWidget {
  const ProductsAnalyticsSection({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final chart = WmsChartTheme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: chart.sectionBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: chart.border),
      ),
      child: WmsDashboardSection(
        title: 'Product Analytics',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              elevated: true,
              padding: const EdgeInsets.all(AppSpacing.md),
              backgroundColor: chart.cardBackground,
              borderColor: chart.border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Products by Category',
                    style: WmsDesignTokens.cardTitle(context).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: chart.colors.textPrimary,
                    ),
                  ),
                  Text(
                    'Catalog distribution by category',
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: chart.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ProductsCategoryChart(products: products),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              elevated: true,
              padding: const EdgeInsets.all(AppSpacing.md),
              backgroundColor: chart.cardBackground,
              borderColor: chart.border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock Status Distribution',
                    style: WmsDesignTokens.cardTitle(context).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: chart.colors.textPrimary,
                    ),
                  ),
                  Text(
                    'Inventory health across catalog',
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: chart.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ProductsStockStatusChart(products: products),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
