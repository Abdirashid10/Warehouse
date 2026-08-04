import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';
import 'package:logisticsmobile/features/users/presentation/cubit/users_cubit.dart';
import 'package:logisticsmobile/features/users/presentation/pages/user_detail_screen.dart';
import 'package:logisticsmobile/features/users/presentation/widgets/create_user_sheet.dart';
import 'package:logisticsmobile/features/users/presentation/widgets/users_enterprise_widgets.dart';
import 'package:logisticsmobile/features/users/presentation/theme/users_typography.dart';
import 'package:logisticsmobile/routes/route_names.dart';
import 'package:logisticsmobile/widgets/wms/wms_shell_navigation_bar.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> with StaffScopeInitMixin {
  UsersCubit? _cubit;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();

  static const _bottomNavIndex = 4;

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    _cubit = UsersCubit(repositories.users)..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _cubit?.close();
    super.dispose();
  }

  bool _isAdmin(BuildContext context) =>
      context.read<AuthBloc>().state.user?.role.isAdmin == true;

  void _clearFilters(UsersCubit cubit) {
    _searchController.clear();
    cubit.setSearch('');
    cubit.setRoleFilter(null);
    cubit.setStatusFilter(UserStatusFilter.all);
  }

  void _onBottomNavSelected(int index) {
    if (index == _bottomNavIndex) return;
    switch (index) {
      case 0:
        context.go(RoutePaths.adminDashboard);
      case 1:
        context.go(RoutePaths.adminInventory);
      case 2:
        context.push(RoutePaths.adminWarehouses);
      case 3:
        context.push(RoutePaths.adminTasks);
      case 4:
        break;
    }
  }

  void _webAdminNotice(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action is available in the NexusLogistics web admin.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleAction(UsersCubit cubit, WmsUser user, UserAction action) async {
    switch (action) {
      case UserAction.viewProfile:
        openUserDetail(context, user);
      case UserAction.editUser:
        _webAdminNotice('Edit user');
      case UserAction.assignWarehouse:
        _webAdminNotice('Assign warehouse');
      case UserAction.resetPassword:
        _webAdminNotice('Reset password');
      case UserAction.changeRole:
        _webAdminNotice('Change role');
      case UserAction.archiveUser:
        _webAdminNotice('Archive user');
      case UserAction.activateUser:
        final next = user.isActive ? 'Inactive' : 'Active';
        await cubit.updateStatus(user, next);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName} is now $next')),
        );
      case UserAction.deleteUser:
        _webAdminNotice('Delete user');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    final colors = WmsUiColors.of(context);
    final isAdmin = _isAdmin(context);

    if (cubit == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const StaffScopeLoadingBody(),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocProvider.value(
        value: cubit,
        child: BlocBuilder<UsersCubit, ResourceState<UsersListState>>(
          builder: (context, state) {
            if (state.isLoading && state.data == null) {
              return const _UsersLoadingView();
            }
            if (state.isFailure && state.data == null) {
              return WmsErrorState(
                message: state.message ?? 'Failed to load users',
                onRetry: cubit.load,
              );
            }

            final data = state.data;
            if (data == null) return const SizedBox.shrink();

            final summary = UsersKpiSummary.fromUsers(data.allUsers);

            return RefreshIndicator(
              onRefresh: cubit.refresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: UsersEnterpriseHeader(
                      totalUsers: summary.totalUsers,
                      onNewUser: () => showCreateUserSheet(context, cubit: cubit),
                      onBack: () => context.pop(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
                  SliverToBoxAdapter(child: UsersKpiStrip(summary: summary)),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
                  SliverToBoxAdapter(
                    child: UsersSearchSection(
                      searchController: _searchController,
                      searchFocusNode: _searchFocusNode,
                      onSearchChanged: cubit.setSearch,
                      selectedRole: data.roleFilter,
                      onRoleSelected: cubit.setRoleFilter,
                      selectedStatus: data.statusFilter,
                      onStatusSelected: cubit.setStatusFilter,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
                  if (data.pageItems.isEmpty)
                    SliverToBoxAdapter(
                      child: UsersEmptyState(
                        onClearFilters: () => _clearFilters(cubit),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= data.pageItems.length) return null;
                            final user = data.pageItems[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: UserEnterpriseCard(
                                user: user,
                                isAdmin: isAdmin,
                                onTap: () => openUserDetail(context, user),
                                onAction: (action) =>
                                    _handleAction(cubit, user, action),
                              ),
                            );
                          },
                          childCount: data.pageItems.length,
                        ),
                      ),
                    ),
                  if (data.totalPages > 1)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: data.page > 1 ? cubit.prevPage : null,
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                            Text(
                              'Page ${data.page} of ${data.totalPages}',
                              style: UsersTypography.pagination(context),
                            ),
                            IconButton(
                              onPressed: data.hasMore ? cubit.nextPage : null,
                              icon: const Icon(Icons.chevron_right_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxxl + AppSpacing.bottomNavHeight),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: WmsShellNavigationBar(
        selectedIndex: _bottomNavIndex,
        onDestinationSelected: _onBottomNavSelected,
        destinations: const [
          WmsNavDestination(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          WmsNavDestination(
            icon: Icons.inventory_2_outlined,
            selectedIcon: Icons.inventory_2_rounded,
            label: 'Inventory',
          ),
          WmsNavDestination(
            icon: Icons.warehouse_outlined,
            selectedIcon: Icons.warehouse_rounded,
            label: 'Warehouse',
          ),
          WmsNavDestination(
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment_rounded,
            label: 'Tasks',
          ),
          WmsNavDestination(
            icon: Icons.people_outline,
            selectedIcon: Icons.people_rounded,
            label: 'Users',
          ),
        ],
      ),
    );
  }
}

class _UsersLoadingView extends StatelessWidget {
  const _UsersLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        WmsSkeletonBox(height: 160, radius: AppSpacing.radiusLg),
        SizedBox(height: AppSpacing.lg),
        WmsKpiSkeleton(),
        SizedBox(height: AppSpacing.lg),
        WmsListSkeleton(),
      ],
    );
  }
}
