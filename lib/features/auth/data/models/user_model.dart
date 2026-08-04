import 'dart:convert';

import 'package:logisticsmobile/features/auth/domain/entities/user.dart';
import 'package:logisticsmobile/features/auth/domain/entities/user_role.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.role,
    super.warehouse,
    super.permissions = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final warehouseValue = json['warehouse'];
    String? warehouseName;
    if (warehouseValue is String) {
      warehouseName = warehouseValue;
    } else if (warehouseValue is Map) {
      warehouseName = warehouseValue['name']?.toString() ??
          warehouseValue['title']?.toString();
    }

    final permissionsRaw = json['permissions'];
    final permissions = <String>[];
    if (permissionsRaw is List) {
      for (final item in permissionsRaw) {
        if (item is String) {
          permissions.add(item);
        } else if (item is Map && item['name'] != null) {
          permissions.add(item['name'].toString());
        }
      }
    }

    final roleValue = json['role']?.toString() ??
        json['userRole']?.toString() ??
        json['type']?.toString();

    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      fullName: (json['fullName'] ??
              json['full_name'] ??
              json['name'] ??
              '')
          .toString(),
      email: (json['email'] ?? '').toString(),
      role: UserRole.fromString(roleValue),
      warehouse: warehouseName,
      permissions: permissions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'role': role.name,
        'warehouse': warehouse,
        'permissions': permissions,
      };

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String source) =>
      UserModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  User toEntity() => User(
        id: id,
        fullName: fullName,
        email: email,
        role: role,
        warehouse: warehouse,
        permissions: permissions,
      );
}
