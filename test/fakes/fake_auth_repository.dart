import 'dart:async';

import 'package:logisticsmobile/features/auth/domain/entities/auth_session.dart';
import 'package:logisticsmobile/features/auth/domain/entities/user.dart';
import 'package:logisticsmobile/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  User? _user;
  final _controller = StreamController<User?>.broadcast();

  @override
  Stream<User?> get userStream => _controller.stream;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<User?> restoreSession() async {
    _controller.add(_user);
    return _user;
  }

  @override
  Future<User?> validateSession() async => _user;

  @override
  Future<User?> getCurrentUser() async => _user;

  void dispose() => _controller.close();
}
