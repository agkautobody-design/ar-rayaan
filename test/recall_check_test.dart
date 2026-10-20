import 'package:ar_rayaan/features/academy/application/recall_checks.dart';
import 'package:ar_rayaan/features/academy/domain/academy_models.dart';
import 'package:ar_rayaan/features/academy/domain/assessment_engine.dart';
import 'package:ar_rayaan/features/academy/domain/course_manifest.dart';
import 'package:ar_rayaan/features/academy/domain/recall_check.dart';
import 'package:flutter_test/flutter_test.dart';

List<AcademyLesson> _allLessons() => <AcademyLesson>[
      for (final AcademyCourse c in kAcademyCourses)
        for (final AcademyUnit u in c.units) ...u.lessons,
    ];

void main() {
  final List<AcademyLesson> lessons = _allLessons();

  group('RecallCheckBuilder (units)', () {
    test('sentences split after . ! ? only at a word end', () {
      expect(
        RecallCheckBuilder.sentences('One two. Three four? Five six! Seven'),
        <String>['One two.', 'Three four?', 'Five six!', 'Seven'],
      );
      expect(RecallCheckBuilder.sentences('Pi is 3.14 roughly.'),
          <String>['Pi is 3.14 roughly.']);
    });

    test('candidate words: plain lower-case, 6+ letters, once, not filler', () {
      expect(
        RecallCheckBuilder.candidateWords(
            "Patience, patience and sa'i are gentle; Ramadan teaches discipline."),
        <String>['patience', 'gentle', 'teaches', 'discipline'],
      );
    });

    test('the seed is stable and web-safe (small)', () {
      expect(RecallCheckBuilder.seedOf('path.u5.l3'),
          RecallCheckBuilder.seedOf('path.u5.l3'));
      expect(RecallCheckBuilder.seedOf('path.u5.l3'), lessThan(1000003));
    });

    test('sentences with quotes, citations or reports are never blanked', () {
      final RecallCheck? q = RecallCheckBuilder.build(
        lessonId: 'x.1',
        teachingText: <String>[
          'The Messenger said, “fasting is a shield for you today” always.',
          'Fasting is prescribed in 2:183 for everyone alive today.',
          'Narrated by the companions about everything important today.',
        ],
        fullText: 'x',
        poolSorted: <String>['aaaaaaing', 'bbbbbbing', 'ccccccing'],
      );
      expect(q, isNull);
    });

    test('no check without two safe distractors', () {
      final RecallCheck? c = RecallCheckBuilder.build(
        lessonId: 'x.2',
        teachingText: <String>['Patience is the beginning of every worthy discipline.'],
        fullText: 'Patience is the beginning of every worthy discipline.',
        poolSorted: <String>['discipline', 'zzzzzzzz'],
      );
      expect(c, isNull);
    });

    test('hand-excluded lessons get no check', () {
      for (final String id in kRecallExcludedLessons) {
        expect(
          RecallCheckBuilder.build(
            lessonId: id,
            teachingText: <String>['Patience is the beginning of every worthy discipline.'],
            fullText: 'x',
            poolSorted: <String>['abcdefing', 'bcdefging', 'cdefghing'],
          ),
          isNull,
          reason: id,
        );
      }
    });
  });

  group('generated recall checks over the real manifest', () {
    final Map<AcademyLesson, RecallCheck> built = <AcademyLesson, RecallCheck>{
      for (final AcademyLesson l in lessons)
        if (RecallChecks.forLesson(l) != null) l: RecallChecks.forLesson(l)!,
    };

    test('a real share of lessons get a check (and the rest are listed)', () {
      expect(lessons.length, 146);
      expect(built.length, greaterThanOrEqualTo(50),
          reason: 'only ${built.length} of ${lessons.length} lessons');
    });

    test('the answer is the lesson’s own wording', () {
      for (final MapEntry<AcademyLesson, RecallCheck> e in built.entries) {
        final RecallCheck c = e.value;
        final String text = RecallChecks.fullTextOf(e.key);
        expect(text.contains(c.sentence), isTrue, reason: e.key.id);
        expect(c.prompt.split(kRecallBlank).length, 2,
            reason: 'exactly one blank in ${e.key.id}');
        expect(c.prompt.replaceFirst(kRecallBlank, c.answer), c.sentence,
            reason: e.key.id);
        expect(c.choices[c.correctIndex], c.answer);
      }
    });

    test('distractors never occur anywhere in the lesson', () {
      for (final MapEntry<AcademyLesson, RecallCheck> e in built.entries) {
        final Set<String> words =
            RecallCheckBuilder.allWords(RecallChecks.fullTextOf(e.key));
        final RecallCheck c = e.value;
        expect(c.choices.toSet().length, 3, reason: e.key.id);
        for (int i = 0; i < c.choices.length; i++) {
          if (i == c.correctIndex) continue;
          expect(words.contains(c.choices[i]), isFalse,
              reason: '${e.key.id}: ${c.choices[i]}');
        }
      }
    });

    test('no blanked sentence quotes, cites or carries Arabic', () {
      final RegExp bad = RegExp(
          '[\'"‘’“”]|\\d+:\\d+|Bukhari|Muslim|Tirmidhi|[؀-ۿ]');
      for (final MapEntry<AcademyLesson, RecallCheck> e in built.entries) {
        expect(bad.hasMatch(e.value.sentence), isFalse,
            reason: '${e.key.id}: ${e.value.sentence}');
      }
    });

    test('lessons with a hand-written check, and audit-flagged ones, get none',
        () {
      for (final AcademyLesson l in lessons) {
        if (RecallChecks.hasHandWrittenCheck(l)) {
          expect(RecallChecks.forLesson(l), isNull, reason: l.id);
        }
        if (kRecallExcludedLessons.contains(l.id)) {
          expect(RecallChecks.forLesson(l), isNull, reason: l.id);
        }
      }
    });

    test('the correct answer is spread over all three positions', () {
      final Set<int> positions =
          built.values.map((RecallCheck c) => c.correctIndex).toSet();
      expect(positions, <int>{0, 1, 2});
    });

    test('questions are deterministic and cached', () {
      for (final AcademyLesson l in lessons.take(40)) {
        final RecallCheck? a = RecallChecks.forLesson(l);
        final RecallCheck? b = RecallChecks.forLesson(l);
        expect(a?.prompt, b?.prompt);
        expect(a?.choices, b?.choices);
      }
    });

    test('grading: the right choice passes, any other fails', () {
      final AcademyLesson l = built.keys.first;
      final RecallCheck c = built[l]!;
      final AssessmentItem item = c.toItem();
      expect(item.literal, isTrue);
      expect(AssessmentEngine.evaluate(<AssessmentItem>[item],
              <int>[c.correctIndex]).passed,
          isTrue);
      for (int i = 0; i < 3; i++) {
        if (i == c.correctIndex) continue;
        expect(
            AssessmentEngine.evaluate(<AssessmentItem>[item], <int>[i]).passed,
            isFalse);
      }
      expect(item.reteachKey, contains(c.sentence));
    });

    test('stepsWithRecall appends one check step and itemsFor resolves it',
        () {
      final AcademyLesson l = built.keys.first;
      final List<AcademyStep> steps = RecallChecks.stepsWithRecall(l);
      expect(steps.length, l.steps.length + 1);
      expect(steps.last.kind, AcademyStepKind.check);
      expect(RecallChecks.itemsFor(steps.last.assessmentId!), isNotNull);
      expect(RecallChecks.itemsFor('recall:no.such.lesson'), isNull);
      // A lesson without a generated check is returned untouched.
      final AcademyLesson none =
          lessons.firstWhere((AcademyLesson x) => !built.containsKey(x));
      expect(identical(RecallChecks.stepsWithRecall(none), none.steps), isTrue);
      // Hand-written assessments still resolve.
      expect(RecallChecks.itemsFor('wudu.basics'), isNotNull);
    });
  });
}
