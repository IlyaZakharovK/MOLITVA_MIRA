import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/auth_local_store.dart';
import '../../data/upload/upload_repository.dart';
import '../../data/streams/api_streams_repository.dart';
import '../../domain/streams/streams_item.dart';
import '../../domain/streams/stream_status.dart';
import '../../domain/streams/streams_repository.dart';
import '../../providers.dart';

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
    // ВАЖНО: нельзя синхронно менять state при создании провайдера во время build.
    // Делаем отложенный старт.
    Future.microtask(loadInitial);
  }

  final Ref ref;
  final bool my;
  final StreamStatus status;

  StreamsRepository get _repo => ref.read(streamsRepositoryProvider);
  AuthLocalStore get _local => ref.read(authLocalStoreProvider);

  UploadRepository get _upload => ref.read(uploadRepositoryProvider);

  Future<void> loadInitial() async {
    if (!mounted) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      items: [],
      from: 1,
      hasMore: true,
    );

    try {
      final page = await _repo.fetchStreams(
        status: status,
        from: 1,
        limit: state.limit,
        my: my,
      );

      final nextFrom = 1 + page.items.length; // offset-логика
      final hasMore = page.items.length < page.total;

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        items: page.items,
        total: page.total,
        from: nextFrom,
        hasMore: hasMore,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!mounted) return;
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

      if (!mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        items: merged,
        total: page.total,
        from: nextFrom,
        hasMore: hasMore,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadInitial();

  /// ==== API: LIKE ====
  /// дергаем appLikeTranslation и обновляем likes у нужного StreamItem
  Future<int?> likeTranslation(String streamId) async {
    final repo = _repo;
    if (repo is! ApiStreamsRepository) {
      throw Exception('StreamsRepository не поддерживает likeTranslation');
    }

    final userId = await _local.getToken();
    if (userId == null) throw Exception('Нет user_id: не авторизован');

    final translationId = int.tryParse(streamId);
    if (translationId == null) throw Exception('Некорректный translation_id: $streamId');

    final res = await repo.likeTranslation(
        translationId: translationId
    );

    // обновим локально count
    final idx = state.items.indexWhere((e) => e.id == streamId);
    if (idx != -1 && mounted) {
      final updated = [...state.items];
      final old = updated[idx];
      updated[idx] = StreamItem(
          id: old.id,
          title: old.title,
          description: old.description,
          participants: old.participants,
          startAt: old.startAt,
          endAt: old.endAt,
          status_id: old.status_id,
          type_id: old.type_id,
          image: old.image,
          likes: res.count,
          invite: old.invite
      );

      state = state.copyWith(items: updated);
    }

    return res.count;
  }


  /// ==== API: UPLOAD STREAM AVATAR ====
  /// appUploadImg: type=3 (аватар/картинка трансляции), imgId = translation_id
  /// После успешной загрузки обновляем локально `image` у нужного StreamItem,
  /// добавляя cache-bust query параметр `v=...`, чтобы картинка обновилась сразу.
  Future<Map<String, dynamic>> uploadStreamAvatar({
    required String streamId,
    required Uint8List bytes,
  }) async {
    final translationId = int.tryParse(streamId);
    if (translationId == null || translationId == 0) {
      throw Exception('Некорректный translation_id: $streamId');
    }

    final res = await _upload.uploadImageBase64(
      type: 3,
      imgId: translationId,
      bytes: bytes,
    );

    final bust = DateTime.now().millisecondsSinceEpoch;

    String? extractedUrl;
    try {
      // часто бэк кладёт ссылку в разные ключи
      dynamic v = res['img'] ?? res['url'] ?? res['link'] ?? res['path'];
      if (v is String && v.trim().isNotEmpty) extractedUrl = v.trim();

      if (extractedUrl == null && res['data'] is Map) {
        final data = res['data'] as Map;
        final vv = data['img'] ?? data['url'] ?? data['link'] ?? data['path'];
        if (vv is String && vv.trim().isNotEmpty) extractedUrl = vv.trim();
      }
    } catch (_) {}

    String withBust(String url) {
      final raw = url.trim();
      if (raw.isEmpty) return raw;

      final uri = Uri.tryParse(raw);
      if (uri == null) {
        final sep = raw.contains('?') ? '&' : '?';
        return '$raw${sep}v=$bust';
      }

      final qp = Map<String, String>.from(uri.queryParameters);
      qp['v'] = bust.toString();
      return uri.replace(queryParameters: qp).toString();
    }

    // локально обновляем элемент, чтобы UI перерисовался сразу
    final idx = state.items.indexWhere((e) => e.id == streamId);
    if (idx != -1 && mounted) {
      final updated = [...state.items];
      final old = updated[idx];

      final base = (extractedUrl ?? old.image).trim();
      final nextImage = base.isEmpty ? old.image : withBust(base);

      updated[idx] = StreamItem(
        id: old.id,
        title: old.title,
        description: old.description,
        participants: old.participants,
        startAt: old.startAt,
        endAt: old.endAt,
        status_id: old.status_id,
        type_id: old.type_id,
        image: nextImage,
        likes: old.likes,
        invite: old.invite,
      );

      state = state.copyWith(items: updated);
    }

    return res;
  }
}
