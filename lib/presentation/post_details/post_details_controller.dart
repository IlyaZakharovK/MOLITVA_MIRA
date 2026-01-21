import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/post_details/fake_post_details_repository.dart';
import '../../domain/post_details/post_comment.dart';
import '../../domain/post_details/post_details.dart';
import '../../domain/post_details/post_details_repository.dart';

final postDetailsRepositoryProvider = Provider<PostDetailsRepository>((ref) {
  return FakePostDetailsRepository();
});

class PostDetailsState {
  final PostDetails post;
  final List<PostComment> comments;

  const PostDetailsState({
    required this.post,
    required this.comments,
  });

  PostDetailsState copyWith({
    PostDetails? post,
    List<PostComment>? comments,
  }) {
    return PostDetailsState(
      post: post ?? this.post,
      comments: comments ?? this.comments,
    );
  }
}

final postDetailsControllerProvider = AsyncNotifierProvider.family<
    PostDetailsController,
    PostDetailsState,
    String>(
  PostDetailsController.new,
);

class PostDetailsController extends FamilyAsyncNotifier<PostDetailsState, String> {
  late final PostDetailsRepository _repo;
  late final String _postId;

  @override
  Future<PostDetailsState> build(String postId) async {
    _repo = ref.watch(postDetailsRepositoryProvider);
    _postId = postId;

    final post = await _repo.fetchPostById(postId);
    final comments = await _repo.fetchComments(postId);

    return PostDetailsState(post: post, comments: comments);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final post = await _repo.fetchPostById(_postId);
      final comments = await _repo.fetchComments(_postId);
      return PostDetailsState(post: post, comments: comments);
    });
  }

  void likeOnce() {
    final cur = state.value;
    if (cur == null) return;
    state = AsyncData(cur.copyWith(post: cur.post.copyWith(likes: cur.post.likes + 1)));
  }

  Future<void> addComment(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;

    await _repo.addComment(postId: _postId, text: t);

    final post = await _repo.fetchPostById(_postId);
    final comments = await _repo.fetchComments(_postId);
    state = AsyncData(PostDetailsState(post: post, comments: comments));
  }
}
