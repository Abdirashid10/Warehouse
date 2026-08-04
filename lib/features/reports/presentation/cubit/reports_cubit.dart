import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/reports/domain/entities/wms_reports_data.dart';
import 'package:logisticsmobile/features/reports/domain/repositories/reports_repository.dart';

class ReportsCubit extends Cubit<ResourceState<WmsReportsData>> {
  ReportsCubit(this._repository) : super(const ResourceState.initial());

  final ReportsRepository _repository;

  Future<void> load() async {
    emit(const ResourceState.loading());
    try {
      final data = await _repository.loadReports();
      emit(ResourceState.success(data));
    } on ApiException catch (e) {
      emit(ResourceState.failure(ErrorMessageMapper.fromApiException(e)));
    } catch (_) {
      emit(const ResourceState.failure('Failed to load reports'));
    }
  }

  Future<void> refresh() => load();
}
