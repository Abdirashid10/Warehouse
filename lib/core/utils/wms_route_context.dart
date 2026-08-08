import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Role-aware route helpers for shared screens (orders, tasks, profile).
extension WmsRouteContext on BuildContext {
  String get currentPath => GoRouterState.of(this).uri.path;

  bool get isAdminWorkspace => currentPath.startsWith('/admin');

  bool get isSupervisorWorkspace => currentPath.startsWith('/supervisor');

  bool get isStaffWorkspace => currentPath.startsWith('/staff');
}
