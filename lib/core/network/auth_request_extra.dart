import 'package:dio/dio.dart';

/// Dio [RequestOptions.extra] flags for auth-aware interceptors.
abstract final class AuthRequestExtra {
  static const String skipSessionExpiry = 'skip_session_expiry';

  static bool shouldSkipSessionExpiry(RequestOptions options) {
    return options.extra[skipSessionExpiry] == true;
  }
}
