import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_repository.dart';
import '../application/profile_repository.dart';
import '../domain/user_profile.dart';

/// SharedPreferences-backed profile store — per-user records, offline-first.
class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String uid) => 'ar.profile.$uid';

  @override
  Future<UserProfile> ensureProfile(AuthUser user) async {
    final String? raw = _prefs.getString(_key(user.uid));
    if (raw != null) {
      try {
        return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Corrupted record — recreate below.
      }
    }
    final UserProfile profile = UserProfile(
      uid: user.uid,
      displayName: user.name ?? user.email.split('@').first,
      email: user.email,
      createdAt: DateTime.now(),
    );
    await save(profile);
    return profile;
  }

  @override
  Future<void> save(UserProfile profile) async {
    await _prefs.setString(_key(profile.uid), jsonEncode(profile.toJson()));
  }
}
