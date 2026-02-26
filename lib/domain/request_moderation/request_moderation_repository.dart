import 'request_moderation_item.dart';

abstract class RequestModerationRepository {
  Future<List<RequestModerationItem>> fetch({
    required int statusId,
    required int page,
    required int limit,
  });

  // ⚠️ endpoints для благословить/отклонить в описании не дали.
  // Я оставил интерфейс — подключишь, когда уточнишь method.
  Future<void> bless(int requestId);
  Future<void> reject(int requestId);
}
