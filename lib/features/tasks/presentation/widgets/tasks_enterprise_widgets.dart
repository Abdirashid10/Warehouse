import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/core/utils/task_workflow_utils.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/features/tasks/presentation/cubit/tasks_cubit.dart';
import 'package:logisticsmobile/widgets/wms/wms_badges.dart';

class TasksEnterpriseHeader extends StatelessWidget {
  const TasksEnterpriseHeader({
    super.key,
    required this.canManage,
    required this.onNewTask,
  });

  final bool canManage;
  final VoidCallback onNewTask;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assignment_outlined, size: WmsIconSizes.status, color: colors.primary),
            const SizedBox(width: WmsIconSizes.iconLabelGap),
            Text(
              'OPERATIONS',
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            Icon(Icons.chevron_right, size: WmsIconSizes.listLeading, color: colors.textTertiary),
            Text(
              'TASKS',
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tasks',
          style: WmsDesignTokens.pageTitle(context).copyWith(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Create, assign and monitor warehouse task workflows.',
          style: WmsDesignTokens.body(context).copyWith(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        if (canManage) ...[
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onNewTask,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              icon: const Icon(Icons.add, size: WmsIconSizes.actionButton),
              label: Text(
                'New Task',
                style: WmsDesignTokens.body(context).copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class TasksKpiStrip extends StatelessWidget {
  const TasksKpiStrip({
    super.key,
    required this.summary,
    required this.selectedFilter,
    required this.onFilterTap,
  });

  final TasksSummary summary;
  final String? selectedFilter;
  final ValueChanged<String?> onFilterTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiDef('Total Tasks', '${summary.total}', Icons.list_alt, null, null),
      _KpiDef(
        'Awaiting',
        '${summary.awaiting}',
        Icons.schedule_outlined,
        WmsTaskStatuses.pending,
        TaskKpiFilter.awaiting,
      ),
      _KpiDef(
        'Accepted',
        '${summary.accepted}',
        Icons.thumb_up_alt_outlined,
        WmsTaskStatuses.accepted,
        TaskKpiFilter.accepted,
      ),
      _KpiDef(
        'In Progress',
        '${summary.inProgress}',
        Icons.play_circle_outline,
        WmsTaskStatuses.inProgress,
        TaskKpiFilter.inProgress,
      ),
      _KpiDef(
        'Completed',
        '${summary.completed}',
        Icons.check_circle_outline,
        WmsTaskStatuses.completed,
        TaskKpiFilter.completed,
      ),
      _KpiDef(
        'Rejected',
        '${summary.rejected}',
        Icons.cancel_outlined,
        WmsTaskStatuses.rejected,
        TaskKpiFilter.rejected,
      ),
      _KpiDef(
        'Overdue',
        '${summary.overdue}',
        Icons.event_busy_outlined,
        WmsTaskStatuses.overdue,
        TaskKpiFilter.overdue,
      ),
    ];

    final width = MediaQuery.sizeOf(context).width;
    final columns = MobileUi.kpiColumns(width);
    final tileHeight = MobileUi.kpiTileHeight(width);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        mainAxisExtent: tileHeight,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        final isSelected =
            item.filterKey != null && selectedFilter == item.filterKey;
        return _KpiCard(
          item: item,
          isSelected: isSelected,
          onTap: () {
            if (item.filterKey == null) {
              onFilterTap(null);
            } else {
              onFilterTap(isSelected ? null : item.filterKey);
            }
          },
        );
      },
    );
  }
}

class _KpiDef {
  const _KpiDef(
    this.label,
    this.value,
    this.icon,
    this.status,
    this.filterKey,
  );

  final String label;
  final String value;
  final IconData icon;
  final String? status;
  final String? filterKey;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _KpiDef item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final accent = item.status != null
        ? WmsTaskStatusBadge.foregroundFor(item.status!, context)
        : colors.primary;
    final bg = item.status != null
        ? WmsTaskStatusBadge.backgroundFor(item.status!, context)
        : colors.primaryMuted;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: isSelected ? accent : colors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(
                  item.icon,
                  size: WmsIconSizes.listLeading,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          WmsDesignTokens.supportingDense(context).copyWith(
                        color: colors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.body(context).copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TasksSearchPanel extends StatelessWidget {
  const TasksSearchPanel({
    super.key,
    required this.nameController,
    required this.productController,
    required this.warehouseController,
    required this.onNameSearch,
    required this.onProductSearch,
    required this.onWarehouseSearch,
    required this.activeFilterCount,
    required this.showFilters,
    required this.onToggleFilters,
    required this.onClearFilters,
    required this.displayCount,
    required this.totalCount,
  });

  final TextEditingController nameController;
  final TextEditingController productController;
  final TextEditingController warehouseController;
  final ValueChanged<String> onNameSearch;
  final ValueChanged<String> onProductSearch;
  final ValueChanged<String> onWarehouseSearch;
  final int activeFilterCount;
  final bool showFilters;
  final VoidCallback onToggleFilters;
  final VoidCallback onClearFilters;
  final int displayCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Search & Filters',
          style: WmsDesignTokens.sectionTitle(context).copyWith(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SearchField(
          controller: nameController,
          onChanged: onNameSearch,
          hint: 'Search by Task Name',
          icon: Icons.assignment_outlined,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SearchField(
          controller: productController,
          onChanged: onProductSearch,
          hint: 'Search by Product',
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SearchField(
          controller: warehouseController,
          onChanged: onWarehouseSearch,
          hint: 'Search by Warehouse',
          icon: Icons.warehouse_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onToggleFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: showFilters || activeFilterCount > 0
                      ? colors.primary
                      : colors.textSecondary,
                  side: BorderSide(
                    color: showFilters || activeFilterCount > 0
                        ? colors.primary.withValues(alpha: 0.5)
                        : colors.border,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.filter_list, size: WmsIconSizes.actionButton),
                label: Text(
                  activeFilterCount > 0
                      ? 'Filters ($activeFilterCount)'
                      : 'Filters',
                ),
              ),
            ),
            if (activeFilterCount > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                onPressed: onClearFilters,
                icon: Icon(Icons.clear, color: colors.textTertiary),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$displayCount of $totalCount tasks',
          style: WmsDesignTokens.supporting(context).copyWith(
            color: colors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.hint,
    required this.icon,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: WmsDesignTokens.body(context).copyWith(
        color: colors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textTertiary, fontSize: 14),
        prefixIcon: Icon(icon, color: colors.textTertiary, size: WmsIconSizes.search),
        filled: true,
        fillColor: colors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class TasksFiltersPanel extends StatelessWidget {
  const TasksFiltersPanel({
    super.key,
    required this.statusFilter,
    required this.priorityFilter,
    required this.typeFilter,
    required this.onStatus,
    required this.onPriority,
    required this.onType,
  });

  final String? statusFilter;
  final String? priorityFilter;
  final String? typeFilter;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String?> onPriority;
  final ValueChanged<String?> onType;

  static const statusFilters = [
    (null, 'All'),
    (WmsTaskStatuses.pending, 'Awaiting'),
    (WmsTaskStatuses.accepted, 'Accepted'),
    (WmsTaskStatuses.inProgress, 'In Progress'),
    (WmsTaskStatuses.completed, 'Completed'),
    (WmsTaskStatuses.overdue, 'Overdue'),
    (WmsTaskStatuses.rejected, 'Rejected'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterGroup(
            label: 'Status',
            children: [
              for (final (value, label) in statusFilters)
                FilterChip(
                  label: Text(label),
                  selected: statusFilter == value,
                  onSelected: (_) => onStatus(value),
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _FilterGroup(
            label: 'Priority',
            children: [
              FilterChip(
                label: const Text('All'),
                selected: priorityFilter == null,
                onSelected: (_) => onPriority(null),
                showCheckmark: false,
              ),
              for (final p in WmsTaskPriorities.all)
                FilterChip(
                  label: Text(WmsTaskPriorityBadge.labelFor(p)),
                  selected: priorityFilter == p,
                  onSelected: (_) => onPriority(p),
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _FilterGroup(
            label: 'Type',
            children: [
              FilterChip(
                label: const Text('All'),
                selected: typeFilter == null,
                onSelected: (_) => onType(null),
                showCheckmark: false,
              ),
              for (final t in WmsTaskTypes.filterTypes)
                FilterChip(
                  label: Text(t),
                  selected: typeFilter == t,
                  onSelected: (_) => onType(t),
                  showCheckmark: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WmsDesignTokens.supportingDense(context).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: children,
        ),
      ],
    );
  }
}

class TaskEnterpriseCard extends StatelessWidget {
  const TaskEnterpriseCard({
    super.key,
    required this.task,
    required this.isManager,
    required this.onView,
    required this.onAction,
    required this.onEdit,
    required this.onReassign,
  });

  final WarehouseTask task;
  final bool isManager;
  final VoidCallback onView;
  final void Function(TaskWorkflowAction action) onAction;
  final VoidCallback onEdit;
  final VoidCallback onReassign;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final displayStatus = task.effectiveStatus;
    final accent = WmsTaskStatusBadge.foregroundFor(displayStatus, context);
    final cardActions = TaskWorkflowUtils.getCardActions(
      task,
      isManager: isManager,
    );

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: WmsDesignTokens.body(context).copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.taskType,
                          style: WmsDesignTokens.supporting(context).copyWith(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      WmsTaskStatusBadge(
                        status: displayStatus,
                        compact: true,
                        useFullLabel: true,
                      ),
                      const SizedBox(height: 4),
                      WmsTaskPriorityBadge(
                        priority: task.priority,
                        compact: true,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (task.productName != null)
                _MetaRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Product',
                  value: task.productName!,
                ),
              if (task.warehouseName != null)
                _MetaRow(
                  icon: Icons.warehouse_outlined,
                  label: 'Warehouse',
                  value: task.warehouseName!,
                ),
              if (task.assignedToName != null)
                _MetaRow(
                  icon: Icons.person_outline,
                  label: 'Assigned Staff',
                  value: task.assignedToName!,
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (task.dueDate != null)
                    Expanded(
                      child: _DateChip(
                        icon: task.isOverdue
                            ? Icons.event_busy_outlined
                            : Icons.event_outlined,
                        label: 'Due',
                        value: WmsFormatters.relativeTime(task.dueDate),
                        highlight: task.isOverdue,
                      ),
                    ),
                  if (task.dueDate != null && task.createdAt != null)
                    const SizedBox(width: AppSpacing.sm),
                  if (task.createdAt != null)
                    Expanded(
                      child: _DateChip(
                        icon: Icons.calendar_today_outlined,
                        label: 'Created',
                        value: WmsFormatters.relativeTime(task.createdAt),
                      ),
                    ),
                ],
              ),
              if (cardActions.isNotEmpty ||
                  isManager ||
                  displayStatus == WmsTaskStatuses.completed) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (displayStatus == WmsTaskStatuses.completed ||
                        cardActions.isEmpty)
                      _ActionChip(
                        icon: Icons.visibility_outlined,
                        label: 'View Details',
                        onTap: onView,
                      )
                    else
                      for (final action in cardActions)
                        _ActionChip(
                          icon: _iconForAction(action),
                          label: action.label,
                          destructive: action.destructive,
                          onTap: () => onAction(action),
                        ),
                    if (isManager) ...[
                      _ActionChip(
                        icon: Icons.swap_horiz,
                        label: 'Reassign',
                        onTap: onReassign,
                      ),
                      _ActionChip(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        onTap: onEdit,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForAction(TaskWorkflowAction action) {
    return switch (action.targetStatus) {
      WmsTaskStatuses.accepted => Icons.thumb_up_alt_outlined,
      WmsTaskStatuses.inProgress => Icons.play_arrow_rounded,
      WmsTaskStatuses.waitingConfirmation => Icons.send_outlined,
      WmsTaskStatuses.completed => Icons.check_circle_outline,
      WmsTaskStatuses.rejected => Icons.cancel_outlined,
      _ => Icons.touch_app_outlined,
    };
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: WmsIconSizes.status, color: colors.textTertiary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: WmsDesignTokens.supportingDense(context).copyWith(
              color: colors.textTertiary,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supporting(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final fg = highlight ? colors.error : colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: highlight ? colors.error.withValues(alpha: 0.3) : colors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: WmsIconSizes.status, color: fg),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '$label $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: fg,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final fg = destructive ? colors.error : colors.textSecondary;
    return Material(
      color: colors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        side: BorderSide(
          color: destructive
              ? colors.error.withValues(alpha: 0.3)
              : colors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: WmsIconSizes.status, color: fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: WmsDesignTokens.supportingDense(context).copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TasksQueueSectionHeader extends StatelessWidget {
  const TasksQueueSectionHeader({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Row(
      children: [
        Text(
          'Enterprise Task Queue',
          style: WmsDesignTokens.sectionTitle(context).copyWith(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colors.primaryMuted,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: WmsDesignTokens.supportingDense(context).copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
