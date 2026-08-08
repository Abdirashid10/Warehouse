import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/constants/wms/stock_constants.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/network/json_list_parser.dart';
import 'package:logisticsmobile/features/inventory/data/models/inventory_models.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';

class InventoryRemoteDataSource {
  InventoryRemoteDataSource(this._dio);

  final Dio _dio;

  /// GET /api/inventory — flat inventory lines (fallback when tracking is empty).
  Future<({List<InventoryItemModel> items, InventorySummaryModel summary})>
      fetchInventory({
    String? query,
    String? warehouseId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiConstants.inventory,
        queryParameters: {
          if (query != null && query.isNotEmpty) 'q': query,
          if (warehouseId != null && warehouseId.isNotEmpty)
            'warehouse_id': warehouseId,
        },
      );
      final maps = JsonListParser.extractMaps(
        response.data,
        keys: ['lines', 'items', 'inventory'],
      );
      final items = maps.map(_applyStockStatus).toList();
      final root = JsonListParser.extractMap(response.data);
      final summary = root?['summary'] is Map<String, dynamic>
          ? InventorySummaryModel.fromJson(
              root!['summary'] as Map<String, dynamic>,
            )
          : InventorySummaryModel.fromItems(items);
      return (items: items, summary: summary);
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  /// GET /api/inventory/tracking — preferred staff view with stock status summary.
  Future<({List<InventoryItemModel> items, InventorySummaryModel summary})>
      fetchTracking({
    String? query,
    String? warehouseId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiConstants.inventoryTracking,
        queryParameters: {
          if (query != null && query.isNotEmpty) 'q': query,
          if (warehouseId != null && warehouseId.isNotEmpty)
            'warehouse_id': warehouseId,
        },
      );
      final maps = JsonListParser.extractMaps(
        response.data,
        keys: ['rows', 'items', 'inventory', 'data'],
      );
      final items = maps.map(_applyStockStatus).toList();
      final root = JsonListParser.extractMap(response.data);
      final summary = root?['summary'] is Map<String, dynamic>
          ? InventorySummaryModel.fromJson(
              root!['summary'] as Map<String, dynamic>,
            )
          : InventorySummaryModel.fromItems(items);
      return (items: items, summary: summary);
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  InventoryItemModel _applyStockStatus(Map<String, dynamic> json) {
    final model = InventoryItemModel.fromJson(json);
    if (model.stockStatus != WmsStockStatuses.inStock &&
        model.stockStatus != WmsStockStatuses.lowStock &&
        model.stockStatus != WmsStockStatuses.outOfStock) {
      final qty = model.quantity;
      final min = model.minThreshold ?? 0;
      String status;
      if (qty <= 0) {
        status = WmsStockStatuses.outOfStock;
      } else if (min > 0 && qty <= min) {
        status = WmsStockStatuses.lowStock;
      } else {
        status = WmsStockStatuses.inStock;
      }
      return InventoryItemModel(
        id: model.id,
        productName: model.productName,
        sku: model.sku,
        warehouseName: model.warehouseName,
        quantity: model.quantity,
        stockStatus: status,
        minThreshold: model.minThreshold,
        expiryDate: model.expiryDate,
        warehouseId: model.warehouseId,
        productId: model.productId,
        batchNumber: model.batchNumber,
        damagedQuantity: model.damagedQuantity,
      );
    }
    return model;
  }

  Future<List<WarehouseOption>> fetchWarehouses() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.inventoryWarehouses);
      final maps = JsonListParser.extractMaps(
        response.data,
        keys: ['warehouses'],
      );
      return maps
          .map(
            (w) => WarehouseOption(
              id: (w['_id'] ?? w['id'] ?? '').toString(),
              name: (w['name'] ?? '').toString(),
            ),
          )
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }
}
