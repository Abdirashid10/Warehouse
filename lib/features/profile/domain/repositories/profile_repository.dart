import 'package:logisticsmobile/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile();
}
