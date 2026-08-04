import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/auth/domain/entities/user_role.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:logisticsmobile/routes/route_names.dart';
import 'package:logisticsmobile/widgets/app_card.dart';

/// Clean enterprise dashboard header — light surface, emerald accents.
class WmsExecutiveHeader extends StatelessWidget {
  const WmsExecutiveHeader({
    super.key,
    this.subtitle = 'Warehouse Control Center',
    this.warehouseName,
    this.roleLabel,
    this.displayName,
    this.lastSyncedAt,
    this.showLoadingBar = false,
    this.onNotificationsTap,
    this.additionalBadges = const [],
    this.compact = false,
    this.welcomeBackStyle = false,
    this.embeddedInShell = false,
  });

  final String subtitle;
  final String? warehouseName;
  final String? roleLabel;
  final String? displayName;
  final DateTime? lastSyncedAt;
  final bool showLoadingBar;
  final VoidCallback? onNotificationsTap;
  final List<({IconData icon, String label})> additionalBadges;
  final bool compact;
  final bool welcomeBackStyle;
  final bool embeddedInShell;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final colors = WmsUiColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, auth) {
        final user = auth.user;
        final name = displayName?.trim().isNotEmpty == true
            ? displayName!
            : (user?.fullName ?? user?.email ?? 'Operator');
        final role = roleLabel ?? user?.role.label ?? 'Staff';
        final warehouse = warehouseName?.trim().isNotEmpty == true
            ? warehouseName!
            : (user?.warehouse ?? 'Main Distribution Center');
        final fallbackInitials = _initialsFromName(name);
        final initials = user?.initials ?? fallbackInitials;
        final syncLabel = lastSyncedAt != null
            ? 'Synced ${WmsFormatters.relativeTime(lastSyncedAt)}'
            : null;

        final cardPadding = compact ? AppSpacing.xs : AppSpacing.md;
        final outerBottom = compact ? 4.0 : AppSpacing.md;
        final avatarSize = compact ? 26.0 : 36.0;

        final topInset =
            embeddedInShell ? 0.0 : MediaQuery.paddingOf(context).top;

        return Container(
          color: embeddedInShell
              ? Colors.transparent
              : Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.fromLTRB(
            embeddedInShell ? 0 : AppSpacing.screenPadding,
            (compact ? AppSpacing.xs : AppSpacing.md) + topInset,
            embeddedInShell ? 0 : AppSpacing.screenPadding,
            outerBottom,
          ),
          child: AppCard(
            padding: EdgeInsets.all(cardPadding),
            elevated: true,
            accentColor: primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (compact && !welcomeBackStyle)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              WmsFormatters.greeting(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WmsDesignTokens.body(context).copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WmsDesignTokens.cardTitle(context).copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    height: 1.15,
                                  ),
                            ),
                            const SizedBox(height: 1),
                            SizedBox(
                              width: double.infinity,
                              height: 11,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  subtitle,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: WmsDesignTokens.supportingDense(context).copyWith(
                                        color: primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _NotificationButton(
                        compact: compact,
                        onTap: onNotificationsTap ??
                            () {
                              final path = _notificationsPath(user?.role);
                              if (path != null) context.go(path);
                            },
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: welcomeBackStyle
                            ? _WelcomeBackCopy(
                                name: name,
                                role: role,
                                warehouse: warehouse,
                                syncLabel: syncLabel,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    WmsFormatters.greeting(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: WmsDesignTokens.body(context).copyWith(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: WmsDesignTokens.pageTitle(context).copyWith(
                                          height: 1.15,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: WmsDesignTokens.body(context).copyWith(
                                          color: primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.warehouse_outlined,
                                          size: WmsIconSizes.status, color: colors.textSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          warehouse,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: WmsDesignTokens.body(context).copyWith(
                                                color: colors.textPrimary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (syncLabel != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.sync_rounded,
                                            size: WmsIconSizes.status, color: colors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          syncLabel,
                                          style: WmsDesignTokens.description(context).copyWith(
                                                color: colors.textSecondary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _HeaderAvatar(initials: initials, size: avatarSize),
                      const SizedBox(width: 4),
                      _NotificationButton(
                        compact: compact,
                        onTap: onNotificationsTap ??
                            () {
                              final path = _notificationsPath(user?.role);
                              if (path != null) context.go(path);
                            },
                      ),
                    ],
                  ),
                if (!welcomeBackStyle) ...[
                  if (compact) const SizedBox(height: AppSpacing.xs),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (compact) ...[
                          _HeaderAvatar(initials: initials, size: avatarSize),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        _HeaderBadge(
                            icon: Icons.badge_outlined, label: role, compact: true),
                        const SizedBox(width: AppSpacing.xs),
                        _HeaderBadge(
                          icon: Icons.warehouse_outlined,
                          label: warehouse,
                          compact: true,
                        ),
                        if (syncLabel != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          _HeaderBadge(
                            icon: Icons.sync_rounded,
                            label: syncLabel,
                            compact: true,
                          ),
                        ],
                        for (final badge in additionalBadges) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _HeaderBadge(
                            icon: badge.icon,
                            label: badge.label,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else if (additionalBadges.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < additionalBadges.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.sm),
                          _HeaderBadge(
                            icon: additionalBadges[i].icon,
                            label: additionalBadges[i].label,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (showLoadingBar) ...[
                  const SizedBox(height: AppSpacing.sm),
                  LinearProgressIndicator(
                    minHeight: 2,
                    color: primary,
                    backgroundColor: wms.primaryLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String? _notificationsPath(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return RoutePaths.adminNotifications;
      case UserRole.supervisor:
        return RoutePaths.supervisorNotifications;
      case UserRole.staff:
      case UserRole.unknown:
      case null:
        return RoutePaths.staffNotifications;
    }
  }

  static String _initialsFromName(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}

class _WelcomeBackCopy extends StatelessWidget {
  const _WelcomeBackCopy({
    required this.name,
    required this.role,
    required this.warehouse,
    this.syncLabel,
  });

  final String name;
  final String role;
  final String warehouse;
  final String? syncLabel;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: WmsDesignTokens.body(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
            children: [
              const TextSpan(text: 'Welcome back, '),
              TextSpan(
                text: name,
                style: WmsDesignTokens.pageTitle(context).copyWith(
                  fontSize: 20,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          role,
          style: WmsDesignTokens.cardTitle(context).copyWith(
                color: primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.warehouse_outlined, size: WmsIconSizes.status, color: colors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Assigned Warehouses',
              style: WmsDesignTokens.description(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          warehouse,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: WmsDesignTokens.body(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
        ),
        if (syncLabel != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.sync_rounded, size: WmsIconSizes.status, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                syncLabel!,
                style: WmsDesignTokens.description(context).copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.initials, this.size = 48});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: primary.withValues(alpha: 0.25), width: 2),
      ),
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final pad = compact ? AppSpacing.xs : AppSpacing.sm;
    final iconSize = compact ? 18.0 : 22.0;
    return Material(
      color: wms.surfaceVariant,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Icon(
            Icons.notifications_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.icon,
    required this.label,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final wms = context.wms;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: wms.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: WmsIconSizes.status, color: primary),
          const SizedBox(width: WmsIconSizes.iconLabelGap),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
