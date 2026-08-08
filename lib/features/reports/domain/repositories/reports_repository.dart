import 'package:logisticsmobile/features/reports/domain/entities/wms_reports_data.dart';

abstract class ReportsRepository {
  Future<WmsReportsData> loadReports();
}
