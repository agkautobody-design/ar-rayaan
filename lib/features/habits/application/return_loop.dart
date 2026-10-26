import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../../streaks/application/streaks_providers.dart';
import 'habits_providers.dart';

/// Code-level kill switch for the whole return loop (the optional "days
/// returned" count and the quiet completion cards). Set to false and the
/// Settings switch disappears, nothing is recorded and no card appears.
/// See docs/product/return_loop.md.
const bool kReturnLoopEnabled = true;

/// The only acts that can be counted. There is deliberately NO value for the
/// five prayers or any other act of worship that is an obligation: a prayer
/// can never be recorded here, because the type has no way to say so.
enum ReturnAct { quran, adhkar, lesson }

/// Pure maths for "days returned", kept free of Flutter so it is easy to test.
///
/// A day counts when at least one [ReturnAct] happened on it. The run carries
/// on across a single missed day once per calendar week (Monday to Sunday):
/// that is the built-in grace day. A second missed day in the same week, or
/// two missed days in a row, starts a fresh run silently; nothing is ever
/// shown about what was lost.
class ReturnLoop {
  const ReturnLoop._();

  /// Fewest days worth mentioning; one day is simply "today".
  static const int minToShow = 2;

  static DateTime _parse(String s) {
    final List<String> p = s.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _before(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day - n);

  /// Key of the Monday that starts [d]'s week.
  static String _weekOf(DateTime d) {
    final DateTime monday = DateTime(d.year, d.month, d.day - (d.weekday - 1));
    return FastingLogController.stamp(monday);
  }

  /// Number of days in the current run as of [today]. Zero when the run has
  /// lapsed (more than one missed day) or there is nothing recorded.
  static int daysReturned(Set<String> days, DateTime today) {
    final DateTime now = _day(today);
    final Set<String> valid = <String>{};
    for (final String s in days) {
      try {
        valid.add(FastingLogController.stamp(_parse(s)));
      } catch (_) {}
    }
    if (valid.isEmpty) return 0;
    bool has(DateTime d) => valid.contains(FastingLogController.stamp(d));

    final Set<String> graceUsedInWeeks = <String>{};
    DateTime? cursor;
    // Start at today if done, else yesterday, else the day before (a grace).
    if (has(now)) {
      cursor = now;
    } else if (has(_before(now, 1))) {
      cursor = _before(now, 1);
    } else if (has(_before(now, 2))) {
      // Yesterday was missed: that is today's grace day.
      graceUsedInWeeks.add(_weekOf(_before(now, 1)));
      cursor = _before(now, 2);
    } else {
      return 0;
    }

    int count = 0;
    // Bounded: the store never holds more than a few hundred days.
    for (int guard = 0; guard < 4000 && cursor != null; guard++) {
      count++;
      final DateTime prev = _before(cursor, 1);
      if (has(prev)) {
        cursor = prev;
        continue;
      }
      final DateTime prev2 = _before(cursor, 2);
      if (has(prev2) && !graceUsedInWeeks.contains(_weekOf(prev))) {
        graceUsedInWeeks.add(_weekOf(prev));
        cursor = prev2;
        continue;
      }
      cursor = null;
    }
    return count;
  }

  /// Calm, positive wording. Null when there is nothing worth saying.
  static String? message(int days) {
    if (days < minToShow) return null;
    return 'You came back $days days.';
  }
}

/// The Settings switch. OFF by default; stored on this device only.
class ReturnLoopEnabledController extends Notifier<bool> {
  static const String key = 'ar.return.enabled';

  @override
  bool build() {
    if (!kReturnLoopEnabled) return false;
    try {
      return ref.watch(sharedPreferencesProvider).getBool(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> set(bool on) async {
    if (!kReturnLoopEnabled) return;
    state = on;
    try {
      await ref.read(sharedPreferencesProvider).setBool(key, on);
    } catch (_) {}
    // Turning it off forgets the days (silent reset); nothing lingers.
    if (!on) {
      await ref.read(returnDaysProvider.notifier).clear();
      await ref.read(streaksStoreProvider.notifier).clear();
    }
  }
}

final NotifierProvider<ReturnLoopEnabledController, bool>
returnLoopEnabledProvider = NotifierProvider<ReturnLoopEnabledController, bool>(
  ReturnLoopEnabledController.new,
);

/// Days on which a [ReturnAct] happened (zero-padded `yyyy-mm-dd`). Nothing
/// is stored while the switch is off.
class ReturnDaysController extends Notifier<Set<String>> {
  static const String key = 'ar.return.days';

  /// Keeps the store small: older days cannot change the count anyway.
  static const int keepDays = 400;

  @override
  Set<String> build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      return (prefs.getStringList(key) ?? <String>[]).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _save() async {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setStringList(key, state.toList()..sort());
    } catch (_) {}
  }

  /// Notes that [act] happened today. A no-op while the switch is off.
  Future<void> record(ReturnAct act, {DateTime? now}) async {
    if (!kReturnLoopEnabled) return;
    if (!ref.read(returnLoopEnabledProvider)) return;
    final DateTime d = now ?? DateTime.now();
    final String stamp = FastingLogController.stamp(d);
    if (state.contains(stamp)) return;
    final String oldest = FastingLogController.stamp(
      DateTime(d.year, d.month, d.day - keepDays),
    );
    state = <String>{
      ...state.where((String s) => s.compareTo(oldest) >= 0),
      stamp,
    };
    await _save();
  }

  Future<void> clear() async {
    state = <String>{};
    try {
      await ref.read(sharedPreferencesProvider).remove(key);
    } catch (_) {}
  }
}

final NotifierProvider<ReturnDaysController, Set<String>> returnDaysProvider =
    NotifierProvider<ReturnDaysController, Set<String>>(
      ReturnDaysController.new,
    );

/// The sentence to show, or null (switch off, or fewer than two days).
final Provider<String?> returnMessageProvider = Provider<String?>((Ref ref) {
  if (!ref.watch(returnLoopEnabledProvider)) return null;
  return ReturnLoop.message(
    ReturnLoop.daysReturned(ref.watch(returnDaysProvider), DateTime.now()),
  );
});

/// Fire-and-forget hook for the three screens. Never throws (a bare test
/// container has no preferences).
Future<void> noteReturn(WidgetRef ref, ReturnAct act) async {
  try {
    await ref.read(returnDaysProvider.notifier).record(act);
  } catch (_) {}
  await noteStreak(ref, switch (act) {
    ReturnAct.quran => StreakAct.quran,
    ReturnAct.adhkar => StreakAct.dhikr,
    ReturnAct.lesson => StreakAct.lesson,
  });
}

/// Records [act] for the streaks (Qur'an, dhikr, lessons). A no-op while
/// "Keep my streaks" is off. Never throws.
Future<void> noteStreak(WidgetRef ref, StreakAct act) async {
  try {
    if (!kReturnLoopEnabled) return;
    if (!ref.read(returnLoopEnabledProvider)) return;
    await ref.read(streaksStoreProvider.notifier).record(act);
  } catch (_) {}
}
