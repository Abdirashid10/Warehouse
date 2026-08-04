import 'package:logisticsmobile/core/constants/wms/stock_constants.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';

class InventoryItemModel {
  InventoryItemModel({
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

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final warehouse = json['warehouse'];
    final qty = json['quantity'] ?? json['current_quantity'] ?? 0;
    final min = json['minStockThreshold'] ?? json['min_stock_threshold'];

    return InventoryItemModel(
      id: (json['_id'] ?? json['id'] ?? '${product?['_id']}-${warehouse?['_id']}').toString(),
      productName: product is Map
          ? (product['name'] ?? '').toString()
          : (json['product_name'] ?? '').toString(),
      sku: product is Map
          ? (product['sku'] ?? '').toString()
          : (json['sku'] ?? '').toString(),
      warehouseName: warehouse is Map
          ? (warehouse['name'] ?? '').toString()
          : (json['warehouse_name'] ?? '').toString(),
      quantity: qty is num ? qty : num.tryParse(qty.toString()) ?? 0,
      stockStatus: (json['_stockStatus'] ?? json['stock_status'] ?? WmsStockStatuses.inStock).toString(),
      minThreshold: min is num ? min : num.tryParse('$min'),
      expiryDate: DateTime.tryParse(
        (json['expiryDate'] ?? json['expiry_date'] ?? '').toString(),
      ),
      warehouseId: warehouse is Map ? warehouse['_id']?.toString() : null,
      productId: product is Map ? product['_id']?.toString() : null,
      batchNumber: _optionalString(
        json['batch'] ??
            json['batchNumber'] ??
            json['batch_number'] ??
            json['lot'] ??
            json['lotNumber'],
      ),
      damagedQuantity: _optionalNum(
        json['damaged'] ?? json['damagedQty'] ?? json['damaged_quantity'],
      ),
    );
  }

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static num? _optionalNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }

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

  InventoryItem toEntity() => InventoryItem(
        id: id,
        productName: productName,
        sku: sku,
        warehouseName: warehouseName,
        quantity: quantity,
        stockStatus: stockStatus,
        minThreshold: minThreshold,
        expiryDate: expiryDate,
        warehouseId: warehouseId,
        productId: productId,
        batchNumber: batchNumber,
        damagedQuantity: damagedQuantity,
      );
}

class InventorySummaryModel {
  InventorySummaryModel({
    required this.totalUnits,
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
  });

  factory InventorySummaryModel.fromJson(Map<String, dynamic> json) {
    return InventorySummaryModel(
      totalUnits: json['total_units'] ?? json['totalUnits'] ?? 0,
      inStock: ((json['in_stock'] ?? json['inStock'] ?? 0) as num).toInt(),
      lowStock: ((json['low_stock'] ?? json['lowStock'] ?? 0) as num).toInt(),
      outOfStock: ((json['out_of_stock'] ?? json['outOfStock'] ?? 0) as num).toInt(),
    );
  }

  factory InventorySummaryModel.fromItems(List<InventoryItemModel> items) {
    var inStock = 0;
    var low = 0;
    var out = 0;
    num total = 0;
    for (final item in items) {
      total += item.quantity;
      switch (item.stockStatus) {
        case WmsStockStatuses.lowStock:
          low++;
        case WmsStockStatuses.outOfStock:
          out++;
        default:
          inStock++;
      }
    }
    return InventorySummaryModel(
      totalUnits: total,
      inStock: inStock,
      lowStock: low,
      outOfStock: out,
    );
  }

  final num totalUnits;
  final int inStock;
  final int lowStock;
  final int outOfStock;

  InventorySummary toEntity() => InventorySummary(
        totalUnits: totalUnits,
        inStock: inStock,
        lowStock: lowStock,
        outOfStock: outOfStock,
      );
}
