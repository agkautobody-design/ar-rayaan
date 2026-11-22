import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:ar_rayaan/features/games/engine/game_registry.dart';
import 'package:ar_rayaan/features/games/engine/puzzle_engines.dart';

void main() {
  batch2Tests();
  test('Shape Quest answers are right and options differ', () {
    for (int seed = 0; seed < 30; seed++) {
      final List<MathQuestion> qs = buildShapeQuestions(Random(seed));
      expect(qs.length, 10);
      for (final MathQuestion q in qs) {
        expect(q.options.toSet().length, 4);
        expect(q.options.every((int v) => v > 0), isTrue);
        final int a = q.options[q.answer];
        final RegExpMatch? m = RegExp(r'a (\w+)').firstMatch(q.text);
        const Map<String, int> n = <String, int>{
          'triangle': 3, 'square': 4, 'rectangle': 4, 'pentagon': 5,
          'hexagon': 6, 'heptagon': 7, 'octagon': 8, 'nonagon': 9,
          'decagon': 10,
        };
        final int sides = n[m!.group(1)]!;
        expect(a, q.text.contains('add up') ? (sides - 2) * 180 : sides);
      }
    }
  });
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

void batch2Tests() {
  group('Colour Sort', () {
    test('a new puzzle is full, mixed, and the same for the same seed', () {
      final ColourSort a = ColourSort.generate(Random(4));
      final ColourSort b = ColourSort.generate(Random(4));
      expect(a.tubes, b.tubes);
      expect(a.isSolved, isFalse);
      final List<int> all = a.tubes.expand((List<int> t) => t).toList()..sort();
      expect(all.length, 20);
      for (int c = 0; c < 5; c++) {
        expect(all.where((int v) => v == c).length, 4);
      }
    });

    test('pours only onto the same colour or empty, and wins when sorted', () {
      final ColourSort g = ColourSort.of(<List<int>>[
        <int>[0, 1, 1],
        <int>[0, 0, 0, 1],
        <int>[],
      ]);
      expect(g.canPour(0, 1), isFalse); // 1 onto 0
      expect(g.pour(1, 0), isTrue); // 1 onto 1 → [0,1,1,1]
      expect(g.tubes[0], <int>[0, 1, 1, 1]);
      expect(g.tubes[1], <int>[0, 0, 0]);
      expect(g.pour(0, 2), isTrue);
      expect(g.tubes[2], <int>[1, 1, 1]);
      expect(g.pour(0, 1), isTrue); // 0 onto 0 → [0,0,0,0]
      expect(g.tubes[1].length, 4);
      expect(g.isSolved, isFalse);
      final ColourSort done = ColourSort.of(<List<int>>[
        <int>[0, 0, 0, 0],
        <int>[],
      ]);
      expect(done.isSolved, isTrue);
    });
  });

  group('Towers', () {
    test('rules and the fewest moves', () {
      final Towers t = Towers(3);
      expect(t.best, 7);
      expect(t.canMove(1, 0), isFalse);
      expect(t.move(0, 2), isTrue);
      expect(t.canMove(0, 2), isFalse); // 2 onto 1
      expect(t.move(0, 1), isTrue);
      expect(t.move(2, 1), isTrue);
      expect(t.isSolved, isFalse);
    });

    test('the standard solution solves it in the fewest moves', () {
      final Towers t = Towers(4);
      void solve(int n, int a, int b, int c) {
        if (n == 0) return;
        solve(n - 1, a, c, b);
        expect(t.move(a, c), isTrue);
        solve(n - 1, b, a, c);
      }

      solve(4, 0, 1, 2);
      expect(t.isSolved, isTrue);
      expect(t.moves, t.best);
    });
  });

  group('Memory Numbers', () {
    test('right length, no leading zero, same seed same number', () {
      for (int d = 3; d <= 9; d++) {
        final String n = memoryNumber(Random(d), d);
        expect(n.length, d);
        expect(n.startsWith('0'), isFalse);
        expect(memoryNumber(Random(d), d), n);
      }
    });
  });

  group('Clue Hunt', () {
    test('the code has four different symbols and feedback is exact', () {
      final List<int> code = clueCode(Random(2));
      expect(code.toSet().length, 4);
      final ClueFeedback all = clueFeedback(code, code);
      expect(all.place, 4);
      expect(all.misplaced, 0);
      final ClueFeedback swap =
          clueFeedback(<int>[0, 1, 2, 3], <int>[1, 0, 2, 4]);
      expect(swap.place, 1);
      expect(swap.misplaced, 2);
    });
  });

  group('Sudoku', () {
    test('a puzzle has one answer, which fills every row, column and box', () {
      final SudokuPuzzle s = SudokuPuzzle.generate(Random(9), clues: 45);
      expect(SudokuPuzzle.countSolutions(s.puzzle), 1);
      for (int i = 0; i < 81; i++) {
        if (s.puzzle[i] != 0) expect(s.puzzle[i], s.solution[i]);
      }
      for (int k = 0; k < 9; k++) {
        final Set<int> row = <int>{}, col = <int>{}, box = <int>{};
        for (int j = 0; j < 9; j++) {
          row.add(s.solution[k * 9 + j]);
          col.add(s.solution[j * 9 + k]);
          box.add(s.solution[(k ~/ 3 * 3 + j ~/ 3) * 9 + k % 3 * 3 + j % 3]);
        }
        expect(row.length, 9);
        expect(col.length, 9);
        expect(box.length, 9);
      }
    });
  });
}
