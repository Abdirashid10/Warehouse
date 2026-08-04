import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/features/inventory/presentation/pages/inventory_screen.dart';

/// Admin bottom-nav inventory tab (no pushed scaffold wrapper).
class AdminInventoryTab extends StatelessWidget {
  const AdminInventoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory Tracking',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Organization-wide stock levels, filters, and low-stock indicators',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const Expanded(child: InventoryScreen()),
          ],
        ),
      ),
    );
  }
}
