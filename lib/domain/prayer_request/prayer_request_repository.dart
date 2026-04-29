import 'prayer_category.dart';
import 'prayer_text.dart';

abstract class PrayerRequestRepository {
  Future<List<PrayerCategory>> getCategories();
  Future<List<PrayerText>> getPrayersByCategory(int categoryId);

  Future<void> createTranslation({
    required String name,
    required String description,
    required int type,
    required DateTime datePlanned,

    int? prayersCategoryId,
    int? prayersTextId,

    required bool prayerOptional,
    required String prayerOptionalText,
  });
}
