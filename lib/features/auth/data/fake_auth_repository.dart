import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../application/auth_repository.dart';

/// Pre-Firebase authentication: realistic latency, validation, session state,
/// and **session persistence** (survives restarts) so every auth screen is
/// fully functional. Replaced by FirebaseAuthRepository when the Founder's
/// Firebase config lands (O-4) — Firebase persists sessions natively.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository([this._prefs]);

  final SharedPreferences? _prefs;

  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  static const Duration _latency = Duration(milliseconds: 700);
  static const String _sessionKey = 'ar.auth.session';

  /// Restores a persisted session (call once at bootstrap when prefs exist).
  Future<void> init() async {
    final String? raw = _prefs?.getString(_sessionKey);
    if (raw == null) return;
    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      _user = AuthUser(
        uid: json['uid'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
      );
    } catch (_) {
      await _prefs?.remove(_sessionKey);
    }
  }

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _user; // current session first (restored or null)
    yield* _controller.stream;
  }

  @override
  Future<AuthUser?> currentUser() async => _user;

  Future<AuthUser> _establish(AuthUser user) async {
    _user = user;
    await _prefs?.setString(
      _sessionKey,
      jsonEncode({'uid': user.uid, 'email': user.email, 'name': user.name}),
    );
    _controller.add(_user);
    return user;
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_latency);
    if (password.length < 6) {
      throw const AuthException('Incorrect email or password.');
    }
    return _establish(AuthUser(uid: 'demo-uid', email: email, name: 'Ahmed'));
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_latency);
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }
    return _establish(AuthUser(uid: 'demo-uid', email: email, name: name));
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    await Future<void>.delayed(_latency);
    return _establish(
      const AuthUser(
        uid: 'demo-google',
        email: 'ahmed@gmail.com',
        name: 'Ahmed',
      ),
    );
  }

  @override
  Future<AuthUser> signInWithApple() async {
    await Future<void>.delayed(_latency);
    return _establish(
      const AuthUser(
        uid: 'demo-apple',
        email: 'ahmed@icloud.com',
        name: 'Ahmed',
      ),
    );
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    await Future<void>.delayed(_latency);
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _user = null;
    await _prefs?.remove(_sessionKey);
    _controller.add(null);
  }
}
