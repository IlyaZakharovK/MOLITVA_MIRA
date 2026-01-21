import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/communities/community_item.dart';
import '../../domain/communities/communities_repository.dart';
import '../../providers.dart';

final communitiesControllerProvider =
AsyncNotifierProvider<CommunitiesController, List<CommunityItem>>(
  CommunitiesController.new,
);

class CommunitiesController extends AsyncNotifier<List<CommunityItem>> {
  late final CommunitiesRepository _repo;

  @override
  Future<List<CommunityItem>> build() async {
    _repo = ref.watch(communitiesRepositoryProvider);
    return _repo.fetchCommunities();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.fetchCommunities());
  }

  Future<void> join(String id) async {
    // Можно сделать optimistic update, но пока просто запрос + обновление
    await _repo.joinCommunity(id);
    await refresh();
  }
}
