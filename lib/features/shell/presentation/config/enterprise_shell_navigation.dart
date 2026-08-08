import 'package:flutter/material.dart';

/// Shared bottom navigation configuration for all roles.
abstract final class EnterpriseShellNavigation {
  static const destinations = [
    EnterpriseNavItem(
      icon: Icons.dashboard_rounded,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    EnterpriseNavItem(
      icon: Icons.inventory_2_rounded,
      selectedIcon: Icons.inventory_2_rounded,
      label: 'Inventory',
    ),
    EnterpriseNavItem(
      icon: Icons.shopping_cart_rounded,
      selectedIcon: Icons.shopping_cart_rounded,
      label: 'Orders',
    ),
    EnterpriseNavItem(
      icon: Icons.assignment_rounded,
      selectedIcon: Icons.assignment_rounded,
      label: 'Tasks',
    ),
    EnterpriseNavItem(
      icon: Icons.person_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  static const tabTitles = [
    'Dashboard',
    'Inventory',
    'Orders',
    'Tasks',
    'Profile',
  ];
}

class EnterpriseNavItem {
  const EnterpriseNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
