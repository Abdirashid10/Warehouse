import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/network/api_response_parser.dart';
import 'package:logisticsmobile/features/profile/domain/entities/user_profile.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<UserProfile> fetchProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiConstants.profileMe);
      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'Profile not found');
      }
      final profileJson = ApiResponseParser.extractUser(data);
      if (profileJson == null) {
        throw const ApiException(message: 'Profile response missing user data');
      }
      return _mapProfile(profileJson, envelope: data);
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  UserProfile _mapProfile(
    Map<String, dynamic> json, {
    Map<String, dynamic>? envelope,
  }) {
    final envelopeMap = envelope ?? json;
    final warehousesRaw = envelopeMap['assigned_warehouses'] ??
        envelopeMap['assignedWarehouses'] ??
        json['assigned_warehouses'];
    final warehouses = <String>[];
    if (warehousesRaw is Map) {
      final list = warehousesRaw['warehouses'];
      if (list is List) {
        for (final w in list) {
          if (w is Map) warehouses.add((w['name'] ?? '').toString());
        }
      }
    } else if (warehousesRaw is List) {
      for (final w in warehousesRaw) {
        if (w is String) {
          warehouses.add(w);
        } else if (w is Map) {
          warehouses.add((w['name'] ?? '').toString());
        }
      }
    } else if (envelopeMap['assignedWarehouse'] is String) {
      warehouses.add(envelopeMap['assignedWarehouse'] as String);
    } else if (json['warehouse'] is String) {
      warehouses.add(json['warehouse'] as String);
    }

    final permissionsRaw = envelopeMap['permissions'] ?? json['permissions'];
    final permissions = <String>[];
    if (permissionsRaw is List) {
      for (final p in permissionsRaw) {
        if (p is String) permissions.add(p);
        if (p is Map && p['name'] != null) {
          permissions.add(p['name'].toString());
        }
      }
    }

    return UserProfile(
      fullName: (json['fullName'] ?? json['full_name'] ?? json['name'] ?? '')
          .toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'Staff').toString(),
      username: (json['username'] ?? '').toString(),
      phone: json['phone']?.toString(),
      accountStatus: (json['accountStatus'] ?? json['status'] ?? 'Active')
          .toString(),
      assignedWarehouses: warehouses,
      permissions: permissions,
      lastActiveAt: DateTime.tryParse(
        (json['lastActiveAt'] ?? json['last_active_at'] ?? '').toString(),
      ),
      memberSince: DateTime.tryParse(
        (json['createdAt'] ?? json['created_at'] ?? '').toString(),
      ),
    );
  }
}
