import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/features/admin/presentation/cubit/administration_cubit.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_account_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_activity_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_audit_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_notifications_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_roles_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_users_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_warehouses_panel.dart';
import 'package:logisticsmobile/features/audit/presentation/cubit/audit_cubit.dart';
import 'package:logisticsmobile/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:logisticsmobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:logisticsmobile/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:logisticsmobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:logisticsmobile/features/users/presentation/cubit/users_cubit.dart';
import 'package:logisticsmobile/widgets/wms/wms_kpi_strip.dart';
import 'package:logisticsmobile/widgets/wms/wms_pushed_scaffold.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

class AdministrationScreen extends StatefulWidget {
  const AdministrationScreen({super.key});

  @override
  State<AdministrationScreen> createState() => _AdministrationScreenState();
}

class _AdministrationScreenState extends State<AdministrationScreen>
    with StaffScopeInitMixin {
  AdministrationCubit? _adminCubit;
  UsersCubit? _usersCubit;
  AuditCubit? _auditCubit;
  NotificationsCubit? _notificationsCubit;
  ProfileCubit? _profileCubit;
  final _userSearchController = TextEditingController();
  final _auditSearchController = TextEditingController();

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    _adminCubit = AdministrationCubit(repositories)..load();
    _usersCubit = UsersCubit(repositories.users)..load();
    _auditCubit = AuditCubit(repositories.audit)..load();
    _notificationsCubit = NotificationsCubit(
      GetNotificationsUseCase(repositories.notifications),
    )..load();
    _profileCubit = ProfileCubit(GetProfileUseCase(repositories.profile))..load();
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    _auditSearchController.dispose();
    _adminCubit?.close();
    _usersCubit?.close();
    _auditCubit?.close();
    _notificationsCubit?.close();
    _profileCubit?.close();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _adminCubit!.refresh(),
      _usersCubit!.refresh(),
      _auditCubit!.refresh(),
      _notificationsCubit!.load(),
      _profileCubit!.load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final adminCubit = _adminCubit;
    final colors = WmsUiColors.of(context);
    if (adminCubit == null) {
      return const WmsPushedScaffold(
        title: 'Administration',
        body: StaffScopeLoadingBody(),
      );
    }

    return WmsPushedScaffold(
      title: 'Administration',
      body: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: adminCubit),
          BlocProvider.value(value: _usersCubit!),
          BlocProvider.value(value: _auditCubit!),
          BlocProvider.value(value: _notificationsCubit!),
          BlocProvider.value(value: _profileCubit!),
        ],
        child: BlocBuilder<AdministrationCubit, ResourceState<AdministrationBundle>>(
          builder: (context, state) {
            if (state.isLoading && state.data == null) {
              return const _AdminLoadingView();
            }
            if (state.isFailure && state.data == null) {
              return WmsErrorState(
                message: state.message ?? 'Failed to load administration',
                onRetry: adminCubit.load,
              );
            }
            final bundle = state.data;
            if (bundle == null) return const SizedBox.shrink();

            return DefaultTabController(
              length: 7,
              child: RefreshIndicator(
                onRefresh: _refreshAll,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _AdminHeader(bundle: bundle)),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _AdminTabDelegate(
                        child: Container(
                          color: colors.background,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                            vertical: AppSpacing.sm,
                          ),
                          child: const TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            tabs: [
                              Tab(text: 'Users'),
                              Tab(text: 'Roles'),
                              Tab(text: 'Warehouses'),
                              Tab(text: 'Audit'),
                              Tab(text: 'Activity'),
                              Tab(text: 'Alerts'),
                              Tab(text: 'Account'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: TabBarView(
                        children: [
                          AdminUsersPanel(
                            cubit: _usersCubit!,
                            searchController: _userSearchController,
                            padding: false,
                            recentAudit: bundle.auditActivities,
                          ),
                          AdminRolesPanel(bundle: bundle),
                          AdminWarehousesPanel(bundle: bundle),
                          AdminAuditPanel(
                            cubit: _auditCubit!,
                            searchController: _auditSearchController,
                            padding: false,
                          ),
                          AdminActivityPanel(activities: bundle.auditActivities),
                          AdminNotificationsPanel(
                            cubit: _notificationsCubit!,
                            padding: false,
                            sectioned: true,
                          ),
                          AdminAccountPanel(profileCubit: _profileCubit!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.bundle});

  final AdministrationBundle bundle;

  @override
  Widget build(BuildContext context) {
    final activeUsers = bundle.users.where((u) => u.isActive).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusXl),
          bottomRight: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Administration Center',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Users, roles, warehouses, compliance, and account controls',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          WmsKpiStrip(
            items: [
              WmsKpiItem(
                label: 'Users',
                value: '${bundle.users.where((u) => !u.archived).length}',
                icon: Icons.people_outline,
                color: AppColors.primary,
                background: Colors.white,
              ),
              WmsKpiItem(
                label: 'Active',
                value: '$activeUsers',
                icon: Icons.verified_user_outlined,
                color: AppColors.success,
                background: Colors.white,
              ),
              WmsKpiItem(
                label: 'Warehouses',
                value: '${bundle.warehouses.length}',
                icon: Icons.warehouse_outlined,
                color: AppColors.accent,
                background: Colors.white,
              ),
              WmsKpiItem(
                label: 'Unread',
                value: '${bundle.unreadCount}',
                icon: Icons.notifications_outlined,
                color: AppColors.warning,
                background: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminLoadingView extends StatelessWidget {
  const _AdminLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        WmsSkeletonBox(height: 140, radius: AppSpacing.radiusXl),
        SizedBox(height: AppSpacing.md),
        WmsKpiSkeleton(),
        SizedBox(height: AppSpacing.md),
        WmsSkeletonBox(height: 48, radius: AppSpacing.radiusMd),
      ],
    );
  }
}

class _AdminTabDelegate extends SliverPersistentHeaderDelegate {
  _AdminTabDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 62;

  @override
  double get maxExtent => 62;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _AdminTabDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
