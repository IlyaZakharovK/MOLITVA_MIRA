import 'package:vsem_mirom/domain/funcs/parseFuncs.dart';

class PrayCategoryItem {
  final int id;
  final String name;

  const PrayCategoryItem({required this.id, required this.name});

  factory PrayCategoryItem.fromAPI(Map<String, dynamic> json) {
    final int id = toInt(json['id']);
    final String name = toStr(json['name']);
    return PrayCategoryItem(id: id, name: name);
  }
}

class ListPrayCategories {
  final List<PrayCategoryItem> categories;

  const ListPrayCategories({required this.categories});

  factory ListPrayCategories.fromAPI(List<dynamic> listCategories){
    final parsed =
        listCategories.whereType<Map>().map((e){
          final map = stringKeyedMap(e);
          return PrayCategoryItem.fromAPI(map);
        }).toList();
    return ListPrayCategories(categories: parsed);
  }
}
