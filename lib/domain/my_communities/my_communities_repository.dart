import 'my_community_item.dart';

abstract class MyCommunitiesRepository {
  Future<List<MyCommunityItem>> fetchMyCommunities();
}
