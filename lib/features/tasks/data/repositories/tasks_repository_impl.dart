import 'package:logisticsmobile/features/tasks/data/datasources/tasks_remote_data_source.dart';

import 'package:logisticsmobile/features/tasks/domain/entities/create_task_input.dart';

import 'package:logisticsmobile/features/tasks/domain/entities/task_assignee.dart';

import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';

import 'package:logisticsmobile/features/tasks/domain/repositories/tasks_repository.dart';



class TasksRepositoryImpl implements TasksRepository {

  TasksRepositoryImpl(this._remote);



  final TasksRemoteDataSource _remote;



  @override

  Future<List<WarehouseTask>> getTasks({String? status}) async {

    final query = status != null && status.isNotEmpty

        ? {'status': status}

        : null;

    final models = await _remote.fetchTasks(query: query);

    return models.map((m) => m.toEntity()).toList();

  }



  @override

  Future<WarehouseTask> getTask(String id) async {

    final model = await _remote.fetchTask(id);

    return model.toEntity();

  }



  @override

  Future<TaskFormMeta> getFormMeta() => _remote.fetchFormMeta();



  @override

  Future<List<TaskAssignee>> getAssignees(String warehouseId) =>

      _remote.fetchAssignees(warehouseId);



  @override

  Future<WarehouseTask> createTask(CreateTaskInput input) async {

    final model = await _remote.createTask(input);

    return model.toEntity();

  }



  @override

  Future<WarehouseTask> reassignTask({

    required String id,

    required ReassignTaskInput input,

  }) async {

    final model = await _remote.reassignTask(id: id, input: input);

    return model.toEntity();

  }



  @override

  Future<WarehouseTask> updateTaskStatus({

    required String id,

    required String status,

    String? note,

  }) async {

    final model = await _remote.updateStatus(id: id, status: status, note: note);

    return model.toEntity();

  }

}


