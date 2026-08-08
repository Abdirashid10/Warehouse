import 'package:equatable/equatable.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/utils/task_workflow_utils.dart';

class TaskStatusHistoryEntry extends Equatable {
  const TaskStatusHistoryEntry({
    required this.status,
    this.statusLabel,
    this.changedAt,
    this.note,
    this.action,
    this.changedByName,
  });

  final String status;
  final String? statusLabel;
  final DateTime? changedAt;
  final String? note;
  final String? action;
  final String? changedByName;

  @override
  List<Object?> get props =>
      [status, statusLabel, changedAt, note, action, changedByName];
}

class WarehouseTask extends Equatable {
  const WarehouseTask({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.taskType,
    this.productName,
    this.quantity,
    this.warehouseName,
    this.dueDate,
    this.movementType,
    this.description,
    this.assignedToName,
    this.assignedToId,
    this.assignedByName,
    this.createdByName,
    this.warehouseId,
    this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.workflowStatus,
    this.isOverdueFlag = false,
    this.statusHistory = const [],
  });

  final String id;
  final String title;
  final String status;
  final String priority;
  final String taskType;
  final String? productName;
  final num? quantity;
  final String? warehouseName;
  final DateTime? dueDate;
  final String? movementType;
  final String? description;
  final String? assignedToName;
  final String? assignedToId;
  final String? assignedByName;
  final String? createdByName;
  final String? warehouseId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? workflowStatus;
  final bool isOverdueFlag;
  final List<TaskStatusHistoryEntry> statusHistory;

  bool get isActive =>
      status != WmsTaskStatuses.completed && status != WmsTaskStatuses.rejected;

  bool get isOverdue =>
      isOverdueFlag || TaskWorkflowUtils.isTaskOverdue(this);

  String get effectiveStatus => TaskWorkflowUtils.displayStatus(this);

  String get workflowBucket => TaskWorkflowUtils.workflowBucket(this);

  @override
  List<Object?> get props => [
        id,
        title,
        status,
        priority,
        taskType,
        productName,
        quantity,
        warehouseName,
        dueDate,
        movementType,
        description,
        assignedToName,
        assignedToId,
        assignedByName,
        createdByName,
        warehouseId,
        createdAt,
        updatedAt,
        acceptedAt,
        startedAt,
        completedAt,
        workflowStatus,
        isOverdueFlag,
        statusHistory,
      ];
}
