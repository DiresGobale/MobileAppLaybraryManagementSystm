class AppNotification {
  final int? id;
  final int userId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        title: m['title'] as String,
        message: m['message'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        isRead: (m['is_read'] as int) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'title': title,
        'message': message,
        'created_at': createdAt.millisecondsSinceEpoch,
        'is_read': isRead ? 1 : 0,
      };
}
