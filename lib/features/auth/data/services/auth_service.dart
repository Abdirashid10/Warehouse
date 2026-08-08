import 'package:logisticsmobile/core/auth/auth_debug_log.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:logisticsmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:logisticsmobile/features/auth/domain/entities/auth_session.dart';
import 'package:logisticsmobile/features/auth/domain/entities/user.dart';

/// Coordinates remote auth calls and local token persistence.
class AuthService {
  AuthService({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remote = remoteDataSource,
        _local = localDataSource;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  /// POST /api/auth/login, persist JWT, then GET current user profile.
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final loginResponse = await _remote.login(
      email: email,
      password: password,
    );

    var session = loginResponse.toEntity();
    if (session.accessToken.isEmpty) {
      throw const ApiException(message: 'Invalid authentication response');
    }

    await _local.saveSession(session);

    try {
      final profile = await _remote.fetchCurrentUser();
      session = AuthSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        user: profile.toEntity(),
      );
      await _local.saveSession(session);
    } on ApiException catch (e, st) {
      AuthDebugLog.exception('signIn → fetchCurrentUser', e, st);
      if (e.type == ApiExceptionType.unauthorized) {
        // The login itself succeeded and returned a valid token + user. A 401
        // on the follow-up profile fetch should NOT discard the freshly issued
        // session — otherwise the user is bounced back to login and must retry.
        AuthDebugLog.step(
          'Profile 401 after login — keeping login payload (session preserved)',
        );
        return session;
      }
      AuthDebugLog.step(
        'Profile fetch failed (${e.message}); keeping login user payload',
      );
    } catch (e, st) {
      AuthDebugLog.exception('signIn → fetchCurrentUser', e, st);
      rethrow;
    }
    return session;
  }

  Future<void> signOut() => _remote.logout();

  Future<User> fetchProfile() async {
    final model = await _remote.fetchCurrentUser();
    return model.toEntity();
  }

  /// No refresh endpoint on Logistics WMS backend; returns null.
  Future<AuthSession?> refreshSession(String refreshToken) async => null;
}
