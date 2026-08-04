import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/storage/session_storage.dart';

/// Attaches `Authorization: Bearer <token>` from secure session storage.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._sessionStorage);

  final SessionStorage _sessionStorage;

  static const _publicPaths = [
    ApiConstants.login,
    '/auth/bootstrap',
    '/auth/bootstrap-status',
  ];

  bool _isPublic(String path) {
    for (final p in _publicPaths) {
      if (path.contains(p)) return true;
    }
    return false;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options.path)) {
      final token = await _sessionStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      } else if (kDebugMode) {
        debugPrint(
          'Auth: no token for ${options.method} ${options.path}',
        );
      }
    }
    handler.next(options);
  }
}
