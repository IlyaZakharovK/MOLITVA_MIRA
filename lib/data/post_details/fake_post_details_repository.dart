import '../../domain/post_details/post_comment.dart';
import '../../domain/post_details/post_details.dart';
import '../../domain/post_details/post_details_repository.dart';

class FakePostDetailsRepository implements PostDetailsRepository {
  final Map<String, List<PostComment>> _commentsByPost = {};

  @override
  Future<PostDetails> fetchPostById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    // Если у поста еще нет комментариев — создадим стартовые
    _commentsByPost.putIfAbsent(id, () {
      final now = DateTime.now();
      return [
        PostComment(
          id: 'c1',
          postId: id,
          author: 'Админ',
          text: 'Спасибо за участие 🙏',
          createdAt: now.subtract(const Duration(minutes: 12)),
          isMine: false,
        ),
        PostComment(
          id: 'c2',
          postId: id,
          author: 'Екатерина',
          text: 'Аминь.',
          createdAt: now.subtract(const Duration(minutes: 7)),
          isMine: false,
        ),
      ];
    });

    return PostDetails(
      id: id,
      author: 'Молитва мира',
      timeLabel: 'Сегодня 12:40',
      text:
      'Это экран отдельного поста.\n\n'
          'Пост id: $id\n\n'
          'Позже заменим на API и будем грузить реальные данные.',
      hasImage: true,
      likes: 12,
      comments: _commentsByPost[id]!.length,
    );
  }

  @override
  Future<List<PostComment>> fetchComments(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return List<PostComment>.from(_commentsByPost[postId] ?? const []);
  }

  @override
  Future<void> addComment({required String postId, required String text}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final list = _commentsByPost.putIfAbsent(postId, () => []);
    list.add(
      PostComment(
        id: 'c${list.length + 1}',
        postId: postId,
        author: 'Вы',
        text: text,
        createdAt: DateTime.now(),
        isMine: true,
      ),
    );
  }
}
