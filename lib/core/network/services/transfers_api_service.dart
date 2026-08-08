import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';

/// Transfers API — prepared for Phase 3 integration.
class TransfersApiService {
  TransfersApiService(this._dio);

  final Dio _dio;

  Future<Response<dynamic>> getTransfers({Map<String, dynamic>? query}) =>
      _dio.get(ApiConstants.inventoryMovements, queryParameters: query);
}
