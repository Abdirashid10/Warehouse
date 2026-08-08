import 'package:logisticsmobile/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remote);

  final NotificationsRemoteDataSource _remote;

  @override
  Future<({List<AppNotification> items, int unreadCount})> getNotifications() =>
      _remote.fetchNotifications();
}
