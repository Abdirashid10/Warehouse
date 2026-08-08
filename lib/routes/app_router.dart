import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/auth/auth_debug_log.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:logisticsmobile/features/auth/presentation/pages/login_screen.dart';
import 'package:logisticsmobile/features/auth/presentation/pages/splash_screen.dart';
import 'package:logisticsmobile/features/audit/presentation/pages/audit_logs_screen.dart';
import 'package:logisticsmobile/features/inventory/presentation/pages/expiry_risk_screen.dart';
import 'package:logisticsmobile/features/inventory/presentation/pages/inventory_screen.dart';
import 'package:logisticsmobile/features/inventory/presentation/pages/inventory_tracking_screen.dart';
import 'package:logisticsmobile/features/admin/presentation/pages/admin_inventory_tab.dart';
import 'package:logisticsmobile/features/admin/presentation/pages/administration_screen.dart';
import 'package:logisticsmobile/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:logisticsmobile/features/orders/presentation/pages/my_orders_screen.dart';
import 'package:logisticsmobile/features/orders/presentation/pages/order_detail_screen.dart';
import 'package:logisticsmobile/features/products/presentation/pages/products_list_screen.dart';
import 'package:logisticsmobile/features/profile/presentation/pages/profile_screen.dart';
import 'package:logisticsmobile/features/settings/presentation/pages/settings_screen.dart';
import 'package:logisticsmobile/features/reports/presentation/pages/reports_screen.dart';
import 'package:logisticsmobile/features/shell/presentation/pages/admin_shell.dart';
import 'package:logisticsmobile/features/shell/presentation/pages/staff_shell.dart';
import 'package:logisticsmobile/features/shell/presentation/pages/supervisor_shell.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/pages/stock_movements_screen.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/pages/stock_operations_screen.dart';
import 'package:logisticsmobile/features/dashboard/presentation/pages/admin_dashboard_screen.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/presentation/pages/supervisor_dashboard_screen.dart';
import 'package:logisticsmobile/features/tasks/presentation/pages/my_tasks_screen.dart';
import 'package:logisticsmobile/features/tasks/presentation/pages/task_detail_screen.dart';
import 'package:logisticsmobile/features/users/presentation/pages/user_detail_screen.dart';
import 'package:logisticsmobile/features/users/presentation/pages/users_screen.dart';
import 'package:logisticsmobile/features/warehouses/presentation/pages/warehouses_screen.dart';
import 'package:logisticsmobile/features/dashboard/presentation/pages/staff_dashboard_screen.dart';
import 'package:logisticsmobile/routes/auth_refresh_notifier.dart';
import 'package:logisticsmobile/routes/role_route_helper.dart';
import 'package:logisticsmobile/routes/route_names.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static GoRouter create({
    required AuthBloc authBloc,
    required AuthRefreshNotifier refreshListenable,
  }) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: RoutePaths.splash,
      debugLogDiagnostics: kDebugMode,
      refreshListenable: refreshListenable,
      redirect: (context, state) => _redirect(authBloc.state, state),
      routes: [
        GoRoute(
          path: RoutePaths.splash,
          name: RouteNames.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: RoutePaths.login,
          name: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: RoutePaths.settings,
          name: RouteNames.settings,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: RoutePaths.adminRoot,
          redirect: (_, __) => RoutePaths.adminDashboard,
        ),
        GoRoute(
          path: RoutePaths.supervisorRoot,
          redirect: (_, __) => RoutePaths.supervisorDashboard,
        ),
        GoRoute(
          path: RoutePaths.staffRoot,
          redirect: (_, __) => RoutePaths.staffDashboard,
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AdminShell(navigationShell: navigationShell);
          },
          branches: [
            _shellBranch(RoutePaths.adminDashboard, RouteNames.adminDashboard,
                const AdminDashboardScreen()),
            _shellBranch(RoutePaths.adminInventory, RouteNames.adminInventory,
                const AdminInventoryTab()),
            _shellBranch(RoutePaths.adminOrders, RouteNames.adminOrders,
                const MyOrdersScreen()),
            _shellBranch(RoutePaths.adminTasks, RouteNames.adminTasks,
                const MyTasksScreen(embeddedInShell: true)),
            _shellBranch(RoutePaths.adminProfile, RouteNames.adminProfile,
                const ProfileScreen()),
          ],
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return SupervisorShell(navigationShell: navigationShell);
          },
          branches: [
            _shellBranch(RoutePaths.supervisorDashboard, RouteNames.supervisorDashboard,
                const SupervisorDashboardScreen()),
            _shellBranch(RoutePaths.supervisorInventory, RouteNames.supervisorInventory,
                const InventoryScreen()),
            _shellBranch(RoutePaths.supervisorOrders, RouteNames.supervisorOrders,
                const MyOrdersScreen()),
            _shellBranch(RoutePaths.supervisorTasks, RouteNames.supervisorTasks,
                const MyTasksScreen(embeddedInShell: true)),
            _shellBranch(RoutePaths.supervisorProfile, RouteNames.supervisorProfile,
                const ProfileScreen()),
          ],
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return StaffShell(navigationShell: navigationShell);
          },
          branches: [
            _shellBranch(RoutePaths.staffDashboard, RouteNames.staffDashboard,
                const StaffDashboardScreen()),
            _shellBranch(RoutePaths.staffInventory, RouteNames.staffInventory,
                const InventoryScreen()),
            _shellBranch(RoutePaths.staffOrders, RouteNames.staffOrders,
                const MyOrdersScreen()),
            _shellBranch(RoutePaths.staffTasks, RouteNames.staffTasks,
                const MyTasksScreen(embeddedInShell: true)),
            _shellBranch(RoutePaths.staffProfile, RouteNames.staffProfile,
                const ProfileScreen()),
          ],
        ),
        _pushedRoute(RoutePaths.adminProducts, RouteNames.adminProducts,
            const ProductsListScreen()),
        _pushedRoute(RoutePaths.adminNotifications, RouteNames.adminNotifications,
            const NotificationsScreen()),
        _pushedRoute(RoutePaths.adminStockMovements, RouteNames.adminStockMovements,
            const StockMovementsScreen()),
        _stockOpsRoute(
          RoutePaths.adminStockOperations,
          RouteNames.adminStockOperations,
        ),
        _pushedRoute(RoutePaths.adminWarehouses, RouteNames.adminWarehouses,
            const WarehousesScreen()),
        _pushedRoute(RoutePaths.adminReports, RouteNames.adminReports,
            const ReportsScreen()),
        _pushedRoute(RoutePaths.adminAudit, RouteNames.adminAudit,
            const AuditLogsScreen()),
        _pushedRoute(RoutePaths.adminUsers, RouteNames.adminUsers,
            const UsersScreen()),
        GoRoute(
          path: '/admin/users/:id',
          name: RouteNames.adminUserDetail,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final extra = state.extra;
            if (extra is UserDetailArgs) {
              return UserDetailScreen(args: extra);
            }
            return const Scaffold(
              body: Center(child: Text('User not found')),
            );
          },
        ),
        _pushedRoute(RoutePaths.adminAdministration, RouteNames.adminAdministration,
            const AdministrationScreen()),
        _pushedRoute(RoutePaths.supervisorNotifications,
            RouteNames.supervisorNotifications,
            const NotificationsScreen()),
        _pushedRoute(RoutePaths.supervisorProducts, RouteNames.supervisorProducts,
            const ProductsListScreen()),
        _pushedRoute(
          RoutePaths.supervisorInventoryTracking,
          RouteNames.supervisorInventoryTracking,
          const InventoryTrackingScreen(),
        ),
        _pushedRoute(
          RoutePaths.supervisorStockMovements,
          RouteNames.supervisorStockMovements,
          const StockMovementsScreen(),
        ),
        _pushedRoute(RoutePaths.supervisorWarehouses, RouteNames.supervisorWarehouses,
            const WarehousesScreen()),
        _pushedRoute(
          RoutePaths.supervisorExpiryRisk,
          RouteNames.supervisorExpiryRisk,
          const ExpiryRiskScreen(),
        ),
        _pushedRoute(RoutePaths.supervisorAudit, RouteNames.supervisorAudit,
            const AuditLogsScreen()),
        _stockOpsRoute(
          RoutePaths.supervisorStockOperations,
          RouteNames.supervisorStockOperations,
        ),
        _pushedRoute(RoutePaths.supervisorReports, RouteNames.supervisorReports,
            const ReportsScreen()),
        _stockOpsRoute(
          RoutePaths.staffStockOperations,
          RouteNames.staffStockOperations,
        ),
        _pushedRoute(RoutePaths.staffNotifications, RouteNames.staffNotifications,
            const NotificationsScreen()),
        _pushedRoute(RoutePaths.staffReports, RouteNames.staffReports,
            const ReportsScreen()),
        GoRoute(
          path: '/staff/tasks/:id',
          name: RouteNames.staffTaskDetail,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) =>
              TaskDetailScreen(taskId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/staff/orders/:id',
          name: RouteNames.staffOrderDetail,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) =>
              OrderDetailScreen(orderId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/supervisor/tasks/:id',
          name: RouteNames.supervisorTaskDetail,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) =>
              TaskDetailScreen(taskId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/supervisor/orders/:id',
          name: RouteNames.supervisorOrderDetail,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) =>
              OrderDetailScreen(orderId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/admin/tasks/:id',
          name: RouteNames.adminTaskDetail,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) =>
              TaskDetailScreen(taskId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/admin/orders/:id',
          name: RouteNames.adminOrderDetail,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) =>
              OrderDetailScreen(orderId: state.pathParameters['id']!),
        ),
      ],
    );
  }

  static StatefulShellBranch _shellBranch(
    String path,
    String name,
    Widget child,
  ) {
    return StatefulShellBranch(
      routes: [
        GoRoute(path: path, name: name, builder: (context, state) => child),
      ],
    );
  }

  static GoRoute _pushedRoute(String path, String name, Widget child) {
    return GoRoute(
      path: path,
      name: name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => child,
    );
  }

  static GoRoute _stockOpsRoute(String path, String name) {
    return GoRoute(
      path: path,
      name: name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final tab = state.extra is int ? (state.extra as int).clamp(0, 5) : 0;
        return StockOperationsScreen(initialTab: tab);
      },
    );
  }

  static String? _redirect(AuthState authState, GoRouterState state) {
    final location = state.matchedLocation;
    final isSplash = location == RoutePaths.splash;
    final isLogin = location == RoutePaths.login;
    final isAuthRoute = isSplash || isLogin;

    String? target;

    switch (authState.status) {
      case AuthStatus.unknown:
        target = isSplash ? null : RoutePaths.splash;
        break;

      case AuthStatus.loading:
        // Never bounce the user during a sign-in/sign-out. Also treat an
        // ambiguous loadingType defensively as "stay put" — redirecting to
        // splash remounts it and queues a new AuthCheckRequested, which can
        // clobber a valid session and cause the login loop.
        if (authState.loadingType == AuthLoadingType.login ||
            authState.loadingType == AuthLoadingType.logout ||
            authState.loadingType == null) {
          target = null;
        } else {
          target = isSplash ? null : RoutePaths.splash;
        }
        break;

      case AuthStatus.unauthenticated:
        target = isLogin ? null : RoutePaths.login;
        if (target == RoutePaths.login) {
          AuthDebugLog.redirect(
            from: location,
            to: target,
            authStatus: authState.status.name,
            reason: authState.failureDetail ??
                authState.errorMessage ??
                'unauthenticated (no detail)',
          );
        }
        break;

      case AuthStatus.authenticated:
        final user = authState.user;
        if (user == null) {
          target = RoutePaths.login;
          AuthDebugLog.redirect(
            from: location,
            to: target,
            authStatus: 'authenticated-but-user-null',
            reason: 'AuthState.user is null — should not happen after login',
          );
          break;
        }

        final home = RoleRouteHelper.dashboardPathForRole(user.role);

        if (isAuthRoute) {
          target = home;
          AuthDebugLog.navigationRoute(home, reason: 'post-auth home');
        } else if (!RoleRouteHelper.isAllowedRouteForRole(location, user.role)) {
          target = home;
          AuthDebugLog.navigationRoute(home, reason: 'role guard');
        } else {
          target = null;
        }
        break;
    }

    if (kDebugMode && target != null) {
      AuthDebugLog.redirect(
        from: location,
        to: target,
        authStatus: authState.status.name,
      );
    }

    // Idempotency guard: never redirect to the route we are already on. This
    // prevents a GoRouter redirect loop (continuous re-evaluation) that would
    // otherwise spin the UI and trigger ANR / "isn't responding".
    if (target != null && target == location) {
      return null;
    }

    return target;
  }
}
