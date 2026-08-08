import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/presentation/wms_inventory_refresh_bus.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/core/utils/task_workflow_utils.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';
import 'package:logisticsmobile/features/dashboard/domain/usecases/load_staff_dashboard_usecase.dart';
import 'package:logisticsmobile/features/dashboard/presentation/cubit/staff_dashboard_cubit.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/staff_operations_dashboard_body.dart';import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/routes/route_names.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Staff operations dashboard — mobile-first execution workspace.
class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen>
    with StaffScopeInitMixin {
  StaffDashboardCubit? _cubit;
  StaffRepositories? _repos;
  String? _selectedKpiFilter;
  StreamSubscription<void>? _refreshSubscription;

  static Color _backgroundColor(WmsUiColors colors) =>
      colors.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    _repos = repositories;
    _cubit = StaffDashboardCubit(
      LoadStaffDashboardUseCase(repositories.dashboard),
    )..load();
  }

  @override
  void initState() {
    super.initState();
    _refreshSubscription =
        WmsInventoryRefreshBus.instance.onRefresh.listen((_) {
      _cubit?.load();
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _cubit?.close();
    super.dispose();
  }

  Future<void> _handleTaskAction(
    BuildContext context,
    WarehouseTask task,
    TaskWorkflowAction action,
  ) async {
    final repos = _repos;
    final cubit = _cubit;
    if (repos == null || cubit == null) return;

    final colors = WmsUiColors.of(context);

    if (action.destructive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colors.surface,
          title: Text(action.label, style: TextStyle(color: colors.textPrimary)),
          content: Text(
            'Are you sure you want to ${action.label.toLowerCase()} "${task.title}"?',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: colors.error),
              child: Text(action.label),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    try {
      await repos.tasks.updateTaskStatus(
        id: task.id,
        status: action.targetStatus,
      );
      if (!context.mounted) return;
      await cubit.load();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task updated: ${action.label}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.success,
        ),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMessageMapper.fromApiException(e)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.error,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update task'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      return const Scaffold(body: StaffScopeLoadingBody());
    }

    final colors = WmsUiColors.of(context);
    final backgroundColor = _backgroundColor(colors);

    return ColoredBox(
      color: backgroundColor,
      child: BlocProvider.value(
        value: cubit,
        child: BlocBuilder<StaffDashboardCubit, ResourceState<StaffDashboardData>>(
          builder: (context, state) {
            if (state.isLoading && state.data == null) {
              return const Padding(
                padding: EdgeInsets.all(MobileUi.dashboardScreenPadding),
                child: WmsKpiSkeleton(),
              );
            }

            if (state.isFailure && state.data == null) {
              return WmsErrorState(
                message: state.message ?? 'Failed to load dashboard',
                onRetry: cubit.load,
              );
            }

            if (state.data == null) {
              return const SizedBox.shrink();
            }

            return RefreshIndicator(
              onRefresh: cubit.load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(MobileUi.dashboardScreenPadding),
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, auth) {
                    return StaffOperationsDashboardBody(
                      data: state.data!,
                      assignedWarehouseName: auth.user?.warehouse,
                      stockOpsRoute: RoutePaths.staffStockOperations,
                      ordersRoute: RoutePaths.staffOrders,
                      tasksRoute: RoutePaths.staffTasks,
                      inventoryRoute: RoutePaths.staffInventory,
                      reportsRoute: RoutePaths.staffReports,
                      notificationsRoute: RoutePaths.staffNotifications,
                      selectedKpiFilter: _selectedKpiFilter,
                      onKpiFilterTap: (filter) =>
                          setState(() => _selectedKpiFilter = filter),
                      onTaskAction: (task, action) =>
                          _handleTaskAction(context, task, action),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
