import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../../prayer/application/prayer_log.dart';
import '../domain/streak_math.dart';

/// The acts recorded in the streak store. The five prayers are NOT here: the
/// prayers streak is read from the prayer log the person already keeps.
enum StreakAct { quran, dhikr, lesson }

/// What a streak is about, as the person sees it.
enum StreakTrack {
  quran('Qur’an reading'),
  dhikr('Dhikr and tasbeeh'),
  prayers('Prayers logged'),
  returned('Days returned');

  const StreakTrack(this.label);

  final String label;

  /// Prayers are between a person and Allah: this track is never offered for
  /// sharing, whatever else changes.
  bool get shareable => this != StreakTrack.prayers;
}

/// Days on which each [StreakAct] happened (zero-padded `yyyy-mm-dd`). Kept
/// on this device only (`ar.streaks.days`). Recording is gated by the
/// "Keep my streaks" switch (see `noteStreak` in return_loop.dart).
class StreaksStore extends Notifier<Map<StreakAct, Set<String>>> {
  static const String key = 'ar.streaks.days';

  /// Keeps the store small: older days cannot change a run anyway.
  static const int keepDays = 400;

  @override
  Map<StreakAct, Set<String>> build() {
    final Map<StreakAct, Set<String>> out = <StreakAct, Set<String>>{
      for (final StreakAct a in StreakAct.values) a: <String>{},
    };
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final String? raw = prefs.getString(key);
      if (raw == null) return out;
      final Object? j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return out;
      for (final StreakAct a in StreakAct.values) {
        final Object? list = j[a.name];
        if (list is List<dynamic>) {
          out[a] = <String>{
            for (final dynamic s in list)
              if (s is String) s,
          };
        }
      }
    } catch (_) {}
    return out;
  }

  Future<void> _save() async {
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setString(
            key,
            jsonEncode(<String, List<String>>{
              for (final MapEntry<StreakAct, Set<String>> e in state.entries)
                e.key.name: (e.value.toList()..sort()),
            }),
          );
    } catch (_) {}
  }

  /// Notes that [act] happened today (or [now]).
  Future<void> record(StreakAct act, {DateTime? now}) async {
    final DateTime d = now ?? DateTime.now();
    final String stamp = StreakMath.stamp(d);
    final Set<String> have = state[act] ?? <String>{};
    if (have.contains(stamp)) return;
    final String oldest = StreakMath.stamp(
      DateTime(d.year, d.month, d.day - keepDays),
    );
    state = <StreakAct, Set<String>>{
      ...state,
      act: <String>{...have.where((String s) => s.compareTo(oldest) >= 0), stamp},
    };
    await _save();
  }

  /// Forgets every stored day (switching streaks off, or "Erase").
  Future<void> clear() async {
    state = <StreakAct, Set<String>>{
      for (final StreakAct a in StreakAct.values) a: <String>{},
    };
    try {
      await ref.read(sharedPreferencesProvider).remove(key);
    } catch (_) {}
  }
}

final NotifierProvider<StreaksStore, Map<StreakAct, Set<String>>>
streaksStoreProvider =
    NotifierProvider<StreaksStore, Map<StreakAct, Set<String>>>(
      StreaksStore.new,
    );

/// One streak, ready to draw: the days done, the days that do not count
/// either way, and the run that is alive today.
class StreakView {
  const StreakView({
    required this.track,
    required this.done,
    required this.neutral,
    required this.run,
    required this.today,
  });

  final StreakTrack track;
  final Set<String> done;
  final Set<String> neutral;
  final StreakRun run;
  final DateTime today;

  int get days => run.days;

  bool get graceAvailable => StreakMath.graceAvailable(run, today);

  bool isDone(DateTime d) => done.contains(StreakMath.stamp(d));

  bool isGrace(DateTime d) => run.bridged.contains(StreakMath.stamp(d));

  bool isNeutral(DateTime d) =>
      neutral.contains(StreakMath.stamp(d)) && !isDone(d);

  /// Done days in the month of [month].
  int doneInMonth(DateTime month) {
    final String prefix = StreakMath.stamp(DateTime(month.year, month.month, 1))
        .substring(0, 8);
    return done.where((String s) => s.startsWith(prefix)).length;
  }
}

/// Prayer days from the log: a day counts when at least one prayer is marked
/// prayed (on time or late). A day with only "excused" marks is neutral: it
/// is skipped, never counted against anyone.
({Set<String> done, Set<String> neutral}) prayerDays(PrayerLogState log) {
  final Set<String> done = <String>{};
  final Set<String> neutral = <String>{};
  for (final MapEntry<String, Map<String, PrayerMark>> e in log.days.entries) {
    final Iterable<PrayerMark> marks = e.value.values;
    if (marks.any(
      (PrayerMark m) => m == PrayerMark.prayed || m == PrayerMark.prayedLate,
    )) {
      done.add(e.key);
    } else if (marks.isNotEmpty &&
        marks.every((PrayerMark m) => m == PrayerMark.excused)) {
      neutral.add(e.key);
    }
  }
  return (done: done, neutral: neutral);
}

final ProviderFamily<StreakView, StreakTrack> streakViewProvider =
    Provider.family<StreakView, StreakTrack>((Ref ref, StreakTrack track) {
      final DateTime now = DateTime.now();
      Set<String> done;
      Set<String> neutral = <String>{};
      switch (track) {
        case StreakTrack.quran:
          done = ref.watch(streaksStoreProvider)[StreakAct.quran] ?? <String>{};
        case StreakTrack.dhikr:
          done = ref.watch(streaksStoreProvider)[StreakAct.dhikr] ?? <String>{};
        case StreakTrack.returned:
          done = <String>{
            for (final Set<String> s in ref.watch(streaksStoreProvider).values)
              ...s,
          };
        case StreakTrack.prayers:
          final ({Set<String> done, Set<String> neutral}) p = prayerDays(
            ref.watch(prayerLogProvider),
          );
          done = p.done;
          neutral = p.neutral;
      }
      return StreakView(
        track: track,
        done: done,
        neutral: neutral,
        run: StreakMath.run(done, now, neutral: neutral),
        today: DateTime(now.year, now.month, now.day),
      );
    });
