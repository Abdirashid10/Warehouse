import 'package:logisticsmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:logisticsmobile/features/auth/domain/entities/auth_session.dart';

/// Auth API service — login, logout, session refresh.
class AuthApiService {
  AuthApiService(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    return response.toEntity();
  }

  Future<void> logout() => _remoteDataSource.logout();

  /// Backend does not expose a refresh endpoint; session ends on 401.
  Future<AuthSession?> refreshSession(String refreshToken) async => null;
}
