import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/streaming/chat_message.dart';
import 'live_stream_controller.dart';

class LiveStreamScreen extends ConsumerStatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  ConsumerState<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends ConsumerState<LiveStreamScreen> {
  static const _blue = Color(0xFF1E5BFF);

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _muted = false;
  bool _micOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      endDrawer: const _StreamChatDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            // ======== VIDEO PLACEHOLDER (WS-stream later) ========
            Positioned.fill(
              child: Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.wifi_tethering, size: 54, color: Colors.white70),
                    SizedBox(height: 10),
                    Text(
                      'WS трансляция (заглушка)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ======== Bottom Controls ========
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: _BottomControls(
                  muted: _muted,
                  micOn: _micOn,
                  onToggleMute: () => setState(() => _muted = !_muted),
                  onToggleMic: () => setState(() => _micOn = !_micOn),
                  onOpenChat: () => _scaffoldKey.currentState?.openEndDrawer(),
                  onExit: () => Navigator.of(context).pushReplacementNamed('/news'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  static const _blue = Color(0xFF1E5BFF);
  static const _red = Color(0xFFFF3B30);

  final bool muted;
  final bool micOn;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleMic;
  final VoidCallback onOpenChat;
  final VoidCallback onExit;

  const _BottomControls({
    required this.muted,
    required this.micOn,
    required this.onToggleMute,
    required this.onToggleMic,
    required this.onOpenChat,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleBtn(
            bg: Colors.white12,
            icon: muted ? Icons.volume_off : Icons.volume_up,
            iconColor: Colors.white,
            onTap: onToggleMute,
          ),
          _CircleBtn(
            bg: Colors.white12,
            icon: micOn ? Icons.mic : Icons.mic_off,
            iconColor: Colors.white,
            onTap: onToggleMic,
          ),
          _CircleBtn(
            bg: _blue,
            icon: Icons.chat_bubble_outline,
            iconColor: Colors.white,
            onTap: onOpenChat,
          ),
          _CircleBtn(
            bg: _red,
            icon: Icons.call_end,
            iconColor: Colors.white,
            onTap: onExit,
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final Color bg;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleBtn({
    required this.bg,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}

class _StreamChatDrawer extends ConsumerStatefulWidget {
  const _StreamChatDrawer();

  @override
  ConsumerState<_StreamChatDrawer> createState() => _StreamChatDrawerState();
}

class _StreamChatDrawerState extends ConsumerState<_StreamChatDrawer> {
  static const _blue = Color(0xFF1E5BFF);

  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(liveStreamChatProvider);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: const Color(0xFFF6F7F9),
      child: SafeArea(
        child: Column(
          children: [
            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Чат',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // messages
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
                data: (items) => ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _ChatBubble(m: items[i]),
                ),
              ),
            ),

            // input
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: 'Сообщение...',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 42,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final text = _ctrl.text;
                        _ctrl.clear();
                        await ref.read(liveStreamChatProvider.notifier).send(text);
                      },
                      child: const Icon(Icons.send, size: 18, color: Colors.white),
                    ),
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

class _ChatBubble extends StatelessWidget {
  final ChatMessage m;
  const _ChatBubble({required this.m});

  @override
  Widget build(BuildContext context) {
    final isMine = m.isMine;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? const Color(0xFF1E5BFF) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 12,
                  color: Color(0x12000000),
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      m.author,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                Text(
                  m.text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isMine ? Colors.white : Colors.black87,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
