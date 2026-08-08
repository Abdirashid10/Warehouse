import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/network/json_list_parser.dart';
import 'package:logisticsmobile/core/utils/warehouse_staff_count.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';

class WarehousesRemoteDataSource {
  WarehousesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Warehouse>> fetchWarehouses() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.inventoryWarehouses);
      final maps = JsonListParser.extractMaps(response.data, keys: ['warehouses']);
      return maps.map(_mapWarehouse).toList();
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Future<Warehouse> createWarehouse({
    required String name,
    required String location,
    required num capacity,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiConstants.inventoryWarehouses,
        data: {'name': name, 'location': location, 'capacity': capacity},
      );
      return _extractWarehouse(response.data);
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Future<Warehouse> updateWarehouse({
    required String id,
    String? name,
    String? location,
    num? capacity,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        '${ApiConstants.inventoryWarehouses}/$id',
        data: {
          if (name != null) 'name': name,
          if (location != null) 'location': location,
          if (capacity != null) 'capacity': capacity,
        },
      );
      return _extractWarehouse(response.data);
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Warehouse _extractWarehouse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final wh = data['warehouse'];
      if (wh is Map<String, dynamic>) return _mapWarehouse(wh);
      return _mapWarehouse(data);
    }
    throw const ApiException(message: 'Invalid warehouse response');
  }

  Warehouse _mapWarehouse(Map<String, dynamic> json) {
    final staffCount = resolveWarehouseStaffCount(
      staffCountFromApi: json['staff_count'] ?? json['staffCount'],
      assignedStaffRaw: json['assigned_staff'] ?? json['assignedStaff'],
    );
    final totalUnits = json['totalUnits'] ?? json['total_units'] ?? 0;
    final utilization = json['utilization'];
    final assignedRaw = json['assigned_staff'] ?? json['assignedStaff'];
    final assignedStaff = <WarehouseStaffMember>[];
    if (assignedRaw is List) {
      for (final item in assignedRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = (map['id'] ?? map['_id'] ?? '').toString();
        if (id.isEmpty) continue;
        assignedStaff.add(
          WarehouseStaffMember(
            id: id,
            displayName: (map['full_name'] ??
                    map['fullName'] ??
                    map['username'] ??
                    'Staff')
                .toString(),
            username: map['username']?.toString(),
            avatar: map['avatar']?.toString(),
          ),
        );
      }
    }

    return Warehouse(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      capacity: json['capacity'] as num? ?? 0,
      staffCount: staffCount,
      totalUnits: totalUnits is num ? totalUnits : num.tryParse('$totalUnits') ?? 0,
      utilization: utilization is int
          ? utilization
          : int.tryParse('${utilization ?? ''}') ?? 0,
      lineCount: json['lineCount'] is int
          ? json['lineCount'] as int
          : int.tryParse('${json['lineCount'] ?? ''}') ?? 0,
      assignedStaff: assignedStaff,
    );
  }
}
