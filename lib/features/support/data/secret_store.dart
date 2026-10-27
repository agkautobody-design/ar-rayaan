import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small named secrets and opt-in memory, kept encrypted on the device.
///
/// On a phone the platform secure store (Keystore, Keychain) holds them. In a
/// browser nothing is written: a value lives in memory for the visit, because
/// a browser cannot keep a secret from someone who has the device. Reads fall
/// back to memory, so a failing store never breaks a screen. Nothing here is
/// ever sent anywhere, logged, or put in analytics.
abstract final class SecretStore {
  static final Map<String, String> _memory = <String, String>{};
  static FlutterSecureStorage? _storage;
  static FlutterSecureStorage get _store => _storage ??= const FlutterSecureStorage();

  static bool get persistsAcrossVisits => !kIsWeb;

  static Future<String?> read(String key) async {
    final String? m = _memory[key];
    if (m != null) return m;
    if (kIsWeb) return null;
    try {
      final String? v = await _store.read(key: key);
      if (v != null) _memory[key] = v;
      return v;
    } catch (_) {
      return null;
    }
  }

  static String? readSync(String key) => _memory[key];

  static Future<void> write(String key, String? value) async {
    if (value == null || value.isEmpty) {
      _memory.remove(key);
      if (!kIsWeb) {
        try {
          await _store.delete(key: key);
        } catch (_) {}
      }
      return;
    }
    _memory[key] = value;
    if (!kIsWeb) {
      try {
        await _store.write(key: key, value: value);
      } catch (_) {}
    }
  }

  /// Loads the given keys into memory at start-up. Never throws.
  static Future<void> preload(List<String> keys) async {
    for (final String k in keys) {
      await read(k);
    }
  }

  static void debugReset() {
    _memory.clear();
    _storage = null;
  }
}
