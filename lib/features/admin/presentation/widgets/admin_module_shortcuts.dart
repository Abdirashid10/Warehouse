import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/routes/route_names.dart';
import 'package:logisticsmobile/widgets/app_card.dart';

class AdminModuleShortcut {
  const AdminModuleShortcut({
    required this.label,
    required this.icon,
    required this.route,
    this.isShellIndex,
  });

  final String label;
  final IconData icon;
  final String route;
  final int? isShellIndex;
}

class AdminModuleShortcuts extends StatelessWidget {
  const AdminModuleShortcuts({super.key});

  static const modules = [
    AdminModuleShortcut(
      label: 'Products',
      icon: Icons.category_outlined,
      route: RoutePaths.adminProducts,
    ),
    AdminModuleShortcut(
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      route: RoutePaths.adminInventory,
      isShellIndex: 1,
    ),
    AdminModuleShortcut(
      label: 'Stock Ops',
      icon: Icons.inventory_outlined,
      route: RoutePaths.adminStockOperations,
    ),
    AdminModuleShortcut(
      label: 'Movements',
      icon: Icons.swap_horiz_rounded,
      route: RoutePaths.adminStockMovements,
    ),
    AdminModuleShortcut(
      label: 'Warehouses',
      icon: Icons.warehouse_outlined,
      route: RoutePaths.adminWarehouses,
    ),
    AdminModuleShortcut(
      label: 'Orders',
      icon: Icons.shopping_cart_outlined,
      route: RoutePaths.adminOrders,
      isShellIndex: 2,
    ),
    AdminModuleShortcut(
      label: 'Tasks',
      icon: Icons.assignment_outlined,
      route: RoutePaths.adminTasks,
    ),
    AdminModuleShortcut(
      label: 'Reports',
      icon: Icons.assessment_outlined,
      route: RoutePaths.adminReports,
    ),
    AdminModuleShortcut(
      label: 'Audit',
      icon: Icons.history,
      route: RoutePaths.adminAudit,
    ),
    AdminModuleShortcut(
      label: 'Administration',
      icon: Icons.admin_panel_settings_outlined,
      route: RoutePaths.adminAdministration,
    ),
    AdminModuleShortcut(
      label: 'Users',
      icon: Icons.people_outline,
      route: RoutePaths.adminUsers,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Admin modules',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossCount = constraints.maxWidth > 400 ? 3 : 2;
            return GridView.count(
              crossAxisCount: crossCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.45,
              children: [
                for (final module in modules)
                  _ModuleTile(
                    module: module,
                    onTap: () {
                      if (module.isShellIndex != null) {
                        context.go(module.route);
                      } else {
                        context.push(module.route);
                      }
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.module, required this.onTap});

  final AdminModuleShortcut module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.primaryMuted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(module.icon, color: colors.primary, size: WmsIconSizes.dashboardCard),
          ),
          const Spacer(),
          Text(
            module.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
