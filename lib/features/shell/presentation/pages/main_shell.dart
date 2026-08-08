import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/widgets/wms/wms_shell_navigation_bar.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: WmsShellNavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          WmsNavDestination(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          WmsNavDestination(
            icon: Icons.task_alt_outlined,
            selectedIcon: Icons.task_alt_rounded,
            label: 'Tasks',
          ),
          WmsNavDestination(
            icon: Icons.inventory_2_outlined,
            selectedIcon: Icons.inventory_2_rounded,
            label: 'Inventory',
          ),
          WmsNavDestination(
            icon: Icons.notifications_outlined,
            selectedIcon: Icons.notifications_rounded,
            label: 'Alerts',
          ),
          WmsNavDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
