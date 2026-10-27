/// Ranked matching for every shelf of the global search. Pure Dart — no
/// Flutter, no I/O — so it is unit-tested with the plain Dart SDK.
///
/// * A query is read as a set of stemmed words ([QuerySpec]), plus the
///   alternative wordings in `kPhraseAliases`. "Soft" words that only say
///   what kind of thing is wanted ("prophet", "story", "dua") are dropped
///   when other words remain, so "prophet yusuf" finds Yusuf's story.
/// * A [SearchDoc] holds the words of one item's title, subtitle and body.
///   [scoreDoc] gives 0 (no match) or a score: the title answering the whole
///   query beats title+subtitle together, which beats the body alone.
///   Words may be spread over fields: a query matches when every word is
///   found somewhere in the item.
library;

import 'search_text.dart';

/// Words that name the KIND of thing wanted, not the thing. They are ignored
/// when the query has other words, and used when it has nothing else.
const Set<String> kSoftWords = <String>{
  'prophet', 'prophets', 'messenger', 'nabi', 'rasul', 'sayyidina', 'hazrat',
  'story', 'stories', 'surah', 'sura', 'ayah', 'ayat', 'verse', 'verses',
  'chapter', 'hadith', 'hadeeth', 'dua', 'duas', 'supplication', 'islamic',
  'islam', 'muslim', 'muslims', 'companion', 'companions', 'sahabi', 'about',
  'meaning', 'explain', 'explanation',
};

/// The words of [input] that carry the meaning of a search.
List<String> meaningTokens(String input) {
  final List<String> all = searchTokens(input, dropStopwords: true);
  final List<String> hard = <String>[
    for (final String t in all)
      if (!kSoftWords.contains(t)) t,
  ];
  return hard.isEmpty ? all : hard;
}

/// A parsed query: the alternatives it may be read as.
class QuerySpec {
  QuerySpec._(this.phrase, this.alternatives);

  /// The query squashed (for raw phrase checks).
  final String phrase;

  /// Each entry is one reading: the words that must all be found. The first
  /// is the query itself; the rest come from aliases.
  final List<List<String>> alternatives;

  bool get isEmpty => alternatives.isEmpty;

  factory QuerySpec.parse(String query) {
    final String q = squashText(normalizeSearchQuery(query));
    final List<List<String>> alts = <List<String>>[];
    final List<String> main = meaningTokens(q);
    if (main.isNotEmpty) alts.add(main);
    for (final String alias in queryAliases(q)) {
      final List<String> t = meaningTokens(alias);
      if (t.isNotEmpty) alts.add(t);
    }
    return QuerySpec._(q, alts);
  }
}

/// [input] lower-cased with apostrophes dropped and every other mark turned
/// into a single space, so "Ya'qub (Jacob)" becomes "yaqub jacob". Raw phrase
/// checks are made on this, at the start of a word only ("isa" is not found
/// inside "disagreement").
String squashText(String input) {
  final StringBuffer b = StringBuffer();
  bool space = true;
  for (final int r in input.toLowerCase().runes) {
    if (r == 0x27 || r == 0x2019 || r == 0x02BF || r == 0x02BE) continue;
    final bool keep = (r >= 0x30 && r <= 0x39) ||
        (r >= 0x61 && r <= 0x7A) ||
        r > 0x7F;
    if (keep) {
      b.writeCharCode(r);
      space = false;
    } else if (!space) {
      b.write(' ');
      space = true;
    }
  }
  return b.toString().trim();
}

/// The words of one searchable item, by field. Built once per item.
class SearchDoc {
  SearchDoc({String title = '', String subtitle = '', String body = ''})
      : lowerTitle = squashText(title),
        lowerAll = ' ${squashText('$title $subtitle $body')}',
        titleWords = searchTokens(title).toSet(),
        subtitleWords = searchTokens(subtitle).toSet(),
        bodyWords = searchTokens(body).toSet();

  /// The title squashed (see [squashText]).
  final String lowerTitle;

  /// A space, then title, subtitle and body squashed.
  final String lowerAll;
  final Set<String> titleWords;
  final Set<String> subtitleWords;
  final Set<String> bodyWords;

  Set<String>? _headWords;
  Set<String>? _allWords;

  Set<String> get headWords =>
      _headWords ??= <String>{...titleWords, ...subtitleWords};
  Set<String> get allWords =>
      _allWords ??= <String>{...headWords, ...bodyWords};
}

/// Remembers one [SearchDoc] per object, so the words of a shelf are cut up
/// once, not on every keystroke.
final Expando<SearchDoc> _docs = Expando<SearchDoc>('searchDocs');

/// The cached [SearchDoc] for [owner], built by [make] the first time.
SearchDoc docFor(Object owner, SearchDoc Function() make) =>
    _docs[owner] ??= make();

/// 0 when [doc] does not answer [spec]; otherwise a score where higher is a
/// better answer:
///   120 the title is exactly the phrase
///   111-115 the title starts with the phrase (shorter title first)
///   110 the phrase is in the title (at the start of a word)
///   101-105 every word is a whole word of the title (shorter title first)
///   100 the title has every word (a word may be the start of a longer one)
///    80 title + subtitle together have every word
///    60 the whole item (any field) has every word
///    50 the phrase is somewhere in the item
/// An alias reading scores 10 less than the same reading of the query.
int scoreDoc(SearchDoc doc, QuerySpec spec) {
  if (spec.isEmpty && spec.phrase.length < 2) return 0;
  int best = 0;
  if (spec.phrase.length >= 3) {
    if (doc.lowerTitle == spec.phrase) {
      best = 120;
    } else if (doc.lowerTitle.startsWith(spec.phrase)) {
      // The shorter the rest of the title, the closer the match.
      final int extra = doc.lowerTitle.split(' ').length -
          spec.phrase.split(' ').length;
      best = 115 - (extra > 4 ? 4 : (extra < 0 ? 0 : extra));
    } else if (' ${doc.lowerTitle}'.contains(' ${spec.phrase}')) {
      best = 110;
    } else if (doc.lowerAll.contains(' ${spec.phrase}')) {
      best = 50;
    }
  }
  for (int i = 0; i < spec.alternatives.length; i++) {
    final List<String> words = spec.alternatives[i];
    final int penalty = i == 0 ? 0 : 10;
    int s = 0;
    if (words.isNotEmpty && words.every(doc.titleWords.contains)) {
      // Every word is a whole word of the title ("musa", not "musab").
      // The fewer other words in the title, the closer the match.
      final int extra = doc.titleWords.length - words.toSet().length;
      s = 105 - (extra > 4 ? 4 : (extra < 0 ? 0 : extra));
    } else if (queryTokensCovered(words, doc.titleWords)) {
      s = 100;
    } else if (queryTokensCovered(words, doc.headWords)) {
      s = 80;
    } else if (queryTokensCovered(words, doc.allWords)) {
      s = 60;
    }
    s -= s == 0 ? 0 : penalty;
    if (s > best) best = s;
  }
  return best;
}
