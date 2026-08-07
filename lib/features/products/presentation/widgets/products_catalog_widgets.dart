import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/widgets/wms/wms_catalog_primitives.dart';

export 'package:logisticsmobile/widgets/wms/wms_catalog_primitives.dart'
    show WmsCatalogListScaffold, WmsCatalogSearchField;

/// Web-parity category pills — lavender "All" selected, white + border others.
class ProductsCategoryChipBar extends StatelessWidget {
  const ProductsCategoryChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  static const _selectedBg = Color(0xFFEEF2FF);
  static const _selectedBorder = Color(0xFFC7D2FE);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CategoryPill(
            label: 'All',
            selected: selected == null || selected!.isEmpty,
            onTap: () => onSelected(null),
          ),
          for (final option in options) ...[
            const SizedBox(width: AppSpacing.sm),
            _CategoryPill(
              label: option,
              selected: selected == option,
              onTap: () => onSelected(option),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Material(
      color: selected ? ProductsCategoryChipBar._selectedBg : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? ProductsCategoryChipBar._selectedBorder
              : colors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: WmsDesignTokens.supporting(context).copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
          ),
        ),
      ),
    );
  }
}

/// Web-style product row card — name, SKU, category, unit cost.
class ProductCatalogCard extends StatelessWidget {
  const ProductCatalogCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metaStyle = WmsDesignTokens.supporting(context).copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 14,
      height: 1.4,
    );

    return WmsCatalogListCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: WmsDesignTokens.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 4),
          Text('SKU ${product.sku}', style: metaStyle),
          Text(
            product.category?.isNotEmpty == true ? product.category! : '—',
            style: metaStyle,
          ),
          Text(
            product.unitCost != null
                ? 'Unit cost ${WmsFormatters.currency(product.unitCost)}'
                : 'Unit cost —',
            style: metaStyle.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

/// Web-parity products catalog header.
class ProductsCatalogHeader extends StatelessWidget {
  const ProductsCatalogHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const WmsCatalogPageHeader(
      title: 'Products',
      subtitle:
          'Product catalog from the WMS — search by name, SKU, or category',
    );
  }
}
