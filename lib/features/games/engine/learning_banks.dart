/// Question banks for the learning games that run on the shared quiz engine:
/// Seerah Challenge, Hadith Knowledge and Arabic Words.
///
/// Rules this file keeps (and `test/games/learning_games_test.dart` checks):
///  * every question is made from content that is already in the app, and
///    every question carries a non-empty source and an explanation;
///  * Seerah questions come from a bank whose "evidence" phrase must appear
///    word for word in the story it names; the source shown is the story's
///    own source lines;
///  * Hadith questions are built from the bundled Forty Hadith of an-Nawawi
///    only, using a hand-checked list of the Prophet's ﷺ own words
///    (`assets/games/hadith_quiz.json`): the saying, its collection, its
///    number and its grade WITH the person who gave it. A report with no
///    named grader is not asked;
///  * Arabic Words use the 99 Names list and the 28-letter curriculum only:
///    words whose meaning is not sourced in the app (the large word deck) are
///    never used;
///  * no timer, no points; nothing is invented here.
///
/// Pure Dart (no Flutter) so it can be checked with a plain Dart SDK.
library;

import 'dart:math';

import '../../hadith/domain/hadith_models.dart';
import 'quiz_engine.dart';

/// [s] cut at a word to at most [max] characters, with an ellipsis if cut.
String shortSource(String s, {int max = 140}) {
  final String t = s.trim();
  if (t.length <= max) return t;
  final int cut = t.lastIndexOf(' ', max);
  return '${t.substring(0, cut > max ~/ 2 ? cut : max)} …';
}

// ---------------------------------------------------------------------------
// Seerah Challenge
// ---------------------------------------------------------------------------

/// A story of the Seerah School as the bank needs it: its title and the
/// source lines printed under it.
typedef SeerahStory = ({String title, List<String> sources});

/// Builds [count] Seerah questions from the bank (`assets/games/seerah_quiz.json`,
/// its `questions` list). A question whose story is missing or has no source
/// line is dropped, so nothing is ever asked without a source.
List<QuizQuestion> buildSeerahQuiz(
  List<Map<String, dynamic>> bank,
  Map<String, SeerahStory> stories,
  Random rnd, {
  required int count,
}) {
  final List<QuizQuestion> pool = seerahPool(bank, stories)..shuffle(rnd);
  return <QuizQuestion>[
    for (final QuizQuestion q in pool.take(count)) shuffleOptions(q, rnd),
  ];
}

/// Every usable Seerah question, in bank order, options as written.
List<QuizQuestion> seerahPool(
  List<Map<String, dynamic>> bank,
  Map<String, SeerahStory> stories,
) {
  final List<QuizQuestion> out = <QuizQuestion>[];
  for (final Map<String, dynamic> b in bank) {
    final SeerahStory? s = stories[b['story'] as String];
    if (s == null) continue;
    final List<String> lines = <String>[
      for (final String l in s.sources)
        if (l.trim().isNotEmpty) l.trim(),
    ];
    if (lines.isEmpty) continue;
    final String answer = b['answer'] as String;
    final List<String> wrong = (b['wrong'] as List<dynamic>).cast<String>();
    out.add(QuizQuestion(
      id: b['id'] as String,
      prompt: b['prompt'] as String,
      options: <String>[answer, ...wrong],
      answer: 0,
      explanation: b['why'] as String,
      citation: 'Seerah School, “${s.title}”: '
          '${lines.take(2).map(shortSource).join(' · ')}',
    ));
  }
  return out;
}

// ---------------------------------------------------------------------------
// Hadith Knowledge
// ---------------------------------------------------------------------------

/// A hadith of the Forty with what a question needs.
class _H {
  const _H(this.n, this.src, this.grade, this.said, this.head, this.askSource);
  final int n;
  final String src;
  final HadithGrade grade;

  /// The Prophet's ﷺ own words, copied from the Forty (never a Companion's
  /// question), 4 to 50 words.
  final String said;

  /// The first part of [said] shown in "finish the hadith", or null when the
  /// saying has no clean break.
  final String? head;

  /// False when the collection an-Nawawi names was not confirmed against a
  /// checked corpus, so "which collection" is not asked.
  final bool askSource;

  /// The words that follow [head], or null.
  String? get tail {
    final String? h = head;
    if (h == null) return null;
    return said.substring(h.length).trim();
  }
}

const List<String> _collectionWords = <String>[
  'bukhari',
  'muslim',
  'tirmidhi',
  'nasa',
  'dawud',
  'majah',
  'ahmad',
  'darimi',
  'bayhaqi',
  'daraqutni',
  'malik',
  'hujjah',
];

Set<String> _collectionsIn(String src) {
  final String s = src.toLowerCase();
  return <String>{
    for (final String w in _collectionWords)
      if (s.contains(w)) w,
  };
}

String _squash(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

int _wordCount(String s) => _squash(s).split(' ').length;

/// The hadith the quiz may ask about: every entry of the curated list
/// (`assets/games/hadith_quiz.json`, its `items`) whose Forty entry has a
/// source and a grade WITH a named grader, and whose saying is word for word
/// inside that entry's English text. The saying is the Prophet's ﷺ own
/// words, chosen by hand: the earlier version took the first quoted string,
/// which was often a Companion's question.
List<_H> _hadithPool(
  List<Map<String, dynamic>> forty,
  List<Map<String, dynamic>> curated,
) {
  final Map<int, Map<String, dynamic>> byN = <int, Map<String, dynamic>>{
    for (final Map<String, dynamic> h in forty)
      if (h['n'] is int) h['n'] as int: h,
  };
  final List<_H> out = <_H>[];
  for (final Map<String, dynamic> c in curated) {
    final Object? n = c['n'];
    final Object? said = c['said'];
    if (n is! int || said is! String) continue;
    final Map<String, dynamic>? h = byN[n];
    if (h == null) continue;
    final Object? src = h['src'];
    final Object? en = h['en'];
    if (src is! String || src.trim().isEmpty || en is! String) continue;
    final HadithGrade? grade = HadithGrade.fromJson(h);
    if (grade == null) continue;
    if (!_squash(en).contains(_squash(said))) continue;
    final Object? head = c['head'];
    String? headText;
    if (head is String &&
        _squash(said).startsWith(_squash(head)) &&
        _squash(said).length > _squash(head).length) {
      headText = _squash(head);
    }
    out.add(_H(
      n,
      src.trim(),
      grade,
      _squash(said),
      headText,
      c['collection'] != false,
    ));
  }
  return out;
}

/// How many Hadith Knowledge questions the curated list can supply.
int hadithQuestionCount(
  List<Map<String, dynamic>> forty,
  List<Map<String, dynamic>> curated,
) {
  final List<_H> pool = _hadithPool(forty, curated);
  return pool.length +
      pool.where((_H h) => h.askSource).length +
      pool.where((_H h) => h.head != null).length;
}

String _hadithCite(_H h) =>
    'Forty Hadith of Imam an-Nawawi (42-hadith edition), No. ${h.n} · '
    '${h.src} · ${h.grade.label}';

String _hadithExplain(_H h, {required bool withWording}) {
  final StringBuffer b = StringBuffer()
    ..write('This is hadith ${h.n} in an-Nawawi’s Forty. ')
    ..write('An-Nawawi names: ${h.src}. ')
    ..write('The grade the app shows is ${h.grade.label}; later scholars '
        'sometimes grade a report differently.');
  if (withWording) b.write(' The wording: “${h.said}”');
  return b.toString();
}

/// Builds [count] questions from the curated list and the Forty.
///
/// Three kinds: finish the hadith (the second half of the Prophet's ﷺ words),
/// which collection an-Nawawi names, and which number it has in the Forty.
/// One right answer each: the wrong collections never share a collection
/// with the right one, the wrong numbers are other hadith, and the wrong
/// endings come from other hadith, with a different opening and a similar
/// length, so no ending can also be a true ending of this hadith.
List<QuizQuestion> buildHadithQuiz(
  List<Map<String, dynamic>> forty,
  List<Map<String, dynamic>> curated,
  Random rnd, {
  required int count,
}) {
  final List<_H> pool = _hadithPool(forty, curated);
  if (pool.length < 5) return <QuizQuestion>[];
  final List<QuizQuestion> all = <QuizQuestion>[];
  final List<_H> finishable = <_H>[
    for (final _H h in pool)
      if (h.head != null) h,
  ];
  final List<_H> sourced = <_H>[
    for (final _H h in pool)
      if (h.askSource) h,
  ];
  for (final _H h in pool) {
    if (h.askSource && sourced.length >= 4) {
      final QuizQuestion? q = _collectionQuestion(h, sourced, rnd);
      if (q != null) all.add(q);
    }
    all.add(_numberQuestion(h, pool, rnd));
  }
  if (finishable.length >= 4) {
    for (final _H h in finishable) {
      final QuizQuestion? q = _finishQuestion(h, finishable, rnd);
      if (q != null) all.add(q);
    }
  }
  // One question of each hadith first, so a short game does not repeat one.
  all.shuffle(rnd);
  final Set<String> seen = <String>{};
  final List<QuizQuestion> first = <QuizQuestion>[];
  final List<QuizQuestion> rest = <QuizQuestion>[];
  for (final QuizQuestion q in all) {
    final String hadith = q.id.split('-').last;
    (seen.add(hadith) ? first : rest).add(q);
  }
  return <QuizQuestion>[...first, ...rest].take(count).toList();
}

QuizQuestion? _collectionQuestion(_H h, List<_H> pool, Random rnd) {
  final Set<String> mine = _collectionsIn(h.src);
  final List<String> others = <String>{
    for (final _H o in pool)
      if (_collectionsIn(o.src).intersection(mine).isEmpty && o.src != h.src)
        o.src,
  }.toList()
    ..shuffle(rnd);
  if (others.length < 3) return null;
  final List<String> options = <String>[h.src, ...others.take(3)]
    ..shuffle(rnd);
  return QuizQuestion(
    id: 'hk-c-${h.n}',
    prompt: '“${h.said}”\n\nWhich collection does an-Nawawi name for this '
        'hadith?',
    options: options,
    answer: options.indexOf(h.src),
    explanation: _hadithExplain(h, withWording: false),
    citation: _hadithCite(h),
    kicker: 'Hadith',
  );
}

QuizQuestion _numberQuestion(_H h, List<_H> pool, Random rnd) {
  final List<int> others = <int>[
    for (final _H o in pool)
      if (o.n != h.n) o.n,
  ]..shuffle(rnd);
  final List<int> nums = <int>[h.n, ...others.take(3)]..sort();
  return QuizQuestion(
    id: 'hk-n-${h.n}',
    prompt: '“${h.said}”\n\nWhich number does this hadith have in an-Nawawi’s '
        'Forty?',
    options: <String>[for (final int n in nums) 'Hadith $n'],
    answer: nums.indexOf(h.n),
    explanation: _hadithExplain(h, withWording: false),
    citation: _hadithCite(h),
    kicker: 'Hadith',
  );
}

String _opening(String s) {
  final List<String> w = _squash(s).toLowerCase().split(' ');
  return w.take(2).join(' ');
}

QuizQuestion? _finishQuestion(_H h, List<_H> finishable, Random rnd) {
  final String head = h.head!;
  final String tail = h.tail!;
  final int want = _wordCount(tail);
  final List<_H> cand = <_H>[
    for (final _H o in finishable)
      if (o.n != h.n && _opening(o.tail!) != _opening(tail)) o,
  ]..shuffle(rnd);
  // The closest lengths first, so the longest ending is not the answer.
  cand.sort((_H a, _H b) => (_wordCount(a.tail!) - want)
      .abs()
      .compareTo((_wordCount(b.tail!) - want).abs()));
  final List<String> wrong = <String>[];
  final Set<String> openings = <String>{_opening(tail)};
  for (final _H o in cand.take(10)) {
    final String t = o.tail!;
    if (!openings.add(_opening(t))) continue;
    wrong.add(t);
    if (wrong.length == 3) break;
  }
  if (wrong.length < 3) return null;
  final List<String> options = <String>[tail, ...wrong]..shuffle(rnd);
  return QuizQuestion(
    id: 'hk-f-${h.n}',
    prompt: '“$head …”\n\nHow does the hadith go on?',
    options: options,
    answer: options.indexOf(tail),
    explanation: _hadithExplain(h, withWording: true),
    citation: _hadithCite(h),
    kicker: 'Finish the hadith',
  );
}

// ---------------------------------------------------------------------------
// Arabic Words
// ---------------------------------------------------------------------------

/// One of the 99 Names as the games file prints it.
typedef ArabicNameRow = ({
  int n,
  String name,
  String arabic,
  String meaning,
  String ref,
});

/// One letter of the alphabet curriculum.
typedef ArabicLetterRow = ({int lesson, String arabic, String name});

/// What an Arabic Words game asks about.
abstract final class ArabicWordTopics {
  static const String mixed = 'mixed';
  static const String names = 'names';
  static const String letters = 'letters';
  static const List<String> all = <String>[mixed, names, letters];

  static String label(String t) => switch (t) {
        names => 'The 99 Names',
        letters => 'The 28 letters',
        _ => 'Names and letters',
      };
}

/// Builds [count] questions. Names: the Arabic to its transliterated name, or
/// the name to its Arabic. Letters: the letter to its name, or a name to its
/// letter. The meaning is shown after the answer, never asked: several Names
/// have close meanings, and a question must have one right answer.
List<QuizQuestion> buildArabicWordsQuiz(
  List<ArabicNameRow> names,
  List<ArabicLetterRow> letters,
  Random rnd, {
  required int count,
  String topic = ArabicWordTopics.mixed,
}) {
  // Name 1 is the Name itself, so it is not used as a wrong choice.
  final List<ArabicNameRow> nameRows = <ArabicNameRow>[
    for (final ArabicNameRow r in names)
      if (r.arabic.trim().isNotEmpty && r.meaning.trim().isNotEmpty) r,
  ];
  final bool useNames =
      topic != ArabicWordTopics.letters && nameRows.length >= 8;
  final bool useLetters =
      topic != ArabicWordTopics.names && letters.length >= 8;
  final List<String> kinds = <String>[
    if (useNames) ...<String>['nt', 'na'],
    if (useLetters) ...<String>['lg', 'ln'],
  ];
  if (kinds.isEmpty) return <QuizQuestion>[];
  final List<QuizQuestion> out = <QuizQuestion>[];
  final Set<String> used = <String>{};
  int guard = 0;
  int round = 0;
  while (out.length < count && guard++ < count * 40) {
    final String kind = kinds[round++ % kinds.length];
    QuizQuestion? q;
    if (kind == 'nt' || kind == 'na') {
      final ArabicNameRow r = nameRows[rnd.nextInt(nameRows.length)];
      if (r.n == 1 || used.contains('$kind${r.n}')) continue;
      q = kind == 'nt'
          ? _nameTranslit(r, nameRows, rnd)
          : _nameArabic(r, nameRows, rnd);
      if (q != null) used.add('$kind${r.n}');
    } else {
      final ArabicLetterRow r = letters[rnd.nextInt(letters.length)];
      if (used.contains('$kind${r.lesson}')) continue;
      q = kind == 'lg'
          ? _letterName(r, letters, rnd)
          : _nameLetter(r, letters, rnd);
      if (q != null) used.add('$kind${r.lesson}');
    }
    if (q != null) out.add(q);
  }
  return out;
}

String _nameCite(ArabicNameRow r) {
  final String ref = r.ref.trim();
  final bool hasRef = ref.isNotEmpty && ref != r.name && ref != 'Allah';
  return 'The 99 Names list in the app, Name ${r.n}'
      '${hasRef ? ' (reference: $ref)' : ''}. The Arabic was checked '
      'against six published lists of the Names';
}

String _nameFact(ArabicNameRow r) =>
    'Name ${r.n} is ${r.name} (${r.arabic}): ${r.meaning}.';

QuizQuestion? _nameTranslit(
  ArabicNameRow r,
  List<ArabicNameRow> pool,
  Random rnd,
) {
  final List<String> wrong = <String>{
    for (final ArabicNameRow o in pool)
      if (o.n != 1 && o.n != r.n && o.name != r.name) o.name,
  }.toList()
    ..shuffle(rnd);
  if (wrong.length < 3) return null;
  final List<String> options = <String>[r.name, ...wrong.take(3)]
    ..shuffle(rnd);
  return QuizQuestion(
    id: 'aw-nt-${r.n}',
    prompt: r.arabic,
    promptIsArabic: true,
    kicker: 'Which Name is this?',
    options: options,
    answer: options.indexOf(r.name),
    explanation: _nameFact(r),
    citation: _nameCite(r),
  );
}

QuizQuestion? _nameArabic(
  ArabicNameRow r,
  List<ArabicNameRow> pool,
  Random rnd,
) {
  final List<String> wrong = <String>{
    for (final ArabicNameRow o in pool)
      if (o.n != 1 && o.n != r.n && o.arabic != r.arabic) o.arabic,
  }.toList()
    ..shuffle(rnd);
  if (wrong.length < 3) return null;
  final List<String> options = <String>[r.arabic, ...wrong.take(3)]
    ..shuffle(rnd);
  return QuizQuestion(
    id: 'aw-na-${r.n}',
    prompt: 'Which one is the Name ${r.name}?',
    optionsAreArabic: true,
    options: options,
    answer: options.indexOf(r.arabic),
    explanation: _nameFact(r),
    citation: _nameCite(r),
  );
}

String _letterCite(ArabicLetterRow r) =>
    'Letters school, lesson ${r.lesson} of 28 (the alphabet curriculum in '
    'the app)';

String _letterFact(ArabicLetterRow r) =>
    'Lesson ${r.lesson} teaches ${r.name} (${r.arabic}).';

QuizQuestion? _letterName(
  ArabicLetterRow r,
  List<ArabicLetterRow> pool,
  Random rnd,
) {
  final List<String> wrong = <String>{
    for (final ArabicLetterRow o in pool)
      if (o.name != r.name) o.name,
  }.toList()
    ..shuffle(rnd);
  if (wrong.length < 3) return null;
  final List<String> options = <String>[r.name, ...wrong.take(3)]
    ..shuffle(rnd);
  return QuizQuestion(
    id: 'aw-lg-${r.lesson}',
    prompt: r.arabic,
    promptIsArabic: true,
    kicker: 'What is this letter called?',
    options: options,
    answer: options.indexOf(r.name),
    explanation: _letterFact(r),
    citation: _letterCite(r),
  );
}

QuizQuestion? _nameLetter(
  ArabicLetterRow r,
  List<ArabicLetterRow> pool,
  Random rnd,
) {
  final List<String> wrong = <String>{
    for (final ArabicLetterRow o in pool)
      if (o.arabic != r.arabic) o.arabic,
  }.toList()
    ..shuffle(rnd);
  if (wrong.length < 3) return null;
  final List<String> options = <String>[r.arabic, ...wrong.take(3)]
    ..shuffle(rnd);
  return QuizQuestion(
    id: 'aw-ln-${r.lesson}',
    prompt: 'Which letter is ${r.name}?',
    optionsAreArabic: true,
    options: options,
    answer: options.indexOf(r.arabic),
    explanation: _letterFact(r),
    citation: _letterCite(r),
  );
}
