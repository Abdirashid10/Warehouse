import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/network/json_list_parser.dart';
import 'package:logisticsmobile/features/notifications/data/datasources/notifications_response_parser.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<({List<AppNotification> items, int unreadCount})> fetchNotifications() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.notifications);
      final root = JsonListParser.extractMap(response.data) ?? {};
      final maps = NotificationsResponseParser.extractMaps(response.data);
      final unread = NotificationsResponseParser.readUnreadCount(root, response.data);

      final items = maps.map(NotificationsResponseParser.mapNotification).toList();

      return (
        items: items,
        unreadCount: unread,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }
}
