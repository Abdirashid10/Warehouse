import 'package:equatable/equatable.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/domain/entities/supervisor_dashboard_data.dart';

enum SupervisorDashboardStatus { initial, loading, success, failure, empty }

class SupervisorDashboardState extends Equatable {
  const SupervisorDashboardState({
    this.status = SupervisorDashboardStatus.initial,
    this.data,
    this.errorMessage,
  });

  final SupervisorDashboardStatus status;
  final SupervisorDashboardData? data;
  final String? errorMessage;

  bool get isLoading => status == SupervisorDashboardStatus.loading;
  bool get isSuccess => status == SupervisorDashboardStatus.success;
  bool get isFailure => status == SupervisorDashboardStatus.failure;
  bool get isEmpty => status == SupervisorDashboardStatus.empty;

  SupervisorDashboardState copyWith({
    SupervisorDashboardStatus? status,
    SupervisorDashboardData? data,
    String? errorMessage,
  }) {
    return SupervisorDashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}
