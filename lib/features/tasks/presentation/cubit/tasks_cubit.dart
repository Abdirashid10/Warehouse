import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/utils/task_workflow_utils.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/create_task_input.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/features/tasks/domain/repositories/tasks_repository.dart';
import 'package:logisticsmobile/features/tasks/domain/usecases/get_tasks_usecase.dart';

class TasksListState {
  const TasksListState({
    required this.tasks,
    this.nameQuery = '',
    this.productQuery = '',
    this.warehouseQuery = '',
    this.statusFilter,
    this.typeFilter,
    this.priorityFilter,
    this.showFilters = false,
  });

  final List<WarehouseTask> tasks;
  final String nameQuery;
  final String productQuery;
  final String warehouseQuery;
  final String? statusFilter;
  final String? typeFilter;
  final String? priorityFilter;
  final bool showFilters;

  TasksSummary get summary => TaskWorkflowUtils.summarize(tasks);

  TaskPerformanceMetrics get performance =>
      TaskWorkflowUtils.performanceMetrics(tasks);

  List<TaskActivityItem> get recentActivity =>
      TaskWorkflowUtils.recentActivity(tasks);

  int get activeFilterCount {
    var count = 0;
    if (statusFilter != null) count++;
    if (typeFilter != null) count++;
    if (priorityFilter != null) count++;
    return count;
  }

  List<WarehouseTask> get filtered {
    var list = TaskWorkflowUtils.filterByStatus(tasks, statusFilter);

    if (typeFilter != null && typeFilter!.isNotEmpty) {
      final type = typeFilter!.toLowerCase();
      list = list
          .where((t) => t.taskType.toLowerCase().contains(type))
          .toList();
    }

    if (priorityFilter != null && priorityFilter!.isNotEmpty) {
      list =
          list.where((t) => t.priority == priorityFilter).toList();
    }

    final name = nameQuery.trim().toLowerCase();
    if (name.isNotEmpty) {
      list = list.where((t) => t.title.toLowerCase().contains(name)).toList();
    }

    final product = productQuery.trim().toLowerCase();
    if (product.isNotEmpty) {
      list = list
          .where(
            (t) => (t.productName?.toLowerCase().contains(product) ?? false),
          )
          .toList();
    }

    final warehouse = warehouseQuery.trim().toLowerCase();
    if (warehouse.isNotEmpty) {
      list = list
          .where(
            (t) =>
                (t.warehouseName?.toLowerCase().contains(warehouse) ?? false),
          )
          .toList();
    }

    return list;
  }

  TasksListState copyWith({
    List<WarehouseTask>? tasks,
    String? nameQuery,
    String? productQuery,
    String? warehouseQuery,
    String? statusFilter,
    String? typeFilter,
    String? priorityFilter,
    bool? showFilters,
    bool clearStatusFilter = false,
    bool clearTypeFilter = false,
    bool clearPriorityFilter = false,
  }) {
    return TasksListState(
      tasks: tasks ?? this.tasks,
      nameQuery: nameQuery ?? this.nameQuery,
      productQuery: productQuery ?? this.productQuery,
      warehouseQuery: warehouseQuery ?? this.warehouseQuery,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      priorityFilter:
          clearPriorityFilter ? null : (priorityFilter ?? this.priorityFilter),
      showFilters: showFilters ?? this.showFilters,
    );
  }
}

class TasksCubit extends Cubit<ResourceState<TasksListState>> {
  TasksCubit(this._getTasks, this._repository)
      : super(const ResourceState.initial());

  final GetTasksUseCase _getTasks;
  final TasksRepository _repository;

  Future<void> load() async {
    final current = state.data;
    emit(ResourceState.loading(data: current));
    try {
      final tasks = await _getTasks();
      emit(
        ResourceState.success(
          (current ?? const TasksListState(tasks: [])).copyWith(tasks: tasks),
        ),
      );
    } on ApiException catch (e) {
      emit(ResourceState.failure(
        ErrorMessageMapper.fromApiException(e),
        data: current,
      ));
    } catch (_) {
      emit(ResourceState.failure('Failed to load tasks', data: current));
    }
  }

  void setNameQuery(String query) => _mutate(
        (s) => s.copyWith(nameQuery: query),
      );

  void setProductQuery(String query) => _mutate(
        (s) => s.copyWith(productQuery: query),
      );

  void setWarehouseQuery(String query) => _mutate(
        (s) => s.copyWith(warehouseQuery: query),
      );

  void setStatusFilter(String? status) => _mutate(
        (s) => s.copyWith(
          statusFilter: status,
          clearStatusFilter: status == null,
        ),
      );

  void setTypeFilter(String? type) => _mutate(
        (s) => s.copyWith(
          typeFilter: type,
          clearTypeFilter: type == null,
        ),
      );

  void setPriorityFilter(String? priority) => _mutate(
        (s) => s.copyWith(
          priorityFilter: priority,
          clearPriorityFilter: priority == null,
        ),
      );

  void toggleFilters() => _mutate(
        (s) => s.copyWith(showFilters: !s.showFilters),
      );

  void clearFilters() => _mutate(
        (s) => s.copyWith(
          clearStatusFilter: true,
          clearTypeFilter: true,
          clearPriorityFilter: true,
        ),
      );

  Future<void> updateTaskStatus({
    required String taskId,
    required String status,
    String? note,
  }) async {
    final current = state.data;
    if (current == null) return;

    try {
      final updated = await _repository.updateTaskStatus(
        id: taskId,
        status: status,
        note: note,
      );
      final tasks = current.tasks
          .map((t) => t.id == taskId ? updated : t)
          .toList();
      emit(ResourceState.success(current.copyWith(tasks: tasks)));
    } on ApiException catch (e) {
      emit(ResourceState.failure(
        ErrorMessageMapper.fromApiException(e),
        data: current,
      ));
      rethrow;
    }
  }

  Future<WarehouseTask> createTask(CreateTaskInput input) async {
    final current = state.data;
    try {
      final created = await _repository.createTask(input);
      if (current != null) {
        emit(
          ResourceState.success(
            current.copyWith(tasks: [created, ...current.tasks]),
          ),
        );
      }
      return created;
    } on ApiException catch (e) {
      emit(ResourceState.failure(
        ErrorMessageMapper.fromApiException(e),
        data: current,
      ));
      rethrow;
    }
  }

  Future<WarehouseTask> reassignTask({
    required String taskId,
    required ReassignTaskInput input,
  }) async {
    final current = state.data;
    if (current == null) {
      return _repository.reassignTask(id: taskId, input: input);
    }
    try {
      final updated = await _repository.reassignTask(id: taskId, input: input);
      final tasks = current.tasks.map((t) => t.id == taskId ? updated : t).toList();
      emit(ResourceState.success(current.copyWith(tasks: tasks)));
      return updated;
    } on ApiException catch (e) {
      emit(ResourceState.failure(
        ErrorMessageMapper.fromApiException(e),
        data: current,
      ));
      rethrow;
    }
  }

  Future<void> refresh() => load();

  void _mutate(TasksListState Function(TasksListState) transform) {
    final data = state.data;
    if (data == null) return;
    emit(ResourceState.success(transform(data)));
  }
}

/// KPI filter keys used by the dashboard strip.
abstract final class TaskKpiFilter {
  static const total = '__total__';
  static const awaiting = WmsTaskStatuses.pending;
  static const accepted = WmsTaskStatuses.accepted;
  static const inProgress = WmsTaskStatuses.inProgress;
  static const completed = WmsTaskStatuses.completed;
  static const rejected = WmsTaskStatuses.rejected;
  static const overdue = WmsTaskStatuses.overdue;
}
