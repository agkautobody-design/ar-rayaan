/// Local retrieval over the app's own verified packs (the Huda worship
/// guides and the curated Q&A bank): a tokenised, normalised, alias-aware,
/// fuzzy index with a confidence score.
///
/// EXTRACTIVE ONLY. An answer is built by quoting an existing entry (its
/// title, its own steps or answer, and its own source line). Nothing is
/// written by this file and nothing is paraphrased: if no entry is close
/// enough, [LocalKnowledge.find] returns a low-confidence match (shown as
/// "closest in my library") or nothing, and Hādi never guesses.
///
/// Pure Dart: no Flutter, no network, deterministic, fully testable.
library;

import 'dart:math' as math;

/// The story packs the index reads (file names under assets/stories/, no
/// extension). Khutbahs are left out: they are sermons, not answers.
const List<String> kHadiKnowledgeStoryPacks = <String>[
  'prophets', 'companions', 'women', 'seerah', 'ghayb', 'signs', 'tales',
  'dailyduas', 'newmuslim', 'modernhadith',
];

/// One entry of the library this index can quote.
class KnowledgeEntry {
  const KnowledgeEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.source,
    this.route,
    this.note = '',
    this.category = '',
  });

  /// Stable id: a guide id (`huda-wudu`) or `qa:<n>`.
  final String id;

  /// 'guide' or 'qa'.
  final String kind;
  final String title;
  final String subtitle;

  /// The entry's own lines, verbatim (guide steps, or the one QA answer).
  final List<String> body;

  /// The entry's own source line, verbatim.
  final String source;

  /// Where the full entry lives in the app (a route Hādi may open).
  final String? route;

  /// The entry's own note on differences between schools, verbatim.
  final String note;
  final String category;
}

/// A match, with how sure the index is that it answers the question.
class KnowledgeMatch {
  const KnowledgeMatch(
    this.entry,
    this.confidence, {
    this.strong = 0,
    this.titleCoverage = 0,
    this.order = 0,
  });
  final KnowledgeEntry entry;

  /// The share (0 to 1) of the question's weight covered by the entry's
  /// title or subtitle words, not by words deep in its body.
  final double strong;

  /// The share of the entry's own title words that the question contains.
  final double titleCoverage;

  /// Position in the pack, for a stable tie-break.
  final int order;

  /// 0 to 1: the share of the question's meaningful words (weighted by how
  /// rare they are) that this entry's title, subtitle, question or topic
  /// covers.
  final double confidence;
}

class LocalKnowledge {
  LocalKnowledge._(this.entries) {
    final int n = entries.length;
    for (final KnowledgeEntry e in entries) {
      final Map<String, double> w = <String, double>{};
      void add(String text, double weight) {
        for (final String t in tokens(text)) {
          if (weight > (w[t] ?? 0)) w[t] = weight;
        }
      }

      final Set<String> tt = tokens(e.title).toSet();
      if (e.kind == 'guide') tt.addAll(tokens(e.id.replaceAll('-', ' ')));
      _titleTerms.add(tt);
      add(e.title, 3);
      add(e.subtitle, 2);
      add(e.category, 1);
      if (e.kind == 'guide') add(e.id.replaceAll('-', ' '), 3);
      if (e.kind != 'story') {
        for (final String line in e.body) {
          add(line, 0.5);
        }
      }
      _weights.add(w);
    }
    final Map<String, int> df = <String, int>{};
    for (final Map<String, double> w in _weights) {
      for (final String t in w.keys) {
        df[t] = (df[t] ?? 0) + 1;
      }
    }
    for (final MapEntry<String, int> e in df.entries) {
      _idf[e.key] = math.log(1 + n / e.value);
    }
    _unseen = math.log(1 + n.toDouble());
    _vocab = _idf.keys.toList();
  }

  /// Builds the index from the two pack documents (already decoded).
  factory LocalKnowledge.fromJson({
    required List<dynamic> guides,
    required List<dynamic> qa,
    List<dynamic> stories = const <dynamic>[],
  }) {
    final List<KnowledgeEntry> out = <KnowledgeEntry>[];
    for (final dynamic g in guides) {
      if (g is! Map) continue;
      final Object? id = g['id'];
      final Object? title = g['title'];
      final Object? steps = g['steps'];
      if (id is! String || title is! String || steps is! List) continue;
      final Object? sources = g['sources'];
      out.add(
        KnowledgeEntry(
          id: id,
          kind: 'guide',
          title: title,
          subtitle: g['subtitle'] is String ? g['subtitle'] as String : '',
          body: <String>[
            for (final dynamic s in steps)
              if (s is String) s,
          ],
          source: sources is List
              ? sources.whereType<String>().join('; ')
              : '',
          route: '/huda/guide?id=$id',
          note: g['madhhabNote'] is String ? g['madhhabNote'] as String : '',
          category: g['category'] is String ? g['category'] as String : '',
        ),
      );
    }
    int i = 0;
    for (final dynamic e in qa) {
      i++;
      if (e is! Map) continue;
      final Object? q = e['q'];
      final Object? a = e['a'];
      if (q is! String || a is! String) continue;
      out.add(
        KnowledgeEntry(
          id: 'qa:$i',
          kind: 'qa',
          title: q,
          subtitle: '',
          body: <String>[a],
          source: e['s'] is String ? e['s'] as String : '',
          route: '/academy/qa',
        ),
      );
    }
    for (final dynamic st in stories) {
      if (st is! Map) continue;
      final Object? id = st['id'];
      final Object? title = st['title'];
      final Object? chapters = st['chapters'];
      if (id is! String || title is! String || chapters is! List) continue;
      if (chapters.isEmpty || chapters.first is! Map) continue;
      final Map<dynamic, dynamic> ch = chapters.first as Map<dynamic, dynamic>;
      final Object? text = ch['body'];
      if (text is! String || text.trim().isEmpty) continue;
      final String label = (ch['label'] is String
              ? ch['label'] as String
              : (st['sourceLabel'] is String
                  ? st['sourceLabel'] as String
                  : ''))
          .trim();
      final Object? srcs = st['sources'];
      out.add(
        KnowledgeEntry(
          id: id,
          kind: 'story',
          title: title,
          subtitle: st['subtitle'] is String ? st['subtitle'] as String : '',
          body: <String>[_excerpt(text)],
          source: srcs is List
              ? srcs.whereType<String>().take(3).join('; ')
              : '',
          route: '/stories',
          note: _labelNote(label),
          category: <String>[
            if (st['kicker'] is String) st['kicker'] as String,
            if (st['hisnCategory'] is String) st['hisnCategory'] as String,
          ].join(' '),
        ),
      );
    }
    return LocalKnowledge._(out);
  }

  /// The first [maxExcerpt] characters of a story chapter, cut at a sentence
  /// end. A verbatim cut, never a rewrite.
  static const int maxExcerpt = 700;

  static String _excerpt(String t) {
    final String s = t.trim();
    if (s.length <= maxExcerpt) return s;
    final String cut = s.substring(0, maxExcerpt);
    int end = -1;
    for (final String m in <String>['. ', '! ', '? ']) {
      final int i = cut.lastIndexOf(m);
      if (i > end) end = i;
    }
    return end > 200 ? cut.substring(0, end + 1) : cut.trimRight();
  }

  /// What the story's own label means for the reader, in words the app
  /// already uses. Established stories need no note.
  static String _labelNote(String label) {
    if (label.contains('not checked')) {
      return 'Unverified: the source for this report has not been checked.';
    }
    if (label == 'Reflection' || label == 'Interpretive') {
      return 'This is a reflection, not a ruling.';
    }
    return '';
  }

  final List<KnowledgeEntry> entries;
  final List<Map<String, double>> _weights = <Map<String, double>>[];
  final List<Set<String>> _titleTerms = <Set<String>>[];
  final Map<String, double> _idf = <String, double>{};
  late final double _unseen;
  late final List<String> _vocab;

  /// Confidence at or above which Hādi answers from this index alone.
  static const double answerThreshold = 0.72;

  /// Confidence at or above which an entry is offered as "closest".
  static const double closestThreshold = 0.5;

  // ── Text handling ──────────────────────────────────────────────────

  static const Set<String> _stop = <String>{
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'am', 'be', 'do', 'does',
    'did', 'i', 'me', 'my', 'we', 'us', 'our', 'you', 'your', 'it', 'its',
    'this', 'that', 'these', 'those', 'how', 'what', 'whats', 'when', 'where',
    'why', 'which', 'who', 'whom', 'to', 'of', 'in', 'on', 'at', 'for', 'and',
    'or', 'but', 'with', 'about', 'from', 'by', 'as', 'can', 'could', 'should',
    'would', 'will', 'shall', 'may', 'must', 'tell', 'please', 'give', 'show',
    'explain', 'need', 'want', 'wanna', 'know', 'learn', 'like', 'help',
    'something', 'anything', 'some', 'any', 'there', 'then', 'so', 'if',
    'not', 'no', 'yes', 'u', 'ur', 'im', 'ive', 'dont', 'cant', 'hadi',
    'islamic', 'muslim', 'steps', 'step', 'way', 'guide', 'rule',
    'rules', 'meaning', 'mean', 'means', 'define', 'definition', 'info',
    'information', 'basics', 'basic', 'beginner', 'beginners', 'easy',
    'simple', 'quick', 'thing', 'things', 'one', 'get', 'make', 'makes',
    'made', 'use', 'using', 'doing', 'done', 'go', 'going', 'let', 'lets',
    'story', 'stories', 'making', 'taking', 'having', 'being', 'getting', 'giving', 'saying',
    'telling', 'showing', 'learning', 'knowing', 'wanting', 'looking',
    'find', 'finding',
  };

  /// Spelling variants people actually type, folded to one form. Spelling
  /// only: no meaning is added here.
  static const Map<String, String> _alias = <String, String>{
    'wudhu': 'wudu', 'wuzu': 'wudu', 'wudoo': 'wudu', 'ablution': 'wudu',
    'ablutions': 'wudu', 'wudu': 'wudu',
    'salat': 'salah', 'salaah': 'salah', 'namaz': 'salah', 'namaaz': 'salah',
    'salah': 'salah',
    'ramadhan': 'ramadan', 'ramazan': 'ramadan', 'ramdan': 'ramadan',
    'zakah': 'zakat', 'zakaat': 'zakat', 'zakāt': 'zakat',
    'tahajud': 'tahajjud', 'tahajjud': 'tahajjud', 'qiyam': 'tahajjud',
    'umra': 'umrah', 'omra': 'umrah',
    'haj': 'hajj', 'hadj': 'hajj',
    'hadees': 'hadith', 'hadeeth': 'hadith', 'hadiths': 'hadith',
    'quraan': 'quran', 'koran': 'quran', 'quran': 'quran',
    'jannat': 'jannah', 'janna': 'jannah',
    'sadaqa': 'sadaqah', 'sadqa': 'sadaqah', 'sadaqat': 'sadaqah',
    'fidya': 'fidyah', 'fidyah': 'fidyah',
    'itikaf': 'itikaf', 'itikaaf': 'itikaf', 'etikaf': 'itikaf',
    'istikhara': 'istikhara', 'istikharah': 'istikhara',
    'tarawih': 'taraweeh', 'taraweh': 'taraweeh', 'taraweeh': 'taraweeh',
    'ghusal': 'ghusl', 'ghusl': 'ghusl', 'janaba': 'ghusl',
    'tayamum': 'tayammum', 'tayammum': 'tayammum',
    'janaza': 'janazah', 'jenazah': 'janazah', 'janazah': 'janazah',
    'nikkah': 'nikah', 'nikah': 'nikah', 'marriage': 'nikah',
    'married': 'nikah', 'wedding': 'nikah',
    'tawbah': 'tawba', 'tauba': 'tawba', 'taubah': 'tawba', 'tawba': 'tawba',
    'repent': 'tawba', 'repentance': 'tawba',
    'azan': 'adhan', 'adhaan': 'adhan', 'athan': 'adhan', 'adhan': 'adhan',
    'jumah': 'jumuah', 'juma': 'jumuah', 'jummah': 'jumuah',
    'jumuah': 'jumuah', 'friday': 'jumuah',
    'masjid': 'mosque', 'masjids': 'mosque', 'mosque': 'mosque',
    'rakat': 'rakah', 'rakah': 'rakah', 'rakaat': 'rakah', 'rakats': 'rakah',
    'rakahs': 'rakah',
    'sunnat': 'rawatib', 'sunan': 'rawatib', 'rawatib': 'rawatib',
    'roza': 'fasting', 'roze': 'fasting', 'sawm': 'fasting',
    'siyam': 'fasting', 'fast': 'fasting', 'fasts': 'fasting',
    'fasting': 'fasting',
    'pray': 'salah', 'prayer': 'salah', 'prayers': 'salah', 'praying': 'salah',
    'prays': 'salah',
    'kid': 'children', 'kids': 'children', 'child': 'children',
    'son': 'children', 'daughter': 'children', 'toddler': 'children',
    'mum': 'parents', 'mom': 'parents', 'mother': 'parents',
    'dad': 'parents', 'father': 'parents', 'parent': 'parents',
    'travelling': 'travel', 'traveling': 'travel', 'journey': 'travel',
    'trip': 'travel', 'traveller': 'travel', 'traveler': 'travel',
    'sleep': 'sleeping', 'sleeping': 'sleeping', 'bed': 'sleeping',
    'bedtime': 'sleeping',
    'eat': 'eating', 'eating': 'eating', 'food': 'eating', 'meal': 'eating',
    'sick': 'illness', 'ill': 'illness', 'sickness': 'illness',
    'illness': 'illness',
    'died': 'deceased', 'dead': 'deceased', 'deceased': 'deceased',
    'funeral': 'janazah', 'burial': 'burial', 'burying': 'burial',
    'baby': 'baby', 'newborn': 'baby', 'aqiqah': 'baby', 'aqeeqah': 'baby',
    'convert': 'islam', 'revert': 'islam', 'shahada': 'islam',
    'shahadah': 'islam',
    'sunnah': 'sunnah', 'sin': 'sin', 'sins': 'sin',
    'waswas': 'waswas', 'whispers': 'waswas', 'whisper': 'waswas',
    'wasawis': 'waswas',
    'ihram': 'ihram', 'ehram': 'ihram',
    'tawaf': 'tawaf', 'sai': 'tawaf', 'saee': 'tawaf',
    'arafah': 'arafat', 'arafat': 'arafat',
  };

  static String _stem(String t) {
    if (t.length > 5 && t.endsWith('ing')) return t.substring(0, t.length - 3);
    if (t.length > 4 && t.endsWith('ies')) return '${t.substring(0, t.length - 3)}y';
    if (t.length > 4 && t.endsWith('es') && !t.endsWith('ses')) {
      return t.substring(0, t.length - 2);
    }
    if (t.length > 3 && t.endsWith('s') && !t.endsWith('ss')) {
      return t.substring(0, t.length - 1);
    }
    return t;
  }

  /// The meaningful, normalised words of [text].
  static List<String> tokens(String text) {
    final String s = text
        .toLowerCase()
        .replaceAll(RegExp('[’‘\'`ʿʾ]'), '')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    final List<String> out = <String>[];
    for (final String raw in s.split(RegExp(r'\s+'))) {
      if (raw.length < 2 || _stop.contains(raw)) continue;
      final String a = _alias[raw] ?? raw;
      final String t = _alias[a] ?? _stem(_stem(a));
      if (t.length < 2 || _stop.contains(t)) continue;
      out.add(t);
    }
    return out;
  }

  // ── Retrieval ──────────────────────────────────────────────────────

  static bool _within1(String a, String b) {
    if ((a.length - b.length).abs() > 1) return false;
    int i = 0;
    int j = 0;
    int edits = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) {
        i++;
        j++;
        continue;
      }
      edits++;
      if (edits > 1) return false;
      if (a.length > b.length) {
        i++;
      } else if (a.length < b.length) {
        j++;
      } else {
        i++;
        j++;
      }
    }
    return edits + (a.length - i) + (b.length - j) <= 1;
  }

  /// A question term as it exists in the index: itself, or (for words of
  /// five letters or more) a vocabulary word one typo away.
  String? _resolve(String t) {
    if (_idf.containsKey(t)) return t;
    if (t.length < 5) return null;
    for (final String v in _vocab) {
      if (v.length >= 5 && _within1(t, v)) return v;
    }
    return null;
  }

  /// True for a question that asks WHERE something is in the app, or for a
  /// time or a nearby place. Those go to the screen that does it, never to
  /// a library entry that merely shares a word.
  static bool looksLikeLookup(String question) => RegExp(
        r'\b(?:find|locate|finder|times?|near|nearby|nearest|where|open|'
        r'show|download|app|settings?|button|screen|page|bookmarks?|search|'
        r'listen|play|watch|calculator|calculate|names? of allah|'
        r'(?:what|who) (?:is|are) (?:al|ar|ad|as|an|ash) )\b',
        caseSensitive: false,
      ).hasMatch(question);

  static int _rank(String kind) => kind == 'guide' ? 0 : (kind == 'qa' ? 1 : 2);

  /// The best matches for [question], best first, each with a confidence.
  /// Empty when the question has no meaningful word.
  List<KnowledgeMatch> find(String question, {int limit = 3}) {
    final List<String> raw = tokens(question).toSet().toList();
    if (raw.isEmpty || entries.isEmpty) return const <KnowledgeMatch>[];
    final List<String> terms = <String>[];
    final List<double> idf = <double>[];
    double total = 0;
    for (final String t in raw) {
      final String? r = _resolve(t);
      terms.add(r ?? t);
      final double i = r == null ? _unseen : (_idf[r] ?? _unseen);
      idf.add(i);
      total += i;
    }
    if (total <= 0) return const <KnowledgeMatch>[];
    final List<KnowledgeMatch> scored = <KnowledgeMatch>[];
    for (int e = 0; e < entries.length; e++) {
      final Map<String, double> w = _weights[e];
      double got = 0;
      double strongGot = 0;
      for (int k = 0; k < terms.length; k++) {
        final double tw = w[terms[k]] ?? 0;
        if (tw <= 0) continue;
        got += idf[k] * math.min(tw, 3) / 3;
        if (tw >= 2) strongGot += idf[k];
      }
      // A question covered only by words deep in the body is not an answer.
      double conf = got / total;
      final double strong = strongGot / total;
      if (strong == 0) conf *= 0.4;
      final Set<String> tt = _titleTerms[e];
      int hit = 0;
      for (final String t in tt) {
        if (terms.contains(t)) hit++;
      }
      final double cover = tt.isEmpty ? 0 : hit / tt.length;
      if (conf > 0) {
        scored.add(
          KnowledgeMatch(
            entries[e],
            conf,
            strong: strong,
            titleCoverage: cover,
            order: e,
          ),
        );
      }
    }
    scored.sort((KnowledgeMatch a, KnowledgeMatch b) {
      final int c = b.confidence.compareTo(a.confidence);
      if (c != 0) return c;
      final int t = b.titleCoverage.compareTo(a.titleCoverage);
      if (t != 0) return t;
      final int r = _rank(a.entry.kind).compareTo(_rank(b.entry.kind));
      return r != 0 ? r : a.order.compareTo(b.order);
    });
    return scored.take(limit).toList();
  }

  /// The one match good enough to answer alone, or null. Requires a margin
  /// over the runner-up so two near-equal entries never produce a guess.
  KnowledgeMatch? confident(String question) {
    final List<KnowledgeMatch> m = find(question, limit: 2);
    if (m.isEmpty) return null;
    final KnowledgeMatch top = m.first;
    if (top.confidence < answerThreshold || top.strong < 0.6) return null;
    // "What does X mean" is a definition. A story that merely has X in its
    // title does not define it.
    if (top.entry.kind == 'story' &&
        RegExp(r'\b(?:meaning|mean|means)\b', caseSensitive: false)
            .hasMatch(question)) {
      return null;
    }
    // A curated Q&A entry is one specific question: the person must have
    // asked most of it.
    if (top.entry.kind == 'qa' && top.titleCoverage < 0.6) return null;
    if (m.length > 1 && m[1].confidence > top.confidence - 0.06) {
      final KnowledgeMatch next = m[1];
      if (next.entry.title == top.entry.title) return top;
      // The question names one entry's title much more fully than the other.
      if (top.titleCoverage - next.titleCoverage >= 0.3) return top;
      // Two guides tie because the question is only the broad topic word
      // ("salah"): the first guide in the pack is the main one.
      if (top.confidence >= 0.95 &&
          top.entry.kind == 'guide' &&
          next.entry.kind != 'qa') {
        return top;
      }
      return null;
    }
    return top;
  }

  /// The closest entry below the answer threshold, or null.
  KnowledgeMatch? closest(String question) {
    final List<KnowledgeMatch> m = find(question, limit: 1);
    if (m.isEmpty ||
        m.first.confidence < closestThreshold ||
        m.first.strong < 0.5) {
      return null;
    }
    return m.first;
  }

  // ── Composition (quotation only) ───────────────────────────────────

  /// Longest answer composed from one entry.
  static const int maxChars = 1400;

  /// The reply for [e]: the entry's own words and its own source line.
  static String compose(KnowledgeEntry e) {
    final StringBuffer b = StringBuffer();
    if (e.kind == 'qa') {
      b.write(e.body.join('\n\n'));
    } else if (e.kind == 'story') {
      b.write(e.title);
      if (e.subtitle.isNotEmpty) b.write('. ${e.subtitle}');
      b.write('.\n');
      if (e.note.isNotEmpty) b.write('\n${e.note}');
      b.write('\n\n${e.body.join('\n\n')}');
      b.write('\n\nThis is the start of the story; the full story is in '
          'Stories.');
    } else {
      b.write(e.title);
      if (e.subtitle.isNotEmpty) b.write('. ${e.subtitle}');
      b.write('.\n');
      int n = 0;
      for (final String s in e.body) {
        if (b.length + s.length > maxChars && n >= 2) break;
        n++;
        b.write('\n$n. $s');
      }
      if (n < e.body.length) {
        b.write('\n\nThere are ${e.body.length - n} more steps in the guide.');
      }
      if (e.note.isNotEmpty && b.length + e.note.length < maxChars + 400) {
        b.write('\n\nSchools of law: ${e.note}');
      }
    }
    if (e.source.isNotEmpty) b.write('\n\nSource: ${e.source}');
    return b.toString();
  }
}
