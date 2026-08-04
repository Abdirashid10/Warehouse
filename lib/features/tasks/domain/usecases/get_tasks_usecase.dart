import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/features/tasks/domain/repositories/tasks_repository.dart';

class GetTasksUseCase {
  const GetTasksUseCase(this._repository);

  final TasksRepository _repository;

  Future<List<WarehouseTask>> call({String? status}) =>
      _repository.getTasks(status: status);
}
