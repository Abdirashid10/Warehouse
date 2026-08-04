import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/config/api_config.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/network/dio_client.dart';
import 'package:logisticsmobile/core/network/unauthorized_handler.dart';
import 'package:logisticsmobile/core/storage/session_storage.dart';
import 'package:logisticsmobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:logisticsmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:logisticsmobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:logisticsmobile/features/auth/data/services/auth_service.dart';
import 'package:logisticsmobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/validate_session_usecase.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:logisticsmobile/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:logisticsmobile/features/dashboard/data/repositories/control_center_repository_impl.dart';
import 'package:logisticsmobile/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:logisticsmobile/features/inventory/data/datasources/inventory_remote_data_source.dart';
import 'package:logisticsmobile/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:logisticsmobile/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:logisticsmobile/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:logisticsmobile/core/network/connectivity_service.dart';
import 'package:logisticsmobile/core/settings/theme_cubit.dart';
import 'package:logisticsmobile/core/settings/theme_preferences.dart';
import 'package:logisticsmobile/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:logisticsmobile/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:logisticsmobile/features/products/data/datasources/products_remote_data_source.dart';
import 'package:logisticsmobile/features/products/data/repositories/products_repository_impl.dart';
import 'package:logisticsmobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:logisticsmobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:logisticsmobile/features/stock_operations/data/datasources/movements_remote_data_source.dart';
import 'package:logisticsmobile/features/stock_operations/data/repositories/movements_repository_impl.dart';
import 'package:logisticsmobile/features/tasks/data/datasources/tasks_remote_data_source.dart';
import 'package:logisticsmobile/features/tasks/data/repositories/tasks_repository_impl.dart';
import 'package:logisticsmobile/features/audit/data/datasources/audit_remote_data_source.dart';
import 'package:logisticsmobile/features/audit/data/repositories/audit_repository_impl.dart';
import 'package:logisticsmobile/features/reports/data/datasources/reports_remote_data_source.dart';
import 'package:logisticsmobile/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/data/datasources/supervisor_dashboard_remote_data_source.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/data/repositories/supervisor_dashboard_repository_impl.dart';
import 'package:logisticsmobile/features/users/data/datasources/users_remote_data_source.dart';
import 'package:logisticsmobile/features/users/data/repositories/users_repository_impl.dart';
import 'package:logisticsmobile/features/warehouses/data/datasources/warehouses_remote_data_source.dart';
import 'package:logisticsmobile/features/warehouses/data/repositories/warehouses_repository_impl.dart';
import 'package:logisticsmobile/routes/app_router.dart';
import 'package:logisticsmobile/routes/auth_refresh_notifier.dart';

class AppDependencies {
  AppDependencies({
    required this.authBloc,
    required this.authRepository,
    required this.router,
    required this.authRefreshNotifier,
    required this.dio,
    required this.sessionStorage,
    required this.staffRepositories,
    required this.connectivity,
    required this.themeCubit,
    required this.themePreferences,
  });

  final AuthBloc authBloc;
  final AuthRepository authRepository;
  final GoRouter router;
  final AuthRefreshNotifier authRefreshNotifier;
  final Dio dio;
  final SessionStorage sessionStorage;
  final StaffRepositories staffRepositories;
  final ConnectivityService connectivity;
  final ThemeCubit themeCubit;
  final ThemePreferences themePreferences;

  Future<void> dispose() async {
    await themeCubit.close();
    await authBloc.close();
    if (authRepository is AuthRepositoryImpl) {
      (authRepository as AuthRepositoryImpl).dispose();
    }
    authRefreshNotifier.dispose();
    connectivity.dispose();
  }
}

class InjectionContainer {
  static Future<AppDependencies> init({
    AuthRepository? authRepositoryOverride,
    Dio? dioOverride,
    SessionStorage? sessionStorageOverride,
    UnauthorizedHandler? unauthorizedHandlerOverride,
  }) async {
    final sessionStorage =
        sessionStorageOverride ?? await SecureSessionStorage.create();
    final unauthorizedHandler = unauthorizedHandlerOverride ?? UnauthorizedHandler();

    final authLocal = AuthLocalDataSource(sessionStorage);
    final dio = dioOverride ??
        DioClient.create(
          sessionStorage: sessionStorage,
          unauthorizedHandler: unauthorizedHandler,
        );
    final authRemote = AuthRemoteDataSource(dio);
    final authService = AuthService(
      remoteDataSource: authRemote,
      localDataSource: authLocal,
    );

    final authRepository = authRepositoryOverride ??
        AuthRepositoryImpl(
          localDataSource: authLocal,
          authService: authService,
          sessionStorage: sessionStorage,
        );

    final tasksRemote = TasksRemoteDataSource(dio);
    final inventoryRemote = InventoryRemoteDataSource(dio);
    final movementsRemote = MovementsRemoteDataSource(dio);
    final ordersRemote = OrdersRemoteDataSource(dio);
    final dashboardRemote = DashboardRemoteDataSource(dio);
    final profileRemote = ProfileRemoteDataSource(dio);
    final notificationsRemote = NotificationsRemoteDataSource(dio);
    final productsRemote = ProductsRemoteDataSource(dio);
    final connectivity = ConnectivityService();
    await connectivity.start();

    final themePreferences = await ThemePreferences.create();
    final themeCubit = ThemeCubit(themePreferences)..load();

    final supervisorDashboardRemote = SupervisorDashboardRemoteDataSource(dio);
    final usersRemote = UsersRemoteDataSource(dio);
    final auditRemote = AuditRemoteDataSource(dio);
    final reportsRemote = ReportsRemoteDataSource(dio);
    final warehousesRemote = WarehousesRemoteDataSource(dio);
    final profileRepo = ProfileRepositoryImpl(profileRemote);
    final productsRepo = ProductsRepositoryImpl(productsRemote);
    final ordersRepo = OrdersRepositoryImpl(ordersRemote);
    final notificationsRepo = NotificationsRepositoryImpl(notificationsRemote);
    final movementsRepo = MovementsRepositoryImpl(movementsRemote);
    final inventoryRepo = InventoryRepositoryImpl(inventoryRemote);
    final supervisorDashboardRepo = SupervisorDashboardRepositoryImpl(
      remote: supervisorDashboardRemote,
      profileRepository: profileRepo,
    );

    final staffRepositories = StaffRepositories(
      dashboard: DashboardRepositoryImpl(
        dashboardRemote: dashboardRemote,
        tasksRemote: tasksRemote,
        inventoryRemote: inventoryRemote,
        movementsRemote: movementsRemote,
        productsRepository: productsRepo,
        ordersRepository: ordersRepo,
        notificationsRepository: notificationsRepo,
        auditRepository: AuditRepositoryImpl(auditRemote),
        warehousesRepository: WarehousesRepositoryImpl(warehousesRemote),
      ),
      supervisorDashboard: supervisorDashboardRepo,
      controlCenter: ControlCenterRepositoryImpl(
        supervisorDashboard: supervisorDashboardRepo,
        dashboardRemote: dashboardRemote,
        orders: ordersRepo,
        notifications: notificationsRepo,
        movements: movementsRepo,
      ),
      users: UsersRepositoryImpl(usersRemote),
      audit: AuditRepositoryImpl(auditRemote),
      reports: ReportsRepositoryImpl(reportsRemote),
      warehouses: WarehousesRepositoryImpl(warehousesRemote),
      tasks: TasksRepositoryImpl(tasksRemote),
      inventory: inventoryRepo,
      movements: movementsRepo,
      orders: ordersRepo,
      profile: profileRepo,
      notifications: notificationsRepo,
      products: productsRepo,
    );

    final authBloc = AuthBloc(
      restoreSession: RestoreSessionUseCase(authRepository),
      validateSession: ValidateSessionUseCase(authRepository),
      login: LoginUseCase(authRepository),
      logout: LogoutUseCase(authRepository),
    );

    unauthorizedHandler.onSessionExpired = () {
      debugPrint('[Auth] UnauthorizedHandler.notifySessionExpired() called');
      authBloc.add(const AuthSessionExpired());
    };

    final authRefreshNotifier = AuthRefreshNotifier();
    authBloc.stream.listen((authState) {
      if (kDebugMode) {
        debugPrint(
          '[Auth] Bloc state → status=${authState.status.name} '
          'user=${authState.user?.email ?? "null"} '
          'role=${authState.user?.role.name ?? "n/a"} '
          'loading=${authState.loadingType?.name ?? "n/a"}',
        );
      }
      authRefreshNotifier.notify();
    });

    final router = AppRouter.create(
      authBloc: authBloc,
      refreshListenable: authRefreshNotifier,
    );

    if (kDebugMode) {
      debugPrint(
        'Logistics WMS API [${ApiConfig.environmentLabel}]: ${ApiConfig.baseUrl}',
      );
      debugPrint('API logging: ${ApiConfig.enableRequestLogging}');
    }

    return AppDependencies(
      authBloc: authBloc,
      authRepository: authRepository,
      router: router,
      authRefreshNotifier: authRefreshNotifier,
      dio: dio,
      sessionStorage: sessionStorage,
      staffRepositories: staffRepositories,
      connectivity: connectivity,
      themeCubit: themeCubit,
      themePreferences: themePreferences,
    );
  }
}
