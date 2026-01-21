class CommunityDetails {
  final String title;
  final String description;
  final int membersCount;
  final bool isSubscribed;

  const CommunityDetails({
    required this.title,
    required this.description,
    required this.membersCount,
    required this.isSubscribed,
  });

  CommunityDetails copyWith({
    String? title,
    String? description,
    int? membersCount,
    bool? isSubscribed,
  }) {
    return CommunityDetails(
      title: title ?? this.title,
      description: description ?? this.description,
      membersCount: membersCount ?? this.membersCount,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}
