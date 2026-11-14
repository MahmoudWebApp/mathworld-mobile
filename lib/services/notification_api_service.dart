import '../core/network/api_client.dart';

class UserNotice {
  const UserNotice({
    required this.id,
    required this.type,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.createdAtUtc,
    this.readAtUtc,
    this.targetPath,
  });

  final int id;
  final String type;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final DateTime createdAtUtc;
  final DateTime? readAtUtc;
  final String? targetPath;

  bool get isUnread => readAtUtc == null;

  factory UserNotice.fromJson(Map<String, dynamic> json) => UserNotice(
        id: (json['Id'] as num).toInt(),
        type: json['Type'] as String? ?? 'system',
        titleAr: json['TitleAr'] as String? ?? '',
        titleEn: json['TitleEn'] as String? ?? '',
        bodyAr: json['BodyAr'] as String? ?? '',
        bodyEn: json['BodyEn'] as String? ?? '',
        createdAtUtc: DateTime.tryParse(json['CreatedAtUtc'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        readAtUtc: DateTime.tryParse(json['ReadAtUtc'] as String? ?? ''),
        targetPath: json['TargetPath'] as String?,
      );
}

class NotificationInbox {
  const NotificationInbox({
    required this.items,
    required this.unreadCount,
    required this.totalCount,
    required this.hasMore,
    required this.skip,
  });

  final List<UserNotice> items;
  final int unreadCount;
  final int totalCount;
  final bool hasMore;
  final int skip;

  factory NotificationInbox.fromJson(Map<String, dynamic> json) {
    final items = (json['Items'] as List<dynamic>? ?? const [])
        .map((item) => UserNotice.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList(growable: false);
    return NotificationInbox(
      items: items,
      unreadCount: (json['UnreadCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['TotalCount'] as num?)?.toInt() ?? items.length,
      hasMore: json['HasMore'] as bool? ?? false,
      skip: (json['Skip'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Same authenticated 30-day inbox as Next.js, with no fabricated messages.
class NotificationApiService {
  const NotificationApiService(this._client);

  final ApiClient _client;

  Future<NotificationInbox> getInbox({int take = 30, int skip = 0}) async {
    if (take < 1 || take > 50 || skip < 0 || skip > 10000) {
      throw ArgumentError('Invalid inbox pagination');
    }
    final response = await _client.get('/notifications', queryParameters: {
      'take': take,
      'skip': skip,
    });
    final envelope = Map<String, dynamic>.from(response.data as Map);
    return NotificationInbox.fromJson(
      Map<String, dynamic>.from(envelope['Data'] as Map),
    );
  }

  Future<void> markRead(int id) async {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive');
    await _client.put('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _client.put('/notifications/read-all');
  }
}
