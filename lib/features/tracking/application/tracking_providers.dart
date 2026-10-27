import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../../academy/domain/path_ux.dart';
import '../../habits/application/habits_providers.dart';
import '../../prayer/application/prayer_log.dart';
import '../domain/encouragement.dart';
import '../domain/tracking_math.dart';

/// The acts recorded in the log store. Prayers and fasting are NOT here: they
/// are read from the prayer log and the fasting log the person already keeps.
enum TrackingAct { quran, dhikr, lesson }

/// What a log is about, as the person sees it.
enum TrackingTrack {
  all('Everything'),
  quran('Qur’an reading'),
  dhikr('Dhikr and tasbeeh'),
  prayers('Prayers'),
  fasting('Fasting'),
  lessons('Lessons');

  const TrackingTrack(this.label);

  final String label;

  /// Prayers, fasting and the like are between a person and Allah: no track
  /// is offered for sharing, whatever else changes.
  bool get shareable => false;

  /// Tracks that need the opt-in switch (the others read logs the person
  /// already keeps by hand).
  bool get needsSwitch =>
      this == TrackingTrack.quran || this == TrackingTrack.dhikr;

  /// "prayers" or "days" in the sentence "You have logged 3 days this week".
  String get unitOne => this == TrackingTrack.prayers ? 'prayer' : 'day';
  String get unitMany => this == TrackingTrack.prayers ? 'prayers' : 'days';
}

/// Days on which each [TrackingAct] happened (zero-padded `yyyy-mm-dd`). Kept
/// on this device only (`ar.tracking.days`). Recording is gated by the
/// "Keep a private log" switch (see `noteTracking` in return_loop.dart).
class TrackingStore extends Notifier<Map<TrackingAct, Set<String>>> {
  static const String key = 'ar.tracking.days';

  /// The key an earlier release used for the same days. Read once so nobody
  /// loses what they already logged; never written again.
  static const String legacyKey = 'ar.streaks.days';

  /// About ten years of days; they are tiny and counts must not shrink.
  static const int keepDays = 3650;

  @override
  Map<TrackingAct, Set<String>> build() {
    final Map<TrackingAct, Set<String>> out = <TrackingAct, Set<String>>{
      for (final TrackingAct a in TrackingAct.values) a: <String>{},
    };
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final String? raw = prefs.getString(key) ?? prefs.getString(legacyKey);
      if (raw == null) return out;
      final Object? j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return out;
      for (final TrackingAct a in TrackingAct.values) {
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
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(
        key,
        jsonEncode(<String, List<String>>{
          for (final MapEntry<TrackingAct, Set<String>> e in state.entries)
            e.key.name: (e.value.toList()..sort()),
        }),
      );
      await prefs.remove(legacyKey);
    } catch (_) {}
  }

  /// Notes that [act] happened today (or [now]).
  Future<void> record(TrackingAct act, {DateTime? now}) async {
    final DateTime d = now ?? DateTime.now();
    final String stamp = TrackingMath.stamp(d);
    final Set<String> have = state[act] ?? <String>{};
    if (have.contains(stamp)) return;
    final String oldest = TrackingMath.stamp(
      DateTime(d.year, d.month, d.day - keepDays),
    );
    state = <TrackingAct, Set<String>>{
      ...state,
      act: <String>{...have.where((String s) => s.compareTo(oldest) >= 0), stamp},
    };
    await _save();
  }

  /// Forgets every stored day (switching the log off, or "Erase").
  Future<void> clear() async {
    state = <TrackingAct, Set<String>>{
      for (final TrackingAct a in TrackingAct.values) a: <String>{},
    };
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove(key);
      await prefs.remove(legacyKey);
    } catch (_) {}
  }
}

final NotifierProvider<TrackingStore, Map<TrackingAct, Set<String>>>
trackingStoreProvider =
    NotifierProvider<TrackingStore, Map<TrackingAct, Set<String>>>(
      TrackingStore.new,
    );

/// One log, ready to draw: how much was logged on each day.
class TrackingView {
  const TrackingView({
    required this.track,
    required this.perDay,
    required this.today,
  });

  final TrackingTrack track;

  /// `yyyy-mm-dd` -> how many were logged that day (always at least 1).
  final Map<String, int> perDay;
  final DateTime today;

  Set<String> get days => perDay.keys.toSet();

  bool isLogged(DateTime d) => perDay.containsKey(TrackingMath.stamp(d));

  /// The plain total for [p]: prayers for the prayers log, days for the rest.
  /// It only adds up what is inside the period; days outside it, or empty
  /// days, change nothing.
  int total(LogPeriod p) {
    final DateTime? from = TrackingMath.periodStart(p, today);
    final String last = TrackingMath.stamp(today);
    final String? lo = from == null ? null : TrackingMath.stamp(from);
    int sum = 0;
    for (final MapEntry<String, int> e in perDay.entries) {
      if (e.key.compareTo(last) > 0) continue;
      if (lo != null && e.key.compareTo(lo) < 0) continue;
      sum += e.value;
    }
    return sum;
  }

  /// Days with something logged in the month of [month].
  int daysInMonth(DateTime month) {
    final String prefix = TrackingMath.stamp(
      DateTime(month.year, month.month, 1),
    ).substring(0, 8);
    return perDay.keys.where((String s) => s.startsWith(prefix)).length;
  }

  /// The last day something was logged, or null.
  DateTime? get lastLogged => TrackingMath.lastLogged(days, today);
}

/// Days from the prayer log with how many prayers were marked prayed (on time
/// or late). Missed and excused marks add nothing and are never shown.
Map<String, int> prayerCounts(PrayerLogState log) {
  final Map<String, int> out = <String, int>{};
  for (final MapEntry<String, Map<String, PrayerMark>> e in log.days.entries) {
    final int n = e.value.values
        .where(
          (PrayerMark m) =>
              m == PrayerMark.prayed || m == PrayerMark.prayedLate,
        )
        .length;
    if (n > 0) out[e.key] = n;
  }
  return out;
}

Map<String, int> _ones(Iterable<String> days) => <String, int>{
  for (final String s in days) s: 1,
};

/// Days the learner finished an Academy lesson or answered a review (which
/// is also how Hifz revision and lessons in the Review Queue are logged).
/// The Academy keeps these on this device whatever the switch says.
Set<String> _academyDays(Ref ref) {
  try {
    return ActivityLog.decode(
      ref.watch(sharedPreferencesProvider).getString(ActivityLog.prefKey),
    );
  } catch (_) {
    return <String>{};
  }
}

final ProviderFamily<TrackingView, TrackingTrack> trackingViewProvider =
    Provider.family<TrackingView, TrackingTrack>((
      Ref ref,
      TrackingTrack track,
    ) {
      final DateTime now = DateTime.now();
      final Map<TrackingAct, Set<String>> store = ref.watch(
        trackingStoreProvider,
      );
      Map<String, int> perDay;
      switch (track) {
        case TrackingTrack.quran:
          perDay = _ones(store[TrackingAct.quran] ?? <String>{});
        case TrackingTrack.dhikr:
          perDay = _ones(store[TrackingAct.dhikr] ?? <String>{});
        case TrackingTrack.lessons:
          perDay = _ones(<String>{
            ...?store[TrackingAct.lesson],
            ..._academyDays(ref),
          });
        case TrackingTrack.prayers:
          perDay = prayerCounts(ref.watch(prayerLogProvider));
        case TrackingTrack.fasting:
          perDay = _ones(ref.watch(fastingLogProvider));
        case TrackingTrack.all:
          perDay = _ones(<String>{
            for (final Set<String> s in store.values) ...s,
            ..._academyDays(ref),
            ...prayerCounts(ref.watch(prayerLogProvider)).keys,
            ...ref.watch(fastingLogProvider),
          });
      }
      return TrackingView(
        track: track,
        perDay: perDay,
        today: DateTime(now.year, now.month, now.day),
      );
    });

/// The warm line for this person, from every day they logged anything.
final Provider<Encouragement> encouragementProvider = Provider<Encouragement>((
  Ref ref,
) {
  final TrackingView all = ref.watch(trackingViewProvider(TrackingTrack.all));
  return EncouragementMath.forDays(all.days, DateTime.now());
});
