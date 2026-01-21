import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/prayer_request/prayer_category.dart';
import '../../domain/prayer_request/prayer_text.dart';
import '../../domain/prayer_request/prayer_request_repository.dart';
import '../../domain/prayer_request/prayer_request_mode.dart';
import '../../providers.dart';

class _Keep {
  const _Keep();
}

const _keep = _Keep();

final prayerRequestModeProvider = StateProvider<PrayerRequestMode>((ref) {
  return PrayerRequestMode.normal;
});

final prayerRequestControllerProvider =
StateNotifierProvider<PrayerRequestController, PrayerRequestState>(
      (ref) => PrayerRequestController(ref),
);

class PrayerRequestState {
  final bool isSubmitting;

  final bool categoriesLoading;
  final List<PrayerCategory> categories;

  final bool prayersLoading;
  final List<PrayerText> prayers;

  final int? categoryId;
  final int? prayerId;
  final String prayerText;

  final bool selfPray;

  final String? errorMessage;

  const PrayerRequestState({
    required this.isSubmitting,
    required this.categoriesLoading,
    required this.categories,
    required this.prayersLoading,
    required this.prayers,
    required this.categoryId,
    required this.prayerId,
    required this.prayerText,
    required this.selfPray,
    required this.errorMessage,
  });

  factory PrayerRequestState.initial() => const PrayerRequestState(
    isSubmitting: false,
    categoriesLoading: false,
    categories: [],
    prayersLoading: false,
    prayers: [],
    categoryId: null,
    prayerId: null,
    prayerText: '',
    selfPray: false,
    errorMessage: null,
  );

  PrayerRequestState copyWith({
    bool? isSubmitting,
    bool? categoriesLoading,
    List<PrayerCategory>? categories,
    bool? prayersLoading,
    List<PrayerText>? prayers,

    Object? categoryId = _keep,
    Object? prayerId = _keep,

    String? prayerText,
    bool? selfPray,
    String? errorMessage,
    bool clearError = false,
  }) {
    final nextCategoryId =
    categoryId == _keep ? this.categoryId : categoryId as int?;
    final nextPrayerId =
    prayerId == _keep ? this.prayerId : prayerId as int?;

    return PrayerRequestState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      categoriesLoading: categoriesLoading ?? this.categoriesLoading,
      categories: categories ?? this.categories,
      prayersLoading: prayersLoading ?? this.prayersLoading,
      prayers: prayers ?? this.prayers,
      categoryId: nextCategoryId,
      prayerId: nextPrayerId,
      prayerText: prayerText ?? this.prayerText,
      selfPray: selfPray ?? this.selfPray,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

}

class PrayerRequestController extends StateNotifier<PrayerRequestState> {
  PrayerRequestController(this.ref) : super(PrayerRequestState.initial()) {
    loadCategories();
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  final Ref ref;

  PrayerRequestRepository get _repo => ref.read(prayerRequestRepositoryProvider);

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> loadCategories() async {
    state = state.copyWith(categoriesLoading: true, clearError: true);
    try {
      final cats = await _repo.getCategories();
      state = state.copyWith(
        categoriesLoading: false,
        categories: cats,
      );
    } catch (e) {
      state = state.copyWith(
        categoriesLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> selectCategory(dynamic rawId) async {
    // если выбрана "своя молитва" — категории/молитвы должны быть None
    if (state.selfPray) return;

    final id = _asInt(rawId);

    state = state.copyWith(
      categoryId: id,
      prayerId: null,
      prayerText: '',
      prayers: const [],
      prayersLoading: false,
      clearError: true,
    );

    if (id == null) return;

    await _loadPrayers(id);
  }


  Future<void> _loadPrayers(int categoryId) async {
    state = state.copyWith(prayersLoading: true, clearError: true);
    try {
      final prayers = await _repo.getPrayersByCategory(categoryId);
      state = state.copyWith(
        prayersLoading: false,
        prayers: prayers,
      );
    } catch (e) {
      state = state.copyWith(
        prayersLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void selectPrayer(dynamic rawId) {
    if (state.selfPray) return;
    if (state.categoryId == null) return;

    final id = _asInt(rawId);

    PrayerText? selected;
    for (final p in state.prayers) {
      if (p.id == id) {
        selected = p;
        break;
      }
    }

    state = state.copyWith(
      prayerId: id,
      prayerText: selected?.text ?? '',
      clearError: true,
    );
  }


  void setSelfPray(bool value) {
    if (value) {
      state = state.copyWith(
        selfPray: true,
        categoryId: null,
        prayerId: null,
        prayers: const [],
        prayerText: '',
        clearError: true,
      );
    } else {
      state = state.copyWith(
        selfPray: false,
        categoryId: null,
        prayerId: null,
        prayers: const [],
        prayerText: '',
        clearError: true,
      );
    }
  }

  Future<void> submitTranslation({
    required String name,
    required String description,
    required int type, // 1 open / 2 closed
    required DateTime datePlanned,

    // если selfPray=true -> categoryId/prayerId должны быть null
    required bool selfPray,
    required String selfPrayText,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.createTranslation(
        name: name,
        description: description,
        type: type,
        datePlanned: datePlanned,
        prayersCategoryId: selfPray ? null : state.categoryId,
        prayersTextId: selfPray ? null : state.prayerId,
        prayerOptional: selfPray,
        prayerOptionalText: selfPray ? selfPrayText : '',
      );

      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      rethrow;
    }
  }
}
