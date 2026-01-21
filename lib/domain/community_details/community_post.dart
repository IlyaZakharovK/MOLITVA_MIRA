class CommunityPost {
  final String id;
  final String communityTitle;
  final String author;
  final String timeLabel;
  final String text;
  final bool hasImage;
  final int likes;
  final int comments;

  const CommunityPost({
    required this.id,
    required this.communityTitle,
    required this.author,
    required this.timeLabel,
    required this.text,
    required this.hasImage,
    required this.likes,
    required this.comments,
  });
}
