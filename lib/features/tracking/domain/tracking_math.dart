/// Pure maths for the private log, free of Flutter so it is easy to test.
///
/// The log only ever adds up what the person wrote down: how many days (or,
/// for prayers, how many prayers) fall in a period. There is no run length,
/// nothing resets because a day was empty, and an empty day is just empty
/// space on the calendar.
library;

/// A period the log can add up.
enum LogPeriod {
  /// Monday to today.
  week,

  /// The first of this month to today.
  month,

  /// Everything the log holds.
  allTime,
}

abstract final class TrackingMath {
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

  /// The day with its clock time dropped.
  static DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The Monday that starts [d]'s week.
  static DateTime weekStart(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  /// The first day of the period that ends on [today].
  static DateTime? periodStart(LogPeriod p, DateTime today) {
    switch (p) {
      case LogPeriod.week:
        return weekStart(today);
      case LogPeriod.month:
        return DateTime(today.year, today.month, 1);
      case LogPeriod.allTime:
        return null;
    }
  }

  /// Valid, normalised days up to and including [today]. Junk is dropped.
  static Set<String> clean(Iterable<String> raw, DateTime today) {
    final String last = stamp(today);
    final Set<String> out = <String>{};
    for (final String s in raw) {
      final DateTime? d = parse(s);
      if (d == null) continue;
      final String k = stamp(d);
      if (k.compareTo(last) <= 0) out.add(k);
    }
    return out;
  }

  /// How many of [days] fall inside [p] as of [today]. This is a plain total
  /// for the period: it never depends on the days around it.
  static int daysIn(Set<String> days, LogPeriod p, DateTime today) {
    final Set<String> ok = clean(days, today);
    final DateTime? from = periodStart(p, today);
    if (from == null) return ok.length;
    final String lo = stamp(from);
    return ok.where((String s) => s.compareTo(lo) >= 0).length;
  }

  /// The most recent logged day on or before [today], or null.
  static DateTime? lastLogged(Set<String> days, DateTime today) {
    final Set<String> ok = clean(days, today);
    if (ok.isEmpty) return null;
    final List<String> sorted = ok.toList()..sort();
    return parse(sorted.last);
  }

  /// The earliest logged day, or null.
  static DateTime? firstLogged(Set<String> days, DateTime today) {
    final Set<String> ok = clean(days, today);
    if (ok.isEmpty) return null;
    final List<String> sorted = ok.toList()..sort();
    return parse(sorted.first);
  }

  /// Whole calendar days from [a] to [b].
  static int daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays;
}
