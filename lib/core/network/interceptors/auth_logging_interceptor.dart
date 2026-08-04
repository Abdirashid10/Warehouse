import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/network/api_response_parser.dart';

/// Debug logging for login responses and Authorization headers.
class AuthLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final auth = options.headers['Authorization']?.toString();
      final hasBearer = auth != null && auth.startsWith('Bearer ');
      final preview = hasBearer
          ? 'Bearer ${_maskToken(auth.substring(7))}'
          : '(none)';
      debugPrint(
        'Auth → ${options.method} ${options.path} | Authorization: $preview',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kDebugMode && response.requestOptions.path.contains(ApiConstants.login)) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final token = ApiResponseParser.extractToken(data);
        final user = ApiResponseParser.extractUser(data);
        debugPrint(
          'Auth ← login ${response.statusCode} | '
          'token: ${token != null ? '${token.length} chars (${_maskToken(token)})' : 'MISSING'} | '
          'user: ${user != null ? user['email'] ?? user['id'] : 'MISSING'}',
        );
      }
    }
    handler.next(response);
  }

  static String _maskToken(String token) {
    if (token.length <= 12) return '***';
    return '${token.substring(0, 8)}…${token.substring(token.length - 4)}';
  }
}
