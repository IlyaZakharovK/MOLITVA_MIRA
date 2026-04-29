import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/auth_local_store.dart';
import '../../data/upload/upload_repository.dart';
import '../../domain/profile/profile_model.dart';
import '../../domain/profile/profile_repository.dart';
import '../../providers.dart';

final profileControllerProvider =
StateNotifierProvider<ProfileController, AsyncValue<ProfileModel>>((ref) {
  final repo = ref.watch(profileRepositoryProvider); // у тебя уже есть
  final local = ref.watch(authLocalStoreProvider);
  final upload = ref.watch(uploadRepositoryProvider);
  return ProfileController(repo, local, upload)..load();
});

class ProfileController extends StateNotifier<AsyncValue<ProfileModel>> {
  ProfileController(this._repo, this._local, this._upload)
      : super(const AsyncLoading());

  final ProfileRepository _repo;
  final AuthLocalStore _local;
  final UploadRepository _upload;

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      final p = await _repo.load();
      state = AsyncData(p);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Тихий refresh: без глобального AsyncLoading на весь экран.
  Future<void> refresh() async {
    final prev = state.valueOrNull;
    try {
      final p = await _repo.load();
      state = AsyncData(p);
      print(p.role);
    } catch (e, st) {
      // если было что показывать — оставляем старые данные
      if (prev != null) {
        state = AsyncData(prev);
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  Future<void> save(ProfileModel updated) async {
    state = AsyncData(updated); // optimistic
    await _repo.save(updated);
  }

  /// appUploadImg: type=1 (аватар пользователя)
  /// После успешной загрузки делаем refresh профиля.
  Future<Map<String, dynamic>> uploadAvatar(Uint8List bytes) async {
    final raw = await _local.getToken();
    final userId = _asInt(raw);

    if (userId == null || userId == 0) {
      throw Exception('Не удалось определить userId из localStore.getToken()');
    }

    final res = await _upload.uploadImageBase64(
      type: 1,
      imgId: userId,
      bytes: bytes,
    );

    await refresh();
    return res;
  }
}