import 'package:logisticsmobile/features/audit/data/datasources/audit_remote_data_source.dart';
import 'package:logisticsmobile/features/audit/domain/entities/audit_activity.dart';
import 'package:logisticsmobile/features/audit/domain/repositories/audit_repository.dart';

class AuditRepositoryImpl implements AuditRepository {
  AuditRepositoryImpl(this._remote);

  final AuditRemoteDataSource _remote;

  @override
  Future<AuditPage> getActivities({
    int page = 1,
    int limit = 25,
    String? query,
    String? module,
  }) =>
      _remote.fetchActivities(
        page: page,
        limit: limit,
        query: query,
        module: module,
      );
}
