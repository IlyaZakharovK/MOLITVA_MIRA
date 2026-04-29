import 'package:vsem_mirom/domain/funcs/parseFuncs.dart';

class PrayPrams {
  final int categoryId;
  final String categoryName;
  final int prayId;
  final String prayName;
  final String prayText;

  const PrayPrams({
    required this.categoryId,
    required this.categoryName,
    required this.prayId,
    required this.prayName,
    required this.prayText,
  });

  factory PrayPrams.fromArgs(Map<dynamic, dynamic> args){
    return PrayPrams(
      categoryId: toInt(args['categoryId']),
      categoryName: toStr(args['categoryName']),
      prayId: toInt(args['prayId']),
      prayName: toStr(args['prayName']),
      prayText: toStr(args['prayText']),
    );
  }
}
