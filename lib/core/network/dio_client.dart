import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logisticsmobile/core/config/api_config.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/network/interceptors/api_logging_interceptor.dart';
import 'package:logisticsmobile/core/network/interceptors/auth_interceptor.dart';
import 'package:logisticsmobile/core/network/interceptors/auth_logging_interceptor.dart';
import 'package:logisticsmobile/core/network/interceptors/error_interceptor.dart';
import 'package:logisticsmobile/core/network/interceptors/response_interceptor.dart';
import 'package:logisticsmobile/core/network/interceptors/unauthorized_interceptor.dart';
import 'package:logisticsmobile/core/network/unauthorized_handler.dart';
import 'package:logisticsmobile/core/storage/session_storage.dart';

class DioClient {
  DioClient._();

  static Dio create({
    required SessionStorage sessionStorage,
    required UnauthorizedHandler unauthorizedHandler,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor(sessionStorage));
    if (kDebugMode || ApiConfig.enableRequestLogging) {
      dio.interceptors.add(AuthLoggingInterceptor());
    }
    if (ApiConfig.enableRequestLogging) {
      dio.interceptors.add(ApiLoggingInterceptor());
    }
    dio.interceptors.add(ResponseInterceptor());
    dio.interceptors.add(ErrorInterceptor());
    dio.interceptors.add(
      UnauthorizedInterceptor(
        sessionStorage: sessionStorage,
        unauthorizedHandler: unauthorizedHandler,
      ),
    );

    return dio;
  }
}
