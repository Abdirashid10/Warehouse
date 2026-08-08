import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/settings/theme_cubit.dart';
import 'package:logisticsmobile/core/settings/theme_preferences.dart';

/// Global theme provider — wraps [ThemeCubit] for enterprise light/dark switching.
///
/// Use [ThemeProvider.of] / [ThemeProvider.toggle] instead of hard-coded colors.
abstract final class ThemeProvider {
  static ThemeCubit of(BuildContext context) => context.read<ThemeCubit>();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Toggle between light and dark (persisted).
  static Future<void> toggle(BuildContext context) async {
    final cubit = of(context);
    final next = isDark(context)
        ? AppThemePreference.light
        : AppThemePreference.dark;
    await cubit.setThemePreference(next);
  }

  static String modeLabel(BuildContext context) =>
      isDark(context) ? 'Dark Mode' : 'Light Mode';

  static String modeEmoji(BuildContext context) =>
      isDark(context) ? '🌙' : '☀';
}

extension ThemeProviderContext on BuildContext {
  ThemeCubit get themeProvider => ThemeProvider.of(this);

  bool get isDarkMode => ThemeProvider.isDark(this);
}
