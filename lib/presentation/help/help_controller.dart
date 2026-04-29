import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/help/help_chat_message_item.dart';
import '../../domain/help/help_repository.dart';
import '../../providers.dart';

final helpChatControllerProvider =
StateNotifierProvider.autoDispose<HelpChatController, HelpChatState>((ref) {
  final repo = ref.watch(helpChatRepositoryProvider);
  return HelpChatController(repo);
});

class HelpChatState {
  final bool isLoading;
  final bool isRefreshing;
  final bool isSending;
  final String? error;
  final List<HelpChatMessageItem> messages;
  final int lastMessageId;

  const HelpChatState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.isSending = false,
    this.error,
    this.messages = const [],
    this.lastMessageId = 0,
  });

  bool get isEmpty => !isLoading && messages.isEmpty;

  HelpChatState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? isSending,
    Object? error = _sentinel,
    List<HelpChatMessageItem>? messages,
    int? lastMessageId,
  }) {
    return HelpChatState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSending: isSending ?? this.isSending,
      error: identical(error, _sentinel) ? this.error : error as String?,
      messages: messages ?? this.messages,
      lastMessageId: lastMessageId ?? this.lastMessageId,
    );
  }
}

const _sentinel = Object();

class HelpChatController extends StateNotifier<HelpChatState> {
  final HelpRepository _repo;

  Timer? _pollTimer;
  bool _pollInFlight = false;
  final Set<int> _knownIds = <int>{};

  HelpChatController(this._repo) : super(const HelpChatState(isLoading: true)) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadInitial();
    _startPolling();
  }

  Future<void> _loadInitial() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final items = await _repo.fetchHelpChat();
      final sorted = _normalize(items);

      _knownIds
        ..clear()
        ..addAll(sorted.map((e) => e.id));

      state = state.copyWith(
        isLoading: false,
        error: null,
        messages: sorted,
        lastMessageId: _lastIdFrom(sorted),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        messages: const [],
        lastMessageId: 0,
      );
    }
  }

  Future<void> refresh() async {
    try {
      state = state.copyWith(isRefreshing: true, error: null);

      final items = await _repo.fetchHelpChat();
      final sorted = _normalize(items);

      _knownIds
        ..clear()
        ..addAll(sorted.map((e) => e.id));

      state = state.copyWith(
        isRefreshing: false,
        error: null,
        messages: sorted,
        lastMessageId: _lastIdFrom(sorted),
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> retry() async => _loadInitial();

  Future<void> sendMessage(String text) async {
    final msg = text.trim();

    if (msg.isEmpty) {
      throw Exception('Поле сообщения не должно быть пустым');
    }
    if (msg.length > 500) {
      throw Exception('Сообщение не должно превышать 500 символов');
    }

    try {
      state = state.copyWith(isSending: true, error: null);

      final ok = await _repo.sendMessage(message: msg);
      if (!ok) {
        throw Exception('Не удалось отправить сообщение');
      }

      state = state.copyWith(isSending: false, error: null);
      await refresh();
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
      rethrow;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
          (_) => _pollUpdates(),
    );
  }

  Future<void> _pollUpdates() async {
    if (_pollInFlight) return;
    if (state.isLoading || state.isSending) return;

    _pollInFlight = true;
    try {
      if (state.lastMessageId <= 0) {
        final items = await _repo.fetchHelpChat();
        final sorted = _normalize(items);

        _knownIds
          ..clear()
          ..addAll(sorted.map((e) => e.id));

        state = state.copyWith(
          error: null,
          messages: sorted,
          lastMessageId: _lastIdFrom(sorted),
        );
        return;
      }

      final incoming = await _repo.refreshHelpChat(
        lastMessageId: state.lastMessageId,
      );

      if (incoming.isEmpty) return;

      final merged = <HelpChatMessageItem>[...state.messages];
      var changed = false;

      for (final item in _normalize(incoming)) {
        if (_knownIds.add(item.id)) {
          merged.add(item);
          changed = true;
        }
      }

      if (!changed) return;

      final sorted = _normalize(merged);
      state = state.copyWith(
        error: null,
        messages: sorted,
        lastMessageId: _lastIdFrom(sorted),
      );
    } catch (_) {
      // Тихий фоновой опрос без шумных ошибок для пользователя.
    } finally {
      _pollInFlight = false;
    }
  }

  List<HelpChatMessageItem> _normalize(List<HelpChatMessageItem> items) {
    final map = <int, HelpChatMessageItem>{};
    for (final item in items) {
      map[item.id] = item;
    }
    final list = map.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  int _lastIdFrom(List<HelpChatMessageItem> items) {
    if (items.isEmpty) return 0;
    return items.fold<int>(0, (maxId, item) => item.id > maxId ? item.id : maxId);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
