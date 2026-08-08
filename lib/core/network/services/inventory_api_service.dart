import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';

/// Inventory API — prepared for Phase 3 integration.
class InventoryApiService {
  InventoryApiService(this._dio);

  final Dio _dio;

  Future<Response<dynamic>> getInventory({Map<String, dynamic>? query}) =>
      _dio.get(ApiConstants.inventoryTracking, queryParameters: query);
}
