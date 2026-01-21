import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/streaming/fake_stream_chat_repository.dart';
import '../../domain/streaming/chat_message.dart';
import '../../domain/streaming/stream_chat_repository.dart';

final streamChatRepositoryProvider = Provider<StreamChatRepository>((ref) {
  return FakeStreamChatRepository();
});

final liveStreamChatProvider =
AsyncNotifierProvider<LiveStreamChatController, List<ChatMessage>>(
  LiveStreamChatController.new,
);

class LiveStreamChatController extends AsyncNotifier<List<ChatMessage>> {
  late final StreamChatRepository _repo;

  @override
  Future<List<ChatMessage>> build() async {
    _repo = ref.watch(streamChatRepositoryProvider);
    return _repo.fetchMessages();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.fetchMessages());
  }

  Future<void> send(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    await _repo.sendMessage(t);
    // обновляем список
    state = await AsyncValue.guard(() => _repo.fetchMessages());
  }
}
