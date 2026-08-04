import 'package:logisticsmobile/features/auth/domain/entities/user_role.dart';
import 'package:logisticsmobile/routes/route_names.dart';

abstract final class RoleRouteHelper {
  static String dashboardPathForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return RoutePaths.adminDashboard;
      case UserRole.supervisor:
        return RoutePaths.supervisorDashboard;
      case UserRole.staff:
      case UserRole.unknown:
        return RoutePaths.staffDashboard;
    }
  }

  static bool isRoleHomeRoute(String location, UserRole role) {
    return location == dashboardPathForRole(role);
  }

  static bool isAllowedRouteForRole(String location, UserRole role) {
    if (_isGlobalRoute(location)) return true;
    switch (role) {
      case UserRole.admin:
        return RoutePaths.isAdminArea(location);
      case UserRole.supervisor:
        return RoutePaths.isSupervisorArea(location);
      case UserRole.staff:
      case UserRole.unknown:
        return RoutePaths.isStaffArea(location);
    }
  }

  static bool _isGlobalRoute(String location) {
    return location == RoutePaths.settings;
  }
}
