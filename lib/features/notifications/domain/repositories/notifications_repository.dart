import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationsRepository {
  Future<({List<AppNotification> items, int unreadCount})> getNotifications();
}
