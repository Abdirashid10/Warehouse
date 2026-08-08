import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/constants/app_constants.dart';
import 'package:logisticsmobile/core/settings/theme_preferences.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/profile/domain/entities/user_profile.dart';
import 'package:logisticsmobile/routes/route_names.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_metric_pill.dart';

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

  static Color roleColor(String role, WmsUiColors colors) {
    final lower = role.toLowerCase();
    if (lower.contains('admin')) return colors.info;
    if (lower.contains('supervisor')) return colors.accent;
    return colors.primary;
  }

  static Color statusColor(String status, WmsUiColors colors) {
    final lower = status.toLowerCase();
    if (lower.contains('active')) return colors.success;
    if (lower.contains('suspend') || lower.contains('inactive')) {
      return colors.error;
    }
    return colors.warning;
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
    final colors = WmsUiColors.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.logout_rounded, color: colors.error),
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
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<bool> confirmChangePassword(BuildContext context) async {
    final colors = WmsUiColors.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.lock_outline, color: colors.primary),
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
    final colors = WmsUiColors.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.security_outlined, color: colors.warning),
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
    final colors = WmsUiColors.of(context);
    final avatarSize = ProfileUi.avatarSize(width);
    final roleColor = ProfileUi.roleColor(roleLabel, colors);
    final statusColor = ProfileUi.statusColor(accountStatus, colors);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        MobileUi.headerBottomGap(width),
      ),
      // Hero banner: a soft role-tinted wash behind the identity block, so the
      // header reads as one cohesive surface rather than a plain white card.
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              roleColor.withValues(alpha: colors.isDark ? 0.22 : 0.10),
              roleColor.withValues(alpha: colors.isDark ? 0.10 : 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: roleColor.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: roleColor.withValues(alpha: colors.isDark ? 0.22 : 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                        color: roleColor.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    ProfileUi.initials(displayName),
                    style: WmsDesignTokens.cardTitle(context).copyWith(
                      color: const Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: WmsDesignTokens.pageTitle(context).copyWith(
                          fontSize: 19,
                          height: 1.2,
                        ),
                      ),
                      if (username != null && username!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@$username',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: WmsDesignTokens.supportingDense(context)
                              .copyWith(height: 1.25),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // One scrollable line. As a Wrap these three chips ran onto two or
            // three rows once a warehouse name was long, which is exactly the
            // clutter the hero is meant to avoid.
            SizedBox(
              height: 26,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _ProfileChip(
                    icon: Icons.badge_outlined,
                    label: roleLabel,
                    color: roleColor,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _ProfileChip(
                    icon: Icons.verified_user_outlined,
                    label: accountStatus,
                    color: statusColor,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _ProfileChip(
                    icon: Icons.warehouse_outlined,
                    label: warehouseLabel,
                    color: colors.accent,
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
    final colors = WmsUiColors.of(context);
    // Same scrollable strip the inventory, products, orders and tasks screens
    // use, so account stats read as part of one system.
    return WmsMetricPillBar(
      // The hosting sliver already applies the screen inset.
      padding: EdgeInsets.zero,
      metrics: [
        WmsMetricPillData(
          label: 'Tasks Completed',
          value: '${ProfileMetrics.tasksCompleted(profile)}',
          icon: Icons.assignment_turned_in_outlined,
          color: const Color(0xFF7C3AED),
        ),
        WmsMetricPillData(
          label: 'Orders Managed',
          value: '${ProfileMetrics.ordersManaged(profile)}',
          icon: Icons.shopping_cart_outlined,
          color: colors.info,
        ),
        WmsMetricPillData(
          label: 'Inventory Actions',
          value: '${ProfileMetrics.inventoryActions(profile)}',
          icon: Icons.inventory_2_outlined,
          color: colors.warning,
        ),
        WmsMetricPillData(
          label: 'Last Activity',
          value: ProfileMetrics.lastActivityLabel(profile),
          icon: Icons.schedule_outlined,
          color: colors.primary,
        ),
      ],
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
    final colors = WmsUiColors.of(context);
    return ProfileSettingsSection(
      title: 'Account Information',
      children: [
        ProfileActionTile(
          icon: Icons.mail_outline_rounded,
          title: 'Email',
          subtitle: email,
          iconColor: colors.info,
          iconBackground: colors.infoMuted,
          showChevron: false,
        ),
        if (phone != null && phone!.isNotEmpty)
          ProfileActionTile(
            icon: Icons.phone_outlined,
            title: 'Phone Number',
            subtitle: phone,
            iconColor: colors.primary,
            iconBackground: colors.primaryMuted,
            showChevron: false,
          ),
        ProfileActionTile(
          icon: Icons.badge_outlined,
          title: 'Role',
          subtitle: roleLabel,
          iconColor: ProfileUi.roleColor(roleLabel, colors),
          iconBackground: ProfileUi.roleColor(roleLabel, colors).withValues(alpha: 0.12),
          showChevron: false,
        ),
        ProfileActionTile(
          icon: Icons.warehouse_outlined,
          title: 'Assigned Warehouse',
          subtitle: warehouseLabel,
          iconColor: colors.accent,
          iconBackground: colors.accentMuted,
          showChevron: false,
        ),
        ProfileActionTile(
          icon: Icons.login_rounded,
          title: 'Last Login',
          subtitle: lastLogin,
          iconColor: WmsUiColors.of(context).textSecondary,
          // A visible neutral tint: colors.background is near-white and
          // vanished against the card, leaving one icon box unstyled among
          // four tinted ones.
          iconBackground: WmsUiColors.of(context).mutedSurface,
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
    final colors = WmsUiColors.of(context);
    return ProfileSettingsSection(
      title: 'Account Security',
      children: [
        ProfileActionTile(
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          subtitle: 'Update your sign-in credentials',
          iconColor: colors.primary,
          iconBackground: colors.primaryMuted,
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
          iconColor: colors.warning,
          iconBackground: colors.warningMuted,
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
          iconColor: colors.info,
          iconBackground: colors.infoMuted,
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
          iconColor: colors.error,
          iconBackground: colors.errorMuted,
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
    final colors = WmsUiColors.of(context);
    return ProfileSettingsSection(
      title: 'Enterprise Shortcuts',
      children: [
        if (showAdminShortcuts) ...[
          ProfileActionTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Administration Center',
            subtitle: 'Users, roles, audit, notifications',
            iconColor: colors.info,
            iconBackground: colors.infoMuted,
            onTap: onAdministration!,
          ),
          ProfileActionTile(
            icon: Icons.category_outlined,
            title: 'Products Catalog',
            subtitle: 'SKU catalog and product master data',
            iconColor: colors.warning,
            iconBackground: colors.warningMuted,
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
          iconColor: colors.info,
          iconBackground: colors.infoMuted,
          onTap: onOrders,
        ),
        ProfileActionTile(
          icon: Icons.history_rounded,
          title: 'Activity History',
          subtitle: 'Recent operational events and movements',
          iconColor: colors.accent,
          iconBackground: colors.accentMuted,
          onTap: onActivity,
        ),
        if (showAuditLogs)
          ProfileActionTile(
            icon: Icons.fact_check_outlined,
            title: 'Audit Logs',
            subtitle: 'Compliance trail and system changes',
            iconColor: colors.error,
            iconBackground: colors.errorMuted,
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
    final wms = context.wms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Small uppercase eyebrow rather than the accent-rail section header —
        // four of these stack on this screen, so the lighter treatment keeps
        // the page from reading as four competing headings.
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: 6),
          child: Text(
            title.toUpperCase(),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.supportingDense(context).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              height: 1.3,
            ),
          ),
        ),
        AppCard(
          elevated: true,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    // Aligned to the text column, not an arbitrary 56dp.
                    indent: ProfileActionTile.dividerIndent,
                    color: wms.border.withValues(alpha: 0.6),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
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
    this.iconColor,
    this.iconBackground,
    this.trailing,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  /// Optional override; defaults to the theme primary at paint time. A const
  /// default cannot read the theme, which is how the light-mode swatch got
  /// baked in here.
  final Color? iconColor;

  /// Optional override; defaults to the theme primary tint at paint time.
  final Color? iconBackground;
  final Widget? trailing;
  final bool showChevron;

  /// Leading icon box. Sized so the tile stays ~56dp — the previous 16dp
  /// padding around a 34dp glyph produced a 66dp box on its own, making every
  /// tile taller than a comfortable list row.
  static const double iconBoxSize = 36;

  /// Left inset for the divider between tiles, aligned to the text column.
  static const double dividerIndent =
      AppSpacing.md + iconBoxSize + AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final colors = WmsUiColors.of(context);
    final resolvedIconColor = iconColor ?? colors.primary;
    final resolvedIconBackground = iconBackground ?? colors.primaryMuted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: resolvedIconBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, size: 18, color: resolvedIconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.body(context).copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    // Single line: two-line subtitles gave neighbouring tiles
                    // different heights and a ragged left rail.
                    Text(
                      subtitle!,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: wms.textSecondary,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ] else if (showChevron && onTap != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                color: wms.textTertiary,
                size: 18,
              ),
            ],
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
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          // A hard cap rather than Flexible: these chips live in a horizontally
          // scrolling strip, where the incoming width is unbounded and a flex
          // child would throw.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

