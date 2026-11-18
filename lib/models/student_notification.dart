/// One localized private message from the MathWorld backend.
class StudentNotification {
  final int id;
  final String title;
  final String body;
  final String type;
  final String? actionPath;
  final DateTime createdAt;
  final bool isRead;

  const StudentNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.actionPath,
    required this.createdAt,
    required this.isRead,
  });

  factory StudentNotification.fromJson(Map<String, dynamic> json) {
    return StudentNotification(
      id: (json['Id'] as num).toInt(),
      title: (json['Title'] ?? '').toString(),
      body: (json['Body'] ?? '').toString(),
      type: (json['Type'] ?? 'announcement').toString(),
      actionPath: json['ActionPath']?.toString(),
      createdAt: DateTime.tryParse(json['CreatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isRead: json['IsRead'] == true,
    );
  }
}

class StudentNotificationPage {
  final List<StudentNotification> notifications;
  final int page;
  final int total;
  final bool hasMore;
  final int unreadCount;

  const StudentNotificationPage({
    required this.notifications,
    required this.page,
    required this.total,
    required this.hasMore,
    required this.unreadCount,
  });

  factory StudentNotificationPage.fromJson(Map<String, dynamic> json) {
    final raw = json['Notifications'] as List<dynamic>? ?? const [];
    return StudentNotificationPage(
      notifications: raw.whereType<Map>().map((item) =>
        StudentNotification.fromJson(Map<String, dynamic>.from(item))).toList(),
      page: (json['Page'] as num?)?.toInt() ?? 1,
      total: (json['Total'] as num?)?.toInt() ?? 0,
      hasMore: json['HasMore'] == true,
      unreadCount: (json['UnreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
