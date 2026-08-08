import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    this.description,
    this.category,
    this.categoryId,
    this.unitCost,
    this.unitPrice,
    this.minStockThreshold,
    this.barcode,
    this.imageUrl,
    this.totalStock,
    this.warehouseCount,
    this.earliestExpiry,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String sku;
  final String? description;
  final String? category;
  final String? categoryId;
  final num? unitCost;
  final num? unitPrice;
  final num? minStockThreshold;
  final String? barcode;
  final String? imageUrl;
  final num? totalStock;
  final int? warehouseCount;
  final DateTime? earliestExpiry;
  final DateTime? updatedAt;

  bool get isExpired {
    final expiry = earliestExpiry;
    return expiry != null && expiry.isBefore(DateTime.now());
  }

  String get stockStatusLabel {
    if (isExpired) return 'Expired';
    final stock = totalStock ?? 0;
    final minStock = minStockThreshold ?? 0;
    final whCount = warehouseCount ?? 0;
    if (whCount == 0 && stock == 0) return 'No Inventory';
    if (stock == 0) return 'Out Of Stock';
    if (stock > 0 && stock <= minStock) return 'Low Stock';
    return 'In Stock';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        sku,
        description,
        category,
        categoryId,
        unitCost,
        unitPrice,
        minStockThreshold,
        barcode,
        imageUrl,
        totalStock,
        warehouseCount,
        earliestExpiry,
        updatedAt,
      ];
}
