import 'community_item.dart';

abstract class CommunitiesRepository {
  Future<List<CommunityItem>> fetchCommunities();
  Future<void> joinCommunity(String id);
}
