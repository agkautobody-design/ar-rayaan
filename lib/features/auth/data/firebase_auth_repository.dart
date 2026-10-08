import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../application/auth_repository.dart';

/// Live Firebase Auth implementation (O-4). Drop-in for
/// [FakeAuthRepository] — same contract, so no screen changes. Sessions
/// persist natively via Firebase.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository([fb.FirebaseAuth? auth])
    : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  static AuthUser _toAuthUser(fb.User u) {
    return AuthUser(
      uid: u.uid,
      email: u.email ?? '',
      name: u.displayName,
    );
  }

  /// Maps Firebase errors to human, founder-friendly messages. Static and
  /// pure so it is unit-testable without a live Firebase instance.
  static AuthException mapError(Object e) {
    if (e is fb.FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return const AuthException('That email address looks invalid.');
        case 'user-disabled':
          return const AuthException('This account has been disabled.');
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return const AuthException('Email or password is incorrect.');
        case 'email-already-in-use':
          return const AuthException(
            'An account already exists for that email — try signing in.',
          );
        case 'weak-password':
          return const AuthException(
            'Please choose a stronger password (6+ characters).',
          );
        case 'too-many-requests':
          return const AuthException(
            'Too many attempts — please wait a moment and try again.',
          );
        case 'network-request-failed':
          return const AuthException(
            'No connection — check your internet and try again.',
          );
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          return const AuthException('Sign-in was cancelled.');
      }
    }
    return const AuthException('Something went wrong. Please try again.');
  }

  Future<AuthUser> _guard(Future<fb.UserCredential> Function() action) async {
    try {
      final fb.UserCredential cred = await action();
      final fb.User? u = cred.user;
      if (u == null) {
        throw const AuthException('Sign-in failed. Please try again.');
      }
      return _toAuthUser(u);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().map(
      (fb.User? u) => u == null ? null : _toAuthUser(u),
    );
  }

  @override
  Future<AuthUser?> currentUser() async {
    final fb.User? u = _auth.currentUser;
    return u == null ? null : _toAuthUser(u);
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _guard(
      () => _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final AuthUser user = await _guard(
      () => _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
    try {
      await _auth.currentUser?.updateDisplayName(name);
    } catch (_) {
      // Display name is cosmetic — never fail the sign-up over it.
    }
    return AuthUser(uid: user.uid, email: user.email, name: name);
  }

  @override
  Future<AuthUser> signInWithGoogle() {
    return _guard(() => _auth.signInWithPopup(fb.GoogleAuthProvider()));
  }

  @override
  Future<AuthUser> signInWithApple() {
    return _guard(() => _auth.signInWithPopup(fb.OAuthProvider('apple.com')));
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
