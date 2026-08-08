import 'package:logisticsmobile/features/supervisor_dashboard/domain/entities/supervisor_dashboard_data.dart';

abstract class SupervisorDashboardRepository {
  Future<SupervisorDashboardData> loadDashboard();
}
