import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/constants/app_constants.dart';
import 'package:logisticsmobile/core/di/injection_container.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/settings/theme_cubit.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/widgets/auth_failure_listener.dart';
import 'package:logisticsmobile/core/utils/overflow_safe.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/widgets/connectivity_scope.dart';
import 'package:logisticsmobile/widgets/offline_banner.dart';

class LogisticsApp extends StatelessWidget {
  const LogisticsApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: dependencies.authBloc),
        BlocProvider<ThemeCubit>.value(value: dependencies.themeCubit),
      ],
      child: StaffScope(
        repositories: dependencies.staffRepositories,
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp.router(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeState.themeMode,
              routerConfig: dependencies.router,
              builder: (context, child) {
                final clamped = MobileUi.clampMediaQuery(MediaQuery.of(context));
                return MediaQuery(
                  data: clamped,
                  child: ConnectivityScope(
                    connectivity: dependencies.connectivity,
                    child: AuthFailureListener(
                      child: OfflineBanner(
                        connectivity: dependencies.connectivity,
                        child: OverflowSafe.host(
                          child ?? const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
