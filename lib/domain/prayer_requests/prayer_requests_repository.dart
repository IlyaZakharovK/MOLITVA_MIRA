import 'prayer_request_item.dart';
import 'request_status.dart';

abstract class PrayerRequestsRepository {
  Future<List<PrayerRequestItem>> fetchRequests();

  Future<void> setStatus({
    required String id,
    required RequestStatus status,
  });
}

