import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/features/notifications/data/datasources/notifications_response_parser.dart';

void main() {
  group('NotificationsResponseParser', () {
    test('reads notifications from web-style envelope', () {
      final maps = NotificationsResponseParser.extractMaps({
        'notifications': [
          {
            '_id': '1',
            'title': 'User login',
            'message': 'rashka (Supervisor) signed in.',
            'type': 'system',
            'isRead': false,
            'createdAt': '2026-06-20T10:00:00.000Z',
            'performedBy': 'rashka',
          },
        ],
        'unreadCount': 41,
      });

      expect(maps, hasLength(1));
      final item = NotificationsResponseParser.mapNotification(maps.first);
      expect(item.title, 'User login');
      expect(item.read, isFalse);
      expect(item.performedBy, 'rashka');
      expect(item.categoryLabel, contains('SYSTEM'));
    });

    test('reads nested docs array', () {
      final maps = NotificationsResponseParser.extractMaps({
        'data': {
          'notifications': {
            'docs': [
              {
                'id': '2',
                'title': 'Low stock',
                'body': 'SKU-1 is low',
                'read': true,
              },
            ],
          },
          'unread_count': 3,
        },
      });

      expect(maps, hasLength(1));
      expect(NotificationsResponseParser.mapNotification(maps.first).read, isTrue);
    });
  });
}
