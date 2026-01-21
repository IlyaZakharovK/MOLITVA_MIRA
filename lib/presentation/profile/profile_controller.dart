import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile/api_profile_repository.dart';
import '../../domain/profile/profile_model.dart';
import '../../domain/profile/profile_repository.dart';

import '../../providers.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ApiProfileRepository(
    dio: ref.watch(dioProvider),
    local: ref.watch(authLocalStoreProvider),
  );
});

final profileControllerProvider =
StateNotifierProvider<ProfileController, AsyncValue<ProfileModel>>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileController(repo)..load();
});

class ProfileController extends StateNotifier<AsyncValue<ProfileModel>> {
  ProfileController(this._repo) : super(const AsyncLoading());

  final ProfileRepository _repo;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      final p = await _repo.load();
      state = AsyncData(p);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> save(ProfileModel updated) async {
    state = AsyncData(updated); // оптимистично
    await _repo.save(updated);
  }
}
