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

// ---------------------------------------------------------- Colour Sort

/// Tubes of coloured water. Pour the top colour onto the same colour or into
/// an empty tube until every tube holds one colour.
class ColourSort {
  ColourSort._(this.tubes);

  /// Each tube lists its colours from the bottom up.
  final List<List<int>> tubes;
  int moves = 0;

  static const int capacity = 4;

  /// [colours] colours, plus two empty tubes, shuffled by a seeded random.
  factory ColourSort.generate(Random rnd, {int colours = 5}) {
    final List<int> pool = <int>[
      for (int c = 0; c < colours; c++)
        for (int k = 0; k < capacity; k++) c,
    ];
    ColourSort g;
    do {
      pool.shuffle(rnd);
      g = ColourSort._(<List<int>>[
        for (int t = 0; t < colours; t++)
          pool.sublist(t * capacity, (t + 1) * capacity),
        <int>[],
        <int>[],
      ]);
    } while (g.isSolved);
    return g;
  }

  factory ColourSort.of(List<List<int>> tubes) =>
      ColourSort._(<List<int>>[for (final List<int> t in tubes) List<int>.of(t)]);

  /// How many of the top colour of [tube] sit together.
  int _run(List<int> tube) {
    if (tube.isEmpty) return 0;
    int n = 0;
    for (int i = tube.length - 1; i >= 0 && tube[i] == tube.last; i--) {
      n++;
    }
    return n;
  }

  bool canPour(int from, int to) {
    if (from == to) return false;
    final List<int> a = tubes[from], b = tubes[to];
    if (a.isEmpty || b.length >= capacity) return false;
    if (b.isNotEmpty && b.last != a.last) return false;
    // Pouring a whole tube into an empty one only shuffles it.
    if (b.isEmpty && _run(a) == a.length) return false;
    return true;
  }

  /// Pours as much of the top colour as fits. Returns whether anything moved.
  bool pour(int from, int to) {
    if (!canPour(from, to)) return false;
    final List<int> a = tubes[from], b = tubes[to];
    int n = min(_run(a), capacity - b.length);
    while (n-- > 0) {
      b.add(a.removeLast());
    }
    moves++;
    return true;
  }

  bool get isSolved => tubes.every((List<int> t) =>
      t.isEmpty || (t.length == capacity && t.every((int c) => c == t.first)));

  bool get isStuck {
    for (int i = 0; i < tubes.length; i++) {
      for (int j = 0; j < tubes.length; j++) {
        if (canPour(i, j)) return false;
      }
    }
    return !isSolved;
  }
}

// ------------------------------------------------------------- Towers

/// Tower of Hanoi: move the stack to the last peg, one disc at a time, never
/// a bigger disc on a smaller one.
class Towers {
  Towers(this.discs)
      : pegs = <List<int>>[
          <int>[for (int d = discs; d >= 1; d--) d],
          <int>[],
          <int>[],
        ];

  final int discs;
  final List<List<int>> pegs;
  int moves = 0;

  /// The fewest moves that can solve it.
  int get best => (1 << discs) - 1;

  bool canMove(int from, int to) {
    if (from == to || pegs[from].isEmpty) return false;
    return pegs[to].isEmpty || pegs[to].last > pegs[from].last;
  }

  bool move(int from, int to) {
    if (!canMove(from, to)) return false;
    pegs[to].add(pegs[from].removeLast());
    moves++;
    return true;
  }

  bool get isSolved => pegs[2].length == discs;
}

// ------------------------------------------------------ Memory Numbers

/// A number to remember: [digits] digits, no leading zero.
String memoryNumber(Random rnd, int digits) {
  final StringBuffer b = StringBuffer('${1 + rnd.nextInt(9)}');
  for (int i = 1; i < digits; i++) {
    b.write(rnd.nextInt(10));
  }
  return b.toString();
}

// -------------------------------------------------------- Clue Hunt

/// Feedback on a guess in Clue Hunt: how many symbols are right and in the
/// right place, and how many are right but in the wrong place.
class ClueFeedback {
  const ClueFeedback(this.place, this.misplaced);
  final int place;
  final int misplaced;
}

/// A hidden code of four symbols out of six, with no symbol repeated.
List<int> clueCode(Random rnd) =>
    (<int>[0, 1, 2, 3, 4, 5]..shuffle(rnd)).sublist(0, 4);

/// Compares [guess] with [code].
ClueFeedback clueFeedback(List<int> code, List<int> guess) {
  int place = 0, shared = 0;
  for (int i = 0; i < code.length; i++) {
    if (guess[i] == code[i]) place++;
    if (code.contains(guess[i])) shared++;
  }
  return ClueFeedback(place, shared - place);
}

// ------------------------------------------------------------- Sudoku

/// A 9 by 9 Sudoku with exactly one answer.
class SudokuPuzzle {
  SudokuPuzzle(this.puzzle, this.solution);

  /// 0 is an empty cell.
  final List<int> puzzle;
  final List<int> solution;

  static List<int> _base(Random rnd) {
    // A valid grid by pattern, then shuffled by row, column and digit swaps
    // that keep it valid.
    final List<int> digits = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(rnd);
    List<int> order() {
      final List<int> bands = <int>[0, 1, 2]..shuffle(rnd);
      return <int>[
        for (final int b in bands)
          for (final int r in (<int>[0, 1, 2]..shuffle(rnd))) b * 3 + r,
      ];
    }

    final List<int> rows = order(), cols = order();
    return <int>[
      for (final int r in rows)
        for (final int c in cols) digits[(r * 3 + r ~/ 3 + c) % 9],
    ];
  }

  /// Counts answers (stops at [limit]).
  static int countSolutions(List<int> grid, {int limit = 2}) {
    final List<int> g = List<int>.of(grid);
    int found = 0;
    bool ok(int i, int v) {
      final int r = i ~/ 9, c = i % 9;
      for (int k = 0; k < 9; k++) {
        if (g[r * 9 + k] == v || g[k * 9 + c] == v) return false;
      }
      final int br = r ~/ 3 * 3, bc = c ~/ 3 * 3;
      for (int a = 0; a < 3; a++) {
        for (int b = 0; b < 3; b++) {
          if (g[(br + a) * 9 + bc + b] == v) return false;
        }
      }
      return true;
    }

    void go() {
      if (found >= limit) return;
      int best = -1, bestN = 10;
      for (int i = 0; i < 81; i++) {
        if (g[i] != 0) continue;
        int n = 0;
        for (int v = 1; v <= 9; v++) {
          if (ok(i, v)) n++;
        }
        if (n < bestN) {
          bestN = n;
          best = i;
          if (n <= 1) break;
        }
      }
      if (best == -1) {
        found++;
        return;
      }
      for (int v = 1; v <= 9 && found < limit; v++) {
        if (ok(best, v)) {
          g[best] = v;
          go();
          g[best] = 0;
        }
      }
    }

    go();
    return found;
  }

  /// A puzzle with about [clues] given cells and one answer.
  factory SudokuPuzzle.generate(Random rnd, {int clues = 40}) {
    final List<int> sol = _base(rnd);
    final List<int> p = List<int>.of(sol);
    final List<int> order = List<int>.generate(81, (int i) => i)..shuffle(rnd);
    int left = 81;
    for (final int i in order) {
      if (left <= clues) break;
      final int keep = p[i];
      p[i] = 0;
      if (countSolutions(p) != 1) {
        p[i] = keep;
      } else {
        left--;
      }
    }
    return SudokuPuzzle(p, sol);
  }
}
