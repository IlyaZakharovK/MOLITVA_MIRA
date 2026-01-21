import 'notification_item.dart';

abstract class NotificationsRepository {
  Future<List<NotificationItem>> fetchNotifications();
}
