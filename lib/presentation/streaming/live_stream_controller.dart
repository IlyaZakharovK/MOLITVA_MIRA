import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../data/auth/auth_local_store.dart';
import '../../data/streaming/live_translation_repository.dart';
import '../../data/streaming/sfu_ws_client.dart';
import '../../domain/prayer_request/prayer_request_repository.dart';
import '../../providers.dart';
import '../../domain/profile/profile_role.dart';

final liveTranslationRepositoryProvider = Provider<LiveTranslationRepository>((
    ref,
    ) {
  final dio = ref.watch(dioProvider);
  return LiveTranslationRepository(dio);
});

enum AudioOutputMode { muted, ear }

extension AudioOutputModeX on AudioOutputMode {
  String get label {
    switch (this) {
      case AudioOutputMode.muted:
        return 'Без звука';
      case AudioOutputMode.ear:
        return 'Звук включён';
    }
  }

  bool get isAudible => this != AudioOutputMode.muted;
}

enum AudioOutputRoute { earpiece, speaker }

extension AudioOutputRouteX on AudioOutputRoute {
  String get label {
    switch (this) {
      case AudioOutputRoute.earpiece:
        return 'Фронтальный динамик';
      case AudioOutputRoute.speaker:
        return 'Динамик устройства';
    }
  }

  String get description {
    switch (this) {
      case AudioOutputRoute.earpiece:
        return 'Звук будет воспроизводиться через разговорный динамик';
      case AudioOutputRoute.speaker:
        return 'Звук будет воспроизводиться через основной внешний динамик';
    }
  }
}

/// Сообщение чата трансляции (API: appGetChatMessagesTranslation / appStartChatAutoUpdate)
class LiveChatMessage {
  final int messageId;
  final String message;
  final String dateAdd; // обычно "14:33" или дата
  final String author;
  final String avatarUrl;
  final bool isMine;

  const LiveChatMessage({
    required this.messageId,
    required this.message,
    required this.dateAdd,
    required this.author,
    required this.avatarUrl,
    required this.isMine,
  });

  static int _toInt(dynamic v) => int.tryParse((v ?? '').toString()) ?? 0;
  static String _toStr(dynamic v) => (v ?? '').toString();

  factory LiveChatMessage.fromApi(Map<String, dynamic> j) {
    final author = _toStr(j['author']).trim();
    final avatar = _toStr(j['avatar_url']).trim();
    final isMine = author.toLowerCase() == 'текущий пользователь' || avatar.isEmpty;

    return LiveChatMessage(
      messageId: _toInt(j['message_id']),
      message: _toStr(j['message']),
      dateAdd: _toStr(j['date_add']),
      author: author,
      avatarUrl: avatar,
      isMine: isMine,
    );
  }
}

class LiveStreamState {
  final bool isLoading;
  final String? error;

  final LiveTranslation? translation;
  final int? localUserId;
  final ProfileRole? localRole;

  /// Исторически используется как "может говорить"
  final bool isOwner;

  final bool canModerateUsers;
  final String? forcedExitMessage;

  final bool wsConnected;
  final bool rtcConnected;

  final AudioOutputMode audioMode;
  final AudioOutputRoute preferredAudioRoute;

  /// mic enabled (только owner)
  final bool micOn;

  /// метроном включён пользователем (доступен всем)
  final bool metronomeOn;

  /// remote stream (основной звук)
  final MediaStream? remoteStream;

  /// stream метронома (если есть)
  final MediaStream? metronomeStream;

  /// Voice activity detection (только основной поток, метроном игнорируем)
  final bool speaking;

  /// 0..1 — условная громкость/активность речи
  final double speakingLevel;

  /// строка статуса (диагностика)
  final String status;

  final int participantsCount;
  final List<OnlineUser> participants;

  /// На WEB нужен первый клик для autoplay
  final bool needsUserGestureToPlay;

  /// Метроним доступен (offerMtr пришёл/pc поднят)
  final bool metronomeAvailable;

  /// Actual prayer text (resolved by prayers_category_id + prayers_texts_id)
  final bool prayerTextLoading;
  final String prayerText;
  final String? prayerTextError;

  final bool chatLoading;
  final bool chatSending;
  final String? chatError;
  final bool chatEmpty;
  final List<LiveChatMessage> chatMessages;
  final int lastChatMessageId;

  const LiveStreamState({
    required this.isLoading,
    required this.error,
    required this.translation,
    required this.localUserId,
    required this.localRole,
    required this.isOwner,
    required this.canModerateUsers,
    required this.forcedExitMessage,
    required this.wsConnected,
    required this.rtcConnected,
    required this.audioMode,
    required this.preferredAudioRoute,
    required this.micOn,
    required this.metronomeOn,
    required this.remoteStream,
    required this.metronomeStream,
    required this.speaking,
    required this.speakingLevel,
    required this.status,
    required this.participantsCount,
    required this.participants,
    required this.needsUserGestureToPlay,
    required this.metronomeAvailable,
    required this.prayerTextLoading,
    required this.prayerText,
    required this.prayerTextError,
    required this.chatLoading,
    required this.chatSending,
    required this.chatError,
    required this.chatEmpty,
    required this.chatMessages,
    required this.lastChatMessageId,
  });

  factory LiveStreamState.initial() => const LiveStreamState(
    isLoading: true,
    error: null,
    translation: null,
    localUserId: null,
    localRole: null,
    isOwner: false,
    canModerateUsers: false,
    forcedExitMessage: null,
    wsConnected: false,
    rtcConnected: false,
    audioMode: AudioOutputMode.muted,
    preferredAudioRoute: AudioOutputRoute.earpiece,
    micOn: false,
    metronomeOn: false,
    remoteStream: null,
    metronomeStream: null,
    speaking: false,
    speakingLevel: 0,
    status: 'Загрузка…',
    participantsCount: 0,
    participants: [],
    needsUserGestureToPlay: true,
    metronomeAvailable: false,
    prayerTextLoading: false,
    prayerText: '',
    prayerTextError: null,
    chatLoading: false,
    chatSending: false,
    chatError: null,
    chatEmpty: false,
    chatMessages: [],
    lastChatMessageId: 0,
  );

  LiveStreamState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    LiveTranslation? translation,
    int? localUserId,
    ProfileRole? localRole,
    bool? isOwner,
    bool? canModerateUsers,
    String? forcedExitMessage,
    bool clearForcedExitMessage = false,
    bool? wsConnected,
    bool? rtcConnected,
    AudioOutputMode? audioMode,
    AudioOutputRoute? preferredAudioRoute,
    bool? micOn,
    bool? metronomeOn,
    MediaStream? remoteStream,
    MediaStream? metronomeStream,
    bool? speaking,
    double? speakingLevel,
    String? status,
    int? participantsCount,
    List<OnlineUser>? participants,
    bool? needsUserGestureToPlay,
    bool? metronomeAvailable,
    bool? prayerTextLoading,
    String? prayerText,
    String? prayerTextError,
    bool clearPrayerTextError = false,
    bool? chatLoading,
    bool? chatSending,
    String? chatError,
    bool? chatEmpty,
    bool clearChatError = false,
    List<LiveChatMessage>? chatMessages,
    int? lastChatMessageId,
  }) {
    return LiveStreamState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      translation: translation ?? this.translation,
      localUserId: localUserId ?? this.localUserId,
      localRole: localRole ?? this.localRole,
      isOwner: isOwner ?? this.isOwner,
      canModerateUsers: canModerateUsers ?? this.canModerateUsers,
      forcedExitMessage: clearForcedExitMessage
          ? null
          : (forcedExitMessage ?? this.forcedExitMessage),
      wsConnected: wsConnected ?? this.wsConnected,
      rtcConnected: rtcConnected ?? this.rtcConnected,
      audioMode: audioMode ?? this.audioMode,
      preferredAudioRoute: preferredAudioRoute ?? this.preferredAudioRoute,
      micOn: micOn ?? this.micOn,
      metronomeOn: metronomeOn ?? this.metronomeOn,
      remoteStream: remoteStream ?? this.remoteStream,
      metronomeStream: metronomeStream ?? this.metronomeStream,
      speaking: speaking ?? this.speaking,
      speakingLevel: speakingLevel ?? this.speakingLevel,
      status: status ?? this.status,
      participantsCount: participantsCount ?? this.participantsCount,
      participants: participants ?? this.participants,
      needsUserGestureToPlay:
      needsUserGestureToPlay ?? this.needsUserGestureToPlay,
      metronomeAvailable: metronomeAvailable ?? this.metronomeAvailable,
      prayerTextLoading: prayerTextLoading ?? this.prayerTextLoading,
      prayerText: prayerText ?? this.prayerText,
      prayerTextError: clearPrayerTextError
          ? null
          : (prayerTextError ?? this.prayerTextError),
      chatLoading: chatLoading ?? this.chatLoading,
      chatSending: chatSending ?? this.chatSending,
      chatError: clearChatError ? null : (chatError ?? this.chatError),
      chatEmpty: chatEmpty ?? this.chatEmpty,
      chatMessages: chatMessages ?? this.chatMessages,
      lastChatMessageId: lastChatMessageId ?? this.lastChatMessageId,
    );
  }
}

class SomeStream {
  final int id;
  final String invite;
  final bool invited;

  const SomeStream({
    required this.id,
    required this.invite,
    required this.invited,
  });
}

final liveStreamControllerProvider = StateNotifierProvider.autoDispose
    .family<LiveStreamController, LiveStreamState, SomeStream>(
      (ref, streamData) => LiveStreamController(
      ref,
      streamData: streamData
  ),
);

enum _ChatPollMode { refreshAll, incremental }

class LiveStreamController extends StateNotifier<LiveStreamState> {
  LiveStreamController(
      this.ref, {
        required this.streamData,
      }) : super(LiveStreamState.initial()) {
    ref.onDispose(_onProviderDispose);
    _init();
  }

  final Ref ref;
  final SomeStream streamData;

  LiveTranslationRepository get _repo =>
      ref.read(liveTranslationRepositoryProvider);

  AuthLocalStore get _local => ref.read(authLocalStoreProvider);

  PrayerRequestRepository get _prayersRepo =>
      ref.read(prayerRequestRepositoryProvider);

  // ===== WS/RTC =====
  SfuWsClient? _ws;
  StreamSubscription? _wsSub;

  RTCPeerConnection? _pc;

  // metronome
  RTCPeerConnection? _mtrPc;
  String? _lastOfferMtrSdp;

  RTCRtpTransceiver? _audioTransceiver;

  MediaStream? _localStream;
  MediaStreamTrack? _micTrack;

  final List<RTCIceCandidate> _pendingIce = [];

  // ===== VAD =====
  Timer? _vadTimer;
  double? _lastTotalAudioEnergy;
  double? _lastTotalSamplesDuration;
  DateTime _lastSpeakingAt = DateTime.fromMillisecondsSinceEpoch(0);
  double _smoothedLevel = 0.0;

  // ===== Presence ping =====
  Timer? _presenceTimer;
  bool _presenceInFlight = false;

  // ===== Chat polling =====
  bool _chatInFlight = false;
  bool _chatInitialized = false;
  final Set<int> _chatKnownIds = <int>{};

  _ChatPollMode _chatPollMode = _ChatPollMode.refreshAll;
  int _localTempChatId = -1;


  static const String _wsUrl = 'wss://media.molitvamira.ru/ws';
  static const String _bannedDialogMessage =
      'Вы были забанены на данной трансляции.';

  void _log(String msg) {
    debugPrint('[LIVE] $msg');
    if (!mounted) return;
    state = state.copyWith(status: msg);
  }

  bool _hasPrivilegedRole(ProfileRole? role) {
    return role == ProfileRole.clergy ||
        role == ProfileRole.temple ||
        role == ProfileRole.admin;
  }

  OnlineUser? _findUserById(List<OnlineUser> users, int? userId) {
    if (userId == null || userId <= 0) return null;
    for (final user in users) {
      if (user.id == userId) return user;
    }
    return null;
  }

  bool _resolveCanSpeak({
    required LiveTranslation tr,
    required int? localUserId,
    required ProfileRole? localRole,
    required List<OnlineUser> onlineUsers,
  }) {
    final byOwner = localUserId != null && localUserId == tr.ownerId;
    final byRole = _hasPrivilegedRole(localRole);
    final me = _findUserById(onlineUsers, localUserId);
    final byPresence = me?.speak == true;
    return byOwner || byRole || byPresence;
  }

  bool _resolveCanModerate({
    required LiveTranslation tr,
    required int? localUserId,
    required ProfileRole? localRole,
  }) {
    final byOwner = localUserId == tr.ownerId;
    final byRole = _hasPrivilegedRole(localRole);
    return byOwner || byRole;
  }

  void clearForcedExitMessage() {
    if (!mounted) return;
    state = state.copyWith(clearForcedExitMessage: true);
  }

  Future<void> _handleBan() async {
    if (!mounted) return;

    try {
      _micTrack?.enabled = false;
    } catch (_) {}

    state = state.copyWith(
      isLoading: false,
      clearError: true,
      forcedExitMessage: _bannedDialogMessage,
      status: _bannedDialogMessage,
      isOwner: false,
      micOn: false,
      audioMode: AudioOutputMode.muted,
      metronomeOn: false,
      speaking: false,
      speakingLevel: 0,
    );

    await _dispose(updateState: false);
  }

  // ---------------- Presence ----------------

  void _startPresenceLoop({
    required int userId,
    required int translationId,
    bool pingImmediately = true,
  }) {
    _stopPresenceLoop();

    if (pingImmediately) {
      unawaited(_pingPresence(userId: userId, translationId: translationId));
    }

    unawaited(
      _ensureChatInitialized(userId: userId, translationId: translationId),
    );

    _presenceTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_pingPresence(userId: userId, translationId: translationId));
      unawaited(_pollChatTick(userId: userId, translationId: translationId));
    });
  }

  void _stopPresenceLoop() {
    _presenceTimer?.cancel();
    _presenceTimer = null;
    _presenceInFlight = false;

    _chatInFlight = false;
    _chatInitialized = false;
    _chatPollMode = _ChatPollMode.refreshAll;
    _chatKnownIds.clear();
    _localTempChatId = -1;
  }

  Future<void> _pingPresence({
    required int userId,
    required int translationId,
  }) async {
    if (!mounted) return;
    if (userId <= 0 || translationId <= 0) return;
    if (_presenceInFlight) return;

    _presenceInFlight = true;

    try {
      final info = await _repo.appUserOnlineInTranslation(
        translationId: translationId,
        userId: userId,
      );

      if (!mounted) return;

      final tr = state.translation;
      final nextCanSpeak = tr == null
          ? state.isOwner
          : _resolveCanSpeak(
        tr: tr,
        localUserId: userId,
        localRole: state.localRole,
        onlineUsers: info.users,
      );

      final prevCanSpeak = state.isOwner;

      state = state.copyWith(
        participantsCount: info.countOnline,
        participants: info.users,
        isOwner: nextCanSpeak,
      );

      if (tr != null && prevCanSpeak != nextCanSpeak && state.wsConnected) {
        _log(
          nextCanSpeak
              ? 'Вам выдали право говорить. Переподключаемся…'
              : 'Право говорить снято. Переподключаемся…',
        );
        unawaited(refresh());
      }
    } on PresenceBanException {
      await _handleBan();
    } catch (e) {
      debugPrint('[LIVE][PRESENCE] error: $e');
    } finally {
      _presenceInFlight = false;
    }
  }

  // ---------------- Chat API + polling ----------------

  Dio get _dio => ref.read(dioProvider);

  static const String _apiType = 'application';
  static const String _apiPass = 'f92R*#eiDF82W@#k2WO';

  bool _isOkStatus(dynamic status) {
    final s = (status ?? '').toString().toLowerCase().trim();
    return s == 'success' || s == 'ok';
  }

  String _desc(Map<String, dynamic> body) =>
      (body['description'] ?? body['msg'] ?? 'Ошибка').toString();

  Map<String, dynamic> _toStringKeyedMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), val));
    }
    return const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _postApi(
      String method,
      Map<String, dynamic> data,
      ) async {
    final resp = await _dio.post(
      '',
      data: <String, dynamic>{
        'type': _apiType,
        'pass': _apiPass,
        'method': method,
        'data': data,
      },
    );

    final body = resp.data;
    if (body is! Map) throw Exception('Некорректный ответ сервера');
    return _toStringKeyedMap(body);
  }

  List<LiveChatMessage> _parseChatList(dynamic raw) {
    if (raw is! List) return const [];
    final out = <LiveChatMessage>[];
    for (final it in raw) {
      if (it is Map) {
        final m = _toStringKeyedMap(it);
        final msg = LiveChatMessage.fromApi(m);
        if (msg.messageId > 0) out.add(msg);
      }
    }
    out.sort((a, b) => a.messageId.compareTo(b.messageId));
    return out;
  }

  int _maxMessageId(Iterable<LiveChatMessage> list) {
    var m = 0;
    for (final x in list) {
      if (x.messageId > m) m = x.messageId;
    }
    return m;
  }


  Future<void> _pollChatTick({
    required int userId,
    required int translationId,
  }) async {
    if (!mounted) return;
    if (userId <= 0 || translationId <= 0) return;
    if (!_chatInitialized) return;

    // Если чат "не найден"/пустой — каждые 15 секунд перезапрашиваем весь чат,
    // и только когда появятся сообщения — переключаемся на инкрементальный опрос.
    if (_chatPollMode == _ChatPollMode.refreshAll || state.lastChatMessageId <= 0) {
      await _refreshChatFull(userId: userId, translationId: translationId);
      return;
    }

    await _pollChatUpdates(userId: userId, translationId: translationId);
  }

  Future<void> _refreshChatFull({
    required int userId,
    required int translationId,
  }) async {
    if (!mounted) return;
    if (userId <= 0 || translationId <= 0) return;
    if (!_chatInitialized) return;

    if (_chatInFlight) return;
    _chatInFlight = true;

    try {
      final body = await _postApi('appGetChatMessagesTranslation', {
        'translation_id': translationId,
        'user_id': userId,
      });

      final ok = _isOkStatus(body['status']);
      final desc = _desc(body);
      final notFound = desc.toLowerCase().contains('чат не найден');

      if (!ok && notFound) {
        // ✅ Чата нет (или он ещё не создан) — показываем "Чат пуст"
        // и остаёмся в режиме полного перезапроса.
        _chatKnownIds.clear();
        _chatPollMode = _ChatPollMode.refreshAll;

        if (!mounted) return;
        state = state.copyWith(
          chatLoading: false,
          chatEmpty: true,
          clearChatError: true,
          chatMessages: const [],
          lastChatMessageId: 0,
        );
        return;
      }

      if (!ok) {
        throw Exception(desc);
      }

      final messages = _parseChatList(body['data']);

      _chatKnownIds
        ..clear()
        ..addAll(messages.map((m) => m.messageId));

      final lastId = _maxMessageId(messages);

      final empty = messages.isEmpty;
      _chatPollMode = empty ? _ChatPollMode.refreshAll : _ChatPollMode.incremental;

      if (!mounted) return;
      state = state.copyWith(
        chatLoading: false,
        chatMessages: messages,
        lastChatMessageId: lastId,
        chatEmpty: empty,
        clearChatError: true,
      );
    } catch (e) {
      debugPrint('[LIVE][CHAT] refresh error: $e');
      if (!mounted) return;

      state = state.copyWith(
        chatLoading: false,
        chatError: e.toString(),
      );
      _chatPollMode = _ChatPollMode.refreshAll;
    } finally {
      _chatInFlight = false;
    }
  }

  Future<void> _ensureChatInitialized({
    required int userId,
    required int translationId,
  }) async {
    if (!mounted) return;
    if (userId <= 0 || translationId <= 0) return;
    if (_chatInitialized) return;

    _chatInitialized = true;
    _chatPollMode = _ChatPollMode.refreshAll;
    _chatKnownIds.clear();
    _localTempChatId = -1;

    state = state.copyWith(
      chatLoading: true,
      clearChatError: true,
      chatEmpty: false,
      chatMessages: const [],
      lastChatMessageId: 0,
    );

    await _refreshChatFull(userId: userId, translationId: translationId);
  }

  Future<void> _pollChatUpdates({
    required int userId,
    required int translationId,
  }) async {
    if (!mounted) return;
    if (userId <= 0 || translationId <= 0) return;
    if (!_chatInitialized) return;
    if (_chatPollMode != _ChatPollMode.incremental) return;

    if (_chatInFlight) return;
    _chatInFlight = true;

    try {
      final lastId = state.lastChatMessageId;
      if (lastId <= 0) {
        _chatPollMode = _ChatPollMode.refreshAll;
        return;
      }

      final body = await _postApi('appStartChatAutoUpdate', {
        'translation_id': translationId,
        'user_id': userId,
        'lastMessageId': lastId,
      });

      final ok = _isOkStatus(body['status']);
      final desc = _desc(body);
      final notFound = desc.toLowerCase().contains('чат не найден');
      debugPrint('[LIVE][CHAT] poll good: $lastId');
      if (!ok) {
        if (notFound) {
          _chatKnownIds.clear();
          _chatPollMode = _ChatPollMode.refreshAll;

          if (!mounted) return;
          state = state.copyWith(
            chatEmpty: true,
            clearChatError: true,
            chatMessages: const [],
            lastChatMessageId: 0,
          );
        } else {
          debugPrint('[LIVE][CHAT] update error: $desc');
        }
        return;
      }

      final incoming = _parseChatList(body['data']);
      if (incoming.isEmpty) return;

      final merged = <LiveChatMessage>[...state.chatMessages];
      var newMax = lastId;

      for (final m in incoming) {
        if (_chatKnownIds.add(m.messageId)) {
          merged.add(m);
          if (m.messageId > newMax) newMax = m.messageId;
        }
      }

      merged.sort((a, b) {
        final aNeg = a.messageId <= 0;
        final bNeg = b.messageId <= 0;
        if (aNeg != bNeg) return aNeg ? 1 : -1; // локальные (<=0) — в конец
        if (!aNeg) return a.messageId.compareTo(b.messageId);
        return b.messageId.compareTo(a.messageId); // -1, -2, -3...
      });

      if (!mounted) return;
      state = state.copyWith(
        chatMessages: merged,
        lastChatMessageId: newMax,
        chatEmpty: false,
        clearChatError: true,
      );
      debugPrint('[LIVE][CHAT] poll good: $lastId');
    } catch (e) {
      debugPrint('[LIVE][CHAT] poll error: $e');
    } finally {
      _chatInFlight = false;
    }
  }

  Future<void> sendChatMessage(String text) async {
    final tr = state.translation;
    final userId = state.localUserId ?? 0;
    if (tr == null) return;
    if (userId <= 0) return;

    final msg = text.trim();
    if (msg.isEmpty) {
      throw Exception('Нельзя отправлять пустые сообщения');
    }
    if (msg.length > 500) {
      throw Exception('Максимальная длина сообщения — 500 символов');
    }

    // ✅ Optimistic UI: сначала показываем сообщение в чате,
    // и только потом отправляем на сервер.
    final local = LiveChatMessage(
      messageId: _localTempChatId--,
      message: msg,
      dateAdd: '',
      author: 'Текущий пользователь',
      avatarUrl: '',
      isMine: true,
    );

    final merged = <LiveChatMessage>[...state.chatMessages, local];
    merged.sort((a, b) {
      final aNeg = a.messageId <= 0;
      final bNeg = b.messageId <= 0;
      if (aNeg != bNeg) return aNeg ? 1 : -1; // локальные (<=0) — в конец
      if (!aNeg) return a.messageId.compareTo(b.messageId);
      return b.messageId.compareTo(a.messageId); // -1, -2, -3...
    });

    if (!mounted) return;
    state = state.copyWith(
      chatSending: true,
      clearChatError: true,
      chatEmpty: false,
      chatMessages: merged,
    );

    try {
      final body = await _postApi('appSendMessageToChat', {
        'translation_id': tr.id,
        'user_id': userId,
        'message': msg,
      });

      if (!_isOkStatus(body['status'])) {
        throw Exception(_desc(body));
      }

      final incoming = _parseChatList(body['data']);

      if (incoming.isNotEmpty) {
        final merged2 = <LiveChatMessage>[
          ...state.chatMessages.where((m) => m.messageId != local.messageId),
        ];

        var newMax = state.lastChatMessageId;

        for (final m in incoming) {
          if (_chatKnownIds.add(m.messageId)) {
            merged2.add(m);
          }
          if (m.messageId > newMax) newMax = m.messageId;
        }

        merged2.sort((a, b) {
          final aNeg = a.messageId <= 0;
          final bNeg = b.messageId <= 0;
          if (aNeg != bNeg) return aNeg ? 1 : -1;
          if (!aNeg) return a.messageId.compareTo(b.messageId);
          return b.messageId.compareTo(a.messageId); // -1, -2, -3...
        });

        _chatPollMode = _ChatPollMode.incremental;

        if (!mounted) return;
        state = state.copyWith(
          chatMessages: merged2,
          lastChatMessageId: newMax,
          chatEmpty: false,
          clearChatError: true,
        );
      } else {
        await _refreshChatFull(userId: userId, translationId: tr.id);
      }
    } catch (e) {
      if (!mounted) return;

      final cleaned = state.chatMessages
          .where((m) => m.messageId != local.messageId)
          .toList(growable: false);

      state = state.copyWith(
        chatError: e.toString(),
        chatMessages: cleaned,
        chatEmpty: cleaned.where((m) => m.messageId > 0).isEmpty,
      );
      rethrow;
    } finally {
      if (!mounted) return;
      state = state.copyWith(chatSending: false);
    }
  }
  // ---------------- VAD ----------------

  void _startVad() {
    _vadTimer?.cancel();
    _vadTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      unawaited(_pollVad());
    });
  }

  void _stopVad() {
    _vadTimer?.cancel();
    _vadTimer = null;
    _lastTotalAudioEnergy = null;
    _lastTotalSamplesDuration = null;
    _smoothedLevel = 0.0;
    _lastSpeakingAt = DateTime.fromMillisecondsSinceEpoch(0);
    if (mounted) {
      state = state.copyWith(speaking: false, speakingLevel: 0);
    }
  }

  Future<void> _pollVad() async {
    final pc = _pc;
    if (pc == null) return;

    try {
      final reports = await pc.getStats();

      double? audioLevel;
      double? totalEnergy;
      double? totalDuration;

      for (final r in reports) {
        final type = (r.type ?? '').toString();
        final values = r.values;

        if (type != 'inbound-rtp' && type != 'inboundrtp') continue;

        final kind = (values['kind'] ?? values['mediaType'] ?? '').toString();
        if (kind != 'audio') continue;

        if (values['audioLevel'] != null) {
          final v = values['audioLevel'];
          final lvl = (v is num) ? v.toDouble() : double.tryParse(v.toString());
          if (lvl != null) audioLevel = lvl;
        }
        if (values['totalAudioEnergy'] != null) {
          final v = values['totalAudioEnergy'];
          final d = (v is num) ? v.toDouble() : double.tryParse(v.toString());
          if (d != null) totalEnergy = d;
        }
        if (values['totalSamplesDuration'] != null) {
          final v = values['totalSamplesDuration'];
          final d = (v is num) ? v.toDouble() : double.tryParse(v.toString());
          if (d != null) totalDuration = d;
        }
      }

      double level = 0.0;
      if (audioLevel != null) {
        final raw = audioLevel!;
        level = raw <= 1.0 ? raw : (raw / 32767.0);
      } else if (totalEnergy != null && totalDuration != null) {
        if (_lastTotalAudioEnergy != null &&
            _lastTotalSamplesDuration != null) {
          final dE = totalEnergy! - _lastTotalAudioEnergy!;
          final dT = totalDuration! - _lastTotalSamplesDuration!;
          if (dE.isFinite && dT.isFinite && dE >= 0 && dT > 0) {
            final power = dE / dT;
            level = (power * 8.0).clamp(0.0, 1.0);
          }
        }
        _lastTotalAudioEnergy = totalEnergy;
        _lastTotalSamplesDuration = totalDuration;
      }

      _smoothedLevel = (_smoothedLevel * 0.75) + (level * 0.25);

      final now = DateTime.now();
      final bool speakingNow = _smoothedLevel > 0.08;
      if (speakingNow) _lastSpeakingAt = now;
      final bool speaking =
          speakingNow || now.difference(_lastSpeakingAt).inMilliseconds < 450;

      if (!mounted) return;
      final lvlOut = _smoothedLevel.clamp(0.0, 1.0);
      if (state.speaking != speaking ||
          (state.speakingLevel - lvlOut).abs() > 0.03) {
        state = state.copyWith(speaking: speaking, speakingLevel: lvlOut);
      }
    } catch (_) {}
  }

  // ---------------- Prayer resolving ----------------

  Future<void> _resolvePrayerText(LiveTranslation tr) async {
    if (!mounted) return;

    if (tr.prayer_optional == 1) {
      state = state.copyWith(
        prayerTextLoading: false,
        prayerText: tr.prayer_optional_text,
        prayerTextError: null,
        clearPrayerTextError: true,
      );
      return;
    }

    if (tr.prayers_category_id <= 0 || tr.prayers_texts_id <= 0) {
      state = state.copyWith(
        prayerTextLoading: false,
        prayerText: tr.description,
        prayerTextError: null,
        clearPrayerTextError: true,
      );
      return;
    }

    state = state.copyWith(prayerTextLoading: true, clearPrayerTextError: true);

    try {
      final prayers = await _prayersRepo.getPrayersByCategory(
        tr.prayers_category_id,
      );

      String? resolved;
      for (final p in prayers) {
        if (p.id == tr.prayers_texts_id) {
          resolved = (p.text ?? '').toString();
          break;
        }
      }

      final textToShow = (resolved != null && resolved.trim().isNotEmpty)
          ? resolved
          : tr.description;

      if (!mounted) return;
      state = state.copyWith(
        prayerTextLoading: false,
        prayerText: textToShow,
        prayerTextError: null,
        clearPrayerTextError: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        prayerTextLoading: false,
        prayerText: tr.description,
        prayerTextError: e.toString(),
      );
    }
  }

  Future<void> _init() async {
    try {
      _chatInitialized = false;
      _chatInFlight = false;
      _chatKnownIds.clear();

      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearForcedExitMessage: true,
        status: 'Загрузка трансляции…',
      );

      final token = await _local.getToken();
      final localUserId = token == null ? null : int.tryParse(token.toString());

      ProfileRole? role;
      if (localUserId != null && localUserId > 0) {
        try {
          final profRepo = ref.read(profileRepositoryProvider);
          final prof = await profRepo.load();
          role = prof.role;
        } catch (_) {
          role = null;
        }
      }

      final tr = streamData.invited
          ? await _repo.fetchByInvite(streamData.invite)
          : await _repo.fetchById(streamData.id);

      OnlineInfo initialOnline = const OnlineInfo(countOnline: 0, users: []);

      if (localUserId != null && localUserId > 0) {
        initialOnline = await _repo.appUserOnlineInTranslation(
          translationId: tr.id,
          userId: localUserId,
        );
      }

      final canSpeak = _resolveCanSpeak(
        tr: tr,
        localUserId: localUserId,
        localRole: role,
        onlineUsers: initialOnline.users,
      );

      final canModerateUsers = _resolveCanModerate(
        tr: tr,
        localUserId: localUserId,
        localRole: role,
      );

      state = state.copyWith(
        isLoading: false,
        translation: tr,
        localUserId: localUserId,
        localRole: role,
        isOwner: canSpeak,
        canModerateUsers: canModerateUsers,
        participantsCount: initialOnline.countOnline,
        participants: initialOnline.users,
        status: 'Данные трансляции получены',
      );

      if (localUserId != null && localUserId > 0) {
        _startPresenceLoop(
          userId: localUserId,
          translationId: tr.id,
          pingImmediately: false,
        );
      }

      unawaited(_resolvePrayerText(tr));

      await _connectWsAndJoin(tr: tr, isOwner: canSpeak);
      await _setupWebRtcAndNegotiate(tr: tr, isOwner: canSpeak);
      await _applyAudioModeToTracks();
    } on PresenceBanException {
      await _handleBan();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        status: 'Ошибка: $e',
      );
    }
  }

  Future<void> moderateParticipant({
    required OnlineUser target,
    required TranslationUserModerationAction action,
  }) async {
    if (action == TranslationUserModerationAction.none) return;

    final tr = state.translation;
    final actorId = state.localUserId;

    if (tr == null) throw Exception('Трансляция не загружена');
    if (actorId == null || actorId <= 0) {
      throw Exception('Не найден локальный пользователь');
    }
    if (!state.canModerateUsers) {
      throw Exception('Недостаточно прав');
    }
    if (target.role != ProfileRole.layman) {
      throw Exception('Изменять можно только layman');
    }
    if (target.id == tr.ownerId) {
      throw Exception('Нельзя изменять владельца трансляции');
    }

    await _repo.moderateUserInTranslation(
      translationId: tr.id,
      actorUserId: actorId,
      targetUserId: target.id,
      action: action,
    );

    await _pingPresence(userId: actorId, translationId: tr.id);
  }

  Future<void> refresh() async {
    await _dispose(updateState: false);
    if (!mounted) return;
    state = LiveStreamState.initial();
    await _init();
  }

  Future<void> _applyAudioRoute() async {
    try {
      if (WebRTC.platformIsIOS) {
        await Helper.ensureAudioSession();
        await Helper.setAppleAudioConfiguration(
          AppleAudioConfiguration(
            appleAudioCategory: AppleAudioCategory.playAndRecord,
            appleAudioMode: AppleAudioMode.voiceChat,
          ),
        );
      }

      switch (state.preferredAudioRoute) {
        case AudioOutputRoute.earpiece:
          await Helper.setSpeakerphoneOn(false);
          break;
        case AudioOutputRoute.speaker:
          await Helper.setSpeakerphoneOn(true);
          break;
      }
    } catch (e) {
      debugPrint('[LIVE][AUDIO] failed to apply route: $e');
    }
  }

  Future<void> _applyAudioModeToTracks() async {
    final enable = state.audioMode.isAudible;

    try {
      final rs = state.remoteStream;
      if (rs != null) {
        for (final t in rs.getAudioTracks()) {
          t.enabled = enable;
        }
      }
    } catch (_) {}

    try {
      final ms = state.metronomeStream;
      if (ms != null) {
        for (final t in ms.getAudioTracks()) {
          t.enabled = enable;
        }
      }
    } catch (_) {}

    await _applyAudioRoute();
  }

  bool get _audioEnabled => state.audioMode.isAudible;

  Future<void> _connectWsAndJoin({
    required LiveTranslation tr,
    required bool isOwner,
  }) async {
    _log('WS: подключение…');

    _ws = SfuWsClient(wsUrl: _wsUrl);
    await _ws!.connect();

    if (!mounted) return;
    state = state.copyWith(wsConnected: true);

    final pin = isOwner ? tr.speakerPin : tr.listenerPin;

    final joinCompleter = Completer<void>();

    _wsSub = _ws!.stream.listen((msg) async {
      if ((msg['type'] ?? '').toString() == 'pong') return;

      if (msg.containsKey('status') && !msg.containsKey('type')) {
        final st = (msg['status'] ?? '').toString().toLowerCase().trim();
        if (st == 'success' || st == 'ok') {
          _log('WS: join success');

          if (msg['offerMtr'] != null) {
            _lastOfferMtrSdp = msg['offerMtr'].toString();
            if (mounted) {
              state = state.copyWith(metronomeAvailable: _audioEnabled);
            }
            if (state.metronomeOn && _audioEnabled) {
              await _setupMetronomeIfNeeded(
                tr: tr,
                offerSdp: _lastOfferMtrSdp!,
              );
            }
          }

          if (!joinCompleter.isCompleted) joinCompleter.complete();
          return;
        }

        final m = (msg['msg'] ?? bodyMessage(msg) ?? 'Join error').toString();
        if (!joinCompleter.isCompleted)
          joinCompleter.completeError(Exception(m));
        return;
      }

      if ((msg['type'] ?? '').toString() == 'answer') {
        final sdp = (msg['sdp'] ?? '').toString();
        final status = (msg['status'] ?? '').toString().toLowerCase().trim();
        _log('WS: answer received ($status)');
        if ((status == 'success' || status == 'ok') && sdp.isNotEmpty) {
          await _onAnswer(sdp);
        }
        return;
      }

      if ((msg['type'] ?? '').toString() == 'ice') {
        final cand = msg['candidate'];
        if (cand is Map) {
          final candidate = (cand['candidate'] ?? '').toString();
          final sdpMid = (cand['sdpMid'] ?? '').toString();
          final sdpMLineIndex = cand['sdpMLineIndex'];
          final idx = (sdpMLineIndex is num)
              ? sdpMLineIndex.toInt()
              : int.tryParse(sdpMLineIndex.toString()) ?? 0;

          if (candidate.isNotEmpty) {
            await _onRemoteIce(RTCIceCandidate(candidate, sdpMid, idx));
          }
        }
        return;
      }

      if ((msg['type'] ?? '').toString() == 'offerMtr') {
        final sdp = (msg['sdp'] ?? '').toString();
        if (sdp.isNotEmpty) {
          _lastOfferMtrSdp = sdp;

          if (mounted) {
            state = state.copyWith(metronomeAvailable: _audioEnabled);
          }

          if (state.metronomeOn && _audioEnabled) {
            await _setupMetronomeIfNeeded(tr: tr, offerSdp: sdp);
          }
        }
        return;
      }

      if ((msg['type'] ?? '').toString() == 'iceMtr' && _mtrPc != null) {
        final cand = msg['candidate'];
        if (cand is Map) {
          final candidate = (cand['candidate'] ?? '').toString();
          final sdpMid = (cand['sdpMid'] ?? '').toString();
          final sdpMLineIndex = cand['sdpMLineIndex'];
          final idx = (sdpMLineIndex is num)
              ? sdpMLineIndex.toInt()
              : int.tryParse(sdpMLineIndex.toString()) ?? 0;

          if (candidate.isNotEmpty) {
            try {
              await _mtrPc!.addCandidate(
                RTCIceCandidate(candidate, sdpMid, idx),
              );
            } catch (_) {}
          }
        }
        return;
      }

      if ((msg['status'] ?? '').toString().toLowerCase().trim() == 'error') {
        _log('WS error: ${msg['msg']}');
        return;
      }
    });

    _log('WS: join…');
    await _ws!.join(roomId: tr.roomId, pin: pin);
    await joinCompleter.future;
  }

  String? bodyMessage(Map msg) {
    if (msg['description'] != null) return msg['description'].toString();
    if (msg['msg'] != null) return msg['msg'].toString();
    return null;
  }

  // ===== Main RTC =====
  Future<void> _setupWebRtcAndNegotiate({
    required LiveTranslation tr,
    required bool isOwner,
  }) async {
    _log('RTC: createPeerConnection…');

    final config = <String, dynamic>{
      'iceServers': [
        {
          'urls': 'turn:media.molitvamira.ru:3478?transport=udp',
          'username': tr.coturnUser,
          'credential': tr.coturnPass,
        },
        {
          'urls': 'turn:media.molitvamira.ru:3478?transport=tcp',
          'username': tr.coturnUser,
          'credential': tr.coturnPass,
        },
      ],
      'sdpSemantics': 'unified-plan',
    };

    _pc = await createPeerConnection(config);

    _pc!.onConnectionState = (s) => _log('RTC: connectionState=$s');
    _pc!.onIceConnectionState = (s) => _log('RTC: iceState=$s');

    _pc!.onIceCandidate = (c) {
      if (c.candidate == null) return;
      _ws?.send({
        'type': 'ice',
        'candidate': {
          'candidate': c.candidate,
          'sdpMid': c.sdpMid,
          'sdpMLineIndex': c.sdpMLineIndex,
        },
      });
    };

    _pc!.onTrack = (e) async {
      if (e.track.kind != 'audio') return;

      final stream = (e.streams.isNotEmpty) ? e.streams.first : null;
      if (stream != null) {
        if (!mounted) return;
        state = state.copyWith(remoteStream: stream);
        await _applyAudioModeToTracks();
        _log('RTC: remote audio track received');
      }
    };

    if (isOwner) {
      _audioTransceiver = await _pc!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv),
      );

      try {
        _localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });
        final tracks = _localStream!.getAudioTracks();
        if (tracks.isNotEmpty) {
          _micTrack = tracks.first;
          _micTrack!.enabled = false;
          if (mounted) state = state.copyWith(micOn: false);
          await _audioTransceiver!.sender.replaceTrack(_micTrack);
          _log('RTC: mic granted, replaceTrack set (OFF)');
        }
      } catch (e) {
        _log('RTC: mic denied ($e) -> recvonly');
        _audioTransceiver!.setDirection(TransceiverDirection.RecvOnly);
        if (mounted) state = state.copyWith(micOn: false);
      }
    } else {
      _audioTransceiver = await _pc!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
    }

    _log('RTC: createOffer…');
    final offer = await _pc!.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 0,
    });
    await _pc!.setLocalDescription(offer);

    _ws?.send({'type': 'offer', 'sdp': offer.sdp});
    _log('RTC: offer sent, wait answer…');
  }

  Future<void> _onAnswer(String sdp) async {
    final pc = _pc;
    if (pc == null) return;

    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));

    if (_pendingIce.isNotEmpty) {
      for (final c in _pendingIce) {
        try {
          await pc.addCandidate(c);
        } catch (_) {}
      }
      _pendingIce.clear();
    }

    if (!mounted) return;
    state = state.copyWith(rtcConnected: true);
    _log('RTC: connected');

    _startVad();
  }

  Future<void> _onRemoteIce(RTCIceCandidate c) async {
    final pc = _pc;
    if (pc == null) return;

    final rd = await pc.getRemoteDescription();
    if (rd == null) {
      _pendingIce.add(c);
      return;
    }
    try {
      await pc.addCandidate(c);
    } catch (_) {}
  }

  // ===== Metronome RTC =====
  Future<void> _setupMetronomeIfNeeded({
    required LiveTranslation tr,
    required String offerSdp,
  }) async {
    if (_mtrPc != null) return;
    if (!_audioEnabled) return;

    _log('MTR: setup…');

    final config = <String, dynamic>{
      'iceServers': [
        {
          'urls': 'turn:media.molitvamira.ru:3478?transport=udp',
          'username': tr.coturnUser,
          'credential': tr.coturnPass,
        },
        {
          'urls': 'turn:media.molitvamira.ru:3478?transport=tcp',
          'username': tr.coturnUser,
          'credential': tr.coturnPass,
        },
      ],
      'sdpSemantics': 'unified-plan',
    };

    _mtrPc = await createPeerConnection(config);
    _mtrPc!.onIceCandidate = (c) {
      if (c.candidate == null) return;
      _ws?.send({
        'type': 'iceMtr',
        'candidate': {
          'candidate': c.candidate,
          'sdpMid': c.sdpMid,
          'sdpMLineIndex': c.sdpMLineIndex,
        },
      });
    };

    _mtrPc!.onTrack = (e) async {
      if (e.track.kind != 'audio') return;
      final stream = (e.streams.isNotEmpty) ? e.streams.first : null;
      if (stream != null) {
        if (!mounted) return;
        state = state.copyWith(metronomeStream: stream);
        await _applyAudioModeToTracks();
        _log('MTR: metronome track received');
      }
    };

    await _mtrPc!.setRemoteDescription(
      RTCSessionDescription(offerSdp, 'offer'),
    );
    final answer = await _mtrPc!.createAnswer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 0,
    });
    await _mtrPc!.setLocalDescription(answer);

    _ws?.send({'type': 'answerMtr', 'sdp': answer.sdp});
    _log('MTR: answer sent');
  }

  Future<void> _disposeMetronome({required bool updateState}) async {
    try {
      await _mtrPc?.close();
    } catch (_) {}
    _mtrPc = null;

    if (updateState && mounted) {
      state = state.copyWith(metronomeStream: null, metronomeOn: false);
    }
  }

  // ===== UI actions =====

  Future<void> selectAudioRoute(AudioOutputRoute route) async {
    if (!mounted) return;

    state = state.copyWith(preferredAudioRoute: route);

    if (_audioEnabled) {
      await _applyAudioRoute();
    }

    _log('AUDIO ROUTE: ${route.label}');
  }

  Future<void> toggleSound() async {
    final next = switch (state.audioMode) {
      AudioOutputMode.muted => AudioOutputMode.ear,
      AudioOutputMode.ear => AudioOutputMode.muted,
    };

    if (!mounted) return;
    state = state.copyWith(audioMode: next);

    await _applyAudioModeToTracks();

    if (next == AudioOutputMode.muted) {
      if (mounted) state = state.copyWith(metronomeAvailable: false);
      await _disposeMetronome(updateState: true);
    } else {
      if (mounted) {
        state = state.copyWith(metronomeAvailable: _lastOfferMtrSdp != null);
      }

      if (state.metronomeOn &&
          _lastOfferMtrSdp != null &&
          state.translation != null) {
        await _setupMetronomeIfNeeded(
          tr: state.translation!,
          offerSdp: _lastOfferMtrSdp!,
        );
      }
    }

    _log('AUDIO: ${next.label}');
  }

  Future<void> toggleMetronome() async {
    final tr = state.translation;
    if (tr == null) return;

    if (!_audioEnabled) {
      _log('Метроном недоступен: звук выключен');
      return;
    }

    if (state.metronomeOn) {
      await _disposeMetronome(updateState: true);
      _log('MTR: stopped');
      return;
    }

    if (_lastOfferMtrSdp == null) {
      _log('Метроном недоступен: offerMtr ещё не приходил');
      return;
    }

    if (!mounted) return;
    state = state.copyWith(metronomeOn: true);
    await _setupMetronomeIfNeeded(tr: tr, offerSdp: _lastOfferMtrSdp!);
    _log('MTR: started');
  }

  Future<void> toggleMic() async {
    if (!state.isOwner) return;

    if (_micTrack == null) {
      try {
        _localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });
        final tracks = _localStream!.getAudioTracks();
        if (tracks.isNotEmpty) {
          _micTrack = tracks.first;
          await _audioTransceiver?.sender.replaceTrack(_micTrack);
        }
      } catch (e) {
        _log('MIC: denied ($e)');
        return;
      }
    }

    final next = !state.micOn;
    if (!mounted) return;
    state = state.copyWith(micOn: next);

    _micTrack?.enabled = next;

    _log(next ? 'MIC: ON' : 'MIC: OFF');
  }

  Future<void> exit() async => _dispose(updateState: false);

  Future<void> stopTranslation() async {
    final tr = state.translation;
    final localUserId = state.localUserId;

    if (tr == null) {
      throw Exception('Трансляция не загружена');
    }
    if (localUserId == null || localUserId <= 0) {
      throw Exception('Не найден локальный пользователь');
    }
    if (tr.ownerId != localUserId) {
      throw Exception('Останавливать трансляцию может только её создатель');
    }

    if (mounted) {
      state = state.copyWith(
        clearError: true,
        status: 'Остановка трансляции…',
      );
    }

    await _repo.stopTranslation(
      translationId: tr.id,
      userId: localUserId,
    );

    await _dispose(updateState: false);
  }

  void _onProviderDispose() {
    unawaited(_dispose(updateState: false));
  }

  Future<void> _dispose({required bool updateState}) async {
    try {
      _stopPresenceLoop();
      _stopVad();

      // Сохраняем ссылки до очистки state, чтобы корректно остановить треки
      final oldRemoteStream = state.remoteStream;
      final oldMetronomeStream = state.metronomeStream;

      // В release autoDispose может не успеть — чистим всегда, чтобы не оставались “мертвые” ссылки
      if (mounted) {
        state = state.copyWith(
          wsConnected: false,
          rtcConnected: false,
          audioMode: AudioOutputMode.muted,
          micOn: false,
          remoteStream: null,
          metronomeStream: null,
          metronomeOn: false,
          metronomeAvailable: false,
          speaking: false,
          speakingLevel: 0,
          chatLoading: false,
          chatSending: false,
          chatMessages: const [],
          lastChatMessageId: 0,
          clearChatError: true,
        );
      }

      // Освобождаем удалённые потоки (важно для Android/release)
      try {
        final rs = oldRemoteStream;
        if (rs != null) {
          for (final t in rs.getTracks()) {
            try {
              t.stop();
            } catch (_) {}
          }
          try {
            await rs.dispose();
          } catch (_) {}
        }
      } catch (_) {}

      try {
        final ms = oldMetronomeStream;
        if (ms != null) {
          for (final t in ms.getTracks()) {
            try {
              t.stop();
            } catch (_) {}
          }
          try {
            await ms.dispose();
          } catch (_) {}
        }
      } catch (_) {}

      await _wsSub?.cancel();
      _wsSub = null;

      await _disposeMetronome(updateState: false);

      try {
        await _ws?.close();
      } catch (_) {}
      _ws = null;

      if (_localStream != null) {
        for (final t in _localStream!.getTracks()) {
          try {
            t.stop();
          } catch (_) {}
        }
        try {
          await _localStream!.dispose();
        } catch (_) {}
      }
      _localStream = null;
      _micTrack = null;

      try {
        await _pc?.close();
      } catch (_) {}
      _pc = null;

      try {
        await Helper.clearAndroidCommunicationDevice();
      } catch (_) {}

      _audioTransceiver = null;
      _pendingIce.clear();
    } catch (_) {}
  }
}
