import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/create_task_input.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/task_assignee.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/features/tasks/domain/repositories/tasks_repository.dart';
import 'package:logisticsmobile/features/tasks/presentation/cubit/task_detail_cubit.dart';
import 'package:logisticsmobile/features/tasks/presentation/cubit/tasks_cubit.dart';
import 'package:logisticsmobile/widgets/app_button.dart';

typedef TaskReassignHandler = Future<WarehouseTask> Function(ReassignTaskInput input);

Future<void> showReassignTaskSheet(
  BuildContext context, {
  required WarehouseTask task,
  required TasksRepository repository,
  TaskReassignHandler? onReassign,
}) async {
  final warehouseId = task.warehouseId;
  if (warehouseId == null || warehouseId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Warehouse information unavailable for reassignment')),
    );
    return;
  }

  var assignees = <TaskAssignee>[];
  try {
    assignees = await repository.getAssignees(warehouseId);
  } catch (_) {
    assignees = const [];
  }
  if (!context.mounted) return;

  var saving = false;
  String? selectedId = task.assignedToId;
  if ((selectedId == null || selectedId.isEmpty) && assignees.isNotEmpty) {
    selectedId = assignees.first.id;
  }
  String? apiError;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> submit() async {
            if (selectedId == null || selectedId!.isEmpty) {
              setSheetState(() => apiError = 'Select a staff member');
              return;
            }
            if (onReassign == null) {
              setSheetState(() => apiError = 'Reassign handler unavailable');
              return;
            }

            setSheetState(() {
              saving = true;
              apiError = null;
            });

            try {
              final updated = await onReassign(
                ReassignTaskInput(assignedToId: selectedId!),
              );
              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(
                  content: Text(
                    'Task reassigned to ${updated.assignedToName ?? 'staff'}',
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: sheetContext.wms.success,
                ),
              );
            } on ApiException catch (e) {
              setSheetState(() {
                saving = false;
                apiError = ErrorMessageMapper.fromApiException(e);
              });
            } catch (_) {
              setSheetState(() {
                saving = false;
                apiError = 'Failed to reassign task';
              });
            }
          }

          final colors = WmsUiColors.of(context);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.lg,
              AppSpacing.screenPadding,
              AppSpacing.screenPadding + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Reassign Task', style: WmsDesignTokens.sectionTitle(context)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  task.title,
                  style: WmsDesignTokens.body(context).copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (assignees.isEmpty)
                  Text(
                    'No staff available for ${task.warehouseName ?? 'this warehouse'}',
                    style: WmsDesignTokens.supporting(context).copyWith(color: colors.error),
                  )
                else ...[
                  Text(
                    'Assigned Staff',
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    key: ValueKey('reassign-task-${task.id}-$selectedId'),
                    initialValue: selectedId,
                    isExpanded: true,
                    decoration: const InputDecoration(hintText: 'Select staff'),
                    items: [
                      for (final s in assignees)
                        DropdownMenuItem(value: s.id, child: Text(s.displayName)),
                    ],
                    onChanged: saving ? null : (v) => setSheetState(() => selectedId = v),
                  ),
                ],
                if (apiError != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    apiError!,
                    style: WmsDesignTokens.supporting(context).copyWith(color: colors.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        variant: AppButtonVariant.outline,
                        onPressed: saving ? null : () => Navigator.pop(sheetContext),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: 'Reassign',
                        isLoading: saving,
                        onPressed: (saving || assignees.isEmpty) ? null : submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> showReassignFromList(
  BuildContext context, {
  required WarehouseTask task,
  required TasksCubit cubit,
  required TasksRepository repository,
}) {
  return showReassignTaskSheet(
    context,
    task: task,
    repository: repository,
    onReassign: (input) => cubit.reassignTask(taskId: task.id, input: input),
  );
}

Future<void> showReassignFromDetail(
  BuildContext context, {
  required WarehouseTask task,
  required TaskDetailCubit cubit,
  required TasksRepository repository,
}) {
  return showReassignTaskSheet(
    context,
    task: task,
    repository: repository,
    onReassign: cubit.reassign,
  );
}
