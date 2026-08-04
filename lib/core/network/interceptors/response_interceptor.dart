import 'package:dio/dio.dart';

/// Normalizes successful responses and debug metadata before repositories parse them.
class ResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    response.extra['receivedAt'] = DateTime.now().toIso8601String();
    handler.next(response);
  }
}
