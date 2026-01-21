import 'chat_message.dart';

abstract class StreamChatRepository {
  Future<List<ChatMessage>> fetchMessages();
  Future<void> sendMessage(String text);
}
