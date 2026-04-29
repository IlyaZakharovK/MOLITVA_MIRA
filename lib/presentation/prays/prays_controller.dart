import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/prays/pray_category_item.dart';
import '../../domain/prays/pray_list_item.dart';
import '../../domain/prays/prays_repository.dart';
import '../../providers.dart';

/// Экран "Молитвы".
///
/// ВАЖНО: в проекте должен быть Provider для репозитория молитв.
/// Ожидаемое имя: [prayRepositoryProvider].
/// Если у тебя он называется иначе — просто замени в одном месте ниже.
final praysControllerProvider =
    AsyncNotifierProvider<PraysController, PraysState>(PraysController.new);

class PraysState {
  final List<PrayCategoryItem> categories;

  /// categoryId -> список молитв
  final Map<int, List<PrayItem>> praysByCategory;

  /// категории, которые сейчас грузятся (ленивая подгрузка)
  final Set<int> loadingCategoryIds;

  /// последняя нефатальная ошибка (не ломает экран)
  final String? error;

  const PraysState({
    required this.categories,
    required this.praysByCategory,
    required this.loadingCategoryIds,
    required this.error,
  });

  PraysState copyWith({
    List<PrayCategoryItem>? categories,
    Map<int, List<PrayItem>>? praysByCategory,
    Set<int>? loadingCategoryIds,
    String? error,
    bool clearError = false,
  }) {
    return PraysState(
      categories: categories ?? this.categories,
      praysByCategory: praysByCategory ?? this.praysByCategory,
      loadingCategoryIds: loadingCategoryIds ?? this.loadingCategoryIds,
      error: clearError ? null : (error ?? this.error),
    );
  }

  factory PraysState.initial(List<PrayCategoryItem> categories) => PraysState(
        categories: categories,
        praysByCategory: const {},
        loadingCategoryIds: const {},
        error: null,
      );
}

class PraysController extends AsyncNotifier<PraysState> {
  PrayRepository get _repo => ref.read(prayRepositoryProvider);

  @override
  Future<PraysState> build() async {
    final cats = await _repo.fetchPrayCategories();
    return PraysState.initial(cats.categories);
  }

  /// Полная перезагрузка списка категорий.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final cats = await _repo.fetchPrayCategories();
      return PraysState.initial(cats.categories);
    });
  }

  /// Ленивая загрузка молитв внутри конкретной категории.
  Future<void> loadCategory(int categoryId, {bool force = false}) async {
    final cur = state.valueOrNull;
    if (cur == null) return;

    if (!force && cur.praysByCategory.containsKey(categoryId)) return;
    if (cur.loadingCategoryIds.contains(categoryId)) return;

    final nextLoading = {...cur.loadingCategoryIds, categoryId};
    state = AsyncValue.data(cur.copyWith(loadingCategoryIds: nextLoading, clearError: true));

    try {
      final list = await _repo.fetchPraysInCategory(categoryId: categoryId);

      final after = state.valueOrNull ?? cur;
      final nextMap = {...after.praysByCategory, categoryId: list.prays};
      final doneLoading = {...(state.valueOrNull?.loadingCategoryIds ?? nextLoading)}
        ..remove(categoryId);

      state = AsyncValue.data(
        after.copyWith(
          praysByCategory: nextMap,
          loadingCategoryIds: doneLoading,
        ),
      );
    } catch (e) {
      final after = state.valueOrNull ?? cur;
      final doneLoading = {...after.loadingCategoryIds}..remove(categoryId);
      state = AsyncValue.data(
        after.copyWith(
          loadingCategoryIds: doneLoading,
          error: e.toString(),
        ),
      );
    }
  }
}
