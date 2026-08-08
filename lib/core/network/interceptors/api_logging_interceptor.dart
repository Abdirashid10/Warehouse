import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Structured request/response logging for development.
class ApiLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint(
      '→ ${options.method} ${options.uri}\n'
      '  Headers: ${options.headers}\n'
      '  Body: ${options.data}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    debugPrint(
      '← ${response.statusCode} ${response.requestOptions.uri}\n'
      '  Data: ${response.data}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '✕ ${err.requestOptions.method} ${err.requestOptions.uri}\n'
      '  ${err.message}\n'
      '  Response: ${err.response?.data}',
    );
    handler.next(err);
  }
}
