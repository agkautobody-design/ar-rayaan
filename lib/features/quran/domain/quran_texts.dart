/// Attribution for the two bundled Qur'an texts, read from
/// `assets/quran/texts.json` so credit, link and licence status live in
/// one data file the screens read (they can never drift apart).
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/content_loader.dart';
import '../application/translation_providers.dart';
import 'translation_pack.dart';
import '../../../app/core/retry_when_online.dart';

/// The interim translation's credit, as shown in footers and when sharing.
/// It is labelled interim because the rights holder's permission for this
/// app has not been confirmed (see the note in assets/quran/texts.json).
const String kInterimFooterCredit =
    'Saheeh International (interim), via Tanzil.net';
const String kInterimShareCredit = 'Saheeh International (interim), via Tanzil';

class QuranTextCredit {
  const QuranTextCredit({
    required this.title,
    required this.credit,
    required this.url,
    required this.note,
    this.short = kInterimFooterCredit,
    this.shareShort = kInterimShareCredit,
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

  /// One-line credit for screen footers ("Translation: <short>").
  final String short;

  /// One-line credit for copied or shared text.
  final String shareShort;
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

  /// Footer under the reader and the surah list.
  String get footerLine =>
      'Arabic: Tanzil Uthmani · Translation: ${translation.short}';

  /// Credit line appended to copied or exported ayahs (no app sign-off).
  String get shareCreditLine =>
      'Arabic: Tanzil Uthmani (tanzil.net). Translation: '
      '${translation.shareShort}.';

  /// The credits for what the reader actually shows: the active pack's own
  /// attribution and licence reference, or the interim translation (with an
  /// honest note when the chosen one has not been installed yet).
  QuranTexts forActive(ActiveTranslation? active) {
    if (active == null) return this;
    final TranslationPack? p = active.pack;
    if (p != null) {
      return QuranTexts(
        arabic: arabic,
        translation: QuranTextCredit(
          title: 'Translation · ${p.title}',
          credit: p.attribution,
          url: p.url,
          note:
              'Translator: ${p.translator}. Publisher: ${p.publisher}. '
              'Licence reference: ${p.licenseId}. Shown exactly as supplied '
              'in the publisher\u2019s text. A translation gives the meaning '
              'of the Qur\u2019an, it is not the Qur\u2019an itself.',
          short: p.attribution,
          shareShort: p.attribution.endsWith('.')
              ? p.attribution.substring(0, p.attribution.length - 1)
              : p.attribution,
        ),
      );
    }
    if (active.wantedId == kInterimEnglishId) return this;
    final String wanted = active.wantedId == kClearQuranId
        ? 'The Clear Quran (Dr. Mustafa Khattab) is the translation for this '
              'app and its text is being added'
        : 'The chosen translation is not installed on this device';
    return QuranTexts(
      arabic: arabic,
      translation: QuranTextCredit(
        title: translation.title,
        credit: translation.credit,
        url: translation.url,
        note: '${translation.note} $wanted, so the interim translation is '
            'shown until it arrives.',
        short: translation.short,
        shareShort: translation.shareShort,
      ),
    );
  }

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
  QuranTexts base = QuranTexts.fallback;
  try {
    final String raw = await ContentLoader.loadString('assets/quran/texts.json');
    base = QuranTexts.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    // Built-in copy for now; fetched again once the connection is back.
    refreshWhenBackOnline(ref);
  }
  try {
    return base.forActive(await ref.watch(activeTranslationProvider.future));
  } catch (_) {
    return base;
  }
});
