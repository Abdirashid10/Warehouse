import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Resolves detail and module paths from the active role area (/staff, /supervisor, /admin).
abstract final class WmsRoutePaths {
  static String _prefix(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/admin')) return '/admin';
    if (location.startsWith('/supervisor')) return '/supervisor';
    return '/staff';
  }

  static String taskDetail(BuildContext context, String id) =>
      '${_prefix(context)}/tasks/$id';

  static String orderDetail(BuildContext context, String id) =>
      '${_prefix(context)}/orders/$id';
}
