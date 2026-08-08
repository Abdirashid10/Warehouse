import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/constants/wms/stock_constants.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:logisticsmobile/features/inventory/presentation/widgets/inventory_enterprise_widgets.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_badges.dart';
import 'package:logisticsmobile/widgets/wms/wms_metric_pill.dart';
import 'package:logisticsmobile/widgets/wms/wms_premium_cards.dart';

/// Shared geometry for the redesigned inventory surfaces.
abstract final class InventoryMobileUi {
  /// Height of the horizontal metrics strip, including its scroll padding.
  static const double metricsBarHeight = 78;

  /// Width of a single metric pill.
  static const double metricPillWidth = 132;

  /// Height of the compact search / filter row controls.
  static const double controlHeight = 46;

  /// Gap between the stacked surfaces on the page.
  static const double blockGap = AppSpacing.md;

  /// Leading status badge on a product tile.
  static const double tileBadgeSize = 38;
}

// ═══════════════════════════════════════════════════════════════════════════
// Summary metrics — horizontally scrollable strip
// ═══════════════════════════════════════════════════════════════════════════

/// Compact, horizontally scrollable summary bar.
///
/// Replaces the previous eight-tile vertical grid, which occupied four full
/// rows before a single product was visible. Every metric that maps to a stock
/// status doubles as a filter toggle, so the strip is a control surface rather
/// than a static readout.
class InventoryMetricsBar extends StatelessWidget {
  const InventoryMetricsBar({
    super.key,
    required this.data,
    this.onStockFilter,
  });

  final InventoryViewState data;
  final ValueChanged<String?>? onStockFilter;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final metrics = <_MetricSpec>[
      _MetricSpec(
        label: 'Total Units',
        value: WmsFormatters.quantity(data.summary.totalUnits),
        color: colors.info,
        icon: Icons.inventory_2_outlined,
      ),
      _MetricSpec(
        label: 'In Stock',
        value: '${data.summary.inStock}',
        color: colors.success,
        icon: Icons.check_circle_outline,
        filter: WmsStockStatuses.inStock,
      ),
      _MetricSpec(
        label: 'Low Stock',
        value: '${data.summary.lowStock}',
        color: colors.warning,
        icon: Icons.warning_amber_rounded,
        filter: WmsStockStatuses.lowStock,
      ),
      _MetricSpec(
        label: 'Out of Stock',
        value: '${data.summary.outOfStock}',
        color: colors.error,
        icon: Icons.remove_shopping_cart_outlined,
        filter: WmsStockStatuses.outOfStock,
      ),
      _MetricSpec(
        label: 'Expired',
        value: '${data.expiredCount}',
        color: InventoryUi.expiredPurple,
        icon: Icons.event_busy_outlined,
        filter: WmsStockStatuses.expired,
      ),
      _MetricSpec(
        label: 'Expiring Soon',
        value: '${data.expiringSoonCount}',
        color: colors.warning,
        icon: Icons.schedule_outlined,
      ),
      _MetricSpec(
        label: 'Expiring 30D',
        value: '${data.expiring30DaysCount}',
        color: colors.info,
        icon: Icons.date_range_outlined,
      ),
      _MetricSpec(
        label: 'Safe',
        value: '${data.safeCount}',
        color: colors.success,
        icon: Icons.verified_outlined,
      ),
    ];

    return WmsMetricPillBar(
      metrics: [
        for (final metric in metrics)
          () {
            final selected =
                metric.filter != null && data.stockFilter == metric.filter;
            return WmsMetricPillData(
              label: metric.label,
              value: metric.value,
              icon: metric.icon,
              color: metric.color,
              selected: selected,
              onTap: metric.filter == null || onStockFilter == null
                  ? null
                  // Tapping the active metric clears the filter.
                  : () => onStockFilter!(selected ? null : metric.filter),
            );
          }(),
      ],
    );
  }
}

class _MetricSpec {
  const _MetricSpec({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.filter,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  /// Stock status this metric filters by, when it maps to one.
  final String? filter;
}

// ═══════════════════════════════════════════════════════════════════════════
// Search + filter bar
// ═══════════════════════════════════════════════════════════════════════════

/// Compact search field paired with a filter button that opens a bottom sheet.
///
/// Replaces the always-expanded filter panel, which stacked a search bar and
/// three labelled chip rows inside a card. Active filters stay visible as
/// removable chips so nothing is hidden behind the sheet.
class InventoryFilterBar extends StatelessWidget {
  const InventoryFilterBar({
    super.key,
    required this.data,
    required this.searchController,
    required this.onSearch,
    required this.onWarehouse,
    required this.onCategory,
    required this.onStockFilter,
    required this.onSort,
  });

  final InventoryViewState data;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onWarehouse;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onStockFilter;
  final ValueChanged<InventorySortField> onSort;

  int get _activeCount => [
        data.warehouseId,
        data.categoryFilter,
        data.stockFilter,
      ].where((f) => f != null && f.isNotEmpty).length;

  String? _warehouseName() {
    final id = data.warehouseId;
    if (id == null) return null;
    for (final w in data.warehouses) {
      if (w.id == id) return w.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final activeCount = _activeCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: InventoryMobileUi.controlHeight,
                child: TextField(
                  controller: searchController,
                  onChanged: onSearch,
                  textInputAction: TextInputAction.search,
                  style: WmsDesignTokens.body(context),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search product, SKU, barcode',
                    hintStyle: WmsDesignTokens.description(context),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: wms.textSecondary,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    suffixIcon: data.searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              searchController.clear();
                              onSearch('');
                            },
                          ),
                    filled: true,
                    fillColor: wms.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide(
                        color: wms.border.withValues(alpha: 0.7),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterButton(
              activeCount: activeCount,
              onTap: () => _openFilterSheet(context),
            ),
          ],
        ),
        if (activeCount > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          _ActiveFilterChips(
            warehouseLabel: _warehouseName(),
            categoryLabel: data.categoryFilter,
            statusLabel: data.stockFilter,
            onClearWarehouse: () => onWarehouse(null),
            onClearCategory: () => onCategory(null),
            onClearStatus: () => onStockFilter(null),
            onClearAll: () {
              onWarehouse(null);
              onCategory(null);
              onStockFilter(null);
            },
          ),
        ],
      ],
    );
  }

  Future<void> _openFilterSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (sheetContext) => InventoryFilterSheet(
        data: data,
        onWarehouse: onWarehouse,
        onCategory: onCategory,
        onStockFilter: onStockFilter,
        onSort: onSort,
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final primary = Theme.of(context).colorScheme.primary;
    final active = activeCount > 0;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);

    return Material(
      color: active ? wms.primaryLight : wms.surfaceVariant,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: InventoryMobileUi.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: active
                  ? primary.withValues(alpha: 0.35)
                  : wms.border.withValues(alpha: 0.7),
              width: active ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: active ? primary : wms.textSecondary,
              ),
              if (active) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$activeCount',
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.warehouseLabel,
    required this.categoryLabel,
    required this.statusLabel,
    required this.onClearWarehouse,
    required this.onClearCategory,
    required this.onClearStatus,
    required this.onClearAll,
  });

  final String? warehouseLabel;
  final String? categoryLabel;
  final String? statusLabel;
  final VoidCallback onClearWarehouse;
  final VoidCallback onClearCategory;
  final VoidCallback onClearStatus;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final entries = <({String label, IconData icon, VoidCallback onClear})>[
      if (statusLabel != null && statusLabel!.isNotEmpty)
        (
          label: statusLabel!,
          icon: Icons.flag_outlined,
          onClear: onClearStatus,
        ),
      if (warehouseLabel != null && warehouseLabel!.isNotEmpty)
        (
          label: warehouseLabel!,
          icon: Icons.warehouse_outlined,
          onClear: onClearWarehouse,
        ),
      if (categoryLabel != null && categoryLabel!.isNotEmpty)
        (
          label: categoryLabel!,
          icon: Icons.category_outlined,
          onClear: onClearCategory,
        ),
    ];

    if (entries.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          if (index == entries.length) {
            return TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                'Clear all',
                style: WmsDesignTokens.supportingDense(context).copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }
          final entry = entries[index];
          return _ActiveChip(
            label: entry.label,
            icon: entry.icon,
            onClear: entry.onClear,
          );
        },
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({
    required this.label,
    required this.icon,
    required this.onClear,
  });

  final String label;
  final IconData icon;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final wms = context.wms;

    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.sm, right: 2),
      decoration: BoxDecoration(
        color: wms.primaryLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: primary),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: Icon(Icons.close_rounded, size: 14, color: primary),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            tooltip: 'Remove filter',
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet holding every filter and the sort order.
class InventoryFilterSheet extends StatelessWidget {
  const InventoryFilterSheet({
    super.key,
    required this.data,
    required this.onWarehouse,
    required this.onCategory,
    required this.onStockFilter,
    required this.onSort,
  });

  final InventoryViewState data;
  final ValueChanged<String?> onWarehouse;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onStockFilter;
  final ValueChanged<InventorySortField> onSort;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filters & Sort',
                      style: WmsDesignTokens.sectionTitle(context)
                          .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      onStockFilter(null);
                      onWarehouse(null);
                      onCategory(null);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SheetGroup(
                        label: 'Stock status',
                        child: _OptionWrap(
                          options: WmsStockStatuses.all,
                          selected: data.stockFilter,
                          allLabel: 'All statuses',
                          onSelected: onStockFilter,
                        ),
                      ),
                      _SheetGroup(
                        label: 'Warehouse',
                        child: _OptionWrap(
                          options: [for (final w in data.warehouses) w.name],
                          values: [for (final w in data.warehouses) w.id],
                          selected: data.warehouseId,
                          allLabel: 'All warehouses',
                          onSelected: onWarehouse,
                        ),
                      ),
                      _SheetGroup(
                        label: 'Category',
                        child: _OptionWrap(
                          options: data.allCategories,
                          selected: data.categoryFilter,
                          allLabel: 'All categories',
                          onSelected: onCategory,
                        ),
                      ),
                      _SheetGroup(
                        label: 'Sort by',
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final field in InventorySortField.values)
                              ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(field.label),
                                    if (data.sortField == field) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        data.sortAscending
                                            ? Icons.arrow_upward_rounded
                                            : Icons.arrow_downward_rounded,
                                        size: 14,
                                      ),
                                    ],
                                  ],
                                ),
                                selected: data.sortField == field,
                                showCheckmark: false,
                                visualDensity: VisualDensity.compact,
                                onSelected: (_) => onSort(field),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: const Text('Show results'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetGroup extends StatelessWidget {
  const _SheetGroup({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: WmsDesignTokens.supportingDense(context).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// Wrapped choice chips with a leading "all" option.
///
/// [values] lets the visible label differ from the emitted value (warehouse
/// name shown, warehouse id emitted).
class _OptionWrap extends StatelessWidget {
  const _OptionWrap({
    required this.options,
    required this.selected,
    required this.allLabel,
    required this.onSelected,
    this.values,
  });

  final List<String> options;
  final List<String>? values;
  final String? selected;
  final String allLabel;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        ChoiceChip(
          label: Text(allLabel),
          selected: selected == null || selected!.isEmpty,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          onSelected: (_) => onSelected(null),
        ),
        for (var i = 0; i < options.length; i++)
          ChoiceChip(
            label: Text(options[i]),
            selected: selected == (values != null ? values![i] : options[i]),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            onSelected: (_) =>
                onSelected(values != null ? values![i] : options[i]),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Results bar
// ═══════════════════════════════════════════════════════════════════════════

/// Single row carrying the result count and the active sort.
///
/// Folds together the old "Product Inventory" section header and the separate
/// sort chip strip, which between them consumed roughly 100dp.
class InventoryResultsBar extends StatelessWidget {
  const InventoryResultsBar({
    super.key,
    required this.count,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
  });

  final int count;
  final InventorySortField sortField;
  final bool sortAscending;
  final ValueChanged<InventorySortField> onSort;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;

    return Row(
      children: [
        Expanded(
          child: Text(
            count == 1 ? '1 product' : '$count products',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.supportingDense(context).copyWith(
              fontWeight: FontWeight.w600,
              color: wms.textSecondary,
            ),
          ),
        ),
        PopupMenuButton<InventorySortField>(
          onSelected: onSort,
          tooltip: 'Change sort order',
          position: PopupMenuPosition.under,
          itemBuilder: (context) => [
            for (final field in InventorySortField.values)
              PopupMenuItem(
                value: field,
                child: Row(
                  children: [
                    Icon(field.icon, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(field.label)),
                    if (sortField == field)
                      Icon(
                        sortAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 16,
                      ),
                  ],
                ),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_vert_rounded, size: 16, color: wms.textSecondary),
                const SizedBox(width: 4),
                Text(
                  sortField.label,
                  maxLines: 1,
                  softWrap: false,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: wms.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Product tile
// ═══════════════════════════════════════════════════════════════════════════

/// Compact inventory list tile.
///
/// The previous card stacked eleven labelled fields vertically — roughly 380dp
/// per product, so barely one item fit on screen. This tile carries the same
/// primary information in about a quarter of the height: identity and status on
/// the first row, quantities on a single divided stat row. Full detail stays one
/// tap away in the existing detail sheet.
///
/// Every text run is single-line with ellipsis, which is what fixes the ragged
/// wrapping the old two-line fields produced on narrow screens.
class InventoryProductTile extends StatelessWidget {
  const InventoryProductTile({
    super.key,
    required this.item,
    required this.availableQuantity,
    required this.reservedQuantity,
    required this.lastUpdated,
    required this.onTap,
    this.selected = false,
    this.selectionMode = false,
    this.onSelected,
  });

  final InventoryItem item;
  final num availableQuantity;
  final num reservedQuantity;
  final DateTime? lastUpdated;
  final VoidCallback onTap;
  final bool selected;
  final bool selectionMode;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final wms = context.wms;
    final status = InventoryUi.displayStatus(item);
    final accent = InventoryUi.indicatorColor(status, WmsUiColors.of(context));
    final expired = InventoryUi.isExpired(item);

    return AppCard(
      elevated: true,
      onTap: selectionMode ? () => onSelected?.call(!selected) : onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: selected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.45)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (selectionMode) ...[
                SizedBox(
                  width: 28,
                  child: Checkbox(
                    value: selected,
                    onChanged: (v) => onSelected?.call(v ?? false),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ] else ...[
                WmsPremiumIconBadge(
                  icon: WmsStockStatusBadge.iconFor(status),
                  color: accent,
                  size: InventoryMobileUi.tileBadgeSize,
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.productName,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.cardTitle(context).copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.sku} · ${item.warehouseName}',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: wms.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              WmsStockStatusBadge(status: status, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, thickness: 0.8, color: wms.border.withValues(alpha: 0.6)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _TileStat(
                label: 'On hand',
                value: WmsFormatters.quantity(item.quantity),
              ),
              _TileStat(
                label: 'Available',
                value: WmsFormatters.quantity(availableQuantity),
                valueColor:
                    availableQuantity > 0 ? colors.success : colors.error,
              ),
              _TileStat(
                label: 'Reserved',
                value: WmsFormatters.quantity(reservedQuantity),
              ),
              _TileStat(
                label: expired ? 'Expired' : 'Updated',
                value: expired
                    ? WmsFormatters.notificationTimestamp(item.expiryDate)
                    : (lastUpdated != null
                        ? WmsFormatters.relativeTime(lastUpdated)
                        : '—'),
                valueColor: expired ? InventoryUi.expiredPurple : null,
                alignEnd: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One cell of the tile's stat row. Equal-width so the row stays a clean grid
/// regardless of value length; values scale down rather than wrap.
class _TileStat extends StatelessWidget {
  const _TileStat({
    required this.label,
    required this.value,
    this.valueColor,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final align =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.end : TextAlign.start;
    final boxAlign = alignEnd ? Alignment.centerRight : Alignment.centerLeft;

    return Expanded(
      child: Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: WmsDesignTokens.supportingDense(context).copyWith(
              fontSize: 11,
              color: wms.textSecondary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: boxAlign,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: WmsDesignTokens.body(context).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
