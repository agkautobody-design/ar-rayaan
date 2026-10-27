import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/academy/domain/v3/lesson_v3_model.dart';
import 'package:ar_rayaan/features/academy/domain/v3/lesson_v3_state.dart';
import 'package:ar_rayaan/features/academy/domain/v3/lessons_v3.dart';
import 'package:ar_rayaan/features/academy/domain/v3/phrase_registry.dart';
import 'package:ar_rayaan/features/academy/domain/v3/quran_verses.dart';
import 'package:ar_rayaan/features/academy/presentation/v3/v3_gates.dart';
import 'package:ar_rayaan/features/academy/presentation/v3/v3_steps.dart';
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
  final LessonsV3 data = _load();
  final LessonV3 lesson = data['path.u1.l1']!;
  final CheckStep check = lesson.steps.whereType<CheckStep>().first;

  testWidgets('a wrong answer re-teaches, offers the step, never traps',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final CheckStepState st = CheckStepState(check, GatedRun());
    final CheckItem first = check.items.first;
    final int wrong = first.answer == 0 ? 1 : 0;
    String? wentBack;
    bool passed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CheckView(
            state: st,
            resolver: data.resolver,
            onGoBack: (String id) => wentBack = id,
            onPassed: () => passed = true,
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(Key('v3-option-$wrong')));
    await tester.pump();
    expect(find.byKey(const Key('v3-reteach')), findsOneWidget);
    expect(find.byKey(const Key('v3-explain')), findsNothing);
    await tester.tap(find.byKey(const Key('v3-show-step')));
    expect(wentBack, isNotNull);

    // A second wrong pick shows the answer.
    final int other = <int>[
      for (int i = 0; i < first.options.length; i++)
        if (i != first.answer && i != wrong) i,
    ].first;
    await tester.tap(find.byKey(Key('v3-option-$other')));
    await tester.pump();
    expect(find.byKey(const Key('v3-explain')), findsOneWidget);
    expect(passed, isFalse, reason: 'there are more questions');
  });

  testWidgets('a say step shows Arabic, transliteration and meaning',
      (WidgetTester tester) async {
    final SayStep say = data['path.u0.l1']!.steps.whereType<SayStep>().first;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SayView(step: say, resolver: data.resolver),
        ),
      ),
    ));
    expect(find.textContaining('Ash-hadu'), findsWidgets);
    expect(find.textContaining('I bear witness'), findsWidgets);
    // No recording exists for hadith text, so no hear-it button is faked.
    expect(find.byKey(const Key('v3-hear')), findsNothing);
  });
}
