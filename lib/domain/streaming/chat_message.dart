// chat_message.dart
class ChatMessage {
  final int messageId;
  final String message;
  final String author;
  final String avatarUrl;
  final String dateAdd; // обычно "14:33" от API
  final DateTime createdAt;
  final bool isMine;

  const ChatMessage({
    required this.messageId,
    required this.message,
    required this.author,
    required this.avatarUrl,
    required this.dateAdd,
    required this.createdAt,
    required this.isMine,
  });

  factory ChatMessage.fromApiJson(
      Map<String, dynamic> json, {
        required bool isMine,
      }) {
    final id =
        int.tryParse((json['message_id'] ?? json['id'] ?? 0).toString()) ?? 0;
    final message = (json['message'] ?? json['text'] ?? '').toString();
    final author = (json['author'] ?? '').toString();
    final avatarUrl = (json['avatar_url'] ?? '').toString();
    final dateAdd = (json['date_add'] ?? '').toString();

    return ChatMessage(
      messageId: id,
      message: message,
      author: author,
      avatarUrl: avatarUrl,
      dateAdd: dateAdd,
      createdAt: _parseDate(dateAdd),
      isMine: isMine,
    );
  }

  static DateTime _parseDate(String raw) {
    final s = raw.trim();
    final now = DateTime.now();

    final hm = RegExp(r'^\d{1,2}:\d{2}$');
    if (hm.hasMatch(s)) {
      final parts = s.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return DateTime(now.year, now.month, now.day, h, m);
    }

    try {
      return DateTime.parse(s);
    } catch (_) {
      return now;
    }
  }
}
