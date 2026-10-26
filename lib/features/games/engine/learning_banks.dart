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
///    only: the hadith text, its collection, its number and its grade WITH
///    the person who gave it. A report with no named grader is not asked;
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

final RegExp _quoteRe = RegExp('[“"]([^”"]+)[”"]');
final RegExp _sentenceEnd = RegExp(r'[,;:.]$');

/// A hadith of the Forty with what a question needs.
class _H {
  const _H(this.n, this.src, this.grade, this.quote, this.cut);
  final int n;
  final String src;
  final HadithGrade grade;

  /// The Prophet's ﷺ words as the app prints them, 8 to 45 words.
  final String quote;

  /// Word index after which [quote] can be split for "finish the hadith",
  /// or -1 when it has no natural break.
  final int cut;
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

int _count(String s, String ch) => ch.allMatches(s).length;

List<_H> _hadithPool(List<Map<String, dynamic>> forty) {
  final List<_H> out = <_H>[];
  for (final Map<String, dynamic> h in forty) {
    final Object? n = h['n'];
    final Object? src = h['src'];
    final Object? en = h['en'];
    if (n is! int || src is! String || en is! String) continue;
    if (src.trim().isEmpty) continue;
    final HadithGrade? grade = HadithGrade.fromJson(h);
    if (grade == null) continue;
    String? quote;
    for (final RegExpMatch m in _quoteRe.allMatches(en)) {
      final String q = m.group(1)!.trim();
      final int words = q.split(RegExp(r'\s+')).length;
      if (words >= 8 && words <= 45) {
        quote = q;
        break;
      }
    }
    if (quote == null) continue;
    final List<String> w = quote.split(RegExp(r'\s+'));
    int cut = -1;
    if (w.length >= 10) {
      int best = 1 << 30;
      for (int i = 3; i <= w.length - 4; i++) {
        if (!_sentenceEnd.hasMatch(w[i])) continue;
        final String head = w.sublist(0, i + 1).join(' ');
        if (_count(head, '(') != _count(head, ')') ||
            _count(head, '[') != _count(head, ']')) {
          continue;
        }
        final int d = (i - w.length ~/ 2).abs();
        if (d < best) {
          best = d;
          cut = i;
        }
      }
    }
    out.add(_H(n, src.trim(), grade, quote, cut));
  }
  return out;
}

/// How many Hadith Knowledge questions the Forty can supply.
int hadithQuestionCount(List<Map<String, dynamic>> forty) {
  final List<_H> pool = _hadithPool(forty);
  return pool.length * 2 + pool.where((_H h) => h.cut >= 0).length;
}

String _hadithCite(_H h) =>
    'Forty Hadith of Imam an-Nawawi, No. ${h.n} · ${h.src} · '
    '${h.grade.label}';

String _hadithExplain(_H h, {required bool withWording}) {
  final StringBuffer b = StringBuffer()
    ..write('This is hadith ${h.n} in an-Nawawi’s Forty. ')
    ..write('It is reported in ${h.src}. ')
    ..write('The grade the app shows is ${h.grade.label}.');
  if (withWording) b.write(' The wording: “${h.quote}”');
  return b.toString();
}

/// Builds [count] questions from the bundled Forty (`assets/hadith/nawawi40.json`).
///
/// Three kinds: finish the hadith (the second half of the words), which
/// collection reports it, and which number it has in the Forty. The wrong
/// choices for "which collection" never name a collection that the right
/// answer also names, so there is one right answer.
List<QuizQuestion> buildHadithQuiz(
  List<Map<String, dynamic>> forty,
  Random rnd, {
  required int count,
}) {
  final List<_H> pool = _hadithPool(forty);
  if (pool.length < 5) return <QuizQuestion>[];
  final List<QuizQuestion> all = <QuizQuestion>[];
  final List<_H> finishable = <_H>[
    for (final _H h in pool)
      if (h.cut >= 0) h,
  ];
  for (final _H h in pool) {
    all.add(_collectionQuestion(h, pool, rnd));
    all.add(_numberQuestion(h, pool, rnd));
  }
  if (finishable.length >= 4) {
    for (final _H h in finishable) {
      all.add(_finishQuestion(h, finishable, rnd));
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

QuizQuestion _collectionQuestion(_H h, List<_H> pool, Random rnd) {
  final Set<String> mine = _collectionsIn(h.src);
  final List<String> others = <String>{
    for (final _H o in pool)
      if (_collectionsIn(o.src).intersection(mine).isEmpty &&
          o.src != h.src)
        o.src,
  }.toList()
    ..shuffle(rnd);
  final List<String> options = <String>[h.src, ...others.take(3)]
    ..shuffle(rnd);
  return QuizQuestion(
    id: 'hk-c-${h.n}',
    prompt: '“${h.quote}”\n\nWhich collection does an-Nawawi name for this '
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
    prompt: '“${h.quote}”\n\nWhich number does this hadith have in an-Nawawi’s '
        'Forty?',
    options: <String>[for (final int n in nums) 'Hadith $n'],
    answer: nums.indexOf(h.n),
    explanation: _hadithExplain(h, withWording: false),
    citation: _hadithCite(h),
    kicker: 'Hadith',
  );
}

QuizQuestion _finishQuestion(_H h, List<_H> finishable, Random rnd) {
  final List<String> w = h.quote.split(RegExp(r'\s+'));
  final String head = w.sublist(0, h.cut + 1).join(' ');
  final String tail = w.sublist(h.cut + 1).join(' ');
  final List<String> others = <String>[
    for (final _H o in finishable)
      if (o.n != h.n)
        o.quote
            .split(RegExp(r'\s+'))
            .sublist(o.cut + 1)
            .join(' '),
  ]..shuffle(rnd);
  final List<String> options = <String>[tail, ...others.take(3)]..shuffle(rnd);
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
