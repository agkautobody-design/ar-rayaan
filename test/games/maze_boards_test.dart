import 'package:ar_rayaan/features/games/engine/maze_boards.dart';
import 'package:ar_rayaan/features/games/engine/puzzle_engines.dart';
import 'package:ar_rayaan/features/games/presentation/puzzle_games.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

LogicalKeyboardKey _key(int dir) => switch (dir) {
      Maze.up => LogicalKeyboardKey.arrowUp,
      Maze.right => LogicalKeyboardKey.arrowRight,
      Maze.down => LogicalKeyboardKey.arrowDown,
      _ => LogicalKeyboardKey.arrowLeft,
    };

/// The key presses that walk [m] from [from] to its exit.
List<LogicalKeyboardKey> _walk(Maze m, int from) {
  final List<int> path = m.pathToExit(from);
  final List<LogicalKeyboardKey> keys = <LogicalKeyboardKey>[];
  for (int i = 0; i + 1 < path.length; i++) {
    final int d =
        Maze.dirs.firstWhere((int d) => m.move(path[i], d) == path[i + 1]);
    keys.add(_key(d));
  }
  return keys;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the twelve maze boards', () {
    test('there are twelve, smallest first, each with one hex digit a cell',
        () {
      expect(kMazeBoards.length, 12);
      final List<int> sizes =
          kMazeBoards.map((MazeBoard b) => b.size).toList();
      expect(sizes, <int>[5, 6, 8, 9, 11, 12, 14, 16, 18, 20, 23, 26]);
      for (final MazeBoard b in kMazeBoards) {
        expect(b.open.length, b.size * b.size, reason: b.asset);
        expect(RegExp(r'^[0-9a-f]+$').hasMatch(b.open), isTrue);
      }
    });

    test('every board is a proper maze with a way from start to exit', () {
      for (final MazeBoard b in kMazeBoards) {
        final Maze m = Maze.fromOpen(b.size, b.open);
        int passages = 0;
        for (int c = 0; c < b.size * b.size; c++) {
          final int r = c ~/ b.size, col = c % b.size;
          // A door in one cell is a door in the next, and none leads out.
          if (m.canMove(c, Maze.right)) {
            expect(col < b.size - 1, isTrue, reason: '${b.asset} edge');
            expect(m.canMove(c + 1, Maze.left), isTrue, reason: b.asset);
            passages++;
          }
          if (m.canMove(c, Maze.down)) {
            expect(r < b.size - 1, isTrue, reason: '${b.asset} edge');
            expect(m.canMove(c + b.size, Maze.up), isTrue, reason: b.asset);
            passages++;
          }
          if (m.canMove(c, Maze.left)) expect(col > 0, isTrue);
          if (m.canMove(c, Maze.up)) expect(r > 0, isTrue);
        }
        // One route between any two cells: cells - 1 passages, all joined.
        expect(passages, b.size * b.size - 1, reason: b.asset);
        final Set<int> seen = <int>{m.start};
        final List<int> todo = <int>[m.start];
        while (todo.isNotEmpty) {
          final int c = todo.removeLast();
          for (final int d in Maze.dirs) {
            final int n = m.move(c, d);
            if (seen.add(n)) todo.add(n);
          }
        }
        expect(seen.length, b.size * b.size, reason: b.asset);
        final List<int> route = m.pathToExit(m.start);
        expect(route.first, m.start);
        expect(route.last, m.exit);
      }
    });

    test('the walker sits on the picture at the start and at the exit', () {
      for (final MazeBoard b in kMazeBoards) {
        final (double x0, double y0) = b.centre(0, 0);
        final (double x1, double y1) = b.centre(b.size - 1, b.size - 1);
        for (final double v in <double>[x0, y0, x1, y1]) {
          expect(v, inExclusiveRange(0, 1));
        }
        expect(x1, greaterThan(x0));
        expect(y1, greaterThan(y0));
      }
    });
  });

  testWidgets('Maze Escape: all twelve boards can be walked out of',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: MazeScreen()));
    await tester.pump();
    expect(find.text('MAZE 1 OF 12 · 0 MOVES'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(find.byKey(const ValueKey<String>('maze-walker')), findsOneWidget);

    int moves = 0;
    for (int level = 0; level < 12; level++) {
      final MazeBoard b = kMazeBoards[level];
      final Maze m = Maze.fromOpen(b.size, b.open);
      // A wall stops the walker: try the way that is shut at the start.
      final int shut =
          Maze.dirs.firstWhere((int d) => !m.canMove(m.start, d));
      await tester.sendKeyEvent(_key(shut));
      await tester.pump();
      for (final LogicalKeyboardKey k in _walk(m, m.start)) {
        await tester.sendKeyEvent(k);
        moves++;
      }
      await tester.pump(const Duration(milliseconds: 200));
      if (level < 11) {
        expect(find.text('MAZE ${level + 2} OF 12 · $moves MOVES'),
            findsOneWidget,
            reason: 'after board ${b.size}');
      }
    }
    expect(find.text('Out of all 12 mazes'), findsOneWidget);
  });
}
