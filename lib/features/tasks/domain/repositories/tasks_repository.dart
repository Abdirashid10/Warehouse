import 'package:logisticsmobile/features/tasks/domain/entities/create_task_input.dart';

import 'package:logisticsmobile/features/tasks/domain/entities/task_assignee.dart';

import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';



abstract class TasksRepository {

  Future<List<WarehouseTask>> getTasks({String? status});

  Future<WarehouseTask> getTask(String id);

  Future<TaskFormMeta> getFormMeta();

  Future<List<TaskAssignee>> getAssignees(String warehouseId);

  Future<WarehouseTask> createTask(CreateTaskInput input);

  Future<WarehouseTask> reassignTask({

    required String id,

    required ReassignTaskInput input,

  });

  Future<WarehouseTask> updateTaskStatus({

    required String id,

    required String status,

    String? note,

  });

}


