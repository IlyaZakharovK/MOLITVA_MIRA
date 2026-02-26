import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/communities/community_item.dart';
import '../../domain/communities/communities_repository.dart';
import '../../providers.dart';

final communitiesControllerProvider =
AsyncNotifierProvider.family<
    CommunitiesController,
    CommunitiesState,
    bool
>(CommunitiesController.new);

class CommunitiesController extends FamilyAsyncNotifier<CommunitiesState, bool> {
  static const int _defaultLimit = 10;

  late final CommunitiesRepository _repo;
  late final bool _my;

  @override
  Future<CommunitiesState> build(bool my) async {
    _repo = ref.watch(communitiesRepositoryProvider);
    _my = my;

    final items = await _repo.fetchCommunities(page: 1, limit: _defaultLimit, my: _my);
    return CommunitiesState(
      items: items,
      page: 1,
      limit: _defaultLimit,
      hasMore: items.length >= _defaultLimit,
      isLoadingMore: false,
      pendingSubActions: const {},
    );
  }

  Future<void> refresh() async {
    final prev = state.valueOrNull;
    final limit = prev?.limit ?? _defaultLimit;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchCommunities(page: 1, limit: limit, my: _my);
      return (prev ?? const CommunitiesState()).copyWith(
        items: items,
        page: 1,
        limit: limit,
        hasMore: items.length >= limit,
        isLoadingMore: false,
        pendingSubActions: const {},
      );
    });
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    if (!cur.hasMore || cur.isLoadingMore) return;

    state = AsyncValue.data(cur.copyWith(isLoadingMore: true));

    try {
      final nextPage = cur.page + 1;
      final next =
      await _repo.fetchCommunities(page: nextPage, limit: cur.limit, my: _my);
      final merged = [...cur.items, ...next];

      state = AsyncValue.data(
        cur.copyWith(
          items: merged,
          page: nextPage,
          hasMore: next.length >= cur.limit,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(cur.copyWith(isLoadingMore: false));
      rethrow;
    }
  }

  /// Реальный поиск через репозиторий (каждые 3 символа — на экране).
  Future<List<CommunityItem>> searchCommunities(String request) {
    return _repo.searchCommunities(request: request);
  }

  /// Создать группу.
  /// type: 1 - открытое, 2 - закрытое
  Future<bool> createGroup({
    required int type,
    required String name,
    required String description,
  }) async {
    final ok = await _repo.createGroup(
      type: type,
      name: name,
      description: description,
    );
    if (ok) {
      await refresh();
    }
    return ok;
  }

  /// Подписка/отписка.
  /// action: 1 - подписаться, 2 - отписаться
  Future<bool> subUnSub({
    required int action,
    required int groupId,
  }) async {
    final cur = state.valueOrNull;
    if (cur == null) return false;

    if (cur.pendingSubActions.contains(groupId)) return false;

    final idx = cur.items.indexWhere((e) => e.id == groupId);
    if (idx < 0) return false;

    final original = cur.items[idx];

    final optimistic = _applySubOptimistic(original, action);
    final nextItems = [...cur.items]..[idx] = optimistic;

    final nextPending = {...cur.pendingSubActions, groupId};
    state = AsyncValue.data(
      cur.copyWith(items: nextItems, pendingSubActions: nextPending),
    );

    try {
      final ok = await _repo.subUnSub(action: action, groupId: groupId);
      final after = state.valueOrNull;
      if (after == null) return ok;

      final pendingRemoved = {...after.pendingSubActions}..remove(groupId);

      if (!ok) {
        // откат
        final rollbackItems = [...after.items];
        final ridx = rollbackItems.indexWhere((e) => e.id == groupId);
        if (ridx >= 0) rollbackItems[ridx] = original;

        state = AsyncValue.data(
          after.copyWith(items: rollbackItems, pendingSubActions: pendingRemoved),
        );
        return false;
      }

      state = AsyncValue.data(
        after.copyWith(pendingSubActions: pendingRemoved),
      );
      return true;
    } catch (_) {
      final after = state.valueOrNull;
      if (after != null) {
        final pendingRemoved = {...after.pendingSubActions}..remove(groupId);
        // откат
        final rollbackItems = [...after.items];
        final ridx = rollbackItems.indexWhere((e) => e.id == groupId);
        if (ridx >= 0) rollbackItems[ridx] = original;

        state = AsyncValue.data(
          after.copyWith(items: rollbackItems, pendingSubActions: pendingRemoved),
        );
      }
      rethrow;
    }
  }

  CommunityItem _applySubOptimistic(CommunityItem item, int action) {
    final isSub = item.subed;
    final subs = item.subscribers;

    final nextSubed = action == 1 ? true : false;
    final nextSubs = mathMax0(subs + (nextSubed && !isSub ? 1 : 0) - (!nextSubed && isSub ? 1 : 0));

    return CommunityItem(
      id: item.id,
      type: item.type,
      invite: item.invite,
      ownerId: item.ownerId,
      name: item.name,
      description: item.description,
      dateAdd: item.dateAdd,
      subscribers: nextSubs,
      image: item.image,
      subed: nextSubed,
      owner: item.owner,
    );
  }

  int mathMax0(int v) => v < 0 ? 0 : v;
}

class CommunitiesState {
  final List<CommunityItem> items;
  final int page;
  final int limit;
  final bool hasMore;
  final bool isLoadingMore;

  /// Чтобы не спамили запросами по одному и тому же groupId
  final Set<int> pendingSubActions;

  const CommunitiesState({
    this.items = const [],
    this.page = 1,
    this.limit = CommunitiesController._defaultLimit,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.pendingSubActions = const {},
  });

  CommunitiesState copyWith({
    List<CommunityItem>? items,
    int? page,
    int? limit,
    bool? hasMore,
    bool? isLoadingMore,
    Set<int>? pendingSubActions,
  }) {
    return CommunitiesState(
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      pendingSubActions: pendingSubActions ?? this.pendingSubActions,
    );
  }
}