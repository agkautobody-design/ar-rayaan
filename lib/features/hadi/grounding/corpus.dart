import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'passage.dart';

/// Hādi's library: the only scripture the assistant may show.
///
/// - Qur'an passages are named by surah and ayah; the Arabic and English come
///   from the app's own bundled text (`assets/quran/quran.json`), never from
///   the model.
/// - Hadith passages come from `assets/noor/hadi_corpus.json`: a small,
///   curated list with the collection, number, grade and who gave the grade,
///   each checked on sunnah.com on the date in the file. Nothing outside the
///   list can be cited.
///
/// Retrieval is deliberately simple (topic words with inverse document
/// frequency): it is deterministic, needs no network and is fully testable.
class HadiCorpus {
  HadiCorpus._({
    required List<List<List<String>>> verses,
    required List<String> surahNames,
    required List<_Entry> entries,
    required Map<String, Passage> hadith,
    required this.checked,
  })  : _verses = verses,
        _surahKeys = <String>[for (final String n in surahNames) _letters(n)],
        _entries = entries,
        _hadith = hadith {
    final int n = entries.length;
    final Map<String, int> df = <String, int>{};
    for (final _Entry e in entries) {
      for (final String t in e.terms) {
        df[t] = (df[t] ?? 0) + 1;
      }
    }
    for (final MapEntry<String, int> e in df.entries) {
      _idf[e.key] = math.log(1 + n / e.value);
    }
  }

  /// Builds the corpus from the two JSON documents. Pure, so tests do not
  /// need the asset bundle.
  factory HadiCorpus.fromJson({
    required Map<String, dynamic> corpus,
    required List<dynamic> quran,
  }) {
    final List<List<List<String>>> verses = <List<List<String>>>[];
    final List<String> surahNames = <String>[];
    for (final dynamic s in quran) {
      final Map<String, dynamic> surah = s as Map<String, dynamic>;
      surahNames.add(surah['tl'] as String? ?? '');
      final List<dynamic> vs = surah['v'] as List<dynamic>;
      final List<List<String>> rows = <List<String>>[];
      for (final dynamic v in vs) {
        final List<dynamic> row = v as List<dynamic>;
        rows.add(<String>[row[1] as String, row[2] as String]);
      }
      verses.add(rows);
    }

    final List<_Entry> entries = <_Entry>[];
    final Map<String, Passage> hadith = <String, Passage>{};

    for (final dynamic q in corpus['quran'] as List<dynamic>) {
      final Map<String, dynamic> m = q as Map<String, dynamic>;
      final String ref = m['ref'] as String;
      final List<String> topics = <String>[
        for (final dynamic t in m['topics'] as List<dynamic>) t as String,
      ];
      entries.add(_Entry(id: 'q:$ref', topics: topics, text: ''));
    }

    for (final dynamic h in corpus['hadith'] as List<dynamic>) {
      final Map<String, dynamic> m = h as Map<String, dynamic>;
      final String id = m['id'] as String;
      final Passage p = Passage(
        id: id,
        kind: PassageKind.hadith,
        reference: '${m['collection']} ${m['number']}',
        english: m['english'] as String,
        collection: m['collection'] as String,
        number: m['number'] as String,
        grade: m['grade'] as String?,
        grader: m['grader'] as String?,
        textKind: m['textKind'] as String?,
        verifiedOn: m['verifiedOn'] as String?,
        verifiedAt: m['verifiedAt'] as String?,
      );
      hadith[id] = p;
      entries.add(
        _Entry(
          id: id,
          topics: <String>[
            for (final dynamic t in m['topics'] as List<dynamic>) t as String,
          ],
          text: p.english,
        ),
      );
    }

    return HadiCorpus._(
      verses: verses,
      surahNames: surahNames,
      entries: entries,
      hadith: hadith,
      checked: corpus['checked'] as String? ?? '',
    );
  }

  /// The day the corpus was last read against its sources.
  final String checked;

  /// The most ayat one passage may span.
  static const int maxRange = 10;

  final List<List<List<String>>> _verses;
  final List<String> _surahKeys;
  final List<_Entry> _entries;
  final Map<String, Passage> _hadith;
  final Map<String, double> _idf = <String, double>{};

  /// Every ID the retriever can offer (not every ID that can be resolved:
  /// any real ayah range can be resolved).
  List<String> get offeredIds => <String>[for (final _Entry e in _entries) e.id];

  /// The corpus hadith.
  List<Passage> get hadith => _hadith.values.toList();

  static final RegExp _quranId = RegExp(r'^q:(\d{1,3}):(\d{1,3})(?:-(\d{1,3}))?$');

  /// The passage for [id], or null when it does not resolve.
  Passage? resolve(String id) {
    final String key = id.trim().toLowerCase();
    if (key.startsWith('q:')) {
      final RegExpMatch? m = _quranId.firstMatch(key);
      if (m == null) return null;
      final int surah = int.parse(m.group(1)!);
      final int from = int.parse(m.group(2)!);
      final String? toRaw = m.group(3);
      final int to = toRaw == null ? from : int.parse(toRaw);
      return quranRange(surah, from, to);
    }
    return _hadith[key];
  }

  /// A run of ayat from one surah, printed from the bundled text. Null when
  /// the surah or an ayah does not exist or the run is longer than
  /// [maxRange].
  Passage? quranRange(int surah, int from, int to) {
    if (surah < 1 || surah > _verses.length) return null;
    final List<List<String>> rows = _verses[surah - 1];
    if (from < 1 || to < from || to > rows.length) return null;
    if (to - from + 1 > maxRange) return null;
    final bool single = from == to;
    final StringBuffer ar = StringBuffer();
    final StringBuffer en = StringBuffer();
    for (int a = from; a <= to; a++) {
      final List<String> row = rows[a - 1];
      if (a > from) {
        ar.write(' ');
        en.write(' ');
      }
      ar.write(row[0]);
      if (!single) en.write('($surah:$a) ');
      en.write(row[1].trim());
    }
    final String span = single ? '$from' : '$from–$to';
    return Passage(
      id: single ? 'q:$surah:$from' : 'q:$surah:$from-$to',
      kind: PassageKind.quran,
      reference: 'Qur’an $surah:$span',
      english: en.toString(),
      arabic: ar.toString(),
    );
  }

  static String _letters(String s) =>
      s.toLowerCase().replaceAll(RegExp('[^a-z]'), '');

  /// A surah's name without its article and a closing "h", so "Al-Baqarah",
  /// "Baqarah" and "Baqara" are one key.
  static String _bareName(String letters) {
    String s = letters;
    for (final String a in <String>[
      'adh', 'ath', 'ash', 'al', 'an', 'ar', 'as', 'at', 'az', 'ad',
    ]) {
      if (s.startsWith(a) && s.length > a.length + 2) {
        s = s.substring(a.length);
        break;
      }
    }
    if (s.endsWith('h') && s.length > 4) s = s.substring(0, s.length - 1);
    return s;
  }

  /// The number of a surah named in free text ("Al-Baqarah", "Baqara", "2"),
  /// or null when it is not a surah of the bundled Qur'an.
  int? surahNumber(String name) {
    final String trimmed = name.trim();
    final int? digits = int.tryParse(trimmed);
    if (digits != null) {
      return digits >= 1 && digits <= _surahKeys.length ? digits : null;
    }
    final String k = _letters(trimmed);
    if (k.isEmpty) return null;
    if (k == 'imran' || k == 'aliimran' || k == 'aalimran') return 3;
    final String bare = _bareName(k);
    for (int i = 0; i < _surahKeys.length; i++) {
      final String key = _surahKeys[i];
      if (key.isEmpty) continue;
      if (key == k || _bareName(key) == bare) return i + 1;
    }
    return null;
  }

  /// The corpus hadith for a free-typed reference such as `Bukhari` + `1303`.
  Passage? hadithByRef(String book, String number) {
    final String b = bookKey(book);
    final String n = number.trim();
    for (final Passage p in _hadith.values) {
      if (bookKey(p.collection ?? '') == b && p.number == n) return p;
    }
    return null;
  }

  /// Folds spellings of a collection's name to one key.
  static String bookKey(String book) {
    String s = book.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    for (final String prefix in <String>['sahih', 'sunan', 'jami', 'musnad']) {
      if (s.startsWith(prefix) && s.length > prefix.length) {
        s = s.substring(prefix.length);
      }
    }
    for (final String prefix in <String>['al', 'an', 'at']) {
      if (s.startsWith(prefix) && s.length > prefix.length + 3) {
        s = s.substring(prefix.length);
      }
    }
    if (s.startsWith('abudaw') || s.startsWith('abidaw')) return 'abudawud';
    if (s.startsWith('nasa')) return 'nasai';
    return s;
  }

  // ── Retrieval ──────────────────────────────────────────────────────

  static const Set<String> _stop = <String>{
    'the', 'and', 'for', 'are', 'was', 'were', 'with', 'that', 'this',
    'have', 'has', 'had', 'you', 'your', 'not', 'but', 'what', 'how',
    'why', 'when', 'who', 'does', 'did', 'can', 'could', 'would', 'should',
    'about', 'from', 'into', 'there', 'their', 'they', 'them', 'his', 'her',
    'him', 'she', 'its', 'our', 'out', 'any', 'all', 'one', 'get', 'got',
    'let', 'say', 'said', 'tell', 'give', 'please', 'islam', 'islamic',
    'muslim', 'allah', 'quran', 'hadith', 'ayah', 'verse', 'want', 'need',
    'feel', 'feeling', 'like', 'just', 'really', 'very', 'much', 'more',
  };

  /// Words a person types mapped to the topic words the corpus uses.
  static const Map<String, List<String>> _synonyms = <String, List<String>>{
    'anxious': <String>['anxiety', 'worry', 'hardship', 'ease', 'peace'],
    'anxiety': <String>['worry', 'hardship', 'ease', 'peace'],
    'worried': <String>['worry', 'anxiety', 'hardship', 'ease'],
    'worry': <String>['anxiety', 'hardship', 'ease', 'peace'],
    'stress': <String>['anxiety', 'hardship', 'ease'],
    'stressed': <String>['anxiety', 'hardship', 'ease'],
    'panic': <String>['anxiety', 'peace', 'remembrance'],
    'overwhelmed': <String>['burden', 'capacity', 'hardship'],
    'sad': <String>['grief', 'despair', 'hope', 'hardship'],
    'depressed': <String>['grief', 'despair', 'hope', 'hardship'],
    'depression': <String>['grief', 'despair', 'hope', 'hardship'],
    'hopeless': <String>['despair', 'hope', 'relief', 'mercy'],
    'unhappy': <String>['grief', 'hope', 'hardship'],
    'lonely': <String>['lonely', 'alone', 'near', 'wherever'],
    'alone': <String>['lonely', 'alone', 'near', 'wherever'],
    'loneliness': <String>['lonely', 'alone', 'near'],
    'sin': <String>['sins', 'repentance', 'forgiveness'],
    'sinned': <String>['sins', 'repentance', 'forgiveness'],
    'sins': <String>['repentance', 'forgiveness'],
    'guilty': <String>['guilt', 'repentance', 'forgiveness'],
    'guilt': <String>['repentance', 'forgiveness', 'mercy'],
    'regret': <String>['repentance', 'forgiveness', 'guilt'],
    'ashamed': <String>['shame', 'repentance', 'forgiveness'],
    'repent': <String>['repentance', 'tawbah', 'forgiveness'],
    'tawbah': <String>['repentance', 'forgiveness'],
    'angry': <String>['anger', 'restrain', 'pardon'],
    'anger': <String>['restrain', 'pardon', 'forgive'],
    'furious': <String>['anger', 'restrain'],
    'mom': <String>['parents', 'mother'],
    'dad': <String>['parents', 'father'],
    'mother': <String>['parents'],
    'father': <String>['parents'],
    'parent': <String>['parents'],
    'marriage': <String>['marriage', 'spouse', 'wives'],
    'married': <String>['marriage', 'spouse'],
    'husband': <String>['marriage', 'husband', 'wives'],
    'wife': <String>['marriage', 'wife', 'spouse'],
    'spouse': <String>['marriage', 'spouse'],
    'death': <String>['death', 'grief'],
    'dying': <String>['death', 'grief'],
    'died': <String>['death', 'grief', 'loss'],
    'grieving': <String>['grief', 'tears', 'loss'],
    'mourning': <String>['grief', 'tears', 'loss'],
    'job': <String>['provision', 'rizq', 'trust'],
    'money': <String>['provision', 'rizq', 'trust'],
    'rizq': <String>['provision', 'trust'],
    'income': <String>['provision', 'rizq'],
    'poor': <String>['provision', 'trust'],
    'debt': <String>['provision', 'trust', 'worry'],
    'patience': <String>['patience', 'sabr'],
    'patient': <String>['patience', 'sabr'],
    'afraid': <String>['fear', 'trust'],
    'scared': <String>['fear', 'trust'],
    'fear': <String>['fear', 'trust'],
    'pray': <String>['prayer', 'salah'],
    'prayer': <String>['prayer', 'salah'],
    'salah': <String>['prayer'],
    'namaz': <String>['prayer'],
    'fast': <String>['fasting', 'ramadan'],
    'fasting': <String>['fasting', 'ramadan'],
    'ramadan': <String>['fasting', 'ramadan'],
    'charity': <String>['charity', 'spend', 'sadaqah'],
    'sadaqah': <String>['charity', 'spend'],
    'zakat': <String>['zakah', 'charity'],
    'learn': <String>['knowledge', 'learning'],
    'study': <String>['knowledge', 'learning'],
    'knowledge': <String>['knowledge', 'learning'],
    'forgive': <String>['forgiveness', 'forgive'],
    'forgiveness': <String>['forgiveness', 'mercy'],
    'dua': <String>['dua', 'supplication'],
    'supplication': <String>['dua'],
    'gratitude': <String>['gratitude', 'grateful', 'thankful'],
    'grateful': <String>['gratitude', 'thankful'],
    'thankful': <String>['gratitude', 'grateful'],
    'neighbour': <String>['neighbor', 'neighbour'],
    'neighbor': <String>['neighbor', 'neighbour'],
    'gossip': <String>['backbite', 'gossip', 'suspicion'],
    'backbiting': <String>['backbite', 'gossip'],
    'remember': <String>['remembrance', 'dhikr'],
    'dhikr': <String>['remembrance', 'dhikr'],
  };

  static String _stem(String w) {
    if (w.length > 5 && w.endsWith('ing')) return w.substring(0, w.length - 3);
    if (w.length > 4 && w.endsWith('ed')) return w.substring(0, w.length - 2);
    if (w.length > 3 && w.endsWith('s') && !w.endsWith('ss')) {
      return w.substring(0, w.length - 1);
    }
    return w;
  }

  static Set<String> _terms(Iterable<String> words) {
    final Set<String> out = <String>{};
    for (final String raw in words) {
      final String w = raw.toLowerCase();
      if (w.length < 3 || _stop.contains(w)) continue;
      out.add(_stem(w));
    }
    return out;
  }

  static List<String> _words(String s) => <String>[
        for (final RegExpMatch m in RegExp('[a-zA-Z]+').allMatches(s))
          m.group(0)!,
      ];

  /// The passages most related to [query], best first. Empty when nothing
  /// scores: then Hādi has nothing in its library for the question and must
  /// not pretend it does.
  List<Passage> retrieve(String query, {int limit = 4}) {
    final List<String> words = _words(query);
    final Set<String> q = _terms(words);
    for (final String w in words) {
      final List<String>? extra = _synonyms[w.toLowerCase()];
      if (extra != null) q.addAll(_terms(extra));
    }
    if (q.isEmpty) return const <Passage>[];
    final List<_Scored> scored = <_Scored>[];
    for (final _Entry e in _entries) {
      double score = 0;
      bool topicHit = false;
      for (final String t in q) {
        if (e.terms.contains(t)) {
          final bool onTopic = e.topicTerms.contains(t);
          topicHit = topicHit || onTopic;
          score += (_idf[t] ?? 1) * (onTopic ? 2 : 1);
        }
      }
      // A passage is offered only when the question touches one of its
      // topics; a stray word in its body is not enough.
      if (topicHit && score >= 1.5) scored.add(_Scored(e.id, score));
    }
    scored.sort((_Scored a, _Scored b) {
      final int c = b.score.compareTo(a.score);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
    final List<Passage> out = <Passage>[];
    for (final _Scored s in scored) {
      final Passage? p = resolve(s.id);
      if (p != null) out.add(p);
      if (out.length >= limit) break;
    }
    return out;
  }

  /// What the model is shown for each passage it may cite: the ID to write,
  /// the citation and a shortened text. The model writes only the ID.
  static String describeForModel(Passage p) {
    String text = p.english;
    if (text.length > 240) text = '${text.substring(0, 237)}...';
    return '[[src:${p.id}]] ${p.reference}: $text';
  }
}

class _Entry {
  _Entry({required this.id, required List<String> topics, required String text})
      : topicTerms = HadiCorpus._terms(topics),
        terms = <String>{
          ...HadiCorpus._terms(topics),
          ...HadiCorpus._terms(HadiCorpus._words(text)),
        };

  final String id;
  final Set<String> topicTerms;
  final Set<String> terms;
}

class _Scored {
  const _Scored(this.id, this.score);
  final String id;
  final double score;
}

/// The bundled corpus, loaded once. Falls back to an empty corpus (nothing
/// can then be cited) if an asset cannot be read, so Hādi never fails.
final FutureProvider<HadiCorpus> hadiCorpusProvider =
    FutureProvider<HadiCorpus>((ref) => HadiCorpusLoader.load());

abstract final class HadiCorpusLoader {
  static Future<HadiCorpus>? _cached;

  static Future<HadiCorpus> load() => _cached ??= _read();

  static Future<HadiCorpus> _read() async {
    try {
      final String c = await rootBundle.loadString('assets/noor/hadi_corpus.json');
      final String q = await rootBundle.loadString('assets/quran/quran.json');
      return HadiCorpus.fromJson(
        corpus: json.decode(c) as Map<String, dynamic>,
        quran: json.decode(q) as List<dynamic>,
      );
    } catch (_) {
      return HadiCorpus.fromJson(
        corpus: <String, dynamic>{
          'quran': <dynamic>[],
          'hadith': <dynamic>[],
          'checked': '',
        },
        quran: <dynamic>[],
      );
    }
  }
}
