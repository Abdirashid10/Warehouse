import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/features/dashboard/data/mappers/staff_control_center_mapper.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/staff_dashboard_header.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/warehouse_control_center_body.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/core/utils/task_workflow_utils.dart';

/// **Deprecated for staff users** — maps staff data into the admin/supervisor
/// [WarehouseControlCenterBody]. Staff dashboard uses
/// [StaffOperationsDashboardBody] instead.
///
/// Staff mobile dashboard — web-parity section order with responsive layout.
class StaffMobileDashboardScroll extends StatelessWidget {
  const StaffMobileDashboardScroll({
    super.key,
    required this.data,
    required this.assignedWarehouseName,
    required this.stockOpsRoute,
    required this.ordersRoute,
    required this.tasksRoute,
    required this.inventoryRoute,
    required this.reportsRoute,
    required this.notificationsRoute,
    required this.onTaskAction,
    this.selectedKpiFilter,
    this.onKpiFilterTap,
  });

  final StaffDashboardData data;
  final String? assignedWarehouseName;
  final String stockOpsRoute;
  final String ordersRoute;
  final String tasksRoute;
  final String inventoryRoute;
  final String reportsRoute;
  final String notificationsRoute;
  final void Function(WarehouseTask task, TaskWorkflowAction action) onTaskAction;
  final String? selectedKpiFilter;
  final ValueChanged<String?>? onKpiFilterTap;

  static const _gap = MobileUi.dashboardSectionGap;

  @override
  Widget build(BuildContext context) {
    final controlData = StaffControlCenterMapper.fromStaffData(data);
    final body = WarehouseControlCenterBody(
      data: controlData,
      inventoryRoute: inventoryRoute,
      tasksRoute: tasksRoute,
      ordersRoute: ordersRoute,
      notificationsRoute: notificationsRoute,
      stockOpsRoute: stockOpsRoute,
    );
    final sections = body.buildSections(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StaffDashboardHeader(
          assignedWarehouseName: assignedWarehouseName,
          stockOpsRoute: stockOpsRoute,
          ordersRoute: ordersRoute,
          tasksRoute: tasksRoute,
          reportsRoute: reportsRoute,
          onNavigate: (route, {replace = false}) {
            if (replace) {
              context.go(route);
            } else {
              context.push(route);
            }
          },
        ),
        const SizedBox(height: _gap),
        for (var i = 0; i < sections.length; i++) ...[
          sections[i],
          if (i < sections.length - 1) const SizedBox(height: _gap),
        ],
      ],
    );
  }
}
