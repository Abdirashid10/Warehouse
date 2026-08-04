import 'package:logisticsmobile/features/profile/domain/entities/user_profile.dart';
import 'package:logisticsmobile/features/profile/domain/repositories/profile_repository.dart';

class GetProfileUseCase {
  const GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<UserProfile> call() => _repository.getProfile();
}
