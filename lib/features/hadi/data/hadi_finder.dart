/// Finds the app's own screens for a question: the "closest topics" under a
/// refusal, and one-line pointers for questions about using the app.
///
/// Pure Dart. Nothing here is religious content: it only names screens that
/// already exist (their titles and keywords come from the Find Anything list
/// in `search/domain/app_destinations.dart`, plus a few plain-word aliases
/// below). It never states a ruling, a hadith or a du'a.
library;

import 'dart:math' as math;

import '../../sakina/domain/crisis_detector.dart';
import '../../search/domain/app_destinations.dart';

/// Every route the finder may offer. Each MUST be on `kHadiNavWhitelist` and
/// have a name in `kHadiRouteNames` (test/hadi_coverage_test.dart checks).
const Set<String> kHadiFinderRoutes = <String>{
  '/qibla', '/prayer', '/huda', '/tasbeeh', '/adhkar', '/games/names99',
  '/calendar', '/masajid', '/family-tree', '/academy/letters',
  '/academy/arabic-language', '/games/trivia', '/games', '/academy/hifz',
  '/academy/recitation', '/zakat', '/ramadan', '/quran', '/quran/bookmarks',
  '/hadith', '/stories', '/academy/seerah', '/new-muslim',
  '/academy/family-life', '/academy/hajj-umrah-pack', '/sakina', '/feelings',
  '/finance', '/share', '/player', '/notes', '/settings/language',
  '/settings', '/search', '/academy/qa', '/academy/aqeedah',
  '/academy/hadith', '/academy/hisn', '/home/elder', '/journey',
  '/academy/quranic-arabic', '/academy', '/explore',
  '/huda/guide?id=huda-nikah',
  '/huda/guide?id=huda-tahajjud',
  '/huda/guide?id=huda-witr',
  '/huda/guide?id=huda-what-is-islam',
  '/huda/guide?id=huda-madhhab-overview',
};

class _Feature {
  _Feature(this.route);
  final String route;

  /// Word -> weight (a keyword counts for more than a word of the title).
  final Map<String, double> words = <String, double>{};
}

/// Plain-word aliases for screens. Only routes; no content.
const Map<String, List<String>> _extras = <String, List<String>>{
  '/stories': <String>[
    'companions', 'sahabah', 'sahabi', 'abu bakr', 'umar', 'uthman', 'ali',
    'khadijah', 'aisha', 'fatimah', 'prophet', 'prophets', 'caliph',
    'caliphs', 'khutbah', 'story', 'tale', 'women',
  ],
  '/academy/seerah': <String>[
    'seerah', 'sirah', 'hijrah', 'migration', 'revelation', 'makkah',
    'madinah', 'muhammad', 'prophet', 'life of the prophet', 'biography',
    'badr', 'uhud', 'mawlid',
  ],
  '/academy/aqeedah': <String>[
    'iman', 'faith', 'belief', 'tawheed', 'tawhid', 'taqwa', 'shirk',
    'angels', 'aqeedah', 'creed', 'jannah', 'jannat', 'paradise', 'qadr',
  ],
  '/academy/hadith': <String>['hadith', 'hadees', 'sahih', 'narrators'],
  '/hadith': <String>['hadith', 'hadees', 'nawawi', 'forty'],
  '/quran': <String>[
    'quran', 'quraan', 'surah', 'ayah', 'verse', 'juz', 'para', 'longest',
    'shortest', 'tafsir', 'recite', 'revelation',
  ],
  '/calendar': <String>[
    'calendar', 'muharram', 'safar', 'rabi', 'rajab', 'shaban', 'shawwal',
    'mawlid', 'milad', 'month', 'hijri', 'date', 'ashura', 'eid',
  ],
  '/ramadan': <String>[
    'ramadan', 'ramadhan', 'ramazan', 'taraweeh', 'iftar', 'suhoor',
    'fasting', 'fast', 'roza',
  ],
  '/huda': <String>[
    'prayer', 'salah', 'salat', 'namaz', 'wudu', 'ghusl', 'tayammum',
    'fasting', 'hajj', 'umrah', 'rakat', 'rakah', 'guide', 'learn to pray',
  ],
  '/academy/hajj-umrah-pack': <String>[
    'hajj', 'umrah', 'umra', 'ihram', 'tawaf', 'sai', 'safa', 'marwa',
    'arafah', 'muzdalifah', 'mina', 'pilgrimage', 'kaaba',
  ],
  '/masajid': <String>[
    'mosque', 'masjid', 'mosques', 'masjids', 'halal', 'restaurant', 'food',
    'nearby', 'jumuah', 'jummah',
  ],
  '/academy/family-life': <String>[
    'marriage', 'nikah', 'husband', 'wife', 'family', 'parents', 'spouse',
    'children', 'kids', 'baby', 'names',
  ],
  '/academy/qa': <String>['question', 'questions', 'answers', 'ask'],
  '/academy/hisn': <String>['dua', 'duas', 'supplication', 'adhkar', 'dhikr'],
  '/adhkar': <String>['dua', 'duas', 'supplication', 'adhkar', 'dhikr'],
  '/games/names99': <String>['names of allah', '99 names', 'asma ul husna'],
  '/new-muslim': <String>['new muslim', 'convert', 'revert', 'shahada'],
  '/academy': <String>['children', 'kids', 'child', 'teach', 'learn', 'school'],
  '/settings': <String>[
    'settings', 'text size', 'font', 'bigger', 'larger', 'notifications',
    'key', 'offline', 'theme', 'dark',
  ],
  '/zakat': <String>['zakat', 'zakah', 'nisab', 'sadaqah', 'charity'],
  '/prayer': <String>['fajr', 'fajar', 'times', 'adhan', 'jumuah', 'jummah'],
};

/// Words that say nothing about the topic.
const Set<String> _stop = <String>{
  'a', 'an', 'the', 'i', 'me', 'my', 'we', 'us', 'our', 'you', 'your', 'he', //
  'she', 'it', 'its', 'his', 'her', 'is', 'am', 'are', 'was', 'were', 'be', //
  'been', 'do', 'does', 'did', 'to', 'of', 'in', 'on', 'at', 'for', 'from', //
  'with', 'by', 'and', 'or', 'if', 'can', 'could', 'would', 'should', //
  'will', 'may', 'might', 'must', 'shall', 'have', 'has', 'had', 'this', //
  'that', 'there', 'as', 'so', 'than', 'about', 'also', 'just', 'please', //
  'what', 'how', 'why', 'who', 'when', 'where', 'which', 'whats', 'tell', //
  'explain', 'know', 'want', 'need', 'something', 'anything', 'near', //
  'nearby', 'islam', 'islamic', 'muslim', 'app', 'show', 'find', 'any', //
  'some', 'more', 'get', 'give', 'help', 'wanna', 'u', 'pls', 'plz', //
};

/// Everyday words that appear in the screens' descriptions but say nothing
/// about what a screen is for ("time" is not Prayer Times, "friend" is not
/// Verse Cards). Ignored when picking the closest screens for a refusal.
const Set<String> _everyday = <String>{
  'time', 'friend', 'day', 'week', 'year', 'life', 'work', 'job', 'home',
  'house', 'people', 'place', 'thing', 'way', 'new', 'good', 'best', 'free',
  'make', 'take', 'look', 'use', 'start', 'stop', 'city', 'plan', 'manage',
  'management', 'lunch', 'dinner', 'weekend', 'today', 'tomorrow', 'person',
  'someone', 'anyone',
};

/// Spellings people type, mapped to the spelling the library uses. Applied to
/// the question only, and only when the library really uses the target.
const Map<String, String> kHadiSpellings = <String, String>{
  'fajar': 'fajr',
  'fjr': 'fajr',
  'umra': 'umrah',
  'umrh': 'umrah',
  'quraan': 'quran',
  'qoran': 'quran',
  'hadees': 'hadith',
  'hadis': 'hadith',
  'hadeeth': 'hadith',
  'hadit': 'hadith',
  'jannat': 'jannah',
  'jenna': 'jannah',
  'tawheed': 'tawhid',
  'tauheed': 'tawhid',
  'tauhid': 'tawhid',
  'wat': 'what',
  'wut': 'what',
  'abt': 'about',
  'ur': 'your',
  'r': 'are',
};

abstract final class HadiFinder {
  static String _norm(String s) => CrisisDetector.normalize(s);

  /// Plural "s" and "-ing" off, as the shelf does.
  static String stem(String w) {
    if (w.length > 5 && w.endsWith('ing')) return w.substring(0, w.length - 3);
    if (w.length > 3 &&
        w.endsWith('s') &&
        !w.endsWith('ss') &&
        !w.endsWith('us') &&
        !w.endsWith('is')) {
      return w.substring(0, w.length - 1);
    }
    return w;
  }

  /// Topic words of [s]: normalised, spelling-fixed, stemmed, no stop words.
  static List<String> words(String s) {
    final String n = _norm(s);
    if (n.isEmpty) return const <String>[];
    final List<String> raw = n.split(' ');
    final List<String> out = <String>[];
    for (int i = 0; i < raw.length; i++) {
      String w = raw[i];
      if (w == '2' && i > 0 && raw[i - 1] == 'how') w = 'to';
      w = kHadiSpellings[w] ?? w;
      if (w.length < 3 || _stop.contains(w)) continue;
      final String st = stem(w);
      if (!_stop.contains(st)) out.add(st);
    }
    return out;
  }

  /// Edit distance with adjacent swaps counted as one edit.
  static int distance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    List<int> prev2 = List<int>.filled(b.length + 1, 0);
    List<int> prev = <int>[for (int j = 0; j <= b.length; j++) j];
    for (int i = 1; i <= a.length; i++) {
      final List<int> cur = List<int>.filled(b.length + 1, 0);
      cur[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final int cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        int v = prev[j - 1] + cost;
        if (prev[j] + 1 < v) v = prev[j] + 1;
        if (cur[j - 1] + 1 < v) v = cur[j - 1] + 1;
        if (i > 1 &&
            j > 1 &&
            a.codeUnitAt(i - 1) == b.codeUnitAt(j - 2) &&
            a.codeUnitAt(i - 2) == b.codeUnitAt(j - 1) &&
            prev2[j - 2] + 1 < v) {
          v = prev2[j - 2] + 1;
        }
        cur[j] = v;
      }
      prev2 = prev;
      prev = cur;
    }
    return prev[b.length];
  }

  /// True when question word [t] is shelf/feature word [v] with a slip: the
  /// same first letter, at least 4 letters, one edit (two for words of 8+).
  /// [strict] asks for 5+ letters when only one edit is allowed.
  static bool near(String t, String v, {bool strict = false}) {
    if (t == v) return true;
    if (t.length < 4 || v.length < 4) return false;
    if (t.codeUnitAt(0) != v.codeUnitAt(0)) return false;
    final int shorter = t.length < v.length ? t.length : v.length;
    if (strict && shorter < 5) return false;
    final int limit = shorter >= 8 ? 2 : 1;
    if ((t.length - v.length).abs() > limit) return false;
    return distance(t, v) <= limit;
  }

  // ── The feature index ────────────────────────────────────────────────

  static final List<_Feature> _features = _buildFeatures();
  static final Map<String, int> _df = _buildDf();

  static void _addWords(_Feature f, String phrase, double weight) {
    for (final String w in words(phrase)) {
      final double have = f.words[w] ?? 0;
      if (weight > have) f.words[w] = weight;
    }
  }

  static List<_Feature> _buildFeatures() {
    final Map<String, _Feature> byRoute = <String, _Feature>{};
    _Feature feat(String route) =>
        byRoute.putIfAbsent(route, () => _Feature(route));
    for (final AppDestination d in kAppDestinations) {
      if (!kHadiFinderRoutes.contains(d.route)) continue;
      final _Feature f = feat(d.route);
      for (final String k in d.keywords) {
        _addWords(f, k, 2);
      }
      _addWords(f, d.title, 1.5);
      _addWords(f, d.subtitle, 0.5);
    }
    _extras.forEach((String route, List<String> list) {
      final _Feature f = feat(route);
      for (final String k in list) {
        _addWords(f, k, 2);
      }
    });
    return byRoute.values.toList();
  }

  static Map<String, int> _buildDf() {
    final Map<String, int> df = <String, int>{};
    for (final _Feature f in _features) {
      for (final String w in f.words.keys) {
        df[w] = (df[w] ?? 0) + 1;
      }
    }
    return df;
  }

  /// The screens closest to [question], best first, at most [limit]. Empty
  /// when nothing in the question resembles any screen. Never includes
  /// Find Anything (the caller always offers it separately).
  static List<String> closestRoutes(String question, {int limit = 3}) {
    final Set<String> qw = words(question)
        .where((String w) => !_everyday.contains(w))
        .toSet();
    if (qw.isEmpty) {
      // "tell me something about islam": all that is left is the word itself.
      return RegExp(r'\bislam\b').hasMatch(_norm(question))
          ? const <String>[
              '/huda/guide?id=huda-what-is-islam',
              '/new-muslim',
            ]
          : const <String>[];
    }
    final List<(double, int, String)> scored = <(double, int, String)>[];
    for (int i = 0; i < _features.length; i++) {
      final _Feature f = _features[i];
      if (f.route == '/search') continue;
      double score = 0;
      for (final String t in qw) {
        double best = 0;
        f.words.forEach((String v, double w) {
          final double idf = 1 / math.sqrt((_df[v] ?? 1).toDouble());
          if (t == v) {
            if (w * idf > best) best = w * idf;
          } else if (near(t, v)) {
            if (w * idf * 0.6 > best) best = w * idf * 0.6;
          }
        });
        score += best;
      }
      if (score > 0) scored.add((score, i, f.route));
    }
    scored.sort(((double, int, String) a, (double, int, String) b) {
      final int c = b.$1.compareTo(a.$1);
      return c != 0 ? c : a.$2.compareTo(b.$2);
    });
    if (scored.isEmpty) return const <String>[];
    // A screen far behind the best one is noise, not a close topic.
    final double floor = scored.first.$1 * 0.5;
    return <String>[
      for (final (double, int, String) s in scored.take(limit))
        if (s.$1 >= floor) s.$3,
    ];
  }

  // ── Questions about using the app ────────────────────────────────────

  /// Words that start a "where is / how do I use" question.
  static const Set<String> _cue = <String>{
    'where', 'find', 'open', 'show', 'take', 'go', 'access', 'use', 'change',
    'set', 'turn', 'make', 'increase', 'enlarge', 'listen', 'play', 'see',
    'view', 'locate', 'reach', 'get', 'start', 'download', 'save',
  };

  static const List<_Pointer> _pointers = <_Pointer>[
    _Pointer(
      <String>['download', 'downloads', 'offline'],
      'Saving the Qur’an, audio and guides for offline use is done on the '
          'Downloads screen.',
      <String>['/downloads'],
      requires: <String>['download', 'downloads', 'offline'],
      unless: <String>[
        'haram', 'halal', 'permissible', 'allowed', 'ruling', 'sin',
        'music', 'movie', 'film', 'song', 'torrent', 'hadi', 'why',
      ],
      bare: true,
    ),
    _Pointer(
      <String>['streak', 'streaks'],
      'A streak counts the days in a row you read, make dhikr or log a '
          'prayer. It is gentle: a missed day is never shown as a failure. '
          'Your streaks are on their own screen.',
      <String>['/streaks'],
      bare: true,
    ),
    _Pointer(
      <String>['tasbeeh', 'tasbih', 'tasbeh', 'tasbi', 'counter', 'rosary'],
      'The Tasbeeh counter has its own screen in the app.',
      <String>['/tasbeeh'],
    ),
    _Pointer(
      <String>['bookmark', 'bookmarks', 'bookmarked'],
      'Your Qur’an bookmarks are on their own list. Stories you save are '
          'kept in your Journey.',
      <String>['/quran/bookmarks', '/journey'],
      unless: <String>['story', 'stories', 'hadith', 'dua', 'verse'],
    ),
    _Pointer(
      <String>['nasheed', 'nasheeds', 'naat', 'naats', 'anasheed'],
      'Nasheeds and naats are in the Nasheed Player.',
      <String>['/player'],
    ),
    _Pointer(
      <String>['size', 'font', 'bigger', 'larger', 'enlarge', 'zoom'],
      'Text size is in Settings, under Text size and Elder Mode.',
      <String>['/settings', '/home/elder'],
    ),
    _Pointer(
      <String>['language', 'languages', 'urdu', 'translation', 'arabic'],
      'Language & Voice is in Settings: tap it to pick a language.',
      <String>['/settings/language'],
      requires: <String>['language', 'languages'],
    ),
    _Pointer(
      <String>['tree', 'genealogy', 'lineage'],
      'The Messengers’ family tree has its own screen.',
      <String>['/family-tree'],
      requires: <String>['tree'],
    ),
    _Pointer(
      <String>['elder', 'elders', 'senior'],
      'Elder Home is a simpler, larger home screen, and the text size is in '
          'Settings.',
      <String>['/home/elder', '/settings'],
    ),
    _Pointer(
      <String>['wasia'],
      'Wasia, the letter teacher, is in the Academy.',
      <String>['/academy/gate'],
    ),
    _Pointer(
      <String>['names', '99'],
      'The 99 Names of Allah has its own screen under Games.',
      <String>['/games/names99'],
      requires: <String>['99'],
    ),
  ];

  /// A one-line pointer with a button when [question] asks where something
  /// in the app is or how to use it, or null. Strict: a question that only
  /// mentions a word is not a request to move.
  static String? pointerReply(String question) {
    final List<String> raw = _norm(question).split(' ');
    if (raw.length > 12 || raw.isEmpty || raw.first.isEmpty) return null;
    final List<String> t = <String>[
      for (final String w in raw) stem(kHadiSpellings[w] ?? w),
    ];
    final bool cued = t.any(_cue.contains);
    for (final _Pointer p in _pointers) {
      if (!cued && !p.bare) continue;
      final bool hit = t.any((String w) => p.aliases.any(
            (String a) => w == a || near(w, a, strict: true),
          ));
      if (!hit) continue;
      if (p.requires.isNotEmpty &&
          !t.any((String w) => p.requires.contains(w))) {
        continue;
      }
      if (t.any(p.unless.contains)) continue;
      return '${p.line}\n${<String>[for (final String r in p.routes) '[GO:$r]'].join('\n')}';
    }
    return null;
  }

  /// The plain line shown once under the first reply when no key is set.
  static const String offlineNote =
      'Hādi is answering from the app’s built-in checked library only.';

  /// Why Hādi is answering only from the built-in library.
  static const String offlineWhy =
      'Hādi is answering from the app’s built-in checked library only, '
      'because no AI key is set. That library is free, works without '
      'internet, and is the only place I take answers from here, so when it '
      'has nothing on a question I say so instead of guessing. A free key '
      'from your own AI account, added in Settings in Hādi’s section, lets '
      'me reason further.\n[GO:/settings]';

  static bool asksWhyOffline(String question) {
    final String n = _norm(question);
    if (n.split(' ').length > 12) return false;
    final bool aboutHadi = RegExp(r'\b(?:hadi|you|u|this)\b').hasMatch(n);
    return aboutHadi &&
        RegExp(r'\b(?:offline|off\s*line|not\s+connected|no\s+internet|'
                r'not\s+live|not\s+online|no\s+ai|no\s+api|without\s+ai)\b')
            .hasMatch(n);
  }

  /// A reply that says how to use the app, for "how do I use this app".
  static const String howToUseReply =
      'Ask me for anything by name and I will point you to its screen, or '
      'open Explore to see every room, or Find Anything to search all of '
      'them. Prayer Times, the Qur’an, Dhikr and Du’a, Stories and the Huda '
      'guides are the usual starting places.\n[GO:/explore]\n[GO:/search]';

  static bool asksHowToUseApp(String question) => RegExp(
        r'^(?:(?:please|hi|hello|salam|hey)\s+)*(?:how\s+(?:do|can|to)\s+'
        r'(?:i\s+)?use\s+(?:this|the)\s+app|how\s+does\s+(?:this|the)\s+app\s+'
        r'work|how\s+to\s+use\s+(?:this|the)\s+app|help\s+me\s+use\s+(?:this|'
        r'the)\s+app|what\s+is\s+this\s+app\s+for|i\s+am\s+lost|im\s+lost|'
        r'i\s+do\s+not\s+know\s+where\s+to\s+start)\s*$',
      ).hasMatch(_norm(question));
}

class _Pointer {
  const _Pointer(
    this.aliases,
    this.line,
    this.routes, {
    this.requires = const <String>[],
    this.unless = const <String>[],
    this.bare = false,
  });
  final List<String> aliases;
  final String line;
  final List<String> routes;

  /// When not empty, the question must also contain one of these.
  final List<String> requires;

  /// When the question contains one of these, the shelf answers instead.
  final List<String> unless;

  /// True when the alias alone is enough: no "where / how do I" cue needed.
  final bool bare;
}
