import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';

/// How a Hādi reply was produced. Counted on this device only.
enum HadiAnswerKind {
  /// The built-in checked library answered (or pointed to a screen).
  local,

  /// The library had nothing and said so (no hosted AI used).
  miss,

  /// A hosted-AI call was made and answered.
  hosted,

  /// A saved hosted answer was reused: no call, no cost.
  cache,

  /// A hosted call failed and the library answered instead.
  failed,

  /// Crisis, child-safety, grief or personal-ruling reply (always local).
  safety,
}

/// Telemetry-free counters: they live in shared_preferences and never leave
/// the device. They exist so the owner can see how often Hādi answers on its
/// own (the thing that keeps hosted-AI cost down). No question text is kept.
class HadiStats {
  HadiStats(this._prefs);

  final SharedPreferences _prefs;

  static String _key(HadiAnswerKind k) => 'ar.hadi.stats.${k.name}';

  int count(HadiAnswerKind k) => _prefs.getInt(_key(k)) ?? 0;

  Future<void> record(HadiAnswerKind k) async {
    try {
      await _prefs.setInt(_key(k), count(k) + 1);
    } catch (_) {}
  }

  int get total => HadiAnswerKind.values.fold<int>(
        0,
        (int a, HadiAnswerKind k) => a + count(k),
      );

  /// Share of replies that needed no hosted call (0 to 1), or null with no
  /// replies yet. Cache hits count as local: they cost nothing.
  double? get localShare {
    final int t = total;
    if (t == 0) return null;
    final int paid = count(HadiAnswerKind.hosted) + count(HadiAnswerKind.failed);
    return (t - paid) / t;
  }

  Future<void> reset() async {
    for (final HadiAnswerKind k in HadiAnswerKind.values) {
      await _prefs.remove(_key(k));
    }
  }
}

final Provider<HadiStats> hadiStatsProvider = Provider<HadiStats>(
  (ref) => HadiStats(ref.watch(sharedPreferencesProvider)),
);
