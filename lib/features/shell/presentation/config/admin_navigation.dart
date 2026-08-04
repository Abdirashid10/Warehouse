import 'package:flutter/material.dart';
import 'package:logisticsmobile/features/shell/presentation/widgets/wms_app_drawer.dart';
import 'package:logisticsmobile/routes/route_names.dart';

/// Admin drawer sections — web-parity grouping with 20px section gaps.
abstract final class AdminNavigation {
  static const mainNavigationHeader = 'Main Navigation';
  static const administrationHeader = 'Administration';

  static List<WmsDrawerSection> drawerSections() => const [
        WmsDrawerSection(
          title: mainNavigationHeader,
          items: [
            WmsDrawerItem(
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              bottomIndex: 0,
            ),
            WmsDrawerItem(
              label: 'Products',
              icon: Icons.category_outlined,
              pushRoute: RoutePaths.adminProducts,
            ),
            WmsDrawerItem(
              label: 'Inventory',
              icon: Icons.inventory_2_outlined,
              bottomIndex: 1,
            ),
            WmsDrawerItem(
              label: 'Stock Operations',
              icon: Icons.inventory_outlined,
              pushRoute: RoutePaths.adminStockOperations,
            ),
            WmsDrawerItem(
              label: 'Stock Movements',
              icon: Icons.swap_horiz_rounded,
              pushRoute: RoutePaths.adminStockMovements,
            ),
            WmsDrawerItem(
              label: 'Warehouses',
              icon: Icons.warehouse_outlined,
              pushRoute: RoutePaths.adminWarehouses,
            ),
            WmsDrawerItem(
              label: 'Orders',
              icon: Icons.shopping_cart_outlined,
              bottomIndex: 2,
            ),
            WmsDrawerItem(
              label: 'Tasks',
              icon: Icons.assignment_outlined,
              bottomIndex: 3,
            ),
          ],
        ),
        WmsDrawerSection(
          title: administrationHeader,
          items: [
            WmsDrawerItem(
              label: 'Reports',
              icon: Icons.assessment_outlined,
              pushRoute: RoutePaths.adminReports,
            ),
            WmsDrawerItem(
              label: 'Audit Logs',
              icon: Icons.history,
              pushRoute: RoutePaths.adminAudit,
            ),
            WmsDrawerItem(
              label: 'Administration',
              icon: Icons.admin_panel_settings_outlined,
              pushRoute: RoutePaths.adminAdministration,
            ),
            WmsDrawerItem(
              label: 'Users',
              icon: Icons.people_outline,
              pushRoute: RoutePaths.adminUsers,
            ),
            WmsDrawerItem(
              label: 'Notifications',
              icon: Icons.notifications_outlined,
              pushRoute: RoutePaths.adminNotifications,
            ),
            WmsDrawerItem(
              label: 'Profile',
              icon: Icons.person_outline,
              bottomIndex: 4,
            ),
          ],
        ),
      ];
}
