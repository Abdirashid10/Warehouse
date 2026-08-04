import 'package:logisticsmobile/features/users/domain/entities/create_user_input.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';

abstract class UsersRepository {
  Future<List<WmsUser>> getUsers();
  Future<WmsUser> createUser(CreateUserInput input);
  Future<WmsUser> updateUserStatus({required String id, required String status});
}
