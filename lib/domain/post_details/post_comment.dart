class PostComment {
  final String id;
  final String postId;
  final String author;
  final String text;
  final DateTime createdAt;
  final bool isMine;

  const PostComment({
    required this.id,
    required this.postId,
    required this.author,
    required this.text,
    required this.createdAt,
    required this.isMine,
  });
}
