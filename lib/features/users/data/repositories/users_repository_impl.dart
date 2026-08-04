import 'package:logisticsmobile/features/users/data/datasources/users_remote_data_source.dart';
import 'package:logisticsmobile/features/users/domain/entities/create_user_input.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';
import 'package:logisticsmobile/features/users/domain/repositories/users_repository.dart';

class UsersRepositoryImpl implements UsersRepository {
  UsersRepositoryImpl(this._remote);

  final UsersRemoteDataSource _remote;

  @override
  Future<List<WmsUser>> getUsers() => _remote.fetchUsers();

  @override
  Future<WmsUser> createUser(CreateUserInput input) => _remote.createUser(input);

  @override
  Future<WmsUser> updateUserStatus({
    required String id,
    required String status,
  }) =>
      _remote.updateStatus(id: id, status: status);
}
