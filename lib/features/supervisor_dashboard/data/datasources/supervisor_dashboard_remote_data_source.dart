import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/network/json_list_parser.dart';

class SupervisorDashboardRemoteDataSource {
  SupervisorDashboardRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchStats() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.dashboardStats);
      return JsonListParser.extractMap(response.data) ?? {};
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Future<Map<String, dynamic>> fetchWidgets() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.dashboardWidgets);
      return JsonListParser.extractMap(response.data) ?? {};
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Future<List<Map<String, dynamic>>> fetchWarehouses() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.inventoryWarehouses);
      return JsonListParser.extractMaps(response.data, keys: ['warehouses']);
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Future<List<Map<String, dynamic>>> fetchTeamActivities({int limit = 20}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiConstants.auditActivities,
        queryParameters: {'limit': limit},
      );
      return JsonListParser.extractMaps(response.data, keys: ['activities']);
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }
}
