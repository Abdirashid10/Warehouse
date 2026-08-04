import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';
import 'package:logisticsmobile/features/dashboard/domain/usecases/load_staff_dashboard_usecase.dart';

class StaffDashboardCubit extends Cubit<ResourceState<StaffDashboardData>> {
  StaffDashboardCubit(this._load) : super(const ResourceState.initial());

  final LoadStaffDashboardUseCase _load;

  Future<void> load() async {
    emit(const ResourceState.loading());
    try {
      final data = await _load();
      emit(ResourceState.success(data));
    } on ApiException catch (e) {
      emit(ResourceState.failure(ErrorMessageMapper.fromApiException(e)));
    } catch (_) {
      emit(const ResourceState.failure('Failed to load dashboard'));
    }
  }
}
