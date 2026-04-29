import 'package:vsem_mirom/domain/prays/pray_category_item.dart';
import 'package:vsem_mirom/domain/prays/pray_list_item.dart';

abstract class PrayRepository {
  Future<ListPrayCategories> fetchPrayCategories();
  Future<ListPrayItem> fetchPraysInCategory({
    required int categoryId
  });
}