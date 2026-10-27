/// How a v3 lesson feeds the app's existing spaced-review queue (FSRS).
///
/// A completed lesson is already queued by id (ReviewQueueNotifier.addLesson);
/// FSRS then decides WHEN it comes back. This file decides WHAT is asked when
/// it does: questions drawn from the lesson's own hand-written check items,
/// a few at a time, a different few each round. All right at the first pick is
/// "good"; any miss is "again" (it only comes back sooner). No points, no
/// scores, no streaks (see review_questions.dart).
library;

import 'dart:math';

import '../review_questions.dart';
import 'lesson_v3_model.dart';
import 'lesson_v3_state.dart' show stableSeed;
import 'phrase_resolver.dart';

/// How many questions one review of a lesson asks.
const int kV3QuestionsPerReview = 4;

/// The sentence of a fill item with its blank shown as "____".
String? fillSentence(CheckItem item, PhraseResolver r) {
  final FillSpec? f = item.fill;
  if (f == null) return null;
  final ResolvedPhrase? p = r.resolve(f.ref);
  if (p == null || p.lines.length != 1) return null;
  final ResolvedLine line = p.lines.first;
  final List<String> toks = f.show == 'arabic'
      ? PhraseResolver.tokens(line.arabic)
      : (line.translit ?? '').split(RegExp(r'\s+')).where((String t) => t.isNotEmpty).toList();
  if (f.blank < 0 || f.blank >= toks.length) return null;
  return <String>[
    for (int i = 0; i < toks.length; i++) i == f.blank ? '_____' : toks[i],
  ].join(' ');
}

/// The label of option [o] as text.
String optionLabel(CheckOption o, PhraseResolver r) {
  if (o.text != null) return o.text!;
  if (o.word != null) return r.wordArabic(o.word!) ?? '';
  if (o.ref != null) return r.resolve(o.ref!)?.arabicJoined ?? '';
  return '';
}

ReviewQuestion? reviewQuestionOf(CheckItem it, PhraseResolver r) {
  if (it.lookback != null || it.options.length < 2) return null;
  String? glyph;
  final String? ref = it.ref;
  if (ref != null) {
    final String? ar = r.resolve(ref)?.arabicJoined;
    if (ar != null && ar.length <= 120) glyph = ar;
  }
  final String? blanked = fillSentence(it, r);
  if (blanked != null && it.fill!.show == 'arabic') glyph = blanked;
  final StringBuffer prompt = StringBuffer();
  if ((it.scenario ?? '').isNotEmpty) prompt..write(it.scenario)..write('\n\n');
  prompt.write(it.question);
  if (blanked != null && it.fill!.show == 'translit') {
    prompt..write('\n\n')..write(blanked);
  }
  final ReviewQuestion q = ReviewQuestion(
    prompt: prompt.toString(),
    glyph: glyph,
    options: <String>[for (final CheckOption o in it.options) optionLabel(o, r)],
    answer: it.answer,
    why: it.explain,
  );
  return q.isValid ? q : null;
}

/// The questions for one review of [lesson]. [round] changes which items are
/// asked and how their choices are ordered, so repeats do not reward position.
List<ReviewQuestion> v3ReviewQuestions(
  LessonV3 lesson,
  PhraseResolver r, {
  int round = 0,
  int count = kV3QuestionsPerReview,
}) {
  final List<CheckItem> pool = <CheckItem>[
    for (final CheckItem it in lesson.checkItems)
      if (it.review && it.lookback == null) it,
  ];
  if (pool.isEmpty) return const <ReviewQuestion>[];
  final int n = pool.length;
  final int take = count < n ? count : n;
  final int start = (round < 0 ? 0 : round) * take % n;
  final Random rng = Random(stableSeed('${lesson.id}#review#$round'));
  final List<ReviewQuestion> out = <ReviewQuestion>[];
  for (int i = 0; i < take; i++) {
    final ReviewQuestion? q = reviewQuestionOf(pool[(start + i) % n], r);
    if (q != null) out.add(q.shuffled(rng));
  }
  return out;
}

/// All of the lesson's words as plain text: what Wasia is grounded on and what
/// the share / print handout carries. Includes the Arabic, its transliteration
/// and meaning, and every source the lesson names.
String lessonPlainText(LessonV3 lesson, PhraseResolver r) {
  final StringBuffer b = StringBuffer(lesson.title)..write('. ');
  void line(String? s) {
    if (s != null && s.trim().isNotEmpty) b..write(s.trim())..write(' ');
  }

  void phrase(String? ref) {
    if (ref == null) return;
    final ResolvedPhrase? p = r.resolve(ref);
    if (p == null) return;
    for (final ResolvedLine l in p.lines) {
      line(l.arabic);
      line(l.translit);
      line(l.meaning);
    }
    line(p.wholeMeaning);
    for (final String s in p.sources) {
      line('($s)');
    }
  }

  for (final V3Step s in lesson.steps) {
    line(s.source);
    switch (s) {
      case TeachStep():
        line(s.title);
        s.paragraphs.forEach(line);
        s.bullets.forEach(line);
        phrase(s.quranRef);
      case SayStep():
        line(s.title);
        s.refs.forEach(phrase);
        line(s.note);
      case ListenStep():
        line(s.title);
        phrase(s.ref);
        line(s.note);
      case HowToStep():
        line(s.title);
        line(s.intro);
        for (final HowToItem i in s.items) {
          line(i.text);
          line(i.count);
          line(i.detail);
        }
        s.mistakes.forEach(line);
      case ContrastStep():
        line(s.title);
        line(s.intro);
        line(s.agree);
        for (final ContrastRow v in s.rows) {
          line('${v.name}: ${v.text}');
        }
        line(s.closing);
      case ArrangeStep():
        line(s.prompt);
        for (final ArrangeItem i in s.items) {
          line('${i.text}. ${i.why}');
        }
      case MatchStep():
        line(s.prompt);
        for (final MatchPair p in s.pairs) {
          line(p.why);
        }
      case CheckStep():
        break;
      case RecapStep():
        line(s.title);
        s.canDo.forEach(line);
      case DoItStep():
        line(s.title);
        line(s.body);
    }
  }
  return b.toString().trim();
}

/// Every Qur'an / phrase source the lesson shows, for the sources sheet.
List<String> lessonSources(LessonV3 lesson, PhraseResolver r) {
  final List<String> out = <String>[];
  void add(String s) {
    if (s.trim().isNotEmpty && !out.contains(s)) out.add(s);
  }

  for (final V3Step s in lesson.steps) {
    add(s.source ?? '');
    final List<String> refs = switch (s) {
      SayStep() => s.refs,
      ListenStep() => <String>[s.ref],
      TeachStep() => <String>[if (s.quranRef != null) s.quranRef!],
      _ => const <String>[],
    };
    for (final String ref in refs) {
      r.resolve(ref)?.sources.forEach(add);
    }
  }
  return out;
}
