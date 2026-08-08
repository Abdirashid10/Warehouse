import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/settings/theme_provider.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_state.dart';

/// Global enterprise app header — shared across Admin, Supervisor, and Staff.
class WmsEnterpriseAppHeader extends StatelessWidget {
  const WmsEnterpriseAppHeader({
    super.key,
    this.subtitle = 'Warehouse Operations Center',
    required this.notificationsRoute,
    required this.profileRoute,
    this.onMenuTap,
    this.showGreeting = true,
  });

  final String subtitle;
  final String notificationsRoute;
  final String profileRoute;
  final VoidCallback? onMenuTap;
  final bool showGreeting;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    return Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onMenuTap,
                  icon: Icon(
                    Icons.menu_rounded,
                    color: colors.textPrimary,
                    size: WmsIconSizes.header,
                  ),
                  tooltip: 'Menu',
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: showGreeting
                      ? BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, auth) {
                            final name = auth.user?.fullName.trim();
                            final firstName = (name == null || name.isEmpty)
                                ? 'there'
                                : name.split(RegExp(r'\s+')).first;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '${WmsFormatters.greeting()}, $firstName',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: WmsDesignTokens.userName(context).copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: WmsDesignTokens.description(context).copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      : Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: WmsDesignTokens.sectionTitle(context).copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                ),
                _ThemeToggleButton(),
                IconButton(
                  onPressed: () => context.push(notificationsRoute),
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: colors.textPrimary,
                    size: WmsIconSizes.header,
                  ),
                  tooltip: 'Notifications',
                  visualDensity: VisualDensity.compact,
                ),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, auth) {
                    final user = auth.user;
                    return IconButton(
                      onPressed: () => context.go(profileRoute),
                      tooltip: 'Profile',
                      visualDensity: VisualDensity.compact,
                      icon: CircleAvatar(
                        radius: 14,
                        backgroundColor: colors.primaryMuted,
                        child: Text(
                          user?.initials ?? '?',
                          style: WmsDesignTokens.badge(context).copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final isDark = ThemeProvider.isDark(context);
    final emoji = ThemeProvider.modeEmoji(context);

    return Tooltip(
      message: 'Switch to ${isDark ? 'Light' : 'Dark'} Mode',
      child: IconButton(
        onPressed: () => ThemeProvider.toggle(context),
        icon: Text(emoji, style: const TextStyle(fontSize: 18)),
        color: colors.textSecondary,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
