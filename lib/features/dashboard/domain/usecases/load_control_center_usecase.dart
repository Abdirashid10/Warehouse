import 'package:logisticsmobile/features/dashboard/domain/entities/control_center_data.dart';
import 'package:logisticsmobile/features/dashboard/domain/repositories/control_center_repository.dart';

class LoadControlCenterUseCase {
  const LoadControlCenterUseCase(this._repository);

  final ControlCenterRepository _repository;

  Future<ControlCenterData> call() => _repository.load();
}
