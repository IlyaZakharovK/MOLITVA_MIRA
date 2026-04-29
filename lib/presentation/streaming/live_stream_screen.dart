// live_stream_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/services.dart';
import 'package:vsem_mirom/domain/streams/stream_status.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../domain/profile/profile_role.dart';
import '../../helper/parsData.dart';
import '../streams/streams_screen.dart';
import '../widgets/app_message_bar.dart';
import '../widgets/burger_button.dart';
import '../../data/streaming/live_translation_repository.dart';
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

  SomeStream? _stream;
  bool _streamArgsResolved = false;
  String? _streamArgsError;

  bool _participantsOpen = false;

  bool _chatOpen = false;
  int _lastChatLen = 0;

  bool _stickToBottom = true;
  bool _userScrolledUp = false;
  bool _chatHasNew = false;
  bool _chatListenerAttached = false;
  final TextEditingController _chatInput = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  final FocusNode _chatFocus = FocusNode();

  bool _exitDialogOpen = false;
  bool _stopDialogOpen = false;
  bool _forcedExitInProgress = false;

  @override
  void initState() {
    super.initState();

    () async {
      try {
        await WakelockPlus.enable();
      } catch (_) {}
    }();

    () async {
      try {
        await _mainRenderer.initialize();
        await _mtrRenderer.initialize();
        if (mounted) setState(() => _renderersReady = true);
      } catch (_) {
        if (mounted) setState(() => _renderersReady = false);
      }
    }();

    _chatScroll.addListener(_onChatScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_streamArgsResolved) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args : const <dynamic, dynamic>{};

    final translationId = readInt(map['translationID']);
    final invite = readString(map['invite']).toString();
    final invited = readBool(map['invited']);

    debugPrint('$translationId|$invite|$invited');

    final next = SomeStream(
      id: translationId,
      invite: invite,
      invited: invited,
    );

    if (next.invited) {
      if (next.invite.isEmpty) {
        _streamArgsError = 'Ошибка: не передан invite (invited=true)';
      }
    } else {
      if (next.id <= 0) {
        _streamArgsError = 'Ошибка: не передан translation_id';
      }
    }

    _stream = _streamArgsError == null ? next : null;
    _streamArgsResolved = true;
  }

  @override
  void dispose() {
    // ✅ возвращаем поведение сна как было
    () async {
      try {
        await WakelockPlus.disable();
      } catch (_) {}
    }();

    try {
      _mainRenderer.srcObject = null;
    } catch (_) {}
    try {
      _mtrRenderer.srcObject = null;
    } catch (_) {}

    try {
      final s = _stream;
      if (s != null) {
        ref.invalidate(liveStreamControllerProvider(s));
      }
    } catch (_) {}

    _chatInput.dispose();
    _chatScroll.removeListener(_onChatScroll);
    _chatScroll.dispose();
    _chatFocus.dispose();

    _mainRenderer.dispose();
    _mtrRenderer.dispose();
    super.dispose();
  }

  void _closeParticipants() => setState(() => _participantsOpen = false);

  void _toggleParticipants() {
    // при открытии списка участников закрываем чат, чтобы не накладывались
    setState(() {
      if (!_participantsOpen) _chatOpen = false;
      _participantsOpen = !_participantsOpen;
    });
  }

  void _closeChat() => setState(() => _chatOpen = false);

  void _toggleChat() {
    // при открытии чата закрываем список участников, чтобы не накладывались
    final opening = !_chatOpen;
    setState(() {
      if (opening) _participantsOpen = false;
      _chatOpen = opening;
      if (opening) {
        _chatHasNew = false;
        _stickToBottom = true;
        _userScrolledUp = false;
      }
    });

    if (opening) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollChatToBottom();
        if (mounted) FocusScope.of(context).requestFocus(_chatFocus);
      });
    }
  }

  Future<void> _showAudioOutputSheet(
      LiveStreamController ctrl,
      AudioOutputRoute currentRoute,
      ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _AudioOutputSheet(
              currentRoute: currentRoute,
              onSelect: (route) async {
                Navigator.of(sheetContext).pop();
                await ctrl.selectAudioRoute(route);
              },
            ),
          ),
        );
      },
    );
  }

  void _scrollChatToBottom() {
    if (!_chatScroll.hasClients) return;
    try {
      _chatScroll.animateTo(
        _chatScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } catch (_) {}
  }

  bool _isChatAtBottom() {
    if (!_chatScroll.hasClients) return true;
    final p = _chatScroll.position;
    // Нас считаем "внизу" только если реально почти упёрлись в maxScrollExtent.
    // Так точнее, чем extentAfter (он иногда врёт в момент перестроения списка).
    final remaining = p.maxScrollExtent - p.pixels;
    return remaining <= 4;
  }

  void _onChatScroll() {
    if (!_chatScroll.hasClients) return;

    final p = _chatScroll.position;
    final remaining = p.maxScrollExtent - p.pixels;

    // маленький порог — чтобы "читаю историю" не считалось "внизу"
    final stick = remaining <= 4;
    final scrolledUp = !stick;

    bool changed = false;

    if (_stickToBottom != stick) {
      _stickToBottom = stick;
      changed = true;
    }
    if (_userScrolledUp != scrolledUp) {
      _userScrolledUp = scrolledUp;
      changed = true;
    }
    if (stick && _chatHasNew) {
      _chatHasNew = false;
      changed = true;
    }

    if (changed && mounted) {
      setState(() {});
    }
  }

  void _viewNewMessages() {
    if (!mounted) return;
    setState(() {
      _chatHasNew = false;
      _userScrolledUp = false;
      _stickToBottom = true;
    });
    SchedulerBinding.instance.addPostFrameCallback(
          (_) => _scrollChatToBottom(),
    );
  }

  Future<void> _onShareInvite(
      BuildContext context,
      String invite,
      int id,
      ) async {
    final inv = invite.isEmpty
        ? id.toString().trim()
        : invite.toString().trim();
    debugPrint(invite);
    if (inv.isEmpty) {
      showAppMessageBar(
        context,
        'Нет кода приглашения',
        brand: Colors.redAccent,
      );
      return;
    }

    final link = invite.isEmpty
        ? 'https://molitvamira.ru/translations/?id=${Uri.encodeComponent(inv)}'
        : 'https://molitvamira.ru/translations/?invite=${Uri.encodeComponent(inv)}';
    await Clipboard.setData(ClipboardData(text: link));

    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Приглашение'),
        content: const Text(
          'Пригласительная ссылка скопирована в буфер. Теперь Вы можете ее отправить другому участнику.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _onBackPressed(LiveStreamController ctrl) async {
    if (_forcedExitInProgress) return;

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
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) =>
                  StreamsScreen(my: true, initialStatus: StreamStatus.active),
            ),
          );
        }
      }
    } finally {
      _exitDialogOpen = false;
    }
  }

  Future<void> _onStopTranslation(LiveStreamController ctrl) async {
    if (_forcedExitInProgress) return;
    if (_stopDialogOpen) return;

    _stopDialogOpen = true;

    try {
      final res = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Остановка трансляции'),
          content: const Text(
            'Вы действительно желаете остановить трансляцию?',
          ),
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
        try {
          await ctrl.stopTranslation();
        } catch (e) {
          if (!mounted) return;
          showAppMessageBar(
            context,
            e.toString(),
            brand: Colors.redAccent,
          );
          return;
        }

        if (!mounted) return;

        final nav = Navigator.of(context, rootNavigator: true);
        nav.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) =>
                StreamsScreen(my: true, initialStatus: StreamStatus.active),
          ),
              (route) => false,
        );
      }
    } finally {
      _stopDialogOpen = false;
    }
  }

  Future<void> _handleForcedExit(
      LiveStreamController ctrl,
      String message,
      ) async {
    if (_forcedExitInProgress || !mounted) return;
    _forcedExitInProgress = true;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Вы забанены'),
            content: const Text('Вы были забанены на данной трансляции.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Выйти'),
              ),
            ],
          ),
        ),
      );

      if (!mounted) return;
      ctrl.clearForcedExitMessage();

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              StreamsScreen(my: true, initialStatus: StreamStatus.active),
        ),
            (route) => false,
      );
    } finally {
      _forcedExitInProgress = false;
    }
  }

  Future<void> _showParticipantActions({
    required OnlineUser user,
    required LiveStreamController ctrl,
  }) async {
    TranslationUserModerationAction selected =
        TranslationUserModerationAction.none;
    debugPrint("OGOOOOOOOOOO");

    final action = await showDialog<TranslationUserModerationAction>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Widget radioRow(TranslationUserModerationAction value) {
              return RadioListTile<TranslationUserModerationAction>(
                value: value,
                groupValue: selected,
                dense: true,
                activeColor: Colors.redAccent,
                contentPadding: EdgeInsets.zero,
                title: Text(value.title),
                onChanged: (v) {
                  if (v == null) return;
                  setModalState(() => selected = v);
                },
              );
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Пользователь: ${user.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    radioRow(TranslationUserModerationAction.none),
                    radioRow(TranslationUserModerationAction.ban),
                    radioRow(TranslationUserModerationAction.allowSpeak),
                    radioRow(TranslationUserModerationAction.forbidSpeak),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F4F86),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Подтвердить'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Отмена'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted ||
        action == null ||
        action == TranslationUserModerationAction.none) {
      return;
    }

    try {
      await ctrl.moderateParticipant(target: user, action: action);
      if (!mounted) return;
      showAppMessageBar(context, 'Действие выполнено');
    } catch (e) {
      if (!mounted) return;
      showAppMessageBar(
        context,
        e.toString(),
        brand: Colors.redAccent,
      );
    }
  }

  Widget _topButton({
    required VoidCallback onTap,
    required Widget child,
    Color bg = const Color(0xFF3F4F86),
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 4),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_streamArgsResolved) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7F9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_streamArgsError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        body: Center(child: Text(_streamArgsError!)),
      );
    }

    final stream = _stream!;
    final st = ref.watch(liveStreamControllerProvider(stream));
    final ctrl = ref.read(liveStreamControllerProvider(stream).notifier);

    final forcedExitMessage = st.forcedExitMessage;
    if (forcedExitMessage != null &&
        forcedExitMessage.trim().isNotEmpty &&
        !_forcedExitInProgress) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_handleForcedExit(ctrl, forcedExitMessage));
      });
    }

    // ✅ Листенер для автоскролла/баннера новых сообщений.
    // ВАЖНО: ref.listen можно вызывать только внутри build().
    if (!_chatListenerAttached) {
      _chatListenerAttached = true;
      ref.listen<LiveStreamState>(liveStreamControllerProvider(stream), (
          prev,
          next,
          ) {
        final forcedExit = next.forcedExitMessage;
        if (forcedExit != null && forcedExit.trim().isNotEmpty) {
          unawaited(_handleForcedExit(ctrl, forcedExit));
          return;
        }

        final prevLen = prev?.chatMessages.length ?? 0;
        final nextLen = next.chatMessages.length;
        if (nextLen == prevLen) return;

        if (!_chatOpen) {
          _lastChatLen = nextLen;
          return;
        }

        if (nextLen > prevLen) {
          final userScrolledUp = _userScrolledUp;
          final forceScrollOnFirstLoad = prevLen == 0;
          final lastIsMine =
              next.chatMessages.isNotEmpty && next.chatMessages.last.isMine;

          if (forceScrollOnFirstLoad || lastIsMine || !userScrolledUp) {
            if (mounted) {
              setState(() {
                _chatHasNew = false;
                _userScrolledUp = false;
                _stickToBottom = true;
              });
            }
            SchedulerBinding.instance.addPostFrameCallback(
                  (_) => _scrollChatToBottom(),
            );
          } else {
            if (mounted) setState(() => _chatHasNew = true);
          }
        }

        _lastChatLen = nextLen;
      });
    }

    final MediaStream? desiredMain =
    (st.audioMode != AudioOutputMode.muted && st.remoteStream != null)
        ? st.remoteStream
        : null;
    if (_mainRenderer.srcObject != desiredMain) {
      _mainRenderer.srcObject = desiredMain;
    }

    final bool showMetronomeBtn =
        st.isOwner &&
            st.audioMode != AudioOutputMode.muted &&
            st.metronomeAvailable;

    final bool shouldAttachMetronome =
        st.isOwner &&
            st.audioMode != AudioOutputMode.muted &&
            st.metronomeOn &&
            st.metronomeStream != null;

    final MediaStream? desiredMtr = shouldAttachMetronome
        ? st.metronomeStream
        : null;
    if (_mtrRenderer.srcObject != desiredMtr) {
      _mtrRenderer.srcObject = desiredMtr;
    }

    if (st.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7F9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (st.error != null &&
        (st.forcedExitMessage == null || st.forcedExitMessage!.trim().isEmpty)) {
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

    final hasForcedExit =
        st.forcedExitMessage != null && st.forcedExitMessage!.trim().isNotEmpty;

    if (hasForcedExit && st.translation == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF2F3B59),
        body: SizedBox.expand(),
      );
    }

    final tr = st.translation!;
    final bool isStreamOwner = tr.ownerId == st.localUserId;
    final streamName = tr.name.trim();

    final inviteCode = tr.invite.trim();
    final bool canShareInvite =
        (tr.type == 2 || tr.type == 3) && inviteCode.isNotEmpty;

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
              _LiveStreamHeader(
                label: 'ТРАНСЛЯЦИЯ',
                name: streamName,
                participantsCount: st.participantsCount,
                canShareInvite: canShareInvite,
                soundRoute: st.preferredAudioRoute,
                onBack: () => _onBackPressed(ctrl),
                onToggleParticipants: _toggleParticipants,
                onManageAudioOutput: () => _showAudioOutputSheet(
                  ctrl,
                  st.preferredAudioRoute,
                ),
                onShare: () => _onShareInvite(context, inviteCode, tr.id),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final pad = const EdgeInsets.fromLTRB(14, 6, 14, 14);

                    // --- Prayer + waves ---
                    final prayerContent = Column(
                      key: const ValueKey('prayer'),
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
                    );

                    // --- Chat ---
                    final chatContent = Column(
                      key: const ValueKey('chat'),
                      children: [
                        Expanded(
                          child: _StreamChatPanel(
                            isLoading: st.chatLoading,
                            isSending: st.chatSending,
                            error: st.chatError,
                            messages: st.chatMessages,
                            scrollController: _chatScroll,
                            showNewMessages: _chatHasNew,
                            onViewNewMessages: _viewNewMessages,
                            inputController: _chatInput,
                            focusNode: _chatFocus,
                            onSend: (text) => ctrl.sendChatMessage(text),
                          ),
                        ),
                      ],
                    );

                    if (_chatOpen && st.chatMessages.length != _lastChatLen) {
                      _lastChatLen = st.chatMessages.length;
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        _scrollChatToBottom();
                      });
                    }

                    final content = Padding(
                      padding: pad,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.topLeft,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        transitionBuilder: (child, anim) {
                          final isChat = child.key == const ValueKey('chat');
                          final tween = Tween<Offset>(
                            begin: Offset(isChat ? 1.0 : -1.0, 0.0),
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeOutCubic));
                          return ClipRect(
                            child: SlideTransition(
                              position: anim.drive(tween),
                              child: FadeTransition(
                                opacity: anim,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: _chatOpen ? chatContent : prayerContent,
                      ),
                    );

                    final w = c.maxWidth;
                    final drawerW = math.min(320.0, w * 0.72);

                    return Stack(
                      children: [
                        content,

                        // ✅ Кнопки справа сверху: share + participants
                        // ✅ Иконка чата — ниже, выравнивание по правому краю
                        if (_participantsOpen)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _closeParticipants,
                              child: Container(
                                color: Colors.black.withOpacity(0.18),
                              ),
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
                            ownerId: tr.ownerId,
                            localUserId: st.localUserId,
                            canModerateUsers: st.canModerateUsers,
                            onClose: _closeParticipants,
                            onTapUser: (user) =>
                                _showParticipantActions(user: user, ctrl: ctrl),
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
                  canStopTranslation: isStreamOwner,
                  soundMode: st.audioMode,
                  micOn: st.micOn,
                  showMetronome: showMetronomeBtn,
                  metronomeOn: st.metronomeOn,
                  onToggleSound: () => ctrl.toggleSound(),
                  onToggleMetronome: () => ctrl.toggleMetronome(),
                  onToggleMic: () => ctrl.toggleMic(),
                  chatOpen: _chatOpen,
                  onOpenChat: () => _toggleChat(),
                  onStopTranslation: () => _onStopTranslation(ctrl),
                  onExit: () => _onBackPressed(ctrl),
                ),
              ),
              if (_renderersReady) ...[
                SizedBox(
                  width: 1,
                  height: 1,
                  child: RTCVideoView(_mainRenderer),
                ),
                if (st.isOwner)
                  SizedBox(
                    width: 1,
                    height: 1,
                    child: RTCVideoView(_mtrRenderer),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StreamChatPanel extends StatelessWidget {
  final bool isLoading;
  final bool isSending;
  final String? error;
  final List<LiveChatMessage> messages;
  final ScrollController scrollController;

  /// Если пользователь не внизу списка и пришли новые сообщения —
  /// показываем баннер "Есть новые сообщения. Просмотреть"
  final bool showNewMessages;
  final VoidCallback onViewNewMessages;

  final TextEditingController inputController;
  final FocusNode focusNode;
  final ValueChanged<String> onSend;

  const _StreamChatPanel({
    required this.isLoading,
    required this.isSending,
    required this.error,
    required this.messages,
    required this.scrollController,
    required this.showNewMessages,
    required this.onViewNewMessages,
    required this.inputController,
    required this.focusNode,
    required this.onSend,
  });

  void _doSend(BuildContext context) {
    final text = inputController.text.trim();

    if (text.isEmpty) {
      showAppMessageBar(
        context,
        'Нельзя отправлять пустые сообщения',
        brand: Colors.redAccent,
      );
      return;
    }

    // Поле ввода и так ограничено 500 символами, но оставим страховку
    if (text.length > 500) {
      showAppMessageBar(
        context,
        'Максимальная длина сообщения — 500 символов',
        brand: Colors.redAccent,
      );
      return;
    }

    inputController.clear();
    onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Чат трансляции',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          if ((error ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: messages.isEmpty
                      ? (isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : const Center(
                    child: Text(
                      'Чат пуст.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ))
                      : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final m = messages[i];
                      return _ChatBubble(m: m);
                    },
                  ),
                ),
                if (showNewMessages)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onViewNewMessages,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0x22000000),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                  color: Color(0x22000000),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Есть новые сообщения. Просмотреть',
                              style: TextStyle(
                                color: Color(0xFF1E5BFF),
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: inputController,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 4,
                    inputFormatters: [LengthLimitingTextInputFormatter(500)],
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _doSend(context),
                    decoration: InputDecoration(
                      hintText: 'Напишите сообщение…',
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: isSending ? null : () => _doSend(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSending
                          ? const Color(0xFF3F4F86).withOpacity(0.55)
                          : const Color(0xFF3F4F86),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isSending
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final LiveChatMessage m;

  const _ChatBubble({required this.m});

  @override
  Widget build(BuildContext context) {
    final isMine = m.isMine;
    final align = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMine
        ? const Color(0xFF3F4F86)
        : const Color(0xFFF1F2F6);
    final textColor = isMine ? Colors.white : Colors.black87;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    m.author,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  m.message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                m.dateAdd,
                style: TextStyle(
                  fontSize: 11,
                  color: isMine ? Colors.black38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantsDrawer extends StatefulWidget {
  final int count;
  final List<OnlineUser> users;
  final int ownerId;
  final int? localUserId;
  final bool canModerateUsers;
  final VoidCallback onClose;
  final ValueChanged<OnlineUser> onTapUser;

  const _ParticipantsDrawer({
    required this.count,
    required this.users,
    required this.ownerId,
    required this.localUserId,
    required this.canModerateUsers,
    required this.onClose,
    required this.onTapUser,
  });

  @override
  State<_ParticipantsDrawer> createState() => _ParticipantsDrawerState();
}

class _ParticipantsDrawerState extends State<_ParticipantsDrawer> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _canManage(OnlineUser user) {
    print(user.role);


    return widget.canModerateUsers &&
        user.role == ProfileRole.layman &&
        user.id != widget.ownerId &&
        user.id != widget.localUserId;
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();

    final filtered = widget.users.where((u) {
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q);
    }).toList(growable: false);

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
                        'Участники (${widget.count})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Поиск пользователя',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                  child: Text(
                    'Ничего не найдено',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final user = filtered[i];
                    final canManage = _canManage(user);

                    return InkWell(
                      onTap: canManage ? () => widget.onTapUser(user) : () => _canManage(user),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x11000000)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF3F4F86),
                              child: Text(
                                user.name.isEmpty
                                    ? '?'
                                    : user.name.trim().characters.first.toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (user.speak) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.mic,
                                          size: 14,
                                          color: Colors.green,
                                        ),
                                      ],
                                      if (user.ban) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.block,
                                          size: 14,
                                          color: Colors.redAccent,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (canManage)
                              IconButton(
                                onPressed: () => widget.onTapUser(user),
                                icon: const Icon(Icons.more_vert),
                                splashRadius: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
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

class _WaveformBarsState extends State<_WaveformBars>
    with SingleTickerProviderStateMixin {
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
    final dt = (_last == Duration.zero)
        ? 0.016
        : (elapsed - _last).inMicroseconds / 1e6;
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
        painter: _WaveformPainter(phase: _phase, level: _smooth),
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

      final centerBoost =
          0.75 + 0.25 * (1.0 - (p - 0.5).abs() * 2.0).clamp(0.0, 1.0);

      final h = (minH + (maxH - minH) * level * v01 * centerBoost).clamp(
        minH,
        maxH,
      );
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

enum _HeaderAction { audioOutput, share, participants }

class _LiveStreamHeader extends StatelessWidget {
  final String label;
  final String name;
  final int participantsCount;
  final bool canShareInvite;
  final AudioOutputRoute soundRoute;

  final VoidCallback onBack;
  final VoidCallback onToggleParticipants;
  final VoidCallback onManageAudioOutput;
  final VoidCallback? onShare;

  const _LiveStreamHeader({
    required this.label,
    required this.name,
    required this.participantsCount,
    required this.canShareInvite,
    required this.soundRoute,
    required this.onBack,
    required this.onToggleParticipants,
    required this.onManageAudioOutput,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final badgeText = participantsCount <= 0
        ? null
        : (participantsCount > 99 ? '99+' : '$participantsCount');

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 10, 10, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0x11000000))),
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => BurgerButton(
              color: Colors.black87,
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: Color(0xFF3F4F86),
                  ),
                ),
                const SizedBox(height: 2),
                LayoutBuilder(
                  builder: (context, c) => _MarqueeText(
                    text: name.isEmpty ? '—' : name,
                    maxWidth: c.maxWidth,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<_HeaderAction>(
            tooltip: 'Действия',
            position: PopupMenuPosition.under,
            onSelected: (a) {
              switch (a) {
                case _HeaderAction.audioOutput:
                  onManageAudioOutput();
                  break;
                case _HeaderAction.share:
                  onShare?.call();
                  break;
                case _HeaderAction.participants:
                  onToggleParticipants();
                  break;
              }
            },
            itemBuilder: (ctx) {
              final items = <PopupMenuEntry<_HeaderAction>>[];

              items.add(
                PopupMenuItem<_HeaderAction>(
                  value: _HeaderAction.audioOutput,
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0x143F4F86),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.phone_in_talk_rounded,
                          size: 16,
                          color: Color(0xFF3F4F86),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Вывод звука'),
                            const SizedBox(height: 2),
                            Text(
                              soundRoute.label,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );

              items.add(
                const PopupMenuItem<_HeaderAction>(
                  value: _HeaderAction.share,
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 18),
                      SizedBox(width: 10),
                      Text('Поделиться'),
                    ],
                  ),
                ),
              );

              items.add(
                PopupMenuItem<_HeaderAction>(
                  value: _HeaderAction.participants,
                  child: Row(
                    children: [
                      const Icon(Icons.groups_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text('Участники (${participantsCount.clamp(0, 9999)})'),
                    ],
                  ),
                ),
              );

              return items;
            },
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF3F4F86),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 4),
                    color: Color(0x22000000),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(Icons.more_vert, size: 22, color: Colors.white),
                  ),
                  if (badgeText != null)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double maxWidth;

  /// Скорость прокрутки в пикселях в секунду (примерно).
  final double pxPerSecond;

  const _MarqueeText({
    required this.text,
    required this.style,
    required this.maxWidth,
    this.pxPerSecond = 28,
  });

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  Animation<double>? _anim;

  double _overflowPx = 0;

  @override
  void initState() {
    super.initState();
    _recalcAndMaybeStart();
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.maxWidth != widget.maxWidth ||
        oldWidget.style != widget.style ||
        oldWidget.pxPerSecond != widget.pxPerSecond) {
      _recalcAndMaybeStart();
    }
  }

  void _recalcAndMaybeStart() {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final textW = painter.width;
    final newOverflow = math.max(0, textW - widget.maxWidth);

    if (newOverflow <= 0) {
      _overflowPx = 0;
      _stop();
      if (mounted) setState(() {});
      return;
    }

    _overflowPx = 2;

    final pauseMs = 900;
    final moveMs = math.max(
      1500,
      (_overflowPx / widget.pxPerSecond * 1000).round(),
    );
    final totalMs = pauseMs + moveMs + pauseMs;

    _ctrl?.dispose();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    _anim = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: pauseMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: _overflowPx,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: moveMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(_overflowPx),
        weight: pauseMs.toDouble(),
      ),
    ]).animate(_ctrl!);

    _ctrl!.repeat(reverse: true);

    if (mounted) setState(() {});
  }

  void _stop() {
    if (_ctrl == null) return;
    _ctrl!.stop();
    _ctrl!.dispose();
    _ctrl = null;
    _anim = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_overflowPx <= 0 || _ctrl == null || _anim == null) {
      return Text(
        widget.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
      );
    }

    return ClipRect(
      child: AnimatedBuilder(
        animation: _ctrl!,
        builder: (context, child) {
          final dx = _anim!.value;
          return Transform.translate(offset: Offset(-dx, 0), child: child);
        },
        child: Text(
          widget.text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: widget.style,
        ),
      ),
    );
  }
}

class _AudioOutputSheet extends StatelessWidget {
  final AudioOutputRoute currentRoute;
  final ValueChanged<AudioOutputRoute> onSelect;

  const _AudioOutputSheet({
    required this.currentRoute,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x1F3F4F86),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Вывод звука',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Нижняя кнопка только включает и выключает звук. Здесь можно выбрать, куда именно он будет выводиться.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            _AudioOutputOptionTile(
              title: AudioOutputRoute.earpiece.label,
              subtitle: 'По умолчанию',
              icon: Icons.phone_in_talk_rounded,
              selected: currentRoute == AudioOutputRoute.earpiece,
              onTap: () => onSelect(AudioOutputRoute.earpiece),
            ),
            const SizedBox(height: 10),
            _AudioOutputOptionTile(
              title: AudioOutputRoute.speaker.label,
              subtitle: 'Громче и удобнее без поднесения к уху',
              icon: Icons.volume_up_rounded,
              selected: currentRoute == AudioOutputRoute.speaker,
              onTap: () => onSelect(AudioOutputRoute.speaker),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioOutputOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AudioOutputOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0x123F4F86) : const Color(0xFFF7F8FC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF3F4F86)
                  : const Color(0x11000000),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF3F4F86)
                      : const Color(0x143F4F86),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : const Color(0xFF3F4F86),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? const Color(0xFF3F4F86) : Colors.white,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF3F4F86)
                        : const Color(0xFFB8BFCC),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final bool isOwner;
  final bool canStopTranslation;

  final AudioOutputMode soundMode;
  final bool micOn;

  final bool showMetronome;
  final bool metronomeOn;
  final bool chatOpen;

  final VoidCallback onToggleSound;
  final VoidCallback onToggleMetronome;
  final VoidCallback onToggleMic;
  final VoidCallback onOpenChat;
  final VoidCallback onStopTranslation;
  final VoidCallback onExit;

  const _BottomControls({
    required this.isOwner,
    required this.canStopTranslation,
    required this.soundMode,
    required this.chatOpen,
    required this.micOn,
    required this.showMetronome,
    required this.metronomeOn,
    required this.onToggleSound,
    required this.onToggleMetronome,
    required this.onToggleMic,
    required this.onOpenChat,
    required this.onStopTranslation,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final Color soundBg = switch (soundMode) {
      AudioOutputMode.muted => Colors.redAccent,
      AudioOutputMode.ear => Colors.green,
    };

    final IconData soundIcon = switch (soundMode) {
      AudioOutputMode.muted => Icons.volume_off,
      AudioOutputMode.ear => Icons.volume_up,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isOwner) ...[
          _RoundBtn(
            bg: micOn ? Colors.green : Colors.redAccent,
            icon: micOn ? Icons.mic : Icons.mic_off,
            onTap: onToggleMic,
          ),
          const SizedBox(width: 14),
        ],
        _RoundBtn(
          bg: soundBg,
          icon: soundIcon,
          onTap: onToggleSound,
        ),
        const SizedBox(width: 14),
        _RoundBtnSVG(
          bg: Colors.lightBlueAccent,
          onTap: onOpenChat,
          child: chatOpen
              ? Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: SvgPicture.asset(
                'assets/svg/sound.svg',
                color: Colors.white,
              ),
            ),
          )
              : const Icon(Icons.chat_bubble_outline, color: Colors.white),
        ),
        if (canStopTranslation) ...[
          const SizedBox(width: 14),
          _RoundBtn(
            bg: Colors.redAccent,
            onTap: onStopTranslation,
            icon: Icons.stop,
          ),
        ],
        const SizedBox(width: 14),
        _RoundBtn(
          bg: Colors.redAccent,
          icon: Icons.exit_to_app,
          onTap: onExit,
        ),
      ],
    );
  }
}

class _RoundBtnSVG extends StatelessWidget {
  final Color bg;
  final Widget child;
  final VoidCallback onTap;

  const _RoundBtnSVG({
    required this.bg,
    required this.child,
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
        child: child,
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final Color bg;
  final IconData icon;
  final VoidCallback onTap;

  const _RoundBtn({required this.bg, required this.icon, required this.onTap});

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
