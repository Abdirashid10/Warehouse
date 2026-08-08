import 'package:logisticsmobile/features/dashboard/domain/entities/management_dashboard_data.dart';
import 'package:logisticsmobile/features/dashboard/domain/repositories/dashboard_repository.dart';

class LoadManagementDashboardUseCase {
  const LoadManagementDashboardUseCase(this._repository);

  final DashboardRepository _repository;

  Future<ManagementDashboardData> call() => _repository.loadManagementDashboard();
}
