import 'package:flutter_test/flutter_test.dart';

import 'package:mathworld_mobile/services/notification_api_service.dart';

void main() {
  Map<String, dynamic> sampleNotice(int id, {bool unread = true}) => {
        'Id': id,
        'Type': 'admin',
        'TitleAr': 'عنوان $id',
        'TitleEn': 'Notice $id',
        'BodyAr': 'تفاصيل',
        'BodyEn': 'Details',
        'CreatedAtUtc': '2026-11-14T10:00:00Z',
        'ReadAtUtc': unread ? null : '2026-11-14T10:30:00Z',
        'TargetPath': '/dashboard',
      };

  test('parses full 30-day inbox pagination and unread state', () {
    final response = NotificationInbox.fromJson({
      'Items': [sampleNotice(42), sampleNotice(41, unread: false)],
      'UnreadCount': 9,
      'TotalCount': 70,
      'HasMore': true,
      'Skip': 30,
      'Take': 30,
    });

    expect(response.items.map((item) => item.id), [42, 41]);
    expect(response.totalCount, 70);
    expect(response.unreadCount, 9);
    expect(response.hasMore, isTrue);
    expect(response.skip, 30);
    expect(response.items.first.isUnread, isTrue);
    expect(response.items.last.isUnread, isFalse);
    expect(response.items.first.createdAtUtc.isUtc, isTrue);
  });

  test('accepts the older first-page inbox response without pagination', () {
    final response = NotificationInbox.fromJson({
      'Items': [sampleNotice(7)],
      'UnreadCount': 1,
    });
    expect(response.items.single.id, 7);
    expect(response.totalCount, 1);
    expect(response.hasMore, isFalse);
    expect(response.skip, 0);
  });

  test('parses empty final page and a fully read inbox', () {
    final response = NotificationInbox.fromJson({
      'Items': <Object>[],
      'UnreadCount': 0,
      'TotalCount': 60,
      'HasMore': false,
      'Skip': 60,
      'Take': 30,
    });
    expect(response.items, isEmpty);
    expect(response.hasMore, isFalse);
    expect(response.skip, 60);
    expect(response.totalCount, 60);
  });
}
