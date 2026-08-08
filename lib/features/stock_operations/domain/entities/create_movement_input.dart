import 'package:equatable/equatable.dart';
import 'package:logisticsmobile/core/constants/wms/inventory_conditions.dart';

/// Payload for POST /api/inventory/movements.
class CreateMovementInput extends Equatable {
  const CreateMovementInput({
    required this.type,
    required this.productId,
    required this.quantity,
    required this.reason,
    this.warehouseId,
    this.fromWarehouseId,
    this.toWarehouseId,
    this.batchNumber,
    this.sourceLocation,
    this.destinationLocation,
    this.customerName,
    this.condition = WmsInventoryConditions.availableGood,
  });

  final String type;
  final String productId;
  final int quantity;
  final String reason;
  final String? warehouseId;
  final String? fromWarehouseId;
  final String? toWarehouseId;
  final String? batchNumber;
  final String? sourceLocation;
  final String? destinationLocation;
  final String? customerName;
  final String condition;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'type': type,
      'productId': productId,
      'quantity': quantity,
      'reason': reason,
      'condition': condition,
    };
    if (warehouseId != null && warehouseId!.isNotEmpty) {
      map['warehouseId'] = warehouseId;
    }
    if (fromWarehouseId != null && fromWarehouseId!.isNotEmpty) {
      map['fromWarehouseId'] = fromWarehouseId;
    }
    if (toWarehouseId != null && toWarehouseId!.isNotEmpty) {
      map['toWarehouseId'] = toWarehouseId;
    }
    if (batchNumber != null && batchNumber!.trim().isNotEmpty) {
      map['batchNumber'] = batchNumber!.trim();
    }
    if (sourceLocation != null && sourceLocation!.trim().isNotEmpty) {
      map['source_location'] = sourceLocation!.trim();
    }
    if (destinationLocation != null && destinationLocation!.trim().isNotEmpty) {
      map['destination_location'] = destinationLocation!.trim();
    }
    if (customerName != null && customerName!.trim().isNotEmpty) {
      map['customerName'] = customerName!.trim();
    }
    return map;
  }

  @override
  List<Object?> get props => [
        type,
        productId,
        quantity,
        reason,
        warehouseId,
        fromWarehouseId,
        toWarehouseId,
        batchNumber,
        sourceLocation,
        destinationLocation,
        customerName,
        condition,
      ];
}
