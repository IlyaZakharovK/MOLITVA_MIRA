import 'request_moderation_item.dart';

abstract class RequestModerationRepository {
  Future<List<RequestModerationItem>> fetch({
    required int statusId,
    required int page,
    required int limit,
  });

  Future<void> bless(int requestId);
  Future<void> reject({required int requestId, String comment});
}
