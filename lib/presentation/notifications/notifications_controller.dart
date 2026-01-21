import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/notifications/notification_item.dart';
import '../../domain/notifications/notifications_repository.dart';
import '../../providers.dart';

final notificationsControllerProvider =
AsyncNotifierProvider<NotificationsController, List<NotificationItem>>(
  NotificationsController.new,
);

class NotificationsController extends AsyncNotifier<List<NotificationItem>> {
  late final NotificationsRepository _repo;

  @override
  Future<List<NotificationItem>> build() async {
    _repo = ref.watch(notificationsRepositoryProvider);
    return _repo.fetchNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.fetchNotifications());
  }
}
