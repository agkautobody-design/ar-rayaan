import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where a person's own AI key lives.
///
/// Before Oct 2026 the key sat in SharedPreferences in plain text (localStorage
/// in a browser). Now:
///  * on Android and iOS it is kept in the platform's secure store (Keystore,
///    Keychain) and loaded into memory at start-up by [load];
///  * in a browser nothing is written at all: the key lives in memory for the
///    visit and has to be pasted again next time, because a browser cannot
///    hold a secret from someone who has the device;
///  * a key found in the old plain-text place is moved, and the plain-text
///    copy is removed.
///
/// [read] is synchronous (the controllers read the key on every question). It
/// falls back to the old preference only so a test, or an install that has not
/// reached [load] yet, still works; after [load] that place is empty.
abstract final class ApiKeyVault {
  /// The old plain-text place. Read only for the move, then removed.
  static const String legacyPref = 'ar.hadi.apikey';

  static const String _secureName = 'ar.hadi.apikey.secure';

  static String? _memory;

  static FlutterSecureStorage? _storage;

  static FlutterSecureStorage get _store =>
      _storage ??= const FlutterSecureStorage();

  /// True when a saved key survives closing the app.
  static bool get persistsAcrossVisits => !kIsWeb;

  /// The key in use, or null.
  static String? read(SharedPreferences? prefs) {
    final String? m = _memory;
    if (m != null && m.trim().isNotEmpty) return m.trim();
    try {
      final String? old = prefs?.getString(legacyPref);
      if (old != null && old.trim().isNotEmpty) return old.trim();
    } catch (_) {}
    return null;
  }

  /// Loads the saved key into memory and moves any plain-text copy. Call once
  /// at start-up, before the first question. Never throws.
  static Future<void> load(SharedPreferences prefs) async {
    String? stored;
    if (!kIsWeb) {
      try {
        stored = await _store.read(key: _secureName);
      } catch (_) {
        stored = null;
      }
    }
    String? old;
    try {
      old = prefs.getString(legacyPref);
    } catch (_) {
      old = null;
    }
    final String? s1 = stored;
    final String? o1 = old;
    if (s1 != null && s1.trim().isNotEmpty) {
      _memory = s1.trim();
    } else if (o1 != null && o1.trim().isNotEmpty) {
      _memory = o1.trim();
      if (!kIsWeb) {
        try {
          await _store.write(key: _secureName, value: o1.trim());
        } catch (_) {}
      }
    }
    if (old != null) {
      try {
        await prefs.remove(legacyPref);
      } catch (_) {}
    }
  }

  /// Keeps [key] for this visit and, on a phone, in the secure store. An empty
  /// key removes it everywhere. The plain-text place is always cleared.
  static Future<void> save(String key, SharedPreferences? prefs) async {
    final String trimmed = key.trim();
    _memory = trimmed.isEmpty ? null : trimmed;
    if (!kIsWeb) {
      try {
        if (trimmed.isEmpty) {
          await _store.delete(key: _secureName);
        } else {
          await _store.write(key: _secureName, value: trimmed);
        }
      } catch (_) {}
    }
    try {
      await prefs?.remove(legacyPref);
    } catch (_) {}
  }

  /// Forgets the in-memory key (tests).
  static void debugReset() {
    _memory = null;
    _storage = null;
  }
}
