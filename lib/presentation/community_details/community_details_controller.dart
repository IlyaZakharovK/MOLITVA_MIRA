import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/community_details/fake_community_details_repository.dart';
import '../../domain/community_details/community_details.dart';
import '../../domain/community_details/community_details_repository.dart';
import '../../domain/community_details/community_post.dart';

class CommunityDetailsState {
  final CommunityDetails community;
  final List<CommunityPost> posts;

  const CommunityDetailsState({
    required this.community,
    required this.posts,
  });

  CommunityDetailsState copyWith({
    CommunityDetails? community,
    List<CommunityPost>? posts,
  }) {
    return CommunityDetailsState(
      community: community ?? this.community,
      posts: posts ?? this.posts,
    );
  }
}

final communityDetailsRepositoryProvider = Provider<CommunityDetailsRepository>((ref) {
  return FakeCommunityDetailsRepository();
});

final communityDetailsControllerProvider = AsyncNotifierProvider.family<
    CommunityDetailsController,
    CommunityDetailsState,
    String>(
  CommunityDetailsController.new,
);

class CommunityDetailsController
    extends FamilyAsyncNotifier<CommunityDetailsState, String> {
  late final CommunityDetailsRepository _repo;
  late final String _title;

  @override
  Future<CommunityDetailsState> build(String title) async {
    _repo = ref.watch(communityDetailsRepositoryProvider);
    _title = title;

    final community = await _repo.fetchCommunityByTitle(title);
    final posts = await _repo.fetchCommunityPosts(title);

    return CommunityDetailsState(community: community, posts: posts);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final community = await _repo.fetchCommunityByTitle(_title);
      final posts = await _repo.fetchCommunityPosts(_title);
      return CommunityDetailsState(community: community, posts: posts);
    });
  }

  Future<void> toggleSubscribe() async {
    final current = state.value;
    if (current == null) return;

    final c = current.community;
    final next = c.copyWith(
      isSubscribed: !c.isSubscribed,
      membersCount: c.membersCount + (c.isSubscribed ? -1 : 1),
    );

    state = AsyncData(current.copyWith(community: next));
  }
}
