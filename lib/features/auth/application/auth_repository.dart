/// Authentication domain contracts.
///
/// The live implementation (Firebase Auth) arrives in WP4 once the Founder
/// supplies the Firebase project config (open item O-4). Until then,
/// [FakeAuthRepository] backs the UI so the full flow is real and testable.
/// Swapping implementations touches no screen code.
library;

class AuthUser {
  const AuthUser({required this.uid, required this.email, this.name});

  final String uid;
  final String email;
  final String? name;
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

  Future<void> signOut();
}
