import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/constants/app_constants.dart';
import 'package:logisticsmobile/core/config/api_config.dart';
import 'package:logisticsmobile/core/settings/theme_cubit.dart';
import 'package:logisticsmobile/core/settings/theme_preferences.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_pushed_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    return WmsPushedScaffold(
      title: 'Settings',
      body: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          final wms = context.wms;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              Text(
                'Appearance, notifications, and app information',
                style: WmsDesignTokens.supporting(context),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(
                'Appearance',
                style: WmsDesignTokens.sectionTitle(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Choose how NexusLogistics looks on this device.',
                style: WmsDesignTokens.supporting(context),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                elevated: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final option in AppThemePreference.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            side: BorderSide(
                              color: themeState.preference == option
                                  ? colors.primary
                                  : wms.border,
                            ),
                          ),
                          tileColor: themeState.preference == option
                              ? wms.primaryLight
                              : null,
                          leading: Icon(
                            _themeIcon(option),
                            color: themeState.preference == option
                                ? colors.primary
                                : colors.iconSecondary,
                          ),
                          title: Text(
                            _themeLabel(option),
                            style: WmsDesignTokens.cardTitle(context),
                          ),
                          subtitle: Text(
                            _themeSubtitle(option),
                            style: WmsDesignTokens.supporting(context),
                          ),
                          trailing: themeState.preference == option
                              ? Icon(Icons.check_circle, color: colors.primary)
                              : null,
                          onTap: () => context
                              .read<ThemeCubit>()
                              .setThemePreference(option),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(
                'Notifications',
                style: WmsDesignTokens.sectionTitle(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: SwitchListTile(
                  title: Text('Push notifications', style: WmsDesignTokens.cardTitle(context)),
                  subtitle: Text(
                    'Operational alerts and warehouse updates',
                    style: WmsDesignTokens.supporting(context),
                  ),
                  value: themeState.pushNotifications,
                  onChanged: (v) => context.read<ThemeCubit>().setPushNotifications(v),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(
                'About',
                style: WmsDesignTokens.sectionTitle(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.warehouse_rounded, color: colors.primary),
                      title: Text(AppConstants.appName, style: WmsDesignTokens.cardTitle(context)),
                      subtitle: Text(
                        AppConstants.appTagline,
                        style: WmsDesignTokens.supporting(context),
                      ),
                    ),
                    Divider(height: 1, color: wms.divider),
                    ListTile(
                      leading: Icon(Icons.info_outline, color: colors.iconSecondary),
                      title: const Text('Version'),
                      trailing: Text('v${AppConstants.appVersion}'),
                    ),
                    ListTile(
                      leading: Icon(Icons.cloud_outlined, color: colors.iconSecondary),
                      title: const Text('API environment'),
                      subtitle: Text(ApiConfig.environmentLabel),
                    ),
                    ListTile(
                      leading: Icon(Icons.security_outlined, color: colors.iconSecondary),
                      title: const Text('Security'),
                      subtitle: const Text('Secure session storage and token handling'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _themeIcon(AppThemePreference preference) {
    switch (preference) {
      case AppThemePreference.system:
        return Icons.brightness_auto_rounded;
      case AppThemePreference.light:
        return Icons.light_mode_outlined;
      case AppThemePreference.dark:
        return Icons.dark_mode_outlined;
    }
  }

  String _themeLabel(AppThemePreference preference) {
    switch (preference) {
      case AppThemePreference.system:
        return 'System default';
      case AppThemePreference.light:
        return 'Light';
      case AppThemePreference.dark:
        return 'Dark';
    }
  }

  String _themeSubtitle(AppThemePreference preference) {
    switch (preference) {
      case AppThemePreference.system:
        return 'Match device light/dark setting';
      case AppThemePreference.light:
        return 'Enterprise light workspace';
      case AppThemePreference.dark:
        return 'Reduced glare for low-light warehouses';
    }
  }
}
