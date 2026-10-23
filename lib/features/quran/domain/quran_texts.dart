/// Attribution for the two bundled Qur'an texts, read from
/// `assets/quran/texts.json` so credit, link and licence status live in
/// one data file the screens read (they can never drift apart).
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/content_loader.dart';

class QuranTextCredit {
  const QuranTextCredit({
    required this.title,
    required this.credit,
    required this.url,
    required this.note,
  });

  factory QuranTextCredit.fromJson(Map<String, dynamic> j) => QuranTextCredit(
        title: j['title'] as String,
        credit: j['credit'] as String,
        url: j['url'] as String,
        note: j['note'] as String,
      );

  final String title;
  final String credit;
  final String url;
  final String note;
}

class QuranTexts {
  const QuranTexts({required this.arabic, required this.translation});

  factory QuranTexts.fromJson(Map<String, dynamic> j) => QuranTexts(
        arabic: QuranTextCredit.fromJson(j['arabic'] as Map<String, dynamic>),
        translation:
            QuranTextCredit.fromJson(j['translation'] as Map<String, dynamic>),
      );

  final QuranTextCredit arabic;
  final QuranTextCredit translation;

  /// Used until the asset has loaded. A test keeps it equal to the JSON.
  static const QuranTexts fallback = QuranTexts(
    arabic: QuranTextCredit(
      title: 'Arabic Text · Tanzil Uthmani',
      credit: 'Tanzil Project',
      url: 'https://tanzil.net',
      note:
          'Verbatim copy of the Tanzil Uthmani text, 114 surahs and 6,236 ayahs. Tanzil asks that the text is never changed and that its source is named, so it is shown exactly as supplied.',
    ),
    translation: QuranTextCredit(
      title: 'Translation · Saheeh International',
      credit:
          'Saheeh International (Abul-Qasim Publishing House, 1997), supplied by the Tanzil Project',
      url: 'https://tanzil.net/trans/en.sahih',
      note:
          'Shown verbatim as supplied by Tanzil, with its own punctuation and quotation marks, and nothing added or removed. A translation gives the meaning of the Qur’an, it is not the Qur’an itself. Licence status: the rights holder\'s own permission for this app has not yet been confirmed, so the translation stays marked as interim.',
    ),
  );
}

final FutureProvider<QuranTexts> quranTextsProvider =
    FutureProvider<QuranTexts>((Ref ref) async {
  try {
    final String raw = await ContentLoader.loadString('assets/quran/texts.json');
    return QuranTexts.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return QuranTexts.fallback;
  }
});
