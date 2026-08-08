import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/create_task_input.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/task_assignee.dart';
import 'package:logisticsmobile/features/tasks/domain/repositories/tasks_repository.dart';
import 'package:logisticsmobile/features/tasks/presentation/cubit/tasks_cubit.dart';
import 'package:logisticsmobile/widgets/app_button.dart';
import 'package:logisticsmobile/widgets/app_text_field.dart';

Future<void> showCreateTaskSheet(
  BuildContext context, {
  required TasksCubit cubit,
  required TasksRepository repository,
}) async {
  TaskFormMeta meta;
  try {
    meta = await repository.getFormMeta();
  } catch (_) {
    meta = const TaskFormMeta();
  }
  if (!context.mounted) return;

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final supplierCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  var taskType = WmsTaskTypes.createFormTypes.first;
  var priority = WmsTaskPriorities.medium;
  String? warehouseId;
  String? toWarehouseId;
  String? assignedToId;
  String? productId;
  DateTime dueDate = DateTime.now().add(const Duration(days: 1));

  TaskFormMeta metaData = meta;
  List<TaskAssignee> assignees = const [];
  var loadingAssignees = false;
  var saving = false;
  String? apiError;

  Future<void> loadAssignees(StateSetter setSheetState, String whId) async {
    setSheetState(() {
      loadingAssignees = true;
      assignedToId = null;
    });
    try {
      assignees = await repository.getAssignees(whId);
    } catch (_) {
      assignees = const [];
    } finally {
      setSheetState(() => loadingAssignees = false);
    }
  }

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
          Future<void> pickDueDate() async {
            final date = await showDatePicker(
              context: context,
              initialDate: dueDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date == null || !context.mounted) return;
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(dueDate),
            );
            if (time == null) {
              setSheetState(() => dueDate = date);
              return;
            }
            setSheetState(
              () => dueDate = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              ),
            );
          }

          Future<void> submit() async {
            setSheetState(() => apiError = null);
            if (!(formKey.currentState?.validate() ?? false)) return;
            if (warehouseId == null || warehouseId!.isEmpty) {
              setSheetState(() => apiError = 'Select a warehouse.');
              return;
            }
            if (assignedToId == null || assignedToId!.isEmpty) {
              setSheetState(() => apiError = 'Assign a staff member.');
              return;
            }
            if (WmsTaskTypes.requiresToWarehouse(taskType) &&
                (toWarehouseId == null || toWarehouseId!.isEmpty)) {
              setSheetState(() => apiError = 'Select a destination warehouse.');
              return;
            }
            if (WmsTaskTypes.requiresToWarehouse(taskType) &&
                toWarehouseId == warehouseId) {
              setSheetState(() => apiError = 'Source and destination must differ.');
              return;
            }
            if (WmsTaskTypes.requiresProduct(taskType) &&
                (productId == null || productId!.isEmpty)) {
              setSheetState(() => apiError = 'Select a product.');
              return;
            }
            if (WmsTaskTypes.requiresQuantity(taskType)) {
              final qty = num.tryParse(qtyCtrl.text.trim());
              if (qty == null || qty < 1) {
                setSheetState(() => apiError = 'Quantity must be at least 1.');
                return;
              }
            }
            if (WmsTaskTypes.requiresSupplier(taskType) &&
                supplierCtrl.text.trim().isEmpty) {
              setSheetState(() => apiError = 'Supplier is required for receive tasks.');
              return;
            }

            setSheetState(() => saving = true);
            try {
              final created = await cubit.createTask(
                CreateTaskInput(
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  taskType: taskType,
                  priority: priority,
                  warehouseId: warehouseId!,
                  toWarehouseId: toWarehouseId,
                  assignedToId: assignedToId!,
                  dueDate: dueDate,
                  relatedProductId: productId,
                  quantity: num.tryParse(qtyCtrl.text.trim()),
                  supplierName: supplierCtrl.text.trim(),
                ),
              );
              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(
                  content: Text('Task "${created.title}" created successfully'),
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
                apiError = 'Failed to create task. Please try again.';
              });
            }
          }

          final colors = WmsUiColors.of(context);
          final width = MediaQuery.sizeOf(context).width;
          final maxFormWidth = width >= WmsDesignTokens.tabletWidth ? 560.0 : width;
          final destWarehouses = metaData.warehouses
              .where((w) => w.id != warehouseId)
              .toList();

          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.lg,
              AppSpacing.screenPadding,
              AppSpacing.screenPadding + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxFormWidth),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create Task',
                                    style: WmsDesignTokens.sectionTitle(context),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Create, assign and monitor warehouse task workflows.',
                                    style: WmsDesignTokens.body(context).copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: saving ? null : () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        if (metaData.warehouses.isEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No warehouses available. Add a warehouse first.',
                            style: WmsDesignTokens.supporting(context).copyWith(
                              color: colors.error,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: titleCtrl,
                            label: 'Task Name',
                            hint: 'Enter task title',
                            enabled: !saving,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Task name is required' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: descCtrl,
                            label: 'Description',
                            hint: 'Optional details',
                            maxLines: 3,
                            enabled: !saving,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _FieldLabel(context, 'Task Type'),
                          DropdownButtonFormField<String>(
                            key: ValueKey('create-task-type-$taskType'),
                            initialValue: taskType,
                            isExpanded: true,
                            decoration: const InputDecoration(hintText: 'Select type'),
                            items: [
                              for (final t in WmsTaskTypes.createFormTypes)
                                DropdownMenuItem(value: t, child: Text(t)),
                            ],
                            onChanged: saving
                                ? null
                                : (v) {
                                    if (v == null) return;
                                    setSheetState(() {
                                      taskType = v;
                                      productId = null;
                                      toWarehouseId = null;
                                      qtyCtrl.clear();
                                      supplierCtrl.clear();
                                    });
                                  },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _FieldLabel(context, 'Priority'),
                          DropdownButtonFormField<String>(
                            key: ValueKey('create-task-priority-$priority'),
                            initialValue: priority,
                            isExpanded: true,
                            decoration: const InputDecoration(hintText: 'Select priority'),
                            items: [
                              for (final p in WmsTaskPriorities.all)
                                DropdownMenuItem(
                                  value: p,
                                  child: Text(_priorityLabel(p)),
                                ),
                            ],
                            onChanged: saving
                                ? null
                                : (v) {
                                    if (v == null) return;
                                    setSheetState(() => priority = v);
                                  },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _FieldLabel(context, 'Warehouse'),
                          DropdownButtonFormField<String>(
                            key: ValueKey('create-task-warehouse-$warehouseId'),
                            initialValue: warehouseId,
                            isExpanded: true,
                            decoration: const InputDecoration(hintText: 'Select warehouse'),
                            items: [
                              for (final w in metaData.warehouses)
                                DropdownMenuItem(value: w.id, child: Text(w.name)),
                            ],
                            onChanged: saving
                                ? null
                                : (v) {
                                    if (v == null) return;
                                    setSheetState(() {
                                      warehouseId = v;
                                      toWarehouseId = null;
                                    });
                                    loadAssignees(setSheetState, v);
                                  },
                          ),
                          if (WmsTaskTypes.requiresToWarehouse(taskType)) ...[
                            const SizedBox(height: AppSpacing.md),
                            _FieldLabel(context, 'Destination Warehouse'),
                            DropdownButtonFormField<String>(
                              key: ValueKey('create-task-to-warehouse-$toWarehouseId'),
                              initialValue: toWarehouseId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                hintText: 'Select destination',
                              ),
                              items: [
                                for (final w in destWarehouses)
                                  DropdownMenuItem(value: w.id, child: Text(w.name)),
                              ],
                              onChanged: saving
                                  ? null
                                  : (v) => setSheetState(() => toWarehouseId = v),
                            ),
                          ],
                          if (WmsTaskTypes.requiresProduct(taskType)) ...[
                            const SizedBox(height: AppSpacing.md),
                            _FieldLabel(context, 'Product'),
                            DropdownButtonFormField<String>(
                              key: ValueKey('create-task-product-$productId'),
                              initialValue: productId,
                              isExpanded: true,
                              decoration: const InputDecoration(hintText: 'Select product'),
                              items: [
                                for (final p in metaData.products)
                                  DropdownMenuItem(
                                    value: p.id,
                                    child: Text(
                                      p.sku != null ? '${p.name} (${p.sku})' : p.name,
                                    ),
                                  ),
                              ],
                              onChanged: saving
                                  ? null
                                  : (v) => setSheetState(() => productId = v),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: qtyCtrl,
                              label: 'Quantity',
                              keyboardType: TextInputType.number,
                              enabled: !saving,
                            ),
                          ],
                          if (WmsTaskTypes.requiresSupplier(taskType)) ...[
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: supplierCtrl,
                              label: 'Supplier',
                              enabled: !saving,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          _FieldLabel(context, 'Assigned Staff'),
                          if (warehouseId == null)
                            Text(
                              'Select a warehouse first',
                              style: WmsDesignTokens.supporting(context).copyWith(
                                color: colors.textSecondary,
                              ),
                            )
                          else if (loadingAssignees)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (assignees.isEmpty)
                            Text(
                              'No staff assigned to this warehouse',
                              style: WmsDesignTokens.supporting(context).copyWith(
                                color: colors.error,
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              key: ValueKey('create-task-assignee-$assignedToId'),
                              initialValue: assignedToId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                hintText: 'Select staff member',
                              ),
                              items: [
                                for (final s in assignees)
                                  DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.displayName),
                                  ),
                              ],
                              onChanged: saving
                                  ? null
                                  : (v) => setSheetState(() => assignedToId = v),
                            ),
                          const SizedBox(height: AppSpacing.md),
                          _FieldLabel(context, 'Due Date'),
                          OutlinedButton.icon(
                            onPressed: saving ? null : pickDueDate,
                            icon: const Icon(Icons.event_outlined),
                            label: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(WmsFormatters.dateTimeShort(dueDate)),
                            ),
                          ),
                          if (apiError != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              apiError!,
                              style: WmsDesignTokens.supporting(context).copyWith(
                                color: colors.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'Cancel',
                                  variant: AppButtonVariant.outline,
                                  onPressed: saving
                                      ? null
                                      : () => Navigator.pop(sheetContext),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: AppButton(
                                  label: 'Create Task',
                                  isLoading: saving,
                                  onPressed: saving ? null : submit,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  titleCtrl.dispose();
  descCtrl.dispose();
  qtyCtrl.dispose();
  supplierCtrl.dispose();
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.context, this.text);

  final BuildContext context;

  /// Theme-resolved palette for this section tree.
  ///
  /// Exposed as a getter so every section method reads the live theme rather
  /// than a colour captured when the holder was constructed.
  WmsUiColors get colors => WmsUiColors.of(context);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: WmsDesignTokens.supportingDense(context).copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _priorityLabel(String priority) {
  if (priority.isEmpty) return priority;
  return priority[0].toUpperCase() + priority.substring(1);
}
