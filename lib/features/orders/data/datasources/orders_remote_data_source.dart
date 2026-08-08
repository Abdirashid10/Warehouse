import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/constants/wms/order_constants.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/network/json_list_parser.dart';
import 'package:logisticsmobile/features/orders/data/models/order_model.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';

class OrdersRemoteDataSource {
  OrdersRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<OrderModel>> fetchOrders({String? status}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiConstants.orders,
        queryParameters: status != null && status.isNotEmpty
            ? {'status': status}
            : null,
      );
      final maps = JsonListParser.extractMaps(response.data, keys: ['orders']);
      return maps.map(OrderModel.fromJson).toList();
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Future<OrderModel> fetchOrder(String id) async {
    try {
      final response = await _dio.get<dynamic>('${ApiConstants.orders}/$id');
      final data = response.data;
      Map<String, dynamic>? json;
      if (data is Map<String, dynamic>) {
        json = data['order'] is Map<String, dynamic>
            ? data['order'] as Map<String, dynamic>
            : data;
      }
      if (json == null) {
        throw const ApiException(message: 'Order not found');
      }
      return OrderModel.fromJson(json);
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Future<OrderModel> updateStatus({
    required String id,
    required String status,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        '${ApiConstants.orders}/$id/status',
        data: {'status': status},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final order = data['order'];
        if (order is Map<String, dynamic>) {
          return OrderModel.fromJson(order);
        }
      }
      return fetchOrder(id);
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  OrderStats computeStats(List<OrderModel> orders) {
    var processing = 0;
    var packed = 0;
    var shipped = 0;
    for (final o in orders) {
      switch (o.status) {
        case WmsOrderStatuses.processing:
          processing++;
        case WmsOrderStatuses.packed:
          packed++;
        case WmsOrderStatuses.shipped:
          shipped++;
      }
    }
    return OrderStats(
      actionable: processing + packed + shipped,
      processing: processing,
      packed: packed,
      shipped: shipped,
    );
  }
}
