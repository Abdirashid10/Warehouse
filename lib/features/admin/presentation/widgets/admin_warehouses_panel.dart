import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/utils/warehouse_staff_count.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/admin/presentation/cubit/administration_cubit.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_atoms.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_theme.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';

/// Warehouses tab — capacity, staffing and supervision per facility.
class AdminWarehousesPanel extends StatelessWidget {
  const AdminWarehousesPanel({
    super.key,
    required this.bundle,
    this.padding = false,
  });

  final AdministrationBundle bundle;
  final bool padding;

  List<WmsUser> _usersForWarehouse(String warehouseName) {
    return bundle.users
        .where((u) =>
            !u.archived &&
            u.assignedWarehouse != null &&
            u.assignedWarehouse == warehouseName)
        .toList();
  }

  List<WmsUser> _staffForWarehouse(String warehouseName) {
    return _usersForWarehouse(warehouseName)
        .where((user) => isOperationalWarehouseStaffRole(user.role))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);

    if (bundle.warehouses.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.warehouse_rounded,
        title: 'No warehouses',
        message:
            'Facility records will appear here once they are available to '
            'your account.',
      );
    }

    final totalCapacity =
        bundle.warehouses.fold<num>(0, (sum, w) => sum + w.capacity);

    return AdminTabScroll(
      padding: padding,
      children: [
        AdminSectionIntro(
          eyebrow: 'Infrastructure',
          title: 'Warehouse Assignment',
          subtitle: '${bundle.warehouses.length} facilities · '
              '${WmsFormatters.quantity(totalCapacity)} units of capacity',
          trailing: AdminGlowBadge(
            icon: Icons.warehouse_rounded,
            color: palette.cobalt,
            size: 36,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final warehouse in bundle.warehouses) ...[
          _WarehouseCard(
            warehouse: warehouse,
            assignedUsers: _usersForWarehouse(warehouse.name),
            staffUsers: _staffForWarehouse(warehouse.name),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
        ],
        const SizedBox(height: AppSpacing.sm),
        const _AssignmentNotice(),
      ],
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  const _WarehouseCard({
    required this.warehouse,
    required this.assignedUsers,
    required this.staffUsers,
  });

  final Warehouse warehouse;
  final List<WmsUser> assignedUsers;
  final List<WmsUser> staffUsers;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;

    final supervisor = assignedUsers
        .where((u) => AdminRoles.tierOf(u.role) == AdminRoleTier.supervisor)
        .map((u) => u.displayName)
        .firstOrNull;

    final utilization = warehouse.utilizationPercent;
    final capacityColor = palette.capacityColor(utilization);

    return AdminGlassCard(
      accentStrip: capacityColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminGlowBadge(
                icon: Icons.warehouse_rounded,
                color: capacityColor,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warehouse.name,
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
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.place_rounded,
                          size: 12,
                          color: colors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            warehouse.location.isEmpty
                                ? 'No location set'
                                : warehouse.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WmsDesignTokens.supportingDense(context)
                                .copyWith(
                              color: colors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AdminStatusChip(
                label: '${staffUsers.length} staff',
                color: palette.cobalt,
                icon: Icons.groups_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'CAPACITY USED',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$utilization%',
                style: WmsDesignTokens.cardNumber(context).copyWith(
                  color: capacityColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AdminMicroBar(
            fraction: utilization / 100,
            color: capacityColor,
            height: 7,
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, thickness: 1, color: palette.hairline),
          const SizedBox(height: 6),
          AdminInfoRow(
            icon: Icons.supervisor_account_rounded,
            label: 'Supervisor',
            value: supervisor ?? 'Not assigned',
            valueColor: supervisor == null ? colors.textTertiary : null,
          ),
          AdminInfoRow(
            icon: Icons.inventory_2_rounded,
            label: 'Capacity',
            value: '${WmsFormatters.quantity(warehouse.capacity)} units',
          ),
          AdminInfoRow(
            icon: Icons.badge_rounded,
            label: 'Assigned',
            value: '${assignedUsers.length} accounts',
          ),
          if (staffUsers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final user in staffUsers.take(5))
                  _StaffChip(user: user),
                if (staffUsers.length > 5)
                  AdminStatusChip(
                    label: '+${staffUsers.length - 5} more',
                    color: palette.slate,
                    dense: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StaffChip extends StatelessWidget {
  const _StaffChip({required this.user});

  final WmsUser user;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;
    final accent = palette.roleColor(AdminRoles.tierOf(user.role));

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 11, 4),
      decoration: BoxDecoration(
        color: palette.insetFill,
        borderRadius: BorderRadius.circular(AdminPalette.radiusPill),
        border: palette.glassBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdminAvatar(initials: user.initials, accent: accent, size: 22),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              user.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Explains why assignment is read-only on mobile today.
class _AssignmentNotice extends StatelessWidget {
  const _AssignmentNotice();

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;

    return AdminGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminGlowBadge(
                icon: Icons.person_add_alt_1_rounded,
                color: palette.brand,
                size: 34,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Assign user to warehouse',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.cardTitle(context).copyWith(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            'Assignment changes are made in the web console while the mobile '
            'assign endpoint is unavailable. This card will become an inline '
            'form once that API ships.',
            style: WmsDesignTokens.supporting(context).copyWith(
              color: colors.textSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AdminGradientButton(
            icon: Icons.open_in_new_rounded,
            label: 'Open assignment form',
            expanded: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  content: const Text(
                    'Assignment UI is ready — connect the assign-user API to '
                    'persist changes.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
