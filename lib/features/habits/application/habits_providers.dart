import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';

/// The P1 habit layer (Wave A5): Qada make-up counter + fasting log.
/// All data on-device only. The tone is the app's tone: these are gentle
/// ledgers, never scoreboards — "days you returned," not streaks that shame.
class QadaController extends Notifier<Map<String, int>> {
  static const String _key = 'ar.habits.qada';
  static const List<String> prayers = <String>[
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  @override
  Map<String, int> build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final String? raw = prefs.getString(_key);
      if (raw == null) return <String, int>{for (final String p in prayers) p: 0};
      final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
      return <String, int>{
        for (final String p in prayers) p: (j[p] as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return <String, int>{for (final String p in prayers) p: 0};
    }
  }

  Future<void> _save() async {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_key, jsonEncode(state));
    } catch (_) {}
  }

  /// Add missed prayers to make up (or one completed qada with negative).
  Future<void> adjust(String prayer, int delta) async {
    if (!prayers.contains(prayer)) return;
    final int next = ((state[prayer] ?? 0) + delta).clamp(0, 1 << 31);
    state = <String, int>{...state, prayer: next};
    await _save();
  }

  int get total => state.values.fold(0, (int a, int b) => a + b);
}

final NotifierProvider<QadaController, Map<String, int>> qadaProvider =
    NotifierProvider<QadaController, Map<String, int>>(QadaController.new);

/// Fasting log — the set of days the user fasted. A ledger of returns.
class FastingLogController extends Notifier<Set<String>> {
  static const String _key = 'ar.habits.fasting';

  static String stamp(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  Set<String> build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      return (prefs.getStringList(_key) ?? <String>[]).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _save() async {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setStringList(_key, state.toList());
    } catch (_) {}
  }

  Future<void> toggleToday() async {
    final String today = stamp(DateTime.now());
    final Set<String> next = <String>{...state};
    if (!next.remove(today)) next.add(today);
    state = next;
    await _save();
  }

  bool fastedToday() => state.contains(stamp(DateTime.now()));

  int thisYear() {
    final int y = DateTime.now().year;
    return state.where((String s) => s.startsWith('$y-')).length;
  }
}

final NotifierProvider<FastingLogController, Set<String>> fastingLogProvider =
    NotifierProvider<FastingLogController, Set<String>>(
      FastingLogController.new,
    );
