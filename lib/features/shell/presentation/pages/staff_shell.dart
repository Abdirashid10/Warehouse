import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/features/shell/presentation/config/enterprise_shell_navigation.dart';
import 'package:logisticsmobile/features/shell/presentation/widgets/staff_drawer.dart';
import 'package:logisticsmobile/features/shell/presentation/widgets/wms_enterprise_shell_scaffold.dart';
import 'package:logisticsmobile/routes/route_names.dart';

/// Enterprise staff shell — shared design system with Admin and Supervisor.
class StaffShell extends StatelessWidget {
  const StaffShell({super.key, required this.navigationShell});

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

    return WmsEnterpriseShellScaffold(
      navigationShell: navigationShell,
      headerSubtitle: index == 0 ? 'Staff Dashboard' : 'Warehouse Operations Center',
      showHeaderGreeting: index != 0,
      notificationsRoute: RoutePaths.staffNotifications,
      profileRoute: RoutePaths.staffProfile,
      selectedIndex: index,
      onDestinationSelected: _goBranch,
      drawer: StaffDrawer(
        currentIndex: index,
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

int staffShellIndexForPath(String path) {
  if (path.startsWith(RoutePaths.staffInventory)) return 1;
  if (path.startsWith(RoutePaths.staffOrders)) return 2;
  if (path.startsWith(RoutePaths.staffTasks)) return 3;
  if (path.startsWith(RoutePaths.staffProfile)) return 4;
  return 0;
}
