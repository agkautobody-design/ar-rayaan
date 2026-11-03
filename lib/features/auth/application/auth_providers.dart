import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_auth_repository.dart';
import 'auth_repository.dart';

/// Auth wiring — LIVE Firebase Auth.
/// Each email/password sign-up creates a real, separate Firebase account.
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) => FirebaseAuthRepository());

final StreamProvider<AuthUser?> authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Controls async auth actions from the screens (loading / error states).
class AuthController extends Notifier<AsyncValue<AuthUser?>> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AsyncValue<AuthUser?> build() => const AsyncData(null);

  Future<AuthUser?> _run(Future<AuthUser> Function() action) async {
    state = const AsyncLoading();
    try {
      final AuthUser user = await action();
      state = AsyncData(user);
      return user;
    } on AuthException catch (e, st) {
      state = AsyncError(e, st);
      return null;
    } catch (_, st) {
      state = AsyncError(
        const AuthException('Something went wrong. Please try again.'),
        st,
      );
      return null;
    }
  }

  Future<AuthUser?> signIn(String email, String password) =>
      _run(() => _repo.signInWithEmail(email: email, password: password));

  Future<AuthUser?> signUp(String name, String email, String password) => _run(
    () => _repo.signUpWithEmail(name: name, email: email, password: password),
  );

  Future<AuthUser?> signInWithGoogle() => _run(_repo.signInWithGoogle);

  Future<AuthUser?> signInWithApple() => _run(_repo.signInWithApple);

  Future<bool> resetPassword(String email) async {
    state = const AsyncLoading();
    try {
      await _repo.sendPasswordReset(email: email);
      state = const AsyncData(null);
      return true;
    } on AuthException catch (e, st) {
      state = AsyncError(e, st);
      return false;
    } catch (_, st) {
      state = AsyncError(
        const AuthException('Something went wrong. Please try again.'),
        st,
      );
      return false;
    }
  }

  Future<String?> _runVoid(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> resendVerification() =>
      _runVoid(_repo.sendEmailVerification);

  Future<String?> deleteAccount({String? password}) =>
      _runVoid(() => _repo.deleteAccount(password: password));

  Future<void> signOut() => _repo.signOut();
}

final NotifierProvider<AuthController, AsyncValue<AuthUser?>>
authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<AuthUser?>>(AuthController.new);
