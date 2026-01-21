import '../../domain/communities/communities_repository.dart';
import '../../domain/communities/community_item.dart';

class FakeCommunitiesRepository implements CommunitiesRepository {
  final Set<String> _joined = {};

  @override
  Future<List<CommunityItem>> fetchCommunities() async {
    await Future<void>.delayed(const Duration(milliseconds: 750)); // имитация сети

    return const [
      CommunityItem(
        id: 'c1',
        title: 'Святые покровители\nдня',
        subtitle: 'Вспомним святых и помолимся их\nзаступничеству ежедневно.',
        members: 1023,
        imageAsset: 'assets/png/community_1.png',
      ),
      CommunityItem(
        id: 'c2',
        title: 'Господи, помилуй\nгрешных',
        subtitle: 'Молимся о прощении и укреплении в покаянии.',
        members: 58,
        imageAsset: 'assets/png/community_2.png',
      ),
      CommunityItem(
        id: 'c3',
        title: 'Молитвы к Божией\nМатери',
        subtitle: 'Обращаемся с поклоном и упованием к Царице Небесной.',
        members: 2587,
        imageAsset: 'assets/png/community_3.png',
      ),
      CommunityItem(
        id: 'c4',
        title: 'Утренние молитвы\nвместе',
        subtitle: 'Начинаем день с Богом — вместе читаем утреннее правило.',
        members: 118,
        imageAsset: 'assets/png/community_4.png',
      ),
    ];
  }

  @override
  Future<void> joinCommunity(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _joined.add(id); // можно использовать, если хочешь отображать "Вступили"
  }
}
