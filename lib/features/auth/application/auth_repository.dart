/// Authentication domain contracts.
///
/// The live implementation (Firebase Auth) arrives in WP4 once the Founder
/// supplies the Firebase project config (open item O-4). Until then,
/// [FakeAuthRepository] backs the UI so the full flow is real and testable.
/// Swapping implementations touches no screen code.
library;

class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.name,
    this.usesPassword = true,
    this.emailVerified = false,
  });

  final String uid;
  final String email;
  final String? name;

  /// True when the account signs in with an email and password, so deleting
  /// it needs the password again; false for Google / Apple accounts.
  final bool usesPassword;

  final bool emailVerified;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  Future<AuthUser?> currentUser();

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthUser> signInWithGoogle();

  Future<AuthUser> signInWithApple();

  Future<void> sendPasswordReset({required String email});

  /// Sends (or re-sends) the verification link to the signed-in account.
  /// Throws [AuthException] with a plain message when it cannot.
  Future<void> sendEmailVerification();

  /// Permanently deletes the signed-in account after re-authenticating.
  /// [password] is required for email accounts. Throws [AuthException].
  Future<void> deleteAccount({String? password});

  Future<void> signOut();
}
