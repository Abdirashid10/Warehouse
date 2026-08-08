import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logisticsmobile/core/auth/auth_debug_config.dart';
import 'package:logisticsmobile/features/auth/domain/entities/user.dart';
import 'package:logisticsmobile/features/auth/domain/entities/user_role.dart';

/// Structured auth-flow logging for diagnosing sign-in issues.
abstract final class AuthDebugLog {
  static void step(String message) {
    if (!AuthDebugConfig.verboseAuthLogging && !kDebugMode) return;
    debugPrint('[Auth] $message');
  }

  static void _log(String message) => step(message);

  static String _sanitizeBody(dynamic body) {
    if (body == null) return 'null';
    try {
      if (body is Map || body is List) {
        final copy = jsonDecode(jsonEncode(body)) as dynamic;
        if (copy is Map) {
          for (final key in ['token', 'accessToken', 'access_token', 'jwt']) {
            if (copy.containsKey(key) && copy[key] != null) {
              final t = copy[key].toString();
              copy[key] =
                  t.length <= 16 ? '***' : '${t.substring(0, 12)}…(${t.length} chars)';
            }
          }
        }
        return jsonEncode(copy);
      }
      return body.toString();
    } catch (_) {
      return body.toString();
    }
  }

  static void loginRequest({required String url, required String email}) {
    _log('(1) Login request URL: $url');
    _log('    Login email: $email');
  }

  static void loginHttpResponse({
    required int? statusCode,
    required dynamic body,
  }) {
    _log('(2) Login response status code: $statusCode');
    _log('(3) Login response body: ${_sanitizeBody(body)}');
  }

  static void extractedToken(String? token) {
    if (token == null || token.isEmpty) {
      _log('(4) Extracted token: MISSING');
    } else {
      _log(
        '(4) Extracted token: ${token.substring(0, token.length.clamp(0, 12))}… '
        '(${token.length} chars)',
      );
    }
  }

  static void tokenSaveResult({required bool success, String? detail}) {
    _log(
      '(5) Token saved successfully: $success'
      '${detail != null ? " — $detail" : ""}',
    );
  }

  static void profileHttpResponse({
    required String url,
    required int? statusCode,
    required dynamic body,
  }) {
    _log('(6) GET /profile/me URL: $url');
    _log('(6) GET /profile/me status code: $statusCode');
    _log('(7) GET /profile/me response body: ${_sanitizeBody(body)}');
  }

  static void parsedUserObject(Map<String, dynamic>? json) {
    if (json == null) {
      _log('(8) Parsed user object: null');
      return;
    }
    _log('(8) Parsed user object: ${_sanitizeBody(json)}');
  }

  static void parsedRole({String? roleRaw, UserRole? parsed}) {
    _log('(9) Parsed role: raw="$roleRaw" → enum=${parsed?.name ?? "unknown"}');
  }

  static void navigationRoute(String route, {String? reason}) {
    _log('(10) Navigation route selected: $route${reason != null ? " ($reason)" : ""}');
  }

  static void parsedUser(User user) {
    parsedRole(roleRaw: user.role.name, parsed: user.role);
    _log(
      '    User id=${user.id} name=${user.fullName} email=${user.email}',
    );
  }

  static void exception(
    String context,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    _log('EXCEPTION in $context: $error');
    if (stackTrace != null) {
      _log('Stack trace:\n$stackTrace');
    }
  }

  static void redirect({
    required String from,
    required String? to,
    required String authStatus,
    String? reason,
  }) {
    _log(
      'Router redirect: $from → ${to ?? "stay"} [status=$authStatus]'
      '${reason != null ? " reason=$reason" : ""}',
    );
  }

  static void sessionCheckSkipped(String reason) {
    _log('Session check skipped: $reason');
  }

  static void autoLogoutBlocked({
    required String path,
    required int? statusCode,
    String? detail,
  }) {
    _log(
      'AUTO-LOGOUT DISABLED — would have cleared session for '
      '$path status=$statusCode${detail != null ? " $detail" : ""}',
    );
  }

  static void blocTransition({
    required String from,
    required String to,
    String? detail,
  }) {
    _log('Bloc: $from → $to${detail != null ? " | $detail" : ""}');
  }
}
