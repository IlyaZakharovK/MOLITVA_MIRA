import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/pending_activation_store.dart';
import '../../domain/auth/auth_failure.dart';
import '../../domain/auth/auth_repository.dart';
import 'auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final PendingActivationStore _pendingStore;

  AuthController(this._repo, this._pendingStore) : super(AuthState.initial()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final session = await _repo.restoreSession();
      final pending = await _repo.restorePendingActivationEmail();

      state = state.copyWith(
        isLoading: false,
        session: session,
        pendingActivationEmail: pending,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: null);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final session = await _repo.login(email: email, password: password);
      state = state.copyWith(
        isLoading: false,
        session: session,
        pendingActivationEmail: null,
        errorMessage: null,
      );
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Неизвестная ошибка');
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password1,
    required String password2,
    required int agree,
    int phone = 0,
    int type = 2,
    int diocesesId = 0,
    String hramName = '',
    String hramAddress = '',
    String nastName = '',
    int nastPhone = 0,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.register(
        name: name,
        email: email,
        password1: password1,
        password2: password2,
        agree: agree,
        phone: phone,
        type: type,
        diocesesId: diocesesId,
        hramName: hramName,
        hramAddress: hramAddress,
        nastName: nastName,
        nastPhone: nastPhone,
      );

      state = state.copyWith(
        isLoading: false,
        pendingActivationEmail: email,
        errorMessage: null,
      );
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Неизвестная ошибка');
    }
  }

  Future<void> activateEmail(String code, {required String method}) async {
    final email = state.pendingActivationEmail;
    if (email == null || email.isEmpty) {
      state = state.copyWith(errorMessage: 'Нет email для подтверждения');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.activateEmail(
        email: email,
        activationCode: code,
        method: method,
      );
      state = state.copyWith(
        isLoading: false,
        pendingActivationEmail: null,
        errorMessage: null,
      );
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Неизвестная ошибка');
    }
  }

  Future<void> restoreAccess(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final normalized = email.trim().toLowerCase();
      await _repo.restoreAccess(email: normalized);

      await _pendingStore.setPending(
        email: normalized,
        isAccountActivation: false,
      );

      state = state.copyWith(
        isLoading: false,
        pendingActivationEmail: normalized,
        pendingActivationIsAccount: false,
      );
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Неизвестная ошибка');
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _repo.logout();
    } catch (_) {
      // Даже если logout на репозитории упал, все равно чистим локальные хвосты.
    } finally {
      await _pendingStore.clear();
      state = AuthState.initial();
    }
  }
}