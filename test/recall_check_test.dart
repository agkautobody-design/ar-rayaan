import 'package:ar_rayaan/features/academy/application/recall_checks.dart';
import 'package:ar_rayaan/features/academy/domain/academy_models.dart';
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

  group('generated recall checks are retired', () {
    test('no manifest lesson gets an auto-cloze check', () {
      expect(lessons.length, 146);
      expect(RecallChecks.generatedChecksEnabled, isFalse);
      for (final AcademyLesson l in lessons) {
        expect(RecallChecks.forLesson(l), isNull, reason: l.id);
        expect(identical(RecallChecks.stepsWithRecall(l), l.steps), isTrue,
            reason: l.id);
      }
    });

    test('hand-written assessments still resolve; recall ids do not', () {
      expect(RecallChecks.itemsFor('wudu.basics'), isNotNull);
      expect(RecallChecks.itemsFor('recall:no.such.lesson'), isNull);
      expect(RecallChecks.itemsFor('recall:${lessons.first.id}'), isNull);
    });
  });
}
