/// A whole game of chess: the engine position plus history, move list,
/// undo / redo and the end-of-game rules (checkmate, stalemate, threefold
/// repetition, fifty-move rule, insufficient material, resignation, an
/// agreed draw and running out of time). Pure Dart.
library;

import 'chess_engine.dart';

enum ChessStatus {
  ongoing,
  checkmate,
  stalemate,
  threefold,
  fiftyMove,
  insufficient,
  resigned,
  drawAgreed,
  timeout,
}

class ChessGame {
  ChessGame({String? fen}) : pos = ChessPosition.fromFen(fen ?? kStartFen) {
    _startFen = pos.toFen();
    _keys.add(pos.repetitionKey());
    _evaluate();
  }

  final ChessPosition pos;
  late final String _startFen;

  /// The first position of this game (for saving and replaying).
  String get startFen => _startFen;

  final List<int> _played = <int>[];
  final List<int> _redo = <int>[];
  final List<String> _san = <String>[];
  final List<String> _spoken = <String>[];
  final List<int> _captured = <int>[];
  final List<String> _keys = <String>[];
  List<int>? _legalCache;

  ChessStatus _status = ChessStatus.ongoing;

  /// For a finished game: true = White won, false = Black won, null = draw.
  bool? _whiteWon;

  ChessStatus get status => _status;
  bool get isOver => _status != ChessStatus.ongoing;
  bool get whiteToMove => pos.whiteToMove;
  bool? get whiteWon => _whiteWon;
  bool get inCheck => pos.inCheck;

  /// Moves played so far, oldest first (the redo stack is not included).
  List<int> get moves => List<int>.unmodifiable(_played);

  /// Standard algebraic notation of each played move ('Nf3', 'O-O', 'exd6+').
  List<String> get san => List<String>.unmodifiable(_san);

  /// A screen-reader sentence for each played move.
  List<String> get spoken => List<String>.unmodifiable(_spoken);

  /// Piece ('type | colour bit') captured by each played move, 0 for none.
  List<int> get capturedByPly => List<int>.unmodifiable(_captured);

  bool get canUndo =>
      _played.isNotEmpty &&
      (_status == ChessStatus.ongoing ||
          _status == ChessStatus.checkmate ||
          _status == ChessStatus.stalemate ||
          _status == ChessStatus.threefold ||
          _status == ChessStatus.fiftyMove ||
          _status == ChessStatus.insufficient);
  bool get canRedo => _redo.isNotEmpty && _status == ChessStatus.ongoing;

  List<int> legalMoves() => _legalCache ??= pos.legalMoves();

  /// Legal moves that start on [from].
  List<int> legalFrom(int from) =>
      legalMoves().where((int m) => moveFrom(m) == from).toList();

  /// The legal move from [from] to [to] (with [promo] for a promotion), or
  /// null. A promotion without [promo] matches nothing: ask the player.
  int? findMove(int from, int to, {int promo = 0}) {
    for (final int m in legalMoves()) {
      if (moveFrom(m) == from && moveTo(m) == to && movePromo(m) == promo) {
        return m;
      }
    }
    return null;
  }

  /// Would moving [from] to [to] be a pawn promotion?
  bool needsPromotion(int from, int to) {
    for (final int m in legalMoves()) {
      if (moveFrom(m) == from && moveTo(m) == to && movePromo(m) != 0) {
        return true;
      }
    }
    return false;
  }

  /// Plays [m] if it is legal and the game is on. Returns false otherwise.
  bool play(int m) {
    if (isOver || !legalMoves().contains(m)) return false;
    _apply(m);
    _redo.clear();
    return true;
  }

  void _apply(int m) {
    final List<int> legal = legalMoves();
    final String notation = _notation(m, legal);
    final int from = moveFrom(m);
    final int to = moveTo(m);
    final int moverPiece = pos.board[from];
    final int victim = moveIsEnPassant(m)
        ? pos.board[(from & ~7) | (to & 7)]
        : pos.board[to];
    final bool white = pos.whiteToMove;
    pos.make(m);
    _legalCache = null;
    _played.add(m);
    _captured.add(victim);
    _keys.add(pos.repetitionKey());
    _evaluate();
    final String suffix = _status == ChessStatus.checkmate
        ? '#'
        : (pos.inCheck ? '+' : '');
    _san.add('$notation$suffix');
    _spoken.add(_describe(m, moverPiece, victim, white, suffix));
  }

  /// Takes back the last move. Returns false when there is none to take.
  bool undo() {
    if (!canUndo) return false;
    final int m = _played.removeLast();
    _san.removeLast();
    _spoken.removeLast();
    _captured.removeLast();
    _keys.removeLast();
    pos.unmake();
    _redo.add(m);
    _legalCache = null;
    _whiteWon = null;
    _status = ChessStatus.ongoing;
    _evaluate();
    return true;
  }

  /// Plays again a move that was taken back.
  bool redo() {
    if (!canRedo) return false;
    final int m = _redo.removeLast();
    _apply(m);
    return true;
  }

  void resign({required bool whiteResigns}) {
    if (isOver) return;
    _status = ChessStatus.resigned;
    _whiteWon = !whiteResigns;
  }

  void agreeDraw() {
    if (isOver) return;
    _status = ChessStatus.drawAgreed;
    _whiteWon = null;
  }

  /// [white]'s clock ran out: that side loses (a draw if the other side
  /// could never mate, as the rules say).
  void flag({required bool white}) {
    if (isOver) return;
    _status = ChessStatus.timeout;
    _whiteWon = _hasMatingMaterial(!white) ? !white : null;
  }

  bool _hasMatingMaterial(bool white) {
    int minors = 0;
    for (int sq = 0; sq < 64; sq++) {
      final int p = pos.board[sq];
      if (p == 0 || pieceIsWhite(p) != white) continue;
      final int t = pieceType(p);
      if (t == kPawn || t == kRook || t == kQueen) return true;
      if (t == kBishop || t == kKnight) minors++;
    }
    return minors >= 2 || (minors == 1 && _opponentHasPieces(!white));
  }

  bool _opponentHasPieces(bool white) {
    for (int sq = 0; sq < 64; sq++) {
      final int p = pos.board[sq];
      if (p == 0 || pieceIsWhite(p) != white) continue;
      if (pieceType(p) != kKing) return true;
    }
    return false;
  }

  void _evaluate() {
    if (_status == ChessStatus.resigned ||
        _status == ChessStatus.drawAgreed ||
        _status == ChessStatus.timeout) {
      return;
    }
    _status = ChessStatus.ongoing;
    _whiteWon = null;
    final bool noMoves = legalMoves().isEmpty;
    if (noMoves) {
      if (pos.inCheck) {
        _status = ChessStatus.checkmate;
        _whiteWon = !pos.whiteToMove;
      } else {
        _status = ChessStatus.stalemate;
      }
      return;
    }
    if (pos.insufficientMaterial) {
      _status = ChessStatus.insufficient;
      return;
    }
    if (pos.halfmove >= 100) {
      _status = ChessStatus.fiftyMove;
      return;
    }
    final String key = _keys.last;
    int count = 0;
    for (final String k in _keys) {
      if (k == key) count++;
    }
    if (count >= 3) _status = ChessStatus.threefold;
  }

  // ── Notation ─────────────────────────────────────────────────────────────

  String _notation(int m, List<int> legal) {
    if (moveIsCastle(m)) return moveTo(m) > moveFrom(m) ? 'O-O' : 'O-O-O';
    final int from = moveFrom(m);
    final int to = moveTo(m);
    final int type = pieceType(pos.board[from]);
    final StringBuffer sb = StringBuffer();
    if (type == kPawn) {
      if (moveIsCapture(m)) sb.write('abcdefgh'[from & 7]);
    } else {
      sb.write(_letter(type));
      bool clash = false;
      bool sameFile = false;
      bool sameRank = false;
      for (final int o in legal) {
        if (o == m || moveTo(o) != to || moveFrom(o) == from) continue;
        if (pieceType(pos.board[moveFrom(o)]) != type) continue;
        clash = true;
        if ((moveFrom(o) & 7) == (from & 7)) sameFile = true;
        if ((moveFrom(o) >> 3) == (from >> 3)) sameRank = true;
      }
      if (clash) {
        if (!sameFile) {
          sb.write('abcdefgh'[from & 7]);
        } else if (!sameRank) {
          sb.write(8 - (from >> 3));
        } else {
          sb.write(squareName(from));
        }
      }
    }
    if (moveIsCapture(m)) sb.write('x');
    sb.write(squareName(to));
    final int promo = movePromo(m);
    if (promo != 0) sb.write('=${_letter(promo)}');
    return sb.toString();
  }

  static String _letter(int type) => switch (type) {
        kKnight => 'N',
        kBishop => 'B',
        kRook => 'R',
        kQueen => 'Q',
        kKing => 'K',
        _ => '',
      };

  String _describe(int m, int moverPiece, int victim, bool white, String sfx) {
    final String side = white ? 'White' : 'Black';
    final StringBuffer sb = StringBuffer();
    if (moveIsCastle(m)) {
      sb.write(
        '$side castles ${moveTo(m) > moveFrom(m) ? 'kingside' : 'queenside'}',
      );
    } else {
      sb.write(
        '$side ${pieceName(pieceType(moverPiece))} from '
        '${squareName(moveFrom(m))} to ${squareName(moveTo(m))}',
      );
      if (victim != 0) {
        sb.write(
          moveIsEnPassant(m)
              ? ', capturing en passant'
              : ', capturing a ${pieceName(pieceType(victim))}',
        );
      }
      if (movePromo(m) != 0) {
        sb.write(', promoting to a ${pieceName(movePromo(m))}');
      }
    }
    if (sfx == '#') {
      sb.write(', checkmate');
    } else if (sfx == '+') {
      sb.write(', check');
    }
    return sb.toString();
  }

  // ── Saving ───────────────────────────────────────────────────────────────

  /// The played moves as UCI strings, enough to rebuild the game.
  List<String> toUciList() => <String>[for (final int m in _played) moveToUci(m)];

  /// Rebuilds a game from [uci] moves; stops quietly at the first one that
  /// is not legal (a damaged save).
  static ChessGame fromUciList(List<String> uci, {String? fen}) {
    final ChessGame g = ChessGame(fen: fen);
    for (final String s in uci) {
      final int? m = g.parseUci(s);
      if (m == null || !g.play(m)) break;
    }
    return g;
  }

  /// The legal move written as 'e2e4' / 'e7e8q', or null.
  int? parseUci(String s) {
    if (s.length < 4 || s.length > 5) return null;
    final int from = squareIndex(s.substring(0, 2));
    final int to = squareIndex(s.substring(2, 4));
    if (from < 0 || to < 0) return null;
    int promo = 0;
    if (s.length == 5) {
      promo = switch (s[4].toLowerCase()) {
        'n' => kKnight,
        'b' => kBishop,
        'r' => kRook,
        'q' => kQueen,
        _ => -1,
      };
      if (promo < 0) return null;
    }
    return findMove(from, to, promo: promo);
  }
}
