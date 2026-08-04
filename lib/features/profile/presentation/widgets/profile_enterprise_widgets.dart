import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/constants/app_constants.dart';
import 'package:logisticsmobile/core/settings/theme_preferences.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/profile/domain/entities/user_profile.dart';
import 'package:logisticsmobile/routes/route_names.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_dashboard_section.dart';

abstract final class ProfileUi {
  static const sectionGap = WmsDesignTokens.sectionGap;

  static String initials(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, 1).toUpperCase();
  }

  static double avatarSize(double width) =>
      width <= MobileUi.compactWidth ? 48.0 : 52.0;

  static Color roleColor(String role) {
    final lower = role.toLowerCase();
    if (lower.contains('admin')) return AppColors.info;
    if (lower.contains('supervisor')) return AppColors.accent;
    return AppColors.primary;
  }

  static Color statusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('active')) return AppColors.success;
    if (lower.contains('suspend') || lower.contains('inactive')) {
      return AppColors.error;
    }
    return AppColors.warning;
  }
}

abstract final class ProfileMetrics {
  static int tasksCompleted(UserProfile? profile) =>
      _moduleCount(profile, const ['task']);

  static int ordersManaged(UserProfile? profile) =>
      _moduleCount(profile, const ['order']);

  static int inventoryActions(UserProfile? profile) =>
      _moduleCount(profile, const ['inventory', 'stock', 'movement']);

  static String lastActivityLabel(UserProfile? profile) {
    final at = profile?.lastActiveAt;
    if (at == null) return '—';
    return WmsFormatters.relativeTime(at);
  }

  static String lastLoginLabel(UserProfile? profile) {
    final at = profile?.lastActiveAt;
    if (at == null) return 'Not recorded';
    return WmsFormatters.notificationTimestamp(at);
  }

  static int _moduleCount(UserProfile? profile, List<String> keywords) {
    if (profile == null || profile.permissions.isEmpty) return 0;
    return profile.permissions.where((perm) {
      final lower = perm.toLowerCase();
      return keywords.any(lower.contains);
    }).length;
  }
}

abstract final class ProfileConfirmDialogs {
  static Future<bool> confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
        title: const Text('Sign out?'),
        content: const Text(
          'You will end your secure warehouse session. Unsaved work may be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<bool> confirmChangePassword(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_outline, color: AppColors.primary),
        title: const Text('Change password?'),
        content: const Text(
          'You will be asked to enter your current password and choose a new one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<bool> confirmSecurityAction(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.security_outlined, color: AppColors.warning),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static void showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
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
                style: WmsDesignTokens.sectionTitle(context),
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
                      behavior: SnackBarBehavior.floating,
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

/// Professional profile command-center header.
class ProfileCommandCenterHeader extends StatelessWidget {
  const ProfileCommandCenterHeader({
    super.key,
    required this.displayName,
    required this.roleLabel,
    required this.warehouseLabel,
    required this.accountStatus,
    this.username,
  });

  final String displayName;
  final String roleLabel;
  final String warehouseLabel;
  final String accountStatus;
  final String? username;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final avatarSize = ProfileUi.avatarSize(width);
    final roleColor = ProfileUi.roleColor(roleLabel);
    final statusColor = ProfileUi.statusColor(accountStatus);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        MobileUi.headerBottomGap(width),
      ),
      child: AppCard(
        elevated: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [roleColor, roleColor.withValues(alpha: 0.82)],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: roleColor.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                ProfileUi.initials(displayName),
                style: WmsDesignTokens.cardTitle(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile & settings',
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.pageTitle(context).copyWith(
                          fontSize: 18,
                          height: 1.15,
                        ),
                  ),
                  if (username != null && username!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supporting(context),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _ProfileChip(
                        icon: Icons.badge_outlined,
                        label: roleLabel,
                        color: roleColor,
                      ),
                      _ProfileChip(
                        icon: Icons.warehouse_outlined,
                        label: warehouseLabel,
                        color: AppColors.accent,
                      ),
                      _ProfileChip(
                        icon: Icons.verified_user_outlined,
                        label: accountStatus,
                        color: statusColor,
                      ),
                    ],
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

typedef ProfileExecutiveHeader = ProfileCommandCenterHeader;

class ProfileAccountStatsStrip extends StatelessWidget {
  const ProfileAccountStatsStrip({super.key, this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return WmsDashboardSection(
      title: 'Account Statistics',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SizedBox(
                width: tileWidth,
                child: _StatTile(
                  label: 'Tasks Completed',
                  value: '${ProfileMetrics.tasksCompleted(profile)}',
                  color: const Color(0xFF7C3AED),
                  icon: Icons.assignment_turned_in_outlined,
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _StatTile(
                  label: 'Orders Managed',
                  value: '${ProfileMetrics.ordersManaged(profile)}',
                  color: AppColors.info,
                  icon: Icons.shopping_cart_outlined,
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _StatTile(
                  label: 'Inventory Actions',
                  value: '${ProfileMetrics.inventoryActions(profile)}',
                  color: AppColors.warning,
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _StatTile(
                  label: 'Last Activity',
                  value: ProfileMetrics.lastActivityLabel(profile),
                  color: AppColors.primary,
                  icon: Icons.schedule_outlined,
                  compactValue: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProfileAccountInfoSection extends StatelessWidget {
  const ProfileAccountInfoSection({
    super.key,
    required this.email,
    required this.roleLabel,
    required this.warehouseLabel,
    required this.lastLogin,
    this.phone,
  });

  final String email;
  final String roleLabel;
  final String warehouseLabel;
  final String lastLogin;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return ProfileSettingsSection(
      title: 'Account Information',
      children: [
        ProfileActionTile(
          icon: Icons.mail_outline_rounded,
          title: 'Email',
          subtitle: email,
          iconColor: AppColors.info,
          iconBackground: AppColors.infoLight,
          showChevron: false,
        ),
        if (phone != null && phone!.isNotEmpty)
          ProfileActionTile(
            icon: Icons.phone_outlined,
            title: 'Phone Number',
            subtitle: phone,
            iconColor: AppColors.primary,
            iconBackground: AppColors.primaryLight,
            showChevron: false,
          ),
        ProfileActionTile(
          icon: Icons.badge_outlined,
          title: 'Role',
          subtitle: roleLabel,
          iconColor: ProfileUi.roleColor(roleLabel),
          iconBackground: ProfileUi.roleColor(roleLabel).withValues(alpha: 0.12),
          showChevron: false,
        ),
        ProfileActionTile(
          icon: Icons.warehouse_outlined,
          title: 'Assigned Warehouse',
          subtitle: warehouseLabel,
          iconColor: AppColors.accent,
          iconBackground: AppColors.accentLight,
          showChevron: false,
        ),
        ProfileActionTile(
          icon: Icons.login_rounded,
          title: 'Last Login',
          subtitle: lastLogin,
          iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
          iconBackground: AppColors.background,
          showChevron: false,
        ),
      ],
    );
  }
}

class ProfileSecuritySection extends StatelessWidget {
  const ProfileSecuritySection({
    super.key,
    required this.onLogout,
    this.isLoggingOut = false,
  });

  final VoidCallback onLogout;
  final bool isLoggingOut;

  @override
  Widget build(BuildContext context) {
    return ProfileSettingsSection(
      title: 'Account Security',
      children: [
        ProfileActionTile(
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          subtitle: 'Update your sign-in credentials',
          iconColor: AppColors.primary,
          iconBackground: AppColors.primaryLight,
          onTap: () async {
            final confirmed =
                await ProfileConfirmDialogs.confirmChangePassword(context);
            if (confirmed && context.mounted) {
              ProfileConfirmDialogs.showChangePasswordSheet(context);
            }
          },
        ),
        ProfileActionTile(
          icon: Icons.security_outlined,
          title: 'Security Settings',
          subtitle: 'Two-factor authentication & session policies',
          iconColor: AppColors.warning,
          iconBackground: AppColors.warningLight,
          onTap: () async {
            final confirmed = await ProfileConfirmDialogs.confirmSecurityAction(
              context,
              title: 'Open security settings?',
              message:
                  'Security controls are managed by your warehouse administrator.',
            );
            if (confirmed && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Security settings UI placeholder.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        ProfileActionTile(
          icon: Icons.devices_outlined,
          title: 'Active Sessions',
          subtitle: 'Review devices signed into your account',
          iconColor: AppColors.info,
          iconBackground: AppColors.infoLight,
          onTap: () async {
            final confirmed = await ProfileConfirmDialogs.confirmSecurityAction(
              context,
              title: 'Manage active sessions?',
              message:
                  'You can review and revoke sessions on other devices. This device will remain signed in.',
            );
            if (confirmed && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Active sessions UI is ready. Connect session API to list devices.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        ProfileActionTile(
          icon: Icons.logout_rounded,
          title: 'Logout',
          subtitle: 'End your secure warehouse session',
          iconColor: AppColors.error,
          iconBackground: AppColors.errorLight,
          trailing: isLoggingOut
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: isLoggingOut
              ? null
              : () async {
                  final confirmed =
                      await ProfileConfirmDialogs.confirmLogout(context);
                  if (confirmed && context.mounted) onLogout();
                },
        ),
      ],
    );
  }
}

class ProfilePreferencesSection extends StatelessWidget {
  const ProfilePreferencesSection({
    super.key,
    required this.themePreference,
    required this.pushNotifications,
    required this.language,
    required this.onThemeChanged,
    required this.onPushNotificationsChanged,
    required this.onLanguageChanged,
  });

  final AppThemePreference themePreference;
  final bool pushNotifications;
  final String language;
  final ValueChanged<AppThemePreference> onThemeChanged;
  final ValueChanged<bool> onPushNotificationsChanged;
  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    return ProfileSettingsSection(
      title: 'System Preferences',
      children: [
        ProfileActionTile(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Appearance, notifications, and app info',
          iconColor: colors.primary,
          iconBackground: colors.primaryMuted,
          onTap: () => context.push(RoutePaths.settings),
        ),
        ProfileActionTile(
          icon: Icons.palette_outlined,
          title: 'Appearance',
          subtitle: _themeLabel(themePreference),
          iconColor: colors.accent,
          iconBackground: colors.accentMuted,
          onTap: () => context.push(RoutePaths.settings),
        ),
        ProfileActionTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications Settings',
          subtitle: pushNotifications ? 'Push alerts enabled' : 'Push alerts off',
          iconColor: colors.warning,
          iconBackground: colors.warningMuted,
          trailing: Switch.adaptive(
            value: pushNotifications,
            onChanged: onPushNotificationsChanged,
          ),
          showChevron: false,
          onTap: () => onPushNotificationsChanged(!pushNotifications),
        ),
        ProfileActionTile(
          icon: Icons.language_outlined,
          title: 'Language Selection',
          subtitle: language,
          iconColor: colors.info,
          iconBackground: colors.infoMuted,
          trailing: DropdownButton<String>(
            value: language,
            underline: const SizedBox.shrink(),
            isDense: true,
            items: const [
              DropdownMenuItem(value: 'English', child: Text('English')),
              DropdownMenuItem(value: 'Swahili', child: Text('Swahili')),
            ],
            onChanged: (v) {
              if (v != null) onLanguageChanged(v);
            },
          ),
          showChevron: false,
        ),
        ProfileActionTile(
          icon: Icons.info_outline_rounded,
          title: 'App Version',
          subtitle: '${AppConstants.appName} v${AppConstants.appVersion}',
          iconColor: colors.textSecondary,
          iconBackground: colors.mutedSurface,
          showChevron: false,
        ),
      ],
    );
  }

  static String _themeLabel(AppThemePreference preference) {
    switch (preference) {
      case AppThemePreference.system:
        return 'System default';
      case AppThemePreference.light:
        return 'Light mode';
      case AppThemePreference.dark:
        return 'Dark mode';
    }
  }
}

class ProfileShortcutsSection extends StatelessWidget {
  const ProfileShortcutsSection({
    super.key,
    required this.showAuditLogs,
    required this.onTasks,
    required this.onOrders,
    required this.onActivity,
    this.onAuditLogs,
    this.onAdministration,
    this.onProducts,
    this.showAdminShortcuts = false,
  });

  final bool showAuditLogs;
  final bool showAdminShortcuts;
  final VoidCallback onTasks;
  final VoidCallback onOrders;
  final VoidCallback onActivity;
  final VoidCallback? onAuditLogs;
  final VoidCallback? onAdministration;
  final VoidCallback? onProducts;

  @override
  Widget build(BuildContext context) {
    return ProfileSettingsSection(
      title: 'Enterprise Shortcuts',
      children: [
        if (showAdminShortcuts) ...[
          ProfileActionTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Administration Center',
            subtitle: 'Users, roles, audit, notifications',
            iconColor: AppColors.info,
            iconBackground: AppColors.infoLight,
            onTap: onAdministration!,
          ),
          ProfileActionTile(
            icon: Icons.category_outlined,
            title: 'Products Catalog',
            subtitle: 'SKU catalog and product master data',
            iconColor: AppColors.warning,
            iconBackground: AppColors.warningLight,
            onTap: onProducts!,
          ),
        ],
        ProfileActionTile(
          icon: Icons.assignment_outlined,
          title: 'My Tasks',
          subtitle: 'Assigned warehouse tasks and deadlines',
          iconColor: const Color(0xFF7C3AED),
          iconBackground: const Color(0xFF7C3AED).withValues(alpha: 0.12),
          onTap: onTasks,
        ),
        ProfileActionTile(
          icon: Icons.shopping_cart_outlined,
          title: 'My Orders',
          subtitle: 'Order queue and fulfillment status',
          iconColor: AppColors.info,
          iconBackground: AppColors.infoLight,
          onTap: onOrders,
        ),
        ProfileActionTile(
          icon: Icons.history_rounded,
          title: 'Activity History',
          subtitle: 'Recent operational events and movements',
          iconColor: AppColors.accent,
          iconBackground: AppColors.accentLight,
          onTap: onActivity,
        ),
        if (showAuditLogs)
          ProfileActionTile(
            icon: Icons.fact_check_outlined,
            title: 'Audit Logs',
            subtitle: 'Compliance trail and system changes',
            iconColor: AppColors.error,
            iconBackground: AppColors.errorLight,
            onTap: onAuditLogs!,
          ),
      ],
    );
  }
}

// Legacy widgets kept for compatibility ---------------------------------------

class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({
    super.key,
    required this.displayName,
    required this.roleLabel,
    required this.email,
    required this.assignedWarehouses,
    this.username,
  });

  final String displayName;
  final String roleLabel;
  final String email;
  final List<String> assignedWarehouses;
  final String? username;

  @override
  Widget build(BuildContext context) {
    return ProfileCommandCenterHeader(
      displayName: displayName,
      roleLabel: roleLabel,
      warehouseLabel: assignedWarehouses.isEmpty
          ? 'Not assigned'
          : assignedWarehouses.join(', '),
      accountStatus: 'Active',
      username: username,
    );
  }
}

class ProfileAccountDetailsCard extends StatelessWidget {
  const ProfileAccountDetailsCard({
    super.key,
    required this.accountStatus,
    this.phone,
  });

  final String accountStatus;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return ProfileAccountInfoSection(
      email: '—',
      roleLabel: '—',
      warehouseLabel: '—',
      lastLogin: '—',
      phone: phone,
    );
  }
}

class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({
    super.key,
    required this.children,
    this.title = 'Account settings',
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return WmsDashboardSection(
      title: title,
      child: AppCard(
        elevated: true,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 56),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class ProfileActionTile extends StatelessWidget {
  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primaryLight,
    this.trailing,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color iconBackground;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              padding: const EdgeInsets.all(WmsIconSizes.iconCardPadding),
              child: Icon(icon, size: WmsIconSizes.kpi, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: wms.textSecondary,
                            height: 1.25,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (showChevron && onTap != null)
              Icon(Icons.chevron_right_rounded, color: wms.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

class ProfileLogoutSection extends StatelessWidget {
  const ProfileLogoutSection({
    super.key,
    required this.onLogout,
    this.isLoading = false,
  });

  final VoidCallback onLogout;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ProfileSecuritySection(
      onLogout: onLogout,
      isLoggingOut: isLoading,
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.compactValue = false,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool compactValue;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: WmsDesignTokens.kpiIconSize, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: compactValue ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.kpiValue(context, width: width).copyWith(
                  fontSize: compactValue
                      ? WmsDesignTokens.kpiNumberSize(width) - 6
                      : null,
                ),
          ),
          Text(
            label,
            style: WmsDesignTokens.kpiLabel(context),
          ),
        ],
      ),
    );
  }
}
