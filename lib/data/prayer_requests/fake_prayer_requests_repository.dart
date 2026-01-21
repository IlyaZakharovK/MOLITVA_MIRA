import '../../domain/prayer_requests/prayer_request_item.dart';
import '../../domain/prayer_requests/prayer_requests_repository.dart';
import '../../domain/prayer_requests/request_status.dart';

class FakePrayerRequestsRepository implements PrayerRequestsRepository {
  final List<PrayerRequestItem> _items = [
    const PrayerRequestItem(
      id: 'r1',
      isUrgent: true,
      dateTime: null,
      fromName: 'Дмитриев Олег Иванович',
      categoryOrPrayer: 'Утренгорящий/Богородице Дево',
      text:
      'Какое-то описаниеКакое-то описаниеКакое-то описаниеКакое-то описаниеКакое-то описание...',
      status: RequestStatus.pending,
    ),
    PrayerRequestItem(
      id: 'r2',
      isUrgent: false,
      dateTime: DateTime(2025, 12, 17, 11, 05),
      fromName: 'Дмитриев Олег Иванович',
      categoryOrPrayer: '«Богородице Дево»',
      text:
      'Какое-то описаниеКакое-то описаниеКакое-то описаниеКакое-то описаниеКакое-то описание...',
      status: RequestStatus.rejected,
    ),
    PrayerRequestItem(
      id: 'r3',
      isUrgent: false,
      dateTime: DateTime(2025, 12, 17, 11, 05),
      fromName: 'Дмитриев Олег Иванович',
      categoryOrPrayer: '«Богородице Дево»',
      text:
      'Какое-то описаниеКакое-то описаниеКакое-то описаниеКакое-то описаниеКакое-то описание...',
      status: RequestStatus.pending,
    ),
  ];

  @override
  Future<List<PrayerRequestItem>> fetchRequests() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    return List<PrayerRequestItem>.from(_items);
  }

  @override
  Future<void> setStatus({required String id, required RequestStatus status}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(status: status);
  }
}
