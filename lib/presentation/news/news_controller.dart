import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/news/news_item.dart';
import '../../domain/news/news_repository.dart';
import '../../providers.dart';

final newsControllerProvider =
AsyncNotifierProvider<NewsController, NewsState>(NewsController.new);

class NewsState {
  final List<NewsPost> items;
  final int page;
  final int limit;
  final bool hasMore;
  final bool isLoadingMore;

  const NewsState({
    this.items = const [],
    this.page = 1,
    this.limit = 10,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  NewsState copyWith({
    List<NewsPost>? items,
    int? page,
    int? limit,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return NewsState(
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class NewsController extends AsyncNotifier<NewsState> {
  late final NewsRepository _repo;

  @override
  Future<NewsState> build() async {
    _repo = ref.watch(newsRepositoryProvider);

    const page = 1;
    const limit = 10;

    final items = await _repo.fetchPosts(page: page, limit: limit);
    return NewsState(
      items: items,
      page: page,
      limit: limit,
      hasMore: items.length >= limit,
      isLoadingMore: false,
    );
  }

  Future<void> refresh() async {
    final cur = state.valueOrNull;
    final limit = cur?.limit ?? 10;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchPosts(page: 1, limit: limit);
      return NewsState(
        items: items,
        page: 1,
        limit: limit,
        hasMore: items.length >= limit,
        isLoadingMore: false,
      );
    });
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    if (cur.isLoadingMore || !cur.hasMore) return;

    state = AsyncValue.data(cur.copyWith(isLoadingMore: true));

    try {
      final nextPage = cur.page + 1;
      final next = await _repo.fetchPosts(page: nextPage, limit: cur.limit);

      final merged = [...cur.items, ...next];
      final hasMore = next.length >= cur.limit;

      state = AsyncValue.data(
        cur.copyWith(
          items: merged,
          page: nextPage,
          hasMore: hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      // не роняем экран из-за ошибки догрузки
      final again = state.valueOrNull;
      if (again != null) {
        state = AsyncValue.data(again.copyWith(isLoadingMore: false));
      }
      rethrow;
    }
  }
}