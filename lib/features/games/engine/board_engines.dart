import 'dart:math';

/// Rules and a computer player for Four in a Row and Draughts (checkers),
/// with no screen code so they can be tested.

// ------------------------------------------------------------ Four in a Row

class ConnectFour {
  ConnectFour() : cells = List<int>.filled(rows * cols, 0);

  static const int rows = 6, cols = 7;

  /// 0 empty, 1 first player, 2 second player. Row 0 is the top.
  final List<int> cells;
  int turn = 1;
  int winner = 0;
  List<int> line = <int>[];

  int at(int r, int c) => cells[r * cols + c];

  bool canDrop(int c) => winner == 0 && at(0, c) == 0;

  bool get isFull => cells.every((int v) => v != 0);

  /// Drops a token for the player to move. Returns the row it landed in, or
  /// -1 if the column is full or the game is over.
  int drop(int c) {
    if (!canDrop(c)) return -1;
    int r = rows - 1;
    while (at(r, c) != 0) {
      r--;
    }
    cells[r * cols + c] = turn;
    final List<int> l = _lineAt(r, c);
    if (l.isNotEmpty) {
      winner = turn;
      line = l;
    }
    turn = 3 - turn;
    return r;
  }

  List<int> _lineAt(int r, int c) {
    final int p = at(r, c);
    for (final List<int> d in const <List<int>>[
      <int>[0, 1],
      <int>[1, 0],
      <int>[1, 1],
      <int>[1, -1],
    ]) {
      final List<int> run = <int>[r * cols + c];
      for (final int s in const <int>[1, -1]) {
        int rr = r + d[0] * s, cc = c + d[1] * s;
        while (rr >= 0 && rr < rows && cc >= 0 && cc < cols && at(rr, cc) == p) {
          run.add(rr * cols + cc);
          rr += d[0] * s;
          cc += d[1] * s;
        }
      }
      if (run.length >= 4) return run;
    }
    return <int>[];
  }

  ConnectFour copy() {
    final ConnectFour g = ConnectFour();
    for (int i = 0; i < cells.length; i++) {
      g.cells[i] = cells[i];
    }
    g.turn = turn;
    g.winner = winner;
    return g;
  }

  int _score(int me) {
    // Centre columns are worth more; open threes count.
    int s = 0;
    for (int r = 0; r < rows; r++) {
      if (at(r, 3) == me) s += 3;
    }
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        for (final List<int> d in const <List<int>>[
          <int>[0, 1],
          <int>[1, 0],
          <int>[1, 1],
          <int>[1, -1],
        ]) {
          int mine = 0, theirs = 0;
          for (int k = 0; k < 4; k++) {
            final int rr = r + d[0] * k, cc = c + d[1] * k;
            if (rr < 0 || rr >= rows || cc < 0 || cc >= cols) {
              mine = -9;
              break;
            }
            final int v = at(rr, cc);
            if (v == me) mine++;
            if (v == 3 - me) theirs++;
          }
          if (mine < 0) continue;
          if (theirs == 0) s += mine == 3 ? 5 : (mine == 2 ? 2 : 0);
          if (mine == 0) s -= theirs == 3 ? 6 : (theirs == 2 ? 2 : 0);
        }
      }
    }
    return s;
  }

  int _search(int depth, int alpha, int beta, int me) {
    if (winner != 0) return winner == me ? 100000 + depth : -100000 - depth;
    if (isFull) return 0;
    if (depth == 0) return _score(me);
    final bool maximise = turn == me;
    int best = maximise ? -1000000 : 1000000;
    for (final int c in const <int>[3, 2, 4, 1, 5, 0, 6]) {
      if (!canDrop(c)) continue;
      final ConnectFour g = copy()..drop(c);
      final int v = g._search(depth - 1, alpha, beta, me);
      if (maximise) {
        best = max(best, v);
        alpha = max(alpha, best);
      } else {
        best = min(best, v);
        beta = min(beta, best);
      }
      if (alpha >= beta) break;
    }
    return best;
  }

  /// The column the computer picks for the player to move. [depth] 1 is easy,
  /// 3 is medium, 5 is hard. Easy also slips now and then.
  int computerMove(Random rnd, {int depth = 3}) {
    final List<int> open = <int>[
      for (int c = 0; c < cols; c++)
        if (canDrop(c)) c,
    ];
    if (open.isEmpty) return -1;
    if (depth <= 1 && rnd.nextInt(3) == 0) return open[rnd.nextInt(open.length)];
    int bestV = -2000000;
    final List<int> bestCols = <int>[];
    for (final int c in const <int>[3, 2, 4, 1, 5, 0, 6]) {
      if (!canDrop(c)) continue;
      final ConnectFour g = copy()..drop(c);
      final int v = g._search(depth - 1, -1000000, 1000000, turn);
      if (v > bestV) {
        bestV = v;
        bestCols
          ..clear()
          ..add(c);
      } else if (v == bestV) {
        bestCols.add(c);
      }
    }
    return bestCols[rnd.nextInt(bestCols.length)];
  }
}

// ----------------------------------------------------------------- Draughts

/// A piece: 1 and 2 are the two sides' men, 3 and 4 their kings.
class Draughts {
  Draughts() : board = List<int>.filled(64, 0) {
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 8; c++) {
        if ((r + c).isOdd) board[r * 8 + c] = 2;
      }
    }
    for (int r = 5; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if ((r + c).isOdd) board[r * 8 + c] = 1;
      }
    }
  }

  Draughts.of(this.board, {this.turn = 1});

  /// Row 0 is the top; side 1 starts at the bottom and moves up.
  final List<int> board;
  int turn = 1;

  static int side(int p) => p == 0 ? 0 : (p - 1) % 2 + 1;
  static bool isKing(int p) => p >= 3;

  /// Every legal move for [player]: a list of squares, start first, then each
  /// landing. Captures are compulsory, and a capture continues while it can.
  List<List<int>> moves([int? player]) {
    final int pl = player ?? turn;
    final List<List<int>> caps = <List<int>>[];
    for (int i = 0; i < 64; i++) {
      if (side(board[i]) == pl) _jumps(i, board[i], <int>[i], <int>{}, caps);
    }
    if (caps.isNotEmpty) return caps;
    final List<List<int>> out = <List<int>>[];
    for (int i = 0; i < 64; i++) {
      if (side(board[i]) != pl) continue;
      final int p = board[i];
      for (final int dr in _dirs(p)) {
        for (final int dc in const <int>[-1, 1]) {
          final int r = i ~/ 8 + dr, c = i % 8 + dc;
          if (r < 0 || r > 7 || c < 0 || c > 7) continue;
          if (board[r * 8 + c] == 0) out.add(<int>[i, r * 8 + c]);
        }
      }
    }
    return out;
  }

  List<int> _dirs(int p) => isKing(p)
      ? const <int>[-1, 1]
      : (side(p) == 1 ? const <int>[-1] : const <int>[1]);

  void _jumps(int at, int piece, List<int> path, Set<int> taken,
      List<List<int>> out) {
    bool any = false;
    for (final int dr in _dirs(piece)) {
      for (final int dc in const <int>[-1, 1]) {
        final int r = at ~/ 8 + dr, c = at % 8 + dc;
        final int r2 = r + dr, c2 = c + dc;
        if (r2 < 0 || r2 > 7 || c2 < 0 || c2 > 7) continue;
        final int over = r * 8 + c, land = r2 * 8 + c2;
        final int o = board[over];
        if (o == 0 || side(o) == side(piece) || taken.contains(over)) continue;
        // The start square counts as empty once the piece has left it.
        if (board[land] != 0 && land != path.first) continue;
        any = true;
        _jumps(land, piece, <int>[...path, land], <int>{...taken, over}, out);
      }
    }
    if (!any && path.length > 1) out.add(path);
  }

  /// Plays [path] (one of [moves]). Returns whether it was legal.
  bool play(List<int> path) {
    final bool legal = moves().any((List<int> m) =>
        m.length == path.length &&
        Iterable<int>.generate(m.length).every((int i) => m[i] == path[i]));
    if (!legal) return false;
    int piece = board[path.first];
    board[path.first] = 0;
    for (int i = 1; i < path.length; i++) {
      final int a = path[i - 1], b = path[i];
      if ((a ~/ 8 - b ~/ 8).abs() == 2) {
        board[((a ~/ 8 + b ~/ 8) ~/ 2) * 8 + (a % 8 + b % 8) ~/ 2] = 0;
      }
    }
    final int end = path.last;
    if (!isKing(piece) &&
        ((side(piece) == 1 && end ~/ 8 == 0) ||
            (side(piece) == 2 && end ~/ 8 == 7))) {
      piece += 2;
    }
    board[end] = piece;
    turn = 3 - turn;
    return true;
  }

  /// 0 while the game goes on, otherwise the winning side: the player to
  /// move with no piece or no move has lost.
  int get winner {
    if (moves().isEmpty) return 3 - turn;
    return 0;
  }

  int count(int player) =>
      board.where((int p) => side(p) == player).length;

  Draughts copy() => Draughts.of(List<int>.of(board), turn: turn);

  int _eval(int me) {
    int s = 0;
    for (int i = 0; i < 64; i++) {
      final int p = board[i];
      if (p == 0) continue;
      final int v = isKing(p) ? 5 : 2 + (side(p) == 1 ? (7 - i ~/ 8) : i ~/ 8) ~/ 4;
      s += side(p) == me ? v : -v;
    }
    return s;
  }

  int _search(int depth, int alpha, int beta, int me) {
    final List<List<int>> ms = moves();
    if (ms.isEmpty) return turn == me ? -10000 - depth : 10000 + depth;
    if (depth == 0) return _eval(me);
    final bool maximise = turn == me;
    int best = maximise ? -1000000 : 1000000;
    for (final List<int> m in ms) {
      final Draughts g = copy()..play(m);
      final int v = g._search(depth - 1, alpha, beta, me);
      if (maximise) {
        best = max(best, v);
        alpha = max(alpha, best);
      } else {
        best = min(best, v);
        beta = min(beta, best);
      }
      if (alpha >= beta) break;
    }
    return best;
  }

  /// The computer's move: [depth] 1 easy, 3 medium, 5 hard.
  List<int>? computerMove(Random rnd, {int depth = 3}) {
    final List<List<int>> ms = moves();
    if (ms.isEmpty) return null;
    if (depth <= 1 && rnd.nextInt(3) == 0) return ms[rnd.nextInt(ms.length)];
    int bestV = -2000000;
    final List<List<int>> best = <List<int>>[];
    for (final List<int> m in ms) {
      final Draughts g = copy()..play(m);
      final int v = g._search(depth - 1, -1000000, 1000000, turn);
      if (v > bestV) {
        bestV = v;
        best
          ..clear()
          ..add(m);
      } else if (v == bestV) {
        best.add(m);
      }
    }
    return best[rnd.nextInt(best.length)];
  }
}
