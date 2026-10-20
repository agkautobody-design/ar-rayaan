import '../../calendar/domain/hijri_date.dart';

/// One Ramadan, from the app's own Umm al-Qura calendar — never a
/// hard-coded date. All per-season data (fasting log, juz, notes, sadaqah)
/// is keyed by [hijriYear], so a new Ramadan starts with a clean slate.
class RamadanSeason {
  const RamadanSeason({
    required this.hijriYear,
    required this.start,
    required this.end,
    required this.length,
  });

  /// Hijri year of this Ramadan (for example 1448).
  final int hijriYear;

  /// Gregorian date of 1 Ramadan (midnight, local).
  final DateTime start;

  /// Gregorian date of 1 Shawwal, the day after the last fast (Eid).
  final DateTime end;

  /// Number of days in this Ramadan (29 or 30).
  final int length;

  /// The current Ramadan while it is running, otherwise the next one.
  static RamadanSeason forDate(DateTime today) {
    final HijriDate h = HijriDate.fromGregorian(today);
    final int year = h.month <= 9 ? h.year : h.year + 1;
    final DateTime start = HijriDate(year, 9, 1).toGregorian();
    final DateTime end = HijriDate(year, 10, 1).toGregorian();
    return RamadanSeason(
      hijriYear: year,
      start: start,
      end: end,
      length: HijriDate.monthLength(year, 9),
    );
  }

  static int _jd(DateTime d) =>
      HijriDate.gregorianToJd(d.year, d.month, d.day);

  /// True while [today] falls inside Ramadan.
  bool contains(DateTime today) =>
      _jd(today) >= _jd(start) && _jd(today) < _jd(end);

  /// 1-based day of Ramadan for [today] (meaningful when [contains]).
  int dayOf(DateTime today) => _jd(today) - _jd(start) + 1;

  /// Whole days from [today] until 1 Ramadan (zero or negative once begun).
  int daysUntilStart(DateTime today) => _jd(start) - _jd(today);

  /// SharedPreferences key for one kind of data in this season.
  String key(String name) => 'ar.ramadan.$hijriYear.$name';
}
