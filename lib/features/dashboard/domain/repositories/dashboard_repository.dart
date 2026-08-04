import 'package:logisticsmobile/features/dashboard/domain/entities/management_dashboard_data.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';

abstract class DashboardRepository {
  Future<StaffDashboardData> loadStaffDashboard();
  Future<ManagementDashboardData> loadManagementDashboard();
}