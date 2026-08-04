import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';

/// Client-side mirror of web `taskOverdue.js` and `taskPermissions.js`.
abstract final class TaskWorkflowUtils {
  static bool isTaskOverdue(WarehouseTask task, [DateTime? now]) {
    final current = now ?? DateTime.now();
    final status = task.status;
    if (status == WmsTaskStatuses.completed ||
        status == WmsTaskStatuses.rejected) {
      return false;
    }
    final due = task.dueDate;
    if (due == null) return false;
    return due.isBefore(current);
  }

  static String workflowBucket(WarehouseTask task) {
    if (task.workflowStatus != null && task.workflowStatus!.isNotEmpty) {
      return task.workflowStatus!;
    }
    final status = task.status;
    if (status != WmsTaskStatuses.overdue) return status;

    for (final entry in task.statusHistory.reversed) {
      if (entry.status.isNotEmpty && entry.status != WmsTaskStatuses.overdue) {
        return entry.status;
      }
    }
    return WmsTaskStatuses.pending;
  }

  static String displayStatus(WarehouseTask task) {
    if (isTaskOverdue(task) &&
        task.status != WmsTaskStatuses.completed &&
        task.status != WmsTaskStatuses.rejected) {
      return WmsTaskStatuses.overdue;
    }
    return workflowBucket(task);
  }

  static TasksSummary summarize(List<WarehouseTask> tasks, [DateTime? now]) {
    var awaiting = 0;
    var accepted = 0;
    var inProgress = 0;
    var completed = 0;
    var rejected = 0;
    var overdue = 0;

    for (final task in tasks) {
      final bucket = workflowBucket(task);
      switch (bucket) {
        case WmsTaskStatuses.pending:
          awaiting++;
        case WmsTaskStatuses.accepted:
          accepted++;
        case WmsTaskStatuses.inProgress:
        case WmsTaskStatuses.waitingConfirmation:
          inProgress++;
        case WmsTaskStatuses.completed:
          completed++;
        case WmsTaskStatuses.rejected:
          rejected++;
      }
      if (isTaskOverdue(task, now)) overdue++;
    }

    return TasksSummary(
      total: tasks.length,
      awaiting: awaiting,
      accepted: accepted,
      inProgress: inProgress,
      completed: completed,
      rejected: rejected,
      overdue: overdue,
    );
  }

  static List<WarehouseTask> filterByStatus(
    List<WarehouseTask> tasks,
    String? statusFilter, [
    DateTime? now,
  ]) {
    if (statusFilter == null || statusFilter.isEmpty) return tasks;

    if (statusFilter == WmsTaskStatuses.overdue) {
      return tasks.where((t) => isTaskOverdue(t, now)).toList();
    }
    if (statusFilter == WmsTaskStatuses.inProgress) {
      return tasks
          .where(
            (t) =>
                workflowBucket(t) == WmsTaskStatuses.inProgress ||
                workflowBucket(t) == WmsTaskStatuses.waitingConfirmation,
          )
          .toList();
    }
    if (statusFilter == WmsTaskStatuses.pending) {
      return tasks
          .where((t) => workflowBucket(t) == WmsTaskStatuses.pending)
          .toList();
    }
    return tasks.where((t) => workflowBucket(t) == statusFilter).toList();
  }

  static List<TaskWorkflowAction> getActions(
    WarehouseTask task, {
    required bool isManager,
  }) {
    final bucket = workflowBucket(task);
    if (isManager && bucket == WmsTaskStatuses.waitingConfirmation) {
      return const [
        TaskWorkflowAction(
          label: 'Approve',
          targetStatus: WmsTaskStatuses.completed,
        ),
        TaskWorkflowAction(
          label: 'Reject',
          targetStatus: WmsTaskStatuses.rejected,
          destructive: true,
        ),
      ];
    }

    final targets = isManager
        ? _managerStatusActions(bucket)
        : _staffStatusActions(bucket);

    return targets.map((status) => TaskWorkflowAction.fromStatus(status)).toList();
  }

  static List<TaskWorkflowAction> getCardActions(
    WarehouseTask task, {
    required bool isManager,
  }) {
    final bucket = workflowBucket(task);
    final actions = <TaskWorkflowAction>[];

    switch (bucket) {
      case WmsTaskStatuses.pending:
        actions.addAll([
          TaskWorkflowAction.fromStatus(WmsTaskStatuses.accepted),
          TaskWorkflowAction.fromStatus(WmsTaskStatuses.rejected),
        ]);
      case WmsTaskStatuses.accepted:
        actions.add(TaskWorkflowAction.fromStatus(WmsTaskStatuses.inProgress));
      case WmsTaskStatuses.inProgress:
        if (isManager) {
          actions.add(
            const TaskWorkflowAction(
              label: 'Submit for Approval',
              targetStatus: WmsTaskStatuses.waitingConfirmation,
            ),
          );
          actions.add(TaskWorkflowAction.fromStatus(WmsTaskStatuses.completed));
        } else {
          actions.add(TaskWorkflowAction.fromStatus(WmsTaskStatuses.completed));
        }
      case WmsTaskStatuses.waitingConfirmation:
        if (isManager) {
          actions.add(
            const TaskWorkflowAction(
              label: 'Approve',
              targetStatus: WmsTaskStatuses.completed,
            ),
          );
          actions.add(
            const TaskWorkflowAction(
              label: 'Reject',
              targetStatus: WmsTaskStatuses.rejected,
              destructive: true,
            ),
          );
        }
      case WmsTaskStatuses.completed:
      case WmsTaskStatuses.rejected:
        break;
      case WmsTaskStatuses.overdue:
        actions.add(TaskWorkflowAction.fromStatus(WmsTaskStatuses.accepted));
        actions.add(TaskWorkflowAction.fromStatus(WmsTaskStatuses.inProgress));
    }

    if (isManager && bucket != WmsTaskStatuses.completed) {
      actions.add(const TaskWorkflowAction(
        label: 'Cancel',
        targetStatus: WmsTaskStatuses.rejected,
        iconName: 'cancel',
        destructive: true,
      ));
    }

    return actions.take(3).toList();
  }

  static List<String> _staffStatusActions(String status) {
    switch (status) {
      case WmsTaskStatuses.pending:
        return [WmsTaskStatuses.accepted, WmsTaskStatuses.rejected];
      case WmsTaskStatuses.accepted:
        return [WmsTaskStatuses.inProgress];
      case WmsTaskStatuses.inProgress:
        return [WmsTaskStatuses.completed];
      case WmsTaskStatuses.overdue:
        return [WmsTaskStatuses.accepted, WmsTaskStatuses.inProgress];
      default:
        return [];
    }
  }

  static List<String> _managerStatusActions(String status) {
    switch (status) {
      case WmsTaskStatuses.pending:
        return [
          WmsTaskStatuses.accepted,
          WmsTaskStatuses.rejected,
        ];
      case WmsTaskStatuses.accepted:
        return [WmsTaskStatuses.inProgress, WmsTaskStatuses.rejected];
      case WmsTaskStatuses.inProgress:
        return [
          WmsTaskStatuses.waitingConfirmation,
          WmsTaskStatuses.completed,
        ];
      case WmsTaskStatuses.waitingConfirmation:
        return [WmsTaskStatuses.completed, WmsTaskStatuses.inProgress];
      case WmsTaskStatuses.overdue:
        return [
          WmsTaskStatuses.accepted,
          WmsTaskStatuses.inProgress,
          WmsTaskStatuses.rejected,
        ];
      case WmsTaskStatuses.rejected:
        return [WmsTaskStatuses.pending];
      default:
        return [];
    }
  }

  static TaskPerformanceMetrics performanceMetrics(List<WarehouseTask> tasks) {
    if (tasks.isEmpty) {
      return const TaskPerformanceMetrics(
        completionRate: 0,
        averageCompletionHours: 0,
        overduePercentage: 0,
      );
    }

    final completed =
        tasks.where((t) => workflowBucket(t) == WmsTaskStatuses.completed);
    final completionRate =
        ((completed.length / tasks.length) * 100).round().clamp(0, 100);

    var totalHours = 0.0;
    var completedWithDuration = 0;
    for (final task in completed) {
      final start = task.createdAt;
      final end = task.completedAt ?? task.updatedAt;
      if (start != null && end != null) {
        totalHours += end.difference(start).inMinutes / 60.0;
        completedWithDuration++;
      }
    }
    final avgHours = completedWithDuration == 0
        ? 0.0
        : totalHours / completedWithDuration;

    final overdueCount = tasks.where(isTaskOverdue).length;
    final overduePct =
        ((overdueCount / tasks.length) * 100).round().clamp(0, 100);

    final warehouseCounts = <String, int>{};
    for (final task in tasks) {
      final name = task.warehouseName?.trim();
      if (name == null || name.isEmpty) continue;
      warehouseCounts[name] = (warehouseCounts[name] ?? 0) + 1;
    }
    String? mostActiveWarehouse;
    var maxCount = 0;
    for (final entry in warehouseCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostActiveWarehouse = entry.key;
      }
    }

    return TaskPerformanceMetrics(
      completionRate: completionRate,
      averageCompletionHours: avgHours,
      overduePercentage: overduePct,
      mostActiveWarehouse: mostActiveWarehouse,
    );
  }

  static List<TaskActivityItem> recentActivity(
    List<WarehouseTask> tasks, {
    int limit = 15,
  }) {
    final items = <TaskActivityItem>[];

    for (final task in tasks) {
      if (task.createdAt != null) {
        items.add(
          TaskActivityItem(
            type: TaskActivityType.created,
            taskTitle: task.title,
            actorName: task.assignedByName ?? task.createdByName,
            timestamp: task.createdAt!,
          ),
        );
      }

      for (final entry in task.statusHistory) {
        final type = _activityTypeFor(entry);
        if (type == null || entry.changedAt == null) continue;
        items.add(
          TaskActivityItem(
            type: type,
            taskTitle: task.title,
            actorName: entry.changedByName,
            timestamp: entry.changedAt!,
            note: entry.note,
          ),
        );
      }
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items.take(limit).toList();
  }

  static TaskActivityType? _activityTypeFor(TaskStatusHistoryEntry entry) {
    final action = entry.action?.toLowerCase() ?? '';
    if (action.contains('assign')) return TaskActivityType.assigned;
    if (action.contains('approv')) return TaskActivityType.approved;

    switch (entry.status) {
      case WmsTaskStatuses.pending:
        return TaskActivityType.created;
      case WmsTaskStatuses.accepted:
        return TaskActivityType.assigned;
      case WmsTaskStatuses.inProgress:
        return TaskActivityType.started;
      case WmsTaskStatuses.completed:
        return TaskActivityType.completed;
      case WmsTaskStatuses.waitingConfirmation:
        return TaskActivityType.approved;
      default:
        return null;
    }
  }
}

class TasksSummary {
  const TasksSummary({
    required this.total,
    required this.awaiting,
    required this.accepted,
    required this.inProgress,
    required this.completed,
    required this.rejected,
    required this.overdue,
  });

  final int total;
  final int awaiting;
  final int accepted;
  final int inProgress;
  final int completed;
  final int rejected;
  final int overdue;
}

class TaskPerformanceMetrics {
  const TaskPerformanceMetrics({
    required this.completionRate,
    required this.averageCompletionHours,
    required this.overduePercentage,
    this.mostActiveWarehouse,
  });

  final int completionRate;
  final double averageCompletionHours;
  final int overduePercentage;
  final String? mostActiveWarehouse;
}

enum TaskActivityType {
  created,
  assigned,
  started,
  completed,
  approved,
}

class TaskActivityItem {
  const TaskActivityItem({
    required this.type,
    required this.taskTitle,
    required this.timestamp,
    this.actorName,
    this.note,
  });

  final TaskActivityType type;
  final String taskTitle;
  final DateTime timestamp;
  final String? actorName;
  final String? note;

  String get label => switch (type) {
        TaskActivityType.created => 'Task Created',
        TaskActivityType.assigned => 'Task Assigned',
        TaskActivityType.started => 'Task Started',
        TaskActivityType.completed => 'Task Completed',
        TaskActivityType.approved => 'Task Approved',
      };
}

class TaskWorkflowAction {
  const TaskWorkflowAction({
    required this.label,
    required this.targetStatus,
    this.iconName,
    this.destructive = false,
  });

  final String label;
  final String targetStatus;
  final String? iconName;
  final bool destructive;

  factory TaskWorkflowAction.fromStatus(String status) {
    final (label, destructive) = switch (status) {
      WmsTaskStatuses.accepted => ('Accept', false),
      WmsTaskStatuses.inProgress => ('Start Work', false),
      WmsTaskStatuses.waitingConfirmation => ('Submit for Approval', false),
      WmsTaskStatuses.completed => ('Complete', false),
      WmsTaskStatuses.rejected => ('Reject', true),
      WmsTaskStatuses.pending => ('Reopen', false),
      _ => (status, false),
    };
    return TaskWorkflowAction(
      label: label,
      targetStatus: status,
      destructive: destructive,
    );
  }
}
