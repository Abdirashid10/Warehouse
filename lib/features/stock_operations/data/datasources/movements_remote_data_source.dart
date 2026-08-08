import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/constants/wms/movement_constants.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/network/json_list_parser.dart';
import 'package:logisticsmobile/features/stock_operations/data/models/movement_model.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/create_movement_input.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';

class MovementsRemoteDataSource {
  MovementsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<MovementModel>> fetchMovements({
    String? type,
    int limit = 300,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiConstants.inventoryMovements,
        queryParameters: {
          'limit': limit,
          if (type != null && type.isNotEmpty) 'type': type,
        },
      );
      final maps = JsonListParser.extractMaps(
        response.data,
        keys: ['movements'],
      );
      return maps.map(MovementModel.fromJson).toList();
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  /// POST /api/inventory/movements — records movement and updates inventory.
  Future<StockMovement> createMovement(CreateMovementInput input) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiConstants.inventoryMovements,
        data: input.toJson(),
      );
      final root = JsonListParser.extractMap(response.data);
      final movementMap = root?['movement'];
      if (movementMap is! Map<String, dynamic>) {
        throw ApiException(message: 'Invalid movement response from server');
      }
      return MovementModel.fromJson(movementMap).toEntity();
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  MovementStats computeStats(List<MovementModel> movements) {
    var inbound = 0;
    var outbound = 0;
    var transfers = 0;
    var adjustments = 0;
    var returns = 0;
    for (final m in movements) {
      switch (m.type) {
        case WmsMovementTypes.inbound:
          inbound++;
        case WmsMovementTypes.returnType:
          returns++;
        case WmsMovementTypes.outbound:
          outbound++;
        case WmsMovementTypes.transfer:
          transfers++;
        case WmsMovementTypes.adjustment:
          adjustments++;
      }
    }
    return MovementStats(
      total: movements.length,
      inbound: inbound,
      outbound: outbound,
      transfers: transfers,
      adjustments: adjustments,
      returns: returns,
    );
  }
}
