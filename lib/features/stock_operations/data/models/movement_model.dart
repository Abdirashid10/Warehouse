import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';

class MovementModel {
  MovementModel({
    required this.id,
    required this.type,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.performedBy,
    required this.timestamp,
    this.fromLocation,
    this.toLocation,
    this.notes,
    this.relatedTaskId,
  });

  factory MovementModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final performer = json['performed_by'] ?? json['performedBy'] ?? json['user'];

    return MovementModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? json['movement_type'] ?? '').toString(),
      productName: product is Map
          ? (product['name'] ?? '').toString()
          : (json['product_name'] ?? '').toString(),
      sku: product is Map
          ? (product['sku'] ?? '').toString()
          : (json['sku'] ?? '').toString(),
      quantity: json['quantity'] as num? ?? 0,
      performedBy: performer is Map
          ? (performer['fullName'] ?? performer['name'] ?? performer['username'] ?? 'Staff').toString()
          : (performer ?? 'Staff').toString(),
      timestamp: DateTime.tryParse(
        (json['timestamp'] ?? json['createdAt'] ?? json['created_at'] ?? '').toString(),
      ),
      fromLocation: (json['from'] ?? json['from_warehouse'] ?? json['fromWarehouse']) is Map
          ? ((json['from'] ?? json['from_warehouse'])['name']?.toString())
          : json['from']?.toString(),
      toLocation: (json['to'] ?? json['to_warehouse'] ?? json['toWarehouse']) is Map
          ? ((json['to'] ?? json['to_warehouse'])['name']?.toString())
          : json['to']?.toString(),
      notes: json['notes']?.toString(),
      relatedTaskId: (json['related_task'] ?? json['task_id'])?.toString(),
    );
  }

  final String id;
  final String type;
  final String productName;
  final String sku;
  final num quantity;
  final String performedBy;
  final DateTime? timestamp;
  final String? fromLocation;
  final String? toLocation;
  final String? notes;
  final String? relatedTaskId;

  StockMovement toEntity() => StockMovement(
        id: id,
        type: type,
        productName: productName,
        sku: sku,
        quantity: quantity,
        performedBy: performedBy,
        timestamp: timestamp,
        fromLocation: fromLocation,
        toLocation: toLocation,
        notes: notes,
        relatedTaskId: relatedTaskId,
      );
}
