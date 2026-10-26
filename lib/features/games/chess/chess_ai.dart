/// Hadi's chess engine: alpha-beta search at three strengths.
///
/// The search is a small state machine, [ChessSearch]: [ChessSearch.step]
/// does a bounded slice of work (a few thousand nodes) and returns, so the
/// caller can hand control back to the UI between slices. That is how the
/// board never freezes, on the web (no isolates for this engine) or on a
/// slow phone. No clock is read anywhere: the work is counted in nodes, so a
/// given position, level and seed always give the same move.
library;

import 'dart:math';

import 'chess_engine.dart';

enum ChessLevel { beginner, intermediate, advanced }

extension ChessLevelInfo on ChessLevel {
  String get label => switch (this) {
        ChessLevel.beginner => 'Beginner',
        ChessLevel.intermediate => 'Intermediate',
        ChessLevel.advanced => 'Advanced',
      };

  /// What the level means, in plain words.
  String get blurb => switch (this) {
        ChessLevel.beginner =>
          'Looks one move ahead and sometimes plays a loose move. Gentle.',
        ChessLevel.intermediate =>
          'Looks two moves ahead (both sides counted) and sees simple '
              'tactics.',
        ChessLevel.advanced =>
          'Looks four moves ahead (both sides counted) and follows capture '
              'sequences. A real game.',
      };
}

const int kMateScore = 30000;
const int _inf = 1000000;

const List<int> _values = <int>[0, 100, 320, 330, 500, 900, 0];

/// Static evaluation in centipawns from White's point of view.
int evaluatePosition(ChessPosition p) {
  int score = 0;
  int material = 0;
  for (int sq = 0; sq < 64; sq++) {
    final int piece = p.board[sq];
    if (piece == 0) continue;
    final int t = pieceType(piece);
    if (t != kPawn && t != kKing) material += _values[t];
  }
  final bool endgame = material <= 2600;
  for (int sq = 0; sq < 64; sq++) {
    final int piece = p.board[sq];
    if (piece == 0) continue;
    final int t = pieceType(piece);
    final bool white = pieceIsWhite(piece);
    final int r = sq >> 3;
    final int c = sq & 7;
    final int centre = (7 - (2 * r - 7).abs()) + (7 - (2 * c - 7).abs()); // 0..12
    final int ownRow = white ? 7 - r : r; // 0 = own back rank
    int v = _values[t];
    switch (t) {
      case kPawn:
        v += ownRow * 6 + ((c >= 2 && c <= 5) ? 4 : 0);
        if (ownRow >= 5) v += (ownRow - 4) * 12;
      case kKnight:
        v += centre * 4 - (ownRow == 0 ? 12 : 0);
      case kBishop:
        v += centre * 3 - (ownRow == 0 ? 10 : 0);
      case kRook:
        v += ownRow == 6 ? 15 : 0;
      case kQueen:
        v += centre;
      case kKing:
        if (endgame) {
          v += centre * 4;
        } else {
          v += (ownRow == 0 ? 10 : -ownRow * 10) - centre;
          if (ownRow == 0 && (c == 6 || c == 2)) v += 25;
        }
    }
    score += white ? v : -v;
  }
  return score;
}

/// Parameters of a level.
class _LevelSpec {
  const _LevelSpec(this.depth, this.quiesce, this.rootNodes, this.totalNodes);
  final int depth;
  final int quiesce;

  /// Node budget for the subtree under one root move.
  final int rootNodes;

  /// Node budget for the whole search.
  final int totalNodes;
}

const Map<ChessLevel, _LevelSpec> _specs = <ChessLevel, _LevelSpec>{
  ChessLevel.beginner: _LevelSpec(1, 0, 400, 20000),
  ChessLevel.intermediate: _LevelSpec(2, 2, 6000, 60000),
  ChessLevel.advanced: _LevelSpec(4, 4, 40000, 250000),
};

/// One search in progress. Create it, call [step] until it returns true,
/// then read [best].
class ChessSearch {
  ChessSearch(
    ChessPosition source, {
    required this.level,
    int seed = 1,
    this.sliceNodes = 3000,
  })  : _p = source.clone(),
        _rnd = Random(seed) {
    _spec = _specs[level]!;
    _root = _p.legalMoves();
    // Shuffle first (the seed gives variety), then order best-looking first.
    _root.shuffle(_rnd);
    _orderMoves(_root);
    _scores = List<int>.filled(_root.length, -_inf);
  }

  final ChessLevel level;
  final int sliceNodes;
  final ChessPosition _p;
  final Random _rnd;
  late final _LevelSpec _spec;
  late final List<int> _root;
  late final List<int> _scores;
  int _next = 0;
  int _nodes = 0;
  int _budget = 0;
  int _alpha = -_inf;

  /// Nodes searched so far (for tests and tuning).
  int get nodes => _nodes;

  bool get isDone => _next >= _root.length;

  /// The chosen move, or null when the position has no legal move.
  int? get best => _chosen;
  int? _chosen;

  int get rootMoveCount => _root.length;

  /// Does a bounded slice of work. Returns true when the search is done.
  bool step() {
    if (_root.isEmpty) return true;
    final int stopAt = _nodes + sliceNodes;
    while (_next < _root.length && _nodes < stopAt) {
      _searchRoot(_next);
      _next++;
    }
    if (_next >= _root.length) {
      _chosen = _pick();
      return true;
    }
    return false;
  }

  void _searchRoot(int i) {
    final int m = _root[i];
    final bool total = _nodes >= _spec.totalNodes;
    _budget = total ? 200 : _spec.rootNodes;
    _p.make(m);
    // Beginner and Intermediate score every move exactly (the choice is not
    // always the best one); Advanced narrows the window from the best so far.
    final int alpha = level == ChessLevel.advanced ? _alpha : -_inf;
    final int depth = total ? 1 : _spec.depth;
    final int score = -_negamax(depth - 1, -_inf, -alpha, 1);
    _p.unmake();
    _scores[i] = score;
    if (score > _alpha) _alpha = score;
  }

  int? _pick() {
    int bestIdx = 0;
    for (int i = 1; i < _scores.length; i++) {
      if (_scores[i] > _scores[bestIdx]) bestIdx = i;
    }
    final int top = _scores[bestIdx];
    switch (level) {
      case ChessLevel.advanced:
        return _root[bestIdx];
      case ChessLevel.intermediate:
        final List<int> near = <int>[
          for (int i = 0; i < _root.length; i++)
            if (_scores[i] >= top - 12) _root[i],
        ];
        return near[_rnd.nextInt(near.length)];
      case ChessLevel.beginner:
        // A mate in one is always played; otherwise a gentle player.
        if (top >= kMateScore - 5) return _root[bestIdx];
        final int roll = _rnd.nextInt(100);
        if (roll < 35) return _root[bestIdx];
        if (roll < 90) {
          final List<int> ok = <int>[
            for (int i = 0; i < _root.length; i++)
              if (_scores[i] >= top - 250) _root[i],
          ];
          return ok[_rnd.nextInt(ok.length)];
        }
        return _root[_rnd.nextInt(_root.length)];
    }
  }

  // ── Search ───────────────────────────────────────────────────────────────

  void _orderMoves(List<int> moves) {
    final List<int> keys = <int>[
      for (final int m in moves) _orderKey(m),
    ];
    // Insertion sort, highest key first (lists are short).
    for (int i = 1; i < moves.length; i++) {
      final int m = moves[i];
      final int k = keys[i];
      int j = i - 1;
      while (j >= 0 && keys[j] < k) {
        moves[j + 1] = moves[j];
        keys[j + 1] = keys[j];
        j--;
      }
      moves[j + 1] = m;
      keys[j + 1] = k;
    }
  }

  int _orderKey(int m) {
    int k = 0;
    if (moveIsCapture(m)) {
      final int victim = moveIsEnPassant(m)
          ? kPawn
          : pieceType(_p.board[moveTo(m)]);
      k += 10 * _values[victim] - _values[pieceType(_p.board[moveFrom(m)])] ~/ 10 + 1000;
    }
    if (movePromo(m) != 0) k += _values[movePromo(m)];
    return k;
  }

  int _relativeEval() {
    final int e = evaluatePosition(_p);
    return _p.whiteToMove ? e : -e;
  }

  int _negamax(int depth, int alpha, int beta, int ply) {
    _nodes++;
    if (_budget-- <= 0) return _relativeEval();
    final List<int> moves = _p.legalMoves();
    if (moves.isEmpty) {
      return _p.inCheck ? -(kMateScore - ply) : 0;
    }
    if (_p.halfmove >= 100 || _p.insufficientMaterial) return 0;
    if (depth <= 0) return _quiesce(alpha, beta, _spec.quiesce, moves);
    _orderMoves(moves);
    int best = -_inf;
    for (final int m in moves) {
      _p.make(m);
      final int score = -_negamax(depth - 1, -beta, -alpha, ply + 1);
      _p.unmake();
      if (score > best) best = score;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }

  int _quiesce(int alpha, int beta, int qdepth, List<int> moves) {
    final int stand = _relativeEval();
    if (qdepth <= 0) return stand;
    if (stand >= beta) return stand;
    if (stand > alpha) alpha = stand;
    final List<int> caps = <int>[
      for (final int m in moves)
        if (moveIsCapture(m) || movePromo(m) != 0) m,
    ];
    if (caps.isEmpty) return alpha;
    _orderMoves(caps);
    int best = stand;
    for (final int m in caps) {
      _nodes++;
      if (_budget-- <= 0) break;
      _p.make(m);
      final List<int> reply = _p.legalMoves();
      final int score;
      if (reply.isEmpty) {
        score = _p.inCheck ? kMateScore : 0;
      } else {
        score = -_quiesce(-beta, -alpha, qdepth - 1, reply);
      }
      _p.unmake();
      if (score > best) best = score;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }
}

/// Chooses moves for the computer.
class ChessAi {
  ChessAi({required this.level, this.seed = 1});

  final ChessLevel level;
  final int seed;

  /// Runs the whole search at once. For tests; the app uses [chooseMove].
  int? chooseMoveSync(ChessPosition position) {
    final ChessSearch s = ChessSearch(position, level: level, seed: seed);
    while (!s.step()) {}
    return s.best;
  }

  /// Runs the search a slice at a time, giving the event loop a turn
  /// between slices so the UI stays alive. [isCancelled] is checked between
  /// slices; a cancelled search returns null.
  Future<int?> chooseMove(
    ChessPosition position, {
    bool Function()? isCancelled,
  }) async {
    final ChessSearch s = ChessSearch(position, level: level, seed: seed);
    while (!s.step()) {
      await Future<void>.delayed(Duration.zero);
      if (isCancelled != null && isCancelled()) return null;
    }
    return s.best;
  }
}

/// The engine's own best move, used for hints: Advanced strength, no
/// randomness. Same slicing as [ChessAi.chooseMove].
Future<int?> chessHint(
  ChessPosition position, {
  bool Function()? isCancelled,
}) {
  return ChessAi(level: ChessLevel.advanced, seed: 7)
      .chooseMove(position, isCancelled: isCancelled);
}

/// Would Hadi accept a draw offer? Only in a quiet, balanced game: at least
/// ten moves played and the engine not better than a small edge.
bool chessAcceptsDraw(
  ChessPosition position, {
  required bool computerIsWhite,
  required int plies,
}) {
  if (plies < 20) return false;
  final int e = evaluatePosition(position);
  final int computerScore = computerIsWhite ? e : -e;
  return computerScore <= 60;
}
