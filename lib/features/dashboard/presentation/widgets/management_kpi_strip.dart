import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/management_dashboard_data.dart';
import 'package:logisticsmobile/widgets/wms/wms_kpi_strip.dart';

class ManagementKpiStrip extends StatelessWidget {
  const ManagementKpiStrip({super.key, required this.data});

  final ManagementDashboardData data;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
      child: WmsKpiStrip(
        items: [
          WmsKpiItem(
            label: 'Stock Value',
            value: WmsFormatters.currency(data.totalStockValue),
            icon: Icons.payments_outlined,
            color: colors.primary,
            background: colors.primaryMuted,
          ),
          WmsKpiItem(
            label: 'Units On Hand',
            value: WmsFormatters.quantity(data.totalUnitsOnHand),
            icon: Icons.inventory_2_outlined,
            color: colors.info,
            background: colors.infoMuted,
          ),
          WmsKpiItem(
            label: 'Low Stock',
            value: '${data.lowStockLineCount}',
            icon: Icons.warning_amber_outlined,
            color: colors.warning,
            background: colors.warningMuted,
          ),
          WmsKpiItem(
            label: 'Orders',
            value: '${data.totalOrders}',
            icon: Icons.shopping_cart_outlined,
            color: colors.accent,
            background: colors.accentMuted,
          ),
          WmsKpiItem(
            label: 'Movements Today',
            value: '${data.todayMovementsCount}',
            icon: Icons.swap_horiz,
            color: colors.success,
            background: colors.successMuted,
          ),
          WmsKpiItem(
            label: 'Overdue Tasks',
            value: '${data.overdueTasks}',
            icon: Icons.schedule,
            color: colors.error,
            background: colors.errorMuted,
          ),
        ],
      ),
    );
  }
}
