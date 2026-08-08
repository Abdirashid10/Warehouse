import 'package:logisticsmobile/features/audit/domain/entities/audit_activity.dart';

abstract class AuditRepository {
  Future<AuditPage> getActivities({
    int page = 1,
    int limit = 25,
    String? query,
    String? module,
  });
}
