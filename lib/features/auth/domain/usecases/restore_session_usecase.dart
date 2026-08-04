import 'package:logisticsmobile/features/auth/domain/entities/user.dart';
import 'package:logisticsmobile/features/auth/domain/repositories/auth_repository.dart';

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<User?> call() => _repository.restoreSession();
}
