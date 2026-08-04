import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/control_center_data.dart';
import 'package:logisticsmobile/features/dashboard/domain/usecases/load_control_center_usecase.dart';

class ControlCenterCubit extends Cubit<ResourceState<ControlCenterData>> {
  ControlCenterCubit(this._load) : super(const ResourceState.initial());

  final LoadControlCenterUseCase _load;

  Future<void> load() async {
    emit(ResourceState.loading(data: state.data));
    try {
      final data = await _load();
      emit(ResourceState.success(data));
    } on ApiException catch (e) {
      emit(ResourceState.failure(
        ErrorMessageMapper.fromApiException(e),
        data: state.data,
      ));
    } catch (_) {
      emit(ResourceState.failure(
        'Failed to load control center',
        data: state.data,
      ));
    }
  }
}
