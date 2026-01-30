import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/streams/stream_type.dart';
import '../../domain/streams/stream_status.dart';
import '../shell/app_shell.dart';
import '../widgets/stream_card.dart';
import '../widgets/top_bar.dart';
import 'streams_controller.dart';

final RouteObserver<PageRoute<dynamic>> streamsRouteObserver =
RouteObserver<PageRoute<dynamic>>();

class StreamsScreen extends ConsumerStatefulWidget {
  final bool my;

  /// ✅ если задано — при открытии экрана выберем этот таб и перезагрузим данные
  final StreamStatus? initialStatus;

  const StreamsScreen({
    super.key,
    this.my = false,
    this.initialStatus,
  });

  @override
  ConsumerState<StreamsScreen> createState() => _StreamsScreenState();
}

class _StreamsScreenState extends ConsumerState<StreamsScreen> with RouteAware {
  bool _appliedInitial = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      streamsRouteObserver.subscribe(this, route);
    }

    // ✅ применяем initialStatus один раз при первом заходе
    if (!_appliedInitial && widget.initialStatus != null) {
      _appliedInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        ref.read(streamsStatusProvider(widget.my).notifier).state =
        widget.initialStatus!;

        final key = (my: widget.my, status: widget.initialStatus!);
        ref.read(streamsControllerProvider(key).notifier).refresh();
      });
    }
  }

  @override
  void dispose() {
    streamsRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() => _refreshCurrentTab();

  @override
  void didPopNext() => _refreshCurrentTab();

  void _refreshCurrentTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final status = ref.read(streamsStatusProvider(widget.my));
      final key = (my: widget.my, status: status);

      // ✅ перезагрузка при входе/возврате на экран
      ref.read(streamsControllerProvider(key).notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(streamsStatusProvider(widget.my));

    final key = (my: widget.my, status: status);
    final st = ref.watch(streamsControllerProvider(key));
    final ctrl = ref.read(streamsControllerProvider(key).notifier);

    final visibleItems = widget.my
        ? st.items
        : st.items
        .where((e) =>
    e.type_id != StreamType.closed && e.type_id != StreamType.family)
        .toList(growable: false);

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            TopBar(title: widget.my ? 'Мои трансляции' : 'Трансляции'),

            _TabsRow(
              value: status,
              my: widget.my,
              onChanged: (v) {
                // ✅ ВСЕГДА перезапрашиваем при любом переходе по табу
                ref.read(streamsStatusProvider(widget.my).notifier).state = v;

                final nextKey = (my: widget.my, status: v);
                ref.read(streamsControllerProvider(nextKey).notifier).refresh();
              },
            ),

            Expanded(
              child: st.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : st.error != null
                  ? _ErrorBlock(error: st.error!, onRetry: ctrl.refresh)
                  : visibleItems.isEmpty
                  ? _EmptyBlock(onRefresh: ctrl.refresh)
                  : RefreshIndicator(
                onRefresh: ctrl.refresh,
                child: ListView.builder(
                  padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount:
                  visibleItems.length + (st.hasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i < visibleItems.length) {
                      return Padding(
                        padding:
                        const EdgeInsets.only(bottom: 16),
                        child: StreamCard(item: visibleItems[i]),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(
                          top: 4, bottom: 24),
                      child: Center(
                        child: st.isLoadingMore
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                            : OutlinedButton(
                          onPressed: ctrl.loadMore,
                          child:
                          const Text('Подгрузить ещё'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyBlock({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Трансляций пока нет',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => onRefresh(),
              child: const Text('Обновить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;

  const _ErrorBlock({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ошибка: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFF6A00),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => onRetry(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabsRow extends StatelessWidget {
  final StreamStatus value;
  final ValueChanged<StreamStatus> onChanged;
  final bool my;

  const _TabsRow({
    required this.value,
    required this.onChanged,
    required this.my,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _TabChip(
            text: StreamStatus.active.label,
            active: value == StreamStatus.active,
            onTap: () => onChanged(StreamStatus.active),
          ),
          _TabChip(
            text: StreamStatus.planned.label,
            active: value == StreamStatus.planned,
            onTap: () => onChanged(StreamStatus.planned),
          ),
          if (my)
            _TabChip(
              text: StreamStatus.finished.label,
              active: value == StreamStatus.finished,
              onTap: () => onChanged(StreamStatus.finished),
            ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active ? const Color(0xFF3F4F86) : Colors.white;
    final fg = active ? Colors.white : Colors.black54;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}
