/// The Academy's daily verse: one short, self-contained phrase about
/// learning, rotating by calendar day. Every phrase is a verbatim part of the
/// bundled translation at its reference (test/academy_review_fixes_test.dart
/// checks each one against assets/quran/quran.json), so nothing is
/// paraphrased or invented. 39:9 is not in the rotation because the Academy
/// home already shows it in the knowledge banner.
library;

class DailyVerse {
  const DailyVerse(this.surah, this.ayah, this.text);

  final int surah;
  final int ayah;

  /// A verbatim part of the bundled translation of this ayah.
  final String text;

  String get ref => '$surah:$ayah';
}

const List<DailyVerse> kDailyVerses = <DailyVerse>[
  DailyVerse(20, 114, 'My Lord, increase me in knowledge.'),
  DailyVerse(58, 11,
      'Allah will raise those who have believed among you and those who were given knowledge, by degrees.'),
  DailyVerse(35, 28,
      'Only those fear Allah, from among His servants, who have knowledge.'),
  DailyVerse(96, 5, 'Taught man that which he knew not.'),
  DailyVerse(2, 269,
      'whoever has been given wisdom has certainly been given much good.'),
  DailyVerse(12, 76,
      'over every possessor of knowledge is one [more] knowing.'),
  DailyVerse(16, 43, 'ask the people of the message if you do not know.'),
];

/// The verse for [day] (local calendar day). Stable within a day, and it
/// moves on at midnight.
DailyVerse dailyVerseFor(DateTime day) {
  final int days =
      DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
          Duration.millisecondsPerDay;
  return kDailyVerses[days % kDailyVerses.length];
}
