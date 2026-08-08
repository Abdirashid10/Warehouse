import 'package:logisticsmobile/features/supervisor_dashboard/domain/entities/supervisor_dashboard_data.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/domain/repositories/supervisor_dashboard_repository.dart';

class LoadSupervisorDashboardUseCase {
  const LoadSupervisorDashboardUseCase(this._repository);

  final SupervisorDashboardRepository _repository;

  Future<SupervisorDashboardData> call() => _repository.loadDashboard();
}
