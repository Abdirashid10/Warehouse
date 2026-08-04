import 'package:logisticsmobile/features/auth/domain/entities/auth_session.dart';
import 'package:logisticsmobile/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<User?> restoreSession();

  Future<User?> validateSession();

  Future<User?> getCurrentUser();

  Stream<User?> get userStream;
}
