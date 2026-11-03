import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-first cache manager for Academy content.
/// Stores lesson content locally so users can learn without internet.
class AcademyCache {
  static const String _prefix = 'academy_cache.';
  static const String _versionKey = 'academy_cache_version';
  static const Duration _maxAge = Duration(days: 7);

  /// Cache a lesson's content.
  static Future<void> cacheLesson(String lessonId, Map<String, dynamic> content) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'content': content,
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString('$_prefix$lessonId', jsonEncode(data));
  }

  /// Retrieve a cached lesson, or null if expired/missing.
  static Future<Map<String, dynamic>?> getLesson(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$lessonId');
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(data['cachedAt'] as String);
      if (DateTime.now().difference(cachedAt) > _maxAge) {
        await prefs.remove('$_prefix$lessonId');
        return null;
      }
      return data['content'] as Map<String, dynamic>;
    } catch (_) {
      await prefs.remove('$_prefix$lessonId');
      return null;
    }
  }

  /// Check if a lesson is available offline.
  static Future<bool> hasLesson(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_prefix$lessonId');
  }

  /// Clear all cached lessons.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Get cache size in bytes (approximate).
  static Future<int> getCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    int size = 0;
    for (final key in keys) {
      final value = prefs.getString(key);
      if (value != null) size += value.length * 2; // UTF-16 approx
    }
    return size;
  }

  /// Set the remote content version. If changed, cache is stale.
  static Future<void> setRemoteVersion(int version) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_versionKey);
    if (current != version) {
      await clearAll();
      await prefs.setInt(_versionKey, version);
    }
  }
}
