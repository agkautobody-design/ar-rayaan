/// The shared quiz engine: questions, sessions, hints and the question banks.
///
/// Rules this file keeps:
///  * every question carries a citation and an explanation;
///  * questions come only from the Qur'an text and surah list bundled in the
///    app, or from the app's own story notes that already name a source;
///    nothing is invented here;
///  * no timer, no points, no coins. A hint is free and hides two wrong
///    answers; a game has [kHintsPerGame] of them;
///  * the "Yaseen is the heart of the Qur'an" style of question is not asked:
///    only verbatim text and surah facts are.
///
/// Pure Dart (no Flutter) so it can be checked with a plain Dart SDK.
library;

import 'dart:convert';
import 'dart:math';

import 'game_registry.dart';

/// One multiple-choice question.
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.answer,
    required this.explanation,
    required this.citation,
    this.promptIsArabic = false,
    this.optionsAreArabic = false,
    this.context,
    this.kicker,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        id: j['id'] as String,
        prompt: j['prompt'] as String,
        options: (j['options'] as List<dynamic>).cast<String>(),
        answer: j['answer'] as int,
        explanation: j['explanation'] as String,
        citation: j['citation'] as String,
        promptIsArabic: (j['pa'] as bool?) ?? false,
        optionsAreArabic: (j['oa'] as bool?) ?? false,
        context: j['context'] as String?,
        kicker: j['kicker'] as String?,
      );

  final String id;
  final String prompt;
  final List<String> options;
  final int answer;

  /// Shown after answering: why, in plain words.
  final String explanation;

  /// Shown after answering: where it comes from. Never empty.
  final String citation;
  final bool promptIsArabic;
  final bool optionsAreArabic;

  /// A line above the prompt (the surah, on Easy).
  final String? context;

  /// The small heading over the prompt. When null, an Arabic prompt is headed
  /// "Complete the ayah" and any other prompt has no heading.
  final String? kicker;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'prompt': prompt,
        'options': options,
        'answer': answer,
        'explanation': explanation,
        'citation': citation,
        'pa': promptIsArabic,
        'oa': optionsAreArabic,
        if (context != null) 'context': context,
        if (kicker != null) 'kicker': kicker,
      };
}

/// What the person chose in the setup screen. Travels in the route's query
/// string, so a refresh or a pasted link opens the same setup.
class QuizConfig {
  const QuizConfig({
    required this.gameId,
    this.topic = 'mixed',
    this.count = 10,
    this.difficulty = GameDifficulty.standard,
    this.players = 1,
    this.hints = true,
  });

  factory QuizConfig.fromQuery(String gameId, Map<String, String> q) {
    final int players = int.tryParse(q['players'] ?? '') ?? 1;
    final int count = int.tryParse(q['n'] ?? '') ?? 10;
    return QuizConfig(
      gameId: gameId,
      topic: (q['topic'] ?? '').isEmpty ? 'mixed' : q['topic']!,
      count: count.clamp(1, 30),
      difficulty: GameDifficulty.values.firstWhere(
        (GameDifficulty d) => d.name == q['d'],
        orElse: () => GameDifficulty.standard,
      ),
      players: players.clamp(1, 4),
      hints: q['hints'] != '0',
    );
  }

  final String gameId;
  final String topic;
  final int count;
  final GameDifficulty difficulty;
  final int players;
  final bool hints;

  Map<String, String> toQuery() => <String, String>{
        'topic': topic,
        'n': '$count',
        'd': difficulty.name,
        'players': '$players',
        'hints': hints ? '1' : '0',
      };

  Map<String, dynamic> toJson() => <String, dynamic>{
        'gameId': gameId,
        'topic': topic,
        'count': count,
        'd': difficulty.name,
        'players': players,
        'hints': hints,
      };

  static QuizConfig fromJson(Map<String, dynamic> j) => QuizConfig(
        gameId: j['gameId'] as String,
        topic: (j['topic'] as String?) ?? 'mixed',
        count: (j['count'] as int?) ?? 10,
        difficulty: GameDifficulty.values.firstWhere(
          (GameDifficulty d) => d.name == j['d'],
          orElse: () => GameDifficulty.standard,
        ),
        players: (j['players'] as int?) ?? 1,
        hints: (j['hints'] as bool?) ?? true,
      );
}

/// A game in progress. Plain data plus a few moves, so the screen only
/// calls [pick], [useHint] and [next], and the whole thing can be saved.
class QuizSession {
  QuizSession({
    required this.config,
    required this.questions,
    int? hintsLeft,
    List<int?>? picks,
    List<int>? scores,
    Map<int, List<int>>? hidden,
    this.index = 0,
  })  : hintsLeft = hintsLeft ?? (config.hints ? kHintsPerGame : 0),
        picks = picks ?? List<int?>.filled(questions.length, null),
        scores = scores ?? List<int>.filled(config.players, 0),
        hidden = hidden ?? <int, List<int>>{};

  factory QuizSession.fromJson(Map<String, dynamic> j) {
    final QuizConfig config =
        QuizConfig.fromJson(j['config'] as Map<String, dynamic>);
    final List<QuizQuestion> qs = <QuizQuestion>[
      for (final dynamic q in j['questions'] as List<dynamic>)
        QuizQuestion.fromJson(q as Map<String, dynamic>),
    ];
    final Map<int, List<int>> hidden = <int, List<int>>{};
    (j['hidden'] as Map<String, dynamic>? ?? <String, dynamic>{})
        .forEach((String k, dynamic v) {
      hidden[int.parse(k)] = (v as List<dynamic>).cast<int>();
    });
    return QuizSession(
      config: config,
      questions: qs,
      index: j['index'] as int,
      hintsLeft: j['hintsLeft'] as int,
      picks: (j['picks'] as List<dynamic>).cast<int?>(),
      scores: (j['scores'] as List<dynamic>).cast<int>(),
      hidden: hidden,
    );
  }

  final QuizConfig config;
  final List<QuizQuestion> questions;
  int index;
  int hintsLeft;

  /// The option chosen for each question, null until answered.
  final List<int?> picks;

  /// Right answers per player.
  final List<int> scores;

  /// The wrong options a hint hid, by question index.
  final Map<int, List<int>> hidden;

  int get total => questions.length;
  QuizQuestion get current => questions[index];

  /// 0-based player whose turn it is. One player in solo.
  int get player => index % config.players;

  /// True once the current question has been answered.
  bool get answered => picks[index] != null;

  /// True when the last question is answered.
  bool get finished => index >= total - 1 && answered;

  int get correct => scores.fold(0, (int a, int b) => a + b);

  /// Options of the current question that a hint has hidden.
  Set<int> get hiddenNow => (hidden[index] ?? const <int>[]).toSet();

  bool get canUseHint => hintsLeft > 0 && !answered && hidden[index] == null;

  /// Records an answer. Ignored once answered or when [option] is hidden.
  bool pick(int option) {
    if (answered) return false;
    if (option < 0 || option >= current.options.length) return false;
    if (hiddenNow.contains(option)) return false;
    picks[index] = option;
    if (option == current.answer) scores[player] += 1;
    return true;
  }

  /// Uses one free hint: hides two wrong options. Returns what it hid, or
  /// null when no hint can be used now.
  List<int>? useHint(Random rnd) {
    if (!canUseHint) return null;
    final List<int> wrong = <int>[
      for (int i = 0; i < current.options.length; i++)
        if (i != current.answer) i,
    ]..shuffle(rnd);
    final List<int> out = wrong.take(min(2, wrong.length - 1)).toList();
    hidden[index] = out;
    hintsLeft -= 1;
    return out;
  }

  /// Moves to the next question. False at the end.
  bool next() {
    if (!answered || index >= total - 1) return false;
    index += 1;
    return true;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'config': config.toJson(),
        'questions': <dynamic>[for (final QuizQuestion q in questions) q.toJson()],
        'index': index,
        'hintsLeft': hintsLeft,
        'picks': picks,
        'scores': scores,
        'hidden': <String, dynamic>{
          for (final MapEntry<int, List<int>> e in hidden.entries)
            '${e.key}': e.value,
        },
      };

  String encode() => json.encode(toJson());
}

// ---------------------------------------------------------------------------
// Qur'an Knowledge
// ---------------------------------------------------------------------------

/// What a Qur'an Knowledge game asks about.
abstract final class QuranTopics {
  static const String mixed = 'mixed';
  static const String ayah = 'ayah';
  static const String surahs = 'surahs';
  static const List<String> all = <String>[mixed, ayah, surahs];

  static String label(String t) => switch (t) {
        ayah => 'Complete the ayah',
        surahs => 'Surah names and numbers',
        _ => 'A mix of everything',
      };
}

final RegExp _arabicLetter = RegExp('[\u0621-\u064A]');
final RegExp _arabicMarks = RegExp('[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]');

/// The consonant skeleton of an Arabic word (marks removed), used to be
/// sure two options are really different words and about the same length.
String arabicSkeleton(String w) =>
    w.replaceAll(_arabicMarks, '').replaceAll('\u0671', '\u0627');

final RegExp _stopSigns = RegExp('[\u06D6-\u06DE\u06E9]');

/// A word as an answer option: the pause and prostration signs that the
/// text attaches to a word are taken off, so no option is marked apart.
String cleanWord(String w) => w.replaceAll(_stopSigns, '');

/// True when [w] can be the veiled word: at least three letters.
bool _usableWord(String w) {
  final String s = arabicSkeleton(w);
  if (s.length < 3) return false;
  for (final int c in s.runes) {
    if (c < 0x0621 || c > 0x064A) {
      if (c != 0x0627) return false;
    }
  }
  return _arabicLetter.hasMatch(s);
}

class _AyahRef {
  const _AyahRef(this.surah, this.ayah, this.words, this.text);
  final int surah;
  final int ayah;
  final List<String> words;
  final String text;
}

class _SurahRow {
  const _SurahRow(this.n, this.name, this.arabic, this.meaning, this.count);
  final int n;
  final String name;
  final String arabic;
  final String meaning;
  final int count;
}

String _surahCite(_SurahRow s) =>
    'Qur’an, Surah ${s.n} (${s.name})';

/// Builds [config.count] Qur'an Knowledge questions from the bundled
/// `quran.json` (a list of surahs: n, tl, ar, en, c, v = [[ayah, text, en]]).
///
/// Easy uses the last part of the Qur'an and Al-Fatihah, short ayat, and
/// names the surah above an ayah. Standard uses every surah. Challenge uses
/// longer ayat and chooses the wrong words from the same surah.
List<QuizQuestion> buildQuranQuiz(
  List<dynamic> quran,
  Random rnd, {
  required int count,
  required GameDifficulty difficulty,
  String topic = QuranTopics.mixed,
}) {
  final List<_SurahRow> surahs = <_SurahRow>[];
  final List<_AyahRef> ayat = <_AyahRef>[];
  final int minTok = switch (difficulty) {
    GameDifficulty.easy => 3,
    GameDifficulty.standard => 4,
    GameDifficulty.challenge => 6,
  };
  final int maxTok = switch (difficulty) {
    GameDifficulty.easy => 6,
    GameDifficulty.standard => 9,
    GameDifficulty.challenge => 14,
  };
  for (final dynamic s in quran) {
    final Map<String, dynamic> m = s as Map<String, dynamic>;
    final int n = m['n'] as int;
    surahs.add(_SurahRow(
      n,
      m['tl'] as String,
      m['ar'] as String,
      m['en'] as String,
      m['c'] as int,
    ));
    final bool inPool = difficulty != GameDifficulty.easy || n == 1 || n >= 78;
    if (!inPool) continue;
    for (final dynamic a in m['v'] as List<dynamic>) {
      final List<dynamic> row = a as List<dynamic>;
      final String text = row[1] as String;
      final List<String> words = text
          .split(RegExp(r'\s+'))
          .where((String w) => w.isNotEmpty)
          .toList();
      if (words.length < minTok || words.length > maxTok) continue;
      if (!words.any(_usableWord)) continue;
      ayat.add(_AyahRef(n, row[0] as int, words, text));
    }
  }
  final List<_SurahRow> surahPool = <_SurahRow>[
    for (final _SurahRow s in surahs)
      if (difficulty != GameDifficulty.easy || s.n == 1 || s.n >= 78) s,
  ];
  if (surahPool.length < 4 || ayat.length < 8) return <QuizQuestion>[];
  ayat.shuffle(rnd);

  // The sequence of question kinds.
  final List<String> kinds = <String>[];
  final List<String> cycle = switch (topic) {
    QuranTopics.ayah => <String>['ayah'],
    QuranTopics.surahs => <String>['name', 'number', 'count'],
    _ => <String>['ayah', 'name', 'ayah', 'number', 'ayah', 'count'],
  };
  while (kinds.length < count) {
    final List<String> round = List<String>.of(cycle)..shuffle(rnd);
    kinds.addAll(round);
  }

  final List<QuizQuestion> out = <QuizQuestion>[];
  final Set<String> used = <String>{};
  int ayahCursor = 0;
  int guard = 0;
  for (final String kind in kinds) {
    if (out.length >= count) break;
    if (++guard > count * 60) break;
    QuizQuestion? q;
    if (kind == 'ayah') {
      while (ayahCursor < ayat.length && q == null) {
        final _AyahRef a = ayat[ayahCursor++];
        if (used.contains('a${a.surah}:${a.ayah}')) continue;
        q = _ayahQuestion(a, surahs, ayat, rnd, difficulty);
        if (q != null) used.add('a${a.surah}:${a.ayah}');
      }
    } else {
      final _SurahRow s = surahPool[rnd.nextInt(surahPool.length)];
      if (used.contains('$kind${s.n}')) {
        // try again with another surah for this slot
        for (int t = 0; t < 12 && q == null; t++) {
          final _SurahRow s2 = surahPool[rnd.nextInt(surahPool.length)];
          if (used.contains('$kind${s2.n}')) continue;
          q = _surahQuestion(kind, s2, surahPool, rnd, difficulty);
          if (q != null) used.add('$kind${s2.n}');
        }
      } else {
        q = _surahQuestion(kind, s, surahPool, rnd, difficulty);
        if (q != null) used.add('$kind${s.n}');
      }
    }
    if (q != null) out.add(q);
  }
  return out;
}

QuizQuestion? _ayahQuestion(
  _AyahRef a,
  List<_SurahRow> surahs,
  List<_AyahRef> pool,
  Random rnd,
  GameDifficulty difficulty,
) {
  final List<int> slots = <int>[
    for (int i = 0; i < a.words.length; i++)
      if (_usableWord(a.words[i])) i,
  ];
  if (slots.isEmpty) return null;
  final int at = slots[rnd.nextInt(slots.length)];
  final String answer = cleanWord(a.words[at]);
  final String skel = arabicSkeleton(answer);

  // Wrong words: Challenge takes them from the same surah, otherwise from
  // anywhere. They must be different words of a similar length.
  final List<_AyahRef> source = difficulty == GameDifficulty.challenge
      ? <_AyahRef>[
          for (final _AyahRef p in pool)
            if (p.surah == a.surah) p,
        ]
      : pool;
  final List<String> wrong = <String>[];
  final Set<String> seen = <String>{skel};
  for (int t = 0; t < 200 && wrong.length < 3; t++) {
    final _AyahRef p = source[rnd.nextInt(source.length)];
    final String w = cleanWord(p.words[rnd.nextInt(p.words.length)]);
    if (!_usableWord(w)) continue;
    final String sk = arabicSkeleton(w);
    if (seen.contains(sk)) continue;
    if ((sk.length - skel.length).abs() > 2) continue;
    seen.add(sk);
    wrong.add(w);
  }
  if (wrong.length < 3) return null;
  final List<String> options = <String>[answer, ...wrong]..shuffle(rnd);
  final List<String> shown = List<String>.of(a.words);
  shown[at] = '_____';
  final _SurahRow s = surahs[a.surah - 1];
  return QuizQuestion(
    id: 'qk-a-${a.surah}-${a.ayah}',
    prompt: shown.join(' '),
    promptIsArabic: true,
    optionsAreArabic: true,
    options: options,
    answer: options.indexOf(answer),
    context: difficulty == GameDifficulty.easy ? 'From Surah ${s.name}' : null,
    explanation: 'The ayah reads: ${a.text}',
    citation: 'Qur’an ${a.surah}:${a.ayah} (Surah ${s.name})',
  );
}

QuizQuestion? _surahQuestion(
  String kind,
  _SurahRow s,
  List<_SurahRow> pool,
  Random rnd,
  GameDifficulty difficulty,
) {
  final String fact = 'Surah ${s.n} is ${s.name} (${s.arabic}), '
      '“${s.meaning}”, with ${s.count} ayat.';
  final String cite = '${_surahCite(s)}, from the surah list in the app';
  switch (kind) {
    case 'name':
      final List<_SurahRow> others = <_SurahRow>[
        for (final _SurahRow o in pool)
          if (o.n != s.n) o,
      ]..shuffle(rnd);
      if (others.length < 3) return null;
      final List<String> options = <String>[
        s.name,
        for (final _SurahRow o in others.take(3)) o.name,
      ]..shuffle(rnd);
      return QuizQuestion(
        id: 'qk-name-${s.n}',
        prompt: 'Which surah is number ${s.n}?',
        options: options,
        answer: options.indexOf(s.name),
        explanation: fact,
        citation: cite,
      );
    case 'number':
      final List<int> nums = _nearNumbers(
        s.n,
        <int>[for (final _SurahRow o in pool) o.n],
        rnd,
        difficulty,
      );
      if (nums.length < 4) return null;
      return QuizQuestion(
        id: 'qk-number-${s.n}',
        prompt: 'What is the number of Surah ${s.name}?',
        options: <String>[for (final int n in nums) '$n'],
        answer: nums.indexOf(s.n),
        explanation: fact,
        citation: cite,
      );
    default:
      final int top = pool.map((_SurahRow o) => o.count).reduce(max);
      final List<int> nums = _nearNumbers(
        s.count,
        <int>[for (int i = 3; i <= top; i++) i],
        rnd,
        difficulty,
      );
      if (nums.length < 4) return null;
      return QuizQuestion(
        id: 'qk-count-${s.n}',
        prompt: 'How many ayat does Surah ${s.name} have?',
        options: <String>[for (final int n in nums) '$n'],
        answer: nums.indexOf(s.count),
        explanation: '$fact The count follows the Qur’an text in the app.',
        citation: cite,
      );
  }
}

/// Four different numbers from [allowed] including [answer], sorted. Closer
/// numbers on Challenge, spread out on Easy.
List<int> _nearNumbers(
  int answer,
  List<int> allowed,
  Random rnd,
  GameDifficulty difficulty,
) {
  final int span = switch (difficulty) {
    GameDifficulty.easy => 40,
    GameDifficulty.standard => 15,
    GameDifficulty.challenge => 6,
  };
  final List<int> near = <int>[
    for (final int n in allowed)
      if (n != answer && (n - answer).abs() <= span) n,
  ]..shuffle(rnd);
  final List<int> rest = <int>[
    for (final int n in allowed)
      if (n != answer && (n - answer).abs() > span) n,
  ]..shuffle(rnd);
  final List<int> picks = <int>[answer, ...near, ...rest].take(4).toList()
    ..sort();
  return picks.length == 4 ? picks : <int>[];
}

// ---------------------------------------------------------------------------
// Stories Trivia
// ---------------------------------------------------------------------------

/// One row of the bundled story trivia (`assets/games/trivia.json`).
typedef TriviaRow = ({
  String id,
  String category,
  String question,
  List<String> options,
  int answer,
  String why,
});

final RegExp _verseRef = RegExp(r'\b(\d{1,3}):(\d{1,3})(?:[-–]\d{1,3})?');
final RegExp _hadithRef =
    RegExp(r'(Bukhari|Muslim|Tirmidhi)\s+(\d{1,5})(?:[-–]\d{1,5})?');
final RegExp _seerahRef = RegExp(r"Ibn Hisham|Ibn Sa'd|Ibn Ishaq");
final RegExp _surahNumberRef = RegExp(r'\((\d{1,3})\)');

/// The source a trivia explanation names, or null when it names none.
/// Questions without one are not asked.
String? triviaCitation(String why) {
  final List<String> parts = <String>[];
  for (final RegExpMatch m in _verseRef.allMatches(why)) {
    final int surah = int.parse(m.group(1)!);
    if (surah >= 1 && surah <= 114) {
      parts.add('Qur’an ${m.group(0)}');
    }
  }
  for (final RegExpMatch m in _hadithRef.allMatches(why)) {
    parts.add(m.group(0)!);
  }
  final List<String> seerah = <String>[
    for (final RegExpMatch m in _seerahRef.allMatches(why)) m.group(0)!,
  ];
  if (seerah.isNotEmpty) parts.add('Seerah: ${seerah.toSet().join(', ')}');
  if (parts.isEmpty) {
    final RegExpMatch? m = _surahNumberRef.firstMatch(why);
    if (m != null) {
      final int n = int.parse(m.group(1)!);
      if (n >= 1 && n <= 114) parts.add('Qur’an, Surah $n');
    }
  }
  if (parts.isEmpty) return null;
  final List<String> unique = <String>[];
  for (final String p in parts) {
    if (!unique.contains(p)) unique.add(p);
  }
  return unique.take(3).join(' · ');
}

/// The trivia rows that name a source, as questions in their bundled order.
List<QuizQuestion> storiesPool(List<TriviaRow> rows, {String? topic}) {
  final List<QuizQuestion> out = <QuizQuestion>[];
  for (final TriviaRow r in rows) {
    if (topic != null && topic != 'mixed' && r.category != topic) continue;
    final String? cite = triviaCitation(r.why);
    if (cite == null) continue;
    if (r.options.length < 2 || r.answer < 0 || r.answer >= r.options.length) {
      continue;
    }
    out.add(QuizQuestion(
      id: r.id,
      prompt: r.question,
      options: r.options,
      answer: r.answer,
      explanation: r.why,
      citation: cite,
    ));
  }
  return out;
}

/// The topics a trivia game offers, in a fixed order, for the rows that
/// have at least [min] sourced questions.
List<String> storiesTopics(List<TriviaRow> rows, {int min = 3}) {
  final Map<String, int> n = <String, int>{};
  for (final TriviaRow r in rows) {
    if (triviaCitation(r.why) == null) continue;
    n[r.category] = (n[r.category] ?? 0) + 1;
  }
  return <String>[
    for (final MapEntry<String, int> e in n.entries)
      if (e.value >= min) e.key,
  ];
}

/// [count] questions, shuffled, with each question's options in a random
/// order and the answer re-pointed.
List<QuizQuestion> buildStoriesQuiz(
  List<TriviaRow> rows,
  Random rnd, {
  required int count,
  String topic = 'mixed',
}) {
  final List<QuizQuestion> pool = storiesPool(rows, topic: topic)
    ..shuffle(rnd);
  return <QuizQuestion>[
    for (final QuizQuestion q in pool.take(count)) shuffleOptions(q, rnd),
  ];
}

/// The same question with its options in a random order.
QuizQuestion shuffleOptions(QuizQuestion q, Random rnd) {
  final List<int> order = List<int>.generate(q.options.length, (int i) => i)
    ..shuffle(rnd);
  return QuizQuestion(
    id: q.id,
    prompt: q.prompt,
    options: <String>[for (final int i in order) q.options[i]],
    answer: order.indexOf(q.answer),
    explanation: q.explanation,
    citation: q.citation,
    promptIsArabic: q.promptIsArabic,
    optionsAreArabic: q.optionsAreArabic,
    context: q.context,
    kicker: q.kicker,
  );
}

/// How many questions a setup screen may offer for a pool of [available].
List<int> countChoices(int available) {
  const List<int> all = <int>[5, 10, 15, 20, 30];
  final List<int> ok = <int>[
    for (final int n in all)
      if (n <= available) n,
  ];
  if (ok.isEmpty && available > 0) return <int>[available];
  return ok;
}

/// How many of [total] questions fall to player [p] (0-based) when
/// [players] take turns, one question each in order.
int questionsFor(int total, int players, int p) =>
    players <= 0 ? total : (total - p + players - 1) ~/ players;
