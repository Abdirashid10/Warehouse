import 'package:flutter/foundation.dart';
import 'package:logisticsmobile/core/config/release_config.dart';

/// Centralized API configuration for the Logistics WMS backend.
///
/// The default target is the on-premises Node API on the lab LAN. No flags are
/// needed for a normal run on an emulator or a device attached to that network:
///
/// ```bash
/// flutter run                       # → http://172.16.0.44:8000/api
/// ```
///
/// Resolution order (first match wins):
///  1. `API_BASE_URL` dart-define — a full base URL, for CI or a moved server
///  2. `API_HOST` / `API_PORT` dart-defines — swap just the host or port
///  3. `API_ENV` preset — `local` (same machine) or `emulator` (host loopback)
///  4. the LAN default below
///
/// ```bash
/// # Server moved to a new address — no code change required
/// flutter run --dart-define=API_HOST=172.16.0.51
/// flutter run --dart-define=API_BASE_URL=https://wms.example.com/api
///
/// # Desktop or web against a server on this same machine
/// flutter run --dart-define=API_ENV=local
/// ```
abstract final class ApiConfig {
  /// Host running the Node API.
  ///
  /// This is a static LAN address, so it is only stable while the server keeps
  /// that lease. Give the machine a DHCP reservation (or a static IP) — if it
  /// ever changes, requests will land on whatever host inherits the address
  /// rather than failing outright, which is a confusing failure to diagnose.
  /// Override with `--dart-define=API_HOST=...` instead of editing this file.
  static const String backendHost =
      String.fromEnvironment('API_HOST', defaultValue: '172.24.230.134');

  /// Backend port (`API_PORT` dart-define overrides).
  static const int backendPort =
      int.fromEnvironment('API_PORT', defaultValue: 8000);

  /// Optional preset: `local` | `development` | `emulator`.
  static const String environment = String.fromEnvironment('API_ENV');

  /// Explicit full base URL. Takes precedence over every other source.
  static const String baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Permanent default — the on-premises API on the LAN.
  ///
  /// Reachable from both physical devices and Android emulators, since the
  /// emulator routes through the host's network stack.
  static String get lanBaseUrl => 'http://$backendHost:$backendPort/api';

  /// Same machine as the app (desktop, web, iOS simulator).
  static String get developmentBaseUrl => 'http://localhost:$backendPort/api';

  /// Android emulator → host loopback via `10.0.2.2` (not `localhost`).
  static String get emulatorBaseUrl => 'http://10.0.2.2:$backendPort/api';

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
        return _normalize(emulatorBaseUrl);
      case 'development':
      case 'local':
        // On Android `localhost` is the device itself, so _normalize rewrites
        // it to the emulator's host-loopback alias.
        return _normalize(developmentBaseUrl);
      default:
        return _normalize(lanBaseUrl);
    }
  }

  /// Host portion of the resolved [baseUrl] — used by diagnostics and by the
  /// Android network-security config check.
  static String get resolvedHost => Uri.parse(baseUrl).host;

  /// Whether the resolved endpoint is plaintext HTTP. Cleartext is permitted
  /// only for the on-premises hosts allow-listed in the platform configs.
  static bool get isCleartext => Uri.parse(baseUrl).scheme == 'http';

  static String get environmentLabel {
    if (ReleaseConfig.apiBaseUrlOverride.isNotEmpty) return 'release-override';
    if (baseUrlOverride.isNotEmpty) return 'custom';
    if (environment.isNotEmpty) return environment;
    return 'lan';
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
