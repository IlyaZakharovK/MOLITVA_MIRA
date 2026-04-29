import 'package:vsem_mirom/domain/funcs/parseFuncs.dart';

class PrayItem {
  final int id;
  final String name;
  final String text;

  const PrayItem({required this.id, required this.name, required this.text});

  factory PrayItem.fromAPI(Map<String, dynamic> json) {
    final int id = toInt(json['id']);
    final String name = toStr(json['name']);
    final String text = toStr(json['text']);
    return PrayItem(id: id, name: name, text: text);
  }
}

class ListPrayItem {
  final List<PrayItem> prays;

  const ListPrayItem({required this.prays});

  factory ListPrayItem.fromAPI(List<dynamic> listPrays){
    final parsed =
        listPrays.whereType<Map>().map((e){
          final map = stringKeyedMap(e);
          return PrayItem.fromAPI(map);
        }).toList();
    return ListPrayItem(prays: parsed);
  }
}
