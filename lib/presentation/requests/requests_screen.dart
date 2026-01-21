import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shell/app_shell.dart';

import '../../domain/profile/profile_role.dart';
import '../../domain/prayer_requests/request_status.dart';
import '../../domain/prayer_requests/prayer_request_item.dart';
import '../../domain/prayer_requests/requests_view_mode.dart';

import '../profile/profile_controller.dart';
import '../widgets/top_bar.dart';
import 'prayer_requests_controller.dart';

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(prayerRequestsControllerProvider);
    final profile = ref.watch(profileControllerProvider).value;

    final mode = _resolveMode(profile?.role);

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Запросы на молитву'),

            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
                data: (items) => RefreshIndicator(
                  onRefresh: () =>
                      ref.read(prayerRequestsControllerProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: items.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: mode == RequestsViewMode.moderation
                          ? _ModerationCard(
                        item: items[i],
                        onApprove: () => ref
                            .read(prayerRequestsControllerProvider.notifier)
                            .approve(items[i].id),
                        onReject: () => ref
                            .read(prayerRequestsControllerProvider.notifier)
                            .reject(items[i].id),
                      )
                          : _UserStatusCard(item: items[i]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  RequestsViewMode _resolveMode(ProfileRole? role) {
    if (role == ProfileRole.temple || role == ProfileRole.clergy) {
      return RequestsViewMode.moderation;
    }
    return RequestsViewMode.user;
  }
}

class _ModerationCard extends StatelessWidget {
  static const _blue = Color(0xFF1E5BFF);
  static const _red = Color(0xFFFF6B6B);

  final PrayerRequestItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ModerationCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final bg = item.isUrgent ? const Color(0xFFFFD58A) : Colors.white;

    return _BaseCard(
      background: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RowLine(
            label: 'Время:',
            value: item.isUrgent
                ? 'Как можно скорее'
                : _format(item.dateTime!),
          ),
          _RowLine(label: 'От кого:', value: item.fromName),
          _RowLine(label: 'Молитва:', value: item.categoryOrPrayer),
          _RowLine(label: 'Запрос:', value: item.text, maxLines: 4),

          const SizedBox(height: 12),

          if (item.status == RequestStatus.pending)
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    text: 'Одобрить',
                    color: _blue,
                    onTap: onApprove,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    text: 'Отклонить',
                    color: _red,
                    onTap: onReject,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _UserStatusCard extends StatelessWidget {
  final PrayerRequestItem item;
  const _UserStatusCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final bg = item.isUrgent ? const Color(0xFFFFD58A) : Colors.white;

    return _BaseCard(
      background: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RowLine(
            label: 'Время:',
            value: item.isUrgent
                ? 'Как можно скорее'
                : _format(item.dateTime!),
          ),
          _RowLine(label: 'Молитва:', value: item.categoryOrPrayer),
          _RowLine(label: 'Запрос:', value: item.text, maxLines: 4),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: _StatusPill(status: item.status),
          ),
        ],
      ),
    );
  }
}

class _BaseCard extends StatelessWidget {
  final Widget child;
  final Color background;

  const _BaseCard({
    required this.child,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            color: Color(0x14000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        onPressed: onTap,
        child: Text(text),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final RequestStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      RequestStatus.pending => (const Color(0xFFE6E6E6), Colors.black54),
      RequestStatus.approved => (const Color(0xFF1E5BFF), Colors.white),
      RequestStatus.rejected => (const Color(0xFFFF6B6B), Colors.white),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _RowLine extends StatelessWidget {
  final String label;
  final String value;
  final int? maxLines;

  const _RowLine({
    required this.label,
    required this.value,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72, // под твои подписи "От кого:"/"Утренгорящий:" можно увеличить
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _format(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.day)}.${two(dt.month)}.${dt.year}   ${two(dt.hour)}:${two(dt.minute)}';
}

