/// The loaded set of Academy v3 lessons, plus the checks that keep them honest.
///
/// [LessonsV3.build] merges every `lessons_v3/*.json` file, resolves the
/// "look back" items that point into earlier lessons, and keeps the phrase
/// registry and the Qur'an text the lessons are resolved against.
/// [validateLesson] is run by the tests (and in debug builds) over every
/// lesson: a lesson that names a phrase that is not there, quotes Arabic that
/// differs from quran.json, lets a wrong answer go without a re-teach, or
/// promises "[Established]" without a source does not pass.
library;

import 'lesson_v3_model.dart';
import 'phrase_registry.dart';
import 'phrase_resolver.dart';
import 'quran_verses.dart';

/// App routes a "do it for real" step may open.
bool isDoItRoute(String route) {
  const Set<String> fixed = <String>{
    '/prayer',
    '/qibla',
    '/quran',
    '/hadi',
    '/calendar',
    '/adhkar',
  };
  if (fixed.contains(route)) return true;
  final RegExpMatch? m = RegExp(r'^/quran/(\d{1,3})$').firstMatch(route);
  if (m == null) return false;
  final int n = int.parse(m.group(1)!);
  return n >= 1 && n <= 114;
}

class LessonsV3 {
  LessonsV3._(this.lessons, this.registry, this.quran, this.problems)
      : resolver = PhraseResolver(registry, quran);

  /// Lesson id -> lesson (the id of the manifest lesson it replaces).
  final Map<String, LessonV3> lessons;
  final PhraseRegistry registry;
  final QuranVerses quran;
  final PhraseResolver resolver;

  /// Problems found while merging (duplicate ids, broken look backs).
  final List<String> problems;

  LessonV3? operator [](String id) => lessons[id];

  bool has(String id) => lessons.containsKey(id);

  static LessonsV3 build(
    List<LessonsFile> files,
    PhraseRegistry registry,
    QuranVerses quran,
  ) {
    final List<String> problems = <String>[];
    final Map<String, LessonV3> byId = <String, LessonV3>{};
    for (final LessonsFile f in files) {
      for (final LessonV3 l in f.lessons) {
        if (byId.containsKey(l.id)) {
          problems.add('lesson "${l.id}" is defined twice');
          continue;
        }
        byId[l.id] = l;
      }
    }
    final Map<String, LessonV3> resolved = <String, LessonV3>{};
    for (final LessonV3 l in byId.values) {
      resolved[l.id] = _resolveLookbacks(l, byId, problems);
    }
    return LessonsV3._(resolved, registry, quran, problems);
  }

  static LessonV3 _resolveLookbacks(
    LessonV3 lesson,
    Map<String, LessonV3> all,
    List<String> problems,
  ) {
    final List<V3Step> steps = <V3Step>[];
    for (final V3Step s in lesson.steps) {
      if (s is! CheckStep) {
        steps.add(s);
        continue;
      }
      final List<CheckItem> items = <CheckItem>[];
      for (final CheckItem it in s.items) {
        final String? lb = it.lookback;
        if (lb == null) {
          items.add(it);
          continue;
        }
        final List<String> parts = lb.split('#');
        CheckItem? target;
        if (parts.length == 2 && parts[0] != lesson.id) {
          for (final CheckItem c in all[parts[0]]?.checkItems ?? const <CheckItem>[]) {
            if (c.id == parts[1] && c.lookback == null) target = c;
          }
        }
        if (target == null) {
          problems.add('${lesson.id}/${s.id}/${it.id}: look back "$lb" does not point at an item of another lesson');
          continue;
        }
        items.add(CheckItem(
          id: it.id,
          type: target.type,
          question: target.question,
          options: <CheckOption>[
            for (final CheckOption o in target.options)
              CheckOption(text: o.text, word: o.word, ref: o.ref, reteach: o.reteach),
          ],
          answer: target.answer,
          explain: target.explain,
          scenario: target.scenario,
          ref: target.ref,
          fill: target.fill,
          // A look back is practice, not new material: it stays out of the
          // spaced-review pool of this lesson (its own lesson holds it).
          review: false,
          isLookBack: true,
        ));
      }
      steps.add(CheckStep(id: s.id, title: s.title, items: items));
    }
    return LessonV3(
      id: lesson.id,
      title: lesson.title,
      intro: lesson.intro,
      minutes: lesson.minutes,
      steps: steps,
    );
  }
}

/// Words that must never appear in a lesson: no points, streaks, coins, badges
/// or ranks on religious acts.
final RegExp kForbiddenLessonWords = RegExp(
  r'\b(points?|streaks?|coins?|badges?|leaderboard|xp|rewards? points)\b',
  caseSensitive: false,
);

/// Every piece of text a learner reads in [lesson] (no Arabic): used for the
/// forbidden-word rule.
List<String> lessonTexts(LessonV3 lesson) {
  final List<String> out = <String>[lesson.title, lesson.intro];
  for (final V3Step s in lesson.steps) {
    if (s.source != null) out.add(s.source!);
    switch (s) {
      case TeachStep():
        out..add(s.title)..addAll(s.paragraphs)..addAll(s.bullets);
      case SayStep():
        out..add(s.title)..add(s.note ?? '');
      case ListenStep():
        out..add(s.title)..add(s.note ?? '');
      case HowToStep():
        out..add(s.title)..add(s.intro ?? '')..addAll(s.mistakes);
        for (final HowToItem i in s.items) {
          out..add(i.text)..add(i.count ?? '')..add(i.detail ?? '');
        }
      case ContrastStep():
        out..add(s.title)..add(s.intro ?? '')..add(s.agree ?? '')..add(s.closing ?? '');
        for (final ContrastRow v in s.rows) {
          out..add(v.name)..add(v.text);
        }
      case ArrangeStep():
        out..add(s.title)..add(s.prompt)..add(s.explain);
        for (final ArrangeItem i in s.items) {
          out..add(i.text)..add(i.why);
        }
      case MatchStep():
        out..add(s.title)..add(s.prompt);
        for (final MatchPair p in s.pairs) {
          out..add(p.left.text ?? '')..add(p.right.text ?? '')..add(p.why);
        }
      case CheckStep():
        out.add(s.title);
        for (final CheckItem i in s.items) {
          out..add(i.question)..add(i.scenario ?? '')..add(i.explain);
          for (final CheckOption o in i.options) {
            out..add(o.text ?? '')..add(o.reteach ?? '');
          }
        }
      case RecapStep():
        out..add(s.title)..addAll(s.canDo)..add(s.next ?? '');
      case DoItStep():
        out..add(s.title)..add(s.body)..add(s.button);
    }
  }
  return out;
}

String _normToken(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z؀-ۿ\-]'), '');

/// Problems with [lesson] (empty when it is sound). [r] resolves its phrases.
List<String> validateLesson(LessonV3 lesson, PhraseResolver r) {
  final List<String> out = <String>[];
  void bad(String stepId, String msg) => out.add('${lesson.id}/$stepId: $msg');

  if (lesson.steps.isEmpty) out.add('${lesson.id}: no steps');
  final Set<String> seen = <String>{};
  final Map<String, int> indexOf = <String, int>{};
  for (int i = 0; i < lesson.steps.length; i++) {
    final V3Step s = lesson.steps[i];
    if (!seen.add(s.id)) bad(s.id, 'step id used twice');
    indexOf[s.id] = i;
  }

  bool earlier(String back, int at) {
    final int? j = indexOf[back];
    return j != null && j < at;
  }

  for (int at = 0; at < lesson.steps.length; at++) {
    final V3Step s = lesson.steps[at];
    final String? label = s.label;
    if (label != null && !kHonestyLabels.contains(label)) {
      bad(s.id, 'unknown label "$label"');
    }
    if (label == '[Established]' && (s.source ?? '').trim().isEmpty) {
      bad(s.id, 'is [Established] but names no source');
    }
    switch (s) {
      case TeachStep():
        if (s.paragraphs.isEmpty) bad(s.id, 'no text');
        final String? q = s.quranRef;
        if (q != null && r.resolve(q) == null) bad(s.id, 'ayah "$q" does not resolve');
      case SayStep():
        for (final String ref in s.refs) {
          final ResolvedPhrase? p = r.resolve(ref);
          if (p == null) {
            bad(s.id, 'phrase "$ref" does not resolve');
          } else if (!p.verified) {
            bad(s.id, 'shows "$ref", which is not verified');
          }
        }
        for (final MapEntry<String, List<GlossSpec>> e in s.words.entries) {
          final ResolvedPhrase? p = r.resolve(e.key);
          if (!s.refs.contains(e.key) ||
              p == null ||
              p.lines.length != 1 ||
              e.value.length != PhraseResolver.tokens(p.lines.first.arabic).length) {
            bad(s.id, 'word glosses for "${e.key}" do not match its Arabic words');
          }
        }
      case ListenStep():
        final ResolvedPhrase? p = r.resolve(s.ref);
        if (!s.ref.startsWith('q:') || p == null || !p.hasAudio) {
          bad(s.id, 'listen needs an ayah with real audio, got "${s.ref}"');
        }
        if (s.repeats < 1 || s.repeats > 5) bad(s.id, 'repeats must be 1 to 5');
      case HowToStep():
        if (s.items.length < 2) bad(s.id, 'a how-to needs at least two steps');
      case ContrastStep():
        if (s.rows.length < 2) bad(s.id, 'a contrast needs at least two rows');
      case ArrangeStep():
        if (s.items.length < 3) bad(s.id, 'arrange needs at least three items');
        for (final ArrangeItem i in s.items) {
          if (!earlier(i.back, at)) bad(s.id, 'back "${i.back}" is not an earlier step');
        }
      case MatchStep():
        if (s.pairs.length < 3) bad(s.id, 'match needs at least three pairs');
        for (final MatchPair p in s.pairs) {
          if (!earlier(p.back, at)) bad(s.id, 'back "${p.back}" is not an earlier step');
          for (final Face f in <Face>[p.left, p.right]) {
            if (f.ref != null && r.resolve(f.ref!) == null) {
              bad(s.id, 'match face "${f.ref}" does not resolve');
            }
            if (f.word != null && r.wordArabic(f.word!) == null) {
              bad(s.id, 'match word "${f.word}" does not resolve');
            }
          }
        }
      case CheckStep():
        if (s.items.isEmpty) bad(s.id, 'check with no items');
        final Set<String> ids = <String>{};
        for (final CheckItem it in s.items) {
          if (!ids.add(it.id)) bad(s.id, 'item id "${it.id}" used twice');
          _validateItem(lesson, s, it, at, r, out, earlier);
        }
      case RecapStep():
        if (s.canDo.length < 3) bad(s.id, 'a recap lists at least three things you can now do');
      case DoItStep():
        if (!isDoItRoute(s.route)) bad(s.id, 'route "${s.route}" is not an allowed app route');
    }
  }

  if (!lesson.steps.any((V3Step s) => s is CheckStep || s is ArrangeStep || s is MatchStep)) {
    out.add('${lesson.id}: no gating step (check, arrange or match)');
  }
  if (!lesson.steps.any((V3Step s) => s is RecapStep)) {
    out.add('${lesson.id}: no recap step');
  }
  for (final String t in lessonTexts(lesson)) {
    final RegExpMatch? m = kForbiddenLessonWords.firstMatch(t);
    if (m != null) {
      out.add('${lesson.id}: forbidden word "${m.group(0)}" in "$t"');
    }
  }
  return out;
}

void _validateItem(
  LessonV3 lesson,
  CheckStep step,
  CheckItem it,
  int at,
  PhraseResolver r,
  List<String> out,
  bool Function(String back, int at) earlier,
) {
  void bad(String msg) => out.add('${lesson.id}/${step.id}/${it.id}: $msg');
  if (it.lookback != null) {
    bad('look back was not resolved');
    return;
  }
  if (it.options.length < 2 || it.options.length > 5) bad('needs 2 to 5 options');
  if (it.answer < 0 || it.answer >= it.options.length) {
    bad('answer ${it.answer} is not an option');
    return;
  }
  if (it.type == CheckType.scenario && (it.scenario ?? '').trim().isEmpty) {
    bad('a scenario item needs scenario text');
  }
  if (it.ref != null && r.resolve(it.ref!) == null) bad('ref "${it.ref}" does not resolve');

  final Set<String> shown = <String>{};
  for (int i = 0; i < it.options.length; i++) {
    final CheckOption o = it.options[i];
    final int given = <Object?>[o.text, o.word, o.ref].where((Object? x) => x != null).length;
    if (given != 1) bad('option $i must give exactly one of text, word, ref');
    String? shownAs = o.text;
    if (o.word != null) {
      shownAs = r.wordArabic(o.word!);
      if (shownAs == null) bad('option $i word "${o.word}" does not resolve');
    }
    if (o.ref != null) {
      final ResolvedPhrase? p = r.resolve(o.ref!);
      if (p == null) {
        bad('option $i ref "${o.ref}" does not resolve');
      } else {
        shownAs = p.arabicJoined;
      }
    }
    if (shownAs != null && !shown.add(shownAs)) bad('two options show the same thing');
    if (i != it.answer) {
      if ((o.reteach ?? '').trim().isEmpty) bad('wrong option $i has no re-teach text');
      final String? back = o.back;
      if (!it.isLookBack && (back == null || !earlier(back, at))) {
        bad('wrong option $i must point back to an earlier step (got "$back")');
      }
    }
  }

  final FillSpec? f = it.fill;
  if (it.type == CheckType.fill) {
    if (f == null) {
      bad('a fill item needs a fill spec');
      return;
    }
    final ResolvedPhrase? p = r.resolve(f.ref);
    if (p == null || p.lines.length != 1) {
      bad('fill ref "${f.ref}" must resolve to one line');
      return;
    }
    final ResolvedLine line = p.lines.first;
    if (f.show == 'arabic') {
      final List<String> toks = PhraseResolver.tokens(line.arabic);
      if (f.blank < 0 || f.blank >= toks.length) {
        bad('blank ${f.blank} is outside the ${toks.length} words');
        return;
      }
      for (int i = 0; i < it.options.length; i++) {
        if (it.options[i].word == null) bad('an Arabic fill option must be a word reference');
      }
      final String? right = r.wordArabic(it.options[it.answer].word ?? '');
      if (right != toks[f.blank]) {
        bad('the right option is not the blanked word "${toks[f.blank]}"');
      }
    } else if (f.show == 'translit') {
      final String tr = line.translit ?? '';
      final List<String> toks =
          tr.split(RegExp(r'\s+')).where((String t) => t.isNotEmpty).toList();
      if (f.blank < 0 || f.blank >= toks.length) {
        bad('blank ${f.blank} is outside the ${toks.length} transliteration words');
        return;
      }
      final String right = _normToken(it.options[it.answer].text ?? '');
      if (right != _normToken(toks[f.blank])) {
        bad('the right option is not the blanked word "${toks[f.blank]}"');
      }
    } else {
      bad('fill show must be "arabic" or "translit"');
    }
  } else if (f != null) {
    bad('only a fill item takes a fill spec');
  }
}
