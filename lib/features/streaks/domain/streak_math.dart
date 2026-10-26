/// Pure maths for gentle streaks, free of Flutter so it is easy to test.
///
/// A day counts when something was done on it. The run carries on across one
/// missed day per calendar week (Monday to Sunday): that is the built-in
/// grace day. A second missed day in the same week, or two missed days in a
/// row, quietly starts a fresh run; nothing is ever said about what was lost.
///
/// [neutral] days are days that are neither done nor missed (a prayer log day
/// that is only marked "excused"). They are skipped over: they do not count
/// towards the run and they never use up the grace day.
library;

/// The result of [StreakMath.run].
class StreakRun {
  const StreakRun({
    this.days = 0,
    this.bridged = const <String>{},
    this.graceWeeks = const <String>{},
  });

  /// Days in the current run (0 when there is no run).
  final int days;

  /// `yyyy-mm-dd` of the grace days that kept this run alive.
  final Set<String> bridged;

  /// Monday keys of the weeks whose grace day is already used by this run.
  final Set<String> graceWeeks;
}

abstract final class StreakMath {
  /// Fewest days worth mentioning; one day is simply "today".
  static const int minToShow = 2;

  /// Zero-padded `yyyy-mm-dd`, so keys sort and compare as text.
  static String stamp(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// The civil day for a stored key, or null for junk.
  static DateTime? parse(String s) {
    final List<String> p = s.split('-');
    if (p.length != 3) return null;
    final int? y = int.tryParse(p[0]);
    final int? m = int.tryParse(p[1]);
    final int? d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static DateTime _before(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day - n);

  /// Key of the Monday that starts [d]'s week.
  static String weekOf(DateTime d) =>
      stamp(DateTime(d.year, d.month, d.day - (d.weekday - 1)));

  static Set<String> _clean(Iterable<String> raw) {
    final Set<String> out = <String>{};
    for (final String s in raw) {
      final DateTime? d = parse(s);
      if (d != null) out.add(stamp(d));
    }
    return out;
  }

  /// The run that is alive as of [today].
  static StreakRun run(
    Set<String> days,
    DateTime today, {
    Set<String> neutral = const <String>{},
  }) {
    final Set<String> done = _clean(days);
    if (done.isEmpty) return const StreakRun();
    final Set<String> skip = _clean(neutral).difference(done);
    final DateTime now = DateTime(today.year, today.month, today.day);
    bool has(DateTime d) => done.contains(stamp(d));

    // The day before [d], stepping over neutral days.
    DateTime prev(DateTime d) {
      DateTime p = _before(d, 1);
      for (int i = 0; i < 400 && skip.contains(stamp(p)); i++) {
        p = _before(p, 1);
      }
      return p;
    }

    final Set<String> bridged = <String>{};
    final Set<String> graceWeeks = <String>{};
    DateTime? cursor;
    if (has(now)) {
      cursor = now;
    } else {
      final DateTime p1 = prev(now);
      if (has(p1)) {
        cursor = p1;
      } else {
        final DateTime p2 = prev(p1);
        if (!has(p2)) return const StreakRun();
        // Yesterday was missed: that is today's grace day.
        bridged.add(stamp(p1));
        graceWeeks.add(weekOf(p1));
        cursor = p2;
      }
    }

    int count = 0;
    // Bounded: the store never holds more than a few hundred days.
    for (int guard = 0; guard < 4000 && cursor != null; guard++) {
      count++;
      final DateTime p = prev(cursor);
      if (has(p)) {
        cursor = p;
        continue;
      }
      final DateTime p2 = prev(p);
      if (has(p2) && !graceWeeks.contains(weekOf(p))) {
        graceWeeks.add(weekOf(p));
        bridged.add(stamp(p));
        cursor = p2;
        continue;
      }
      cursor = null;
    }
    return StreakRun(days: count, bridged: bridged, graceWeeks: graceWeeks);
  }

  /// True while this week's grace day has not been used by the run.
  static bool graceAvailable(StreakRun run, DateTime today) =>
      !run.graceWeeks.contains(weekOf(today));

  /// Calm, positive wording. Null when there is nothing worth saying.
  static String? line(int days) {
    if (days < minToShow) return null;
    return '$days days';
  }
}
