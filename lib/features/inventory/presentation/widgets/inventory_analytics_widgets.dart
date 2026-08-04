import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:logisticsmobile/features/inventory/presentation/utils/inventory_metrics.dart';
import 'package:logisticsmobile/features/inventory/presentation/widgets/inventory_enterprise_widgets.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_dashboard_section.dart';

/// Enterprise inventory distribution donut — in stock, low, out, expired.
class InventoryDistributionDonut extends StatelessWidget {
  const InventoryDistributionDonut({
    super.key,
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
    required this.expired,
    this.compact = false,
    this.showLegend = true,
  });

  final int inStock;
  final int lowStock;
  final int outOfStock;
  final int expired;
  final bool compact;
  final bool showLegend;

  static const _segments = [
    (label: 'In Stock', color: AppColors.success),
    (label: 'Low Stock', color: AppColors.warning),
    (label: 'Out Of Stock', color: AppColors.error),
    (label: 'Expired', color: InventoryUi.expiredPurple),
  ];

  @override
  Widget build(BuildContext context) {
    final values = [
      inStock.toDouble(),
      lowStock.toDouble(),
      outOfStock.toDouble(),
      expired.toDouble(),
    ];
    final total = values.fold<double>(0, (sum, value) => sum + value);

    if (total <= 0) {
      return const _InventoryChartEmpty(message: 'No inventory distribution data');
    }

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value <= 0) continue;
      sections.add(
        PieChartSectionData(
          value: value,
          color: _segments[i].color,
          radius: compact ? 42 : 50,
          showTitle: !compact,
          title: compact ? '' : '${((value / total) * 100).round()}%',
          titleStyle: WmsDesignTokens.supportingDense(context).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final chart = PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: compact ? 24 : 32,
        sections: sections,
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );

    final legend = [
      for (var i = 0; i < _segments.length; i++)
        if (values[i] > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _LegendRow(
              color: _segments[i].color,
              label: _segments[i].label,
              value: values[i].toInt(),
            ),
          ),
    ];

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: MobileUi.expiryChartSize,
              height: MobileUi.expiryChartSize,
              child: AspectRatio(aspectRatio: 1, child: chart),
            ),
          ),
          if (showLegend) ...[
            const SizedBox(height: AppSpacing.md),
            ...legend,
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 3, child: chart),
        const SizedBox(width: AppSpacing.sm),
        Expanded(flex: 2, child: Column(children: legend)),
      ],
    );
  }
}

/// Category distribution bar chart from live product categories.
class InventoryCategoryChart extends StatelessWidget {
  const InventoryCategoryChart({super.key, required InventoryViewState data})
      : _data = data,
        _items = null,
        _productsBySku = null;

  const InventoryCategoryChart.fromCatalog({
    super.key,
    required List<InventoryItem> items,
    required Map<String, Product> productsBySku,
  })  : _data = null,
        _items = items,
        _productsBySku = productsBySku;

  final InventoryViewState? _data;
  final List<InventoryItem>? _items;
  final Map<String, Product>? _productsBySku;

  static const _priorityCategories = [
    'Food',
    'Electronics',
    'Drink',
    'Sports',
    'Mobile',
  ];

  String _categoryFor(InventoryItem item) {
    final data = _data;
    if (data != null) return data.categoryFor(item);
    final productsBySku = _productsBySku;
    return productsBySku?[item.sku]?.category ?? 'Uncategorized';
  }

  Iterable<InventoryItem> get _sourceItems {
    final data = _data;
    if (data != null) return data.items;
    return _items ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final series = _categorySeries(_sourceItems, _categoryFor);
    if (series.isEmpty) {
      return const _InventoryChartEmpty(message: 'No category data available');
    }

    final display = series.take(8).toList();
    final maxY = display.fold<double>(0, (m, e) => math.max(m, e.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 140,
          child: BarChart(
            BarChartData(
              maxY: maxY == 0 ? 4 : maxY * 1.2,
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 24),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
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
                          style: WmsDesignTokens.chartAxis(context),
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
                        toY: display[i].value,
                        width: display.length > 5 ? 12 : 16,
                        borderRadius: BorderRadius.circular(4),
                        color: _categoryColor(i),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            for (var i = 0; i < display.length; i++)
              _LegendRow(
                color: _categoryColor(i),
                label: display[i].key,
                value: display[i].value.toInt(),
                compact: true,
              ),
          ],
        ),
      ],
    );
  }

  static List<MapEntry<String, double>> _categorySeries(
    Iterable<InventoryItem> items,
    String Function(InventoryItem) categoryFor,
  ) {
    final counts = <String, double>{};
    for (final item in items) {
      final category = categoryFor(item);
      counts[category] = (counts[category] ?? 0) + 1;
    }
    if (counts.isEmpty) return const [];

    final ordered = <MapEntry<String, double>>[];
    final matched = <String>{};

    for (final priority in _priorityCategories) {
      final match = counts.entries.where(
        (e) => e.key.toLowerCase() == priority.toLowerCase(),
      );
      if (match.isEmpty) continue;
      final entry = match.first;
      ordered.add(MapEntry(priority, entry.value));
      matched.add(entry.key);
    }

    final remaining = counts.entries
        .where((e) => !matched.contains(e.key))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in remaining) {
      ordered.add(MapEntry(entry.key, entry.value));
    }

    return ordered;
  }

  static Color _categoryColor(int index) {
    const colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      Color(0xFF7C3AED),
      Color(0xFF0D9488),
    ];
    return colors[index % colors.length];
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    this.compact = false,
  });

  final Color color;
  final String label;
  final int value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
        Text(
          compact ? '$label ($value)' : label,
          style: WmsDesignTokens.legend(context),
        ),
        if (!compact) ...[
          const Spacer(),
          Text(
            '$value',
            style: WmsDesignTokens.legend(context),
          ),
        ],
      ],
    );
  }
}

class _InventoryChartEmpty extends StatelessWidget {
  const _InventoryChartEmpty({required this.message});

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

/// Analytics block — distribution donut + category chart.
class InventoryAnalyticsSection extends StatelessWidget {
  const InventoryAnalyticsSection({super.key, required this.data});

  final InventoryViewState data;

  @override
  Widget build(BuildContext context) {
    final breakdown = InventoryMetrics.breakdownFor(data.items);

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
                InventoryCategoryChart(data: data),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
