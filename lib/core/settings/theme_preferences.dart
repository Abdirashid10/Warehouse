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

  /// The stored preference, or [AppThemePreference.system] when the user has
  /// never chosen one.
  ///
  /// Following the OS is the correct default: a device in dark mode that opens
  /// this app to a white screen reads as a bug, and the user should not have to
  /// set the same preference twice.
  AppThemePreference get themePreference {
    final value = _prefs.getString(ThemePreferenceKeys.themeMode);
    return AppThemePreference.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemePreference.system,
    );
  }

  /// Whether the user has explicitly chosen a mode, as opposed to inheriting
  /// the system setting.
  bool get hasExplicitPreference =>
      _prefs.getString(ThemePreferenceKeys.themeMode) != null;

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
