import 'package:logisticsmobile/core/constants/wms/task_constants.dart';

class CreateTaskInput {
  const CreateTaskInput({
    required this.title,
    required this.taskType,
    required this.warehouseId,
    required this.assignedToId,
    required this.dueDate,
    this.description = '',
    this.priority = WmsTaskPriorities.medium,
    this.toWarehouseId,
    this.relatedProductId,
    this.quantity,
    this.supplierName,
  });

  final String title;
  final String description;
  final String taskType;
  final String priority;
  final String warehouseId;
  final String? toWarehouseId;
  final String assignedToId;
  final DateTime dueDate;
  final String? relatedProductId;
  final num? quantity;
  final String? supplierName;

  Map<String, dynamic> toJson() {
    final apiType = WmsTaskTypes.toApiType(taskType);
    final isTransfer = WmsTaskTypes.requiresToWarehouse(taskType);
    final needsProduct = WmsTaskTypes.requiresProduct(taskType);
    final needsQty = WmsTaskTypes.requiresQuantity(taskType);
    final isInbound = WmsTaskTypes.requiresSupplier(taskType);

    return {
      'title': title.trim(),
      'description': description.trim(),
      'task_type': apiType == WmsTaskTypes.stockTransfer && taskType == 'Warehouse Transfer'
          ? 'Warehouse Transfer'
          : apiType,
      'priority': priority,
      'warehouse_id': warehouseId,
      'assigned_to_id': assignedToId,
      'due_date': dueDate.toUtc().toIso8601String(),
      if (isTransfer && toWarehouseId != null) 'to_warehouse_id': toWarehouseId,
      if (needsProduct && relatedProductId != null)
        'related_product_id': relatedProductId,
      if (needsQty && quantity != null) 'quantity': quantity,
      if (isInbound) 'supplier_name': supplierName?.trim() ?? '',
    };
  }
}

class ReassignTaskInput {
  const ReassignTaskInput({required this.assignedToId});

  final String assignedToId;

  Map<String, dynamic> toJson() => {'assigned_to_id': assignedToId};
}
