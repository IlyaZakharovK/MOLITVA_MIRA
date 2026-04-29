import 'community_data_item.dart';
import 'community_item.dart';

abstract class CommunitiesRepository {
  Future<CommunityDataItem> fetchCommunities({
    required int page,
    required int limit,
    required bool my
  });

  Future<List<CommunityItem>> searchCommunities({required String request});

  Future<bool> createGroup({
    required int type,
    required String name,
    required String description,
  });
  Future<bool> subUnSub({
    required int action,
    required int groupId
  });
}
