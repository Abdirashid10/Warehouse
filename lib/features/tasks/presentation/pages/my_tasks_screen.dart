import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/task_workflow_utils.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:logisticsmobile/features/tasks/presentation/cubit/tasks_cubit.dart';
import 'package:logisticsmobile/features/tasks/presentation/widgets/create_task_sheet.dart';
import 'package:logisticsmobile/features/tasks/presentation/widgets/reassign_task_sheet.dart';
import 'package:logisticsmobile/features/tasks/presentation/widgets/tasks_analytics_widgets.dart';
import 'package:logisticsmobile/features/tasks/presentation/widgets/tasks_enterprise_widgets.dart';
import 'package:logisticsmobile/routes/wms_route_paths.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Enterprise Tasks — mobile-first workflow screen aligned with web.
class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> with StaffScopeInitMixin {
  TasksCubit? _cubit;
  StaffRepositories? _repos;
  final _nameController = TextEditingController();
  final _productController = TextEditingController();
  final _warehouseController = TextEditingController();

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    _repos = repositories;
    setState(() {
      _cubit = TasksCubit(
        GetTasksUseCase(repositories.tasks),
        repositories.tasks,
      )..load();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _productController.dispose();
    _warehouseController.dispose();
    _cubit?.close();
    super.dispose();
  }

  bool _canManage(BuildContext context) {
    final role = context.read<AuthBloc>().state.user?.role;
    return role?.isAdmin == true || role?.isSupervisor == true;
  }

  void _openTask(BuildContext context, String taskId) {
    context.push(WmsRoutePaths.taskDetail(context, taskId));
  }

  Future<void> _handleAction(
    BuildContext context,
    TasksCubit cubit,
    TaskWorkflowAction action,
    String taskId,
  ) async {
    final colors = WmsUiColors.of(context);

    if (action.destructive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            '${action.label}?',
            style: TextStyle(color: colors.textPrimary),
          ),
          content: Text(
            'This will update the task workflow status.',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action.label),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    try {
      await cubit.updateTaskStatus(
        taskId: taskId,
        status: action.targetStatus,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task updated: ${action.label}')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessageMapper.fromApiException(e)),
            backgroundColor: colors.error,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not update task'),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

  void _onNewTask(BuildContext context) {
    final cubit = _cubit;
    final repos = _repos;
    if (cubit == null || repos == null) return;
    showCreateTaskSheet(context, cubit: cubit, repository: repos.tasks);
  }

  void _onReassign(BuildContext context, WarehouseTask task) {
    final cubit = _cubit;
    final repos = _repos;
    if (cubit == null || repos == null) return;
    showReassignFromList(
      context,
      task: task,
      cubit: cubit,
      repository: repos.tasks,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      return const Scaffold(body: StaffScopeLoadingBody());
    }

    final canManage = _canManage(context);
    final colors = WmsUiColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: widget.embeddedInShell
          ? null
          : AppBar(
              backgroundColor: colors.background,
              foregroundColor: colors.textPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
        title: Text(
          'Tasks',
          style: Theme.of(context).textTheme.titleLarge,
        ),
            ),
      body: BlocProvider.value(
        value: cubit,
        child: BlocBuilder<TasksCubit, ResourceState<TasksListState>>(
          builder: (context, state) {
            if ((state.isLoading || state.status == ResourceStatus.initial) &&
                state.data == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: colors.primary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Loading tasks…',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state.isFailure && state.data == null) {
              return WmsErrorState(
                message: state.message ?? 'Failed to load tasks',
                onRetry: cubit.refresh,
              );
            }

            final data = state.data;
            if (data == null) {
              return WmsErrorState(
                message: state.message ?? 'Failed to load tasks',
                onRetry: cubit.refresh,
              );
            }

            final items = data.filtered;
            final all = data.tasks;

            return RefreshIndicator(
              color: colors.primary,
              backgroundColor: colors.surface,
              onRefresh: cubit.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  AppSpacing.xxxl,
                ),
                children: [
                  TasksEnterpriseHeader(
                    canManage: canManage,
                    onNewTask: () => _onNewTask(context),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  TasksKpiStrip(
                    summary: data.summary,
                    selectedFilter: data.statusFilter,
                    onFilterTap: cubit.setStatusFilter,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  TasksSearchPanel(
                    nameController: _nameController,
                    productController: _productController,
                    warehouseController: _warehouseController,
                    onNameSearch: cubit.setNameQuery,
                    onProductSearch: cubit.setProductQuery,
                    onWarehouseSearch: cubit.setWarehouseQuery,
                    activeFilterCount: data.activeFilterCount,
                    showFilters: data.showFilters,
                    onToggleFilters: cubit.toggleFilters,
                    onClearFilters: cubit.clearFilters,
                    displayCount: items.length,
                    totalCount: all.length,
                  ),
                  if (data.showFilters) ...[
                    const SizedBox(height: AppSpacing.md),
                    TasksFiltersPanel(
                      statusFilter: data.statusFilter,
                      priorityFilter: data.priorityFilter,
                      typeFilter: data.typeFilter,
                      onStatus: cubit.setStatusFilter,
                      onPriority: cubit.setPriorityFilter,
                      onType: cubit.setTypeFilter,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sectionGap),
                  TasksQueueSectionHeader(count: items.length),
                  const SizedBox(height: AppSpacing.md),
                  if (all.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: WmsEmptyStates.tasks(),
                    )
                  else ...[
                    if (items.isEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.md),
                        child: WmsEmptyStates.tasks(onClearFilters: cubit.clearFilters),
                      )
                    else
                      ...items.map(
                        (task) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: TaskEnterpriseCard(
                            task: task,
                            isManager: canManage,
                            onView: () => _openTask(context, task.id),
                            onEdit: () => _openTask(context, task.id),
                            onReassign: () => _onReassign(context, task),
                            onAction: (action) => _handleAction(
                              context,
                              cubit,
                              action,
                              task.id,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    TasksAnalyticsSection(tasks: all),
                    const SizedBox(height: AppSpacing.sectionGap),
                    TasksPerformanceSection(metrics: data.performance),
                    const SizedBox(height: AppSpacing.sectionGap),
                    TasksActivitySection(activity: data.recentActivity),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
