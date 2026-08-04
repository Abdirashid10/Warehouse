import 'dart:async';

import 'package:logisticsmobile/core/auth/auth_debug_config.dart';
import 'package:logisticsmobile/core/auth/auth_debug_log.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/storage/session_storage.dart';
import 'package:logisticsmobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:logisticsmobile/features/auth/data/models/user_model.dart';
import 'package:logisticsmobile/features/auth/data/services/auth_service.dart';
import 'package:logisticsmobile/features/auth/domain/entities/auth_session.dart';
import 'package:logisticsmobile/features/auth/domain/entities/user.dart';
import 'package:logisticsmobile/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthLocalDataSource localDataSource,
    required AuthService authService,
    required SessionStorage sessionStorage,
  })  : _local = localDataSource,
        _authService = authService,
        _sessionStorage = sessionStorage;

  final AuthLocalDataSource _local;
  final AuthService _authService;
  final SessionStorage _sessionStorage;

  final _userController = StreamController<User?>.broadcast();
  User? _currentUser;

  @override
  Stream<User?> get userStream => _userController.stream;

  void _emitUser(User? user) {
    _currentUser = user;
    _userController.add(user);
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _authService.signIn(email: email, password: password);
    _emitUser(session.user);
    return session;
  }

  @override
  Future<void> logout() async {
    try {
      await _authService.signOut();
    } finally {
      await _local.clearSession();
      _emitUser(null);
    }
  }

  @override
  Future<User?> restoreSession() async {
    final hasToken = await _local.hasValidToken();
    if (!hasToken) {
      _emitUser(null);
      return null;
    }

    final cached = await _local.getCachedUser();
    if (cached != null) {
      final user = cached.toEntity();
      _emitUser(user);
      return user;
    }

    return validateSession();
  }

  @override
  Future<User?> validateSession() async {
    final hasToken = await _local.hasValidToken();
    if (!hasToken) {
      await _local.clearSession();
      _emitUser(null);
      return null;
    }

    try {
      final user = await _authService.fetchProfile();
      await _persistUser(user);
      _emitUser(user);
      return user;
    } on ApiException catch (e, st) {
      AuthDebugLog.exception('validateSession', e, st);
      if (e.type == ApiExceptionType.unauthorized) {
        final refreshed = await _tryRefreshToken();
        if (refreshed != null) {
          _emitUser(refreshed);
          return refreshed;
        }
        if (AuthDebugConfig.disableAutomaticLogout) {
          final cached = await _local.getCachedUser();
          if (cached != null) {
            AuthDebugLog.step(
              'validateSession 401 — returning cached user (auto-logout disabled)',
            );
            final user = cached.toEntity();
            _emitUser(user);
            return user;
          }
        }
        await _local.clearSession();
        _emitUser(null);
        return null;
      }
      final cached = await _local.getCachedUser();
      if (cached != null) {
        final user = cached.toEntity();
        _emitUser(user);
        return user;
      }
      rethrow;
    } catch (e, st) {
      AuthDebugLog.exception('validateSession', e, st);
      rethrow;
    }
  }

  Future<User?> _tryRefreshToken() async {
    final refreshToken = await _sessionStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final session = await _authService.refreshSession(refreshToken);
    if (session == null) return null;

    await _local.saveSession(session);
    return session.user;
  }

  Future<void> _persistUser(User user) async {
    final model = UserModel(
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      role: user.role,
      warehouse: user.warehouse,
      permissions: user.permissions,
    );
    await _sessionStorage.saveUserJson(model.toJsonString());
    await _sessionStorage.saveUserRole(user.role.name);
  }

  @override
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    return restoreSession();
  }

  void dispose() {
    _userController.close();
  }
}
