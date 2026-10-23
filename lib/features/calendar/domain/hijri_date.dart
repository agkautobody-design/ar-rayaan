/// Hijri (Islamic) calendar — Umm al-Qura official calendar (data-driven,
/// van Gent port via the `hijri` package) with a tabular civil (Kuwaiti)
/// fallback for dates outside the Umm al-Qura data range (~1356–1500 AH).
/// Fully offline. Converts between Gregorian and Hijri, exposes month
/// metadata and the year's major observances.
///
/// NOTE (honesty): even official-calendar dates can differ ±1 day from
/// local moon sighting in some countries. The user can therefore pick the
/// calendar BASIS and shift every date by whole days (see [HijriConfig]);
/// every consumer (calendar, Ramadan, hawl, fasting markers) reads the same
/// setting through [HijriDate.config], so they can never disagree.
library;

import 'package:hijri/hijri_calendar.dart';

/// Which calendar the dates are computed from.
enum HijriBasis {
  /// The official Umm al-Qura calendar of Saudi Arabia (data table for
  /// 1356-1500 AH, from the `hijri` package, a port of the van Gent tables).
  ummAlQura,

  /// The arithmetic "civil" tabular calendar (Kuwaiti algorithm): 30-year
  /// cycle, odd months 30 days, even months 29. It does not observe the moon
  /// at all, so it can differ from every sighting-based calendar by a day or
  /// two; it is offered because some communities and tools use it.
  tabular,
}

/// The user's calendar choice: a [basis] plus a whole-day shift.
///
/// A positive [adjustDays] makes every Hijri date LATER (the Hijri date shown
/// for a given day moves forward), the usual way to follow a country whose
/// announced month began a day before the calculated one. A uniform shift is
/// only an approximation of month-by-month announcements; it is the same
/// control other prayer apps offer.
class HijriConfig {
  const HijriConfig({this.basis = HijriBasis.ummAlQura, this.adjustDays = 0});

  final HijriBasis basis;

  /// -2 to +2.
  final int adjustDays;

  static const int maxAdjust = 2;

  HijriConfig copyWith({HijriBasis? basis, int? adjustDays}) => HijriConfig(
    basis: basis ?? this.basis,
    adjustDays: (adjustDays ?? this.adjustDays)
        .clamp(-maxAdjust, maxAdjust)
        .toInt(),
  );

  @override
  bool operator ==(Object other) =>
      other is HijriConfig &&
      other.basis == basis &&
      other.adjustDays == adjustDays;

  @override
  int get hashCode => Object.hash(basis, adjustDays);
}

/// A date in the Hijri calendar.
class HijriDate {
  const HijriDate(this.year, this.month, this.day);

  /// The calendar every conversion uses. Set once at start-up from the saved
  /// choice and again whenever the user changes it (see `hijriSettingsProvider`).
  static HijriConfig config = const HijriConfig();

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

  /// Whether the Umm al-Qura table is the active source for [year].
  static bool _useUmmAlQura(int year) =>
      config.basis == HijriBasis.ummAlQura && inUmmAlQuraRange(year);

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

  /// Hijri date for a Gregorian date under the active [config]: the chosen
  /// basis, shifted by the chosen number of days.
  static HijriDate fromGregorian(DateTime date) {
    final DateTime shifted = DateTime(
      date.year,
      date.month,
      date.day + config.adjustDays,
    );
    final HijriDate guess = _fromGregorianTabular(shifted);
    if (config.basis == HijriBasis.tabular || !inUmmAlQuraRange(guess.year)) {
      return guess;
    }
    try {
      final HijriCalendar h = HijriCalendar.fromDate(shifted);
      return HijriDate(h.hYear, h.hMonth, h.hDay);
    } catch (_) {
      return guess;
    }
  }

  /// Gregorian date for this Hijri date (midnight local) under the active
  /// [config] (the inverse of [fromGregorian]).
  DateTime toGregorian() {
    DateTime base;
    if (_useUmmAlQura(year)) {
      try {
        final DateTime g = HijriCalendar().hijriToGregorian(year, month, day);
        base = DateTime(g.year, g.month, g.day);
      } catch (_) {
        base = _tabularToGregorian();
      }
    } else {
      base = _tabularToGregorian();
    }
    return DateTime(base.year, base.month, base.day - config.adjustDays);
  }

  /// First and last Hijri year the date converter offers (the Umm al-Qura
  /// table, 1356-1500 AH, which is also the Gregorian date picker's span).
  static const int converterMinYear = 1356;
  static const int converterMaxYear = 1500;

  /// Gregorian date for a typed Hijri date, under the active [config] (the
  /// same calendar every screen uses), or null when the date does not exist:
  /// a month outside 1-12, a day beyond the month's length, or a year outside
  /// [converterMinYear]-[converterMaxYear].
  static DateTime? gregorianFromHijri(int year, int month, int day) {
    if (year < converterMinYear || year > converterMaxYear) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > monthLength(year, month)) return null;
    return HijriDate(year, month, day).toGregorian();
  }

  DateTime _tabularToGregorian() {
    final (int y, int m, int d) = jdToGregorian(hijriToJd(year, month, day));
    return DateTime(y, m, d);
  }

  // ---------------------------------------------------------------------------
  // Month / year metadata.

  /// Leap years in the 30-year tabular cycle (month 12 has 30 days).
  static bool isLeapYear(int year) => ((11 * year + 14) % 30) < 11;

  static int monthLength(int year, int month) {
    if (_useUmmAlQura(year)) {
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

/// How firmly an observance rests on the Qur'an and authentic sunnah. Shown
/// on screen so the app never presents a disputed practice as settled.
enum ObservanceBasis {
  /// Rests on the Qur'an or an authentic report.
  established('Established in the Qur\u2019an and sunnah'),

  /// The event is established but the date is a popular reckoning, not a
  /// reported one.
  dateUncertain('The event is established; the date is a popular reckoning'),

  /// Scholars differ on whether marking it is part of the religion.
  contested('Scholars differ on observing this day'),

  /// A calendar marker with no prescribed act.
  calendar('A calendar marker; no act of worship is prescribed for the day');

  const ObservanceBasis(this.label);

  final String label;
}

/// A major observance in the Islamic year.
class Observance {
  const Observance(
    this.month,
    this.day,
    this.nameEn,
    this.nameAr, {
    this.basis = ObservanceBasis.established,
    this.about = '',
    this.source = '',
  });

  final int month;
  final int day;
  final String nameEn;
  final String nameAr;

  /// How firmly the observance is established (see [ObservanceBasis]).
  final ObservanceBasis basis;

  /// What the day is and how people meet it, in plain words.
  final String about;

  /// Source line (collection and number, or Qur'an reference).
  final String source;

  HijriDate inYear(int hijriYear) => HijriDate(hijriYear, month, day);
}

/// The year's major observances (static religious data).
///
/// Texts were checked against sunnah.com / quran.com; where a date or a
/// practice is disputed the entry says so instead of presenting it as fixed.
abstract final class Observances {
  static const List<Observance> all = <Observance>[
    Observance(
      1,
      1,
      'Islamic New Year',
      'رأس السنة الهجرية',
      basis: ObservanceBasis.calendar,
      about:
          'The first day of Muharram, the first month of the Hijri year. The '
          'Hijri calendar counts years from the Prophet\u2019s \ufdfa migration to '
          'Madinah. No special act is prescribed for the day itself; Muharram '
          'is a sacred month, and the Prophet \ufdfa called fasting in it the best '
          'fasting after Ramadan.',
      source: 'Sahih Muslim 1163',
    ),
    Observance(
      1,
      10,
      'Day of Ashura',
      'يوم عاشوراء',
      about:
          'The Prophet \ufdfa fasted the 10th of Muharram and told the Muslims to '
          'fast it; he intended to add the 9th as well. Fasting it expiates '
          'the sins of the previous year.',
      source: 'Sahih al-Bukhari 2004 · Sahih Muslim 1134, 1162',
    ),
    Observance(
      3,
      12,
      'Mawlid an-Nabi \ufdfa',
      'المولد النبوي',
      basis: ObservanceBasis.contested,
      about:
          '12 Rabi\u02bf al-Awwal is the popular date for the birth of the '
          'Prophet \ufdfa; the exact day is itself reported differently. Many '
          'Muslims mark it with remembrance and salawat, while other scholars '
          'hold that marking a birthday is not part of the religion. Love of '
          'the Prophet \ufdfa is shown in following his sunnah and sending '
          'salawat on him, which are encouraged every day.',
    ),
    Observance(
      7,
      27,
      'Isra\u2019 & Mi\u2019raj',
      'الإسراء والمعراج',
      basis: ObservanceBasis.dateUncertain,
      about:
          'The Night Journey from Makkah to al-Aqsa is in the Qur\u2019an. The '
          'date is not fixed by an authentic report; 27 Rajab is the popular '
          'reckoning, and scholars differ on whether to mark it. The gift of '
          'the night was the five daily prayers.',
      source: 'Qur\u2019an 17:1 \u00b7 Sahih al-Bukhari 349',
    ),
    Observance(
      8,
      15,
      'Laylat al-Bara\u2019ah',
      'ليلة البراءة',
      basis: ObservanceBasis.contested,
      about:
          'The night of 15 Sha\u2018ban is marked in some regions with night '
          'prayer and fasting the next day. Scholars differ on whether '
          'singling it out has an authentic basis, so this app does not '
          'recommend a special practice for it. Fasting the White Days '
          '(13\u201315) of every month is established.',
    ),
    Observance(
      9,
      1,
      'Ramadan Begins',
      'بداية رمضان',
      about:
          'The month of fasting. \u201cWhoever of you witnesses the month, let '
          'him fast it.\u201d The month begins with the sighting of the new '
          'moon; this app shows the Umm al-Qura calendar date, so confirm by '
          'your local sighting.',
      source: 'Qur\u2019an 2:185',
    ),
    Observance(
      9,
      27,
      'Laylat al-Qadr',
      'ليلة القدر',
      basis: ObservanceBasis.dateUncertain,
      about:
          'The Night of Decree, better than a thousand months. Its exact night '
          'is not known: the Prophet \ufdfa told us to seek it in the odd nights of '
          'the last ten nights of Ramadan. 27 Ramadan is the popular guess and '
          'is shown here only as a reminder to seek it on all of them.',
      source: 'Qur\u2019an 97:1\u20133 \u00b7 Sahih al-Bukhari 2017',
    ),
    Observance(
      10,
      1,
      'Eid al-Fitr',
      'عيد الفطر',
      about:
          'The festival that ends Ramadan: the Eid prayer, charity (zakat '
          'al-fitr) given before the prayer, and food and family. Fasting on '
          'this day is prohibited.',
      source:
          'Sahih al-Bukhari 1503, 1991 · Sahih Muslim 1137',
    ),
    Observance(
      12,
      9,
      'Day of Arafah',
      'يوم عرفة',
      about:
          'The day the pilgrims stand at Arafah. For those not on Hajj, '
          'fasting it expiates the sins of the previous and the coming year.',
      source: 'Sahih Muslim 1162',
    ),
    Observance(
      12,
      10,
      'Eid al-Adha',
      'عيد الأضحى',
      about:
          'The festival of sacrifice on 10 Dhul-Hijjah: the Eid prayer, then '
          'the sacrifice and sharing its meat. Fasting on this day, and on '
          'the three days of Tashreeq after it, is prohibited.',
      source: 'Sahih al-Bukhari 1991 · Sahih Muslim 1137, 1141',
    ),
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
