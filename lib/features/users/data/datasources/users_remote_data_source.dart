import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/network/json_list_parser.dart';
import 'package:logisticsmobile/features/users/domain/entities/create_user_input.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';

class UsersRemoteDataSource {
  UsersRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<WmsUser>> fetchUsers() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.users);
      final maps = JsonListParser.extractMaps(response.data, keys: ['users']);
      return maps.map(_mapUser).toList();
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Future<WmsUser> createUser(CreateUserInput input) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiConstants.users,
        data: input.toJson(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final user = data['user'];
        if (user is Map<String, dynamic>) return _mapUser(user);
      }
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final user = map['user'];
        if (user is Map) return _mapUser(Map<String, dynamic>.from(user));
      }
      throw const ApiException(message: 'Invalid user response');
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Future<WmsUser> updateStatus({
    required String id,
    required String status,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        '${ApiConstants.users}/$id/status',
        data: {'status': status},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final user = data['user'];
        if (user is Map<String, dynamic>) return _mapUser(user);
      }
      throw const ApiException(message: 'Invalid user response');
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  WmsUser _mapUser(Map<String, dynamic> json) {
    return WmsUser(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      status: (json['status'] ?? 'Active').toString(),
      fullName: (json['fullName'] ?? json['full_name'] ?? json['name'])?.toString(),
      assignedWarehouse: _parseWarehouse(json),
      archived: json['archived'] == true,
      lastLoginAt: DateTime.tryParse(
        (json['lastLoginAt'] ?? json['last_login_at'] ?? '').toString(),
      ),
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['created_at'] ?? '').toString(),
      ),
      loginCount: _parseInt(json['loginCount'] ?? json['login_count']),
    );
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  String? _parseWarehouse(Map<String, dynamic> json) {
    final direct = json['warehouse'] ??
        json['assigned_warehouse'] ??
        json['assignedWarehouse'];
    if (direct is String && direct.isNotEmpty) return direct;
    if (direct is Map) {
      final name = direct['name']?.toString();
      if (name != null && name.isNotEmpty) return name;
    }
    final warehousesRaw = json['assigned_warehouses'] ?? json['assignedWarehouses'];
    if (warehousesRaw is List && warehousesRaw.isNotEmpty) {
      final first = warehousesRaw.first;
      if (first is String && first.isNotEmpty) return first;
      if (first is Map) {
        final name = first['name']?.toString();
        if (name != null && name.isNotEmpty) return name;
      }
    }
    return null;
  }
}
