import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/constants/app_constants.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:logisticsmobile/features/profile/domain/entities/user_profile.dart';
import 'package:logisticsmobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:logisticsmobile/widgets/app_button.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/loading_indicator.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

class AdminAccountPanel extends StatefulWidget {
  const AdminAccountPanel({super.key, required this.profileCubit});

  final ProfileCubit profileCubit;

  @override
  State<AdminAccountPanel> createState() => _AdminAccountPanelState();
}

class _AdminAccountPanelState extends State<AdminAccountPanel> {
  bool _darkMode = false;
  bool _pushNotifications = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthBloc>().state.user;

    return BlocBuilder<ProfileCubit, ResourceState<UserProfile>>(
      bloc: widget.profileCubit,
      builder: (context, state) {
        if (state.isLoading && state.data == null) {
          return const WmsListSkeleton(itemCount: 4);
        }
        if (state.isFailure && state.data == null) {
          return WmsErrorState(
            message: state.message ?? 'Failed to load profile',
            onRetry: widget.profileCubit.load,
          );
        }

        final profile = state.data;

        return ListView(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
          children: [
            Text(
              'Profile center',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      _initials(profile?.fullName ?? authUser?.fullName),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    profile?.fullName ?? authUser?.fullName ?? 'User',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (profile?.username.isNotEmpty == true)
                    Text('@${profile!.username}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  _RoleChip(label: profile?.role ?? authUser?.role.label ?? 'Staff'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: profile?.email ?? authUser?.email ?? '—',
            ),
            if (profile?.phone != null)
              _ProfileRow(icon: Icons.phone_outlined, label: 'Phone', value: profile!.phone!),
            _ProfileRow(
              icon: Icons.warehouse_outlined,
              label: 'Warehouse',
              value: profile?.assignedWarehouseLabel ?? authUser?.warehouse ?? 'Not assigned',
            ),
            _ProfileRow(
              icon: Icons.verified_user_outlined,
              label: 'Account status',
              value: profile?.accountStatus ?? 'Active',
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    title: const Text('Edit profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Profile edit UI is ready. Connect profile update API to save changes.',
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                    title: const Text('Change password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangePasswordSheet(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark mode'),
                    subtitle: const Text('UI preference (app theme integration pending)'),
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                  ),
                  SwitchListTile(
                    title: const Text('Push notifications'),
                    subtitle: const Text('Receive operational alerts'),
                    value: _pushNotifications,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language, color: AppColors.primary),
                    title: const Text('Language'),
                    trailing: DropdownButton<String>(
                      value: _language,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'English', child: Text('English')),
                        DropdownMenuItem(value: 'Swahili', child: Text('Swahili')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _language = v);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.security, color: AppColors.primary),
                    title: const Text('Security'),
                    subtitle: const Text('Two-factor & session controls (UI only)'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Security settings UI placeholder.')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final isLoggingOut = authState.isLoading &&
                    authState.loadingType == AuthLoadingType.logout;
                if (isLoggingOut) return const Center(child: LoadingIndicator());
                return AppButton(
                  label: 'Logout',
                  variant: AppButtonVariant.outline,
                  icon: Icons.logout,
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthLogoutRequested());
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${AppConstants.appName} v${AppConstants.appVersion}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  String _initials(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, 1).toUpperCase();
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.screenPadding + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Change password',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'Current password'),
              ),
              const SizedBox(height: AppSpacing.sm),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: AppSpacing.sm),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm new password'),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password change UI is ready. Connect change-password API to persist.',
                      ),
                    ),
                  );
                },
                child: const Text('Update password'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  Text(value, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
