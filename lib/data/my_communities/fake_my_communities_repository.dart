import '../../domain/my_communities/my_community_item.dart';
import '../../domain/my_communities/my_communities_repository.dart';

class FakeMyCommunitiesRepository implements MyCommunitiesRepository {
  @override
  Future<List<MyCommunityItem>> fetchMyCommunities() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    return const [
      MyCommunityItem(
        id: 'mc1',
        title: 'Молитва за мир',
        description: 'Сообщество для совместной молитвы о мире.',
        imageAsset: 'assets/png/community_1.png',
        membersCount: 1023,
        isMine: false,
      ),
      MyCommunityItem(
        id: 'mc2',
        title: 'Утренняя молитва',
        description: 'Каждое утро начинаем день с молитвы.',
        imageAsset: 'assets/png/community_2.png',
        membersCount: 412,
        isMine: false,
      ),
      MyCommunityItem(
        id: 'mc3',
        title: 'Храм Святителя Николая',
        description: 'Официальное сообщество храма.',
        imageAsset: 'assets/png/community_3.png',
        membersCount: 215,
        isMine: true,
      ),
      MyCommunityItem(
        id: 'mc4',
        title: 'Молитвы к Божией Матери',
        description: 'Ежедневные молитвы и прошения.',
        imageAsset: 'assets/png/community_4.png',
        membersCount: 2587,
        isMine: true,
      ),
    ];
  }
}
