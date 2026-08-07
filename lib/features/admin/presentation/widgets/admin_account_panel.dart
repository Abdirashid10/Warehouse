import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/constants/app_constants.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_atoms.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_theme.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:logisticsmobile/features/profile/domain/entities/user_profile.dart';
import 'package:logisticsmobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:logisticsmobile/widgets/loading_indicator.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Account tab — the signed-in operator's profile and preferences.
class AdminAccountPanel extends StatefulWidget {
  const AdminAccountPanel({
    super.key,
    required this.profileCubit,
    this.padding = false,
  });

  final ProfileCubit profileCubit;
  final bool padding;

  @override
  State<AdminAccountPanel> createState() => _AdminAccountPanelState();
}

class _AdminAccountPanelState extends State<AdminAccountPanel> {
  bool _pushNotifications = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
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
        final name = profile?.fullName ?? authUser?.fullName ?? 'User';
        final role = profile?.role ?? authUser?.role.label ?? 'Staff';
        final tier = AdminRoles.tierOf(role);

        return AdminTabScroll(
          padding: widget.padding,
          children: [
            AdminSectionIntro(
              eyebrow: 'Identity',
              title: 'Account Profile',
              subtitle: 'Your credentials, scope and preferences',
              trailing: AdminGlowBadge(
                icon: Icons.badge_rounded,
                color: palette.roleColor(tier),
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileCard(
              name: name,
              username: profile?.username ?? '',
              role: role,
              status: profile?.accountStatus ?? 'Active',
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileDetails(profile: profile, authEmail: authUser?.email),
            const SizedBox(height: AppSpacing.md),
            _AccountActions(onChangePassword: () => _showChangePassword(context)),
            const SizedBox(height: AppSpacing.lg),
            const AdminSectionIntro(
              eyebrow: 'Preferences',
              title: 'Console Settings',
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsCard(
              pushNotifications: _pushNotifications,
              onPushChanged: (value) =>
                  setState(() => _pushNotifications = value),
              language: _language,
              onLanguageChanged: (value) => setState(() => _language = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final isLoggingOut = authState.isLoading &&
                    authState.loadingType == AuthLoadingType.logout;
                if (isLoggingOut) {
                  return const Center(child: LoadingIndicator());
                }
                return _SignOutButton(
                  onPressed: () =>
                      context.read<AuthBloc>().add(const AuthLogoutRequested()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${AppConstants.appName} v${AppConstants.appVersion}',
              textAlign: TextAlign.center,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: palette.colors.textTertiary,
                fontSize: 11.5,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showChangePassword(BuildContext context) {
    final palette = AdminPalette.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          gradient: palette.surfaceGradient,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXxl),
          ),
          border: palette.glassBorder(),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.md,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.colors.textTertiary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  AdminGlowBadge(
                    icon: Icons.lock_reset_rounded,
                    color: palette.brand,
                    size: 40,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Change password',
                      style: WmsDesignTokens.sectionTitle(context).copyWith(
                        color: palette.colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _PasswordField(label: 'Current password'),
              const SizedBox(height: AppSpacing.sm + 2),
              const _PasswordField(label: 'New password'),
              const SizedBox(height: AppSpacing.sm + 2),
              const _PasswordField(label: 'Confirm new password'),
              const SizedBox(height: AppSpacing.lg),
              AdminGradientButton(
                icon: Icons.check_rounded,
                label: 'Update password',
                expanded: true,
                onPressed: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      content: const Text(
                        'Password UI is ready — connect the change-password '
                        'API to persist.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.username,
    required this.role,
    required this.status,
  });

  final String name;
  final String username;
  final String role;
  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;
    final tier = AdminRoles.tierOf(role);
    final accent = palette.roleColor(tier);
    final isActive = status.toLowerCase() == 'active';

    return AdminGlassCard(
      accentStrip: accent,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          AdminAvatar(
            initials: _initials(name),
            accent: accent,
            size: 60,
            statusColor: isActive ? palette.emerald : palette.slate,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.sectionTitle(context).copyWith(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: colors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    AdminStatusChip(
                      label: role,
                      color: accent,
                      icon: AdminRoles.iconFor(tier),
                      dense: true,
                    ),
                    AdminStatusChip(
                      label: status,
                      color: isActive ? palette.emerald : palette.slate,
                      icon: isActive
                          ? Icons.verified_rounded
                          : Icons.pause_circle_rounded,
                      dense: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, 1).toUpperCase();
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.profile, required this.authEmail});

  final UserProfile? profile;
  final String? authEmail;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;

    return AdminGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACCOUNT DETAILS',
            style: WmsDesignTokens.supportingDense(context).copyWith(
              color: colors.textTertiary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          AdminInfoRow(
            icon: Icons.alternate_email_rounded,
            label: 'Email',
            value: profile?.email ?? authEmail ?? '—',
          ),
          AdminInfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: profile?.phone?.isNotEmpty == true
                ? profile!.phone!
                : 'Not provided',
            valueColor: profile?.phone?.isNotEmpty == true
                ? null
                : colors.textTertiary,
          ),
          AdminInfoRow(
            icon: Icons.warehouse_rounded,
            label: 'Warehouse',
            value: profile?.assignedWarehouseLabel ?? 'Not assigned',
          ),
          AdminInfoRow(
            icon: Icons.schedule_rounded,
            label: 'Last active',
            value: profile?.lastActiveAt == null
                ? 'Unknown'
                : WmsFormatters.relativeTime(profile!.lastActiveAt),
            valueColor:
                profile?.lastActiveAt == null ? colors.textTertiary : null,
          ),
          AdminInfoRow(
            icon: Icons.event_available_rounded,
            label: 'Member since',
            value: profile?.memberSince == null
                ? 'Unknown'
                : _formatDate(profile!.memberSince!),
            valueColor:
                profile?.memberSince == null ? colors.textTertiary : null,
          ),
        ],
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';
}

class _AccountActions extends StatelessWidget {
  const _AccountActions({required this.onChangePassword});

  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);

    return AdminGlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.edit_rounded,
            label: 'Edit profile',
            accent: palette.brand,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  content: const Text(
                    'Profile edit UI is ready — connect the profile update API '
                    'to save changes.',
                  ),
                ),
              );
            },
          ),
          Divider(height: 1, thickness: 1, color: palette.hairline),
          _ActionTile(
            icon: Icons.lock_reset_rounded,
            label: 'Change password',
            accent: palette.violet,
            onTap: onChangePassword,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              AdminGlowBadge(icon: icon, color: accent, size: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.pushNotifications,
    required this.onPushChanged,
    required this.language,
    required this.onLanguageChanged,
  });

  final bool pushNotifications;
  final ValueChanged<bool> onPushChanged;
  final String language;
  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;

    return AdminGlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                AdminGlowBadge(
                  icon: Icons.notifications_active_rounded,
                  color: palette.amber,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Push notifications',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            WmsDesignTokens.supportingDense(context).copyWith(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      Text(
                        'Receive operational alerts',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            WmsDesignTokens.supportingDense(context).copyWith(
                          color: colors.textTertiary,
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: pushNotifications, onChanged: onPushChanged),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: palette.hairline),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
            child: Row(
              children: [
                AdminGlowBadge(
                  icon: Icons.language_rounded,
                  color: palette.cobalt,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Language',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: language,
                  underline: const SizedBox.shrink(),
                  borderRadius:
                      BorderRadius.circular(AdminPalette.radiusControl),
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Swahili', child: Text('Swahili')),
                  ],
                  onChanged: (value) {
                    if (value != null) onLanguageChanged(value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final radius = BorderRadius.circular(AdminPalette.radiusPill);

    return Material(
      color: palette.tint(palette.coral, 0.11),
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: palette.coral.withValues(alpha: 0.30)),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 16, color: palette.coral),
              const SizedBox(width: 8),
              Text(
                'Sign out',
                style: WmsDesignTokens.buttonLabel(context).copyWith(
                  color: palette.coral,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;
    final radius = BorderRadius.circular(AdminPalette.radiusControl);

    return TextField(
      obscureText: true,
      style: WmsDesignTokens.body(context).copyWith(
        color: colors.textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: palette.brand,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: WmsDesignTokens.supportingDense(context).copyWith(
          color: colors.textTertiary,
          fontSize: 12.5,
        ),
        filled: true,
        fillColor: palette.insetFill,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: palette.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: palette.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: palette.brand, width: 1.6),
        ),
      ),
    );
  }
}
