/// Hawl — the lunar year a person's wealth must stay at or above nisab
/// before zakat falls due. This tracks ONE date the user gives (the day their
/// wealth first reached nisab) and tells them, on the Hijri calendar, when
/// the year completes. It does not watch their balance: scholars differ on
/// whether the year restarts if wealth dips below nisab mid-year, so that
/// judgement stays with the user and their scholar. The calendar it counts on
/// is the one the user chose (see `HijriDate.config`).
library;

import '../../calendar/domain/hijri_date.dart';

/// Where a hawl stands on a given day.
class HawlStatus {
  const HawlStatus({
    required this.start,
    required this.startHijri,
    required this.dueHijri,
    required this.dueDate,
    required this.daysLeft,
  });

  /// The Gregorian day the user marked as the start.
  final DateTime start;
  final HijriDate startHijri;

  /// The same Hijri day one lunar year later.
  final HijriDate dueHijri;

  /// [dueHijri] as a Gregorian date (midnight, local).
  final DateTime dueDate;

  /// Whole days from today to [dueDate]; zero or negative once complete.
  final int daysLeft;

  bool get isComplete => daysLeft <= 0;
}

abstract final class HawlTracker {
  /// Status of a hawl that began on [start], as of [today]. Both are reduced
  /// to calendar dates, so the time of day never matters.
  static HawlStatus status(DateTime start, DateTime today) {
    final DateTime s = DateTime(start.year, start.month, start.day);
    final DateTime t = DateTime(today.year, today.month, today.day);
    final HijriDate startHijri = HijriDate.fromGregorian(s);
    final int dueYear = startHijri.year + 1;
    final int maxDay = HijriDate.monthLength(dueYear, startHijri.month);
    final HijriDate dueHijri = HijriDate(
      dueYear,
      startHijri.month,
      startHijri.day > maxDay ? maxDay : startHijri.day,
    );
    final DateTime due = dueHijri.toGregorian();
    final int daysLeft =
        HijriDate.gregorianToJd(due.year, due.month, due.day) -
        HijriDate.gregorianToJd(t.year, t.month, t.day);
    return HawlStatus(
      start: s,
      startHijri: startHijri,
      dueHijri: dueHijri,
      dueDate: due,
      daysLeft: daysLeft,
    );
  }
}
