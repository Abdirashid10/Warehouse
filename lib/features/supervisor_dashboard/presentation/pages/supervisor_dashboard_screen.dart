import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/presentation/wms_inventory_refresh_bus.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/control_center_data.dart';
import 'package:logisticsmobile/features/dashboard/domain/usecases/load_control_center_usecase.dart';
import 'package:logisticsmobile/features/dashboard/presentation/cubit/control_center_cubit.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/dashboard_backend_status.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/mobile_web_dashboard_scroll.dart';
import 'package:logisticsmobile/routes/route_names.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';

/// Supervisor warehouse command center — web-parity stacked mobile layout.
class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key, this.forAdmin = false});

  final bool forAdmin;

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen>
    with StaffScopeInitMixin {
  ControlCenterCubit? _cubit;
  DateTime? _lastSyncedAt;
  StreamSubscription<void>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _refreshSubscription =
        WmsInventoryRefreshBus.instance.onRefresh.listen((_) {
      _cubit?.load();
    });
  }

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    _cubit = ControlCenterCubit(
      LoadControlCenterUseCase(repositories.controlCenter),
    )..load();
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      return const Scaffold(body: StaffScopeLoadingBody());
    }

    return BlocProvider.value(
      value: cubit,
      child: BlocListener<ControlCenterCubit, ResourceState<ControlCenterData>>(
        listenWhen: (prev, curr) =>
            curr.data != null && !curr.isLoading && !curr.isFailure,
        listener: (_, __) => setState(() => _lastSyncedAt = DateTime.now()),
        child: BlocBuilder<ControlCenterCubit, ResourceState<ControlCenterData>>(
          builder: (context, state) {
            if (state.isLoading && state.data == null) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: WmsKpiSkeleton(),
              );
            }

            if (state.isFailure && state.data == null) {
              return DashboardBackendError(
                message: state.message ??
                    'Failed to load command center from backend',
                onRetry: cubit.load,
              );
            }

            final data = state.data;
            if (data == null) {
              return const SizedBox.shrink();
            }

            return MobileWebDashboardScroll(
              data: data,
              onRefresh: cubit.load,
              forAdmin: widget.forAdmin,
              lastSyncedAt: _lastSyncedAt,
              isLoading: state.isLoading,
              warningMessage: state.isFailure ? state.message : null,
              inventoryRoute: widget.forAdmin
                  ? RoutePaths.adminInventory
                  : RoutePaths.supervisorInventory,
              tasksRoute: widget.forAdmin
                  ? RoutePaths.adminTasks
                  : RoutePaths.supervisorTasks,
              ordersRoute: widget.forAdmin
                  ? RoutePaths.adminOrders
                  : RoutePaths.supervisorOrders,
              notificationsRoute: widget.forAdmin
                  ? RoutePaths.adminNotifications
                  : RoutePaths.supervisorNotifications,
              stockOpsRoute: widget.forAdmin
                  ? RoutePaths.adminStockOperations
                  : RoutePaths.supervisorStockOperations,
              reportsRoute: widget.forAdmin
                  ? RoutePaths.adminReports
                  : RoutePaths.supervisorReports,
              auditRoute: widget.forAdmin
                  ? RoutePaths.adminAudit
                  : RoutePaths.supervisorAudit,
            );
          },
        ),
      ),
    );
  }
}
