// live_stream_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../widgets/top_bar.dart';
import 'live_stream_controller.dart';
import '../shell/app_shell.dart';

class LiveStreamScreen extends ConsumerStatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  ConsumerState<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends ConsumerState<LiveStreamScreen> {
  final RTCVideoRenderer _mainRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _mtrRenderer = RTCVideoRenderer();

  bool _renderersReady = false;
  int _translationId = 0;

  bool _participantsOpen = false;

  // 🔒 чтобы диалог не открывался повторно/двойной pop не происходил
  bool _exitDialogOpen = false;

  @override
  void initState() {
    super.initState();

    // В release и на некоторых девайсах инициализация renderer'ов может быть
    // асинхронной/ленивой. Если строить RTCVideoView до initialize(), иногда
    // ловится белый экран при повторном заходе.
    () async {
      try {
        await _mainRenderer.initialize();
        await _mtrRenderer.initialize();
        if (mounted) setState(() => _renderersReady = true);
      } catch (_) {
        if (mounted) setState(() => _renderersReady = false);
      }
    }();
  }

  @override
  void dispose() {
    // Сбрасываем srcObject, чтобы нативный texture/audio sink гарантированно освободился
    try {
      _mainRenderer.srcObject = null;
    } catch (_) {}
    try {
      _mtrRenderer.srcObject = null;
    } catch (_) {}

    // ⚠️ Release-фиск: принудительно инвалидируем provider,
    // чтобы при следующем заходе создавался новый контроллер (без "залипания" старых ресурсов).
    if (_translationId > 0) {
      try {
        ref.invalidate(liveStreamControllerProvider(_translationId));
      } catch (_) {}
    }

    _mainRenderer.dispose();
    _mtrRenderer.dispose();
    super.dispose();
  }

  void _closeParticipants() => setState(() => _participantsOpen = false);
  void _toggleParticipants() => setState(() => _participantsOpen = !_participantsOpen);

  Future<void> _onBackPressed(LiveStreamController ctrl) async {
    if (_participantsOpen) {
      _closeParticipants();
      return;
    }

    if (_exitDialogOpen) return;
    _exitDialogOpen = true;

    try {
      final res = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Выход'),
          content: const Text('Вы действительно желаете выйти из трансляции?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Нет'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: const Text('Да'),
            ),
          ],
        ),
      );

      if (res == true) {
        await ctrl.exit();
        if (!mounted) return;

        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) {
          nav.pop();
        } else {
          nav.pushReplacementNamed('/news');
        }
      }
    } finally {
      _exitDialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final translationId = (args is int) ? args : int.tryParse(args.toString()) ?? 0;

    // для dispose(): чтобы можно было invalidate правильный provider
    _translationId = translationId;

    if (translationId <= 0) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7F9),
        body: Center(child: Text('Ошибка: не передан translation_id')),
      );
    }

    final st = ref.watch(liveStreamControllerProvider(translationId));
    final ctrl = ref.read(liveStreamControllerProvider(translationId).notifier);

    final MediaStream? desiredMain =
    (st.audioMode == AudioOutputMode.on && st.remoteStream != null) ? st.remoteStream : null;
    if (_mainRenderer.srcObject != desiredMain) {
      _mainRenderer.srcObject = desiredMain;
    }

    final bool showMetronomeBtn = st.isOwner && st.audioMode == AudioOutputMode.on && st.metronomeAvailable;

    final bool shouldAttachMetronome =
        st.isOwner && st.audioMode == AudioOutputMode.on && st.metronomeOn && st.metronomeStream != null;

    final MediaStream? desiredMtr = shouldAttachMetronome ? st.metronomeStream : null;
    if (_mtrRenderer.srcObject != desiredMtr) {
      _mtrRenderer.srcObject = desiredMtr;
    }

    if (st.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7F9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (st.error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ошибка: ${st.error}'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: ctrl.refresh,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    final tr = st.translation!;
    final title = 'ТРАНСЛЯЦИЯ "${tr.name.toUpperCase()}"';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onBackPressed(ctrl);
      },
      child: AppShell(
        translation: true,
        ctrl: ctrl,
        child: SafeArea(
          child: Column(
            children: [
              TopBar(title: title, translation: true, ctrl: ctrl),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final pad = const EdgeInsets.fromLTRB(14, 6, 14, 14);

                    final content = Padding(
                      padding: pad,
                      child: Column(
                        children: [
                          Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: _WaveformBars(
                              active: st.speaking,
                              level: st.speakingLevel,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  tr.prayer_optional == 1
                                      ? tr.prayer_optional_text
                                      : st.prayerTextLoading
                                      ? 'Загрузка...'
                                      : st.prayerText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    final w = c.maxWidth;
                    final drawerW = math.min(320.0, w * 0.72);

                    return Stack(
                      children: [
                        content,
                        Positioned(
                          right: 14,
                          top: 10,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: _toggleParticipants,
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                color: Color(0xFF3F4F86),
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                    color: Color(0x22000000),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Text(
                                  'Участников: ${st.participantsCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_participantsOpen)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _closeParticipants,
                              child: Container(color: Colors.black.withOpacity(0.18)),
                            ),
                          ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          top: 0,
                          bottom: 0,
                          right: _participantsOpen ? 0 : -drawerW,
                          width: drawerW,
                          child: _ParticipantsDrawer(
                            count: st.participantsCount,
                            users: st.participants,
                            onClose: _closeParticipants,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: _BottomControls(
                  isOwner: st.isOwner,
                  soundOn: st.audioMode == AudioOutputMode.on,
                  micOn: st.micOn,
                  showMetronome: showMetronomeBtn,
                  metronomeOn: st.metronomeOn,
                  onToggleSound: () => ctrl.toggleSound(),
                  onToggleMetronome: () => ctrl.toggleMetronome(),
                  onToggleMic: () => ctrl.toggleMic(),
                ),
              ),

              if (_renderersReady) ...[
                // 1x1 (а не 0x0) — у ряда девайсов 0 может приводить к белому экрану/неподключению
                SizedBox(width: 1, height: 1, child: RTCVideoView(_mainRenderer)),
                if (st.isOwner) SizedBox(width: 1, height: 1, child: RTCVideoView(_mtrRenderer)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantsDrawer extends StatelessWidget {
  final int count;
  final List<String> users;
  final VoidCallback onClose;

  const _ParticipantsDrawer({
    required this.count,
    required this.users,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(-6, 0),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: SafeArea(
          left: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Участники ($count)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: users.isEmpty
                    ? const Center(
                  child: Text(
                    'Пока никого нет',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => Text(
                    users[i],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Волны «как будто спектр» без доступа к PCM:
class _WaveformBars extends StatefulWidget {
  final bool active;
  final double level;

  const _WaveformBars({required this.active, required this.level});

  @override
  State<_WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<_WaveformBars> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _phase = 0.0;
  double _smooth = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (_last == Duration.zero) ? 0.016 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;

    final target = (widget.active ? widget.level : 0.0).clamp(0.0, 1.0);
    _smooth = _smooth * 0.8 + target * 0.2;

    final speed = (widget.active ? 2.8 : 1.2);
    _phase += dt * speed;

    if (_smooth < 0.01 && !widget.active) return;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: CustomPaint(
        painter: _WaveformPainter(
          phase: _phase,
          level: _smooth,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double phase;
  final double level;

  _WaveformPainter({required this.phase, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 46;
    const gap = 2.0;
    final barW = (size.width - gap * (barCount - 1)) / barCount;
    final paint = Paint()..color = const Color(0xFF5AB0FF);

    final minH = (size.height * 0.12).clamp(8.0, 14.0);
    final maxH = size.height;

    double x = 0;
    for (int i = 0; i < barCount; i++) {
      final p = (barCount == 1) ? 0.0 : i / (barCount - 1);

      final low = math.sin(phase * 0.75 + i * 0.14);
      final high = math.sin(phase * 1.55 + i * 0.60);
      final mix = low * (1.0 - p) + high * p;
      final v01 = (mix * 0.5 + 0.5).clamp(0.0, 1.0);

      final centerBoost = 0.75 + 0.25 * (1.0 - (p - 0.5).abs() * 2.0).clamp(0.0, 1.0);

      final h = (minH + (maxH - minH) * level * v01 * centerBoost).clamp(minH, maxH);
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barW, h),
        const Radius.circular(4),
      );
      canvas.drawRRect(r, paint);
      x += barW + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.level != level;
  }
}

class _BottomControls extends StatelessWidget {
  final bool isOwner;

  final bool soundOn;
  final bool micOn;

  final bool showMetronome;
  final bool metronomeOn;

  final VoidCallback onToggleSound;
  final VoidCallback onToggleMetronome;
  final VoidCallback onToggleMic;

  const _BottomControls({
    required this.isOwner,
    required this.soundOn,
    required this.micOn,
    required this.showMetronome,
    required this.metronomeOn,
    required this.onToggleSound,
    required this.onToggleMetronome,
    required this.onToggleMic,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isOwner) ...[
          _RoundBtn(
            bg: micOn ? Colors.green : Colors.red,
            icon: micOn ? Icons.mic : Icons.mic_off,
            onTap: onToggleMic,
          ),
          const SizedBox(width: 14),
        ],
        _RoundBtn(
          bg: soundOn ? Colors.green : Colors.red,
          icon: soundOn ? Icons.volume_up : Icons.volume_off,
          onTap: onToggleSound,
        ),
        if (showMetronome) ...[
          const SizedBox(width: 14),
          _RoundBtn(
            bg: metronomeOn ? Colors.green : Colors.red,
            icon: Icons.alarm,
            onTap: onToggleMetronome,
          ),
        ],
      ],
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final Color bg;
  final IconData icon;
  final VoidCallback onTap;

  const _RoundBtn({
    required this.bg,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 4),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
