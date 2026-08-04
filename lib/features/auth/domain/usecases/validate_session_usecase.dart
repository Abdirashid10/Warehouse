import 'package:logisticsmobile/features/auth/domain/entities/user.dart';
import 'package:logisticsmobile/features/auth/domain/repositories/auth_repository.dart';

class ValidateSessionUseCase {
  const ValidateSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<User?> call() => _repository.validateSession();
}
