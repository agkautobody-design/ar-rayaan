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

  /// Zero-padded `yyyy-mm-dd`, so keys sort and compare as text.
  static String stamp(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Normalises a saved key; the first release stored unpadded `2026-10-4`.
  static String? normalize(String raw) {
    final List<String> p = raw.split('-');
    if (p.length != 3) return null;
    final int? y = int.tryParse(p[0]);
    final int? m = int.tryParse(p[1]);
    final int? d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return stamp(DateTime(y, m, d));
  }

  @override
  Set<String> build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      return (prefs.getStringList(_key) ?? <String>[])
          .map(normalize)
          .whereType<String>()
          .toSet();
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

  /// Marks or unmarks any day (so a missed tap yesterday can be written).
  Future<void> toggleDate(DateTime day) async {
    final String key = stamp(day);
    final Set<String> next = <String>{...state};
    if (!next.remove(key)) next.add(key);
    state = next;
    await _save();
  }

  Future<void> toggleToday() => toggleDate(DateTime.now());

  bool fastedOn(DateTime day) => state.contains(stamp(day));

  bool fastedToday() => fastedOn(DateTime.now());

  bool fastedYesterday() {
    final DateTime n = DateTime.now();
    return fastedOn(DateTime(n.year, n.month, n.day - 1));
  }

  int thisYear() {
    final int y = DateTime.now().year;
    return state.where((String s) => s.startsWith('$y-')).length;
  }
}

final NotifierProvider<FastingLogController, Set<String>> fastingLogProvider =
    NotifierProvider<FastingLogController, Set<String>>(
      FastingLogController.new,
    );

/// Dhikr ledger — how many remembrances were counted each day, saved on this
/// device. A gentle ledger like the others: totals, never streaks.
///
/// The Dhikr School calls [record] with the taps of a session as it ends
/// (see the report for the one-line hook); until then the ledger simply
/// shows zero.
class DhikrLedgerController extends Notifier<Map<String, int>> {
  static const String _key = 'ar.habits.dhikr';

  @override
  Map<String, int> build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final String? raw = prefs.getString(_key);
      if (raw == null) return <String, int>{};
      final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
      return <String, int>{
        for (final MapEntry<String, dynamic> e in j.entries)
          if (e.value is num && (e.value as num) > 0)
            e.key: (e.value as num).toInt(),
      };
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> _save() async {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_key, jsonEncode(state));
    } catch (_) {}
  }

  /// Adds [count] remembrances to [day] (default today).
  Future<void> record(int count, {DateTime? day}) async {
    if (count <= 0) return;
    final String key = FastingLogController.stamp(day ?? DateTime.now());
    state = <String, int>{...state, key: (state[key] ?? 0) + count};
    await _save();
  }

  int get today => state[FastingLogController.stamp(DateTime.now())] ?? 0;

  /// Total over the last seven days including today.
  int get lastSevenDays {
    final DateTime n = DateTime.now();
    int sum = 0;
    for (int i = 0; i < 7; i++) {
      sum += state[FastingLogController.stamp(
            DateTime(n.year, n.month, n.day - i),
          )] ??
          0;
    }
    return sum;
  }
}

final NotifierProvider<DhikrLedgerController, Map<String, int>>
dhikrLedgerProvider =
    NotifierProvider<DhikrLedgerController, Map<String, int>>(
      DhikrLedgerController.new,
    );
