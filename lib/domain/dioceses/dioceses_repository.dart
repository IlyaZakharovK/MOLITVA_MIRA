import 'diocese.dart';

abstract class DiocesesRepository {
  Future<List<Diocese>> getDioceses();
}
