import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shell/app_shell.dart';
import '../widgets/burger_button.dart';
import '../widgets/top_bar.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsControllerProvider);

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Уведомления'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
                data: (items) => RefreshIndicator(
                  onRefresh: () => ref.read(notificationsControllerProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final n = items[i];
                      return _NotificationCard(
                        title: n.title,
                        timeText: _formatTime(n.createdAt),
                        onTap: () {},
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    // Легкая заглушка под дизайн: "Сегодня 10:00" / "Вчера 18:30"
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);

    String hhmm(int v) => v.toString().padLeft(2, '0');
    final time = '${hhmm(dt.hour)}:${hhmm(dt.minute)}';

    if (d == today) return 'Сегодня $time';
    if (d == today.subtract(const Duration(days: 1))) return 'Вчера $time';
    return '${hhmm(dt.day)}.${hhmm(dt.month)}.${dt.year} $time';
  }
}


class _NotificationCard extends StatelessWidget {
  final String title;
  final String timeText;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.title,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 20,
              color: Color(0x14000000),
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // время голубоватым
            Text(
              timeText,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E5BFF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
