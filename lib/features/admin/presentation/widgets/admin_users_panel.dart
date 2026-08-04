import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/features/audit/domain/entities/audit_activity.dart';
import 'package:logisticsmobile/features/users/presentation/cubit/users_cubit.dart';
import 'package:logisticsmobile/features/users/presentation/pages/user_detail_screen.dart';
import 'package:logisticsmobile/features/users/presentation/widgets/users_enterprise_widgets.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

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

  @override
  Widget build(BuildContext context) {
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

        return ListView(
          padding: padding
              ? const EdgeInsets.all(AppSpacing.screenPadding)
              : const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
          children: [
            UsersSearchSection(
              searchController: searchController,
              onSearchChanged: cubit.setSearch,
              selectedRole: data.roleFilter,
              onRoleSelected: cubit.setRoleFilter,
              selectedStatus: data.statusFilter,
              onStatusSelected: cubit.setStatusFilter,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (data.pageItems.isEmpty)
              UsersEmptyState(
                onClearFilters: () {
                  searchController.clear();
                  cubit.setSearch('');
                  cubit.setRoleFilter(null);
                  cubit.setStatusFilter(UserStatusFilter.all);
                },
              )
            else
              ...data.pageItems.map(
                (u) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: UserEnterpriseCard(
                    user: u,
                    onTap: () => openUserDetail(
                      context,
                      u,
                      auditActivities: recentAudit,
                    ),
                    onAction: (_) => openUserDetail(
                      context,
                      u,
                      auditActivities: recentAudit,
                    ),
                  ),
                ),
              ),
            if (data.totalPages > 1) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: data.page > 1 ? cubit.prevPage : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text('Page ${data.page} of ${data.totalPages}'),
                  IconButton(
                    onPressed: data.hasMore ? cubit.nextPage : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
