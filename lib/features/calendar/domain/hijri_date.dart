/// Hijri (Islamic) calendar — Umm al-Qura official calendar (data-driven,
/// van Gent port via the `hijri` package) with a tabular civil (Kuwaiti)
/// fallback for dates outside the Umm al-Qura data range (~1356–1500 AH).
/// Fully offline. Converts between Gregorian and Hijri, exposes month
/// metadata and the year's major observances.
///
/// NOTE (honesty): even official-calendar dates can differ ±1 day from
/// local moon sighting in some countries. The app keeps an honesty note —
/// a moon-sighting data source can refine this later without design changes.
library;

import 'package:hijri/hijri_calendar.dart';

/// A date in the Hijri calendar.
class HijriDate {
  const HijriDate(this.year, this.month, this.day);

  final int year;

  /// 1 = Muharram … 12 = Dhul-Hijjah.
  final int month;

  /// 1-based day of month.
  final int day;

  static const List<String> monthNamesEn = <String>[
    'Muharram',
    'Safar',
    'Rabiʿ al-Awwal',
    'Rabiʿ al-Thani',
    'Jumada al-Ula',
    'Jumada al-Akhirah',
    'Rajab',
    'Shaʿban',
    'Ramadan',
    'Shawwal',
    'Dhul-Qaʿdah',
    'Dhul-Hijjah',
  ];

  static const List<String> monthNamesAr = <String>[
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  String get monthNameEn => monthNamesEn[month - 1];
  String get monthNameAr => monthNamesAr[month - 1];

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'HijriDate($year, $month, $day)';

  /// '12 Ramadan 1447'
  String format() => '$day ${monthNamesEn[month - 1]} $year';

  // ---------------------------------------------------------------------------
  // Conversion (Julian-day based; civil epoch 1 Muharram 1 AH = JD 1948440).

  /// Julian Day Number for a Gregorian date (Fliegel–Van Flandern).
  static int gregorianToJd(int y, int m, int d) {
    return (1461 * (y + 4800 + (m - 14) ~/ 12)) ~/ 4 +
        (367 * (m - 2 - 12 * ((m - 14) ~/ 12))) ~/ 12 -
        (3 * ((y + 4900 + (m - 14) ~/ 12) ~/ 100)) ~/ 4 +
        d -
        32075;
  }

  /// Gregorian (year, month, day) for a Julian Day Number.
  static (int, int, int) jdToGregorian(int jd) {
    int l = jd + 68569;
    final int n = (4 * l) ~/ 146097;
    l = l - (146097 * n + 3) ~/ 4;
    final int i = (4000 * (l + 1)) ~/ 1461001;
    l = l - (1461 * i) ~/ 4 + 31;
    final int j = (80 * l) ~/ 2447;
    final int d = l - (2447 * j) ~/ 80;
    l = j ~/ 11;
    final int m = j + 2 - 12 * l;
    final int y = 100 * (n - 49) + i + l;
    return (y, m, d);
  }

  /// Julian Day Number for a Hijri date (civil/tabular).
  static int hijriToJd(int y, int m, int d) {
    return 1948440 +
        354 * (y - 1) +
        ((3 + 11 * y) ~/ 30) +
        30 * (m - 1) -
        ((m - 1) ~/ 2) +
        (d - 1);
  }

  /// True when [year] is inside the Umm al-Qura data range (~1356–1500 AH),
  /// where official-calendar data drives conversion.
  static bool inUmmAlQuraRange(int year) => year >= 1356 && year <= 1500;

  /// Tabular (Kuwaiti) conversion — fallback outside the Umm al-Qura range.
  static HijriDate _fromGregorianTabular(DateTime date) {
    final int jd = gregorianToJd(date.year, date.month, date.day);
    int l = jd - 1948440 + 10632;
    final int n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final int j =
        ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l =
        l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final int m = (24 * l) ~/ 709;
    final int d = l - (709 * m) ~/ 24;
    final int y = 30 * n + j - 30;
    return HijriDate(y, m, d);
  }

  /// Hijri date for a Gregorian date — Umm al-Qura official calendar where
  /// in range, tabular civil fallback otherwise.
  static HijriDate fromGregorian(DateTime date) {
    final HijriDate guess = _fromGregorianTabular(date);
    if (!inUmmAlQuraRange(guess.year)) return guess;
    try {
      final HijriCalendar h = HijriCalendar.fromDate(date);
      return HijriDate(h.hYear, h.hMonth, h.hDay);
    } catch (_) {
      return guess;
    }
  }

  /// Gregorian date for this Hijri date (midnight local) — Umm al-Qura
  /// official calendar where in range, tabular civil fallback otherwise.
  DateTime toGregorian() {
    if (inUmmAlQuraRange(year)) {
      try {
        final DateTime g = HijriCalendar().hijriToGregorian(year, month, day);
        return DateTime(g.year, g.month, g.day);
      } catch (_) {
        // Fall through to tabular.
      }
    }
    final (int y, int m, int d) = jdToGregorian(hijriToJd(year, month, day));
    return DateTime(y, m, d);
  }

  // ---------------------------------------------------------------------------
  // Month / year metadata.

  /// Leap years in the 30-year tabular cycle (month 12 has 30 days).
  static bool isLeapYear(int year) => ((11 * year + 14) % 30) < 11;

  static int monthLength(int year, int month) {
    if (inUmmAlQuraRange(year)) {
      try {
        return HijriCalendar().getDaysInMonth(year, month);
      } catch (_) {
        // Fall through to tabular.
      }
    }
    if (month == 12) return isLeapYear(year) ? 30 : 29;
    return month.isOdd ? 30 : 29;
  }

  int get daysInMonth => monthLength(year, month);

  /// Weekday column (0 = Monday … 6 = Sunday) of the 1st of this month.
  int get firstWeekday =>
      HijriDate(year, month, 1).toGregorian().weekday - 1;

  HijriDate get firstOfMonth => HijriDate(year, month, 1);

  /// The Hijri date [days] days after this one.
  HijriDate addDays(int days) {
    return fromGregorian(
      toGregorian().add(Duration(days: days)),
    );
  }
}

/// A major observance in the Islamic year.
class Observance {
  const Observance(this.month, this.day, this.nameEn, this.nameAr);

  final int month;
  final int day;
  final String nameEn;
  final String nameAr;

  HijriDate inYear(int hijriYear) => HijriDate(hijriYear, month, day);
}

/// The year's major observances (static religious data).
abstract final class Observances {
  static const List<Observance> all = <Observance>[
    Observance(1, 1, 'Islamic New Year', 'رأس السنة الهجرية'),
    Observance(1, 10, 'Day of Ashura', 'يوم عاشوراء'),
    Observance(3, 12, 'Mawlid an-Nabi ﷺ', 'المولد النبوي'),
    Observance(7, 27, 'Isra’ & Mi’raj', 'الإسراء والمعراج'),
    Observance(8, 15, 'Laylat al-Bara’ah', 'ليلة البراءة'),
    Observance(9, 1, 'Ramadan Begins', 'بداية رمضان'),
    Observance(9, 27, 'Laylat al-Qadr', 'ليلة القدر'),
    Observance(10, 1, 'Eid al-Fitr', 'عيد الفطر'),
    Observance(12, 9, 'Day of Arafah', 'يوم عرفة'),
    Observance(12, 10, 'Eid al-Adha', 'عيد الأضحى'),
  ];

  /// Upcoming observances from [today] (Gregorian), soonest first, within the
  /// next 12 lunar months. Each entry pairs the observance with its Hijri
  /// date in the correct year.
  static List<(Observance, HijriDate)> upcoming(DateTime today) {
    final HijriDate now = HijriDate.fromGregorian(today);
    final DateTime todayG = DateTime(today.year, today.month, today.day);
    final List<(Observance, HijriDate)> result = <(Observance, HijriDate)>[];
    for (final Observance o in all) {
      for (int y = now.year; y <= now.year + 1; y++) {
        final HijriDate date = o.inYear(y);
        if (!date.toGregorian().isBefore(todayG)) {
          result.add((o, date));
          break;
        }
      }
    }
    result.sort(
      (a, b) => a.$2.toGregorian().compareTo(b.$2.toGregorian()),
    );
    return result;
  }
}
