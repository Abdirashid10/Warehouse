import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/auth/domain/entities/user_role.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';
import 'package:logisticsmobile/features/users/presentation/cubit/users_cubit.dart';
import 'package:logisticsmobile/features/users/presentation/theme/users_typography.dart';
import 'package:logisticsmobile/widgets/app_card.dart';

/// Web-parity enterprise header for Users administration.
class UsersEnterpriseHeader extends StatelessWidget {
  const UsersEnterpriseHeader({
    super.key,
    required this.totalUsers,
    required this.onNewUser,
    this.onBack,
  });

  final int totalUsers;
  final VoidCallback onNewUser;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    return Padding(
      padding: WmsDesignTokens.screenHorizontalPadding(
        MediaQuery.sizeOf(context).width,
      ).copyWith(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null) ...[
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              style: IconButton.styleFrom(
                foregroundColor: colors.textPrimary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 40),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined, size: WmsIconSizes.status, color: colors.primary),
            const SizedBox(width: WmsIconSizes.iconLabelGap),
              Text(
                'ADMINISTRATION',
                style: WmsDesignTokens.supportingDense(context).copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              Icon(Icons.chevron_right, size: WmsIconSizes.listLeading, color: colors.textTertiary),
              Text(
                'USERS',
                style: WmsDesignTokens.supportingDense(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Users',
                      style: WmsDesignTokens.pageTitle(context),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Create, edit, promote, archive, and manage system users.',
                      style: UsersTypography.pageSubtitle(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      '$totalUsers',
                      style: UsersTypography.kpiNumber(
                        context,
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      'Total',
                      style: UsersTypography.kpiLabel(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onNewUser,
              icon: const Icon(Icons.add, size: WmsIconSizes.actionButton),
              label: Text(
                'New User',
                style: WmsDesignTokens.buttonLabel(context).copyWith(
                  color: colors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UsersKpiSummary {
  const UsersKpiSummary({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.administrators,
    required this.supervisors,
    required this.staffMembers,
  });

  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int administrators;
  final int supervisors;
  final int staffMembers;

  factory UsersKpiSummary.fromUsers(List<WmsUser> users) {
    final visible = users.where((u) => !u.archived).toList();
    return UsersKpiSummary(
      totalUsers: visible.length,
      activeUsers: visible.where((u) => u.isActive).length,
      inactiveUsers: visible.where((u) => !u.isActive).length,
      administrators: visible
          .where((u) => UserRole.fromString(u.role) == UserRole.admin)
          .length,
      supervisors: visible
          .where((u) => UserRole.fromString(u.role) == UserRole.supervisor)
          .length,
      staffMembers: visible.where((u) {
        final role = UserRole.fromString(u.role);
        return role == UserRole.staff || role == UserRole.unknown;
      }).length,
    );
  }
}

class UsersKpiStrip extends StatelessWidget {
  const UsersKpiStrip({super.key, required this.summary});

  final UsersKpiSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final items = [
      _KpiDef('Total Users', '${summary.totalUsers}', Icons.people_outline, colors.primary),
      _KpiDef('Active', '${summary.activeUsers}', Icons.verified_user_outlined, colors.success),
      _KpiDef('Inactive', '${summary.inactiveUsers}', Icons.person_off_outlined, colors.error),
      _KpiDef('Administrators', '${summary.administrators}', Icons.shield_outlined, const Color(0xFF9333EA)),
      _KpiDef('Supervisors', '${summary.supervisors}', Icons.supervisor_account_outlined, const Color(0xFFEA580C)),
      _KpiDef('Staff', '${summary.staffMembers}', Icons.badge_outlined, const Color(0xFF2563EB)),
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) => _UsersKpiCard(item: items[i]),
      ),
    );
  }
}

class _KpiDef {
  const _KpiDef(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _UsersKpiCard extends StatelessWidget {
  const _UsersKpiCard({required this.item});
  final _KpiDef item;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(
                item.icon,
                size: WmsIconSizes.listLeading,
                color: item.color,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                    Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: UsersTypography.kpiLabel(context),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UsersTypography.kpiNumber(
                        context,
                        color: item.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class UsersSearchSection extends StatelessWidget {
  const UsersSearchSection({
    super.key,
    required this.searchController,
    this.searchFocusNode,
    required this.onSearchChanged,
    required this.selectedRole,
    required this.onRoleSelected,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  final TextEditingController searchController;
  final FocusNode? searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final String? selectedRole;
  final ValueChanged<String?> onRoleSelected;
  final UserStatusFilter selectedStatus;
  final ValueChanged<UserStatusFilter> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search & Filters', style: WmsDesignTokens.sectionTitle(context)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            onChanged: onSearchChanged,
            style: UsersTypography.searchField(context),
            decoration: InputDecoration(
              hintText: 'Search by username, email, or role…',
              hintStyle: UsersTypography.searchHint(context),
              prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Role', style: UsersTypography.filterSectionLabel(context)),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: 'All', selected: selectedRole == null, onTap: () => onRoleSelected(null)),
                for (final role in UserRoleFilters.chips) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: role,
                    selected: selectedRole == role,
                    color: UserRoleBadge.colorFor(role),
                    onTap: () => onRoleSelected(role),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Status', style: UsersTypography.filterSectionLabel(context)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final filter in UserStatusFilter.values) ...[
                if (filter != UserStatusFilter.values.first) const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: _statusLabel(filter),
                  selected: selectedStatus == filter,
                  onTap: () => onStatusSelected(filter),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _statusLabel(UserStatusFilter filter) {
    switch (filter) {
      case UserStatusFilter.all:
        return 'All';
      case UserStatusFilter.active:
        return 'Active';
      case UserStatusFilter.inactive:
        return 'Inactive';
    }
  }
}

class UserRoleBadge {
  static Color colorFor(String role) {
    switch (UserRole.fromString(role)) {
      case UserRole.admin:
        return const Color(0xFF9333EA);
      case UserRole.supervisor:
        return const Color(0xFFEA580C);
      case UserRole.staff:
      case UserRole.unknown:
        return const Color(0xFF2563EB);
    }
  }

  static String labelFor(WmsUser user) {
    switch (UserRole.fromString(user.role)) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.staff:
        return 'Staff';
      case UserRole.unknown:
        return user.role;
    }
  }
}

enum UserAction {
  viewProfile,
  editUser,
  assignWarehouse,
  resetPassword,
  changeRole,
  archiveUser,
  activateUser,
  deleteUser,
}

class UserEnterpriseCard extends StatelessWidget {
  const UserEnterpriseCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onAction,
    this.isAdmin = true,
  });

  final WmsUser user;
  final VoidCallback onTap;
  final ValueChanged<UserAction> onAction;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final roleColor = UserRoleBadge.colorFor(user.role);
    final roleLabel = UserRoleBadge.labelFor(user);
    final isActive = user.isActive;
    final statusColor = isActive ? colors.success : colors.error;

    return AppCard(
      onTap: onTap,
      elevated: true,
      accentColor: roleColor,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserAvatar(initials: user.initials, color: roleColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: UsersTypography.userName(context),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      user.email,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: UsersTypography.email(context),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UsersTypography.usernameHandle(context),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showActions(context),
                icon: Icon(Icons.more_vert_rounded, color: colors.textSecondary),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _UserBadge(label: roleLabel, color: roleColor, icon: Icons.badge_outlined),
              _UserBadge(
                label: user.status,
                color: statusColor,
                icon: isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
              ),
              _UserBadge(
                label: user.assignedWarehouse ?? 'Unassigned',
                color: colors.info,
                icon: Icons.warehouse_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _MetaRow(
            icon: Icons.schedule_rounded,
            label: 'Last login',
            value: user.lastLoginAt != null
                ? WmsFormatters.dateTimeShort(user.lastLoginAt)
                : 'Never',
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetaRow(
            icon: Icons.calendar_today_outlined,
            label: 'Created',
            value: WmsFormatters.dateShort(user.createdAt),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('View profile', style: UsersTypography.actionLink(context)),
              Icon(Icons.chevron_right_rounded, size: WmsIconSizes.listLeading, color: colors.primary),
            ],
          ),
        ],
      ),
    );
  }

  void _showActions(BuildContext context) {
    showUserActionsSheet(context, user: user, isAdmin: isAdmin, onAction: onAction);
  }
}

void showUserActionsSheet(
  BuildContext context, {
  required WmsUser user,
  required bool isAdmin,
  required ValueChanged<UserAction> onAction,
}) {
  final colors = WmsUiColors.of(context);
  final items = <({UserAction action, IconData icon, String label, Color? color})>[
    (action: UserAction.viewProfile, icon: Icons.person_outline, label: 'View Profile', color: null),
    (action: UserAction.editUser, icon: Icons.edit_outlined, label: 'Edit User', color: null),
    (action: UserAction.assignWarehouse, icon: Icons.warehouse_outlined, label: 'Assign Warehouse', color: null),
    (action: UserAction.resetPassword, icon: Icons.lock_reset_outlined, label: 'Reset Password', color: null),
    (action: UserAction.changeRole, icon: Icons.swap_horiz_rounded, label: 'Change Role', color: null),
    (action: UserAction.archiveUser, icon: Icons.archive_outlined, label: 'Archive User', color: colors.warning),
    if (user.isActive)
      (action: UserAction.activateUser, icon: Icons.person_off_outlined, label: 'Deactivate User', color: colors.error)
    else
      (action: UserAction.activateUser, icon: Icons.person_add_alt_1, label: 'Activate User', color: colors.success),
    if (isAdmin)
      (action: UserAction.deleteUser, icon: Icons.delete_outline, label: 'Delete User', color: colors.error),
  ];

  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('User Actions', style: WmsDesignTokens.sectionTitle(ctx)),
              Text(user.displayName, style: UsersTypography.userName(ctx)),
              Text(user.email, style: UsersTypography.email(ctx)),
              const SizedBox(height: AppSpacing.md),
              for (final item in items)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  leading: Icon(item.icon, color: item.color ?? colors.textSecondary),
                  title: Text(
                    item.label,
                    style: UsersTypography.searchField(ctx),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onAction(item.action);
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

class UsersEmptyState extends StatelessWidget {
  const UsersEmptyState({super.key, this.onClearFilters});
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: AppCard(
        elevated: true,
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded, size: 48, color: colors.primary.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.lg),
            Text('No users found', style: WmsDesignTokens.sectionTitle(context)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Adjust search or filters to find system users.',
              textAlign: TextAlign.center,
              style: WmsDesignTokens.body(context).copyWith(color: colors.textSecondary),
            ),
            if (onClearFilters != null) ...[
              const SizedBox(height: AppSpacing.lg),
              TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.initials, required this.color});
  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        initials,
        style: WmsDesignTokens.body(context).copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _UserBadge extends StatelessWidget {
  const _UserBadge({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: WmsComponentStyles.badgeDecoration(foreground: color, background: color.withValues(alpha: 0.1)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: WmsIconSizes.status, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: UsersTypography.badge(context, color: color),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: WmsIconSizes.status, color: colors.textTertiary),
        const SizedBox(width: 6),
        Text('$label: ', style: UsersTypography.metadata(context)),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: UsersTypography.metadataValue(context),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final accent = color ?? colors.primary;
    return FilterChip(
      label: Text(
        label,
        style: UsersTypography.filterChip(
          context,
          color: selected ? accent : colors.textSecondary,
        ).copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: accent.withValues(alpha: 0.12),
      checkmarkColor: accent,
      side: BorderSide(color: selected ? accent : colors.border),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
