import 'package:logisticsmobile/core/network/json_list_parser.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';

/// Parses `/notifications` API payloads into domain models.
abstract final class NotificationsResponseParser {
  static List<Map<String, dynamic>> extractMaps(dynamic data) {
    final direct = JsonListParser.extractMaps(
      data,
      keys: ['notifications', 'items', 'results', 'docs', 'data'],
    );
    if (direct.isNotEmpty) return direct;

    final root = JsonListParser.extractMap(data) ?? {};
    final nested = root['notifications'];
    if (nested is List) return _coerceMaps(nested);
    if (nested is Map) {
      for (final key in const ['docs', 'items', 'results', 'data', 'notifications']) {
        final value = nested[key];
        if (value is List) {
          final maps = _coerceMaps(value);
          if (maps.isNotEmpty) return maps;
        }
      }
    }

    if (data is List) return _coerceMaps(data);
    return [];
  }

  static int readUnreadCount(Map<String, dynamic> root, dynamic raw) {
    final candidates = [
      root['unreadCount'],
      root['unread_count'],
      root['unread'],
    ];
    if (raw is Map<String, dynamic>) {
      candidates.addAll([
        raw['unreadCount'],
        raw['unread_count'],
        raw['unread'],
      ]);
    }
    for (final value in candidates) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse('$value');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static AppNotification mapNotification(Map<String, dynamic> json) {
    final read = json['read'] == true ||
        json['isRead'] == true ||
        json['is_read'] == true;

    return AppNotification(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? json['subject'] ?? json['type'] ?? 'Notification')
          .toString(),
      message: (json['message'] ?? json['body'] ?? json['description'] ?? '')
          .toString(),
      type: (json['type'] ?? json['kind'] ?? 'info').toString(),
      read: read,
      createdAt: DateTime.tryParse(
        (json['createdAt'] ??
                json['created_at'] ??
                json['timestamp'] ??
                json['date'] ??
                '')
            .toString(),
      ),
      category: (json['category'] ?? json['module'] ?? json['type'])?.toString(),
      performedBy: (json['performedBy'] ??
              json['performed_by'] ??
              json['actor'] ??
              json['userName'] ??
              json['username'] ??
              json['createdBy'] ??
              json['created_by'])
          ?.toString(),
    );
  }

  static List<Map<String, dynamic>> _coerceMaps(List<dynamic> list) {
    return list
        .map((entry) {
          if (entry is Map<String, dynamic>) return entry;
          if (entry is Map) return Map<String, dynamic>.from(entry);
          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
