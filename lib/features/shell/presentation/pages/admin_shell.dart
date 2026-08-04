import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/features/shell/presentation/config/admin_navigation.dart';
import 'package:logisticsmobile/features/shell/presentation/config/enterprise_shell_navigation.dart';
import 'package:logisticsmobile/features/shell/presentation/widgets/wms_app_drawer.dart';
import 'package:logisticsmobile/features/shell/presentation/widgets/wms_enterprise_shell_scaffold.dart';
import 'package:logisticsmobile/routes/route_names.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';

/// Admin control center shell with enterprise design system.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex
        .clamp(0, EnterpriseShellNavigation.tabTitles.length - 1);
    final colors = WmsUiColors.of(context);
    final location = GoRouterState.of(context).matchedLocation;

    return WmsEnterpriseShellScaffold(
      navigationShell: navigationShell,
      headerSubtitle: 'Warehouse Operations Center',
      notificationsRoute: RoutePaths.adminNotifications,
      profileRoute: RoutePaths.adminProfile,
      selectedIndex: index,
      onDestinationSelected: _goBranch,
      drawer: WmsAppDrawer(
        subtitle: 'Admin Control Center',
        accentColor: colors.primary,
        roleOverride: 'Administrator',
        sections: AdminNavigation.drawerSections(),
        currentBottomIndex: index,
        currentLocation: location,
        onNavigate: (bottomIndex, pushRoute) {
          if (pushRoute != null) {
            context.push(pushRoute);
          } else if (bottomIndex != null) {
            _goBranch(bottomIndex);
          }
        },
      ),
    );
  }
}

int adminShellIndexForPath(String path) {
  if (path.startsWith(RoutePaths.adminInventory)) return 1;
  if (path.startsWith(RoutePaths.adminOrders)) return 2;
  if (path.startsWith(RoutePaths.adminTasks)) return 3;
  if (path.startsWith(RoutePaths.adminProfile)) return 4;
  return 0;
}
