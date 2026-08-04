import 'package:logisticsmobile/features/auth/domain/entities/user.dart';
import 'package:logisticsmobile/features/auth/domain/entities/user_role.dart';

/// Role-based access helpers for future UI gating.
abstract final class RolePermissions {
  static bool canManageTasks(User user) =>
      user.role.isAdmin || user.role.isSupervisor;

  static bool canManageInventory(User user) =>
      user.role.isAdmin || user.role.isSupervisor;

  static bool canApproveTransfers(User user) =>
      user.role.isAdmin || user.role.isSupervisor;

  static bool canViewReports(User user) => user.role.isAdmin;

  static bool canScanProducts(User user) =>
      user.role.isAdmin || user.role.isSupervisor || user.role.isStaff;

  static String navigationLabelForRole(UserRole role) => role.label;
}
