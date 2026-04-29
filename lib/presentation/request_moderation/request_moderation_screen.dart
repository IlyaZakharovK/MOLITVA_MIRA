import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shell/app_shell.dart';
import '../widgets/top_bar.dart';
import '../widgets/request_moderation_card.dart';
import 'request_moderation_controller.dart';

final RouteObserver<PageRoute<dynamic>> requestModerationRouteObserver =
RouteObserver<PageRoute<dynamic>>();

class RequestModerationScreen extends ConsumerStatefulWidget {
  const RequestModerationScreen({super.key});

  @override
  ConsumerState<RequestModerationScreen> createState() => _RequestModerationScreenState();
}

class _RequestModerationScreenState extends ConsumerState<RequestModerationScreen>
    with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      requestModerationRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    requestModerationRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() => _refreshCurrentTab();

  @override
  void didPopNext() => _refreshCurrentTab();

  void _refreshCurrentTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final statusId = ref.read(requestModerationStatusProvider);
      ref.read(requestModerationControllerProvider(statusId).notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusId = ref.watch(requestModerationStatusProvider);

    final st = ref.watch(requestModerationControllerProvider(statusId));
    final ctrl = ref.read(requestModerationControllerProvider(statusId).notifier);

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Запросы на молитву'),

            _TabsRow(
              value: statusId,
              onChanged: (v) {
                // ✅ как в StreamsScreen: меняем статус и обновляем ИМЕННО новый таб
                ref.read(requestModerationStatusProvider.notifier).state = v;
                ref.read(requestModerationControllerProvider(v).notifier).refresh();
              },
            ),

            Expanded(
              child: st.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : st.error != null
                  ? _ErrorBlock(error: st.error!, onRetry: ctrl.refresh)
                  : st.items.isEmpty
                  ? _EmptyBlock(onRefresh: ctrl.refresh)
                  : RefreshIndicator(
                onRefresh: ctrl.refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: st.items.length + (st.hasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i < st.items.length) {
                      final item = st.items[i];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: RequestModerationCard(
                          item: item,
                          statusId: statusId,
                          onBless: statusId == 1
                              ? () async {
                            try {
                              final res = await showDialog<bool>(
                                context: context,
                                barrierDismissible: true,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: const Text('Модерация молитвы'),
                                  content: const Text("Вы действительно желаете благословить эту молитву?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                      child: const Text('Нет'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),

                                      child: const Text('Да'),
                                    ),
                                  ],
                                ),
                              );

                              if (res == true) {
                                await ctrl.bless(item);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          }
                              : null,
                          onReject: statusId == 1
                              ? () async {
                            try {
                              final comment = await showDialog<String?>(
                                context: context,
                                barrierDismissible: true,
                                useSafeArea: false,
                                builder: (ctx) => const _RejectPrayerDialog(),
                              );
                              if (comment != null) {
                                await ctrl.reject(item, comment);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          }
                              : null,
                        ),
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

class _RejectPrayerDialog extends StatefulWidget {
  const _RejectPrayerDialog();

  @override
  State<_RejectPrayerDialog> createState() => _RejectPrayerDialogState();
}

class _RejectPrayerDialogState extends State<_RejectPrayerDialog> {
  late final TextEditingController _commentCtrl;

  @override
  void initState() {
    super.initState();
    _commentCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = (constraints.maxHeight - keyboard - 24)
                .clamp(240.0, constraints.maxHeight);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(18, 24, 18, keyboard + 16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 460,
                      maxHeight: availableHeight,
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Модерация молитвы',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Вы действительно желаете отклонить эту молитву?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _commentCtrl,
                              maxLength: 1000,
                              minLines: 3,
                              maxLines: 6,
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration(
                                hintText: 'Комментарий к отклонению',
                                alignLabelWithHint: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF3F4F86),
                                  ),
                                ),
                                counterStyle: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(null),
                                  child: const Text('Отмена'),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => Navigator.of(context)
                                      .pop(_commentCtrl.text.trim()),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  child: const Text('Отклонить'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TabsRow extends StatelessWidget {
  final int value; // statusId
  final ValueChanged<int> onChanged;

  const _TabsRow({
    required this.value,
    required this.onChanged,
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
            text: 'Новые',
            active: value == 1,
            onTap: () => onChanged(1),
          ),
          _TabChip(
            text: 'Благословленные',
            active: value == 2,
            onTap: () => onChanged(2),
          ),
          _TabChip(
            text: 'Отклоненные',
            active: value == 3,
            onTap: () => onChanged(3),
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
              'Запросов пока нет',
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
