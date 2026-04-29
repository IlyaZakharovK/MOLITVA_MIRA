import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/help/help_chat_message_item.dart';
import '../shell/app_shell.dart';
import '../widgets/app_message_bar.dart';
import '../widgets/top_bar.dart';
import 'help_controller.dart';

class HelpChatScreen extends ConsumerStatefulWidget {
  const HelpChatScreen({super.key});

  @override
  ConsumerState<HelpChatScreen> createState() => _HelpChatScreenState();
}

class _HelpChatScreenState extends ConsumerState<HelpChatScreen> {
  late final TextEditingController _inputCtrl;
  late final ScrollController _scrollCtrl;
  late final FocusNode _focusNode;

  int _lastLen = 0;

  @override
  void initState() {
    super.initState();
    _inputCtrl = TextEditingController();
    _scrollCtrl = ScrollController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool jump = false}) {
    if (!_scrollCtrl.hasClients) return;

    final pos = _scrollCtrl.position.maxScrollExtent;
    if (jump) {
      _scrollCtrl.jumpTo(pos);
      return;
    }

    _scrollCtrl.animateTo(
      pos,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _onSend() async {
    final ctrl = ref.read(helpChatControllerProvider.notifier);
    final text = _inputCtrl.text;
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      showAppMessageBar(
        context,
        'Поле сообщения не должно быть пустым',
        brand: Colors.redAccent,
      );
      return;
    }

    if (trimmed.length > 500) {
      showAppMessageBar(
        context,
        'Сообщение не должно превышать 500 символов',
        brand: Colors.redAccent,
      );
      return;
    }

    try {
      await ctrl.sendMessage(trimmed);
      _inputCtrl.clear();
      _focusNode.requestFocus();
      if (!mounted) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (!mounted) return;
      showAppMessageBar(context, e.toString(), brand: Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(helpChatControllerProvider);

    if (st.messages.length != _lastLen) {
      _lastLen = st.messages.length;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(jump: _lastLen <= 3);
      });
    }

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Чат поддержки'),
            Expanded(
              child: Column(
                children: [
                  if (st.isRefreshing)
                    const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: st.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : st.error != null && st.messages.isEmpty
                        ? _ChatLoadError(
                            message: st.error!,
                            onRetry: () => ref
                                .read(helpChatControllerProvider.notifier)
                                .retry(),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(helpChatControllerProvider.notifier)
                                .refresh(),
                            child: st.isEmpty
                                ? const _EmptyChatState()
                                : ListView.builder(
                                    controller: _scrollCtrl,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      12,
                                    ),
                                    itemCount: st.messages.length,
                                    itemBuilder: (context, index) {
                                      final item = st.messages[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _ChatBubble(item: item),
                                      );
                                    },
                                  ),
                          ),
                  ),
                  _Composer(
                    controller: _inputCtrl,
                    focusNode: _focusNode,
                    isSending: st.isSending,
                    onSend: _onSend,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatLoadError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ChatLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42, color: Colors.black45),
            const SizedBox(height: 12),
            Text(
              'Ошибка: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => onRetry(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 80),
        Icon(Icons.mark_chat_read_outlined, size: 56, color: Colors.black38),
        SizedBox(height: 16),
        Text(
          'Сообщений пока нет',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Напишите первое сообщение в поддержку.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final HelpChatMessageItem item;

  const _ChatBubble({required this.item});

  @override
  Widget build(BuildContext context) {
    final isAdmin = item.senderAdmin;
    final align = isAdmin ? Alignment.centerLeft : Alignment.centerRight;
    final bubbleColor = isAdmin ? Colors.white : const Color(0xFF3F4F86);
    final textColor = isAdmin ? Colors.black87 : Colors.white;
    final authorColor = isAdmin ? const Color(0xFF3F4F86) : Colors.white70;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16),
            border: isAdmin ? Border.all(color: Colors.black12) : null,
            boxShadow: const [
              BoxShadow(
                blurRadius: 16,
                color: Color(0x12000000),
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: isAdmin
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: isAdmin
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
                children: [
                  if (item.senderAdmin) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/png/admin_avatar.png',
                        width: 20,
                        height: 20,
                      ),
                    ),
                    SizedBox(width: 5),
                  ],
                  Text(
                    (item.senderAdmin ? 'Администрация' : item.author) +
                        (item.dateAdd.trim().isNotEmpty
                            ? ' ${item.dateAdd}'
                            : ''),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: authorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            color: Color(0x14000000),
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final currentLen = value.text.trim().length;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                inputFormatters: [LengthLimitingTextInputFormatter(500)],
                decoration: InputDecoration(
                  hintText: 'Введите сообщение…',
                  counterText: '$currentLen/500',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF3F4F86)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3F4F86),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isSending ? null : onSend,
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Отправить'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
