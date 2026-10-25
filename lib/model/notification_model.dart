
class NotificationModel {
  final int id;
  final String? title;
  final String? message;
  final bool isRead;
  final DateTime? createdAt;
  final String? type;

  const NotificationModel({
    required this.id,
    this.title,
    this.message,
    required this.isRead,
    this.createdAt,
    this.type,
  });

  // True when the notification has not been read.
  bool get isUnread => !isRead;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _toInt(json['id'] ?? json['notificationId']),
      title: json['title']?.toString(),
      message: (json['message'] ?? json['body'])?.toString(),
      isRead: _toBool(
        json['isRead'] ?? json['read'] ?? json['is_read'],
      ),
      createdAt: _toDate(
        json['createdAt'] ?? json['created_at'],
      ),
      type: json['type']?.toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString().toLowerCase() == 'true';
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
