import 'news_item.dart';

abstract class NewsRepository {
  Future<List<NewsPost>> fetchPosts();
}
