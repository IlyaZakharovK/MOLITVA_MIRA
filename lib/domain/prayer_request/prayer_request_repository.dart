import 'prayer_category.dart';
import 'prayer_text.dart';

abstract class PrayerRequestRepository {
  Future<List<PrayerCategory>> getCategories(); // getDioceses (пока используем его как категории)
  Future<List<PrayerText>> getPrayersByCategory(int categoryId); // appGetPrayersByCategory

  Future<void> createTranslation({
    required String name,
    required String description,
    required int type, // 1 open, 2 closed
    required DateTime datePlanned,

    int? prayersCategoryId,
    int? prayersTextId,

    required bool prayerOptional, // своя молитва
    required String prayerOptionalText,
  });
}
