/// Lamha (لمحة — "a glance, a moment") — the Sunnah Engine (Wave A2).
///
/// The constitution (locked):
/// - Never overwhelming: at most 2 moments per week, ever.
/// - Sources on screen, always.
/// - Gentle — a lamha is a glance, not a lecture; dismissible, on-device.
/// - Seasonal specials override the rotation in their week.
///
/// v1 surfaces the moment in-app (Home "Today for You"); OS notifications
/// ship with the native builds, honoring this same scheduler.
library;

import '../../calendar/domain/hijri_date.dart';

/// A single gentle moment.
class LamhaMoment {
  const LamhaMoment({
    required this.id,
    required this.title,
    required this.body,
    required this.source,
  });

  final String id;
  final String title;
  final String body;
  final String source;
}

/// Weekly moments (keyed by Gregorian weekday).
abstract final class _Weekly {
  static const LamhaMoment friday = LamhaMoment(
    id: 'friday',
    title: 'It’s Jumu’ah',
    body:
        'The best day the sun rises upon. Today: read Surah al-Kahf, send '
        'many salawat upon the Prophet ﷺ, and catch the hour in which dua '
        'is answered.',
    source: 'Sahih al-Bukhari 893 · Sahih Muslim 854 · Abu Dawud 1048',
  );

  static const LamhaMoment monday = LamhaMoment(
    id: 'monday',
    title: 'A Sunnah fast today',
    body:
        'The Prophet ﷺ fasted Mondays — the day he was born and the day '
        'revelation first came down. If you can, fast with him today.',
    source: 'Sahih Muslim 1162',
  );

  static const LamhaMoment thursday = LamhaMoment(
    id: 'thursday',
    title: 'A Sunnah fast today',
    body:
        'Deeds are presented to Allah on Mondays and Thursdays — the '
        'Prophet ﷺ loved his to be presented while he was fasting.',
    source: 'Jamiʿ at-Tirmidhi 747',
  );

  static const LamhaMoment sunday = LamhaMoment(
    id: 'sunday-evening',
    title: 'Tonight: two rak’ah before sleep',
    body:
        'The Prophet ﷺ would not sleep until he recited Al-Mulk — it '
        'intercedes for its companion in the grave.',
    source: 'Jamiʿ at-Tirmidhi 2891 — hasan',
  );

  static const LamhaMoment wednesday = LamhaMoment(
    id: 'wednesday',
    title: 'A quiet istighfar',
    body:
        'The Prophet ﷺ — forgiven entirely — still sought forgiveness more '
        'than seventy times a day. One quiet istighfar now, for the road.',
    source: 'Sahih al-Bukhari 6307',
  );
}

/// The rotating library of midweek moments (cycled weekly, deterministic).
abstract final class _Rotation {
  static const List<LamhaMoment> all = <LamhaMoment>[
    LamhaMoment(
      id: 'home-dua',
      title: 'When you arrive home',
      body:
          'Entering with Bismillah and the home dua brings blessing and '
          'keeps Shaytan out: “Bismillahi walajna, wa bismillahi kharajna, '
          'wa ’ala Rabbina tawakkalna.”',
      source: 'Sunan Abi Dawud 5096 — sahih',
    ),
    LamhaMoment(
      id: 'sleep-dua',
      title: 'Before you sleep tonight',
      body:
          '“Bismika Allahumma amutu wa ahya” — in Your name, O Allah, I die '
          'and I live. Sleep is the lesser death; hand it to Him.',
      source: 'Sahih al-Bukhari 6324',
    ),
    LamhaMoment(
      id: 'morning-dua',
      title: 'When you wake',
      body:
          '“Alhamdu lillahil-ladhi ahyana ba’da ma amatana wa ilayhin-'
          'nushur” — every morning is a small resurrection, and a second '
          'chance.',
      source: 'Sahih al-Bukhari 6312',
    ),
    LamhaMoment(
      id: 'eating-sunnah',
      title: 'At your next meal',
      body:
          'Bismillah before, eat with the right hand, eat from what is '
          'nearest — three small sunnahs that turn bread into worship.',
      source: 'Sahih Muslim 2022 — excerpt',
    ),
    LamhaMoment(
      id: 'tahajjud',
      title: 'The last third of the night',
      body:
          'Allah descends and asks: “Who calls upon Me that I may answer? '
          'Who asks of Me that I may give?” Even one rak’ah at that hour is '
          'heard.',
      source: 'Sahih al-Bukhari 1145 — excerpt',
    ),
    LamhaMoment(
      id: 'salawat',
      title: 'One salawat, ten returned',
      body:
          '“Whoever sends one blessing upon me, Allah sends ten blessings '
          'upon him.” The highest-return transaction you will ever make '
          'takes three seconds.',
      source: 'Sahih Muslim 407',
    ),
    LamhaMoment(
      id: 'parents',
      title: 'A call to your parents',
      body:
          'Paradise lies at the feet of mothers, and a father is the middle '
          'gate of Paradise. If they are alive, one call today is a door '
          'held open for you.',
      source: 'Sunan an-Nasa’i 3106 · Sunan Ibn Majah 3663 — sahih',
    ),
    LamhaMoment(
      id: 'mosque-walk',
      title: 'The walk to the masjid',
      body:
          'Every step to the mosque erases a sin, raises a rank, and writes '
          'a good deed. The light on the Day of Judgment is earned one '
          'step at a time.',
      source: 'Sahih al-Bukhari 657 · Abu Dawud 561 — meaning',
    ),
  ];
}

/// Seasonal specials — they override the rotation during their window.
abstract final class _Seasonal {
  static LamhaMoment? forDate(HijriDate h) {
    // White Days eve (12th of each month): tomorrow begins the White Days.
    if (h.day == 12) {
      return const LamhaMoment(
        id: 'white-days-eve',
        title: 'Tomorrow the White Days begin',
        body:
            'The 13th, 14th and 15th — the nights of the full moon — the '
            'Prophet ﷺ fasted them, and said three days of each month is '
            'like fasting a lifetime.',
        source: 'Sunan an-Nasa’i 2420 · Sahih al-Bukhari 1979',
      );
    }
    // Ashura week (9–10 Muharram).
    if (h.month == 1 && h.day == 9) {
      return const LamhaMoment(
        id: 'ashura',
        title: 'Ashura is upon us',
        body:
            'Fast the 9th with the 10th if you can — fasting Ashura '
            'expiates the year that passed.',
        source: 'Sahih Muslim 1162 · 1134',
      );
    }
    // Arafah (9 Dhul-Hijjah).
    if (h.month == 12 && h.day == 9) {
      return const LamhaMoment(
        id: 'arafah',
        title: 'The Day of Arafah',
        body:
            'For those not on Hajj: fasting today expiates the year before '
            'and the year after. And pour out dua — it is the best day of '
            'the year for it.',
        source: 'Sahih Muslim 1162 · Jamiʿ at-Tirmidhi 3585',
      );
    }
    // First days of Ramadan.
    if (h.month == 9 && h.day == 1) {
      return const LamhaMoment(
        id: 'ramadan-1',
        title: 'Ramadan has arrived',
        body:
            'The gates of Paradise are opened, the gates of the Fire are '
            'shut, and the devils are chained. Welcome, ya Ramadan.',
        source: 'Sahih al-Bukhari 1899 — excerpt',
      );
    }
    // Eid mornings.
    if (h.month == 10 && h.day == 1) {
      return const LamhaMoment(
        id: 'eid-fitr',
        title: 'Eid Mubarak',
        body:
            'Eat before the prayer, take one road there and another home, '
            'and let the takbir fill the streets. Taqabbal Allahu minna '
            'wa minkum.',
        source: 'Sahih al-Bukhari 953 · 986',
      );
    }
    if (h.month == 12 && h.day == 10) {
      return const LamhaMoment(
        id: 'eid-adha',
        title: 'Eid al-Adha Mubarak',
        body:
            'The greatest day in the sight of Allah. Takbir, sacrifice, '
            'family — and remember: it is neither the meat nor the blood '
            'that reaches Him, but your taqwa.',
        source: 'Sunan Ibn Majah 3126 · Quran 22:37',
      );
    }
    return null;
  }
}

/// The gentle scheduler. The constitution: at most 2 default moments per
/// week — Friday's message + one rotating midweek glance — plus seasonal
/// specials in their window. Monday/Thursday fasting reminders already
/// live in the Calendar's fasting layer, so they don't consume quota here.
/// The remaining weekly anchors are opt-in (Settings, future wave).
abstract final class LamhaEngine {
  /// Today's default moment, or null on quiet days. Deterministic per date.
  static LamhaMoment? forDate(DateTime date) {
    final HijriDate h = HijriDate.fromGregorian(date);

    // 1. Seasonal specials override everything.
    final LamhaMoment? seasonal = _Seasonal.forDate(h);
    if (seasonal != null) return seasonal;

    // 2. The two default weekly slots.
    switch (date.weekday) {
      case DateTime.friday:
        return _Weekly.friday;
      case DateTime.wednesday:
        final int weekOfYear =
            date.difference(DateTime(date.year, 1, 1)).inDays ~/ 7;
        return _Rotation.all[weekOfYear % _Rotation.all.length];
      default:
        // All other days are quiet by default. Not overwhelming, by design.
        return null;
    }
  }

  /// Opt-in anchors a user may enable later (Mon/Thu fasts, Sun/Wed notes).
  static const List<LamhaMoment> optInAnchors = <LamhaMoment>[
    _Weekly.monday,
    _Weekly.thursday,
    _Weekly.sunday,
    _Weekly.wednesday,
  ];

  /// Every moment surfacing in the week containing [dateInWeek] under the
  /// default rules — used by the constitution test (never more than 2 +
  /// seasonal specials).
  static List<LamhaMoment> defaultWeek(DateTime dateInWeek) {
    final DateTime monday = dateInWeek.subtract(
      Duration(days: dateInWeek.weekday - 1),
    );
    final List<LamhaMoment> out = <LamhaMoment>[];
    for (int i = 0; i < 7; i++) {
      final LamhaMoment? m = forDate(monday.add(Duration(days: i)));
      if (m != null) out.add(m);
    }
    return out;
  }
}
