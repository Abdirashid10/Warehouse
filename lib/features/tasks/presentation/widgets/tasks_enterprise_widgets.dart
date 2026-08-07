import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/widgets/wms/wms_metric_pill.dart';
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

    final colors = WmsUiColors.of(context);

    // Seven tall cards in a two-column grid ran four rows — roughly 600dp
    // before the first task. The same seven now scroll in one ~78dp strip.
    return WmsMetricPillBar(
      // The hosting list already applies the screen inset.
      padding: EdgeInsets.zero,
      metrics: [
        for (final item in items)
          () {
            final isSelected =
                item.filterKey != null && selectedFilter == item.filterKey;
            return WmsMetricPillData(
              label: item.label,
              value: item.value,
              icon: item.icon,
              color: item.status == null
                  ? colors.primary
                  : WmsTaskStatusBadge.foregroundFor(item.status!, context),
              selected: isSelected,
              onTap: () => onFilterTap(
                item.filterKey == null || isSelected ? null : item.filterKey,
              ),
            );
          }(),
      ],
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

    // The first workflow action is the one the operator almost always wants.
    // It gets a real button; everything else tucks into the overflow menu
    // rather than wrapping five chips across two or three rows.
    final primary = cardActions.isEmpty ? null : cardActions.first;
    final secondary = cardActions.skip(1).toList();

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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 3.5,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Title only. Packing the type and priority in here as well
                  // left too little room at 320dp once the status badge and
                  // overflow menu had taken theirs, and the priority badge
                  // cannot shrink.
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.body(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  WmsTaskStatusBadge(status: displayStatus, compact: true),
                  _TaskActionsMenu(
                    actions: secondary,
                    isManager: isManager,
                    onView: onView,
                    onEdit: onEdit,
                    onReassign: onReassign,
                    onAction: onAction,
                    iconForAction: _iconForAction,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Divider(
                height: 1,
                thickness: 0.8,
                color: colors.border.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Type and priority get their own full-width line, where the
              // badge always has room.
              Row(
                children: [
                  WmsTaskPriorityBadge(priority: task.priority, compact: true),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.taskType,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: colors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Icons carry the meaning, so the "Product:" / "Warehouse:"
              // prefixes are gone — they cost a third of each line.
              if (task.productName != null)
                _MetaRow(
                  icon: Icons.inventory_2_outlined,
                  value: task.productName!,
                ),
              if (task.warehouseName != null)
                _MetaRow(
                  icon: Icons.warehouse_outlined,
                  value: task.warehouseName!,
                ),
              if (task.assignedToName != null)
                _MetaRow(
                  icon: Icons.person_outline,
                  value: task.assignedToName!,
                ),
              if (task.dueDate != null || task.createdAt != null) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (task.dueDate != null)
                      Flexible(
                        child: _InlineDate(
                          icon: task.isOverdue
                              ? Icons.event_busy_outlined
                              : Icons.event_outlined,
                          label: 'Due',
                          value: WmsFormatters.relativeTime(task.dueDate),
                          highlight: task.isOverdue,
                        ),
                      ),
                    if (task.dueDate != null && task.createdAt != null)
                      const SizedBox(width: AppSpacing.md),
                    if (task.createdAt != null)
                      Flexible(
                        child: _InlineDate(
                          icon: Icons.calendar_today_outlined,
                          label: 'Created',
                          value: WmsFormatters.relativeTime(task.createdAt),
                        ),
                      ),
                  ],
                ),
              ],
              if (primary != null) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 38,
                  child: FilledButton(
                    onPressed: () => onAction(primary),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          primary.destructive ? colors.error : colors.primary,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconForAction(primary),
                          size: 17,
                          color: const Color(0xFFFFFFFF),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            primary.label,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: WmsDesignTokens.supportingDense(context)
                                .copyWith(
                              // Explicit white — the themed label color
                              // would otherwise beat foregroundColor.
                              color: const Color(0xFFFFFFFF),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
  const _MetaRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colors.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact inline date — icon, label and relative value on one line.
class _InlineDate extends StatelessWidget {
  const _InlineDate({
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
    final tone = highlight ? colors.error : colors.textSecondary;

    // Returns a plain Row — Flexible must be applied by the parent Row at the
    // call site, since a ParentDataWidget has to be a direct child of its Flex.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: tone),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$label $value',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.supportingDense(context).copyWith(
              color: tone,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              fontSize: 11.5,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// Overflow menu holding every action except the primary one.
class _TaskActionsMenu extends StatelessWidget {
  const _TaskActionsMenu({
    required this.actions,
    required this.isManager,
    required this.onView,
    required this.onEdit,
    required this.onReassign,
    required this.onAction,
    required this.iconForAction,
  });

  final List<TaskWorkflowAction> actions;
  final bool isManager;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onReassign;
  final void Function(TaskWorkflowAction action) onAction;
  final IconData Function(TaskWorkflowAction action) iconForAction;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    return PopupMenuButton<VoidCallback>(
      onSelected: (action) => action(),
      tooltip: 'Task actions',
      position: PopupMenuPosition.under,
      icon: Icon(Icons.more_vert_rounded, size: 20, color: colors.textSecondary),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 190),
      splashRadius: 20,
      itemBuilder: (context) => [
        _item(context, Icons.visibility_outlined, 'View details', onView),
        for (final action in actions)
          _item(
            context,
            iconForAction(action),
            action.label,
            () => onAction(action),
            destructive: action.destructive,
          ),
        if (isManager) ...[
          const PopupMenuDivider(height: 1),
          _item(context, Icons.swap_horiz_rounded, 'Reassign', onReassign),
          _item(context, Icons.edit_outlined, 'Edit task', onEdit),
        ],
      ],
    );
  }

  PopupMenuItem<VoidCallback> _item(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback action, {
    bool destructive = false,
  }) {
    final colors = WmsUiColors.of(context);
    final color = destructive ? colors.error : colors.textPrimary;

    return PopupMenuItem<VoidCallback>(
      value: action,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.body(context).copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
