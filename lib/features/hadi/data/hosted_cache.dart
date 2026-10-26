import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Turns a question into a stable cache key: lower case, letters and digits
/// only, single spaces, polite filler removed, at most 200 characters.
String normaliseQuestion(String q) {
  String s = q.toLowerCase();
  s = s.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  s = s.replaceFirst(
    RegExp(r'^(?:(?:please|hadi|salam|salaam|assalamu alaikum|tell me|can you '
        r'tell me|i want to know|i would like to know)\s+)+'),
    '',
  );
  return s.length > 200 ? s.substring(0, 200) : s;
}

/// A saved copy of hosted answers, so the same question is never paid for
/// twice. Persisted in shared_preferences, with a time-to-live and a size
/// cap (oldest entries leave first). It holds question keys and the model's
/// reply text only, on this device only.
///
/// Only reply text from the hosted backend is stored, and it is checked
/// again (reference verifier, ruling filter, label) every time it is shown.
class HostedAnswerCache {
  HostedAnswerCache(
    this._prefs, {
    DateTime Function()? clock,
    this.ttl = const Duration(days: 30),
    this.maxEntries = 100,
  }) : _clock = clock ?? DateTime.now;

  static const String prefKey = 'ar.hadi.hostedCache.v1';

  final SharedPreferences _prefs;
  final DateTime Function() _clock;
  final Duration ttl;
  final int maxEntries;

  Map<String, Map<String, Object?>> _load() {
    try {
      final String? raw = _prefs.getString(prefKey);
      if (raw == null || raw.isEmpty) return <String, Map<String, Object?>>{};
      final Object? d = json.decode(raw);
      if (d is! Map<String, dynamic>) return <String, Map<String, Object?>>{};
      final Map<String, Map<String, Object?>> out =
          <String, Map<String, Object?>>{};
      for (final MapEntry<String, dynamic> e in d.entries) {
        final Object? v = e.value;
        if (v is Map<String, dynamic>) out[e.key] = Map<String, Object?>.from(v);
      }
      return out;
    } catch (_) {
      return <String, Map<String, Object?>>{};
    }
  }

  /// The saved reply for [key], or null when none or older than [ttl].
  String? get(String key) {
    if (key.isEmpty) return null;
    final Map<String, Object?>? e = _load()[key];
    if (e == null) return null;
    final Object? t = e['t'];
    final Object? a = e['a'];
    if (t is! int || a is! String || a.isEmpty) return null;
    final int age = _clock().millisecondsSinceEpoch - t;
    if (age < 0 || age > ttl.inMilliseconds) return null;
    return a;
  }

  Future<void> put(String key, String answer) async {
    if (key.isEmpty || answer.trim().isEmpty) return;
    try {
      final Map<String, Map<String, Object?>> m = _load();
      m[key] = <String, Object?>{
        't': _clock().millisecondsSinceEpoch,
        'a': answer,
      };
      if (m.length > maxEntries) {
        final List<MapEntry<String, Map<String, Object?>>> byAge =
            m.entries.toList()
              ..sort((a, b) => ((a.value['t'] as int?) ?? 0)
                  .compareTo((b.value['t'] as int?) ?? 0));
        final int drop = m.length - maxEntries;
        for (int i = 0; i < drop; i++) {
          m.remove(byAge[i].key);
        }
      }
      await _prefs.setString(prefKey, json.encode(m));
    } catch (_) {}
  }

  Future<void> clear() => _prefs.remove(prefKey);
}
