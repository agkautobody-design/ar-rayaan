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
  'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'by', 'of', 'to', 'in',
  'on', 'for', 'and', 'or', 'how', 'do', 'does', 'did', 'i', 'my', 'me', 'we',
  'you', 'your', 'our', 'what', 'can', 'could', 'should', 'would', 'will',
  'about', 'with', 'at', 'it', 'this', 'that', 'near', 'find', 'show', 'tell',
  'give', 'from', 'there', 'any', 'some', 'if', 'as', 'so', 'am', 'has', 'have',
  'where', 'which', 'who', 'why', 'please', 'want', 'need', 'know',
};

/// The longest query the global search looks at. A longer paste is cut here
/// (at a word edge where it can be): nothing useful is lost, and the work per
/// search stays small and bounded.
const int kMaxSearchQueryChars = 80;

/// The most words of a query that are matched.
const int kMaxSearchQueryWords = 8;

/// [input] trimmed, whitespace collapsed, and cut to [kMaxSearchQueryChars]
/// (never mid-word when a space is near the end) and [kMaxSearchQueryWords]
/// words. Cheap and linear: safe on any input, however long.
String normalizeSearchQuery(String input) {
  // Look at no more than a bounded prefix, so even a huge paste costs little.
  final String head = input.length > kMaxSearchQueryChars * 4
      ? input.substring(0, kMaxSearchQueryChars * 4)
      : input;
  final List<String> words =
      head.trim().split(RegExp(r'\s+')).where((String w) => w.isNotEmpty).toList();
  final StringBuffer b = StringBuffer();
  int count = 0;
  for (final String w in words) {
    if (count >= kMaxSearchQueryWords) break;
    final int add = (count == 0 ? 0 : 1) + w.length;
    if (b.length + add > kMaxSearchQueryChars) {
      if (count == 0) {
        b.write(w.substring(0, kMaxSearchQueryChars));
        count++;
      }
      break;
    }
    if (count > 0) b.write(' ');
    b.write(w);
    count++;
  }
  return b.toString();
}

/// Natural phrases people type, and the words the app's shelves use for the
/// same thing. The key is matched after stemming and stop-word removal, so
/// "difference of opinion" and "differences of opinions" are one key.
const Map<String, List<String>> kPhraseAliases = <String, List<String>>{
  'difference of opinion': <String>['madhhab', 'school of law'],
  'different opinion': <String>['madhhab', 'school of law'],
  'scholars disagree': <String>['madhhab', 'school of law'],
  'disagreement': <String>['madhhab', 'school of law'],
  'why muslims fast': <String>['fasting', 'ramadan'],
  'why fast': <String>['fasting', 'ramadan'],
  'before sleeping': <String>['before sleep'],
  'going to sleep': <String>['before sleep'],
  'bed time': <String>['before sleep'],
  'being patient': <String>['patience'],
  'feeling sad': <String>['grief', 'hardship'],
  'feeling anxious': <String>['anxiety', 'worry'],
};

Map<String, List<String>>? _aliasIndex;

/// Alternative wordings for [query] from [kPhraseAliases] (empty if none).
List<String> queryAliases(String query) {
  _aliasIndex ??= <String, List<String>>{
    for (final MapEntry<String, List<String>> e in kPhraseAliases.entries)
      searchTokens(e.key, dropStopwords: true).join(' '): e.value,
  };
  final String key = searchTokens(query, dropStopwords: true).join(' ');
  return _aliasIndex![key] ?? const <String>[];
}

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

/// Whole-word spelling folds, applied BEFORE stemming. Keys are lower-case
/// with apostrophes removed (the way [_rawWords] leaves a word); values are
/// the one spelling every variant is read as. The query and the text are
/// both folded, so it does not matter which spelling the app's text uses.
/// Spellings already folded by [_synonyms] (salat, namaz, wudhu, zikr,
/// koran, mosque…) are not repeated here.
const Map<String, String> kSpellingFolds = <String, String>{
  // the book
  'quraan': 'quran',
  'kuran': 'quran',
  'qoran': 'quran',
  // surah names
  'yaseen': 'yasin',
  'yaaseen': 'yasin',
  'yasen': 'yasin',
  'yassin': 'yasin',
  'kahaf': 'kahf',
  'rehman': 'rahman',
  'rahmaan': 'rahman',
  'fatihah': 'fatiha',
  'fateha': 'fatiha',
  'fatehah': 'fatiha',
  'fateeha': 'fatiha',
  'ikhlaas': 'ikhlas',
  'ikhlass': 'ikhlas',
  'mulq': 'mulk',
  'baqara': 'baqarah',
  'bakara': 'baqarah',
  'imraan': 'imran',
  'sajda': 'sajdah',
  'waqia': 'waqiah',
  'waqiaa': 'waqiah',
  // people
  'yousuf': 'yusuf',
  'yoosuf': 'yusuf',
  'yosef': 'yusuf',
  'yusef': 'yusuf',
  'yousef': 'yusuf',
  'joseph': 'yusuf',
  'mohammed': 'muhammad',
  'mohamed': 'muhammad',
  'mohammad': 'muhammad',
  'mohamad': 'muhammad',
  'muhammed': 'muhammad',
  'muhamed': 'muhammad',
  'ebrahim': 'ibrahim',
  'ibraheem': 'ibrahim',
  'ibrahem': 'ibrahim',
  'abraham': 'ibrahim',
  'eesa': 'isa',
  'esa': 'isa',
  'jesus': 'isa',
  'moosa': 'musa',
  'mousa': 'musa',
  'moses': 'musa',
  'mariam': 'maryam',
  'maryum': 'maryam',
  'mary': 'maryam',
  // worship words
  'salaat': 'salah',
  'wudoo': 'wudu',
  'wuzoo': 'wudu',
  'sawm': 'fasting',
  'siyam': 'fasting',
  'siam': 'fasting',
  'roza': 'fasting',
  'roja': 'fasting',
  'rozah': 'fasting',
  'zakaat': 'zakat',
  'zakaah': 'zakat',
  'haj': 'hajj',
  'hadj': 'hajj',
  'eed': 'eid',
  'id': 'eid',
  'duaa': 'dua',
  'dhua': 'dua',
  'doa': 'dua',
  'zikir': 'dhikr',
  'zhikr': 'dhikr',
  'dhikir': 'dhikr',
  'tasbeeh': 'tasbih',
  'ramazan': 'ramadan',
  'ramzan': 'ramadan',
  'ramadhan': 'ramadan',
  'nikkah': 'nikah',
  'mathhab': 'madhhab',
  'hijree': 'hijri',
  'hejri': 'hijri',
  'qiblah': 'qibla',
  'kibla': 'qibla',
  'kiblah': 'qibla',
  'masjed': 'masjid',
  'musjid': 'masjid',
  'masajid': 'masjid',
  'jummah': 'jumuah',
  'jumah': 'jumuah',
  'jumaa': 'jumuah',
  'juma': 'jumuah',
  'jumma': 'jumuah',
  'friday': 'jumuah',
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
  final String s = _basicStem(kSpellingFolds[word] ?? word);
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
  final String q = normalizeSearchQuery(query).toLowerCase();
  if (q.isEmpty || text.isEmpty) return false;
  if (_matchesOne(text, q)) return true;
  for (final String alt in queryAliases(q)) {
    if (_matchesOne(text, alt)) return true;
  }
  return false;
}

bool _matchesOne(String text, String q) {
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
  bool allowNear = true,
}) {
  String q = normalizeSearchQuery(query).toLowerCase();
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
  final String nkey = nameKey(_foldedLetters(q));

  final List<SurahMeta> starts = <SurahMeta>[];
  final List<SurahMeta> rest = <SurahMeta>[];
  final List<SurahMeta> near = <SurahMeta>[];
  for (final SurahMeta m in metas) {
    final String name = _letters(m.transliteration);
    final String bare = name.replaceFirst(_article, '');
    final String nname = nameKey(name);
    final String nbare = nameKey(bare);
    if (name == key ||
        bare == key ||
        bare.startsWith(key) ||
        nname == nkey ||
        nbare == nkey ||
        (nkey.length >= 3 && nbare.startsWith(nkey))) {
      starts.add(m);
    } else if (name.contains(key) ||
        nname.contains(nkey) ||
        matchesQuery(m.englishMeaning, q)) {
      rest.add(m);
    } else if (nkey.length >= 5 &&
        (withinOneEdit(nkey, nbare) || withinOneEdit(nkey, nname))) {
      near.add(m);
    }
  }
  // A slip of one letter is only forgiven when nothing matched exactly.
  final bool exact = starts.isNotEmpty || rest.isNotEmpty;
  return <SurahMeta>[...starts, ...rest, if (!exact && allowNear) ...near]
      .take(limit)
      .toList();
}

final RegExp _article = RegExp(r'^(al|an|ar|as|ash|at|az|ad)');

/// [q] with each word spelling-folded, letters only.
String _foldedLetters(String q) => _letters(<String>[
      for (final String w in _rawWords(q)) kSpellingFolds[w] ?? w,
    ].join());

/// A sound-alike key for a transliterated name: letters only, `q` read as
/// `k`, long vowels (ee, oo, ou) shortened, doubled letters collapsed, and
/// a final vowel+h dropped. "Baqarah", "Baqara" and "Bakara" share a key;
/// so do "Yaseen" and "Yasin", "Ikhlaas" and "Ikhlas".
String nameKey(String input) {
  String s = input.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  s = s
      .replaceAll('q', 'k')
      .replaceAll('ee', 'i')
      .replaceAll('oo', 'u')
      .replaceAll('ou', 'u');
  final StringBuffer b = StringBuffer();
  String prev = '';
  for (int i = 0; i < s.length; i++) {
    final String c = s[i];
    if (c != prev) b.write(c);
    prev = c;
  }
  s = b.toString();
  if (s.length > 3 && s.endsWith('h') && 'aeiou'.contains(s[s.length - 2])) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

/// True when [a] and [b] differ by at most one inserted, deleted or
/// replaced letter.
bool withinOneEdit(String a, String b) {
  if (a == b) return true;
  final int la = a.length;
  final int lb = b.length;
  if ((la - lb).abs() > 1) return false;
  int i = 0;
  while (i < la && i < lb && a[i] == b[i]) {
    i++;
  }
  if (la == lb) return a.substring(i + 1) == b.substring(i + 1);
  if (la > lb) return a.substring(i + 1) == b.substring(i);
  return a.substring(i) == b.substring(i + 1);
}
