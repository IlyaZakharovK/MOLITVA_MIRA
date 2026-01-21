import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart' show PersistCookieJar;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vsem_mirom/presentation/my_communities/my_communities_controller.dart';

import 'api/cookieStore.dart';
import 'data/auth/api_auth_repository.dart';
import 'data/auth/auth_local_store.dart';

import 'data/auth/fake_auth_repository.dart';
import 'data/dioceses/api_dioceses_repository.dart';
import 'data/post_details/fake_post_details_repository.dart';
import 'data/prayer_request/api_prayer_request_repository.dart';
import 'data/prayer_requests/fake_prayer_requests_repository.dart';
import 'data/notifications/notifications_repository.dart';
import 'data/communities/communities_repository.dart';
import 'data/auth/pending_activation_store.dart';

import 'domain/auth/auth_repository.dart';
import 'domain/dioceses/diocese.dart';
import 'domain/dioceses/dioceses_repository.dart';
import 'domain/my_communities/my_communities_repository.dart';
import 'domain/post_details/post_details_repository.dart';
import 'domain/prayer_request/prayer_request_repository.dart';
import 'domain/prayer_requests/prayer_requests_repository.dart';
import 'domain/notifications/notifications_repository.dart';
import 'domain/communities/communities_repository.dart';
import 'domain/register/registration_manager.dart';

import 'presentation/auth/auth_controller.dart';
import 'presentation/auth/auth_state.dart';

// --- core api deps (override in main)
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

// --- auth
const _useFakeAuth = false;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (_useFakeAuth) return FakeAuthRepository();

  return ApiAuthRepository(
    dio: ref.watch(dioProvider),
    cookieStore: ref.watch(sessionCookieStoreProvider),
    localStore: ref.watch(authLocalStoreProvider),
  );
});

final pendingActivationStoreProvider = Provider<PendingActivationStore>((ref) {
  return PendingActivationStore(ref.watch(secureStorageProvider));
});

final authControllerProvider =
StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final pending = ref.watch(pendingActivationStoreProvider);
  return AuthController(repo, pending);
});

// --- register flow
final registrationManagerProvider = Provider((ref) => RegistrationManager());

// --- остальные репозитории
final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return FakeNotificationsRepository();
});

final communitiesRepositoryProvider = Provider<CommunitiesRepository>((ref) {
  return FakeCommunitiesRepository();
});

final prayerRequestRepositoryProvider = Provider<PrayerRequestRepository>((ref) {
  return ApiPrayerRequestRepository(ref.watch(dioProvider), ref.watch(authLocalStoreProvider));
});

final prayerRequestsRepositoryProvider = Provider<PrayerRequestsRepository>((ref) {
  return FakePrayerRequestsRepository();
});

final myCommunitiesRepositoryProvider = Provider<MyCommunitiesRepository>((ref) {
  return FakeMyMyCommunitiesRepositoryFix().repo;
});

final postDetailsRepositoryProvider = Provider<PostDetailsRepository>((ref) {
  return FakePostDetailsRepository();
});
