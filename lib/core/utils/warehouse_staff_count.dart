import 'package:logisticsmobile/features/auth/domain/entities/user_role.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';

/// Operational warehouse staff only — excludes Admin and Supervisor roles.
bool isOperationalWarehouseStaffRole(String? role) {
  return UserRole.fromString(role) == UserRole.staff;
}

String? roleFromAssignedStaffEntry(dynamic entry) {
  if (entry is! Map) return null;
  final map = Map<String, dynamic>.from(entry);
  final user = map['user'];
  if (user is Map) {
    return (user['role'] ?? user['userRole'])?.toString();
  }
  return (map['role'] ?? map['userRole'])?.toString();
}

int countStaffFromAssignedList(List<dynamic> assignedStaff) {
  return assignedStaff
      .where((entry) => isOperationalWarehouseStaffRole(roleFromAssignedStaffEntry(entry)))
      .length;
}

int resolveWarehouseStaffCount({
  dynamic staffCountFromApi,
  dynamic assignedStaffRaw,
  Iterable<WmsUser>? assignedUsers,
}) {
  if (assignedUsers != null) {
    return assignedUsers
        .where((user) => !user.archived && isOperationalWarehouseStaffRole(user.role))
        .length;
  }

  if (assignedStaffRaw is List && assignedStaffRaw.isNotEmpty) {
    return countStaffFromAssignedList(assignedStaffRaw);
  }

  final parsed = staffCountFromApi;
  if (parsed is int) return parsed;
  if (parsed is num) return parsed.toInt();
  return int.tryParse(parsed?.toString() ?? '') ?? 0;
}

int countOperationalStaffUsers(Iterable<WmsUser> users) {
  return users
      .where((user) => !user.archived && isOperationalWarehouseStaffRole(user.role))
      .length;
}

int countOperationalStaffForWarehouse(Iterable<WmsUser> users, String warehouseName) {
  final normalized = warehouseName.trim().toLowerCase();
  return users
      .where(
        (user) =>
            !user.archived &&
            isOperationalWarehouseStaffRole(user.role) &&
            user.assignedWarehouse != null &&
            user.assignedWarehouse!.trim().toLowerCase() == normalized,
      )
      .length;
}
