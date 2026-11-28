import 'package:ar_rayaan/features/games/engine/board_engines.dart';
import 'package:ar_rayaan/features/games/presentation/board_games.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String _label(int i, String what) =>
    'Row ${i ~/ 8 + 1}, column ${i % 8 + 1}, $what';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('two players on one device: Ruby moves, then Onyx',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: DraughtsScreen()));
    await tester.pump();
    await tester.tap(find.text('Two players, one device'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('RUBY, YOUR TURN'), findsOneWidget);
    expect(find.text('Ruby: 12   ·   Onyx: 12'), findsOneWidget);

    final Draughts g = Draughts();
    final List<int> mv = g.moves().first;
    await tester.tap(find.bySemanticsLabel(_label(mv.first, 'ruby man')));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(
        _label(mv[1], 'empty, you can move here')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('ONYX, YOUR TURN'), findsOneWidget);
  });
}
