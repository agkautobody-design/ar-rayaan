import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/academy/domain/v3/lesson_v3_model.dart';
import 'package:ar_rayaan/features/academy/domain/v3/lesson_v3_review.dart';
import 'package:ar_rayaan/features/academy/domain/v3/lesson_v3_state.dart';
import 'package:ar_rayaan/features/academy/domain/v3/lessons_v3.dart';
import 'package:ar_rayaan/features/academy/domain/v3/phrase_registry.dart';
import 'package:ar_rayaan/features/academy/domain/v3/phrase_resolver.dart';
import 'package:ar_rayaan/features/academy/domain/v3/quran_verses.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _read(String dir) => <String>[
      for (final FileSystemEntity f in Directory(dir).listSync())
        if (f is File && f.path.endsWith('.json')) f.readAsStringSync(),
    ];

LessonsV3 _load() {
  final PhraseRegistry reg =
      PhraseRegistry.parseAll(_read('assets/academy/phrases'));
  final QuranVerses quran = QuranVerses.parse(
    File('assets/quran/quran.json').readAsStringSync(),
    transliterationJson:
        File('assets/quran/transliteration.json').readAsStringSync(),
  );
  final List<LessonsFile> files = <LessonsFile>[
    for (final String raw in _read('assets/academy/lessons_v3'))
      parseLessonsFile(jsonDecode(raw) as Map<String, dynamic>),
  ];
  return LessonsV3.build(files, reg, quran);
}

LessonV3 _lessonWith(List<V3Step> steps) =>
    LessonV3(id: 't.l1', title: 'T', steps: steps);

void main() {
  final LessonsV3 all = _load();

  group('verified-phrase registry', () {
    test('has no problems and no duplicate ids', () {
      expect(all.registry.problems(), isEmpty);
      expect(all.registry.duplicates, isEmpty);
    });

    test('every phrase has a source, a status and a review flag', () {
      for (final VerifiedPhrase p in all.registry.phrases.values) {
        expect(p.sources, isNotEmpty, reason: p.id);
        expect(p.needsScholarReview, isTrue, reason: p.id);
        if (p.status == PhraseStatus.verified && !p.isComposite) {
          expect(p.arabic, isNotNull, reason: p.id);
          expect(p.copiedFrom, isNotNull, reason: p.id);
        }
      }
    });

    test('composite phrases resolve to their parts in order', () {
      final ResolvedPhrase? p = all.resolver.resolve('shahada.full');
      expect(p, isNotNull);
      expect(p!.lines.length, 2);
      expect(p.hasAudio, isFalse, reason: 'no recording exists for hadith text');
    });
  });

  group('Qur\'an references', () {
    test('an ayah renders exactly the quran.json text', () {
      final List<dynamic> data = jsonDecode(
          File('assets/quran/quran.json').readAsStringSync()) as List<dynamic>;
      final Map<String, dynamic> fatiha = data.first as Map<String, dynamic>;
      final List<dynamic> v = fatiha['v'] as List<dynamic>;
      for (int a = 1; a <= 7; a++) {
        final ResolvedPhrase? p = all.resolver.resolve('q:1:$a');
        expect(p!.lines.single.arabic, (v[a - 1] as List<dynamic>)[1]);
        expect(p.hasAudio, isTrue);
      }
    });

    test('a reference that does not exist does not resolve', () {
      expect(all.resolver.resolve('q:1:8'), isNull);
      expect(all.resolver.resolve('q:115:1'), isNull);
      expect(all.resolver.resolve('no.such.phrase'), isNull);
    });
  });

  group('the foundation lessons', () {
    const List<String> ids = <String>[
      'path.u0.l1',
      'path.u1.l1',
      'path.u2.l1',
      'path.u3.l1',
    ];

    test('are all present and the merge reports no problem', () {
      expect(all.problems, isEmpty);
      for (final String id in ids) {
        expect(all.has(id), isTrue, reason: id);
      }
    });

    test('pass validation (phrases resolve, wrong answers re-teach)', () {
      for (final String id in ids) {
        expect(validateLesson(all[id]!, all.resolver), isEmpty, reason: id);
      }
    });

    test('mix learning modes, 8 to 15 steps, 8+ check items', () {
      for (final String id in ids) {
        final LessonV3 l = all[id]!;
        expect(l.steps.length, inInclusiveRange(8, 15), reason: id);
        expect(l.checkItems.length, greaterThanOrEqualTo(8), reason: id);
        final Set<String> kinds = l.steps.map((V3Step s) => s.kind).toSet();
        expect(kinds.length, greaterThanOrEqualTo(7), reason: id);
        expect(kinds, contains('arrange'));
        expect(kinds, contains('recap'));
      }
    });

    test('rak\'ah counts are as taught', () {
      final String text = lessonPlainText(all['path.u2.l1']!, all.resolver);
      expect(text, contains('Fajr (2 rak’ahs), Dhuhr (4), Asr (4), Maghrib (3) and Isha (4)'));
    });

    test('the Fatihah lesson has real audio and all seven ayat', () {
      final LessonV3 l = all['path.u3.l1']!;
      final Set<String> refs = <String>{
        for (final V3Step s in l.steps)
          if (s is SayStep) ...s.refs,
      };
      for (int a = 1; a <= 7; a++) {
        expect(refs, contains('q:1:$a'));
      }
      expect(l.steps.whereType<ListenStep>(), isNotEmpty);
    });

    test('review asks a few questions and varies by round', () {
      final LessonV3 l = all['path.u1.l1']!;
      final qs = v3ReviewQuestions(l, all.resolver);
      expect(qs.length, kV3QuestionsPerReview);
      for (final q in qs) {
        expect(q.isValid, isTrue);
      }
      expect(v3ReviewQuestions(l, all.resolver, round: 1).first.prompt,
          isNot(qs.first.prompt));
    });
  });

  group('validation catches a broken lesson', () {
    test('a step that names a missing phrase fails', () {
      final LessonV3 l = _lessonWith(<V3Step>[
        const SayStep(id: 's', refs: <String>['no.such.phrase']),
        const RecapStep(id: 'r', canDo: <String>['a', 'b', 'c']),
      ]);
      final List<String> p = validateLesson(l, all.resolver);
      expect(p.any((String m) => m.contains('does not resolve')), isTrue);
    });

    test('a wrong option without a re-teach fails', () {
      final LessonV3 l = _lessonWith(<V3Step>[
        const TeachStep(
            id: 'a', style: TeachStyle.teach, title: 't', paragraphs: <String>['x']),
        const CheckStep(id: 'c', items: <CheckItem>[
          CheckItem(
            id: 'i',
            type: CheckType.mcq,
            question: 'q',
            options: <CheckOption>[
              CheckOption(text: 'right'),
              CheckOption(text: 'wrong'),
            ],
            answer: 0,
            explain: 'e',
          ),
        ]),
        RecapStep(id: 'r', canDo: <String>['a', 'b', 'c']),
      ]);
      final List<String> p = validateLesson(l, all.resolver);
      expect(p.any((String m) => m.contains('re-teach')), isTrue);
    });

    test('[Established] without a source fails', () {
      final LessonV3 l = _lessonWith(<V3Step>[
        const TeachStep(
            id: 'a',
            style: TeachStyle.teach,
            title: 't',
            paragraphs: <String>['x'],
            label: '[Established]'),
        const ArrangeStep(id: 'z', prompt: 'p', explain: 'e', items: <ArrangeItem>[
          ArrangeItem(text: '1', why: 'w', back: 'a'),
          ArrangeItem(text: '2', why: 'w', back: 'a'),
          ArrangeItem(text: '3', why: 'w', back: 'a'),
        ]),
        const RecapStep(id: 'r', canDo: <String>['a', 'b', 'c']),
      ]);
      final List<String> p = validateLesson(l, all.resolver);
      expect(p.any((String m) => m.contains('names no source')), isTrue);
    });

    test('points and streaks are not allowed in lesson text', () {
      final LessonV3 l = _lessonWith(<V3Step>[
        const TeachStep(
            id: 'a',
            style: TeachStyle.teach,
            title: 't',
            paragraphs: <String>['Earn 10 points']),
        const RecapStep(id: 'r', canDo: <String>['a', 'b', 'c']),
      ]);
      expect(validateLesson(l, all.resolver).any((String m) => m.contains('forbidden')),
          isTrue);
    });

    test('a listen step needs an ayah with real audio', () {
      final LessonV3 l = _lessonWith(<V3Step>[
        const ListenStep(id: 'l', ref: 'takbir'),
        const RecapStep(id: 'r', canDo: <String>['a', 'b', 'c']),
      ]);
      expect(validateLesson(l, all.resolver).any((String m) => m.contains('real audio')),
          isTrue);
    });
  });

  group('gating', () {
    CheckStep step() => const CheckStep(id: 'c', items: <CheckItem>[
          CheckItem(
            id: 'i',
            type: CheckType.mcq,
            question: 'q',
            options: <CheckOption>[
              CheckOption(text: 'a', reteach: 'because a', back: 's1'),
              CheckOption(text: 'right'),
              CheckOption(text: 'b', reteach: 'because b', back: 's2'),
            ],
            answer: 1,
            explain: 'why',
          ),
        ]);

    test('a wrong answer re-teaches and names the step', () {
      final CheckStepState st = CheckStepState(step(), GatedRun());
      final PickResult r = st.pick(0);
      expect(r.correct, isFalse);
      expect(r.reteach, 'because a');
      expect(r.back, 's1');
      expect(st.allSettled, isFalse);
    });

    test('after two misses the answer is shown and the learner is released', () {
      final CheckStepState st = CheckStepState(step(), GatedRun());
      st.pick(0);
      final PickResult r = st.pick(2);
      expect(r.revealed, isTrue);
      expect(st.allSettled, isTrue);
      expect(st.run.revealedKeys, <String>['c/i']);
    });

    test('the right answer settles it', () {
      final CheckStepState st = CheckStepState(step(), GatedRun());
      expect(st.pick(1).correct, isTrue);
      expect(st.allSettled, isTrue);
      expect(st.run.revealedKeys, isEmpty);
    });

    test('arrange: wrong order re-teaches, second miss reveals', () {
      const ArrangeStep a = ArrangeStep(id: 'a', prompt: 'p', explain: 'ex', items: <ArrangeItem>[
        ArrangeItem(text: 'one', why: 'w1', back: 's'),
        ArrangeItem(text: 'two', why: 'w2', back: 's'),
        ArrangeItem(text: 'three', why: 'w3', back: 's'),
      ]);
      final ArrangeState st = ArrangeState(a, GatedRun());
      expect(st.pool, isNot(<int>[0, 1, 2]));
      st..place(1)..place(0)..place(2);
      final ArrangeFeedback f = st.check();
      expect(f.correct, isFalse);
      expect(f.back, 's');
      expect(st.placed, isEmpty, reason: 'the wrong place and all after it are handed back');
      st..place(2)..place(1)..place(0);
      final ArrangeFeedback g = st.check();
      expect(g.revealed, isTrue);
      expect(st.settled, isTrue);
    });

    test('match: wrong pairing re-teaches, never traps', () {
      const MatchStep m = MatchStep(id: 'm', prompt: 'p', pairs: <MatchPair>[
        MatchPair(left: Face(text: 'a'), right: Face(text: 'A'), why: 'wa', back: 's'),
        MatchPair(left: Face(text: 'b'), right: Face(text: 'B'), why: 'wb', back: 's'),
        MatchPair(left: Face(text: 'c'), right: Face(text: 'C'), why: 'wc', back: 's'),
      ]);
      final MatchState st = MatchState(m, GatedRun());
      st.selectLeft(0);
      expect(st.tapRight(1)!.correct, isFalse);
      expect(st.tapRight(2)!.revealed, isTrue);
      expect(st.done, contains(0));
      st.selectLeft(1);
      expect(st.tapRight(1)!.correct, isTrue);
      st.selectLeft(2);
      expect(st.tapRight(2)!.correct, isTrue);
      expect(st.allSettled, isTrue);
    });
  });
}
