import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/management_dashboard_data.dart';
import 'package:logisticsmobile/widgets/wms/wms_kpi_strip.dart';

class ManagementKpiStrip extends StatelessWidget {
  const ManagementKpiStrip({super.key, required this.data});

  final ManagementDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
      child: WmsKpiStrip(
        items: [
          WmsKpiItem(
            label: 'Stock Value',
            value: WmsFormatters.currency(data.totalStockValue),
            icon: Icons.payments_outlined,
            color: AppColors.primary,
            background: AppColors.primaryLight,
          ),
          WmsKpiItem(
            label: 'Units On Hand',
            value: WmsFormatters.quantity(data.totalUnitsOnHand),
            icon: Icons.inventory_2_outlined,
            color: AppColors.info,
            background: AppColors.infoLight,
          ),
          WmsKpiItem(
            label: 'Low Stock',
            value: '${data.lowStockLineCount}',
            icon: Icons.warning_amber_outlined,
            color: AppColors.warning,
            background: AppColors.warningLight,
          ),
          WmsKpiItem(
            label: 'Orders',
            value: '${data.totalOrders}',
            icon: Icons.shopping_cart_outlined,
            color: AppColors.accent,
            background: AppColors.accentLight,
          ),
          WmsKpiItem(
            label: 'Movements Today',
            value: '${data.todayMovementsCount}',
            icon: Icons.swap_horiz,
            color: AppColors.success,
            background: AppColors.successLight,
          ),
          WmsKpiItem(
            label: 'Overdue Tasks',
            value: '${data.overdueTasks}',
            icon: Icons.schedule,
            color: AppColors.error,
            background: AppColors.errorLight,
          ),
        ],
      ),
    );
  }
}
