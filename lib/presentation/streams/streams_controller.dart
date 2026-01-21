import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/auth_local_store.dart';
import '../../data/streams/api_streams_repository.dart';
import '../../domain/streams/streams_item.dart';
import '../../domain/streams/stream_status.dart';
import '../../domain/streams/streams_repository.dart';
import '../../providers.dart'; // тут должны быть dioProvider и authLocalStoreProvider

// 🔧 если у тебя authLocalStoreProvider называется иначе — подставь своё имя
final streamsRepositoryProvider = Provider<StreamsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final local = ref.watch(authLocalStoreProvider);
  return ApiStreamsRepository(dio: dio, local: local);
});

final streamsStatusProvider = StateProvider.family<StreamStatus, bool>((ref, my) {
  return StreamStatus.active;
});

class StreamsState {
  final List<StreamItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int from;
  final int limit;
  final int total;
  final String? error;

  const StreamsState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.from,
    required this.limit,
    required this.total,
    required this.error,
  });

  factory StreamsState.initial() => const StreamsState(
    items: [],
    isLoading: true,
    isLoadingMore: false,
    hasMore: true,
    from: 1,
    limit: 20,
    total: 0,
    error: null,
  );

  StreamsState copyWith({
    List<StreamItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? from,
    int? limit,
    int? total,
    String? error,
    bool clearError = false,
  }) {
    return StreamsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      from: from ?? this.from,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

typedef StreamsKey = ({bool my, StreamStatus status});

final streamsControllerProvider =
StateNotifierProvider.family<StreamsController, StreamsState, StreamsKey>((ref, key) {
  return StreamsController(ref, my: key.my, status: key.status);
});

class StreamsController extends StateNotifier<StreamsState> {
  StreamsController(this.ref, {required this.my, required this.status})
      : super(StreamsState.initial()) {
    loadInitial();
  }

  final Ref ref;
  final bool my;
  final StreamStatus status;

  StreamsRepository get _repo => ref.read(streamsRepositoryProvider);

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true, items: [], from: 1, hasMore: true);
    try {
      final page = await _repo.fetchStreams(
        status: status,
        from: 1,
        limit: state.limit,
        my: my,
      );

      final nextFrom = 1 + page.items.length; // offset-логика
      final hasMore = page.items.length < page.total;

      state = state.copyWith(
        isLoading: false,
        items: page.items,
        total: page.total,
        from: nextFrom,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await _repo.fetchStreams(
        status: status,
        from: state.from,
        limit: state.limit,
        my: my,
      );

      final merged = [...state.items, ...page.items];
      final nextFrom = state.from + page.items.length;
      final hasMore = merged.length < page.total;

      state = state.copyWith(
        isLoadingMore: false,
        items: merged,
        total: page.total,
        from: nextFrom,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadInitial();
}
