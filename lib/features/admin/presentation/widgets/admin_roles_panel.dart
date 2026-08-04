import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/features/admin/presentation/cubit/administration_cubit.dart';
import 'package:logisticsmobile/widgets/app_card.dart';

class AdminRoleDefinition {
  const AdminRoleDefinition({
    required this.name,
    required this.accessLevel,
    required this.permissions,
    required this.icon,
    required this.color,
  });

  final String name;
  final String accessLevel;
  final List<String> permissions;
  final IconData icon;
  final Color color;
}

abstract final class AdminRolesCatalog {
  static const roles = [
    AdminRoleDefinition(
      name: 'Admin',
      accessLevel: 'Organization-wide',
      icon: Icons.admin_panel_settings_outlined,
      color: AppColors.primary,
      permissions: [
        'Full system configuration',
        'User & role management',
        'All warehouses & inventory',
        'Reports & audit logs',
        'Order & task oversight',
      ],
    ),
    AdminRoleDefinition(
      name: 'Supervisor',
      accessLevel: 'Warehouse operations',
      icon: Icons.supervisor_account_outlined,
      color: AppColors.accent,
      permissions: [
        'Warehouse inventory control',
        'Staff task assignment',
        'Stock movements approval',
        'Order processing',
        'Operational reports',
      ],
    ),
    AdminRoleDefinition(
      name: 'Staff',
      accessLevel: 'Assigned warehouse',
      icon: Icons.engineering_outlined,
      color: AppColors.info,
      permissions: [
        'Receive & dispatch stock',
        'Execute assigned tasks',
        'Process orders',
        'View warehouse inventory',
        'Personal notifications',
      ],
    ),
  ];
}

class AdminRolesPanel extends StatelessWidget {
  const AdminRolesPanel({super.key, required this.bundle});

  final AdministrationBundle bundle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
      children: [
        Text(
          'Role management',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Access levels and permissions by role (user counts from live directory)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final role in AdminRolesCatalog.roles) ...[
          _RoleCard(
            role: role,
            userCount: bundle.userCountForRole(role.name),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.userCount});

  final AdminRoleDefinition role;
  final int userCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: role.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(role.icon, color: role.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      role.accessLevel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  '$userCount users',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Permissions',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final permission in role.permissions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: role.color),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(permission, style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
