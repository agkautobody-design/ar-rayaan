import 'dart:math';

/// Rules of the single-player puzzle games, with no screen code so they can
/// be tested. Every generator takes a [Random]: the same seed gives the same
/// puzzle, which is how two friends racing get the same game.

// ---------------------------------------------------------------- Maze

/// A square maze with one route between any two cells.
class Maze {
  Maze._(this.size, this._open);

  final int size;

  /// For each cell, the four directions that are open: bit 0 up, 1 right,
  /// 2 down, 3 left.
  final List<int> _open;

  static const int up = 1, right = 2, down = 4, left = 8;
  static const List<int> dirs = <int>[up, right, down, left];

  /// A maze made by depth-first carving, so every cell is reachable.
  factory Maze.generate(int size, Random rnd) {
    final List<int> open = List<int>.filled(size * size, 0);
    final List<bool> seen = List<bool>.filled(size * size, false);
    final List<int> stack = <int>[0];
    seen[0] = true;
    while (stack.isNotEmpty) {
      final int cur = stack.last;
      final int r = cur ~/ size, c = cur % size;
      final List<int> options = <int>[];
      if (r > 0 && !seen[cur - size]) options.add(up);
      if (c < size - 1 && !seen[cur + 1]) options.add(right);
      if (r < size - 1 && !seen[cur + size]) options.add(down);
      if (c > 0 && !seen[cur - 1]) options.add(left);
      if (options.isEmpty) {
        stack.removeLast();
        continue;
      }
      final int d = options[rnd.nextInt(options.length)];
      final int next = switch (d) {
        up => cur - size,
        right => cur + 1,
        down => cur + size,
        _ => cur - 1,
      };
      open[cur] |= d;
      open[next] |= opposite(d);
      seen[next] = true;
      stack.add(next);
    }
    return Maze._(size, open);
  }

  static int opposite(int d) => switch (d) {
        up => down,
        down => up,
        left => right,
        _ => left,
      };

  /// The start (top left) and the exit (bottom right).
  int get start => 0;
  int get exit => size * size - 1;

  bool canMove(int cell, int dir) => (_open[cell] & dir) != 0;

  /// The cell after moving [dir] from [cell], or [cell] if a wall is there.
  int move(int cell, int dir) {
    if (!canMove(cell, dir)) return cell;
    return switch (dir) {
      up => cell - size,
      right => cell + 1,
      down => cell + size,
      _ => cell - 1,
    };
  }

  /// The cells on the way from [from] to the exit, [from] first.
  List<int> pathToExit(int from) {
    final List<int> prev = List<int>.filled(size * size, -1);
    final List<int> queue = <int>[from];
    prev[from] = from;
    for (int i = 0; i < queue.length; i++) {
      final int cur = queue[i];
      if (cur == exit) break;
      for (final int d in dirs) {
        if (!canMove(cur, d)) continue;
        final int n = move(cur, d);
        if (prev[n] == -1) {
          prev[n] = cur;
          queue.add(n);
        }
      }
    }
    final List<int> path = <int>[];
    int at = exit;
    while (at != from) {
      path.add(at);
      at = prev[at];
    }
    path.add(from);
    return path.reversed.toList();
  }

  /// Size of the maze for [level] (1 to 10): 5 cells a side, growing to 14.
  static int sizeForLevel(int level) => 4 + level.clamp(1, 10);
}

// ---------------------------------------------------------------- Math

/// One Math Quest question: a sum with its order of operations, four answers.
class MathQuestion {
  const MathQuestion(this.text, this.options, this.answer);
  final String text;
  final List<int> options;
  final int answer;
}

/// [count] questions, getting harder as they go. Only whole numbers, no
/// negative answers; the sum is worked out by the rules (× and ÷ first).
List<MathQuestion> buildMathQuestions(Random rnd, {int count = 10}) {
  final List<MathQuestion> out = <MathQuestion>[];
  for (int i = 0; i < count; i++) {
    final int hard = i ~/ 3; // 0..3
    int value;
    String text;
    switch (rnd.nextInt(hard == 0 ? 2 : 4)) {
      case 0:
        final int a = 6 + rnd.nextInt(14 + hard * 10);
        final int b = 3 + rnd.nextInt(10 + hard * 8);
        text = '$a + $b';
        value = a + b;
      case 1:
        final int a = 20 + rnd.nextInt(40 + hard * 20);
        final int b = 3 + rnd.nextInt(15);
        text = '$a − $b';
        value = a - b;
      case 2:
        final int b = 2 + rnd.nextInt(8);
        final int q = 2 + rnd.nextInt(8 + hard);
        final int c = 1 + rnd.nextInt(12 + hard * 4);
        text = '${b * q} ÷ $b + $c';
        value = q + c;
      default:
        final int a = 2 + rnd.nextInt(7 + hard);
        final int b = 2 + rnd.nextInt(8);
        final int c = 1 + rnd.nextInt(10 + hard * 3);
        text = '$a × $b − $c';
        value = a * b - c;
        if (value < 0) {
          text = '$a × $b + $c';
          value = a * b + c;
        }
    }
    final Set<int> opts = <int>{value};
    int guard = 0;
    while (opts.length < 4 && guard++ < 200) {
      final int off = 1 + rnd.nextInt(4 + hard * 2);
      final int w = rnd.nextBool() ? value + off : value - off;
      if (w >= 0) opts.add(w);
    }
    int pad = 1;
    while (opts.length < 4) {
      opts.add(value + 10 + pad++);
    }
    final List<int> shuffled = opts.toList()..shuffle(rnd);
    out.add(MathQuestion('$text = ?', shuffled, shuffled.indexOf(value)));
  }
  return out;
}

// ------------------------------------------------------------- Pattern

/// The symbols of Pattern Sequence, by index 0 to 5.
const int kPatternSymbols = 6;

/// The sequence for [round] (1 to 10): it is the same sequence each round
/// with one more symbol on the end, so a player can build on what they know.
List<int> patternSequence(Random rnd, int rounds) {
  return <int>[for (int i = 0; i < rounds + 2; i++) rnd.nextInt(kPatternSymbols)];
}

/// The first `round + 2` symbols of [full].
List<int> patternForRound(List<int> full, int round) =>
    full.sublist(0, (round + 2).clamp(0, full.length));

// ------------------------------------------------------------- Sliding

/// The 4 by 4 sliding tile puzzle. 0 is the empty square.
class SlidingPuzzle {
  SlidingPuzzle._(this.tiles, this.moves);

  final List<int> tiles;
  int moves;

  static const int side = 4;

  /// Solved: 1 to 15 then the empty square.
  static List<int> solved() => <int>[...List<int>.generate(15, (int i) => i + 1), 0];

  /// Shuffled by making [shuffles] random legal moves from the solved board,
  /// so the puzzle can always be solved.
  factory SlidingPuzzle.shuffled(Random rnd, {int shuffles = 120}) {
    final SlidingPuzzle p = SlidingPuzzle._(solved(), 0);
    int last = -1;
    for (int i = 0; i < shuffles; i++) {
      final int blank = p.tiles.indexOf(0);
      final List<int> near = p._neighbours(blank)..remove(last);
      final int pick = near[rnd.nextInt(near.length)];
      last = blank;
      p._swap(blank, pick);
    }
    if (p.isSolved) return SlidingPuzzle.shuffled(rnd, shuffles: shuffles + 7);
    p.moves = 0;
    return p;
  }

  /// A puzzle with these tiles, for tests.
  factory SlidingPuzzle.of(List<int> tiles) => SlidingPuzzle._(List<int>.of(tiles), 0);

  List<int> _neighbours(int i) {
    final int r = i ~/ side, c = i % side;
    return <int>[
      if (r > 0) i - side,
      if (r < side - 1) i + side,
      if (c > 0) i - 1,
      if (c < side - 1) i + 1,
    ];
  }

  void _swap(int a, int b) {
    final int t = tiles[a];
    tiles[a] = tiles[b];
    tiles[b] = t;
  }

  /// Slides the tile at [index] into the empty square if they touch.
  /// Returns whether it moved.
  bool tap(int index) {
    final int blank = tiles.indexOf(0);
    if (!_neighbours(blank).contains(index)) return false;
    _swap(blank, index);
    moves++;
    return true;
  }

  bool get isSolved {
    final List<int> s = solved();
    for (int i = 0; i < s.length; i++) {
      if (tiles[i] != s[i]) return false;
    }
    return true;
  }
}

// --------------------------------------------------------------- 2048

/// The 2048 board: 4 by 4, slide and merge, new 2s and 4s from a seed.
class MergeGame {
  MergeGame(this._rnd) : cells = List<int>.filled(16, 0) {
    _spawn();
    _spawn();
  }

  final Random _rnd;
  final List<int> cells;
  int score = 0;

  static const int side = 4;

  int at(int r, int c) => cells[r * side + c];

  void _spawn() {
    final List<int> empty = <int>[
      for (int i = 0; i < cells.length; i++)
        if (cells[i] == 0) i,
    ];
    if (empty.isEmpty) return;
    cells[empty[_rnd.nextInt(empty.length)]] = _rnd.nextInt(10) == 0 ? 4 : 2;
  }

  /// Slides every line toward [dir] ('left', 'right', 'up', 'down') and
  /// merges equal neighbours once per move. Returns whether anything moved
  /// (if so a new tile appears).
  bool slide(String dir) {
    bool moved = false;
    for (int line = 0; line < side; line++) {
      final List<int> idx = <int>[
        for (int k = 0; k < side; k++)
          switch (dir) {
            'left' => line * side + k,
            'right' => line * side + (side - 1 - k),
            'up' => k * side + line,
            _ => (side - 1 - k) * side + line,
          },
      ];
      final List<int> vals = <int>[for (final int i in idx) cells[i]]
          .where((int v) => v != 0)
          .toList();
      final List<int> merged = <int>[];
      for (int k = 0; k < vals.length; k++) {
        if (k + 1 < vals.length && vals[k] == vals[k + 1]) {
          merged.add(vals[k] * 2);
          score += vals[k] * 2;
          k++;
        } else {
          merged.add(vals[k]);
        }
      }
      while (merged.length < side) {
        merged.add(0);
      }
      for (int k = 0; k < side; k++) {
        if (cells[idx[k]] != merged[k]) moved = true;
        cells[idx[k]] = merged[k];
      }
    }
    if (moved) _spawn();
    return moved;
  }

  bool get canMove {
    if (cells.contains(0)) return true;
    for (int r = 0; r < side; r++) {
      for (int c = 0; c < side; c++) {
        final int v = at(r, c);
        if (c + 1 < side && at(r, c + 1) == v) return true;
        if (r + 1 < side && at(r + 1, c) == v) return true;
      }
    }
    return false;
  }

  int get best => cells.reduce(max);
  bool get reached2048 => best >= 2048;
}

// ---------------------------------------------------------- Logic grid

/// A clue in Logic Grid.
class GridClue {
  const GridClue(this.kind, this.item, this.house);

  /// 'not' (not in that house), 'in' (lives in that house) or 'next'
  /// (lives in a house next to that house).
  final String kind;
  final int item;
  final int house;
}

/// Four things, four houses in a row; every clue is true and the clues
/// together allow exactly one answer.
class LogicGridPuzzle {
  LogicGridPuzzle(this.solution, this.clues);

  /// `solution[item]` is the house (0 to 3) that item lives in.
  final List<int> solution;
  final List<GridClue> clues;

  static const int n = 4;

  static bool holds(GridClue c, List<int> arrangement) {
    final int h = arrangement[c.item];
    return switch (c.kind) {
      'not' => h != c.house,
      'in' => h == c.house,
      _ => (h - c.house).abs() == 1,
    };
  }

  static List<List<int>> _allArrangements() {
    final List<List<int>> out = <List<int>>[];
    void go(List<int> cur, Set<int> used) {
      if (cur.length == n) {
        out.add(List<int>.of(cur));
        return;
      }
      for (int h = 0; h < n; h++) {
        if (used.contains(h)) continue;
        cur.add(h);
        used.add(h);
        go(cur, used);
        used.remove(h);
        cur.removeLast();
      }
    }

    go(<int>[], <int>{});
    return out;
  }

  /// How many arrangements satisfy all of [clues].
  static int countSolutions(List<GridClue> clues) => _allArrangements()
      .where((List<int> a) => clues.every((GridClue c) => holds(c, a)))
      .length;

  /// A random puzzle. True clues are added until one answer is left, then any
  /// clue that is not needed is dropped.
  factory LogicGridPuzzle.generate(Random rnd) {
    final List<int> sol = <int>[0, 1, 2, 3]..shuffle(rnd);
    final List<GridClue> pool = <GridClue>[];
    for (int item = 0; item < n; item++) {
      for (int house = 0; house < n; house++) {
        final GridClue not = GridClue('not', item, house);
        if (holds(not, sol)) pool.add(not);
        final GridClue next = GridClue('next', item, house);
        if (holds(next, sol)) pool.add(next);
      }
      pool.add(GridClue('in', item, sol[item]));
    }
    pool.shuffle(rnd);
    // Prefer the weaker clues first so "lives in" does not give it all away.
    pool.sort((GridClue a, GridClue b) =>
        (a.kind == 'in' ? 1 : 0).compareTo(b.kind == 'in' ? 1 : 0));
    final List<GridClue> chosen = <GridClue>[];
    for (final GridClue c in pool) {
      chosen.add(c);
      if (countSolutions(chosen) == 1) break;
    }
    // Drop clues that are not needed.
    for (int i = chosen.length - 1; i >= 0; i--) {
      final List<GridClue> without = List<GridClue>.of(chosen)..removeAt(i);
      if (countSolutions(without) == 1) chosen.removeAt(i);
    }
    return LogicGridPuzzle(sol, chosen);
  }
}
