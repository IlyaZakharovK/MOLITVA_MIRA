import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/news/fake_news_repository.dart';
import '../../domain/news/news_item.dart';
import '../../domain/news/news_repository.dart';

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return FakeNewsRepository();
});

final newsControllerProvider =
AsyncNotifierProvider<NewsController, List<NewsPost>>(NewsController.new);

class NewsController extends AsyncNotifier<List<NewsPost>> {
  late final NewsRepository _repo;

  @override
  Future<List<NewsPost>> build() async {
    _repo = ref.watch(newsRepositoryProvider);
    return _repo.fetchPosts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.fetchPosts());
  }
}
