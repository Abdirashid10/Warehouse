import 'package:logisticsmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:logisticsmobile/features/auth/domain/entities/user.dart';

/// User API service — profile and account operations.
class UserApiService {
  UserApiService(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  Future<User> getCurrentUser() async {
    final model = await _remoteDataSource.fetchCurrentUser();
    return model.toEntity();
  }
}
