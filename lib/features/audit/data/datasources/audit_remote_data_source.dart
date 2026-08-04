import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/network/json_list_parser.dart';
import 'package:logisticsmobile/features/audit/domain/entities/audit_activity.dart';

class AuditRemoteDataSource {
  AuditRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuditPage> fetchActivities({
    int page = 1,
    int limit = 25,
    String? query,
    String? module,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiConstants.auditActivities,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (query != null && query.isNotEmpty) 'q': query,
          if (module != null && module.isNotEmpty) 'module': module,
        },
      );
      final data = response.data;
      final maps = JsonListParser.extractMaps(data, keys: ['activities']);
      final pagination = data is Map ? data['pagination'] : null;
      var total = maps.length;
      var pages = 1;
      if (pagination is Map) {
        total = (pagination['total'] as num?)?.toInt() ?? total;
        pages = (pagination['pages'] as num?)?.toInt() ?? 1;
      }

      final activities = maps.map(_mapActivity).toList();
      return AuditPage(
        activities: activities,
        page: page,
        pages: pages,
        total: total,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  AuditActivity _mapActivity(Map<String, dynamic> json) {
    final actor = json['actor'];
    var userName = 'System';
    if (actor is Map) {
      userName = (actor['fullName'] ??
              actor['full_name'] ??
              actor['username'] ??
              'Staff')
          .toString();
    }
    return AuditActivity(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      module: (json['module'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
      userName: userName,
      occurredAt: DateTime.tryParse(
        (json['createdAt'] ?? json['created_at'] ?? '').toString(),
      ),
    );
  }
}
