class CommunityItem {
  final String id;
  final String title;
  final String subtitle;
  final int members;
  final String? imageAsset;

  const CommunityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.members,
    this.imageAsset,
  });
}
