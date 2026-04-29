import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/request_moderation/api_request_moderation_repository.dart';
import '../../domain/request_moderation/request_moderation_item.dart';
import '../../domain/request_moderation/request_moderation_repository.dart';
import '../../providers.dart';

const int kRequestPageSize = 10;

// 1 — новые, 2 — благословленные, 3 — отклоненные
final requestModerationStatusProvider = StateProvider<int>((ref) => 1);

final requestModerationRepositoryProvider = Provider<RequestModerationRepository>((ref) {
  // ⚠️ подстрой под свой источник пароля, если он у тебя уже где-то есть.
  const apiPass = 'f92R*#eiDF82W@#k2WO';

  return ApiRequestModerationRepository(
    dio: ref.watch(dioProvider),
    apiPass: apiPass,
  );
});

final requestModerationControllerProvider = StateNotifierProvider.family<
    RequestModerationController,
    RequestModerationState,
    int>((ref, statusId) {
  final repo = ref.watch(requestModerationRepositoryProvider);
  return RequestModerationController(repo, statusId);
});

class RequestModerationState {
  final List<RequestModerationItem> items;

  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;

  final int page;
  final String? error;

  const RequestModerationState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.page,
    required this.error,
  });

  factory RequestModerationState.initial() => const RequestModerationState(
    items: [],
    isLoading: true,
    isLoadingMore: false,
    hasMore: false,
    page: 1,
    error: null,
  );

  RequestModerationState copyWith({
    List<RequestModerationItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
    bool clearError = false,
  }) {
    return RequestModerationState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RequestModerationController extends StateNotifier<RequestModerationState> {
  final RequestModerationRepository _repo;
  final int statusId;

  RequestModerationController(this._repo, this.statusId)
      : super(RequestModerationState.initial()) {
    // как в StreamsController: не дергаем state синхронно при создании провайдера во время build
    Future.microtask(refresh);
  }

  /// сортировка:
  /// 1) type==4 (SOS) по id desc
  /// 2) остальные по id desc
  List<RequestModerationItem> _sort(List<RequestModerationItem> src) {
    final sos = <RequestModerationItem>[];
    final other = <RequestModerationItem>[];

    for (final e in src) {
      if (e.typeId == 4) {
        sos.add(e);
      } else {
        other.add(e);
      }
    }

    sos.sort((a, b) => b.id.compareTo(a.id));
    other.sort((a, b) => b.id.compareTo(a.id));

    return [...sos, ...other];
  }

  Future<void> refresh() async {
    if (!mounted) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      items: [],
      page: 1,
      hasMore: true,
    );

    try {
      final items = await _repo.fetch(
        statusId: statusId,
        page: 1,
        limit: kRequestPageSize,
      );

      final sorted = _sort(items);

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        items: sorted,
        page: 1,
        hasMore: items.length >= kRequestPageSize,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (!mounted) return;
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final items = await _repo.fetch(
        statusId: statusId,
        page: nextPage,
        limit: kRequestPageSize,
      );

      final merged = _sort([...state.items, ...items]);

      if (!mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        items: merged,
        page: nextPage,
        hasMore: items.length >= kRequestPageSize,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> bless(RequestModerationItem item) async {
    await _repo.bless(item.id);
    await refresh();
  }

  Future<void> reject(RequestModerationItem item, String comment) async {
    await _repo.reject(requestId: item.id, comment: comment);
    await refresh();
  }
}
