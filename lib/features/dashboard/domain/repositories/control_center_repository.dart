import 'package:logisticsmobile/features/dashboard/domain/entities/control_center_data.dart';

abstract class ControlCenterRepository {
  Future<ControlCenterData> load();
}
