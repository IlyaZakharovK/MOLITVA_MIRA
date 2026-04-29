import 'help_chat_message_item.dart';

abstract class HelpRepository {

  Future<List<HelpChatMessageItem>> fetchHelpChat();

  Future<bool> sendMessage({required String message});

  Future<List<HelpChatMessageItem>> refreshHelpChat({required int lastMessageId});

}
