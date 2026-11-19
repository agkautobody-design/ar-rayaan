import 'dart:convert';

import '../../../app/core/content/content_sync.dart';
import 'hosted_cache.dart' show normaliseQuestion;

/// Answers Hādi learned from questions two or more different people asked,
/// checked by tool/hadi_learn/learn.py and installed through Content Sync
/// (qa/hadi_learned.json) with no app release. Exact match on the normalised
/// question only: a near match is never guessed. Entries carry an expiry and
/// are ignored after it, even if the pack was not updated yet.
abstract final class HadiLearned {
  static const String pack = 'qa/hadi_learned.json';

  static Map<String, String> _byKey = <String, String>{};

  /// Loads the pack. Never throws: a bad pack leaves Hādi without learned
  /// answers, which is the same as before.
  static Future<void> load({DateTime? now}) async {
    try {
      parse(await ContentSync.load(pack), now: now);
    } catch (_) {
      _byKey = <String, String>{};
    }
  }

  /// Test hook and the parser behind [load].
  static void parse(String raw, {DateTime? now}) {
    final String today =
        (now ?? DateTime.now()).toIso8601String().substring(0, 10);
    final Map<String, String> out = <String, String>{};
    final Object? d = json.decode(raw);
    if (d is Map<String, dynamic> && d['entries'] is List<dynamic>) {
      for (final dynamic e in d['entries'] as List<dynamic>) {
        if (e is! Map<String, dynamic>) continue;
        final String answer = (e['answer'] ?? '').toString();
        final String expires = (e['expires'] ?? '').toString();
        if (answer.isEmpty || expires.isEmpty || expires.compareTo(today) < 0) {
          continue;
        }
        final Object? keys = e['keys'];
        if (keys is List<dynamic>) {
          for (final dynamic k in keys) {
            out[k.toString()] = answer;
          }
        }
      }
    }
    _byKey = out;
  }

  /// The learned answer for [question], or null.
  static String? answer(String question) {
    if (_byKey.isEmpty) return null;
    final String key = normaliseQuestion(question);
    if (key.split(' ').length < 3) return null;
    return _byKey[key];
  }

  static int get count => _byKey.length;
}
