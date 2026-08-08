import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/auth/auth_debug_config.dart';
import 'package:logisticsmobile/core/auth/auth_debug_log.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/network/auth_request_extra.dart';
import 'package:logisticsmobile/core/network/unauthorized_handler.dart';
import 'package:logisticsmobile/core/storage/session_storage.dart';

/// Clears local session and notifies the app when the token is rejected (401).
class UnauthorizedInterceptor extends Interceptor {
  UnauthorizedInterceptor({
    required SessionStorage sessionStorage,
    required UnauthorizedHandler unauthorizedHandler,
  })  : _sessionStorage = sessionStorage,
        _handler = unauthorizedHandler;

  final SessionStorage _sessionStorage;
  final UnauthorizedHandler _handler;

  static const _publicPaths = [
    ApiConstants.login,
    '/auth/bootstrap',
    '/auth/bootstrap-status',
  ];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final is401 = err.response?.statusCode == 401;
    final isPublic = _isPublicAuthPath(err.requestOptions.path);
    final skipExpiry = AuthRequestExtra.shouldSkipSessionExpiry(err.requestOptions);

    if (is401 && !isPublic) {
      final path = '${err.requestOptions.method} ${err.requestOptions.path}';
      AuthDebugLog.exception(
        'HTTP 401 $path (skipSessionExpiry=$skipExpiry)',
        err,
        err.stackTrace,
      );

      if (AuthDebugConfig.disableAutomaticLogout) {
        AuthDebugLog.autoLogoutBlocked(
          path: path,
          statusCode: 401,
          detail: err.response?.data?.toString(),
        );
        handler.next(err);
        return;
      }

      if (!skipExpiry) {
        await _sessionStorage.clearSession();
        _handler.notifySessionExpired();
      }
    }
    handler.next(err);
  }

  bool _isPublicAuthPath(String path) {
    for (final public in _publicPaths) {
      if (path.contains(public)) return true;
    }
    return false;
  }
}
