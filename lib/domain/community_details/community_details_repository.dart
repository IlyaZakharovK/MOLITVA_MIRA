import 'community_details.dart';
import 'community_post.dart';

abstract class CommunityDetailsRepository {
  Future<CommunityDetails> fetchCommunityByTitle(String title);
  Future<List<CommunityPost>> fetchCommunityPosts(String title);
}
