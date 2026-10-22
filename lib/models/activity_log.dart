class ActivityLog {
  final int? id;
  final int? userId;
  final String action;
  final String? details;
  final DateTime createdAt;

  ActivityLog({
    this.id,
    this.userId,
    required this.action,
    this.details,
    required this.createdAt,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> m) => ActivityLog(
        id: m['id'] as int?,
        userId: m['user_id'] as int?,
        action: m['action'] as String,
        details: m['details'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'action': action,
        'details': details,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}
