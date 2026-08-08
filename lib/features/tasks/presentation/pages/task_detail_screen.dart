import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/task_workflow_utils.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/features/tasks/presentation/cubit/task_detail_cubit.dart';
import 'package:logisticsmobile/features/tasks/presentation/widgets/reassign_task_sheet.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_badges.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen>
    with StaffScopeInitMixin {
  TaskDetailCubit? _cubit;
  StaffRepositories? _repos;

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    _repos = repositories;
    _cubit = TaskDetailCubit(repositories.tasks)..load(widget.taskId);
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  bool _canManage(BuildContext context) {
    final role = context.read<AuthBloc>().state.user?.role;
    return role?.isAdmin == true || role?.isSupervisor == true;
  }

  Future<void> _handleAction(
    BuildContext context,
    TaskDetailCubit cubit,
    TaskWorkflowAction action,
  ) async {
    final colors = WmsUiColors.of(context);

    if (action.destructive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colors.surface,
          title: Text('${action.label}?'),
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
      await cubit.updateStatus(action.targetStatus);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      return const Scaffold(body: StaffScopeLoadingBody());
    }

    final canManage = _canManage(context);
    final colors = WmsUiColors.of(context);

    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          foregroundColor: colors.textPrimary,
          elevation: 0,
          title: Text(
            'Task Details',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: BlocBuilder<TaskDetailCubit, ResourceState<WarehouseTask>>(
          builder: (context, state) {
            if (state.isLoading && state.data == null) {
              return const WmsLoadingState(message: 'Loading task…');
            }
            if (state.isFailure && state.data == null) {
              return WmsErrorState(
                message: state.message ?? 'Failed to load task',
                onRetry: () => cubit.load(widget.taskId),
              );
            }
            final task = state.data;
            if (task == null) return const SizedBox.shrink();

            final displayStatus = task.effectiveStatus;
            final actions = TaskWorkflowUtils.getActions(
              task,
              isManager: canManage,
            );

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                AppCard(
                  elevated: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: WmsDesignTokens.sectionTitle(context).copyWith(
                          color: colors.textPrimary,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        task.taskType,
                        style: WmsDesignTokens.supporting(context).copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          WmsTaskStatusBadge(
                            status: displayStatus,
                            useFullLabel: true,
                          ),
                          WmsTaskPriorityBadge(priority: task.priority),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailRow('Product', task.productName),
                _DetailRow('Warehouse', task.warehouseName),
                _DetailRow('Assigned Staff', task.assignedToName),
                _DetailRow('Assigned By', task.assignedByName),
                _DetailRow(
                  'Due Date',
                  task.dueDate != null
                      ? WmsFormatters.relativeTime(task.dueDate)
                      : null,
                ),
                _DetailRow(
                  'Created',
                  task.createdAt != null
                      ? WmsFormatters.relativeTime(task.createdAt)
                      : null,
                ),
                if (task.quantity != null)
                  _DetailRow('Quantity', '${task.quantity}'),
                if (task.description != null &&
                    task.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Description',
                    style: WmsDesignTokens.sectionTitle(context).copyWith(
                      fontSize: 16,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    elevated: true,
                    child: Text(
                      task.description!,
                      style: WmsDesignTokens.body(context).copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
                if (task.statusHistory.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  Text(
                    'Workflow Activity',
                    style: WmsDesignTokens.sectionTitle(context).copyWith(
                      fontSize: 16,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    elevated: true,
                    child: Column(
                      children: [
                        for (var i = 0; i < task.statusHistory.length; i++) ...[
                          if (i > 0) const Divider(height: AppSpacing.lg),
                          _HistoryRow(entry: task.statusHistory[i]),
                        ],
                      ],
                    ),
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final action in actions)
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: action.destructive
                                ? colors.error
                                : colors.primary,
                          ),
                          onPressed: state.isLoading
                              ? null
                              : () => _handleAction(context, cubit, action),
                          child: Text(action.label),
                        ),
                    ],
                  ),
                ],
                if (canManage &&
                    task.status != WmsTaskStatuses.completed) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: state.isLoading || _repos == null
                        ? null
                        : () => showReassignFromDetail(
                              context,
                              task: task,
                              cubit: cubit,
                              repository: _repos!.tasks,
                            ),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Reassign'),
                  ),
                ] else if (actions.isEmpty &&
                    displayStatus == WmsTaskStatuses.completed) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppCard(
                    elevated: true,
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: colors.success),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Task completed',
                          style: WmsDesignTokens.body(context).copyWith(
                            color: colors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = WmsUiColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        elevated: true,
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: WmsDesignTokens.supporting(context).copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value!,
                style: WmsDesignTokens.body(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final TaskStatusHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WmsTaskStatusBadge(status: entry.status, compact: true),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.changedByName != null)
                Text(
                  entry.changedByName!,
                  style: WmsDesignTokens.supporting(context).copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              if (entry.changedAt != null)
                Text(
                  WmsFormatters.relativeTime(entry.changedAt),
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              if (entry.note != null && entry.note!.isNotEmpty)
                Text(
                  entry.note!,
                  style: WmsDesignTokens.supporting(context).copyWith(
                    color: colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
