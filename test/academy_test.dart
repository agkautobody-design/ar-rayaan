import 'package:ar_rayaan/features/academy/domain/academy_models.dart';
import 'package:ar_rayaan/features/academy/domain/assessment_engine.dart';
import 'package:ar_rayaan/features/academy/domain/course_manifest.dart';
import 'package:ar_rayaan/features/academy/application/academy_providers.dart';
import 'package:ar_rayaan/features/academy/application/academy_strings.dart';
import 'package:ar_rayaan/features/academy/presentation/academy_home_screen.dart';
import 'package:ar_rayaan/features/academy/presentation/lesson_player_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  group('manifest integrity', () {
    test('all ids unique per kind', () {
      final courseIds = <String>{};
      final unitIds = <String>{};
      final lessonIds = <String>{};
      for (final c in kAcademyCourses) {
        expect(courseIds.add(c.id), isTrue, reason: 'dup course ${c.id}');
        for (final u in c.units) {
          expect(unitIds.add(u.id), isTrue, reason: 'dup unit ${u.id}');
          expect(u.courseId, c.id);
          for (final l in u.lessons) {
            expect(lessonIds.add(l.id), isTrue, reason: 'dup lesson ${l.id}');
            expect(l.unitId, u.id);
            expect(l.courseId, c.id);
            expect(l.steps, isNotEmpty);
          }
        }
      }
    });

    test('check steps resolve to assessment catalogs', () {
      for (final c in kAcademyCourses) {
        for (final u in c.units) {
          for (final l in u.lessons) {
            for (final s in l.steps) {
              if (s.kind == AcademyStepKind.check) {
                final items = kAssessments[s.assessmentId!];
                expect(items, isNotNull, reason: 'missing ${s.assessmentId}');
                expect(items!.length, greaterThanOrEqualTo(1));
                for (final it in items) {
                  expect(it.correctIndex, inInclusiveRange(0, it.choices.length - 1));
                }
              }
              if (s.kind == AcademyStepKind.embed) {
                expect(kEmbedRoutes.containsKey(s.ref), isTrue,
                    reason: 'unknown embed ref ${s.ref}');
              }
              if (s.kind == AcademyStepKind.action) {
                expect(s.route, isNotNull);
              }
            }
          }
        }
      }
    });

    test('all string keys resolve in English', () {
      final keys = <String>{};
      void collect(String k) {
        if (k.isNotEmpty) keys.add(k);
      }
      for (final c in kAcademyCourses) {
        collect(c.titleKey);
        collect(c.subtitleKey);
        for (final u in c.units) {
          collect(u.titleKey);
          collect(u.subtitleKey);
          for (final l in u.lessons) {
            collect(l.titleKey);
            for (final s in l.steps) {
              collect(s.titleKey);
              collect(s.bodyKey);
            }
          }
        }
      }
      for (final items in kAssessments.values) {
        for (final it in items) {
          collect(it.promptKey);
          collect(it.reteachKey);
          for (final ch in it.choices) {
            collect(ch);
          }
        }
      }
      final unresolved = keys
          .where((k) => AcademyStrings.get(k) == k)
          .toList();
      expect(unresolved, isEmpty, reason: 'unresolved keys: $unresolved');
    });
  });

  group('AssessmentEngine', () {
    final items = kAssessments['wudu.basics']!;

    test('all correct passes with no wrong ids', () {
      final answers = items.map((e) => e.correctIndex).toList();
      final r = AssessmentEngine.evaluate(items, answers);
      expect(r.passed, isTrue);
      expect(r.correct, items.length);
      expect(r.wrongItemIds, isEmpty);
    });

    test('any wrong fails and returns the id for reteach', () {
      final answers = items.map((e) => e.correctIndex).toList();
      answers[1] = (answers[1] + 1) % items[1].choices.length;
      final r = AssessmentEngine.evaluate(items, answers);
      expect(r.passed, isFalse);
      expect(r.wrongItemIds, <String>[items[1].id]);
    });
  });

  group('AcademyStrings', () {
    test('fallback to English for missing locale key', () {
      expect(AcademyStrings.get('path.title', locale: 'ar'), 'الرحلة');
      expect(AcademyStrings.get('academy.today', locale: 'ar'), 'اليوم');
      // key present in en but not ar → falls back
      expect(AcademyStrings.get('check.passed', locale: 'ar'),
          AcademyStrings.get('check.passed'));
    });

    test('unknown key returns the key (visible in QA, never crashes)', () {
      expect(AcademyStrings.get('nope.key'), 'nope.key');
    });

    test('supported locales listed', () {
      expect(AcademyStrings.supportedLocales,
          containsAll(<String>['en', 'ar', 'ur', 'fr', 'tr', 'id']));
    });
  });

  group('AcademyProgressNotifier', () {
    test('advance, complete, restart; persists across instances', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();

      final n1 = AcademyProgressNotifier(prefs);
      await n1.advance('path.u0.l1', 2);
      expect(n1.of('path.u0.l1').lastStep, 2);

      final n2 = AcademyProgressNotifier(prefs);
      expect(n2.of('path.u0.l1').lastStep, 2, reason: 'loaded from prefs');

      await n2.complete('path.u0.l1');
      final n3 = AcademyProgressNotifier(prefs);
      expect(n3.of('path.u0.l1').completed, isTrue);

      await n3.restart('path.u0.l1');
      final n4 = AcademyProgressNotifier(prefs);
      expect(n4.of('path.u0.l1').lastStep, 0);
      expect(n4.of('path.u0.l1').completed, isFalse);
    });

    test('advance never moves backwards within a lesson', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final n = AcademyProgressNotifier(prefs);
      await n.advance('l', 3);
      await n.advance('l', 1);
      expect(n.of('l').lastStep, 3);
    });
  });

  group('widgets', () {
    testWidgets('AcademyHomeScreen renders header, hero and the verse banner',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(await wrapWithProviders(const AcademyHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Al-Wasia Academy of Sacred Knowledge'), findsOneWidget);
      expect(find.text('Continue where you left off'), findsOneWidget);
      expect(find.text('Your first step'), findsOneWidget);

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.textContaining('39:9'), 250,
          scrollable: scrollable);
      expect(find.textContaining('39:9'), findsOneWidget);
    });

    testWidgets('AcademyHomeScreen shows the Path card and the open schools',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'ar.academy.progress.v1':
            '{"path.u0.l1":{"lastStep":4,"completed":true},'
            '"path.u1.l1":{"lastStep":4,"completed":true},'
            '"path.u2.l1":{"lastStep":3,"completed":true},'
            '"path.u3.l1":{"lastStep":3,"completed":true},'
            '"path.u4.l1":{"lastStep":3,"completed":true},'
            '"path.u5.l1":{"lastStep":2,"completed":true},'
            '"path.u6.l1":{"lastStep":2,"completed":true},'
            '"path.u7.l1":{"lastStep":2,"completed":true},'
            '"path.u8.l1":{"lastStep":2,"completed":true},'
            '"path.u9.l1":{"lastStep":2,"completed":true}}',
      });
      await tester.pumpWidget(await wrapWithProviders(const AcademyHomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('The Path'), findsOneWidget);

      final scrollable = find.byType(Scrollable).first;
      for (final t in <String>[
        'Letters', 'Recitation', 'Quranic Arabic', 'Understanding',
      ]) {
        await tester.scrollUntilVisible(find.text(t), 250,
            scrollable: scrollable);
        expect(find.text(t), findsOneWidget);
      }
      // Three schools open (LIVE), one honest SOON — the founder's design.
      expect(find.text('LIVE'), findsNWidgets(3));
      expect(find.text('SOON'), findsOneWidget);
    });

    testWidgets('LessonPlayerScreen advances steps on Next',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(await wrapWithProviders(
        const LessonPlayerScreen(
          courseId: 'the-path',
          unitId: 'path.u0',
          lessonId: 'path.u0.l1',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('1/4'), findsOneWidget);
      expect(find.text('You are welcome here'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('2/4'), findsOneWidget);
    });
  });
}
