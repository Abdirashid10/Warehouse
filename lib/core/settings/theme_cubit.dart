import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/settings/theme_preferences.dart';

class ThemeState {
  const ThemeState({
    required this.themeMode,
    required this.preference,
    this.pushNotifications = true,
  });

  final ThemeMode themeMode;
  final AppThemePreference preference;
  final bool pushNotifications;

  ThemeState copyWith({
    ThemeMode? themeMode,
    AppThemePreference? preference,
    bool? pushNotifications,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      preference: preference ?? this.preference,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this._preferences)
      : super(
          const ThemeState(
            themeMode: ThemeMode.light,
            preference: AppThemePreference.light,
          ),
        );

  final ThemePreferences _preferences;

  Future<void> load() async {
    final preference = _preferences.themePreference;
    emit(
      ThemeState(
        themeMode: themeModeFromPreference(preference),
        preference: preference,
        pushNotifications: _preferences.pushNotificationsEnabled,
      ),
    );
  }

  Future<void> setThemePreference(AppThemePreference preference) async {
    await _preferences.setThemePreference(preference);
    emit(
      state.copyWith(
        preference: preference,
        themeMode: themeModeFromPreference(preference),
      ),
    );
  }

  Future<void> setPushNotifications(bool enabled) async {
    await _preferences.setPushNotificationsEnabled(enabled);
    emit(state.copyWith(pushNotifications: enabled));
  }
}
