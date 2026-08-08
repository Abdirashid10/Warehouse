import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_drawer_profile_header.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_drawer_widgets.dart';

class WmsDrawerItem {
  const WmsDrawerItem({
    required this.label,
    required this.icon,
    this.bottomIndex,
    this.pushRoute,
    this.route,
  });

  final String label;
  final IconData icon;
  final int? bottomIndex;
  final String? pushRoute;

  /// Shell or pushed route used for active-state highlighting.
  final String? route;
}

class WmsDrawerSection {
  const WmsDrawerSection({this.title, required this.items});

  final String? title;
  final List<WmsDrawerItem> items;
}

class WmsAppDrawer extends StatelessWidget {
  const WmsAppDrawer({
    super.key,
    required this.subtitle,
    required this.currentBottomIndex,
    required this.onNavigate,
    this.items = const [],
    this.sections = const [],
    this.currentLocation = '',
    this.accentColor,
    this.roleOverride,
    this.warehouseOverride,
  });

  final String subtitle;
  final List<WmsDrawerItem> items;
  final List<WmsDrawerSection> sections;
  final int currentBottomIndex;
  final String currentLocation;
  final void Function(int? bottomIndex, String? pushRoute) onNavigate;
  final Color? accentColor;
  final String? roleOverride;
  final String? warehouseOverride;

  List<WmsDrawerSection> get _sections {
    if (sections.isNotEmpty) return sections;
    return [WmsDrawerSection(items: items)];
  }

  /// Flatten section groups into one ordered list (section titles not shown).
  List<WmsDrawerItem> get _allItems => [
        for (final section in _sections) ...section.items,
      ];

  bool _isSelected(WmsDrawerItem item) {
    final path = item.pushRoute ?? item.route;
    if (path != null && path.isNotEmpty) {
      if (currentLocation == path) return true;
      if (currentLocation.startsWith('$path/')) return true;
    }
    if (item.bottomIndex != null) {
      return item.bottomIndex == currentBottomIndex;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final accent = accentColor ?? colors.primary;
    final drawerItems = _allItems;

    return Drawer(
      width: WmsDrawerLayout.drawerWidth(context),
      backgroundColor: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WmsDrawerProfileHeader(
            subtitle: subtitle,
            accentColor: accent,
            roleOverride: roleOverride,
            warehouseOverride: warehouseOverride,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              children: [
                for (final item in drawerItems)
                  WmsDrawerMenuTile(
                    icon: item.icon,
                    label: item.label,
                    selected: _isSelected(item),
                    accentColor: accent,
                    onTap: () {
                      Navigator.pop(context);
                      if (item.pushRoute != null) {
                        onNavigate(null, item.pushRoute);
                      } else {
                        onNavigate(item.bottomIndex, null);
                      }
                    },
                  ),
              ],
            ),
          ),
          const WmsDrawerSignOut(),
        ],
      ),
    );
  }
}
