import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';

/// Tasks API — prepared for Phase 3 integration.
class TasksApiService {
  TasksApiService(this._dio);

  final Dio _dio;

  Future<Response<dynamic>> getTasks({Map<String, dynamic>? query}) =>
      _dio.get(ApiConstants.tasks, queryParameters: query);
}
