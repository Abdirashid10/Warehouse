import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/features/admin/presentation/cubit/administration_cubit.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_account_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_activity_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_alerts_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_audit_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_atoms.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_theme.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_roles_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_users_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_warehouses_panel.dart';
import 'package:logisticsmobile/features/audit/presentation/cubit/audit_cubit.dart';
import 'package:logisticsmobile/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:logisticsmobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:logisticsmobile/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:logisticsmobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:logisticsmobile/features/users/presentation/cubit/users_cubit.dart';
import 'package:logisticsmobile/widgets/wms/wms_pill_tab_bar.dart';
import 'package:logisticsmobile/widgets/wms/wms_pushed_scaffold.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Administration Center — the platform's control panel.
///
/// Composition: an indigo hero banner carrying the bento metric grid, a pinned
/// pill navigation bar, and seven console surfaces beneath it.
class AdministrationScreen extends StatefulWidget {
  const AdministrationScreen({super.key});

  @override
  State<AdministrationScreen> createState() => _AdministrationScreenState();
}

class _AdministrationScreenState extends State<AdministrationScreen>
    with StaffScopeInitMixin, TickerProviderStateMixin {
  static const _tabs = [
    WmsPillTabSpec(label: 'Users', icon: Icons.groups_rounded),
    WmsPillTabSpec(label: 'Roles', icon: Icons.admin_panel_settings_rounded),
    WmsPillTabSpec(label: 'Warehouses', icon: Icons.warehouse_rounded),
    WmsPillTabSpec(label: 'Audit', icon: Icons.shield_rounded),
    WmsPillTabSpec(label: 'Activity', icon: Icons.timeline_rounded),
    WmsPillTabSpec(label: 'Alerts', icon: Icons.notifications_active_rounded),
    WmsPillTabSpec(label: 'Account', icon: Icons.badge_rounded),
  ];

  AdministrationCubit? _adminCubit;
  UsersCubit? _usersCubit;
  AuditCubit? _auditCubit;
  NotificationsCubit? _notificationsCubit;
  ProfileCubit? _profileCubit;

  late final TabController _tabController =
      TabController(length: _tabs.length, vsync: this);

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
    _tabController.dispose();
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
    if (adminCubit == null) {
      return const WmsPushedScaffold(
        title: 'Administration',
        body: StaffScopeLoadingBody(),
      );
    }

    final palette = AdminPalette.of(context);

    return WmsPushedScaffold(
      title: 'Administration',
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.pageGradient),
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: adminCubit),
            BlocProvider.value(value: _usersCubit!),
            BlocProvider.value(value: _auditCubit!),
            BlocProvider.value(value: _notificationsCubit!),
            BlocProvider.value(value: _profileCubit!),
          ],
          child: BlocBuilder<AdministrationCubit,
              ResourceState<AdministrationBundle>>(
            builder: (context, state) {
              if (state.isLoading && state.data == null) {
                return const _AdminLoadingView();
              }

              final bundle = state.data;
              if (bundle == null) {
                return WmsErrorState(
                  message: state.message ?? 'Failed to load administration',
                  onRetry: adminCubit.load,
                );
              }

              return RefreshIndicator(
                color: palette.brand,
                backgroundColor: palette.colors.surface,
                onRefresh: _refreshAll,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: AdminHeroBanner(
                        title: 'Administration Center',
                        subtitle:
                            'Identity, access, infrastructure and compliance',
                        trailing: AdminStatusChip(
                          label: 'Console',
                          color: Colors.white,
                          icon: Icons.lock_rounded,
                        ),
                        child: AdminBentoGrid(bundle: bundle),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PillTabBarDelegate(
                        background: palette.colors.background,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenPadding,
                            AppSpacing.md,
                            AppSpacing.screenPadding,
                            AppSpacing.sm,
                          ),
                          child: AdminPillTabBar(
                            controller: _tabController,
                            tabs: _tabs,
                          ),
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        child: TabBarView(
                          controller: _tabController,
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
                            AdminActivityPanel(
                              activities: bundle.auditActivities,
                            ),
                            AdminAlertsPanel(cubit: _notificationsCubit!),
                            AdminAccountPanel(profileCubit: _profileCubit!),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bento metric grid
// ─────────────────────────────────────────────────────────────────────────────

/// System metrics for the console header.
///
/// Every tile is a live count from the loaded bundle. Where a metric has a
/// natural denominator the tile shows that ratio as a micro-bar; the console
/// holds no history, so no tile claims a period-over-period delta.
class AdminBentoGrid extends StatelessWidget {
  const AdminBentoGrid({super.key, required this.bundle});

  final AdministrationBundle bundle;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= MobileUi.tabletWidth ? 4 : 2;

    final activeUsers = bundle.users.where((u) => u.isActive).length;
    final totalUsers = bundle.users.where((u) => !u.archived).length;
    final admins = bundle.userCountForRole('Admin');
    final totalAlerts = bundle.notifications.length;

    final tiles = <Widget>[
      AdminBentoCard(
        label: 'Total Users',
        value: '$totalUsers',
        icon: Icons.groups_rounded,
        accent: palette.brand,
        caption: '$admins with admin access',
      ),
      AdminBentoCard(
        label: 'Active Sessions',
        value: '$activeUsers',
        icon: Icons.verified_user_rounded,
        accent: palette.emerald,
        share: totalUsers == 0 ? null : activeUsers / totalUsers,
        caption: totalUsers == 0
            ? 'No accounts loaded'
            : '${((activeUsers / totalUsers) * 100).round()}% of directory',
      ),
      AdminBentoCard(
        label: 'Warehouses',
        value: '${bundle.warehouses.length}',
        icon: Icons.warehouse_rounded,
        accent: palette.cobalt,
        caption: 'Managed facilities',
      ),
      AdminBentoCard(
        label: 'Unread Alerts',
        value: '${bundle.unreadCount}',
        icon: Icons.notifications_active_rounded,
        accent: bundle.unreadCount > 0 ? palette.coral : palette.slate,
        share: totalAlerts == 0 ? null : bundle.unreadCount / totalAlerts,
        caption: totalAlerts == 0
            ? 'No alerts loaded'
            : 'of $totalAlerts total alerts',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.sm + 2,
        crossAxisSpacing: AppSpacing.sm + 2,
        mainAxisExtent: AdminPalette.bentoExtent,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) => tiles[index],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chrome
// ─────────────────────────────────────────────────────────────────────────────

class _PillTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _PillTabBarDelegate({required this.child, required this.background});

  final Widget child;
  final Color background;

  static const double _extent =
      AdminPillTabBar.height + AppSpacing.md + AppSpacing.sm;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: background, child: child);
  }

  @override
  bool shouldRebuild(covariant _PillTabBarDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.background != background;
}

class _AdminLoadingView extends StatelessWidget {
  const _AdminLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        WmsSkeletonBox(height: 150, radius: AdminPalette.radiusHero),
        SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: WmsSkeletonBox(
                height: AdminPalette.bentoExtent,
                radius: AdminPalette.radiusCard,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: WmsSkeletonBox(
                height: AdminPalette.bentoExtent,
                radius: AdminPalette.radiusCard,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        WmsSkeletonBox(height: 46, radius: AdminPalette.radiusPill),
        SizedBox(height: AppSpacing.lg),
        WmsSkeletonBox(height: 220, radius: AdminPalette.radiusCard),
      ],
    );
  }
}
