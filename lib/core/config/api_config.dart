import 'package:flutter/foundation.dart';
import 'package:logisticsmobile/core/config/release_config.dart';

/// Centralized API configuration for the Logistics WMS backend.
///
/// Priority: `API_BASE_URL` dart-define → `API_ENV` preset → development default.
///
/// ```bash
/// # Local machine (desktop / iOS simulator)
/// flutter run --dart-define=API_ENV=development
///
/// # Android emulator → host machine
/// flutter run --dart-define=API_ENV=emulator
///
/// # Physical device on LAN
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.42:8000/api
/// ```
abstract final class ApiConfig {
  /// Backend port (`API_PORT` dart-define overrides; default matches running Node server).
  static const int backendPort =
      int.fromEnvironment('API_PORT', defaultValue: 8000);

  /// Optional override: `development` | `emulator`
  static const String environment = String.fromEnvironment('API_ENV');

  /// Explicit base URL (physical device / CI). Takes precedence over [environment].
  static const String baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static String get developmentBaseUrl =>
      'http://localhost:$backendPort/api';

  /// Android emulator → host loopback via `10.0.2.2` (not `localhost`).
  static String get emulatorBaseUrl => 'http://172.16.0.16:$backendPort/api';

  /// Resolves `POST {baseUrl}/auth/login` → `/api/auth/login`.
  static String get baseUrl {
    if (ReleaseConfig.apiBaseUrlOverride.isNotEmpty) {
      return _normalize(ReleaseConfig.apiBaseUrlOverride);
    }
    if (baseUrlOverride.isNotEmpty) {
      return _normalize(baseUrlOverride);
    }
    switch (environment) {
      case 'emulator':
        return emulatorBaseUrl;
      case 'development':
      case 'local':
        return developmentBaseUrl;
      default:
        return kIsWeb ? developmentBaseUrl : emulatorBaseUrl;
    }
  }

  static String get environmentLabel {
    if (baseUrlOverride.isNotEmpty) return 'custom';
    if (environment.isNotEmpty) return environment;
    return kIsWeb ? 'development' : 'emulator';
  }

  static bool get isConfigured =>
      baseUrlOverride.isNotEmpty || environment.isNotEmpty || kDebugMode;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static bool get enableRequestLogging =>
      kDebugMode ||
      const bool.fromEnvironment('API_LOGGING', defaultValue: false);

  static String _normalize(String url) {
    var normalized = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      normalized = normalized
          .replaceFirst('http://localhost:', 'http://10.0.2.2:')
          .replaceFirst('https://localhost:', 'https://10.0.2.2:')
          .replaceFirst('http://127.0.0.1:', 'http://10.0.2.2:')
          .replaceFirst('https://127.0.0.1:', 'https://10.0.2.2:');
    }
    return normalized;
  }
}
