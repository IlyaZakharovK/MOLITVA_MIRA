import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart' show PersistCookieJar;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api/cookieStore.dart';
import 'data/auth/api_auth_repository.dart';
import 'data/auth/auth_local_store.dart';

import 'data/community_details/api_community_details_repository.dart';
import 'data/dioceses/api_dioceses_repository.dart';
import 'data/news/fake_news_repository.dart';
import 'data/prayer_request/api_prayer_request_repository.dart';
import 'data/notifications/notifications_repository.dart';
import 'data/communities/communities_repository.dart';
import 'data/auth/pending_activation_store.dart';
import 'data/help/help_repository.dart';

import 'data/prays/api_prays_repository.dart';
import 'data/profile/api_profile_repository.dart';
import 'data/upload/upload_repository.dart';
import 'domain/auth/auth_repository.dart';
import 'domain/community_details/community_details_repository.dart';
import 'domain/dioceses/diocese.dart';
import 'domain/dioceses/dioceses_repository.dart';
import 'domain/news/news_repository.dart';
import 'domain/prayer_request/prayer_request_repository.dart';
import 'domain/notifications/notifications_repository.dart';
import 'domain/communities/communities_repository.dart';
import 'domain/prays/prays_repository.dart';
import 'domain/profile/profile_repository.dart';
import 'domain/register/registration_manager.dart';
import 'domain/help/help_repository.dart';

import 'presentation/auth/auth_controller.dart';
import 'presentation/auth/auth_state.dart';

final dioProvider = Provider<Dio>((ref) {
  throw UnimplementedError('dioProvider must be overridden in main()');
});

final cookieJarProvider = Provider<PersistCookieJar>((ref) {
  throw UnimplementedError('cookieJarProvider must be overridden in main()');
});

final sessionCookieStoreProvider = Provider<SessionCookieStore>((ref) {
  return SessionCookieStore(ref.watch(cookieJarProvider));
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authLocalStoreProvider = Provider<AuthLocalStore>((ref) {
  return AuthLocalStore(ref.watch(secureStorageProvider));
});

final diocesesRepositoryProvider = Provider<DiocesesRepository>((ref) {
  return ApiDiocesesRepository(ref.watch(dioProvider));
});

final diocesesProvider = FutureProvider<List<Diocese>>((ref) async {
  return ref.watch(diocesesRepositoryProvider).getDioceses();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(
    dio: ref.watch(dioProvider),
    cookieStore: ref.watch(sessionCookieStoreProvider),
    localStore: ref.watch(authLocalStoreProvider),
  );
});

final pendingActivationStoreProvider = Provider<PendingActivationStore>((ref) {
  return PendingActivationStore(ref.watch(secureStorageProvider));
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final repo = ref.watch(authRepositoryProvider);
    final pending = ref.watch(pendingActivationStoreProvider);
    return AuthController(repo, pending);
  },
);

final registrationManagerProvider = Provider((ref) => RegistrationManager());

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return FakeNotificationsRepository();
});

final communitiesRepositoryProvider = Provider<CommunitiesRepository>((ref) {
  return APICommunitiesRepository(
    dio: ref.watch(dioProvider),
    localStore: ref.watch(authLocalStoreProvider),
  );
});

final prayerRequestRepositoryProvider = Provider<PrayerRequestRepository>((ref,) {
  return ApiPrayerRequestRepository(
    ref.watch(dioProvider),
    ref.watch(authLocalStoreProvider),
  );
});

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return APINewsRepository(dio: ref.watch(dioProvider));
});

final communityDetailsRepositoryProvider = Provider<CommunityDetailsRepository>(
  (ref) {
    return APICommunityDetailsRepository(
      dio: ref.watch(dioProvider),
      localStore: ref.watch(authLocalStoreProvider),
    );
  },
);

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return UploadRepository(dio);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ApiProfileRepository(
    dio: ref.watch(dioProvider),
    local: ref.watch(authLocalStoreProvider),
  );
});

final prayRepositoryProvider = Provider<PrayRepository>((ref) {
  return ApiPraysRepository(dio: ref.watch(dioProvider));
});

final helpChatRepositoryProvider = Provider<HelpRepository>((ref) {
  return ApiHelpRepository(
    dio: ref.watch(dioProvider),
    localStore: ref.watch(authLocalStoreProvider),
  );
});

final appHardResetProvider = StateProvider<int>((ref) => 0);
