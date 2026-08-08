import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';
import 'package:logisticsmobile/features/dashboard/domain/repositories/dashboard_repository.dart';

class LoadStaffDashboardUseCase {
  const LoadStaffDashboardUseCase(this._repository);

  final DashboardRepository _repository;

  Future<StaffDashboardData> call() => _repository.loadStaffDashboard();
}
