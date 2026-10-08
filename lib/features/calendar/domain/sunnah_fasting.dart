/// Sunnah & forbidden fasting days — the calendar's fasting layer.
///
/// Pure, fully offline resolver: given a Hijri date (+ Gregorian weekday),
/// returns every fasting marker that applies, each carrying a knowledge card
/// (why the Prophet ﷺ fasted it, with the source on screen).
///
/// Authenticity rules (locked):
/// - Every marker carries its source; grades are never stripped.
/// - Weak/contested practices (e.g. singling out 15 Sha'ban for fasting)
///   are NOT given markers — the app does not promote what is not established.
/// - Forbidden days are marked so the user is *protected*, not just informed.
library;

import 'hijri_date.dart';

/// Whether a marker recommends, reminds, or prohibits fasting.
enum FastingKind {
  /// Established sunnah to fast (recommended).
  recommended,

  /// Fasting is prohibited on this day.
  forbidden,
}

/// A single fasting marker attached to a date, with its knowledge card.
class FastingMarker {
  const FastingMarker({
    required this.kind,
    required this.titleEn,
    required this.titleAr,
    required this.why,
    required this.source,
  });

  final FastingKind kind;
  final String titleEn;
  final String titleAr;

  /// The knowledge card body — why this day matters, in plain language.
  final String why;

  /// Source line shown on screen (collection + reference).
  final String source;
}

/// Resolves fasting markers for any date. All rules are static religious
/// data; the resolver is deterministic and unit-tested.
abstract final class SunnahFasting {
  static const FastingMarker _monday = FastingMarker(
    kind: FastingKind.recommended,
    titleEn: 'Monday Fast',
    titleAr: 'صيام الاثنين',
    why:
        'The Prophet ﷺ was asked about fasting on Mondays and said: "That is '
        'the day on which I was born and the day on which I was sent (with '
        'revelation)." Deeds are also presented on Mondays and Thursdays, and '
        'he ﷺ loved for his deeds to be presented while he was fasting.',
    source: 'Sahih Muslim 1162 · Jamiʿ at-Tirmidhi 747',
  );

  static const FastingMarker _thursday = FastingMarker(
    kind: FastingKind.recommended,
    titleEn: 'Thursday Fast',
    titleAr: 'صيام الخميس',
    why:
        'Deeds are presented to Allah on Mondays and Thursdays, and the '
        'Prophet ﷺ loved for his deeds to be presented while he was fasting.',
    source: 'Jamiʿ at-Tirmidhi 747 · Sahih Muslim 1162',
  );

  static const FastingMarker _whiteDays = FastingMarker(
    kind: FastingKind.recommended,
    titleEn: 'White Days (13–15)',
    titleAr: 'الأيام البيض',
    why:
        'The Prophet ﷺ advised fasting three days of every month — the 13th, '
        '14th and 15th, the nights of the full moon — and said fasting three '
        'days of each month is like fasting a lifetime.',
    source: 'Sunan an-Nasa’i 2420 · Sahih al-Bukhari 1979',
  );

  static const FastingMarker _arafah = FastingMarker(
    kind: FastingKind.recommended,
    titleEn: 'Day of Arafah (for non-pilgrims)',
    titleAr: 'يوم عرفة',
    why:
        'Fasting the Day of Arafah expiates the year before it and the year '
        'after it. (For the pilgrim standing at Arafah, the sunnah is not to '
        'fast, following the Prophet’s ﷺ example.)',
    source: 'Sahih Muslim 1162',
  );

  static const FastingMarker _ashura = FastingMarker(
    kind: FastingKind.recommended,
    titleEn: 'Day of Ashura',
    titleAr: 'يوم عاشوراء',
    why:
        'Fasting the day of Ashura expiates the previous year. When the '
        'Prophet ﷺ came to Madinah he found the Jews fasting it in gratitude '
        'for Musa عليه السلام and said: "We have more right to Musa than you." '
        'He intended to add the 9th to differ from them — so fast the 9th '
        'with the 10th when you can.',
    source: 'Sahih Muslim 1162 · Sahih al-Bukhari 2004',
  );

  static const FastingMarker _tasua = FastingMarker(
    kind: FastingKind.recommended,
    titleEn: 'Tasu’a (9th of Muharram)',
    titleAr: 'تاسوعاء',
    why:
        'The Prophet ﷺ said: "If I live until next year, I will fast the '
        'ninth (along with the tenth)." Fasting the 9th with Ashura follows '
        'his ﷺ intention to differ from the Jews.',
    source: 'Sahih Muslim 1134',
  );

  static const FastingMarker _shawwalNote = FastingMarker(
    kind: FastingKind.recommended,
    titleEn: 'Six of Shawwal',
    titleAr: 'ست من شوال',
    why:
        'Whoever fasts Ramadan then follows it with six days of Shawwal, it '
        'is as if he fasted a lifetime. These six may be fasted any days of '
        'the month, together or apart.',
    source: 'Sahih Muslim 1164',
  );

  static const FastingMarker _eidFitr = FastingMarker(
    kind: FastingKind.forbidden,
    titleEn: 'Eid al-Fitr — no fasting',
    titleAr: 'عيد الفطر',
    why:
        'The Prophet ﷺ prohibited fasting on the two Eid days. Eid al-Fitr '
        'is a day of eating, drinking and remembrance of Allah.',
    source: 'Sahih al-Bukhari 1991 · Sahih Muslim 827',
  );

  static const FastingMarker _eidAdha = FastingMarker(
    kind: FastingKind.forbidden,
    titleEn: 'Eid al-Adha — no fasting',
    titleAr: 'عيد الأضحى',
    why: 'The Prophet ﷺ prohibited fasting on the two Eid days.',
    source: 'Sahih al-Bukhari 1991 · Sahih Muslim 827',
  );

  static const FastingMarker _tashreeq = FastingMarker(
    kind: FastingKind.forbidden,
    titleEn: 'Days of Tashreeq — no fasting',
    titleAr: 'أيام التشريق',
    why:
        'The days of Tashreeq (11–13 Dhul-Hijjah) are days of eating, '
        'drinking and remembrance of Allah; fasting them is prohibited '
        'except for the pilgrim who cannot afford a sacrificial animal.',
    source: 'Sahih Muslim 1141',
  );

  /// Every marker that applies to [date]. A date can carry several
  /// (e.g. a White Day that falls on a Monday).
  static List<FastingMarker> forDate(HijriDate date) {
    final List<FastingMarker> out = <FastingMarker>[];

    // Forbidden days take precedence in spirit (they are never combined with
    // a recommended marker in practice, since Eids/Tashreeq can't be White
    // Days or Mon/Thu-only events — but the resolver stays declarative).
    if (date.month == 10 && date.day == 1) out.add(_eidFitr);
    if (date.month == 12 && date.day == 10) out.add(_eidAdha);
    if (date.month == 12 && date.day >= 11 && date.day <= 13) {
      out.add(_tashreeq);
    }

    // Weekly sunnah (Monday = weekday 1, Thursday = 4, Gregorian).
    final int weekday = date.toGregorian().weekday;
    if (weekday == DateTime.monday) out.add(_monday);
    if (weekday == DateTime.thursday) out.add(_thursday);

    // White Days: 13–15 of every lunar month.
    if (date.day >= 13 && date.day <= 15) out.add(_whiteDays);

    // Fixed annual days.
    if (date.month == 12 && date.day == 9) out.add(_arafah);
    if (date.month == 1 && date.day == 9) out.add(_tasua);
    if (date.month == 1 && date.day == 10) out.add(_ashura);
    if (date.month == 10) out.add(_shawwalNote);

    return out;
  }

  /// True when fasting on [date] is prohibited.
  static bool isForbidden(HijriDate date) =>
      forDate(date).any((FastingMarker m) => m.kind == FastingKind.forbidden);

  /// All recommended-fasting dates in the given Hijri month (for the
  /// "this month" planner card). Forbidden days are excluded.
  static List<(HijriDate, List<FastingMarker>)> recommendedInMonth(
    int year,
    int month,
  ) {
    final int days = HijriDate.monthLength(year, month);
    final List<(HijriDate, List<FastingMarker>)> out =
        <(HijriDate, List<FastingMarker>)>[];
    for (int d = 1; d <= days; d++) {
      final HijriDate date = HijriDate(year, month, d);
      final List<FastingMarker> all = forDate(date);
      // Prohibition always overrides recommendation (e.g. 13 Dhul-Hijjah is
      // both a White Day and Tashreeq — fasting it is forbidden).
      if (all.any((FastingMarker m) => m.kind == FastingKind.forbidden)) {
        continue;
      }
      List<FastingMarker> markers = all
          .where((FastingMarker m) => m.kind == FastingKind.recommended)
          .toList();
      // The Shawwal note applies all month; attaching it to every day would
      // be noise — surface it once, on the 2nd (the earliest day it may be
      // fasted, right after Eid).
      if (month == 10 && d != 2) {
        markers = markers
            .where((FastingMarker m) => m.titleEn != 'Six of Shawwal')
            .toList();
      }
      if (markers.isEmpty) continue;
      out.add((date, markers));
    }
    return out;
  }
}
