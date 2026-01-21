class MyCommunityItem {
  final String id;
  final String title;
  final String description;

  /// PNG asset пока (потом будет url)
  final String imageAsset;

  final int membersCount;

  /// true если сообщество принадлежит пользователю
  final bool isMine;

  const MyCommunityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.membersCount,
    required this.isMine,
  });
}
