import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { system, light, dark }

abstract final class ThemePreferenceKeys {
  static const themeMode = 'app_theme_mode';
  static const pushNotifications = 'push_notifications_enabled';
}

class ThemePreferences {
  ThemePreferences(this._prefs);

  final SharedPreferences _prefs;

  static Future<ThemePreferences> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemePreferences(prefs);
  }

  AppThemePreference get themePreference {
    final value = _prefs.getString(ThemePreferenceKeys.themeMode);
    return AppThemePreference.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemePreference.light,
    );
  }

  Future<void> setThemePreference(AppThemePreference preference) {
    return _prefs.setString(ThemePreferenceKeys.themeMode, preference.name);
  }

  bool get pushNotificationsEnabled =>
      _prefs.getBool(ThemePreferenceKeys.pushNotifications) ?? true;

  Future<void> setPushNotificationsEnabled(bool enabled) {
    return _prefs.setBool(ThemePreferenceKeys.pushNotifications, enabled);
  }
}

ThemeMode themeModeFromPreference(AppThemePreference preference) {
  switch (preference) {
    case AppThemePreference.system:
      return ThemeMode.system;
    case AppThemePreference.light:
      return ThemeMode.light;
    case AppThemePreference.dark:
      return ThemeMode.dark;
  }
}
