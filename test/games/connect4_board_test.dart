import 'package:ar_rayaan/features/games/engine/board_engines.dart';
import 'package:ar_rayaan/features/games/presentation/board_games.dart';
import 'package:ar_rayaan/features/games/ui/connect4_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the board draws six rows by seven columns and reports taps',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final ConnectFour g = ConnectFour()
      ..drop(3)
      ..drop(3);
    final List<int> taps = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Connect4Board(game: g, onDrop: taps.add),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.bySemanticsLabel('emerald token'), findsOneWidget);
    expect(find.bySemanticsLabel('ruby token'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Drop in column \d')), findsNWidgets(7));
    await tester.tap(find.bySemanticsLabel('Drop in column 5'));
    expect(taps, <int>[4]);
  });

  testWidgets('two players on one device: Emerald then Ruby, four wins',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: ConnectFourScreen()));
    await tester.pump();
    await tester.tap(find.text('Two players, one device'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('EMERALD, YOUR TURN'), findsOneWidget);
    Future<void> col(int c) async {
      await tester.tap(find.bySemanticsLabel('Drop in column $c'));
      await tester.pump(const Duration(milliseconds: 400));
    }
    // Emerald stacks column 1, Ruby column 2.
    for (final int c in <int>[1, 2, 1, 2, 1, 2, 1]) {
      await col(c);
    }
    expect(find.text('EMERALD WINS'), findsOneWidget);
  });
}
