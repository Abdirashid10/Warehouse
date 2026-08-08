import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/constants/wms/stock_constants.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_badge_colors.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/app_typography.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/products/domain/entities/products_summary.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/products/domain/entities/product_category.dart';
import 'package:logisticsmobile/features/products/presentation/cubit/products_catalog_cubit.dart';
import 'package:logisticsmobile/features/products/presentation/widgets/product_form_sheet.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_metric_pill.dart';

class ProductsEnterpriseHeader extends StatelessWidget {
  const ProductsEnterpriseHeader({
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
            Icon(
              Icons.inventory_2_outlined,
              size: WmsIconSizes.status,
              color: colors.primary,
            ),
            const SizedBox(width: WmsIconSizes.iconLabelGap),
            Text(
              'MASTER DATA',
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: WmsIconSizes.listLeading,
              color: colors.textTertiary,
            ),
            Text(
              'PRODUCTS',
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Products',
          style: WmsDesignTokens.pageTitle(
            context,
          ).copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Centralized product master data with inventory intelligence and warehouse stock visibility.',
          style: WmsDesignTokens.body(
            context,
          ).copyWith(color: colors.textSecondary, fontSize: 14, height: 1.5),
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
                'Add Product',
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

class ProductsEnterpriseKpiStrip extends StatelessWidget {
  const ProductsEnterpriseKpiStrip({
    super.key,
    required this.summary,
    this.categoryCount = 0,
    this.onLowStock,
    this.onOutOfStock,
  });

  final ProductsSummary summary;
  final int categoryCount;
  final VoidCallback? onLowStock;
  final VoidCallback? onOutOfStock;

  @override
  Widget build(BuildContext context) {
    final categoriesValue = summary.categories > 0
        ? summary.categories
        : categoryCount;
    final colors = WmsUiColors.of(context);
    final items = [
      _KpiDef(
        'Active Products',
        '${summary.total}',
        Icons.inventory_2_outlined,
        const Color(0xFF60A5FA),
        const Color(0xFF1E3A8A),
      ),
      _KpiDef(
        'Categories',
        '$categoriesValue',
        Icons.layers_outlined,
        const Color(0xFFA78BFA),
        const Color(0xFF4C1D95),
      ),
      _KpiDef(
        'Low Stock',
        '${summary.lowStock}',
        Icons.warning_amber_rounded,
        const Color(0xFFFBBF24),
        const Color(0xFF78350F),
        onLowStock,
      ),
      _KpiDef(
        'Out Of Stock',
        '${summary.outOfStock}',
        Icons.remove_shopping_cart_outlined,
        colors.error,
        const Color(0xFF7F1D1D),
        onOutOfStock,
      ),
      _KpiDef(
        'Expiring',
        '${summary.expiring}',
        Icons.schedule_outlined,
        colors.outbound,
        const Color(0xFF7C2D12),
      ),
      _KpiDef(
        'Catalog Value',
        WmsFormatters.currency(summary.totalValue),
        Icons.attach_money_rounded,
        colors.success,
        const Color(0xFF14532D),
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
    this.iconBg, [
    this.onTap,
  ]);

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback? onTap;
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
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
      ),
    );
  }
}

class ProductsEnterpriseSearchPanel extends StatelessWidget {
  const ProductsEnterpriseSearchPanel({
    super.key,
    required this.skuController,
    required this.nameController,
    required this.barcodeController,
    required this.onSkuSearch,
    required this.onNameSearch,
    required this.onBarcodeSearch,
    required this.activeFilterCount,
    required this.showFilters,
    required this.onToggleFilters,
    required this.onClearFilters,
    required this.displayCount,
    required this.totalCount,
  });

  final TextEditingController skuController;
  final TextEditingController nameController;
  final TextEditingController barcodeController;
  final ValueChanged<String> onSkuSearch;
  final ValueChanged<String> onNameSearch;
  final ValueChanged<String> onBarcodeSearch;
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
          controller: skuController,
          onChanged: onSkuSearch,
          hint: 'Search by SKU',
          icon: Icons.qr_code_2_outlined,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SearchField(
          controller: nameController,
          onChanged: onNameSearch,
          hint: 'Search by Product Name',
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SearchField(
          controller: barcodeController,
          onChanged: onBarcodeSearch,
          hint: 'Search by Barcode',
          icon: Icons.barcode_reader,
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
                icon: const Icon(
                  Icons.filter_list,
                  size: WmsIconSizes.actionButton,
                ),
                label: Text(
                  activeFilterCount > 0
                      ? 'Filters ($activeFilterCount)'
                      : 'Filters',
                  style: WmsDesignTokens.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
            if (activeFilterCount > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: 'Clear filters',
                onPressed: onClearFilters,
                icon: Icon(
                  Icons.clear,
                  color: colors.textTertiary,
                  size: WmsIconSizes.search,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$displayCount of $totalCount products',
          style: WmsDesignTokens.supporting(
            context,
          ).copyWith(color: colors.textSecondary, fontSize: 13),
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
      style: WmsDesignTokens.body(
        context,
      ).copyWith(color: colors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textTertiary, fontSize: 14),
        prefixIcon: Icon(
          icon,
          color: colors.textTertiary,
          size: WmsIconSizes.search,
        ),
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

class ProductsEnterpriseFiltersPanel extends StatelessWidget {
  const ProductsEnterpriseFiltersPanel({
    super.key,
    required this.categories,
    required this.warehouses,
    required this.categoryFilterId,
    required this.warehouseFilterId,
    required this.statusFilter,
    required this.warehouseFilterLoading,
    required this.onCategory,
    required this.onWarehouse,
    required this.onStatus,
  });

  final List<ProductCategory> categories;
  final List<WarehouseOption> warehouses;
  final String? categoryFilterId;
  final String? warehouseFilterId;
  final String? statusFilter;
  final bool warehouseFilterLoading;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onWarehouse;
  final ValueChanged<String?> onStatus;

  static const statuses = [
    'In Stock',
    'Low Stock',
    'Out Of Stock',
    'Expired',
    'No Inventory',
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
      child: Column(
        children: [
          _FilterDropdown(
            label: 'Category',
            value: categoryFilterId?.isEmpty == true ? null : categoryFilterId,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('All')),
              for (final c in categories)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: onCategory,
          ),
          const SizedBox(height: AppSpacing.md),
          _FilterDropdown(
            label: 'Warehouse',
            value: warehouseFilterId?.isEmpty == true
                ? null
                : warehouseFilterId,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('All')),
              for (final w in warehouses)
                DropdownMenuItem(value: w.id, child: Text(w.name)),
            ],
            onChanged: warehouseFilterLoading ? null : onWarehouse,
          ),
          if (warehouseFilterLoading) ...[
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              color: colors.primary,
              backgroundColor: colors.border,
              minHeight: 2,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _FilterDropdown(
            label: 'Status',
            value: statusFilter?.isEmpty == true ? null : statusFilter,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('All')),
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

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
  });

  final String label;
  final String? value;
  final List<DropdownMenuItem<String?>> items;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        labelStyle: TextStyle(color: colors.textSecondary),
      ),
      dropdownColor: colors.surfaceElevated,
      style: TextStyle(color: colors.textPrimary),
      items: items,
      onChanged: onChanged,
    );
  }
}

class ProductsEnterpriseCard extends StatelessWidget {
  const ProductsEnterpriseCard({
    super.key,
    required this.product,
    required this.canManage,
    required this.isAdmin,
    required this.onView,
    required this.onEdit,
    required this.onStockHistory,
    required this.onTransfer,
    this.onDelete,
  });

  final Product product;
  final bool canManage;
  final bool isAdmin;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onStockHistory;
  final VoidCallback onTransfer;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final imageUrl = resolveProductImageUrl(product.imageUrl);

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductImage(imageUrl: imageUrl, size: 64),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: WmsDesignTokens.body(context).copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryMuted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.sku,
                            style: WmsDesignTokens.supportingDense(context)
                                .copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                          ),
                        ),
                        if (product.category != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: WmsIconSizes.status,
                                color: colors.textTertiary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  product.category!,
                                  style: WmsDesignTokens.supporting(context)
                                      .copyWith(
                                        color: colors.textSecondary,
                                        fontSize: 13,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  ProductEnterpriseStatusBadge(label: product.stockStatusLabel),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Unit Price',
                      value: WmsFormatters.currency(product.unitPrice),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatTile(
                      label: 'Current Stock',
                      value: WmsFormatters.quantity(product.totalStock),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatTile(
                      label: 'Warehouses',
                      value: '${product.warehouseCount ?? 0}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Last updated ${product.updatedAt != null ? WmsFormatters.relativeTime(product.updatedAt) : '—'}',
                style: WmsDesignTokens.supporting(
                  context,
                ).copyWith(color: colors.textTertiary, fontSize: 14),
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
                  if (canManage)
                    _ActionChip(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      onTap: onEdit,
                    ),
                  _ActionChip(
                    icon: Icons.history,
                    label: 'History',
                    onTap: onStockHistory,
                  ),
                  if (canManage)
                    _ActionChip(
                      icon: Icons.swap_horiz,
                      label: 'Transfer',
                      onTap: onTransfer,
                    ),
                  if (isAdmin && onDelete != null)
                    _ActionChip(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      onTap: onDelete!,
                      destructive: true,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductsEnterpriseCardList extends StatelessWidget {
  const ProductsEnterpriseCardList({
    super.key,
    required this.products,
    required this.canManage,
    required this.isAdmin,
    required this.onView,
    required this.onEdit,
    required this.onStockHistory,
    required this.onTransfer,
    this.onDelete,
  });

  final List<Product> products;
  final bool canManage;
  final bool isAdmin;
  final void Function(Product product) onView;
  final void Function(Product product) onEdit;
  final VoidCallback onStockHistory;
  final VoidCallback onTransfer;
  final void Function(Product product)? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product List',
          style: WmsDesignTokens.sectionTitle(context).copyWith(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < products.length; i++) ...[
          ProductsEnterpriseCard(
            product: products[i],
            canManage: canManage,
            isAdmin: isAdmin,
            onView: () => onView(products[i]),
            onEdit: () => onEdit(products[i]),
            onStockHistory: onStockHistory,
            onTransfer: onTransfer,
            onDelete: onDelete != null ? () => onDelete!(products[i]) : null,
          ),
          if (i < products.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
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
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: WmsDesignTokens.body(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
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
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final fg = destructive ? colors.error : colors.textSecondary;
    return Material(
      color: colors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        side: BorderSide(
          color: destructive
              ? colors.error.withValues(alpha: 0.4)
              : colors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: WmsIconSizes.status, color: fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: WmsDesignTokens.supportingDense(context).copyWith(
                  color: fg,
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

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl, this.size = 52});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _PlaceholderImage(size: size),
            )
          : _PlaceholderImage(size: size),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Container(
      width: size,
      height: size,
      color: colors.surfaceElevated,
      child: Icon(
        Icons.image_outlined,
        size: size * 0.38,
        color: colors.textTertiary,
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? WmsUiColors.of(context).error
        : WmsUiColors.of(context).textPrimary;
    return Row(
      children: [
        Icon(icon, size: WmsIconSizes.kpi, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class ProductEnterpriseStatusBadge extends StatelessWidget {
  const ProductEnterpriseStatusBadge({
    super.key,
    required this.label,
    this.dense = false,
  });

  final String label;

  /// Tighter padding and type for use inside the compact product card.
  final bool dense;

  /// Products spell the empty state `Out Of Stock`; the shared stock-status
  /// vocabulary uses `Out of Stock`. Normalise so both resolve to one palette.
  static String _canonical(String label) {
    switch (label) {
      case 'Out Of Stock':
        return WmsStockStatuses.outOfStock;
      case 'Expiring':
        return WmsStockStatuses.expired;
      default:
        return label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    // Previously this hardcoded dark-theme swatches (a near-black green fill
    // behind green text), which rendered as an unreadable dark blob on the
    // light theme. The shared badge palette is theme-aware and matches the
    // status colors used on the inventory and dashboard screens.
    final palette = WmsBadgeColors.stockStatus(colors, _canonical(label));

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 8,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.fg.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: WmsDesignTokens.supportingDense(context).copyWith(
          color: palette.fg,
          fontWeight: FontWeight.w700,
          fontSize: dense ? 10.5 : 12,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Web-parity scrollable data table for product rows.
class ProductsEnterpriseDataTable extends StatelessWidget {
  const ProductsEnterpriseDataTable({
    super.key,
    required this.products,
    required this.canManage,
    required this.isAdmin,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.onView,
    required this.onEdit,
    required this.onStockHistory,
    required this.onTransfer,
    this.onDelete,
  });

  final List<Product> products;
  final bool canManage;
  final bool isAdmin;
  final ProductSortField sortField;
  final bool sortAscending;
  final ValueChanged<ProductSortField> onSort;
  final void Function(Product product) onView;
  final void Function(Product product) onEdit;
  final VoidCallback onStockHistory;
  final VoidCallback onTransfer;
  final void Function(Product product)? onDelete;

  static const _columns = [
    _TableColumn('', 36, null),
    _TableColumn('SKU', 72, ProductSortField.sku),
    _TableColumn('PRODUCT', 200, ProductSortField.name),
    _TableColumn('CATEGORY', 120, null),
    _TableColumn('BARCODE', 100, null),
    _TableColumn('UNIT PRICE', 100, ProductSortField.price),
    _TableColumn('STOCK', 100, ProductSortField.stock),
    _TableColumn('STATUS', 100, null),
    _TableColumn('UPDATED', 80, ProductSortField.updated),
    _TableColumn('', 44, null),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final tableWidth = _columns.fold<double>(0, (sum, c) => sum + c.width);

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            children: [
              _TableHeaderRow(
                columns: _columns,
                sortField: sortField,
                sortAscending: sortAscending,
                onSort: onSort,
              ),
              for (var i = 0; i < products.length; i++)
                _TableProductRow(
                  product: products[i],
                  columns: _columns,
                  canManage: canManage,
                  isAdmin: isAdmin,
                  isLast: i == products.length - 1,
                  onView: () => onView(products[i]),
                  onEdit: () => onEdit(products[i]),
                  onStockHistory: onStockHistory,
                  onTransfer: onTransfer,
                  onDelete: onDelete != null
                      ? () => onDelete!(products[i])
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableColumn {
  const _TableColumn(this.label, this.width, this.sortField);

  final String label;
  final double width;
  final ProductSortField? sortField;
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({
    required this.columns,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
  });

  final List<_TableColumn> columns;
  final ProductSortField sortField;
  final bool sortAscending;
  final ValueChanged<ProductSortField> onSort;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          for (final col in columns)
            SizedBox(
              width: col.width,
              child: col.sortField != null
                  ? InkWell(
                      onTap: () => onSort(col.sortField!),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                col.label,
                                style: WmsDesignTokens.supportingDense(context)
                                    .copyWith(
                                      color: sortField == col.sortField
                                          ? colors.primary
                                          : colors.textTertiary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ),
                            if (sortField == col.sortField)
                              Icon(
                                sortAscending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 10,
                                color: colors.primary,
                              ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 10,
                      ),
                      child: Text(
                        col.label,
                        style: WmsDesignTokens.supportingDense(context)
                            .copyWith(
                              color: colors.textTertiary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _TableProductRow extends StatelessWidget {
  const _TableProductRow({
    required this.product,
    required this.columns,
    required this.canManage,
    required this.isAdmin,
    required this.isLast,
    required this.onView,
    required this.onEdit,
    required this.onStockHistory,
    required this.onTransfer,
    this.onDelete,
  });

  final Product product;
  final List<_TableColumn> columns;
  final bool canManage;
  final bool isAdmin;
  final bool isLast;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onStockHistory;
  final VoidCallback onTransfer;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final imageUrl = resolveProductImageUrl(product.imageUrl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onView,
        child: Container(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: columns[0].width,
                child: Icon(
                  Icons.chevron_right,
                  size: WmsIconSizes.kpi,
                  color: colors.textTertiary,
                ),
              ),
              SizedBox(
                width: columns[1].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(
                    product.sku,
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: columns[2].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _TableImagePlaceholder(colors: colors),
                              )
                            : _TableImagePlaceholder(colors: colors),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WmsDesignTokens.body(context).copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            if (product.description != null &&
                                product.description!.isNotEmpty)
                              Text(
                                product.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: WmsDesignTokens.supportingDense(context)
                                    .copyWith(
                                      color: colors.textSecondary,
                                      fontSize: 14,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: columns[3].width,
                child: product.category != null
                    ? _CategoryPill(label: product.category!)
                    : Text('—', style: TextStyle(color: colors.textTertiary)),
              ),
              SizedBox(
                width: columns[4].width,
                child: Text(
                  product.barcode?.isNotEmpty == true ? product.barcode! : '—',
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.textSecondary,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(
                width: columns[5].width,
                child: Text(
                  WmsFormatters.currency(product.unitPrice),
                  style: WmsDesignTokens.body(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                width: columns[6].width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      WmsFormatters.quantity(product.totalStock),
                      style: WmsDesignTokens.body(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${product.warehouseCount ?? 0} warehouses',
                      style: WmsDesignTokens.supportingDense(
                        context,
                      ).copyWith(color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: columns[7].width,
                child: ProductEnterpriseStatusBadge(
                  label: product.stockStatusLabel,
                ),
              ),
              SizedBox(
                width: columns[8].width,
                child: Text(
                  product.updatedAt != null
                      ? WmsFormatters.relativeTime(product.updatedAt)
                      : '—',
                  style: WmsDesignTokens.supportingDense(
                    context,
                  ).copyWith(color: colors.textSecondary, fontSize: 12),
                ),
              ),
              SizedBox(
                width: columns[9].width,
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: colors.textTertiary,
                    size: WmsIconSizes.listLeading,
                  ),
                  color: colors.surfaceElevated,
                  onSelected: (action) {
                    switch (action) {
                      case 'view':
                        onView();
                      case 'edit':
                        onEdit();
                      case 'history':
                        onStockHistory();
                      case 'transfer':
                        onTransfer();
                      case 'delete':
                        onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: _ActionRow(
                        icon: Icons.visibility_outlined,
                        label: 'View',
                      ),
                    ),
                    if (canManage)
                      const PopupMenuItem(
                        value: 'edit',
                        child: _ActionRow(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'history',
                      child: _ActionRow(
                        icon: Icons.history,
                        label: 'Stock History',
                      ),
                    ),
                    if (canManage)
                      const PopupMenuItem(
                        value: 'transfer',
                        child: _ActionRow(
                          icon: Icons.swap_horiz,
                          label: 'Transfer',
                        ),
                      ),
                    if (isAdmin && onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: _ActionRow(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          destructive: true,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableImagePlaceholder extends StatelessWidget {
  const _TableImagePlaceholder({required this.colors});

  final WmsUiColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      color: colors.surfaceElevated,
      child: Icon(
        Icons.image_outlined,
        size: WmsIconSizes.listLeading,
        color: colors.textTertiary,
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category_outlined,
            size: WmsIconSizes.status,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile Products page — web-parity structure optimized for phones (320–480dp).
// ---------------------------------------------------------------------------

abstract final class ProductsMobileTypography {
  static double _width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static TextStyle pageTitle(BuildContext context) {
    final narrow = MobileUi.isNarrowPhone(_width(context));
    return WmsDesignTokens.pageTitle(
      context,
    ).copyWith(fontSize: narrow ? 22 : AppTypography.pageTitleSize);
  }

  static TextStyle sectionTitle(BuildContext context) =>
      WmsDesignTokens.sectionTitle(context).copyWith(
        fontSize: MobileUi.isNarrowPhone(_width(context))
            ? 18
            : AppTypography.sectionTitleSize,
      );

  static TextStyle cardTitle(BuildContext context) =>
      WmsDesignTokens.cardTitle(context);

  static TextStyle kpiNumber(BuildContext context) =>
      WmsDesignTokens.cardNumber(context).copyWith(
        fontSize: MobileUi.isNarrowPhone(_width(context))
            ? 20
            : AppTypography.cardNumberSize,
      );

  static TextStyle body(BuildContext context) => WmsDesignTokens.body(context);

  static TextStyle caption(BuildContext context) =>
      WmsDesignTokens.caption(context);
}

/// Page header: back, title, subtitle, full-width Add Product button.
class ProductsMobileHeader extends StatelessWidget {
  const ProductsMobileHeader({
    super.key,
    required this.canManage,
    required this.onAdd,
    this.onBack,
  });

  final bool canManage;
  final VoidCallback onAdd;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final horizontal = MobileUi.screenHorizontalInsetsOf(context);

    // Products is a pushed route with no AppBar, so this header *is* the top
    // chrome: it has to inset itself or the title and Add button sit under the
    // status bar. Same structure as WmsEnterpriseAppHeader — surface fill that
    // paints behind the status bar, content inset below it, hairline underneath
    // — so a pushed screen and a shell tab read identically.
    return Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: horizontal.copyWith(
              top: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (onBack != null) ...[
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(36, 36),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Products',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: ProductsMobileTypography.pageTitle(context)
                            .copyWith(
                              fontSize: 22,
                              height: 1.2,
                              color: colors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Master data & stock visibility',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: ProductsMobileTypography.caption(
                          context,
                        ).copyWith(color: colors.textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
                if (canManage) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _AddProductButton(onAdd: onAdd),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary action for the products header.
///
/// Shows label + icon when there is room and collapses to an icon-only square
/// on narrow phones, so the title never gets squeezed.
class _AddProductButton extends StatelessWidget {
  const _AddProductButton({required this.onAdd});

  final VoidCallback onAdd;

  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final compact = MobileUi.isCompactPhone(MediaQuery.sizeOf(context).width);

    final style = FilledButton.styleFrom(
      backgroundColor: colors.primary,
      foregroundColor: const Color(0xFFFFFFFF),
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : AppSpacing.md),
      minimumSize: Size(compact ? _height : 0, _height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    );

    if (compact) {
      return SizedBox(
        width: _height,
        height: _height,
        child: FilledButton(
          onPressed: onAdd,
          style: style,
          child: const Icon(Icons.add_rounded, size: 20),
        ),
      );
    }

    return SizedBox(
      height: _height,
      child: FilledButton(
        onPressed: onAdd,
        style: style,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 18),
            const SizedBox(width: 5),
            Text(
              'Add Product',
              maxLines: 1,
              softWrap: false,
              style: ProductsMobileTypography.caption(context).copyWith(
                // Explicit white: the themed label color would otherwise win.
                color: const Color(0xFFFFFFFF),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsMobileKpiDef {
  const _ProductsMobileKpiDef(
    this.label,
    this.value,
    this.icon,
    this.iconColor, [
    this.onTap,
  ]);

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
}

/// Two-column KPI grid — all web summary cards.
class ProductsMobileKpiGrid extends StatelessWidget {
  const ProductsMobileKpiGrid({
    super.key,
    required this.summary,
    this.categoryCount = 0,
    this.onLowStock,
    this.onOutOfStock,
  });

  final ProductsSummary summary;
  final int categoryCount;
  final VoidCallback? onLowStock;
  final VoidCallback? onOutOfStock;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final categoriesValue = summary.categories > 0
        ? summary.categories
        : categoryCount;

    final items = [
      _ProductsMobileKpiDef(
        'Active Products',
        '${summary.total}',
        Icons.inventory_2_outlined,
        const Color(0xFF60A5FA),
      ),
      _ProductsMobileKpiDef(
        'Categories',
        '$categoriesValue',
        Icons.layers_outlined,
        const Color(0xFFA78BFA),
      ),
      _ProductsMobileKpiDef(
        'Low Stock',
        '${summary.lowStock}',
        Icons.warning_amber_rounded,
        colors.warning,
        onLowStock,
      ),
      _ProductsMobileKpiDef(
        'Out Of Stock',
        '${summary.outOfStock}',
        Icons.remove_shopping_cart_outlined,
        colors.error,
        onOutOfStock,
      ),
      _ProductsMobileKpiDef(
        'Expiring',
        '${summary.expiring}',
        Icons.schedule_outlined,
        const Color(0xFFFBBF24),
      ),
      _ProductsMobileKpiDef(
        'Catalog Value',
        WmsFormatters.currency(summary.totalValue),
        Icons.attach_money_rounded,
        colors.success,
      ),
    ];

    // Six tall cards in a two-column grid ran three rows deep — around 500dp,
    // more than a phone screen before any product was visible. The same six
    // metrics now scroll horizontally in a single ~78dp strip.
    return WmsMetricPillBar(
      metrics: [
        for (final item in items)
          WmsMetricPillData(
            label: item.label,
            value: item.value,
            icon: item.icon,
            color: item.iconColor,
            onTap: item.onTap,
          ),
      ],
    );
  }
}

/// Single unified search bar (48px) plus horizontal category/warehouse chips.
class ProductsMobileSearchSection extends StatelessWidget {
  const ProductsMobileSearchSection({
    super.key,
    required this.searchController,
    required this.onSearch,
    required this.categories,
    required this.warehouses,
    required this.categoryFilterId,
    required this.warehouseFilterId,
    required this.warehouseFilterLoading,
    required this.onCategory,
    required this.onWarehouse,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final List<ProductCategory> categories;
  final List<WarehouseOption> warehouses;
  final String? categoryFilterId;
  final String? warehouseFilterId;
  final bool warehouseFilterLoading;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onWarehouse;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final selectedCategory = categoryFilterId;
    final selectedWarehouse = warehouseFilterId;

    final categoryName = _labelFor(selectedCategory, [
      for (final c in categories) (id: c.id, name: c.name),
    ]);
    final warehouseName = _labelFor(selectedWarehouse, [
      for (final w in warehouses) (id: w.id, name: w.name),
    ]);
    final activeCount = [
      categoryName,
      warehouseName,
    ].where((v) => v != null).length;

    // Search and both filter rows collapse into one line. The two chip strips
    // cost ~76dp permanently even when nothing was filtered; they now live in
    // a sheet, and only *active* filters take space, as removable chips.
    return Padding(
      padding: MobileUi.screenHorizontalInsetsOf(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: _controlHeight,
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearch,
                    textInputAction: TextInputAction.search,
                    style: ProductsMobileTypography.body(
                      context,
                    ).copyWith(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search SKU, name, barcode',
                      hintStyle: ProductsMobileTypography.caption(
                        context,
                      ).copyWith(color: colors.textTertiary),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      filled: true,
                      fillColor: colors.surfaceElevated,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: colors.border.withValues(alpha: 0.8),
                          width: 0.8,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: colors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ProductsFilterButton(
                activeCount: activeCount,
                loading: warehouseFilterLoading,
                onTap: () => _openFilterSheet(context),
              ),
            ],
          ),
          if (activeCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (categoryName != null)
                    _ActiveFilterChip(
                      label: categoryName,
                      icon: Icons.category_outlined,
                      onClear: () => onCategory(null),
                    ),
                  if (warehouseName != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    _ActiveFilterChip(
                      label: warehouseName,
                      icon: Icons.warehouse_outlined,
                      onClear: () => onWarehouse(null),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (warehouseFilterLoading) ...[
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              color: colors.primary,
              backgroundColor: colors.border,
              minHeight: 2,
            ),
          ],
        ],
      ),
    );
  }

  static const double _controlHeight = 44;

  static String? _labelFor(
    String? id,
    List<({String id, String name})> options,
  ) {
    if (id == null || id.isEmpty) return null;
    for (final option in options) {
      if (option.id == id) return option.name;
    }
    return null;
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
      builder: (sheetContext) => ProductsFilterSheet(
        categories: categories,
        warehouses: warehouses,
        categoryFilterId: categoryFilterId,
        warehouseFilterId: warehouseFilterId,
        onCategory: onCategory,
        onWarehouse: onWarehouse,
      ),
    );
  }
}

class _ProductsFilterButton extends StatelessWidget {
  const _ProductsFilterButton({
    required this.activeCount,
    required this.onTap,
    this.loading = false,
  });

  final int activeCount;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final active = activeCount > 0;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);

    return Material(
      color: active
          ? colors.primary.withValues(alpha: 0.10)
          : colors.surfaceElevated,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : onTap,
        child: Container(
          height: ProductsMobileSearchSection._controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: active
                  ? colors.primary.withValues(alpha: 0.40)
                  : colors.border.withValues(alpha: 0.8),
              width: active ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: active ? colors.primary : colors.textSecondary,
              ),
              if (active) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$activeCount',
                    style: ProductsMobileTypography.caption(context).copyWith(
                      color: const Color(0xFFFFFFFF),
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

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    required this.label,
    required this.icon,
    required this.onClear,
  });

  final String label;
  final IconData icon;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final primary = colors.primary;

    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.sm, right: 2),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: primary),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: ProductsMobileTypography.caption(context).copyWith(
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

/// Bottom sheet holding the category and warehouse filters.
class ProductsFilterSheet extends StatelessWidget {
  const ProductsFilterSheet({
    super.key,
    required this.categories,
    required this.warehouses,
    required this.categoryFilterId,
    required this.warehouseFilterId,
    required this.onCategory,
    required this.onWarehouse,
  });

  final List<ProductCategory> categories;
  final List<WarehouseOption> warehouses;
  final String? categoryFilterId;
  final String? warehouseFilterId;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onWarehouse;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
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
                      'Filters',
                      style: ProductsMobileTypography.sectionTitle(
                        context,
                      ).copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      onCategory(null);
                      onWarehouse(null);
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
                        label: 'Category',
                        child: _OptionWrap(
                          labels: [for (final c in categories) c.name],
                          values: [for (final c in categories) c.id],
                          selected: categoryFilterId,
                          allLabel: 'All categories',
                          onSelected: onCategory,
                        ),
                      ),
                      _SheetGroup(
                        label: 'Warehouse',
                        child: _OptionWrap(
                          labels: [for (final w in warehouses) w.name],
                          values: [for (final w in warehouses) w.id],
                          selected: warehouseFilterId,
                          allLabel: 'All warehouses',
                          onSelected: onWarehouse,
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
            style: ProductsMobileTypography.caption(context).copyWith(
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

class _OptionWrap extends StatelessWidget {
  const _OptionWrap({
    required this.labels,
    required this.values,
    required this.selected,
    required this.allLabel,
    required this.onSelected,
  });

  final List<String> labels;
  final List<String> values;
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
        for (var i = 0; i < labels.length; i++)
          ChoiceChip(
            label: Text(labels[i]),
            selected: selected == values[i],
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => onSelected(values[i]),
          ),
      ],
    );
  }
}

/// Enterprise product card — 60×60 image, details, horizontal action row.
class ProductsMobileCard extends StatelessWidget {
  const ProductsMobileCard({
    super.key,
    required this.product,
    required this.canManage,
    required this.isAdmin,
    required this.onView,
    required this.onEdit,
    required this.onStockHistory,
    required this.onTransfer,
    this.onDelete,
  });

  final Product product;
  final bool canManage;
  final bool isAdmin;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onStockHistory;
  final VoidCallback onTransfer;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final imageUrl = resolveProductImageUrl(product.imageUrl);
    final category = product.category;
    final subtitle = category != null && category.isNotEmpty
        ? '${product.sku} · $category'
        : product.sku;

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onView,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductImage(imageUrl: imageUrl, size: 52),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: ProductsMobileTypography.cardTitle(context)
                          .copyWith(
                            fontSize: 14.5,
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                    ),
                    const SizedBox(height: 2),
                    // SKU and category share one line — they were three
                    // separate wrapping runs before.
                    Text(
                      subtitle,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: ProductsMobileTypography.caption(
                        context,
                      ).copyWith(color: colors.textSecondary, height: 1.25),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ProductEnterpriseStatusBadge(
                        label: product.stockStatusLabel,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ),
              // Five stacked action chips collapse into one overflow menu.
              _ProductActionsMenu(
                canManage: canManage,
                isAdmin: isAdmin,
                onView: onView,
                onEdit: onEdit,
                onStockHistory: onStockHistory,
                onTransfer: onTransfer,
                onDelete: onDelete,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(
            height: 1,
            thickness: 0.8,
            color: colors.border.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _ProductStat(
                label: 'Unit Price',
                value: WmsFormatters.currency(product.unitPrice),
              ),
              _ProductStat(
                label: 'Stock',
                value: WmsFormatters.quantity(product.totalStock),
              ),
              _ProductStat(
                label: 'Warehouses',
                value: '${product.warehouseCount ?? 0}',
              ),
              _ProductStat(
                label: 'Updated',
                value: product.updatedAt != null
                    ? WmsFormatters.relativeTime(product.updatedAt)
                    : '—',
                alignEnd: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Overflow menu replacing the row of action chips.
class _ProductActionsMenu extends StatelessWidget {
  const _ProductActionsMenu({
    required this.canManage,
    required this.isAdmin,
    required this.onView,
    required this.onEdit,
    required this.onStockHistory,
    required this.onTransfer,
    this.onDelete,
  });

  final bool canManage;
  final bool isAdmin;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onStockHistory;
  final VoidCallback onTransfer;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    return PopupMenuButton<VoidCallback>(
      onSelected: (action) => action(),
      tooltip: 'Product actions',
      position: PopupMenuPosition.under,
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: colors.textSecondary,
      ),
      padding: EdgeInsets.zero,
      // Keeps the tap target accessible without inflating the card row.
      constraints: const BoxConstraints(minWidth: 180),
      splashRadius: 20,
      itemBuilder: (context) => [
        _item(context, Icons.visibility_outlined, 'View details', onView),
        if (canManage) ...[
          _item(context, Icons.edit_outlined, 'Edit product', onEdit),
          _item(
            context,
            Icons.swap_horiz_rounded,
            'Transfer stock',
            onTransfer,
          ),
        ],
        _item(context, Icons.history_rounded, 'Stock history', onStockHistory),
        if (isAdmin && onDelete != null) ...[
          const PopupMenuDivider(height: 1),
          _item(
            context,
            Icons.delete_outline_rounded,
            'Delete product',
            onDelete!,
            destructive: true,
          ),
        ],
      ],
    );
  }

  PopupMenuItem<VoidCallback> _item(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback action, {
    bool destructive = false,
  }) {
    final colors = WmsUiColors.of(context);
    final color = destructive ? colors.error : colors.textPrimary;

    return PopupMenuItem<VoidCallback>(
      value: action,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.body(
                context,
              ).copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// One equal-width cell of the card's metric row.
///
/// Replaces the bordered stat boxes, which each carried their own padding,
/// border and background and wrapped onto extra runs on narrow phones.
class _ProductStat extends StatelessWidget {
  const _ProductStat({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
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
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: ProductsMobileTypography.caption(
              context,
            ).copyWith(fontSize: 11, color: colors.textTertiary, height: 1.2),
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
                style: ProductsMobileTypography.body(context).copyWith(
                  fontSize: 13,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
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

/// Section header + mobile product cards.
class ProductsMobileCardList extends StatelessWidget {
  const ProductsMobileCardList({
    super.key,
    required this.products,
    required this.canManage,
    required this.isAdmin,
    required this.onView,
    required this.onEdit,
    required this.onStockHistory,
    required this.onTransfer,
    this.onDelete,
  });

  final List<Product> products;
  final bool canManage;
  final bool isAdmin;
  final void Function(Product product) onView;
  final void Function(Product product) onEdit;
  final VoidCallback onStockHistory;
  final VoidCallback onTransfer;
  final void Function(Product product)? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: MobileUi.screenHorizontalInsetsOf(context),
          child: Text(
            'Product List',
            style: ProductsMobileTypography.sectionTitle(
              context,
            ).copyWith(color: colors.textPrimary),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < products.length; i++)
          Padding(
            padding: MobileUi.screenHorizontalInsetsOf(
              context,
            ).copyWith(bottom: AppSpacing.md),
            child: ProductsMobileCard(
              product: products[i],
              canManage: canManage,
              isAdmin: isAdmin,
              onView: () => onView(products[i]),
              onEdit: () => onEdit(products[i]),
              onStockHistory: onStockHistory,
              onTransfer: onTransfer,
              onDelete: onDelete != null ? () => onDelete!(products[i]) : null,
            ),
          ),
      ],
    );
  }
}
