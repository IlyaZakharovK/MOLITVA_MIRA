import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/prayer_requests/fake_prayer_requests_repository.dart';
import '../../domain/prayer_requests/prayer_request_item.dart';
import '../../domain/prayer_requests/prayer_requests_repository.dart';
import '../../domain/prayer_requests/request_status.dart';
import '../../providers.dart';

final prayerRequestsControllerProvider =
AsyncNotifierProvider<PrayerRequestsController, List<PrayerRequestItem>>(
  PrayerRequestsController.new,
);

class PrayerRequestsController extends AsyncNotifier<List<PrayerRequestItem>> {
  late final PrayerRequestsRepository _repo;

  @override
  Future<List<PrayerRequestItem>> build() async {
    _repo = ref.watch(prayerRequestsRepositoryProvider);
    return _repo.fetchRequests();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.fetchRequests());
  }

  Future<void> approve(String id) async {
    await _repo.setStatus(id: id, status: RequestStatus.approved);
    await refresh();
  }

  Future<void> reject(String id) async {
    await _repo.setStatus(id: id, status: RequestStatus.rejected);
    await refresh();
  }
}
