import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/settings/theme_cubit.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/utils/wms_route_context.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:logisticsmobile/features/profile/domain/entities/user_profile.dart';
import 'package:logisticsmobile/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:logisticsmobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:logisticsmobile/features/profile/presentation/widgets/profile_enterprise_widgets.dart';
import 'package:logisticsmobile/routes/route_names.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with StaffScopeInitMixin {
  ProfileCubit? _cubit;
  String _language = 'English';

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    _cubit = ProfileCubit(GetProfileUseCase(repositories.profile))..load();
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      return const StaffScopeLoadingBody();
    }

    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<ProfileCubit, ResourceState<UserProfile>>(
        builder: (context, state) {
          if (state.isLoading && state.data == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: WmsListSkeleton(itemCount: 4),
            );
          }
          if (state.isFailure && state.data == null) {
            return WmsErrorState(
              message: state.message ?? 'Failed to load profile',
              onRetry: cubit.load,
            );
          }

          final profile = state.data;
          final authUser = context.watch<AuthBloc>().state.user;
          final displayName = _resolveDisplayName(
            profile?.fullName ?? authUser?.fullName,
            profile?.username ?? _emailUsername(authUser?.email),
          );
          final roleLabel = profile?.role ?? authUser?.role.label ?? 'Staff';
          final email = profile?.email ?? authUser?.email ?? '—';
          final warehouseLabel = profile?.assignedWarehouses.isNotEmpty == true
              ? profile!.assignedWarehouses.join(', ')
              : (profile?.assignedWarehouseLabel ??
                  authUser?.warehouse ??
                  'Not assigned');
          final accountStatus = profile?.accountStatus ?? 'Active';

          return Scaffold(
            backgroundColor: WmsUiColors.of(context).background,
            body: RefreshIndicator(
              onRefresh: cubit.load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: ProfileCommandCenterHeader(
                      displayName: displayName,
                      roleLabel: roleLabel,
                      warehouseLabel: warehouseLabel,
                      accountStatus: accountStatus,
                      username: profile?.username,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      0,
                      AppSpacing.screenPadding,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        ProfileAccountStatsStrip(profile: profile),
                        const SizedBox(height: ProfileUi.sectionGap),
                        ProfileAccountInfoSection(
                          email: email,
                          roleLabel: roleLabel,
                          warehouseLabel: warehouseLabel,
                          lastLogin: ProfileMetrics.lastLoginLabel(profile),
                          phone: profile?.phone,
                        ),
                        const SizedBox(height: ProfileUi.sectionGap),
                        ProfileShortcutsSection(
                          showAdminShortcuts: context.isAdminWorkspace,
                          showAuditLogs: context.isAdminWorkspace,
                          onAdministration: () =>
                              context.push(RoutePaths.adminAdministration),
                          onProducts: () => context.push(RoutePaths.adminProducts),
                          onTasks: () => context.push(_tasksPath(context)),
                          onOrders: () => context.go(_ordersPath(context)),
                          onActivity: () => context.push(_activityPath(context)),
                          onAuditLogs: () => context.push(RoutePaths.adminAudit),
                        ),
                        const SizedBox(height: ProfileUi.sectionGap),
                        BlocBuilder<ThemeCubit, ThemeState>(
                          builder: (context, themeState) {
                            return ProfilePreferencesSection(
                              themePreference: themeState.preference,
                              pushNotifications: themeState.pushNotifications,
                              language: _language,
                              onThemeChanged: (p) => context
                                  .read<ThemeCubit>()
                                  .setThemePreference(p),
                              onPushNotificationsChanged: (v) => context
                                  .read<ThemeCubit>()
                                  .setPushNotifications(v),
                              onLanguageChanged: (v) =>
                                  setState(() => _language = v),
                            );
                          },
                        ),
                        const SizedBox(height: ProfileUi.sectionGap),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, authState) {
                            final isLoggingOut = authState.isLoading &&
                                authState.loadingType == AuthLoadingType.logout;
                            return ProfileSecuritySection(
                              isLoggingOut: isLoggingOut,
                              onLogout: () {
                                context
                                    .read<AuthBloc>()
                                    .add(const AuthLogoutRequested());
                              },
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Secure warehouse session · $roleLabel',
                          textAlign: TextAlign.center,
                          style: WmsDesignTokens.supportingDense(context),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _emailUsername(String? email) {
    if (email == null || email.isEmpty) return null;
    return email.split('@').first;
  }

  String _resolveDisplayName(String? fullName, String? fallback) {
    final trimmed = fullName?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    final alt = fallback?.trim() ?? '';
    if (alt.isNotEmpty) return alt;
    return 'User';
  }

  String _tasksPath(BuildContext context) {
    if (context.isAdminWorkspace) return RoutePaths.adminTasks;
    if (context.isSupervisorWorkspace) return RoutePaths.supervisorTasks;
    return RoutePaths.staffTasks;
  }

  String _ordersPath(BuildContext context) {
    if (context.isAdminWorkspace) return RoutePaths.adminOrders;
    if (context.isSupervisorWorkspace) return RoutePaths.supervisorOrders;
    return RoutePaths.staffOrders;
  }

  String _activityPath(BuildContext context) {
    if (context.isAdminWorkspace) return RoutePaths.adminReports;
    if (context.isSupervisorWorkspace) return RoutePaths.supervisorReports;
    return RoutePaths.staffReports;
  }
}
