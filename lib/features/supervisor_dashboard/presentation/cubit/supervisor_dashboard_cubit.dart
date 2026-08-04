import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/domain/usecases/load_supervisor_dashboard_usecase.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/presentation/cubit/supervisor_dashboard_state.dart';

class SupervisorDashboardCubit extends Cubit<SupervisorDashboardState> {
  SupervisorDashboardCubit(this._load) : super(const SupervisorDashboardState());

  final LoadSupervisorDashboardUseCase _load;

  Future<void> load() async {
    final previous = state.data;
    emit(
      SupervisorDashboardState(
        status: SupervisorDashboardStatus.loading,
        data: previous,
      ),
    );
    try {
      final data = await _load();
      if (data.isEffectivelyEmpty) {
        emit(
          SupervisorDashboardState(
            status: SupervisorDashboardStatus.empty,
            data: data,
          ),
        );
      } else {
        emit(
          SupervisorDashboardState(
            status: SupervisorDashboardStatus.success,
            data: data,
          ),
        );
      }
    } on ApiException catch (e) {
      emit(
        SupervisorDashboardState(
          status: SupervisorDashboardStatus.failure,
          data: previous,
          errorMessage: ErrorMessageMapper.fromApiException(e),
        ),
      );
    } catch (_) {
      emit(
        SupervisorDashboardState(
          status: SupervisorDashboardStatus.failure,
          data: previous,
          errorMessage: 'Failed to load supervisor dashboard',
        ),
      );
    }
  }
}
