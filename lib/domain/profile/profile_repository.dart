import 'profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> load();
  Future<void> save(ProfileModel updated);
}
