import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/config/api_config.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';

abstract final class ErrorMessageMapper {
  static String fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Cannot reach backend at ${ApiConfig.baseUrl}. '
            'Start the Node.js server and verify the port (default 8000).';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badResponse:
        return fromResponse(error.response);
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static String fromResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    final message = _extractMessage(response?.data);

    switch (statusCode) {
      case 400:
        return message ?? 'Invalid request. Please check your input.';
      case 401:
        return message ?? 'Invalid email or password.';
      case 403:
        return message ?? 'You do not have permission to perform this action.';
      case 404:
        return message ?? 'The requested resource was not found.';
      case 422:
        return message ?? 'Validation failed. Please check your input.';
      case 500:
      case 502:
      case 503:
        return message ?? 'Server unavailable. Please try again later.';
      default:
        return message ?? 'Something went wrong. Please try again.';
    }
  }

  static String fromApiException(ApiException exception) {
    switch (exception.type) {
      case ApiExceptionType.network:
        return 'Network unavailable. Check your connection and try again.';
      case ApiExceptionType.unauthorized:
        return exception.message.isNotEmpty
            ? exception.message
            : 'Session expired. Please sign in again.';
      case ApiExceptionType.forbidden:
        return exception.message.isNotEmpty
            ? exception.message
            : 'You do not have permission to perform this action.';
      case ApiExceptionType.server:
        return 'Server unavailable. Please try again later.';
      case ApiExceptionType.notFound:
        return exception.message.isNotEmpty
            ? exception.message
            : 'The requested resource was not found.';
      case ApiExceptionType.validation:
        return exception.message.isNotEmpty
            ? exception.message
            : 'Invalid request. Please check your input.';
      default:
        return exception.message;
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is String && data.isNotEmpty) return data;
    if (data is Map) {
      for (final key in ['message', 'error', 'msg', 'detail']) {
        final value = data[key];
        if (value is String && value.isNotEmpty) return value;
      }
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }
      }
    }
    return null;
  }
}
