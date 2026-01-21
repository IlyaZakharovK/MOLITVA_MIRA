class NewsPost {
  final String id;
  final String author;
  final String timeLabel; // пока строка, позже будет DateTime
  final String text;
  final bool hasImage;
  final int likes;
  final int comments;

  const NewsPost({
    required this.id,
    required this.author,
    required this.timeLabel,
    required this.text,
    required this.hasImage,
    required this.likes,
    required this.comments,
  });
}

