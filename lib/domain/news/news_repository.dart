import 'news_item.dart';

abstract class NewsRepository {
  Future<List<NewsPost>> fetchPosts({
    required final int page,
    required final int limit,
  });
}
