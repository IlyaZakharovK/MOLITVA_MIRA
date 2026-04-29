class PostDetails {
  final String id;

  final String author;
  final String timeLabel;
  final String text;
  final bool hasImage;

  final int likes;
  final int comments;

  const PostDetails({
    required this.id,
    required this.author,
    required this.timeLabel,
    required this.text,
    required this.hasImage,
    required this.likes,
    required this.comments,
  });

  PostDetails copyWith({
    String? author,
    String? timeLabel,
    String? text,
    bool? hasImage,
    int? likes,
    int? comments,
  }) {
    return PostDetails(
      id: id,
      author: author ?? this.author,
      timeLabel: timeLabel ?? this.timeLabel,
      text: text ?? this.text,
      hasImage: hasImage ?? this.hasImage,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
    );
  }
}
