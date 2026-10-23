/// Light text matching for the global search. Pure Dart — no Flutter, no
/// I/O — so it is unit-tested with the plain Dart SDK.
///
/// * [searchTokens] lower-cases, drops apostrophes and punctuation, and
///   reduces each word to a crude stem (plural / -ing / -ed / final -e).
/// * A small synonym table folds spellings and wordings the app's own
///   texts do not share with the people searching ("intentions" for the
///   hadith that says "motives", "salah" for "prayer", "nikah" for
///   "marriage").
/// * [matchesQuery] is true when the raw phrase occurs, or when every
///   meaningful query word occurs (prefix-tolerant) in the text.
/// * [matchSurahNames] finds surahs by name, number ("surah 67") or
///   English meaning.
library;

import '../../quran/domain/quran_models.dart';
import 'quran_search.dart' show containsArabicLetters, foldArabic;

/// Words that carry no search meaning on their own.
const Set<String> kSearchStopwords = <String>{
  'a', 'an', 'the', 'is', 'are', 'was', 'be', 'by', 'of', 'to', 'in', 'on',
  'for', 'and', 'or', 'how', 'do', 'does', 'i', 'my', 'me', 'what', 'can',
  'about', 'with', 'at', 'it', 'this', 'that', 'near', 'find', 'show',
};

/// Stem -> canonical stem. Keys are the OUTPUT of [_basicStem].
const Map<String, String> _synonyms = <String, String>{
  // hadith 1 says "motives (niyyah)"; people say "intentions"
  'intention': 'motiv',
  'intend': 'motiv',
  'intent': 'motiv',
  'niyyah': 'motiv',
  'niyyat': 'motiv',
  // prayer
  'salah': 'prayer',
  'salat': 'prayer',
  'salaah': 'prayer',
  'namaz': 'prayer',
  'solat': 'prayer',
  'pray': 'prayer',
  // purification
  'ablution': 'wudu',
  'wudhu': 'wudu',
  'wuzu': 'wudu',
  // marriage
  'nikah': 'marriag',
  'nikaah': 'marriag',
  'wedd': 'marriag',
  'marry': 'marriag',
  'marri': 'marriag',
  // schools of law
  'madhab': 'madhhab',
  'mazhab': 'madhhab',
  'madhahib': 'madhhab',
  // remembrance
  'tasbeeh': 'tasbih',
  'tasbeh': 'tasbih',
  'zikr': 'dhikr',
  'adhkar': 'dhikr',
  'azkar': 'dhikr',
  // giving
  'sadaqah': 'charity',
  'sadaqa': 'charity',
  'sadaqat': 'charity',
  'charitabl': 'charity',
  'zakah': 'zakat',
  // places and books
  'mosqu': 'masjid',
  'koran': 'quran',
};

/// Lower-case, strip apostrophes, split on anything that is not a letter
/// or digit. Arabic letters are kept as they are.
List<String> _rawWords(String input) {
  final String s = input
      .toLowerCase()
      .replaceAll("'", '')
      .replaceAll('’', '')
      .replaceAll('ʿ', '')
      .replaceAll('ʾ', '');
  final StringBuffer b = StringBuffer();
  for (final int r in s.runes) {
    final bool digit = r >= 0x30 && r <= 0x39;
    final bool latin = r >= 0x61 && r <= 0x7A;
    final bool other = r > 0x7F; // accented Latin, Arabic …
    b.writeCharCode(digit || latin || other ? r : 0x20);
  }
  return b
      .toString()
      .split(' ')
      .where((String w) => w.isNotEmpty)
      .toList();
}

String _basicStem(String w) {
  String s = w;
  if (s.length > 5 && s.endsWith('ing')) {
    s = s.substring(0, s.length - 3);
  } else if (s.length > 4 && s.endsWith('ed')) {
    s = s.substring(0, s.length - 2);
  }
  if (s.length > 3 && s.endsWith('s') && !s.endsWith('ss')) {
    s = s.substring(0, s.length - 1);
  }
  if (s.length > 3 && s.endsWith('e')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

/// The matching stem of one word (synonym-folded).
String stemWord(String word) {
  final String s = _basicStem(word);
  return _synonyms[s] ?? s;
}

/// Stemmed words of [input]. With [dropStopwords], filler words are removed
/// unless that would leave nothing.
List<String> searchTokens(String input, {bool dropStopwords = false}) {
  final List<String> raw = _rawWords(input);
  final List<String> kept = dropStopwords
      ? raw.where((String w) => !kSearchStopwords.contains(w)).toList()
      : raw;
  final List<String> use = kept.isEmpty ? raw : kept;
  return <String>[for (final String w in use) stemWord(w)];
}

bool _tokenHit(String queryToken, Set<String> textTokens) {
  if (textTokens.contains(queryToken)) return true;
  if (queryToken.length < 3) return false;
  for (final String t in textTokens) {
    if (t.startsWith(queryToken)) return true;
  }
  return false;
}

/// True when every token of [queryTokens] occurs in [textTokens] (a token of
/// 3+ letters also matches the start of a longer word). False when empty.
bool queryTokensCovered(
  Iterable<String> queryTokens,
  Iterable<String> textTokens,
) {
  final List<String> qt = queryTokens.toList();
  if (qt.isEmpty) return false;
  final Set<String> tt = textTokens.toSet();
  for (final String t in qt) {
    if (!_tokenHit(t, tt)) return false;
  }
  return true;
}

/// True when [text] answers [query]: the raw phrase occurs in it, or every
/// meaningful query word occurs in it (plural-, tense- and synonym-folded;
/// a query word of 3+ letters also matches the start of a longer word).
bool matchesQuery(String text, String query) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty || text.isEmpty) return false;
  if (text.toLowerCase().contains(q)) return true;
  final List<String> qt = searchTokens(q, dropStopwords: true);
  if (qt.isEmpty) return false;
  return queryTokensCovered(qt, searchTokens(text));
}

String _letters(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

final RegExp _surahWord =
    RegExp(r'^(surah|surat|sura|chapter)\s+', caseSensitive: false);

/// Surahs whose name, number ("surah 67") or English meaning answers
/// [query], best first (name starts with the query), then Qur'anic order.
List<SurahMeta> matchSurahNames(
  List<SurahMeta> metas,
  String query, {
  int limit = 8,
}) {
  String q = query.trim().toLowerCase();
  if (q.isEmpty || metas.isEmpty) return const <SurahMeta>[];

  if (containsArabicLetters(q)) {
    final String f = foldArabic(q);
    if (f.length < 2) return const <SurahMeta>[];
    return metas
        .where((SurahMeta m) => foldArabic(m.arabicName).contains(f))
        .take(limit)
        .toList();
  }

  final bool hadWord = _surahWord.hasMatch(q);
  q = q.replaceFirst(_surahWord, '').trim();
  if (q.isEmpty) return const <SurahMeta>[];

  final RegExpMatch? num = RegExp(r'^\d{1,3}$').firstMatch(q);
  if (num != null) {
    if (!hadWord) return const <SurahMeta>[];
    final int n = int.parse(q);
    return metas.where((SurahMeta m) => m.number == n).toList();
  }

  final String key = _letters(q);
  if (key.length < 3) return const <SurahMeta>[];

  final List<SurahMeta> starts = <SurahMeta>[];
  final List<SurahMeta> rest = <SurahMeta>[];
  for (final SurahMeta m in metas) {
    final String name = _letters(m.transliteration);
    final String bare = name.replaceFirst(RegExp(r'^(al|an|ar|as|ash|at|az|ad)'), '');
    if (name == key || bare == key || bare.startsWith(key)) {
      starts.add(m);
    } else if (name.contains(key) || matchesQuery(m.englishMeaning, q)) {
      rest.add(m);
    }
  }
  return <SurahMeta>[...starts, ...rest].take(limit).toList();
}
