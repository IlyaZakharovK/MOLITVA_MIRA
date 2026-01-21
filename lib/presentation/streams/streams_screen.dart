import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shell/app_shell.dart';
import '../../domain/streams/streams_item.dart';
import '../../domain/streams/stream_status.dart';
import '../widgets/top_bar.dart';
import 'streams_controller.dart';

class StreamsScreen extends ConsumerWidget {
  final bool my;
  const StreamsScreen({super.key, this.my = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(streamsStatusProvider(my));

    final key = (my: my, status: status);
    final st = ref.watch(streamsControllerProvider(key));
    final ctrl = ref.read(streamsControllerProvider(key).notifier);

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            TopBar(title: my ? 'Мои трансляции' : 'Трансляции'),
            _TabsRow(
              value: status,
              onChanged: (v) => ref.read(streamsStatusProvider(my).notifier).state = v,
              my: my,
            ),
            Expanded(
              child: st.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : st.error != null
                  ? _ErrorBlock(
                error: st.error!,
                onRetry: ctrl.refresh,
              )
                  : st.items.isEmpty
                  ? const _EmptyBlock()
                  : RefreshIndicator(
                onRefresh: ctrl.refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: st.items.length + (st.hasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i < st.items.length) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _StreamCard(item: st.items[i]),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      child: Center(
                        child: st.isLoadingMore
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : OutlinedButton(
                          onPressed: ctrl.loadMore,
                          child: const Text('Подгрузить ещё'),
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
              style: const TextStyle(color: Color(0xFFFF6A00), fontWeight: FontWeight.w700),
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


  const _TabsRow({required this.value, required this.onChanged, required this.my});

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
          if (my)...{
          _TabChip(
            text: StreamStatus.finished.label,
            active: value == StreamStatus.finished,
            onTap: () => onChanged(StreamStatus.finished),
          )
          }
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

class _StreamCard extends StatelessWidget {
  final StreamItem item;
  const _StreamCard({required this.item});

  static const _blue = Color(0xFF3F4F86);

  String _fmt(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} / ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final statusText = item.status.label;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            color: Color(0x14000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.description.isEmpty ? 'Без описания' : item.description,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Colors.black38),
              const SizedBox(width: 6),
              Text(
                _fmt(item.startAt),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
              if (item.status == StreamStatus.active) ... {
                const Spacer(),
                SizedBox(
                  height: 34,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(
                          '/live_stream');
                    },
                    child: Text('Открыть'),
                  ),
                ),
              }
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Трансляций пока нет',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}

