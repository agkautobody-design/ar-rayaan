import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;

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
      usesPassword: u.providerData.any(
        (fb.UserInfo i) => i.providerId == 'password',
      ),
      emailVerified: u.emailVerified,
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
        case 'requires-recent-login':
          return const AuthException(
            'For your security, please enter your password again.',
          );
        case 'operation-not-allowed':
          return const AuthException(
            'This sign-in method is not turned on yet.',
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
    try {
      // The verify screen tells the user to tap the link — send it.
      await _auth.currentUser?.sendEmailVerification();
    } catch (_) {
      // Rate-limited or offline: the verify screen can resend.
    }
    return AuthUser(uid: user.uid, email: user.email, name: name);
  }

  /// Popup sign-in only exists on the web; on phones and desktop it would
  /// throw an unimplemented error, so say so plainly instead.
  static const AuthException socialUnavailable = AuthException(
    'Google and Apple sign-in are available on the web version for now. '
    'Please use your email and password here.',
  );

  @override
  Future<AuthUser> signInWithGoogle() {
    if (!kIsWeb) return Future<AuthUser>.error(socialUnavailable);
    return _guard(() => _auth.signInWithPopup(fb.GoogleAuthProvider()));
  }

  @override
  Future<AuthUser> signInWithApple() {
    if (!kIsWeb) return Future<AuthUser>.error(socialUnavailable);
    return _guard(() => _auth.signInWithPopup(fb.OAuthProvider('apple.com')));
  }

  @override
  Future<void> sendEmailVerification() async {
    final fb.User? u = _auth.currentUser;
    if (u == null) throw const AuthException('Please sign in first.');
    try {
      await u.sendEmailVerification();
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    final fb.User? u = _auth.currentUser;
    if (u == null) throw const AuthException('Please sign in first.');
    try {
      final bool usesPassword = u.providerData.any(
        (fb.UserInfo i) => i.providerId == 'password',
      );
      if (usesPassword) {
        final String? email = u.email;
        if (email == null || password == null || password.isEmpty) {
          throw const AuthException('Please enter your password to continue.');
        }
        await u.reauthenticateWithCredential(
          fb.EmailAuthProvider.credential(email: email, password: password),
        );
      } else if (kIsWeb) {
        final bool apple = u.providerData.any(
          (fb.UserInfo i) => i.providerId == 'apple.com',
        );
        await u.reauthenticateWithPopup(
          apple ? fb.OAuthProvider('apple.com') : fb.GoogleAuthProvider(),
        );
      } else {
        throw socialUnavailable;
      }
      // Remove the documents we keep about this person before the account
      // itself (best effort).
      final String uid = u.uid;
      final FirebaseFirestore db = FirebaseFirestore.instance;
      for (final String path in <String>['users', 'families']) {
        try {
          await db.collection(path).doc(uid).delete();
        } catch (_) {
          // Rules may deny deleting nested data; the account deletion below
          // is what the person asked for and must still happen.
        }
      }
      await u.delete();
    } on AuthException {
      rethrow;
    } catch (e) {
      throw mapError(e);
    }
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
