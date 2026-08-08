import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/create_task_input.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/features/tasks/domain/repositories/tasks_repository.dart';

class TaskDetailCubit extends Cubit<ResourceState<WarehouseTask>> {
  TaskDetailCubit(this._repository) : super(const ResourceState.initial());

  final TasksRepository _repository;
  String? _taskId;

  Future<void> load(String id) async {
    _taskId = id;
    emit(const ResourceState.loading());
    try {
      final task = await _repository.getTask(id);
      emit(ResourceState.success(task));
    } on ApiException catch (e) {
      emit(ResourceState.failure(ErrorMessageMapper.fromApiException(e)));
    } catch (_) {
      emit(const ResourceState.failure('Failed to load task'));
    }
  }

  Future<void> updateStatus(String status, {String? note}) async {
    final id = _taskId;
    if (id == null) return;
    emit(ResourceState.loading(data: state.data));
    try {
      final task = await _repository.updateTaskStatus(
        id: id,
        status: status,
        note: note,
      );
      emit(ResourceState.success(task));
    } on ApiException catch (e) {
      emit(ResourceState.failure(
        ErrorMessageMapper.fromApiException(e),
        data: state.data,
      ));
      rethrow;
    }
  }

  Future<WarehouseTask> reassign(ReassignTaskInput input) async {
    final id = _taskId;
    if (id == null) {
      throw const ApiException(message: 'Task not loaded');
    }
    emit(ResourceState.loading(data: state.data));
    try {
      final task = await _repository.reassignTask(id: id, input: input);
      emit(ResourceState.success(task));
      return task;
    } on ApiException catch (e) {
      emit(ResourceState.failure(
        ErrorMessageMapper.fromApiException(e),
        data: state.data,
      ));
      rethrow;
    }
  }
}
