
import '../helper/api_constants.dart';
import '../model/notification_model.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService._();

  static Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
  }) async {
    final endpoint = unreadOnly
        ? '${ApiConstants.notifications}/unread'
        : ApiConstants.notifications;

    final data = await ApiClient.getList(endpoint);

    return data
        .map(
          (item) => NotificationModel.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();
  }

  static Future<int> getUnreadCount() async {
    final result = await ApiClient.getObject(
      '${ApiConstants.notifications}/unread/count',
    );

    // Supports either {"count": 3} or {"unreadCount": 3}.
    final value = result['count'] ?? result['unreadCount'];

    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Future<void> markAsRead(int notificationId) async {
    await ApiClient.patch(
      '${ApiConstants.notifications}/$notificationId/read',
    );
  }

  static Future<void> markAllAsRead() async {
    await ApiClient.patch(
      '${ApiConstants.notifications}/read-all',
    );
  }
}
