enum MyCommunityTab {
  subscribed,
  mine,
}

extension MyCommunityTabUi on MyCommunityTab {
  String get label => switch (this) {
    MyCommunityTab.subscribed => 'Подписки',
    MyCommunityTab.mine => 'Мои сообщества',
  };
}
