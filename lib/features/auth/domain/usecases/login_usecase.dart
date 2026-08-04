import 'package:logisticsmobile/features/auth/domain/entities/auth_session.dart';
import 'package:logisticsmobile/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call({
    required String email,
    required String password,
  }) =>
      _repository.login(email: email, password: password);
}
