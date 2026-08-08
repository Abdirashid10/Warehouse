import 'package:equatable/equatable.dart';

class InventoryItem extends Equatable {
  const InventoryItem({
    required this.id,
    required this.productName,
    required this.sku,
    required this.warehouseName,
    required this.quantity,
    required this.stockStatus,
    this.minThreshold,
    this.expiryDate,
    this.warehouseId,
    this.productId,
    this.batchNumber,
    this.damagedQuantity,
  });

  final String id;
  final String productName;
  final String sku;
  final String warehouseName;
  final num quantity;
  final String stockStatus;
  final num? minThreshold;
  final DateTime? expiryDate;
  final String? warehouseId;
  final String? productId;
  final String? batchNumber;
  final num? damagedQuantity;

  @override
  List<Object?> get props => [
        id,
        productName,
        sku,
        warehouseName,
        quantity,
        stockStatus,
        minThreshold,
        expiryDate,
        warehouseId,
        productId,
        batchNumber,
        damagedQuantity,
      ];
}

class InventorySummary extends Equatable {
  const InventorySummary({
    required this.totalUnits,
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
  });

  final num totalUnits;
  final int inStock;
  final int lowStock;
  final int outOfStock;

  @override
  List<Object?> get props => [totalUnits, inStock, lowStock, outOfStock];
}

class WarehouseOption extends Equatable {
  const WarehouseOption({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
