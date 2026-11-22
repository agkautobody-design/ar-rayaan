import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:ar_rayaan/features/games/engine/game_registry.dart';
import 'package:ar_rayaan/features/games/engine/puzzle_engines.dart';

void main() {
  group('Maze', () {
    test('every cell can be reached and the exit is on the route', () {
      for (int seed = 0; seed < 20; seed++) {
        final Maze m = Maze.generate(9, Random(seed));
        final List<int> path = m.pathToExit(m.start);
        expect(path.first, m.start);
        expect(path.last, m.exit);
        for (int i = 0; i + 1 < path.length; i++) {
          final bool step = Maze.dirs
              .any((int d) => m.canMove(path[i], d) && m.move(path[i], d) == path[i + 1]);
          expect(step, isTrue, reason: 'seed $seed step $i');
        }
        // A perfect maze: n*n - 1 open passages.
        int open = 0;
        for (int c = 0; c < 81; c++) {
          if (m.canMove(c, Maze.right)) open++;
          if (m.canMove(c, Maze.down)) open++;
        }
        expect(open, 80);
      }
    });

    test('walls block, and the same seed gives the same maze', () {
      final Maze a = Maze.generate(7, Random(5));
      final Maze b = Maze.generate(7, Random(5));
      for (int c = 0; c < 49; c++) {
        for (final int d in Maze.dirs) {
          expect(a.canMove(c, d), b.canMove(c, d));
          if (!a.canMove(c, d)) expect(a.move(c, d), c);
        }
      }
    });
  });

  group('Math Quest', () {
    test('answers are right, options differ, same seed same questions', () {
      for (int seed = 0; seed < 30; seed++) {
        final List<MathQuestion> qs = buildMathQuestions(Random(seed));
        expect(qs.length, 10);
        for (final MathQuestion q in qs) {
          expect(q.options.toSet().length, 4);
          expect(q.options.every((int v) => v >= 0), isTrue);
          expect(q.options[q.answer], _eval(q.text));
        }
        expect(
          buildMathQuestions(Random(seed)).map((MathQuestion q) => q.text),
          qs.map((MathQuestion q) => q.text),
        );
      }
    });
  });

  group('Pattern', () {
    test('rounds grow by one and keep the same start', () {
      final List<int> full = patternSequence(Random(3), 6);
      expect(full.length, 8);
      expect(patternForRound(full, 1).length, 3);
      expect(patternForRound(full, 6), full);
      expect(patternForRound(full, 2).sublist(0, 3), patternForRound(full, 1));
      expect(full.every((int s) => s >= 0 && s < kPatternSymbols), isTrue);
    });
  });

  group('Sliding Tile', () {
    test('a shuffled puzzle is not solved and can be undone by legal moves', () {
      final SlidingPuzzle p = SlidingPuzzle.shuffled(Random(1));
      expect(p.isSolved, isFalse);
      expect(p.tiles.toList()..sort(), <int>[...List<int>.generate(16, (int i) => i)]);
      expect(p.moves, 0);
    });

    test('only a tile next to the gap moves', () {
      final SlidingPuzzle p = SlidingPuzzle.of(SlidingPuzzle.solved());
      expect(p.tap(0), isFalse);
      expect(p.tap(11), isTrue); // above the gap at 15
      expect(p.tiles[15], 12);
      expect(p.tiles[11], 0);
      expect(p.moves, 1);
      expect(p.isSolved, isFalse);
      expect(p.tap(15), isTrue);
      expect(p.isSolved, isTrue);
    });
  });

  group('Number Merge', () {
    test('slides, merges once per move, and scores', () {
      final MergeGame g = MergeGame(Random(0));
      for (int i = 0; i < 16; i++) {
        g.cells[i] = 0;
      }
      g.cells[0] = 2;
      g.cells[1] = 2;
      g.cells[2] = 4;
      expect(g.slide('left'), isTrue);
      expect(g.at(0, 0), 4);
      expect(g.at(0, 1), 4);
      expect(g.score, 4);
    });

    test('a move that changes nothing adds no tile', () {
      final MergeGame g = MergeGame(Random(0));
      for (int i = 0; i < 16; i++) {
        g.cells[i] = 0;
      }
      g.cells[0] = 2;
      final List<int> before = List<int>.of(g.cells);
      expect(g.slide('left'), isFalse);
      expect(g.cells, before);
    });

    test('a full board with no equal neighbours cannot move', () {
      final MergeGame g = MergeGame(Random(0));
      const List<int> v = <int>[2, 4, 2, 4, 4, 2, 4, 2, 2, 4, 2, 4, 4, 2, 4, 2];
      for (int i = 0; i < 16; i++) {
        g.cells[i] = v[i];
      }
      expect(g.canMove, isFalse);
    });
  });

  group('Logic Grid', () {
    test('every puzzle has exactly one answer and the clues are true', () {
      for (int seed = 0; seed < 25; seed++) {
        final LogicGridPuzzle p = LogicGridPuzzle.generate(Random(seed));
        expect(LogicGridPuzzle.countSolutions(p.clues), 1, reason: 'seed $seed');
        for (final GridClue c in p.clues) {
          expect(LogicGridPuzzle.holds(c, p.solution), isTrue);
        }
        expect(p.clues.length, lessThan(14));
      }
    });
  });

  group('registry', () {
    test('the puzzle games can be raced and have a route', () {
      for (final String id in kRacePuzzleIds) {
        final GameDef g = gameById(id)!;
        expect(g.canRace, isTrue, reason: id);
        expect(g.route, '/games/$id');
      }
    });
  });
}

/// Evaluates "a + b = ?" style text with × ÷ before + −.
int _eval(String text) {
  final String e = text.replaceAll(' = ?', '');
  final List<String> t = e.split(' ');
  int i = 0;
  // First pass: × and ÷.
  final List<String> work = <String>[t[0]];
  for (i = 1; i < t.length; i += 2) {
    final String op = t[i];
    final String rhs = t[i + 1];
    if (op == '×' || op == '÷') {
      final int a = int.parse(work.removeLast());
      final int b = int.parse(rhs);
      work.add('${op == '×' ? a * b : a ~/ b}');
    } else {
      work..add(op)..add(rhs);
    }
  }
  int v = int.parse(work[0]);
  for (i = 1; i < work.length; i += 2) {
    final int b = int.parse(work[i + 1]);
    v = work[i] == '+' ? v + b : v - b;
  }
  return v;
}
