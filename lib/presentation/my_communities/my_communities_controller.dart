import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/my_communities/fake_my_communities_repository.dart';
import '../../domain/my_communities/my_communities_repository.dart';
import '../../domain/my_communities/my_community_item.dart';
import '../../domain/my_communities/my_community_tab.dart';
import '../../providers.dart';

/// маленький хак чтобы не словить конфликт имен при копипасте
/// (можешь убрать и вернуть FakeMyCommunitiesRepository напрямую)
class FakeMyMyCommunitiesRepositoryFix {
  MyCommunitiesRepository get repo => FakeMyCommunitiesRepository();
}

final myCommunitiesTabProvider = StateProvider<MyCommunityTab>((ref) {
  return MyCommunityTab.subscribed;
});

final myCommunitiesControllerProvider =
AsyncNotifierProvider<MyCommunitiesController, List<MyCommunityItem>>(
  MyCommunitiesController.new,
);

class MyCommunitiesController extends AsyncNotifier<List<MyCommunityItem>> {
  late final MyCommunitiesRepository _repo;

  @override
  Future<List<MyCommunityItem>> build() async {
    _repo = ref.watch(myCommunitiesRepositoryProvider);
    return _repo.fetchMyCommunities();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.fetchMyCommunities());
  }
}

final filteredMyCommunitiesProvider =
Provider<AsyncValue<List<MyCommunityItem>>>((ref) {
  final tab = ref.watch(myCommunitiesTabProvider);
  final async = ref.watch(myCommunitiesControllerProvider);

  return async.whenData((list) {
    return list.where((e) {
      if (tab == MyCommunityTab.mine) return e.isMine;
      return !e.isMine;
    }).toList();
  });
});
