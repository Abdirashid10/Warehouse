import 'package:equatable/equatable.dart';

enum ApiExceptionType {
  network,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  cancelled,
  unknown,
}

class ApiException extends Equatable implements Exception {
  const ApiException({
    required this.message,
    this.type = ApiExceptionType.unknown,
    this.statusCode,
  });

  final String message;
  final ApiExceptionType type;
  final int? statusCode;

  factory ApiException.network([String? message]) => ApiException(
        message: message ?? 'Network unavailable. Check your connection.',
        type: ApiExceptionType.network,
      );

  factory ApiException.unauthorized([String? message]) => ApiException(
        message: message ?? 'Session expired. Please sign in again.',
        type: ApiExceptionType.unauthorized,
        statusCode: 401,
      );

  factory ApiException.forbidden([String? message]) => ApiException(
        message: message ??
            'You do not have permission to perform this action.',
        type: ApiExceptionType.forbidden,
        statusCode: 403,
      );

  factory ApiException.server([String? message, int? code]) => ApiException(
        message: message ?? 'Server unavailable. Please try again later.',
        type: ApiExceptionType.server,
        statusCode: code,
      );

  factory ApiException.notFound([String? message]) => ApiException(
        message: message ?? 'The requested resource was not found.',
        type: ApiExceptionType.notFound,
        statusCode: 404,
      );

  factory ApiException.validation([String? message]) => ApiException(
        message: message ?? 'Invalid request. Please check your input.',
        type: ApiExceptionType.validation,
        statusCode: 400,
      );

  @override
  List<Object?> get props => [message, type, statusCode];

  @override
  String toString() => message;
}
