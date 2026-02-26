import 'community_details.dart';

abstract class CommunityDetailsRepository {
  Future<Community> fetchCommunity({required int id});

  Future<Community> fetchCommunityByInvite({required String invite});

  Future<List<Post>> fetchMorePosts({
    required int id,
    required int limit,
    required int page,
  });

  Future<bool> createPost({
    required int groupId,
    required int ownerId,
    required String title,
    required String message,
  });

  Future<bool> createComment({
    required int groupId,
    required int postId,
    required String message,
  });

  Future<bool> subUnSub({
    required int action,
    required int groupId
  });


}
