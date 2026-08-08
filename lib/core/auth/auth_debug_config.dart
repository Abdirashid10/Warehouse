import 'package:flutter/foundation.dart';

/// Auth diagnostics — production values are gated on [kDebugMode].
abstract final class AuthDebugConfig {
  /// When true: do not clear session or emit session-expired on 401 (logs only).
  static bool get disableAutomaticLogout => kDebugMode;

  /// Verbose console logging for the full sign-in pipeline.
  static bool get verboseAuthLogging => kDebugMode;

  /// Show AlertDialog + SnackBar for every auth failure (not only login form).
  static bool get showFailureDialogs => kDebugMode;
}
