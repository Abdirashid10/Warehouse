import 'package:flutter/widgets.dart';
import 'package:logisticsmobile/features/audit/domain/repositories/audit_repository.dart';
import 'package:logisticsmobile/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:logisticsmobile/features/reports/domain/repositories/reports_repository.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/domain/repositories/supervisor_dashboard_repository.dart';
import 'package:logisticsmobile/features/users/domain/repositories/users_repository.dart';
import 'package:logisticsmobile/features/warehouses/domain/repositories/warehouses_repository.dart';
import 'package:logisticsmobile/features/dashboard/domain/repositories/control_center_repository.dart';
import 'package:logisticsmobile/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:logisticsmobile/features/orders/domain/repositories/orders_repository.dart';
import 'package:logisticsmobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:logisticsmobile/features/products/domain/repositories/products_repository.dart';
import 'package:logisticsmobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:logisticsmobile/features/stock_operations/domain/repositories/movements_repository.dart';
import 'package:logisticsmobile/features/tasks/domain/repositories/tasks_repository.dart';

/// Staff module repositories wired to the Logistics WMS API.
class StaffRepositories {
  const StaffRepositories({
    required this.dashboard,
    required this.supervisorDashboard,
    required this.controlCenter,
    required this.tasks,
    required this.inventory,
    required this.movements,
    required this.orders,
    required this.profile,
    required this.notifications,
    required this.products,
    required this.users,
    required this.audit,
    required this.reports,
    required this.warehouses,
  });

  final DashboardRepository dashboard;
  final SupervisorDashboardRepository supervisorDashboard;
  final ControlCenterRepository controlCenter;
  final UsersRepository users;
  final AuditRepository audit;
  final ReportsRepository reports;
  final WarehousesRepository warehouses;
  final TasksRepository tasks;
  final InventoryRepository inventory;
  final MovementsRepository movements;
  final OrdersRepository orders;
  final ProfileRepository profile;
  final NotificationsRepository notifications;
  final ProductsRepository products;
}

class StaffScope extends InheritedWidget {
  const StaffScope({
    super.key,
    required this.repositories,
    required super.child,
  });

  final StaffRepositories repositories;

  static StaffRepositories of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StaffScope>();
    assert(scope != null, 'StaffScope not found');
    return scope!.repositories;
  }

  @override
  bool updateShouldNotify(StaffScope oldWidget) =>
      repositories != oldWidget.repositories;
}
