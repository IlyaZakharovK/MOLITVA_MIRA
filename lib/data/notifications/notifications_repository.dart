import '../../domain/notifications/notification_item.dart';
import '../../domain/notifications/notifications_repository.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  @override
  Future<List<NotificationItem>> fetchNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 650)); // имитация сети

    return [
      NotificationItem(
        id: '1',
        title:
        'Сегодня в 10:00\nПодача заявок на совместные\nмолитвы по храмам на "Молитва Мира".',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationItem(
        id: '2',
        title: 'Новая запись',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      NotificationItem(
        id: '3',
        title: 'Новая запись',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
