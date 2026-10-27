/// Academy v3 lesson format: the data model and its JSON parser.
///
/// A v3 lesson lives in `assets/academy/lessons_v3/<course>.json` and
/// REPLACES the manifest lesson with the same id. Every step is plain data;
/// Arabic is never typed into it: it names a phrase (`shahada.full`) or an
/// ayah (`q:1:2`) and the screen resolves it (see `phrase_resolver.dart`).
/// The format is documented in docs/academy/lesson_format_v3.md.
///
/// Pure Dart (no Flutter) so it is testable without a device.
library;

/// Raised for a malformed lesson file. [path] says where.
class LessonFormatException implements Exception {
  LessonFormatException(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => 'LessonFormatException at $path: $message';
}

const List<String> kHonestyLabels = <String>[
  '[Established]',
  '[Interpretive]',
  '[Reflection]',
];

/// A piece of a match: plain text, a phrase/ayah shown in Arabic, or one Arabic
/// word of a reference.
class Face {
  const Face({this.text, this.ref, this.word});

  final String? text;
  final String? ref;
  final String? word;

  bool get isEmpty => text == null && ref == null && word == null;

  factory Face.parse(Object? raw, String path) {
    final Map<String, dynamic> m = _map(raw, path);
    final Face f = Face(
      text: _optStr(m['text']),
      ref: _optStr(m['ref']),
      word: _optStr(m['word']),
    );
    final int n = <Object?>[f.text, f.ref, f.word].where((Object? x) => x != null).length;
    if (n != 1) {
      throw LessonFormatException(path, 'give exactly one of text, ref, word');
    }
    return f;
  }
}

sealed class V3Step {
  const V3Step({required this.id, this.label, this.source, this.review});

  final String id;

  /// '[Established]' / '[Interpretive]' / '[Reflection]'.
  final String? label;

  /// Free text naming the Qur'an / hadith the step rests on.
  final String? source;

  /// Why a scholar should look at this step (feeds the review list).
  final String? review;

  String get kind;
}

enum TeachStyle { teach, why, story }

class TeachStep extends V3Step {
  const TeachStep({
    required super.id,
    required this.style,
    required this.title,
    required this.paragraphs,
    this.bullets = const <String>[],
    this.quranRef,
    super.label,
    super.source,
    super.review,
  });

  final TeachStyle style;
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  /// Optionally show an ayah (Arabic and translation) under the text.
  final String? quranRef;

  @override
  String get kind => style.name;
}

class SayStep extends V3Step {
  const SayStep({
    required super.id,
    required this.refs,
    this.title = '',
    this.note,
    this.words = const <String, List<GlossSpec>>{},
    super.label,
    super.source,
    super.review,
  });

  /// One or more phrases / ayat shown one under the other.
  final List<String> refs;
  final String title;

  /// Plain-words guidance shown with the phrase (for a prayer position: how to
  /// stand, bow, sit).
  final String? note;

  /// Word glosses for ayat, keyed by ref (a registry phrase carries its own).
  final Map<String, List<GlossSpec>> words;

  @override
  String get kind => 'say';
}

class GlossSpec {
  const GlossSpec({required this.tr, required this.en});

  final String tr;
  final String en;
}

/// Listen and repeat. Only ever for an ayah: that is the only Arabic the app
/// has real audio for.
class ListenStep extends V3Step {
  const ListenStep({
    required super.id,
    required this.ref,
    this.title = '',
    this.repeats = 3,
    this.note,
  });

  final String ref;
  final String title;
  final int repeats;
  final String? note;

  @override
  String get kind => 'listen';
}

class HowToItem {
  const HowToItem({required this.text, this.count, this.detail});

  final String text;
  final String? count;
  final String? detail;
}

class HowToStep extends V3Step {
  const HowToStep({
    required super.id,
    required this.title,
    required this.items,
    this.intro,
    this.mistakes = const <String>[],
    super.label,
    super.source,
    super.review,
  });

  final String title;
  final String? intro;
  final List<HowToItem> items;
  final List<String> mistakes;

  @override
  String get kind => 'howto';
}

class ContrastRow {
  const ContrastRow({required this.name, required this.text});

  final String name;
  final String text;
}

/// Where the four Sunni schools differ. Each row is one topic (or one school)
/// and says who holds what; never one school presented as "the" answer.
class ContrastStep extends V3Step {
  const ContrastStep({
    required super.id,
    required this.title,
    required this.rows,
    this.intro,
    this.agree,
    this.closing,
    super.label,
    super.source,
    super.review,
  });

  final String title;
  final String? intro;

  /// What all four schools agree on.
  final String? agree;
  final List<ContrastRow> rows;
  final String? closing;

  @override
  String get kind => 'contrast';
}

class ArrangeItem {
  const ArrangeItem({required this.text, required this.why, required this.back});

  final String text;

  /// Why this item sits at this position (the re-teach).
  final String why;

  /// The step that taught it.
  final String back;
}

/// Put the items in order. [items] is the CORRECT order.
class ArrangeStep extends V3Step {
  const ArrangeStep({
    required super.id,
    required this.prompt,
    required this.items,
    required this.explain,
    this.title = '',
  });

  final String title;
  final String prompt;
  final List<ArrangeItem> items;
  final String explain;

  @override
  String get kind => 'arrange';
}

class MatchPair {
  const MatchPair({
    required this.left,
    required this.right,
    required this.why,
    required this.back,
  });

  final Face left;
  final Face right;
  final String why;
  final String back;
}

class MatchStep extends V3Step {
  const MatchStep({
    required super.id,
    required this.prompt,
    required this.pairs,
    this.title = '',
  });

  final String title;
  final String prompt;
  final List<MatchPair> pairs;

  @override
  String get kind => 'match';
}

enum CheckType { mcq, fill, scenario }

class CheckOption {
  const CheckOption({this.text, this.word, this.ref, this.reteach, this.back});

  final String? text;

  /// An Arabic word reference (`q:1:2#1`).
  final String? word;

  /// A whole phrase / ayah shown in Arabic.
  final String? ref;

  /// Shown when this option is chosen and is wrong.
  final String? reteach;

  /// The step that taught what this option gets wrong.
  final String? back;
}

class FillSpec {
  const FillSpec({required this.ref, required this.blank, required this.show});

  final String ref;

  /// Index of the word that is blanked out.
  final int blank;

  /// 'arabic' blanks an Arabic word; 'translit' blanks a transliteration word.
  final String show;
}

class CheckItem {
  const CheckItem({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.answer,
    required this.explain,
    this.scenario,
    this.ref,
    this.fill,
    this.review = true,
    this.lookback,
    this.isLookBack = false,
  });

  final String id;
  final CheckType type;
  final String question;
  final List<CheckOption> options;
  final int answer;
  final String explain;

  /// Scenario text shown above the question (type scenario).
  final String? scenario;

  /// A phrase/ayah shown in Arabic above the question.
  final String? ref;
  final FillSpec? fill;

  /// False keeps the item out of the spaced-review pool.
  final bool review;

  /// 'lessonId#itemId': this item is a look back at an earlier lesson's item
  /// and is resolved when the lessons are loaded.
  final String? lookback;

  /// True once a look back has been resolved to the earlier lesson's item. Its
  /// wrong options have no step to go back to in this lesson (re-teach text only).
  final bool isLookBack;
}

class CheckStep extends V3Step {
  const CheckStep({required super.id, required this.items, this.title = ''});

  final String title;
  final List<CheckItem> items;

  @override
  String get kind => 'check';
}

class RecapStep extends V3Step {
  const RecapStep({
    required super.id,
    required this.canDo,
    this.title = '',
    this.next,
  });

  final String title;
  final List<String> canDo;
  final String? next;

  @override
  String get kind => 'recap';
}

class DoItStep extends V3Step {
  const DoItStep({
    required super.id,
    required this.title,
    required this.body,
    required this.route,
    this.button = 'Open',
  });

  final String title;
  final String body;
  final String route;
  final String button;

  @override
  String get kind => 'doit';
}

class LessonV3 {
  const LessonV3({
    required this.id,
    required this.title,
    required this.steps,
    this.intro = '',
    this.minutes,
  });

  final String id;
  final String title;
  final String intro;
  final int? minutes;
  final List<V3Step> steps;

  int indexOfStep(String stepId) =>
      steps.indexWhere((V3Step s) => s.id == stepId);

  /// Every check item of every check step.
  Iterable<CheckItem> get checkItems sync* {
    for (final V3Step s in steps) {
      if (s is CheckStep) yield* s.items;
    }
  }
}

/// A parsed lessons file.
class LessonsFile {
  const LessonsFile({required this.course, required this.lessons});

  final String course;
  final List<LessonV3> lessons;
}

// ---------------------------------------------------------------------------
// Parsing
// ---------------------------------------------------------------------------

Map<String, dynamic> _map(Object? o, String path) {
  if (o is Map<String, dynamic>) return o;
  throw LessonFormatException(path, 'expected an object');
}

List<dynamic> _list(Object? o, String path) {
  if (o is List<dynamic>) return o;
  throw LessonFormatException(path, 'expected a list');
}

String _str(Object? o, String path) {
  if (o is String && o.trim().isNotEmpty) return o;
  throw LessonFormatException(path, 'expected a non-empty string');
}

String? _optStr(Object? o) => o is String && o.trim().isNotEmpty ? o : null;

List<String> _strList(Object? o, String path) {
  if (o == null) return const <String>[];
  final List<dynamic> l = _list(o, path);
  return <String>[
    for (int i = 0; i < l.length; i++) _str(l[i], '$path[$i]'),
  ];
}

/// A body may be one string or a list of paragraphs.
List<String> _paragraphs(Object? o, String path) {
  if (o is String) return <String>[_str(o, path)];
  return _strList(o, path);
}

List<GlossSpec>? _glosses(Object? o, String path) {
  if (o == null) return null;
  final List<dynamic> l = _list(o, path);
  return <GlossSpec>[
    for (int i = 0; i < l.length; i++)
      GlossSpec(
        tr: _str(_map(l[i], '$path[$i]')['tr'], '$path[$i].tr'),
        en: _str(_map(l[i], '$path[$i]')['en'], '$path[$i].en'),
      ),
  ];
}

/// Word glosses: a list applies to the step's first ref; an object is keyed by
/// ref.
Map<String, List<GlossSpec>> _glossMap(Object? o, String firstRef, String path) {
  if (o == null) return const <String, List<GlossSpec>>{};
  if (o is List<dynamic>) {
    return <String, List<GlossSpec>>{firstRef: _glosses(o, path)!};
  }
  final Map<String, dynamic> m = _map(o, path);
  return <String, List<GlossSpec>>{
    for (final MapEntry<String, dynamic> e in m.entries)
      e.key: _glosses(e.value, '$path.${e.key}')!,
  };
}

LessonsFile parseLessonsFile(Map<String, dynamic> json) {
  if (json['schema'] != 3) {
    throw LessonFormatException('schema', 'expected schema 3');
  }
  final String course = _str(json['course'], 'course');
  final List<dynamic> ls = _list(json['lessons'], 'lessons');
  return LessonsFile(
    course: course,
    lessons: <LessonV3>[
      for (int i = 0; i < ls.length; i++) parseLesson(_map(ls[i], 'lessons[$i]'), 'lessons[$i]'),
    ],
  );
}

LessonV3 parseLesson(Map<String, dynamic> m, String path) {
  final String id = _str(m['id'], '$path.id');
  final List<dynamic> steps = _list(m['steps'], '$path.steps');
  return LessonV3(
    id: id,
    title: _str(m['title'], '$path.title'),
    intro: _optStr(m['intro']) ?? '',
    minutes: (m['minutes'] as num?)?.toInt(),
    steps: <V3Step>[
      for (int i = 0; i < steps.length; i++)
        parseStep(_map(steps[i], '$path.steps[$i]'), '$path.steps[$i]'),
    ],
  );
}

V3Step parseStep(Map<String, dynamic> m, String path) {
  final String id = _str(m['id'], '$path.id');
  final String kind = _str(m['kind'], '$path.kind');
  final String? label = _optStr(m['label']);
  final String? source = _optStr(m['source']);
  final String? review = _optStr(m['review']);
  switch (kind) {
    case 'teach':
    case 'why':
    case 'story':
      return TeachStep(
        id: id,
        style: TeachStyle.values.firstWhere((TeachStyle s) => s.name == kind),
        title: _str(m['title'], '$path.title'),
        paragraphs: _paragraphs(m['body'], '$path.body'),
        bullets: _strList(m['bullets'], '$path.bullets'),
        quranRef: _optStr(m['quran']),
        label: label,
        source: source,
        review: review,
      );
    case 'say':
      final List<String> sayRefs = <String>[
        ..._strList(m['refs'], '$path.refs'),
        if (_optStr(m['ref']) != null) _optStr(m['ref'])!,
      ];
      if (sayRefs.isEmpty) {
        throw LessonFormatException(path, 'a say step needs ref or refs');
      }
      return SayStep(
        id: id,
        refs: sayRefs,
        title: _optStr(m['title']) ?? '',
        note: _optStr(m['note']),
        words: _glossMap(m['words'], sayRefs.first, '$path.words'),
        label: label,
        source: source,
        review: review,
      );
    case 'listen':
      return ListenStep(
        id: id,
        ref: _str(m['ref'], '$path.ref'),
        title: _optStr(m['title']) ?? '',
        repeats: (m['repeats'] as num?)?.toInt() ?? 3,
        note: _optStr(m['note']),
      );
    case 'howto':
      final List<dynamic> hItems = _list(m['steps'], '$path.steps');
      return HowToStep(
        id: id,
        title: _str(m['title'], '$path.title'),
        intro: _optStr(m['intro']),
        items: <HowToItem>[
          for (int i = 0; i < hItems.length; i++)
            HowToItem(
              text: _str(_map(hItems[i], '$path.steps[$i]')['text'], '$path.steps[$i].text'),
              count: _optStr(_map(hItems[i], '$path.steps[$i]')['count']),
              detail: _optStr(_map(hItems[i], '$path.steps[$i]')['detail']),
            ),
        ],
        mistakes: _strList(m['mistakes'], '$path.mistakes'),
        label: label,
        source: source,
        review: review,
      );
    case 'contrast':
      final List<dynamic> rows = _list(m['rows'], '$path.rows');
      return ContrastStep(
        id: id,
        title: _str(m['title'], '$path.title'),
        intro: _optStr(m['intro']),
        agree: _optStr(m['agree']),
        closing: _optStr(m['closing']),
        rows: <ContrastRow>[
          for (int i = 0; i < rows.length; i++)
            ContrastRow(
              name: _str(_map(rows[i], '$path.rows[$i]')['name'], '$path.rows[$i].name'),
              text: _str(_map(rows[i], '$path.rows[$i]')['text'], '$path.rows[$i].text'),
            ),
        ],
        label: label ?? '[Interpretive]',
        source: source,
        review: review,
      );
    case 'arrange':
      final List<dynamic> aItems = _list(m['items'], '$path.items');
      return ArrangeStep(
        id: id,
        title: _optStr(m['title']) ?? '',
        prompt: _str(m['prompt'], '$path.prompt'),
        explain: _str(m['explain'], '$path.explain'),
        items: <ArrangeItem>[
          for (int i = 0; i < aItems.length; i++)
            ArrangeItem(
              text: _str(_map(aItems[i], '$path.items[$i]')['text'], '$path.items[$i].text'),
              why: _str(_map(aItems[i], '$path.items[$i]')['why'], '$path.items[$i].why'),
              back: _str(_map(aItems[i], '$path.items[$i]')['back'], '$path.items[$i].back'),
            ),
        ],
      );
    case 'match':
      final List<dynamic> pairs = _list(m['pairs'], '$path.pairs');
      return MatchStep(
        id: id,
        title: _optStr(m['title']) ?? '',
        prompt: _str(m['prompt'], '$path.prompt'),
        pairs: <MatchPair>[
          for (int i = 0; i < pairs.length; i++)
            MatchPair(
              left: Face.parse(_map(pairs[i], '$path.pairs[$i]')['left'], '$path.pairs[$i].left'),
              right: Face.parse(_map(pairs[i], '$path.pairs[$i]')['right'], '$path.pairs[$i].right'),
              why: _str(_map(pairs[i], '$path.pairs[$i]')['why'], '$path.pairs[$i].why'),
              back: _str(_map(pairs[i], '$path.pairs[$i]')['back'], '$path.pairs[$i].back'),
            ),
        ],
      );
    case 'check':
      final List<dynamic> cItems = _list(m['items'], '$path.items');
      return CheckStep(
        id: id,
        title: _optStr(m['title']) ?? '',
        items: <CheckItem>[
          for (int i = 0; i < cItems.length; i++)
            parseCheckItem(_map(cItems[i], '$path.items[$i]'), '$path.items[$i]'),
        ],
      );
    case 'recap':
      return RecapStep(
        id: id,
        title: _optStr(m['title']) ?? '',
        canDo: _strList(m['canDo'], '$path.canDo'),
        next: _optStr(m['next']),
      );
    case 'doit':
      return DoItStep(
        id: id,
        title: _str(m['title'], '$path.title'),
        body: _str(m['body'], '$path.body'),
        route: _str(m['route'], '$path.route'),
        button: _optStr(m['button']) ?? 'Open',
      );
  }
  throw LessonFormatException('$path.kind', 'unknown step kind "$kind"');
}

CheckItem parseCheckItem(Map<String, dynamic> m, String path) {
  final String id = _str(m['id'], '$path.id');
  final String? lookback = _optStr(m['lookback']);
  if (lookback != null) {
    return CheckItem(
      id: id,
      type: CheckType.mcq,
      question: '',
      options: const <CheckOption>[],
      answer: 0,
      explain: '',
      lookback: lookback,
    );
  }
  final String typeName = _optStr(m['type']) ?? 'mcq';
  final CheckType type = CheckType.values.firstWhere(
    (CheckType t) => t.name == typeName,
    orElse: () => throw LessonFormatException('$path.type', 'unknown type "$typeName"'),
  );
  final List<dynamic> opts = _list(m['options'], '$path.options');
  final Map<String, dynamic>? fill =
      m['fill'] == null ? null : _map(m['fill'], '$path.fill');
  return CheckItem(
    id: id,
    type: type,
    question: _str(m['q'], '$path.q'),
    scenario: _optStr(m['scenario']),
    ref: _optStr(m['ref']),
    fill: fill == null
        ? null
        : FillSpec(
            ref: _str(fill['ref'], '$path.fill.ref'),
            blank: (fill['blank'] as num?)?.toInt() ?? -1,
            show: _str(fill['show'], '$path.fill.show'),
          ),
    options: <CheckOption>[
      for (int i = 0; i < opts.length; i++)
        CheckOption(
          text: _optStr(_map(opts[i], '$path.options[$i]')['text']),
          word: _optStr(_map(opts[i], '$path.options[$i]')['word']),
          ref: _optStr(_map(opts[i], '$path.options[$i]')['ref']),
          reteach: _optStr(_map(opts[i], '$path.options[$i]')['reteach']),
          back: _optStr(_map(opts[i], '$path.options[$i]')['back']),
        ),
    ],
    answer: (m['answer'] as num?)?.toInt() ?? -1,
    explain: _str(m['explain'], '$path.explain'),
    review: m['review'] as bool? ?? true,
  );
}
