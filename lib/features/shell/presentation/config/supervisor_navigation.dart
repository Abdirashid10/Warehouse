import 'package:flutter/material.dart';
import 'package:logisticsmobile/features/shell/presentation/widgets/wms_app_drawer.dart';
import 'package:logisticsmobile/routes/route_names.dart';

/// Web-parity supervisor sidebar navigation (mirrors `navigation.js` MANAGEMENT_NAV for Supervisor).
abstract final class SupervisorNavigation {
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
              route: RoutePaths.supervisorDashboard,
            ),
            WmsDrawerItem(
              label: 'Products',
              icon: Icons.category_outlined,
              pushRoute: RoutePaths.supervisorProducts,
            ),
            WmsDrawerItem(
              label: 'Inventory Tracking',
              icon: Icons.inventory_outlined,
              pushRoute: RoutePaths.supervisorInventoryTracking,
            ),
            WmsDrawerItem(
              label: 'Stock Movements',
              icon: Icons.swap_horiz_rounded,
              pushRoute: RoutePaths.supervisorStockMovements,
            ),
            WmsDrawerItem(
              label: 'Warehouses',
              icon: Icons.warehouse_outlined,
              pushRoute: RoutePaths.supervisorWarehouses,
            ),
            WmsDrawerItem(
              label: 'Expiry & Risk',
              icon: Icons.shield_outlined,
              pushRoute: RoutePaths.supervisorExpiryRisk,
            ),
            WmsDrawerItem(
              label: 'Orders',
              icon: Icons.shopping_cart_outlined,
              bottomIndex: 2,
              route: RoutePaths.supervisorOrders,
            ),
            WmsDrawerItem(
              label: 'Tasks',
              icon: Icons.assignment_outlined,
              bottomIndex: 3,
              route: RoutePaths.supervisorTasks,
            ),
          ],
        ),
        WmsDrawerSection(
          title: administrationHeader,
          items: [
            WmsDrawerItem(
              label: 'Reports',
              icon: Icons.assessment_outlined,
              pushRoute: RoutePaths.supervisorReports,
            ),
            WmsDrawerItem(
              label: 'Audit Logs',
              icon: Icons.timeline_outlined,
              pushRoute: RoutePaths.supervisorAudit,
            ),
            WmsDrawerItem(
              label: 'Notifications',
              icon: Icons.notifications_outlined,
              pushRoute: RoutePaths.supervisorNotifications,
            ),
            WmsDrawerItem(
              label: 'Profile',
              icon: Icons.person_outline,
              bottomIndex: 4,
              route: RoutePaths.supervisorProfile,
            ),
          ],
        ),
      ];
}
