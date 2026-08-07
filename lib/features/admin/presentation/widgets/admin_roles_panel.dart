import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/features/admin/presentation/cubit/administration_cubit.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_atoms.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_theme.dart';

/// A capability the platform grants, and which tiers hold it.
class AdminCapability {
  const AdminCapability({
    required this.label,
    required this.icon,
    required this.tiers,
  });

  final String label;
  final IconData icon;

  /// Tiers that hold this capability. Absence is a denial, not an omission.
  final Set<AdminRoleTier> tiers;

  bool grantedTo(AdminRoleTier tier) => tiers.contains(tier);
}

/// A role as presented in the console.
class AdminRoleDefinition {
  const AdminRoleDefinition({
    required this.name,
    required this.tier,
    required this.accessLevel,
    required this.summary,
  });

  final String name;
  final AdminRoleTier tier;
  final String accessLevel;
  final String summary;
}

/// The console's access-control catalogue.
///
/// This mirrors the platform's documented role model. It is presentation
/// reference data, not an authorization source — the API remains the authority
/// on what any account may actually do.
abstract final class AdminRolesCatalog {
  static const roles = [
    AdminRoleDefinition(
      name: 'Admin',
      tier: AdminRoleTier.admin,
      accessLevel: 'Organization-wide',
      summary: 'Unrestricted configuration, identity and compliance control.',
    ),
    AdminRoleDefinition(
      name: 'Supervisor',
      tier: AdminRoleTier.supervisor,
      accessLevel: 'Warehouse operations',
      summary: 'Runs a facility: staffing, approvals and operational reporting.',
    ),
    AdminRoleDefinition(
      name: 'Staff',
      tier: AdminRoleTier.staff,
      accessLevel: 'Assigned warehouse',
      summary: 'Executes assigned work inside a single facility.',
    ),
  ];

  static const capabilities = [
    AdminCapability(
      label: 'System configuration',
      icon: Icons.tune_rounded,
      tiers: {AdminRoleTier.admin},
    ),
    AdminCapability(
      label: 'User & role management',
      icon: Icons.manage_accounts_rounded,
      tiers: {AdminRoleTier.admin},
    ),
    AdminCapability(
      label: 'Audit & compliance logs',
      icon: Icons.shield_rounded,
      tiers: {AdminRoleTier.admin},
    ),
    AdminCapability(
      label: 'All warehouses',
      icon: Icons.hub_rounded,
      tiers: {AdminRoleTier.admin},
    ),
    AdminCapability(
      label: 'Stock movement approval',
      icon: Icons.fact_check_rounded,
      tiers: {AdminRoleTier.admin, AdminRoleTier.supervisor},
    ),
    AdminCapability(
      label: 'Task assignment',
      icon: Icons.assignment_ind_rounded,
      tiers: {AdminRoleTier.admin, AdminRoleTier.supervisor},
    ),
    AdminCapability(
      label: 'Operational reports',
      icon: Icons.insights_rounded,
      tiers: {AdminRoleTier.admin, AdminRoleTier.supervisor},
    ),
    AdminCapability(
      label: 'Receive & dispatch stock',
      icon: Icons.local_shipping_rounded,
      tiers: {
        AdminRoleTier.admin,
        AdminRoleTier.supervisor,
        AdminRoleTier.staff,
      },
    ),
    AdminCapability(
      label: 'Process orders',
      icon: Icons.shopping_cart_rounded,
      tiers: {
        AdminRoleTier.admin,
        AdminRoleTier.supervisor,
        AdminRoleTier.staff,
      },
    ),
    AdminCapability(
      label: 'View assigned inventory',
      icon: Icons.inventory_2_rounded,
      tiers: {
        AdminRoleTier.admin,
        AdminRoleTier.supervisor,
        AdminRoleTier.staff,
      },
    ),
  ];
}

/// Roles tab — role cards plus a full capability matrix.
class AdminRolesPanel extends StatelessWidget {
  const AdminRolesPanel({super.key, required this.bundle, this.padding = false});

  final AdministrationBundle bundle;
  final bool padding;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);

    return AdminTabScroll(
      padding: padding,
      children: [
        AdminSectionIntro(
          eyebrow: 'Access control',
          title: 'Roles & Permissions',
          subtitle: 'Access tiers with live head-count from the directory',
          trailing: AdminGlowBadge(
            icon: Icons.admin_panel_settings_rounded,
            color: palette.violet,
            size: 36,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final role in AdminRolesCatalog.roles) ...[
          _RoleCard(
            role: role,
            userCount: bundle.userCountForRole(role.name),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
        ],
        const SizedBox(height: AppSpacing.sm),
        const AdminSectionIntro(
          eyebrow: 'Matrix',
          title: 'Capability Matrix',
          subtitle: 'A blank cell is an explicit denial, not an unknown',
        ),
        const SizedBox(height: AppSpacing.md),
        const _CapabilityMatrix(),
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
    final palette = AdminPalette.of(context);
    final colors = palette.colors;
    final accent = palette.roleColor(role.tier);

    final granted = AdminRolesCatalog.capabilities
        .where((capability) => capability.grantedTo(role.tier))
        .toList();

    return AdminGlassCard(
      accentStrip: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminGlowBadge(
                icon: AdminRoles.iconFor(role.tier),
                color: accent,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.cardTitle(context).copyWith(
                        color: colors.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.accessLevel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: colors.textTertiary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AdminStatusChip(
                label: '$userCount ${userCount == 1 ? 'user' : 'users'}',
                color: accent,
                icon: Icons.person_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            role.summary,
            style: WmsDesignTokens.supporting(context).copyWith(
              color: colors.textSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, thickness: 1, color: palette.hairline),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.key_rounded, size: 13, color: accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${granted.length} of ${AdminRolesCatalog.capabilities.length} capabilities',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AdminMicroBar(
            fraction: granted.length / AdminRolesCatalog.capabilities.length,
            color: accent,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final capability in granted.take(4))
                AdminStatusChip(
                  label: capability.label,
                  color: accent,
                  icon: capability.icon,
                  dense: true,
                ),
              if (granted.length > 4)
                AdminStatusChip(
                  label: '+${granted.length - 4} more',
                  color: palette.slate,
                  dense: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Capability rows against the three tiers, with an explicit grant/deny mark.
class _CapabilityMatrix extends StatelessWidget {
  const _CapabilityMatrix();

  static const _columnWidth = 42.0;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;

    return AdminGlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                const Expanded(child: SizedBox.shrink()),
                for (final role in AdminRolesCatalog.roles)
                  SizedBox(
                    width: _columnWidth,
                    child: Column(
                      children: [
                        Icon(
                          AdminRoles.iconFor(role.tier),
                          size: 14,
                          color: palette.roleColor(role.tier),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          role.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style:
                              WmsDesignTokens.supportingDense(context).copyWith(
                            color: colors.textTertiary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: palette.hairline),
          for (var i = 0; i < AdminRolesCatalog.capabilities.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: palette.hairline),
            _MatrixRow(capability: AdminRolesCatalog.capabilities[i]),
          ],
        ],
      ),
    );
  }
}

class _MatrixRow extends StatelessWidget {
  const _MatrixRow({required this.capability});

  final AdminCapability capability;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(capability.icon, size: 14, color: colors.textTertiary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    capability.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: colors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final role in AdminRolesCatalog.roles)
            SizedBox(
              width: _CapabilityMatrix._columnWidth,
              child: Center(
                child: capability.grantedTo(role.tier)
                    ? Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: palette.roleColor(role.tier),
                      )
                    : Icon(
                        Icons.remove_rounded,
                        size: 14,
                        color: colors.textTertiary.withValues(alpha: 0.45),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
