import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';

class TaskModel {
  TaskModel({
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

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final product = json['related_product'];
    final warehouse = json['warehouse'];
    final meta = json['task_type_meta'];
    final assignedTo = json['assigned_to'];
    final assignedBy = json['assigned_by'];
    final createdBy = json['created_by'];

    return TaskModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? 'Pending').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      taskType: (json['task_type'] ?? json['taskType'] ?? '').toString(),
      productName: product is Map
          ? (product['name'] ?? product['title'])?.toString()
          : null,
      quantity: json['quantity'] as num?,
      warehouseName:
          warehouse is Map ? warehouse['name']?.toString() : null,
      dueDate: _parseDate(json['due_date'] ?? json['dueDate']),
      movementType: meta is Map
          ? meta['movement_type']?.toString() ??
              meta['movementType']?.toString()
          : null,
      description: json['description']?.toString(),
      assignedToName: _userName(assignedTo),
      assignedToId: assignedTo is Map
          ? (assignedTo['id'] ?? assignedTo['_id'])?.toString()
          : null,
      assignedByName: _userName(assignedBy),
      createdByName: _userName(createdBy),
      warehouseId: warehouse is Map
          ? (warehouse['id'] ?? warehouse['_id'])?.toString()
          : null,
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
      acceptedAt: _parseDate(json['accepted_at'] ?? json['acceptedAt']),
      startedAt: _parseDate(json['started_at'] ?? json['startedAt']),
      completedAt: _parseDate(json['completed_at'] ?? json['completedAt']),
      workflowStatus:
          (json['workflow_status'] ?? json['workflowStatus'])?.toString(),
      isOverdueFlag: json['is_overdue'] == true || json['isOverdue'] == true,
      statusHistory: _parseHistory(json['status_history'] ?? json['statusHistory']),
    );
  }

  static String? _userName(dynamic user) {
    if (user is! Map) return null;
    return (user['full_name'] ??
            user['fullName'] ??
            user['username'] ??
            user['name'])
        ?.toString();
  }

  static List<TaskStatusHistoryEntry> _parseHistory(dynamic raw) {
    if (raw is! List) return const [];
    final entries = <TaskStatusHistoryEntry>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      entries.add(
        TaskStatusHistoryEntry(
          status: (map['status'] ?? '').toString(),
          statusLabel: map['status_label']?.toString(),
          changedAt: _parseDate(map['changed_at'] ?? map['changedAt']),
          note: map['note']?.toString(),
          action: map['action']?.toString(),
          changedByName: _userName(map['changed_by'] ?? map['changedBy']),
        ),
      );
    }
    return entries;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

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

  WarehouseTask toEntity() => WarehouseTask(
        id: id,
        title: title,
        status: status,
        priority: priority,
        taskType: taskType,
        productName: productName,
        quantity: quantity,
        warehouseName: warehouseName,
        dueDate: dueDate,
        movementType: movementType,
        description: description,
        assignedToName: assignedToName,
        assignedToId: assignedToId,
        assignedByName: assignedByName,
        createdByName: createdByName,
        warehouseId: warehouseId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        acceptedAt: acceptedAt,
        startedAt: startedAt,
        completedAt: completedAt,
        workflowStatus: workflowStatus,
        isOverdueFlag: isOverdueFlag,
        statusHistory: statusHistory,
      );
}
