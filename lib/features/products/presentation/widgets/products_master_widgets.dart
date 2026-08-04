import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/products/domain/entities/product_category.dart';
import 'package:logisticsmobile/features/products/domain/entities/products_summary.dart';
import 'package:logisticsmobile/features/products/presentation/widgets/product_form_sheet.dart';
import 'package:logisticsmobile/widgets/wms/wms_catalog_primitives.dart';

class ProductsPageHeader extends StatelessWidget {
  const ProductsPageHeader({
    super.key,
    required this.canManage,
    required this.onAdd,
  });

  final bool canManage;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: WmsIconSizes.status, color: primary),
            const SizedBox(width: 4),
            Text(
              'MASTER DATA',
              style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: wms.textTertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
            ),
            Icon(Icons.chevron_right, size: WmsIconSizes.listLeading, color: wms.textTertiary),
            Text(
              'PRODUCTS',
              style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: wms.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const WmsCatalogPageHeader(
          title: 'Products',
          subtitle:
              'Centralized product master data with inventory intelligence and warehouse stock visibility.',
        ),
        if (canManage) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: WmsIconSizes.actionButton),
              label: const Text('Add Product'),
            ),
          ),
        ],
      ],
    );
  }
}

class ProductsKpiStrip extends StatelessWidget {
  const ProductsKpiStrip({
    super.key,
    required this.summary,
    this.onLowStock,
    this.onOutOfStock,
  });

  final ProductsSummary summary;
  final VoidCallback? onLowStock;
  final VoidCallback? onOutOfStock;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final items = [
      _Kpi('Active', '${summary.total}', Theme.of(context).colorScheme.primary,
          Icons.inventory_2_outlined),
      _Kpi('Categories', '${summary.categories}', wms.tasks, Icons.layers_outlined),
      _Kpi('Low Stock', '${summary.lowStock}', wms.warning,
          Icons.warning_amber_rounded, onLowStock),
      _Kpi('Out', '${summary.outOfStock}', wms.error,
          Icons.remove_shopping_cart_outlined, onOutOfStock),
      _Kpi('Expiring', '${summary.expiring}', wms.info, Icons.schedule_outlined),
      _Kpi('Value', WmsFormatters.currency(summary.totalValue), wms.success,
          Icons.attach_money_rounded),
    ];

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final k = items[i];
          return Material(
            color: wms.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side: BorderSide(color: wms.border),
            ),
            child: InkWell(
              onTap: k.onTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: SizedBox(
                width: 108,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(k.icon, size: WmsIconSizes.status, color: k.color),
                      const Spacer(),
                      Text(
                        k.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WmsDesignTokens.body(context).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                      ),
                      Text(
                        k.label,
                        style: WmsDesignTokens.supportingDense(context).copyWith(
                              color: wms.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value, this.color, this.icon, [this.onTap]);
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
}

class ProductsCategoryChips extends StatelessWidget {
  const ProductsCategoryChips({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ProductCategory> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    final wms = context.wms;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(context, wms, 'All', selectedId == null, () => onSelected(null)),
          for (final c in categories) ...[
            const SizedBox(width: AppSpacing.sm),
            _chip(context, wms, c.name, selectedId == c.id, () => onSelected(c.id)),
          ],
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    WmsThemeExtension wms,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? wms.primaryLight : wms.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? primary.withValues(alpha: 0.4) : wms.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: WmsDesignTokens.supporting(context).copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? primary : null,
                ),
          ),
        ),
      ),
    );
  }
}

class ProductsSearchToolbar extends StatelessWidget {
  const ProductsSearchToolbar({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.activeFilterCount,
    required this.onToggleFilters,
    required this.onClearFilters,
    required this.displayCount,
    required this.totalCount,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final int activeFilterCount;
  final VoidCallback onToggleFilters;
  final VoidCallback onClearFilters;
  final int displayCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: WmsCatalogSearchField(
                controller: controller,
                hintText: 'Search SKU, name, barcode...',
                onChanged: onSearch,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onToggleFilters,
              icon: const Icon(Icons.filter_list, size: WmsIconSizes.actionButton),
              label: Text(activeFilterCount > 0 ? '($activeFilterCount)' : 'Filters'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            if (activeFilterCount > 0)
              TextButton(onPressed: onClearFilters, child: const Text('Clear all')),
            const Spacer(),
            Text(
              '$displayCount of $totalCount products',
              style: WmsDesignTokens.supporting(context).copyWith(
                    color: wms.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class ProductsFiltersPanel extends StatelessWidget {
  const ProductsFiltersPanel({
    super.key,
    required this.categories,
    required this.categoryFilterId,
    required this.statusFilter,
    required this.onCategory,
    required this.onStatus,
  });

  final List<ProductCategory> categories;
  final String? categoryFilterId;
  final String? statusFilter;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onStatus;

  static const statuses = [
    'In Stock',
    'Low Stock',
    'Out Of Stock',
    'No Inventory',
  ];

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: wms.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: wms.border),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String?>(
            initialValue: categoryFilterId?.isEmpty == true ? null : categoryFilterId,
            decoration: const InputDecoration(labelText: 'Category', isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              for (final c in categories)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: onCategory,
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String?>(
            initialValue: statusFilter?.isEmpty == true ? null : statusFilter,
            decoration: const InputDecoration(labelText: 'Stock status', isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              for (final s in statuses)
                DropdownMenuItem(value: s, child: Text(s)),
            ],
            onChanged: onStatus,
          ),
        ],
      ),
    );
  }
}

class ProductCatalogRow extends StatelessWidget {
  const ProductCatalogRow({
    super.key,
    required this.product,
    required this.onTap,
    this.onEdit,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final primary = Theme.of(context).colorScheme.primary;
    final imageUrl = resolveProductImageUrl(product.imageUrl);
    final meta = WmsDesignTokens.supporting(context).copyWith(
      color: wms.textSecondary,
    );

    return WmsCatalogListCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _Thumb(wms: wms),
                  ),
                )
              else
                _Thumb(wms: wms),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.sku,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                            color: primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      product.name,
                      style: WmsDesignTokens.body(context).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (product.description?.isNotEmpty == true)
                      Text(
                        product.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: meta,
                      ),
                  ],
                ),
              ),
              ProductStatusBadge(label: product.stockStatusLabel),
              if (onEdit != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: WmsIconSizes.actionButton, color: wms.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Price ${WmsFormatters.currency(product.unitPrice)}', style: meta),
          Text(
            'Stock ${WmsFormatters.quantity(product.totalStock)} · ${product.warehouseCount ?? 0} warehouses',
            style: meta,
          ),
          if (product.category != null) Text(product.category!, style: meta),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.wms});

  final WmsThemeExtension wms;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: wms.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: wms.border),
      ),
      child: Icon(Icons.image_outlined, size: WmsIconSizes.listLeading, color: wms.textTertiary),
    );
  }
}

class ProductStatusBadge extends StatelessWidget {
  const ProductStatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final (bg, fg) = switch (label) {
      'In Stock' => (wms.successLight, wms.success),
      'Low Stock' => (wms.warningLight, wms.warning),
      'Out Of Stock' => (wms.errorLight, wms.error),
      _ => (wms.surfaceVariant, wms.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
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

// Back-compat aliases for screen imports
typedef ProductsMasterHeader = ProductsPageHeader;
typedef ProductMasterRow = ProductCatalogRow;
