import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_typography.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';

class WmsNavDestination {
  const WmsNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class WmsShellNavigationBar extends StatelessWidget {
  const WmsShellNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<WmsNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    final inactiveColor = isLight
        ? AppTypographyColors.secondaryText
        : scheme.onSurfaceVariant;

    return Material(
      color: scheme.surface,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: wms.border.withValues(alpha: 0.7))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: SizedBox(
              height: MobileUi.bottomNavHeight,
              child: Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Expanded(
                      child: _WmsNavItem(
                        destination: destinations[i],
                        selected: i == selectedIndex,
                        primary: scheme.primary,
                        mutedColor: inactiveColor,
                        indicatorColor: wms.primaryLight,
                        onTap: () => onDestinationSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WmsNavItem extends StatelessWidget {
  const _WmsNavItem({
    required this.destination,
    required this.selected,
    required this.primary,
    required this.mutedColor,
    required this.indicatorColor,
    required this.onTap,
  });

  final WmsNavDestination destination;
  final bool selected;
  final Color primary;
  final Color mutedColor;
  final Color indicatorColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? primary : mutedColor;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? indicatorColor.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: MobileUi.bottomNavIconSize,
                color: color,
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 14,
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: WmsDesignTokens.bottomNavLabel(
                      context,
                      selected: selected,
                      color: color,
                    ).copyWith(fontSize: MobileUi.bottomNavLabelSize),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
