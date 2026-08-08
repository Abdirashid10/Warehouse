import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/features/shell/presentation/widgets/wms_app_drawer.dart';
import 'package:logisticsmobile/routes/route_names.dart';

/// Drawer navigation for staff modules (5-tab bottom nav + drawer extras).
class StaffDrawer extends StatelessWidget {
  const StaffDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  final int currentIndex;
  final void Function(int? bottomIndex, String? pushRoute) onNavigate;

  static const _mainNavigationHeader = 'Main Navigation';
  static const _operationsHeader = 'Operations';

  static const _sections = [
    WmsDrawerSection(
      title: _mainNavigationHeader,
      items: [
        WmsDrawerItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          bottomIndex: 0,
        ),
        WmsDrawerItem(
          label: 'Tasks',
          icon: Icons.assignment_outlined,
          bottomIndex: 3,
        ),
        WmsDrawerItem(
          label: 'Inventory',
          icon: Icons.inventory_2_outlined,
          bottomIndex: 1,
        ),
        WmsDrawerItem(
          label: 'Orders',
          icon: Icons.shopping_cart_outlined,
          bottomIndex: 2,
        ),
      ],
    ),
    WmsDrawerSection(
      title: _operationsHeader,
      items: [
        WmsDrawerItem(
          label: 'Stock Operations',
          icon: Icons.swap_horiz_rounded,
          pushRoute: RoutePaths.staffStockOperations,
        ),
        WmsDrawerItem(
          label: 'Reports',
          icon: Icons.assessment_outlined,
          pushRoute: RoutePaths.staffReports,
        ),
        WmsDrawerItem(
          label: 'Notifications',
          icon: Icons.notifications_outlined,
          pushRoute: RoutePaths.staffNotifications,
        ),
        WmsDrawerItem(
          label: 'Profile',
          icon: Icons.person_outline,
          bottomIndex: 4,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return WmsAppDrawer(
      subtitle: 'Warehouse Operations',
      sections: _sections,
      currentBottomIndex: currentIndex,
      currentLocation: location,
      onNavigate: onNavigate,
    );
  }
}
