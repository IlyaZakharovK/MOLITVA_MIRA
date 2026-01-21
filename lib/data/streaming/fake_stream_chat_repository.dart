import '../../domain/streaming/chat_message.dart';
import '../../domain/streaming/stream_chat_repository.dart';

class FakeStreamChatRepository implements StreamChatRepository {
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'm1',
      author: 'Админ',
      text: 'Добро пожаловать в трансляцию 🙏',
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
      isMine: false,
    ),
    ChatMessage(
      id: 'm2',
      author: 'Екатерина',
      text: 'Спаси Господи всех!',
      createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
      isMine: false,
    ),
    ChatMessage(
      id: 'm3',
      author: 'Вы',
      text: 'Аминь.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      isMine: true,
    ),
  ];

  @override
  Future<List<ChatMessage>> fetchMessages() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return List<ChatMessage>.from(_messages);
  }

  @override
  Future<void> sendMessage(String text) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _messages.add(
      ChatMessage(
        id: 'm${_messages.length + 1}',
        author: 'Вы',
        text: text,
        createdAt: DateTime.now(),
        isMine: true,
      ),
    );
  }
}
