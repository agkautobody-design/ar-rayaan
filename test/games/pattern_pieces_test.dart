import 'dart:math';

import 'package:ar_rayaan/features/games/engine/puzzle_engines.dart';
import 'package:ar_rayaan/features/games/presentation/puzzle_games.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const List<String> _names = <String>[
  'Twelve-point star',
  'Eight-point rosette',
  'Lotus',
  'Knot',
  'Hexagon',
  'Eight-point star',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pattern Sequence uses the six gold pieces and can be won',
      (WidgetTester tester) async {
    final SemanticsHandle sem = tester.ensureSemantics();
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const int seed = 11;
    await tester.pumpWidget(const MaterialApp(home: PatternScreen(seed: seed)));
    await tester.pump();
    // Six pieces to tap, each a picture.
    expect(find.byType(Image), findsWidgets);
    for (final String n in _names) {
      expect(find.bySemanticsLabel(n), findsOneWidget);
    }
    final List<int> full = patternSequence(Random(seed), 6);
    for (int round = 1; round <= 6; round++) {
      expect(find.text('ROUND $round OF 6'), findsOneWidget);
      // Let the showing finish (750 ms a step, two steps a symbol).
      await tester.pump(const Duration(seconds: 20));
      for (final int s in patternForRound(full, round)) {
        await tester.tap(find.bySemanticsLabel(_names[s]));
        await tester.pump();
      }
      await tester.pump();
    }
    expect(find.text('All 6 rounds cleared'), findsOneWidget);
    sem.dispose();
  });
}
