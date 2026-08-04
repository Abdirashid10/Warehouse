import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_chart_theme.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_dashboard_section.dart';

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
    final colors = WmsUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warehouse_outlined, size: WmsIconSizes.status, color: colors.primary),
            const SizedBox(width: 4),
            Text(
              'INFRASTRUCTURE',
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            Icon(Icons.chevron_right, size: WmsIconSizes.listLeading, color: colors.textTertiary),
            Text(
              'WAREHOUSES',
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Warehouses',
          style: WmsDesignTokens.pageTitle(context).copyWith(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Infrastructure & Capacity Control',
          style: WmsDesignTokens.body(context).copyWith(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        if (canManage) ...[
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              icon: const Icon(Icons.add, size: WmsIconSizes.actionButton),
              label: Text(
                'Add Warehouse',
                style: WmsDesignTokens.body(context).copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class WarehousesKpiStrip extends StatelessWidget {
  const WarehousesKpiStrip({super.key, required this.summary});

  final WarehousesSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final items = [
      _KpiDef(
        'Total Warehouses',
        '${summary.totalWarehouses}',
        Icons.warehouse_outlined,
        const Color(0xFF60A5FA),
        const Color(0xFF1E3A8A),
      ),
      _KpiDef(
        'Total Units Stored',
        WmsFormatters.quantity(summary.totalUnitsStored),
        Icons.inventory_2_outlined,
        colors.success,
        const Color(0xFF14532D),
      ),
      _KpiDef(
        'Total Staff',
        '${summary.totalStaff}',
        Icons.groups_outlined,
        const Color(0xFFA78BFA),
        const Color(0xFF4C1D95),
      ),
      _KpiDef(
        'Avg Capacity Used',
        '${summary.averageCapacityUsed}%',
        Icons.speed_outlined,
        colors.primary,
        colors.primaryMuted,
      ),
    ];

    return SizedBox(
      height: MobileUi.horizontalKpiStripHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) => _KpiCard(item: items[i]),
      ),
    );
  }
}

class _KpiDef {
  const _KpiDef(
    this.label,
    this.value,
    this.icon,
    this.iconColor,
    this.iconBg,
  );

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});

  final _KpiDef item;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(
                item.icon,
                size: WmsIconSizes.listLeading,
                color: item.iconColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: colors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.body(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
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
    final colors = WmsUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Search & Filters',
          style: WmsDesignTokens.sectionTitle(context).copyWith(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SearchField(
          controller: nameController,
          onChanged: onNameSearch,
          hint: 'Search by Warehouse Name',
          icon: Icons.warehouse_outlined,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SearchField(
          controller: locationController,
          onChanged: onLocationSearch,
          hint: 'Search by Location',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onToggleFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: showFilters || activeFilterCount > 0
                      ? colors.primary
                      : colors.textSecondary,
                  side: BorderSide(
                    color: showFilters || activeFilterCount > 0
                        ? colors.primary.withValues(alpha: 0.5)
                        : colors.border,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.filter_list, size: WmsIconSizes.actionButton),
                label: Text(
                  activeFilterCount > 0
                      ? 'Filters ($activeFilterCount)'
                      : 'Filters',
                ),
              ),
            ),
            if (activeFilterCount > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                onPressed: onClearFilters,
                icon: Icon(Icons.clear, color: colors.textTertiary),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$displayCount of $totalCount warehouses',
          style: WmsDesignTokens.supporting(context).copyWith(
            color: colors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.hint,
    required this.icon,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: WmsDesignTokens.body(context).copyWith(
        color: colors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textTertiary, fontSize: 14),
        prefixIcon: Icon(icon, color: colors.textTertiary, size: WmsIconSizes.search),
        filled: true,
        fillColor: colors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
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
    (WarehouseCapacityFilter.active, 'Active'),
    (WarehouseCapacityFilter.lowCapacity, 'Low Capacity'),
    (WarehouseCapacityFilter.highCapacity, 'High Capacity'),
    (WarehouseCapacityFilter.full, 'Full'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.border),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final (filter, label) in filters)
            FilterChip(
              label: Text(label),
              selected: selected == filter,
              onSelected: (value) =>
                  onSelected(value ? filter : null),
              showCheckmark: false,
              labelStyle: WmsDesignTokens.body(context).copyWith(
                fontWeight:
                    selected == filter ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }
}

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
    final colors = WmsUiColors.of(context);
    final pct = warehouse.utilizationPercent;
    final barColor = _utilizationColor(pct, colors);

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WarehouseAvatar(name: warehouse.name, initials: warehouse.initials),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warehouse.name,
                        style: WmsDesignTokens.body(context).copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: WmsIconSizes.status,
                            color: colors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              warehouse.location,
                              style: WmsDesignTokens.supporting(context).copyWith(
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
                WarehouseStatusBadge(status: warehouse.statusLabel),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Capacity Used',
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textSecondary,
                fontSize: 12,
                  ),
                ),
                Text(
                  '$pct% Capacity Used',
                  style: WmsDesignTokens.body(context).copyWith(
                    color: barColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 8,
                backgroundColor: colors.surfaceElevated,
                color: barColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Stored Units',
                    value: WmsFormatters.quantity(warehouse.totalUnits),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatTile(
                    label: 'Staff',
                    value: '${warehouse.staffCount}',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatTile(
                    label: 'Available',
                    value: WmsFormatters.quantity(warehouse.availableCapacity),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _ActionChip(
                  icon: Icons.visibility_outlined,
                  label: 'View',
                  onTap: onView,
                ),
                if (canManage) ...[
                  _ActionChip(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onTap: onEdit,
                  ),
                  _ActionChip(
                    icon: Icons.swap_horiz,
                    label: 'Transfer',
                    onTap: onTransfer,
                  ),
                  _ActionChip(
                    icon: Icons.person_add_outlined,
                    label: 'Assign Staff',
                    onTap: onAssignStaff,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _utilizationColor(int pct, WmsUiColors colors) {
    if (pct >= 90) return colors.error;
    if (pct >= 70) return colors.warning;
    if (pct >= 40) return colors.primary;
    return colors.success;
  }
}

class WarehouseAvatar extends StatelessWidget {
  const WarehouseAvatar({
    super.key,
    required this.name,
    required this.initials,
    this.size = 52,
  });

  final String name;
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primaryMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: WmsDesignTokens.body(context).copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}

class WarehouseStatusBadge extends StatelessWidget {
  const WarehouseStatusBadge({super.key, required this.status});

  final WarehouseStatusLabel status;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final (bg, fg, label) = switch (status) {
      WarehouseStatusLabel.active => (
          colors.isDark ? const Color(0xFF14532D) : AppColors.successLight,
          colors.success,
          'Active',
        ),
      WarehouseStatusLabel.warning => (
          colors.isDark ? const Color(0xFF78350F) : AppColors.warningLight,
          colors.warning,
          'Warning',
        ),
      WarehouseStatusLabel.full => (
          colors.isDark ? const Color(0xFF7F1D1D) : AppColors.errorLight,
          colors.error,
          'Full',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: WmsDesignTokens.supportingDense(context).copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: colors.textTertiary,
                        fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: WmsDesignTokens.body(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Material(
      color: colors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: WmsIconSizes.status, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: WmsDesignTokens.supportingDense(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WarehousesPerformanceSection extends StatelessWidget {
  const WarehousesPerformanceSection({super.key, required this.rankings});

  final WarehousePerformanceRankings rankings;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Warehouse Performance',
          style: WmsDesignTokens.sectionTitle(context).copyWith(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          elevated: true,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _RankRow(
                icon: Icons.trending_up,
                label: 'Top Utilized Warehouse',
                warehouse: rankings.topUtilized,
                trailing: rankings.topUtilized != null
                    ? '${rankings.topUtilized!.utilizationPercent}%'
                    : null,
              ),
              const Divider(height: AppSpacing.lg),
              _RankRow(
                icon: Icons.trending_down,
                label: 'Lowest Utilized Warehouse',
                warehouse: rankings.lowestUtilized,
                trailing: rankings.lowestUtilized != null
                    ? '${rankings.lowestUtilized!.utilizationPercent}%'
                    : null,
              ),
              const Divider(height: AppSpacing.lg),
              _RankRow(
                icon: Icons.square_foot,
                label: 'Largest Warehouse',
                warehouse: rankings.largest,
                trailing: rankings.largest != null
                    ? WmsFormatters.quantity(rankings.largest!.capacity)
                    : null,
              ),
              const Divider(height: AppSpacing.lg),
              _RankRow(
                icon: Icons.local_shipping_outlined,
                label: 'Most Active Warehouse',
                warehouse: rankings.mostActive,
                trailing: rankings.mostActive != null
                    ? '${WmsFormatters.quantity(rankings.mostActive!.totalUnits)} units'
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.icon,
    required this.label,
    required this.warehouse,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Warehouse? warehouse;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Row(
      children: [
        Icon(icon, size: WmsIconSizes.kpi, color: colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textSecondary,
                fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                warehouse?.name ?? '—',
                style: WmsDesignTokens.body(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: WmsDesignTokens.body(context).copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}

class WarehouseDetailSheet extends StatelessWidget {
  const WarehouseDetailSheet({super.key, required this.warehouse});

  final Warehouse warehouse;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.screenPadding + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WarehouseAvatar(name: warehouse.name, initials: warehouse.initials),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warehouse.name,
                      style: WmsDesignTokens.sectionTitle(context).copyWith(
                        fontSize: 16,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      warehouse.location,
                      style: WmsDesignTokens.supporting(context).copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              WarehouseStatusBadge(status: warehouse.statusLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailRow('Capacity', WmsFormatters.quantity(warehouse.capacity)),
          _DetailRow('Stored Units', WmsFormatters.quantity(warehouse.totalUnits)),
          _DetailRow(
            'Available',
            WmsFormatters.quantity(warehouse.availableCapacity),
          ),
          _DetailRow('Utilization', '${warehouse.utilizationPercent}%'),
          _DetailRow('Staff Assigned', '${warehouse.staffCount}'),
          _DetailRow('Inventory Lines', '${warehouse.lineCount}'),
          if (warehouse.assignedStaff.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Assigned Staff',
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final s in warehouse.assignedStaff)
                  Chip(
                    label: Text(s.displayName),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: WmsDesignTokens.supporting(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: WmsDesignTokens.body(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
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
    backgroundColor: WmsUiColors.of(context).surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (context) => WarehouseDetailSheet(warehouse: warehouse),
  );
}

class WarehousesAnalyticsSection extends StatelessWidget {
  const WarehousesAnalyticsSection({super.key, required this.warehouses});

  final List<Warehouse> warehouses;

  @override
  Widget build(BuildContext context) {
    final chart = WmsChartTheme.of(context);
    return WmsDashboardSection(
      title: 'Warehouse Analytics',
      child: AppCard(
        elevated: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Warehouse Utilization',
              style: WmsDesignTokens.cardTitle(context).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Capacity utilization by warehouse',
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: chart.colors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            WarehouseUtilizationChart(warehouses: warehouses),
          ],
        ),
      ),
    );
  }
}

class WarehouseUtilizationChart extends StatelessWidget {
  const WarehouseUtilizationChart({super.key, required this.warehouses});

  final List<Warehouse> warehouses;

  static const chartHeight = 160.0;

  @override
  Widget build(BuildContext context) {
    final chart = WmsChartTheme.of(context);
    final display = [...warehouses]
      ..sort((a, b) => b.utilizationPercent.compareTo(a.utilizationPercent));
    final top = display.take(6).toList();

    if (top.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No utilization data available',
            style: chart.emptyMessageStyle,
          ),
        ),
      );
    }

    final maxY = top.fold<double>(
      0,
      (m, w) => math.max(m, w.utilizationPercent.toDouble()),
    );

    return SizedBox(
      height: chartHeight,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 100 : math.min(100, maxY * 1.15),
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
                reservedSize: 28,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}%',
                  style: chart.axisLabelStyle,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= top.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      top[i].name,
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
            for (var i = 0; i < top.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: top[i].utilizationPercent.toDouble(),
                    width: top.length > 4 ? 14 : 18,
                    borderRadius: BorderRadius.circular(4),
                    color: _barColor(top[i].utilizationPercent, chart.colors),
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }

  static Color _barColor(int pct, WmsUiColors colors) {
    if (pct >= 90) return colors.error;
    if (pct >= 70) return colors.warning;
    if (pct >= 40) return colors.primary;
    return colors.success;
  }
}
