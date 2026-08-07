import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/widgets/wms/wms_pushed_scaffold.dart';

/// Admin drawer entry — full inventory tracking UI with warehouse-level stock summaries.
class InventoryTrackingScreen extends StatelessWidget {
  const InventoryTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF0F172A) : colors.background;
    final surface = isDark ? const Color(0xFF111827) : colors.surface;
    final border = isDark ? Colors.white24 : colors.border;
    final primaryText = isDark ? Colors.white : colors.textPrimary;
    final secondaryText = isDark ? Colors.white70 : colors.textSecondary;

    final warehouses = [
      _WarehouseSnapshot(
        name: 'North Hub',
        zone: 'Zone A',
        items: 18,
        lowStock: 3,
        outOfStock: 1,
        status: 'Safe',
        accent: colors.success,
      ),
      _WarehouseSnapshot(
        name: 'East Dock',
        zone: 'Zone B',
        items: 11,
        lowStock: 5,
        outOfStock: 0,
        status: 'Low Stock',
        accent: colors.warning,
      ),
      _WarehouseSnapshot(
        name: 'West Yard',
        zone: 'Zone C',
        items: 6,
        lowStock: 2,
        outOfStock: 2,
        status: 'Out of Stock',
        accent: colors.error,
      ),
    ];

    return WmsPushedScaffold(
      title: 'Inventory Tracking',
      body: Container(
        color: background,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          children: [
            _buildSummaryCard(
              context,
              surface: surface,
              border: border,
              primaryText: primaryText,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Warehouse Inventory',
              style: theme.textTheme.titleMedium?.copyWith(
                color: primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...warehouses.map((warehouse) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _buildWarehouseCard(
                    context,
                    warehouse,
                    surface: surface,
                    border: border,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required Color surface,
    required Color border,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final colors = WmsUiColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Realtime stock overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Monitor stock levels, shelves, and warehouse status in one view.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _StatChip(label: 'Safe', value: '41', color: colors.success),
              _StatChip(label: 'Low', value: '10', color: colors.warning),
              _StatChip(label: 'Out', value: '3', color: colors.error),
              _StatChip(label: 'Expired', value: '2', color: colors.expired),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseCard(
    BuildContext context,
    _WarehouseSnapshot warehouse, {
    required Color surface,
    required Color border,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final colors = WmsUiColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  warehouse.name,
                  style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: warehouse.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  warehouse.status,
                  style: TextStyle(
                    color: warehouse.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            warehouse.zone,
            style: TextStyle(color: secondaryText, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _MetricTile(label: 'Items', value: '${warehouse.items}', color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              _MetricTile(label: 'Low', value: '${warehouse.lowStock}', color: colors.warning),
              const SizedBox(width: AppSpacing.sm),
              _MetricTile(label: 'Out', value: '${warehouse.outOfStock}', color: colors.error),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _WarehouseSnapshot {
  const _WarehouseSnapshot({
    required this.name,
    required this.zone,
    required this.items,
    required this.lowStock,
    required this.outOfStock,
    required this.status,
    required this.accent,
  });

  final String name;
  final String zone;
  final int items;
  final int lowStock;
  final int outOfStock;
  final String status;
  final Color accent;
}
