import 'post_details.dart';
import 'post_comment.dart';

abstract class PostDetailsRepository {
  Future<PostDetails> fetchPostById(String id);

  Future<List<PostComment>> fetchComments(String postId);
  Future<void> addComment({required String postId, required String text});
}