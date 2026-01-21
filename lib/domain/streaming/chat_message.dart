class ChatMessage {
  final String id;
  final String author;
  final String text;
  final DateTime createdAt;
  final bool isMine;

  const ChatMessage({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    required this.isMine,
  });
}
