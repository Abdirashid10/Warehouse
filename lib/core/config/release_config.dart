/// Production build constants — adjust before store release.
abstract final class ReleaseConfig {
  static const String applicationId = 'com.logistics.wms.mobile';
  static const String appDisplayName = 'Logistics WMS';

  /// Set via `--dart-define=API_BASE_URL=https://your-api.example/api`
  static const String apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const bool enableApiLogging = bool.fromEnvironment(
    'ENABLE_API_LOGGING',
    defaultValue: false,
  );

  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
}
