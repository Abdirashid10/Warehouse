import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/constants/wms/stock_constants.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_badges.dart';

/// Reusable inventory product row for staff inventory lists.
class WmsInventoryCard extends StatelessWidget {
  const WmsInventoryCard({super.key, required this.item});

  final InventoryItem item;

  bool get _isLow =>
      item.stockStatus == WmsStockStatuses.lowStock ||
      item.stockStatus.toLowerCase().contains('low');

  bool get _isOut =>
      item.stockStatus == WmsStockStatuses.outOfStock ||
      item.stockStatus.toLowerCase().contains('out');

  @override
  Widget build(BuildContext context) {
    final borderColor = _isOut
        ? AppColors.error
        : _isLow
            ? AppColors.warning
            : null;

    return AppCard(
      child: Container(
        decoration: borderColor != null
            ? BoxDecoration(
                border: Border(left: BorderSide(color: borderColor, width: 4)),
              )
            : null,
        padding: borderColor != null
            ? const EdgeInsets.only(left: AppSpacing.sm)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                WmsStockStatusBadge(status: item.stockStatus),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('SKU ${item.sku}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.warehouse_outlined,
                  size: WmsIconSizes.listLeading,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: WmsIconSizes.iconLabelGap),
                Expanded(
                  child: Text(
                    item.warehouseName,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Text(
                  '${WmsFormatters.quantity(item.quantity)} units',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _isOut
                            ? AppColors.error
                            : _isLow
                                ? AppColors.warning
                                : AppColors.primary,
                      ),
                ),
              ],
            ),
            if (_isLow || _isOut) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    _isOut ? Icons.error_outline : Icons.warning_amber_rounded,
                    size: WmsIconSizes.status,
                    color: _isOut ? AppColors.error : AppColors.warning,
                  ),
                  const SizedBox(width: WmsIconSizes.iconLabelGap),
                  Text(
                    _isOut ? 'Replenishment required' : 'Low stock — review threshold',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _isOut ? AppColors.error : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
            if (item.minThreshold != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Min threshold: ${WmsFormatters.quantity(item.minThreshold)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
