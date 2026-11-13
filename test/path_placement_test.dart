import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/academy/domain/learner_path.dart';
import 'package:ar_rayaan/features/academy/domain/path_placement.dart';
import 'package:ar_rayaan/features/academy/domain/review_questions.dart';
import 'package:ar_rayaan/features/academy/domain/v3/lesson_v3_model.dart';
import 'package:ar_rayaan/features/academy/domain/v3/lessons_v3.dart';
import 'package:ar_rayaan/features/academy/domain/v3/phrase_registry.dart';
import 'package:ar_rayaan/features/academy/domain/v3/quran_verses.dart';
import 'package:ar_rayaan/features/academy/presentation/widgets/path_placement_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

LessonsV3 _load() {
  List<String> read(String d) => <String>[
        for (final FileSystemEntity f in Directory(d).listSync())
          if (f is File && f.path.endsWith('.json')) f.readAsStringSync(),
      ];
  return LessonsV3.build(
    <LessonsFile>[
      for (final String raw in read('assets/academy/lessons_v3'))
        parseLessonsFile(jsonDecode(raw) as Map<String, dynamic>),
    ],
    PhraseRegistry.parseAll(read('assets/academy/phrases')),
    QuranVerses.parse(File('assets/quran/quran.json').readAsStringSync(),
        transliterationJson:
            File('assets/quran/transliteration.json').readAsStringSync()),
  );
}

void main() {
  group('placementFor', () {
    test('a miss in the first lesson starts at the beginning', () {
      final PathPlacementOutcome o = placementFor(<List<bool>>[
        <bool>[true, false],
        <bool>[true, true],
      ]);
      expect(o.startIndex == 0, isTrue);
      expect(o.level == LearnerLevel.fresh, isTrue);
    });
    test('starts at the first lesson with a miss, not the last', () {
      final PathPlacementOutcome o = placementFor(<List<bool>>[
        <bool>[true, true],
        <bool>[true, false],
        <bool>[false, false],
      ]);
      expect(o.startIndex == 1, isTrue);
      expect(o.level == LearnerLevel.basics, isTrue);
    });
    test('everything right means go deeper, with no start lesson', () {
      final PathPlacementOutcome o = placementFor(<List<bool>>[
        <bool>[true, true],
        <bool>[true, true],
      ]);
      expect(o.startIndex == null, isTrue);
      expect(o.level == LearnerLevel.deeper, isTrue);
    });
    test('a lesson with no questions never sends anyone backwards', () {
      final PathPlacementOutcome o = placementFor(<List<bool>>[
        <bool>[],
        <bool>[true, true],
      ]);
      expect(o.startIndex == null, isTrue);
    });
    test('the ladder is the Path in order', () {
      expect(kPathLadder.first == 'path.u0.l1', isTrue);
      expect(kPathLadder.length == 4, isTrue);
    });
  });

  group('the check is built from the Path\'s own lessons', () {
    test('every ladder lesson gives its questions, all valid', () {
      final List<PlacementRung> rungs = PathPlacementDialog.rungsFrom(_load());
      expect(rungs.length == kPathLadder.length, isTrue,
          reason: 'got ${rungs.length}');
      for (final PlacementRung r in rungs) {
        expect(r.questions.length == kPlacementPerLesson, isTrue,
            reason: r.title);
        for (final ReviewQuestion q in r.questions) {
          expect(q.isValid, isTrue, reason: r.title);
          expect(q.why.trim().isNotEmpty, isTrue, reason: r.title);
        }
        expect(r.route.startsWith('/academy/lesson/'), isTrue,
            reason: r.route);
      }
    });
  });

  group('the dialog', () {
    ReviewQuestion q(String p) => ReviewQuestion(
        prompt: p, options: const <String>['a', 'b'], answer: 0, why: 'w');
    Future<void> open(WidgetTester t, void Function(LearnerLevel) on) async {
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PathPlacementView(
            rungs: <PlacementRung>[
              PlacementRung(
                  title: 'One', route: '/one', questions: <ReviewQuestion>[q('Q1'), q('Q2')]),
              PlacementRung(
                  title: 'Two', route: '/two', questions: <ReviewQuestion>[q('Q3'), q('Q4')]),
            ],
            onAccept: on,
          ),
        ),
      ));
    }

    testWidgets('no answer is marked, and a miss in lesson two starts there',
        (WidgetTester t) async {
      LearnerLevel? saved;
      await open(t, (LearnerLevel l) => saved = l);
      expect(find.text('Question 1 of 4'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey<String>('pp-opt-0')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey<String>('pp-opt-0')));
      await t.pump();
      // Lesson two: one right, one "not sure".
      await t.tap(find.byKey(const ValueKey<String>('pp-opt-0')));
      await t.pump();
      expect(find.textContaining('wrong'), findsNothing);
      await t.tap(find.byKey(const ValueKey<String>('pp-skip')));
      await t.pump();
      expect(find.text('Where to begin'), findsOneWidget);
      expect(find.textContaining('Start with: Two'), findsOneWidget);
      expect(saved == null, isTrue, reason: 'nothing saved until accepted');
    });
  });
}
