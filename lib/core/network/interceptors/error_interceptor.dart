import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';

/// Maps [DioException] to typed [ApiException] for repositories and UI.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = _mapException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
        message: apiException.message,
      ),
    );
  }

  ApiException _mapException(DioException err) {
    if (err.error is ApiException) {
      return err.error as ApiException;
    }

    final message = ErrorMessageMapper.fromDioException(err);
    final statusCode = err.response?.statusCode;

    if (statusCode == 401) {
      return ApiException.unauthorized(message);
    }
    if (statusCode == 403) {
      return ApiException.forbidden(message);
    }
    if (statusCode == 404) {
      return ApiException.notFound(message);
    }
    if (statusCode == 400 || statusCode == 422) {
      return ApiException.validation(message);
    }
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return ApiException.network(message);
    }
    if (statusCode != null && statusCode >= 500) {
      return ApiException.server(message, statusCode);
    }

    return ApiException(message: message, statusCode: statusCode);
  }
}
