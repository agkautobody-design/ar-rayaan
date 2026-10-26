import 'package:shared_preferences/shared_preferences.dart';

import 'token_store.dart';

/// Keeps the session token in SharedPreferences (browser storage on the web).
/// That is no safer than the app's other local data; the token can be revoked
/// from the account's session list, and it expires.
class PrefsTokenStore implements TokenStore {
  PrefsTokenStore(this._prefs);

  final SharedPreferences _prefs;

  static const String key = 'ar.community.session';

  @override
  Future<String?> read() async => _prefs.getString(key);

  @override
  Future<void> write(String token) async {
    await _prefs.setString(key, token);
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(key);
  }
}
