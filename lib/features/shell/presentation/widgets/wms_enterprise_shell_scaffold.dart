import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/features/shell/presentation/config/enterprise_shell_navigation.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_enterprise_app_header.dart';
import 'package:logisticsmobile/widgets/wms/wms_shell_navigation_bar.dart';

/// Unified enterprise shell layout for Admin, Supervisor, and Staff.
class WmsEnterpriseShellScaffold extends StatelessWidget {
  const WmsEnterpriseShellScaffold({
    super.key,
    required this.navigationShell,
    required this.headerSubtitle,
    required this.notificationsRoute,
    required this.profileRoute,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.drawer,
    this.showHeaderGreeting = true,
  });

  final Widget navigationShell;
  final String headerSubtitle;
  final String notificationsRoute;
  final String profileRoute;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget drawer;
  final bool showHeaderGreeting;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: drawer,
      body: Builder(
        builder: (scaffoldContext) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WmsEnterpriseAppHeader(
                subtitle: headerSubtitle,
                notificationsRoute: notificationsRoute,
                profileRoute: profileRoute,
                onMenuTap: () => Scaffold.of(scaffoldContext).openDrawer(),
                showGreeting: showHeaderGreeting,
              ),
              Expanded(child: navigationShell),
            ],
          );
        },
      ),
      bottomNavigationBar: WmsShellNavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          for (final d in EnterpriseShellNavigation.destinations)
            WmsNavDestination(
              icon: d.icon,
              selectedIcon: d.selectedIcon,
              label: d.label,
            ),
        ],
      ),
    );
  }
}
