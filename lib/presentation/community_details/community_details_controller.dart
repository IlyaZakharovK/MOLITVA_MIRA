import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/auth_local_store.dart';
import '../../data/upload/upload_repository.dart';
import '../../domain/community_details/community_details.dart';
import '../../domain/community_details/community_details_repository.dart';
import '../../providers.dart';

typedef CommunityDetailsArgs = ({int groupId, bool invited, String invite});

class CommunityDetailsState {
  final Group group;
  final List<Post> posts;

  final int page;
  final int limit;
  final bool hasMore;
  final bool isLoadingMore;

  final int? currentUserId;

  final bool isSubBusy;

  const CommunityDetailsState({
    required this.group,
    required this.posts,
    required this.page,
    required this.limit,
    required this.hasMore,
    required this.isLoadingMore,
    required this.currentUserId,
    required this.isSubBusy,
  });

  CommunityDetailsState copyWith({
    Group? group,
    List<Post>? posts,
    int? page,
    int? limit,
    bool? hasMore,
    bool? isLoadingMore,
    int? currentUserId,
    bool? isSubBusy,
  }) {
    return CommunityDetailsState(
      group: group ?? this.group,
      posts: posts ?? this.posts,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentUserId: currentUserId ?? this.currentUserId,
      isSubBusy: isSubBusy ?? this.isSubBusy,
    );
  }
}

final communityDetailsControllerProvider =
    AsyncNotifierProvider.family<
      CommunityDetailsController,
      CommunityDetailsState,
      CommunityDetailsArgs
    >(CommunityDetailsController.new);

class CommunityDetailsController
    extends FamilyAsyncNotifier<CommunityDetailsState, CommunityDetailsArgs> {
  static const int _defaultLimit = 10;

  CommunityDetailsRepository get _repo =>
      ref.read(communityDetailsRepositoryProvider);

  AuthLocalStore get _local => ref.read(authLocalStoreProvider);

  UploadRepository get _upload => ref.read(uploadRepositoryProvider);

  late final int _groupId;
  late final bool _invited;
  late final String _invite;

  int? _parseUserId(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  @override
  Future<CommunityDetailsState> build(CommunityDetailsArgs args) async {
    _invited = args.invited;
    _invite = args.invite;

    final raw = await _local.getToken();
    final userId = _parseUserId(raw);

    final community = _invited
        ? await _repo.fetchCommunityByInvite(invite: _invite)
        : await _repo.fetchCommunity(id: args.groupId);
    final posts = community.posts;

    final limit = _defaultLimit;
    _groupId = community.group.id;

    return CommunityDetailsState(
      group: community.group,
      posts: posts,
      page: 1,
      limit: limit,
      hasMore: posts.length >= limit,
      isLoadingMore: false,
      currentUserId: userId,
      isSubBusy: false,
    );
  }

  Future<void> refresh() async {
    final cur = state.valueOrNull;
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final raw = await _local.getToken();
      final userId = _parseUserId(raw);

      final community = await _repo.fetchCommunity(id: _groupId);
      final posts = community.posts;

      final limit = cur?.limit ?? _defaultLimit;

      return CommunityDetailsState(
        group: community.group,
        posts: posts,
        page: 1,
        limit: limit,
        hasMore: posts.length >= limit,
        isLoadingMore: false,
        currentUserId: userId,
        isSubBusy: false,
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
      final next = await _repo.fetchMorePosts(
        id: _groupId,
        limit: cur.limit,
        page: nextPage,
      );

      final merged = [...cur.posts, ...next];
      final hasMore = next.length >= cur.limit;

      state = AsyncValue.data(
        cur.copyWith(
          posts: merged,
          page: nextPage,
          hasMore: hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      final again = state.valueOrNull;
      if (again != null) {
        state = AsyncValue.data(again.copyWith(isLoadingMore: false));
      }
      rethrow;
    }
  }

  /// ✅ Реальная подписка/отписка через репозиторий + optimistic UI.
  Future<void> toggleSubscribe() async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    if (cur.isSubBusy) return;

    final g = cur.group;
    final wasSubscribed = g.isSubscribed;
    final action = wasSubscribed ? 2 : 1;

    final optimisticFollowers = g.followersCount + (wasSubscribed ? -1 : 1);
    final nextGroup = Group(
      id: g.id,
      name: g.name,
      description: g.description,
      ownerId: g.ownerId,
      dateAdd: g.dateAdd,
      dateUpdate: g.dateUpdate,
      ownerName: g.ownerName,
      logoUrl: g.logoUrl,
      ownerAvatarUrl: g.ownerAvatarUrl,
      followersCount: optimisticFollowers < 0 ? 0 : optimisticFollowers,
      isSubscribed: !wasSubscribed,
      isOwner: g.isOwner,
      invite: g.invite,
      isClose: g.isClose,
      allowComments: g.allowComments,
    );

    // optimistic
    state = AsyncValue.data(cur.copyWith(group: nextGroup, isSubBusy: true));

    try {
      final ok = await _repo.subUnSub(action: action, groupId: g.id);
      final after = state.valueOrNull;
      if (after == null) return;

      if (!ok) {
        // rollback
        state = AsyncValue.data(after.copyWith(group: g, isSubBusy: false));
        return;
      }

      state = AsyncValue.data(after.copyWith(isSubBusy: false));
    } catch (_) {
      final after = state.valueOrNull;
      if (after != null) {
        state = AsyncValue.data(after.copyWith(group: g, isSubBusy: false));
      }
      rethrow;
    }
  }

  Future<void> setCommentsStatus() async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    await _repo.allUnAll(groupId: cur.group.id);
    refresh();
  }

  Future<void> deleteComment( {
    required int postId,
    required int commentId
}) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    await _repo.deleteComment(groupId: cur.group.id, commentId: commentId, postId: postId);
    refresh();
  }

  Future<void> createPost({
    required String title,
    required String message,
  }) async {
    final cur = state.valueOrNull;
    if (cur == null) return;

    final t = title.trim();
    final m = message.trim();
    if (t.isEmpty || m.isEmpty) {
      throw Exception('Заполните заголовок и текст');
    }

    await _repo.createPost(
      groupId: cur.group.id,
      ownerId: cur.group.ownerId,
      title: t,
      message: m,
    );

    await refresh();
  }

  Future<void> createComment({
    required int postId,
    required String message,
  }) async {
    final cur = state.valueOrNull;
    if (cur == null) return;

    final m = message.trim();
    if (m.isEmpty) {
      throw Exception('Введите текст комментария');
    }

    await _repo.createComment(
      groupId: cur.group.id,
      postId: postId,
      message: m,
    );
    await refresh();
  }

  /// ✅ Загрузка/смена иконки сообщества (logo)
  /// Важно: type зависит от бэкенда. По аналогии с аватаром пользователя (type=1)
  /// для сообщества чаще всего используется type=2.
  Future<Map<String, dynamic>> uploadCommunityLogo(Uint8List bytes) async {
    final cur = state.valueOrNull;
    if (cur == null) throw Exception('Сообщество ещё не загружено');

    if (!cur.group.isOwner) {
      throw Exception('Недостаточно прав для изменения иконки');
    }

    final groupId = cur.group.id;
    if (groupId == 0) {
      throw Exception('Не удалось определить groupId');
    }

    final res = await _upload.uploadImageBase64(
      type: 2,
      imgId: groupId,
      bytes: bytes,
    );

    await refresh();
    return res;
  }
}
