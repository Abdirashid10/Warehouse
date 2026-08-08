import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_atoms.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_theme.dart';
import 'package:logisticsmobile/features/audit/domain/entities/audit_activity.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';
import 'package:logisticsmobile/features/users/presentation/cubit/users_cubit.dart';
import 'package:logisticsmobile/features/users/presentation/pages/user_detail_screen.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Directory tab of the Administration console.
class AdminUsersPanel extends StatelessWidget {
  const AdminUsersPanel({
    super.key,
    required this.cubit,
    required this.searchController,
    this.padding = true,
    this.recentAudit = const [],
  });

  final UsersCubit cubit;
  final TextEditingController searchController;
  final bool padding;
  final List<AuditActivity> recentAudit;

  void _clearFilters() {
    searchController.clear();
    cubit.setSearch('');
    cubit.setRoleFilter(null);
    cubit.setStatusFilter(UserStatusFilter.all);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);

    return BlocBuilder<UsersCubit, ResourceState<UsersListState>>(
      builder: (context, state) {
        if (state.isLoading && state.data == null) {
          return const WmsListSkeleton();
        }
        if (state.isFailure && state.data == null) {
          return WmsErrorState(
            message: state.message ?? 'Failed to load users',
            onRetry: cubit.load,
          );
        }
        final data = state.data;
        if (data == null) return const SizedBox.shrink();

        final hasFilters = data.searchQuery.isNotEmpty ||
            data.roleFilter != null ||
            data.statusFilter != UserStatusFilter.all;

        return AdminTabScroll(
          padding: padding,
          children: [
            AdminSectionIntro(
              eyebrow: 'Identity',
              title: 'User Directory',
              subtitle: '${data.filtered.length} of '
                  '${data.allUsers.where((u) => !u.archived).length} accounts',
              trailing: AdminGlowBadge(
                icon: Icons.groups_rounded,
                color: palette.brand,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AdminSearchField(
              controller: searchController,
              hint: 'Search name, username, email…',
              onChanged: cubit.setSearch,
            ),
            const SizedBox(height: AppSpacing.md),
            _UserFilterBar(
              data: data,
              onRole: cubit.setRoleFilter,
              onStatus: cubit.setStatusFilter,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (data.pageItems.isEmpty)
              AdminEmptyState(
                icon: Icons.person_search_rounded,
                title: 'No matching accounts',
                message: hasFilters
                    ? 'No directory entries match the current search or filters.'
                    : 'User accounts will appear here once the directory loads.',
                actionLabel: hasFilters ? 'Clear filters' : null,
                actionIcon: Icons.restart_alt_rounded,
                onAction: hasFilters ? _clearFilters : null,
              )
            else
              ...data.pageItems.map(
                (user) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                  child: AdminUserCard(
                    user: user,
                    onTap: () => openUserDetail(
                      context,
                      user,
                      auditActivities: recentAudit,
                    ),
                  ),
                ),
              ),
            if (data.totalPages > 1) ...[
              const SizedBox(height: AppSpacing.md),
              _Pager(
                page: data.page,
                totalPages: data.totalPages,
                onPrevious: data.page > 1 ? cubit.prevPage : null,
                onNext: data.hasMore ? cubit.nextPage : null,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Elevated directory card: avatar, role identity, structured metadata.
class AdminUserCard extends StatelessWidget {
  const AdminUserCard({super.key, required this.user, this.onTap});

  final WmsUser user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;
    final tier = AdminRoles.tierOf(user.role);
    final roleColor = palette.roleColor(tier);
    final statusColor =
        user.isActive ? palette.emerald : palette.status(AdminStatus.neutral);

    return AdminGlassCard(
      accentStrip: roleColor,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminAvatar(
                initials: user.initials,
                accent: roleColor,
                statusColor: statusColor,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.cardTitle(context).copyWith(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: colors.textTertiary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        AdminStatusChip(
                          label: user.role,
                          color: roleColor,
                          icon: AdminRoles.iconFor(tier),
                          dense: true,
                        ),
                        AdminStatusChip(
                          label: user.isActive ? 'Active' : user.status,
                          color: statusColor,
                          icon: user.isActive
                              ? Icons.check_circle_rounded
                              : Icons.pause_circle_rounded,
                          dense: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.more_horiz_rounded,
                  size: 18,
                  color: colors.textTertiary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, thickness: 1, color: palette.hairline),
          const SizedBox(height: 6),
          AdminInfoRow(
            icon: Icons.alternate_email_rounded,
            label: 'Email',
            value: user.email.isEmpty ? '—' : user.email,
          ),
          AdminInfoRow(
            icon: Icons.warehouse_rounded,
            label: 'Warehouse',
            value: user.assignedWarehouse?.isNotEmpty == true
                ? user.assignedWarehouse!
                : 'Not assigned',
            valueColor: user.assignedWarehouse?.isNotEmpty == true
                ? null
                : colors.textTertiary,
          ),
          AdminInfoRow(
            icon: Icons.login_rounded,
            label: 'Last login',
            value: user.lastLoginAt == null
                ? 'Never signed in'
                : WmsFormatters.relativeTime(user.lastLoginAt),
            valueColor: user.lastLoginAt == null ? colors.textTertiary : null,
          ),
        ],
      ),
    );
  }
}

class _UserFilterBar extends StatelessWidget {
  const _UserFilterBar({
    required this.data,
    required this.onRole,
    required this.onStatus,
  });

  final UsersListState data;
  final ValueChanged<String?> onRole;
  final ValueChanged<UserStatusFilter> onStatus;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);

    final activeCount = data.allUsers.where((u) => u.isActive).length;
    final inactiveCount =
        data.allUsers.where((u) => !u.archived && !u.isActive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.zero,
            children: [
              AdminFilterPill(
                label: 'All roles',
                selected: data.roleFilter == null,
                onTap: () => onRole(null),
              ),
              for (final role in UserRoleFilters.chips) ...[
                const SizedBox(width: AppSpacing.sm),
                AdminFilterPill(
                  label: role,
                  icon: AdminRoles.iconFor(AdminRoles.tierOf(role)),
                  accent: palette.roleColor(AdminRoles.tierOf(role)),
                  selected: data.roleFilter == role,
                  onTap: () => onRole(data.roleFilter == role ? null : role),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.zero,
            children: [
              AdminFilterPill(
                label: 'Any status',
                selected: data.statusFilter == UserStatusFilter.all,
                onTap: () => onStatus(UserStatusFilter.all),
              ),
              const SizedBox(width: AppSpacing.sm),
              AdminFilterPill(
                label: 'Active',
                count: activeCount,
                icon: Icons.check_circle_rounded,
                accent: palette.emerald,
                selected: data.statusFilter == UserStatusFilter.active,
                onTap: () => onStatus(UserStatusFilter.active),
              ),
              const SizedBox(width: AppSpacing.sm),
              AdminFilterPill(
                label: 'Inactive',
                count: inactiveCount,
                icon: Icons.pause_circle_rounded,
                accent: palette.slate,
                selected: data.statusFilter == UserStatusFilter.inactive,
                onTap: () => onStatus(UserStatusFilter.inactive),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PagerButton(
          icon: Icons.chevron_left_rounded,
          onTap: onPrevious,
          tooltip: 'Previous page',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Page $page of $totalPages',
            style: WmsDesignTokens.supportingDense(context).copyWith(
              color: colors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _PagerButton(
          icon: Icons.chevron_right_rounded,
          onTap: onNext,
          tooltip: 'Next page',
        ),
      ],
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final enabled = onTap != null;
    final radius = BorderRadius.circular(AdminPalette.radiusControl);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.insetFill,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? palette.brand
                  : palette.colors.textTertiary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
