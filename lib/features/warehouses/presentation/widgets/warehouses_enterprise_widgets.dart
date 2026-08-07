import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';
import 'package:logisticsmobile/features/warehouses/presentation/widgets/warehouse_premium_atoms.dart';
import 'package:logisticsmobile/features/warehouses/presentation/widgets/warehouse_premium_theme.dart';

/// Premium Warehouses UI — header, summary metrics, search, warehouse cards,
/// utilisation analytics and performance rankings.
///
/// Every surface composes the atoms in `warehouse_premium_atoms.dart` on top of
/// the token layer in `warehouse_premium_theme.dart`, so the module keeps one
/// consistent, theme-aware visual language in both light and dark mode.

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class WarehousesEnterpriseHeader extends StatelessWidget {
  const WarehousesEnterpriseHeader({
    super.key,
    required this.canManage,
    required this.onAdd,
  });

  final bool canManage;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WarehouseBreadcrumbBadge(
          icon: Icons.account_tree_rounded,
          parent: 'Infrastructure',
          current: 'Warehouses',
        ),
        const SizedBox(height: AppSpacing.md + 2),
        Text(
          'Warehouses',
          style: WmsDesignTokens.pageTitle(context).copyWith(
            color: colors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Infrastructure & capacity control across your network',
          style: WmsDesignTokens.body(context).copyWith(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        if (canManage) ...[
          const SizedBox(height: AppSpacing.lg + 2),
          WarehouseGradientButton(
            icon: Icons.add_rounded,
            label: 'Add Warehouse',
            onPressed: onAdd,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary metrics
// ─────────────────────────────────────────────────────────────────────────────

class WarehousesKpiStrip extends StatelessWidget {
  const WarehousesKpiStrip({super.key, required this.summary});

  final WarehousesSummary summary;

  /// Fixed strip height — sized for the tallest card at a 1.2× text scale.
  static const double height = 132;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);

    final items = <_SummaryMetric>[
      _SummaryMetric(
        label: 'Total Warehouses',
        value: '${summary.totalWarehouses}',
        icon: Icons.warehouse_rounded,
        color: palette.accentBlue,
      ),
      _SummaryMetric(
        label: 'Total Units Stored',
        value: WmsFormatters.quantity(summary.totalUnitsStored),
        icon: Icons.inventory_2_rounded,
        color: palette.accentEmerald,
      ),
      _SummaryMetric(
        label: 'Total Staff',
        value: '${summary.totalStaff}',
        icon: Icons.groups_rounded,
        color: palette.accentViolet,
      ),
      _SummaryMetric(
        label: 'Avg Capacity Used',
        value: '${summary.averageCapacityUsed}%',
        icon: Icons.speed_rounded,
        color: palette.capacityColor(summary.averageCapacityUsed),
      ),
    ];

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) => _SummaryMetricCard(metric: items[i]),
      ),
    );
  }
}

class _SummaryMetric {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({required this.metric});

  final _SummaryMetric metric;

  static const double _width = 176;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;

    return SizedBox(
      width: _width,
      child: WarehouseGlassPanel(
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        borderTint: metric.color,
        glowColor: metric.color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WarehouseGlowBadge(icon: metric.icon, color: metric.color, size: 40),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                metric.value,
                maxLines: 1,
                style: WmsDesignTokens.cardNumber(context).copyWith(
                  color: colors.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -0.6,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              metric.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textTertiary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search & filters
// ─────────────────────────────────────────────────────────────────────────────

/// Search and location inputs fused into one floating control surface.
class WarehousesSearchPanel extends StatelessWidget {
  const WarehousesSearchPanel({
    super.key,
    required this.nameController,
    required this.locationController,
    required this.onNameSearch,
    required this.onLocationSearch,
    required this.activeFilterCount,
    required this.showFilters,
    required this.onToggleFilters,
    required this.onClearFilters,
    required this.displayCount,
    required this.totalCount,
  });

  final TextEditingController nameController;
  final TextEditingController locationController;
  final ValueChanged<String> onNameSearch;
  final ValueChanged<String> onLocationSearch;
  final int activeFilterCount;
  final bool showFilters;
  final VoidCallback onToggleFilters;
  final VoidCallback onClearFilters;
  final int displayCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;
    final filtersActive = showFilters || activeFilterCount > 0;

    return WarehouseGlassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PremiumSearchField(
            controller: nameController,
            onChanged: onNameSearch,
            hint: 'Search warehouses',
            icon: Icons.search_rounded,
            accent: palette.brand,
          ),
          Divider(height: 1, thickness: 1, color: palette.hairline),
          _PremiumSearchField(
            controller: locationController,
            onChanged: onLocationSearch,
            hint: 'Filter by location',
            icon: Icons.location_on_rounded,
            accent: palette.accentTeal,
          ),
          Divider(height: 1, thickness: 1, color: palette.hairline),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm + 2, bottom: 4),
            child: Row(
              children: [
                Flexible(
                  child: _FilterToggle(
                    active: filtersActive,
                    count: activeFilterCount,
                    onTap: onToggleFilters,
                    expanded: showFilters,
                  ),
                ),
                if (activeFilterCount > 0) ...[
                  const SizedBox(width: AppSpacing.xs),
                  WarehouseSoftAction(
                    icon: Icons.close_rounded,
                    color: colors.textSecondary,
                    onTap: onClearFilters,
                    tooltip: 'Clear filters',
                    size: 38,
                  ),
                ],
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '$displayCount of $totalCount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
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

class _PremiumSearchField extends StatelessWidget {
  const _PremiumSearchField({
    required this.controller,
    required this.onChanged,
    required this.hint,
    required this.icon,
    required this.accent,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;

    return Row(
      children: [
        Container(
          margin: const EdgeInsets.only(right: AppSpacing.sm + 2),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: palette.tint(accent, 0.13),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: accent),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: WmsDesignTokens.body(context).copyWith(
              color: colors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: accent,
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
            if (value.text.isEmpty) return const SizedBox(width: AppSpacing.xs);
            return IconButton(
              onPressed: () {
                controller.clear();
                onChanged('');
              },
              tooltip: 'Clear',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              icon: Icon(
                Icons.cancel_rounded,
                size: 17,
                color: colors.textTertiary,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FilterToggle extends StatelessWidget {
  const _FilterToggle({
    required this.active,
    required this.count,
    required this.onTap,
    required this.expanded,
  });

  final bool active;
  final int count;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;
    final radius = BorderRadius.circular(WarehousePalette.radiusPill);
    final foreground = active ? Colors.white : colors.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: active
            ? palette.glow(palette.brand, opacity: 0.30, blur: 14, dy: 5, spread: -4)
            : null,
      ),
      child: Material(
        color: active ? Colors.transparent : palette.insetFill,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: active ? palette.brandGradient : null,
            borderRadius: radius,
            border: active ? null : palette.glassBorder(),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: foreground),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      count > 0 ? 'Filters · $count' : 'Filters',
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
                  const SizedBox(width: 3),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: foreground,
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

class WarehousesFiltersPanel extends StatelessWidget {
  const WarehousesFiltersPanel({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final WarehouseCapacityFilter? selected;
  final ValueChanged<WarehouseCapacityFilter?> onSelected;

  static const filters = [
    (WarehouseCapacityFilter.active, 'Active', Icons.check_circle_outline_rounded),
    (WarehouseCapacityFilter.lowCapacity, 'Low Capacity', Icons.trending_down_rounded),
    (WarehouseCapacityFilter.highCapacity, 'High Capacity', Icons.trending_up_rounded),
    (WarehouseCapacityFilter.full, 'Full', Icons.warning_amber_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return WarehouseGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final (filter, label, icon) in filters)
            _FilterChip(
              label: label,
              icon: icon,
              selected: selected == filter,
              onTap: () => onSelected(selected == filter ? null : filter),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;
    final radius = BorderRadius.circular(WarehousePalette.radiusPill);
    final foreground = selected ? Colors.white : colors.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: selected
            ? palette.glow(palette.brand, opacity: 0.30, blur: 14, dy: 5, spread: -4)
            : null,
      ),
      child: Material(
        color: selected ? Colors.transparent : palette.insetFill,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: selected ? palette.brandGradient : null,
            borderRadius: radius,
            border: selected ? null : palette.glassBorder(),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: foreground),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: foreground,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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

// ─────────────────────────────────────────────────────────────────────────────
// Warehouse card
// ─────────────────────────────────────────────────────────────────────────────

class WarehouseEnterpriseCard extends StatelessWidget {
  const WarehouseEnterpriseCard({
    super.key,
    required this.warehouse,
    required this.canManage,
    required this.onView,
    required this.onEdit,
    required this.onTransfer,
    required this.onAssignStaff,
  });

  final Warehouse warehouse;
  final bool canManage;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onTransfer;
  final VoidCallback onAssignStaff;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;
    final pct = warehouse.utilizationPercent;
    final band = WarehouseCapacityBand.fromPercent(pct);
    final bandColor = palette.bandColor(band);

    return WarehouseGlassPanel(
      radius: WarehousePalette.radiusCard,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderTint: bandColor,
      onTap: onView,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Identity ────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WarehouseGradientTile(initials: warehouse.initials),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warehouse.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.cardTitle(context).copyWith(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.place_rounded,
                          size: 13,
                          color: colors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            warehouse.location.isEmpty
                                ? 'No location set'
                                : warehouse.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WmsDesignTokens.supporting(context).copyWith(
                              color: colors.textSecondary,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              WarehouseStatusBadge(status: warehouse.statusLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Capacity ────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'CAPACITY USED',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.textTertiary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$pct%',
                style: WmsDesignTokens.cardNumber(context).copyWith(
                  color: bandColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -0.4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              WarehouseTonePill(label: band.label, color: bandColor, dense: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          WarehouseCapacityMeter(percent: pct),
          const SizedBox(height: AppSpacing.md + 2),

          // ── Metrics ─────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: WarehouseMetricBox(
                  label: 'Stored',
                  value: WmsFormatters.quantity(warehouse.totalUnits),
                  icon: Icons.inventory_2_rounded,
                  color: palette.accentBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: WarehouseMetricBox(
                  label: 'Staff',
                  value: '${warehouse.staffCount}',
                  icon: Icons.groups_rounded,
                  color: palette.accentViolet,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: WarehouseMetricBox(
                  label: 'Available',
                  value: WmsFormatters.quantity(warehouse.availableCapacity),
                  icon: Icons.check_circle_rounded,
                  color: palette.accentEmerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md + 2),
          Divider(height: 1, thickness: 1, color: palette.hairline),
          const SizedBox(height: AppSpacing.md),

          // ── Actions ─────────────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Expanded(
                  child: WarehouseSoftAction(
                    icon: Icons.visibility_rounded,
                    // Compact phones keep the primary action legible instead
                    // of truncating it next to the icon buttons.
                    label: constraints.maxWidth < 260 ? 'View' : 'View Details',
                    color: palette.accentBlue,
                    onTap: onView,
                  ),
                ),
                if (canManage) ...[
                  const SizedBox(width: AppSpacing.sm),
                  WarehouseSoftAction(
                    icon: Icons.edit_rounded,
                    color: palette.accentIndigo,
                    onTap: onEdit,
                    tooltip: 'Edit warehouse',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  WarehouseSoftAction(
                    icon: Icons.swap_horiz_rounded,
                    color: palette.accentAmber,
                    onTap: onTransfer,
                    tooltip: 'Transfer stock',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  WarehouseSoftAction(
                    icon: Icons.person_add_alt_1_rounded,
                    color: palette.accentTeal,
                    onTap: onAssignStaff,
                    tooltip: 'Assign staff',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kept for API compatibility — now renders the premium gradient identity tile.
class WarehouseAvatar extends StatelessWidget {
  const WarehouseAvatar({
    super.key,
    required this.name,
    required this.initials,
    this.size = 54,
  });

  final String name;
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) =>
      WarehouseGradientTile(initials: initials, size: size);
}

class WarehouseStatusBadge extends StatelessWidget {
  const WarehouseStatusBadge({super.key, required this.status});

  final WarehouseStatusLabel status;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);

    final (color, label, icon) = switch (status) {
      WarehouseStatusLabel.active => (
          palette.bandColor(WarehouseCapacityBand.low),
          'Active',
          Icons.check_circle_rounded,
        ),
      WarehouseStatusLabel.warning => (
          palette.bandColor(WarehouseCapacityBand.high),
          'Warning',
          Icons.warning_amber_rounded,
        ),
      WarehouseStatusLabel.full => (
          palette.bandColor(WarehouseCapacityBand.critical),
          'Full',
          Icons.error_rounded,
        ),
    };

    return WarehouseTonePill(label: label, color: color, icon: icon);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Analytics
// ─────────────────────────────────────────────────────────────────────────────

class WarehousesAnalyticsSection extends StatelessWidget {
  const WarehousesAnalyticsSection({super.key, required this.warehouses});

  final List<Warehouse> warehouses;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WarehouseSectionHeading(
          eyebrow: 'Analytics',
          title: 'Warehouse Utilization',
          subtitle: 'Capacity used by warehouse',
          trailing: WarehouseGlowBadge(
            icon: Icons.bar_chart_rounded,
            color: palette.brand,
            size: 38,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        WarehouseGlassPanel(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md + 2,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WarehouseUtilizationChart(warehouses: warehouses),
              const SizedBox(height: AppSpacing.md),
              const _CapacityLegend(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CapacityLegend extends StatelessWidget {
  const _CapacityLegend();

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final band in WarehouseCapacityBand.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: palette.bandGradient(band)),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                band.label,
                style: WmsDesignTokens.supportingDense(context).copyWith(
                  color: colors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class WarehouseUtilizationChart extends StatelessWidget {
  const WarehouseUtilizationChart({super.key, required this.warehouses});

  final List<Warehouse> warehouses;

  static const double chartHeight = 190;
  static const int _maxBars = 6;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;

    final display = [...warehouses]
      ..sort((a, b) => b.utilizationPercent.compareTo(a.utilizationPercent));
    final top = display.take(_maxBars).toList();

    if (top.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No utilization data available',
            style: WmsDesignTokens.supporting(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    final barWidth = top.length > 4 ? 16.0 : 22.0;

    return SizedBox(
      height: chartHeight,
      child: BarChart(
        BarChartData(
          // Fixed 0–100 scale: utilisation is a percentage, so bars stay
          // honestly comparable between warehouses and across refreshes.
          maxY: 100,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(
              color: palette.hairline,
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
                interval: 25,
                reservedSize: 34,
                getTitlesWidget: (value, _) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '${value.toInt()}%',
                    textAlign: TextAlign.right,
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: colors.textTertiary,
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
                reservedSize: 34,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= top.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      top[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBorderRadius: BorderRadius.circular(12),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              tooltipMargin: 10,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => colors.isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF0F172A),
              tooltipBorder: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
              ),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex < 0 || groupIndex >= top.length) return null;
                final w = top[groupIndex];
                return BarTooltipItem(
                  w.name,
                  WmsDesignTokens.supportingDense(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.3,
                  ),
                  children: [
                    TextSpan(
                      text: '\n${w.utilizationPercent}% used',
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: palette
                            .capacityColor(w.utilizationPercent)
                            .withValues(alpha: 0.95),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    TextSpan(
                      text:
                          '\n${WmsFormatters.quantity(w.totalUnits)} / ${WmsFormatters.quantity(w.capacity)}',
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < top.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: math.max(top[i].utilizationPercent.toDouble(), 0),
                    width: barWidth,
                    borderRadius: BorderRadius.circular(barWidth / 2),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors:
                          palette.capacityGradient(top[i].utilizationPercent),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 100,
                      color: palette.insetFill,
                    ),
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Performance
// ─────────────────────────────────────────────────────────────────────────────

class WarehousesPerformanceSection extends StatelessWidget {
  const WarehousesPerformanceSection({super.key, required this.rankings});

  final WarehousePerformanceRankings rankings;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);

    final rows = <_PerformanceRowData>[
      _PerformanceRowData(
        icon: Icons.trending_up_rounded,
        color: palette.accentAmber,
        label: 'Top Utilized',
        warehouse: rankings.topUtilized,
        value: rankings.topUtilized == null
            ? null
            : '${rankings.topUtilized!.utilizationPercent}%',
        unit: 'capacity',
      ),
      _PerformanceRowData(
        icon: Icons.trending_down_rounded,
        color: palette.accentEmerald,
        label: 'Lowest Utilized',
        warehouse: rankings.lowestUtilized,
        value: rankings.lowestUtilized == null
            ? null
            : '${rankings.lowestUtilized!.utilizationPercent}%',
        unit: 'capacity',
      ),
      _PerformanceRowData(
        icon: Icons.straighten_rounded,
        color: palette.accentIndigo,
        label: 'Largest Warehouse',
        warehouse: rankings.largest,
        value: rankings.largest == null
            ? null
            : WmsFormatters.quantity(rankings.largest!.capacity),
        unit: 'units cap.',
      ),
      _PerformanceRowData(
        icon: Icons.bolt_rounded,
        color: palette.accentViolet,
        label: 'Most Active',
        warehouse: rankings.mostActive,
        value: rankings.mostActive == null
            ? null
            : WmsFormatters.quantity(rankings.mostActive!.totalUnits),
        unit: 'units',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const WarehouseSectionHeading(
          eyebrow: 'Performance',
          title: 'Warehouse Performance',
          subtitle: 'Network leaders at a glance',
        ),
        const SizedBox(height: AppSpacing.md),
        WarehouseGlassPanel(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, thickness: 1, color: palette.hairline),
                _PerformanceRow(data: rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PerformanceRowData {
  const _PerformanceRowData({
    required this.icon,
    required this.color,
    required this.label,
    required this.warehouse,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final Color color;
  final String label;
  final Warehouse? warehouse;
  final String? value;
  final String unit;
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.data});

  final _PerformanceRowData data;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          WarehouseGlowBadge(icon: data.icon, color: data.color, size: 38),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.textTertiary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.warehouse?.name ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.cardTitle(context).copyWith(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (data.value != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data.value!,
                  maxLines: 1,
                  style: WmsDesignTokens.cardNumber(context).copyWith(
                    color: data.color,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    letterSpacing: -0.4,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.unit,
                  maxLines: 1,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.textTertiary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail sheet
// ─────────────────────────────────────────────────────────────────────────────

class WarehouseDetailSheet extends StatelessWidget {
  const WarehouseDetailSheet({super.key, required this.warehouse});

  final Warehouse warehouse;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;
    final pct = warehouse.utilizationPercent;
    final band = WarehouseCapacityBand.fromPercent(pct);
    final bandColor = palette.bandColor(band);

    return Container(
      decoration: BoxDecoration(
        gradient: palette.surfaceGradient,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
        border: palette.glassBorder(),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.screenPadding + MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textTertiary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WarehouseGradientTile(initials: warehouse.initials, size: 56),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warehouse.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WmsDesignTokens.sectionTitle(context).copyWith(
                          color: colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.place_rounded,
                            size: 13,
                            color: colors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              warehouse.location.isEmpty
                                  ? 'No location set'
                                  : warehouse.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  WmsDesignTokens.supporting(context).copyWith(
                                color: colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                WarehouseStatusBadge(status: warehouse.statusLabel),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'CAPACITY USED',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: colors.textTertiary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$pct%',
                  style: WmsDesignTokens.cardNumber(context).copyWith(
                    color: bandColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            WarehouseCapacityMeter(percent: pct),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: WarehouseMetricBox(
                    label: 'Capacity',
                    value: WmsFormatters.quantity(warehouse.capacity),
                    icon: Icons.dashboard_customize_rounded,
                    color: palette.accentIndigo,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: WarehouseMetricBox(
                    label: 'Stored',
                    value: WmsFormatters.quantity(warehouse.totalUnits),
                    icon: Icons.inventory_2_rounded,
                    color: palette.accentBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: WarehouseMetricBox(
                    label: 'Available',
                    value: WmsFormatters.quantity(warehouse.availableCapacity),
                    icon: Icons.check_circle_rounded,
                    color: palette.accentEmerald,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: WarehouseMetricBox(
                    label: 'Inventory Lines',
                    value: '${warehouse.lineCount}',
                    icon: Icons.list_alt_rounded,
                    color: palette.accentTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(
                  Icons.groups_rounded,
                  size: 16,
                  color: palette.accentViolet,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Assigned Staff',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.cardTitle(context).copyWith(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                WarehouseTonePill(
                  label: '${warehouse.staffCount}',
                  color: palette.accentViolet,
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (warehouse.assignedStaff.isEmpty)
              Text(
                'No staff assigned to this warehouse yet.',
                style: WmsDesignTokens.supporting(context).copyWith(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final staff in warehouse.assignedStaff)
                    _StaffChip(name: staff.displayName),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StaffChip extends StatelessWidget {
  const _StaffChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: palette.insetFill,
        borderRadius: BorderRadius.circular(WarehousePalette.radiusPill),
        border: palette.glassBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: palette.brandGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showWarehouseDetailSheet(BuildContext context, Warehouse warehouse) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: WmsUiColors.of(context).isDark
        ? Colors.black.withValues(alpha: 0.62)
        : const Color(0xFF0F172A).withValues(alpha: 0.38),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.88,
    ),
    builder: (context) => WarehouseDetailSheet(warehouse: warehouse),
  );
}
