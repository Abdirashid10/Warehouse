import 'package:logisticsmobile/features/reports/data/datasources/reports_remote_data_source.dart';
import 'package:logisticsmobile/features/reports/domain/entities/wms_reports_data.dart';
import 'package:logisticsmobile/features/reports/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._remote);

  final ReportsRemoteDataSource _remote;

  @override
  Future<WmsReportsData> loadReports() => _remote.fetchReports();
}
