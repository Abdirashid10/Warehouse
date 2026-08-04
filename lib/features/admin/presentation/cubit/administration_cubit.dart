import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/audit/domain/entities/audit_activity.dart'
    show AuditActivity, AuditPage;
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';

class AdministrationBundle {
  const AdministrationBundle({
    required this.users,
    required this.warehouses,
    required this.auditActivities,
    required this.auditTotal,
    required this.notifications,
    required this.unreadCount,
  });

  final List<WmsUser> users;
  final List<Warehouse> warehouses;
  final List<AuditActivity> auditActivities;
  final int auditTotal;
  final List<AppNotification> notifications;
  final int unreadCount;

  int userCountForRole(String role) =>
      users.where((u) => !u.archived && u.role == role).length;
}

class AdministrationCubit extends Cubit<ResourceState<AdministrationBundle>> {
  AdministrationCubit(this._repos) : super(const ResourceState.initial());

  final StaffRepositories _repos;

  Future<void> load() async {
    emit(const ResourceState.loading());
    try {
      final results = await Future.wait([
        _repos.users.getUsers(),
        _repos.warehouses.getWarehouses(),
        _repos.audit.getActivities(page: 1, limit: 50),
        _repos.notifications.getNotifications(),
      ]);

      final auditPage = results[2] as AuditPage;
      final notifications =
          results[3] as ({List<AppNotification> items, int unreadCount});

      emit(
        ResourceState.success(
          AdministrationBundle(
            users: results[0] as List<WmsUser>,
            warehouses: results[1] as List<Warehouse>,
            auditActivities: auditPage.activities,
            auditTotal: auditPage.total,
            notifications: notifications.items,
            unreadCount: notifications.unreadCount,
          ),
        ),
      );
    } on ApiException catch (e) {
      emit(ResourceState.failure(ErrorMessageMapper.fromApiException(e)));
    } catch (_) {
      emit(const ResourceState.failure('Failed to load administration data'));
    }
  }

  Future<void> refresh() => load();
}
