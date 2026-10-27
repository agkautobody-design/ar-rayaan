/// Ranked Qur'an search for the global search. Pure Dart.
///
/// On top of `searchQuran` (verse keys, Arabic with diacritics folded,
/// phrase and all-words English) this adds:
///
/// * named verses: "ayat al kursi", "throne verse", "last two verses of
///   baqarah" go straight to the verse;
/// * word folding for English: "salah" and "salat" find the verses that
///   say "prayer"; "sabr" finds "patience" (see `search_text.dart`);
/// * transliteration: "bismillahir rahmanir raheem" finds 1:1 where the
///   bundled transliteration has it;
/// * Arabic-Indic digits in verse keys ("٢:٢٥٥");
/// * ranking: a named verse first, then the whole phrase, then all words,
///   shortest verse first within a group.
library;

import '../../quran/domain/quran_models.dart';
import 'quran_search.dart';
import 'search_engine.dart';
import 'search_text.dart';

/// A verse (or a few in a row) that people call by a name.
class NamedVerse {
  const NamedVerse(this.surah, this.firstAyah, this.lastAyah, this.names);

  final int surah;
  final int firstAyah;
  final int lastAyah;

  /// Ways to say it, in English letters or Arabic.
  final List<String> names;
}

/// Verses with a widely used name. Each reference was checked against the
/// bundled text (the Arabic opens as expected).
const List<NamedVerse> kNamedVerses = <NamedVerse>[
  NamedVerse(2, 255, 255, <String>[
    'ayat al kursi',
    'ayatul kursi',
    'ayat ul kursi',
    'ayah al kursi',
    'ayatal kursi',
    'ayat kursi',
    'ayah kursi',
    'throne verse',
    'verse of the throne',
    'verse of throne',
    'kursi',
    'آية الكرسي',
    'اية الكرسي',
  ]),
  NamedVerse(2, 285, 286, <String>[
    'last two verses of al baqarah',
    'last two verses of baqarah',
    'last two ayat of baqarah',
    'last 2 verses of baqarah',
    'last two verses of surah baqarah',
    'amana rasul',
    'amanar rasulu',
    'خواتيم البقرة',
    'آخر آيتين من البقرة',
  ]),
  NamedVerse(2, 282, 282, <String>[
    'ayat al dayn',
    'ayatul dayn',
    'verse of debt',
    'longest verse',
    'longest ayah',
    'آية الدين',
  ]),
  NamedVerse(24, 35, 35, <String>[
    'ayat an nur',
    'ayatun nur',
    'ayat al nur',
    'verse of light',
    'light verse',
    'آية النور',
  ]),
  NamedVerse(59, 22, 24, <String>[
    'last three verses of al hashr',
    'last three verses of hashr',
    'last 3 verses of hashr',
    'last verses of surah hashr',
    'khawatim al hashr',
    'خواتيم الحشر',
  ]),
  NamedVerse(9, 128, 129, <String>[
    'last two verses of at tawbah',
    'last two verses of tawbah',
    'last two verses of surah tawbah',
    'laqad jaakum',
    'laqad jaa kum',
  ]),
];

String _letters(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

Map<String, NamedVerse>? _nameIndex;
Map<String, NamedVerse> get _names => _nameIndex ??= <String, NamedVerse>{
      for (final NamedVerse v in kNamedVerses)
        for (final String n in v.names)
          (containsArabicLetters(n) ? foldArabic(n) : nameKey(_letters(n))): v,
    };

/// The named verse [query] asks for, or null. English names are compared by
/// sound-alike key (so "ayatul kursi", "ayat al-kursi" and "ayaat ul kursee"
/// meet); a query that contains a longer name also counts ("ayat al kursi
/// meaning"). Arabic names are compared folded.
NamedVerse? matchNamedVerse(String query) {
  final String q = normalizeSearchQuery(query);
  if (q.isEmpty) return null;
  if (containsArabicLetters(q)) {
    final String f = foldArabic(q);
    for (final MapEntry<String, NamedVerse> e in _names.entries) {
      if (containsArabicLetters(e.key) && f.contains(e.key)) return e.value;
    }
    return null;
  }
  final String key = nameKey(_letters(q));
  if (key.length < 5) return null;
  final NamedVerse? exact = _names[key];
  if (exact != null) return exact;
  NamedVerse? found;
  int foundLen = 0;
  for (final MapEntry<String, NamedVerse> e in _names.entries) {
    if (containsArabicLetters(e.key) || e.key.length < 8) continue;
    if (key.contains(e.key) && e.key.length > foundLen) {
      found = e.value;
      foundLen = e.key.length;
    }
  }
  return found;
}

/// [input] with Arabic-Indic and Persian digits written as 0-9.
String asciiDigits(String input) {
  final StringBuffer b = StringBuffer();
  for (final int r in input.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      b.writeCharCode(0x30 + r - 0x0660);
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      b.writeCharCode(0x30 + r - 0x06F0);
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

final Expando<Set<String>> _enWords = Expando<Set<String>>('enWords');
final Expando<String> _tlKeys = Expando<String>('tlKeys');

Set<String> _wordsOf(Ayah a) => _enWords[a] ??= searchTokens(a.english).toSet();

QuranHit _hit(Surah s, Ayah a, int score) => QuranHit(
      surah: s.meta.number,
      ayah: a.number,
      score: score,
      arabic: a.arabic,
      english: a.english,
      surahName: s.meta.transliteration,
    );

/// Qur'an hits for [query], best first. [translit] maps "surah:ayah" to the
/// bundled transliteration (may be empty). At most [limit] hits.
///
/// Scores: 4 a named verse, 3 a verse key, 2 the whole phrase, all of the
/// query's words, or the transliteration, 1 only another wording of the
/// query ("sabr" read as "patience").
List<QuranHit> findQuran(
  List<Surah> surahs,
  String query, {
  Map<String, String> translit = const <String, String>{},
  int limit = 2000,
}) {
  final String q = normalizeSearchQuery(asciiDigits(query));
  if (q.isEmpty || surahs.isEmpty) return const <QuranHit>[];

  if (parseVerseKey(q) != null) {
    return searchQuran(surahs, q, limit: limit);
  }

  final List<QuranHit> out = <QuranHit>[];

  final NamedVerse? named = matchNamedVerse(q);
  if (named != null && named.surah >= 1 && named.surah <= surahs.length) {
    final Surah s = surahs[named.surah - 1];
    for (int n = named.firstAyah; n <= named.lastAyah; n++) {
      if (n < 1 || n > s.ayahs.length) continue;
      out.add(_hit(s, s.ayahs[n - 1], 4));
    }
    // A name is a name: the verse is the answer, not a word search.
    return out.take(limit).toList();
  }

  if (containsArabicLetters(q)) {
    final List<QuranHit> found = searchQuran(surahs, q, limit: 100000);
    return _ranked(found, (QuranHit h) => h.arabic.length).take(limit).toList();
  }

  final String phrase = foldEnglish(q);
  if (phrase.length < 2) return const <QuranHit>[];
  final QuerySpec spec = QuerySpec.parse(q);
  final String tlKey = nameKey(_letters(q));

  final List<QuranHit> found = <QuranHit>[];
  for (final Surah s in surahs) {
    for (final Ayah a in s.ayahs) {
      final String en = foldEnglish(a.english);
      int score = 0;
      if (en.startsWith(phrase) || en.contains(' $phrase')) {
        score = 2;
      } else {
        final Set<String> words = _wordsOf(a);
        for (int i = 0; i < spec.alternatives.length; i++) {
          if (queryTokensCovered(spec.alternatives[i], words)) {
            // The query's own words beat another wording of it.
            score = i == 0 ? 2 : 1;
            break;
          }
        }
      }
      if (score < 2 && tlKey.length >= 6 && translit.isNotEmpty) {
        final String? t = translit['${s.meta.number}:${a.number}'];
        if (t != null) {
          final String tk = _tlKeys[a] ??= nameKey(_letters(t));
          if (tk.contains(tlKey)) score = 2;
        }
      }
      if (score > 0) found.add(_hit(s, a, score));
    }
  }
  return _ranked(found, (QuranHit h) => h.english.length).take(limit).toList();
}

/// Higher score first; within a score the shorter verse first (the word is
/// a bigger part of it); ties keep Qur'anic order.
List<QuranHit> _ranked(List<QuranHit> hits, int Function(QuranHit) length) {
  final List<(int, QuranHit)> indexed = <(int, QuranHit)>[
    for (int i = 0; i < hits.length; i++) (i, hits[i]),
  ];
  indexed.sort(((int, QuranHit) a, (int, QuranHit) b) {
    final int byScore = b.$2.score.compareTo(a.$2.score);
    if (byScore != 0) return byScore;
    final int byLen = length(a.$2).compareTo(length(b.$2));
    return byLen != 0 ? byLen : a.$1.compareTo(b.$1);
  });
  return <QuranHit>[for (final (int, QuranHit) e in indexed) e.$2];
}
