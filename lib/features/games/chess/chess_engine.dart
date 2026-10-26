/// Shatranj rules engine: a complete, pure-Dart chess position.
///
/// Squares are 0..63 with 0 = a8, 7 = h8, 56 = a1, 63 = h1 (row 0 is rank 8,
/// the way the board is drawn). A piece is `type | (black ? 8 : 0)`.
/// A move is one int: from | to << 6 | promo << 12 | flags << 15, always
/// below 2^31 so it is exact on the web as well.
///
/// Implements every rule of the game: castling (rights, empty path, no
/// castling out of, through or into check), en passant (including the
/// discovered-check trap), promotion to a chosen piece, check, checkmate,
/// stalemate and the insufficient-material test. Repetition and the
/// fifty-move rule live in `ChessGame`, which owns the history.
///
/// Verified against the published perft counts (see
/// test/games/chess_perft_test.dart).
library;

const int kEmpty = 0;
const int kPawn = 1;
const int kKnight = 2;
const int kBishop = 3;
const int kRook = 4;
const int kQueen = 5;
const int kKing = 6;
const int kBlackBit = 8;

/// Move flags (stored shifted by 15).
const int kFlagCapture = 1;
const int kFlagEnPassant = 2;
const int kFlagCastle = 4;
const int kFlagDoublePush = 8;

/// Castling right bits.
const int kWhiteKingSide = 1;
const int kWhiteQueenSide = 2;
const int kBlackKingSide = 4;
const int kBlackQueenSide = 8;

const String kStartFen =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

int moveFrom(int m) => m & 63;
int moveTo(int m) => (m >> 6) & 63;

/// 0 or the promotion piece type (2..5).
int movePromo(int m) => (m >> 12) & 7;
int moveFlags(int m) => m >> 15;
bool moveIsCapture(int m) => (moveFlags(m) & kFlagCapture) != 0;
bool moveIsEnPassant(int m) => (moveFlags(m) & kFlagEnPassant) != 0;
bool moveIsCastle(int m) => (moveFlags(m) & kFlagCastle) != 0;

int makeMoveInt(int from, int to, {int promo = 0, int flags = 0}) =>
    from | (to << 6) | (promo << 12) | (flags << 15);

int pieceType(int p) => p & 7;
bool pieceIsWhite(int p) => p != 0 && (p & kBlackBit) == 0;
bool pieceIsBlack(int p) => (p & kBlackBit) != 0;

/// 'e4' for a square index.
String squareName(int sq) => '${'abcdefgh'[sq & 7]}${8 - (sq >> 3)}';

/// Square index for 'e4', or -1 when [name] is not a square.
int squareIndex(String name) {
  if (name.length != 2) return -1;
  final int file = 'abcdefgh'.indexOf(name[0]);
  final int rank = '12345678'.indexOf(name[1]);
  if (file < 0 || rank < 0) return -1;
  return (7 - rank) * 8 + file;
}

/// 'e2e4', 'e7e8q'.
String moveToUci(int m) {
  final int promo = movePromo(m);
  return '${squareName(moveFrom(m))}${squareName(moveTo(m))}'
      '${promo == 0 ? '' : _pieceLetter(promo).toLowerCase()}';
}

String _pieceLetter(int type) => switch (type) {
      kKnight => 'N',
      kBishop => 'B',
      kRook => 'R',
      kQueen => 'Q',
      kKing => 'K',
      _ => '',
    };

/// Spoken / written name of a piece type.
String pieceName(int type) => switch (type) {
      kPawn => 'pawn',
      kKnight => 'knight',
      kBishop => 'bishop',
      kRook => 'rook',
      kQueen => 'queen',
      kKing => 'king',
      _ => 'piece',
    };

// ── Precomputed tables ────────────────────────────────────────────────────

final List<List<int>> _knightTargets = _buildJumps(
  const <List<int>>[
    <int>[-2, -1],
    <int>[-2, 1],
    <int>[-1, -2],
    <int>[-1, 2],
    <int>[1, -2],
    <int>[1, 2],
    <int>[2, -1],
    <int>[2, 1],
  ],
);

final List<List<int>> _kingTargets = _buildJumps(
  const <List<int>>[
    <int>[-1, -1],
    <int>[-1, 0],
    <int>[-1, 1],
    <int>[0, -1],
    <int>[0, 1],
    <int>[1, -1],
    <int>[1, 0],
    <int>[1, 1],
  ],
);

List<List<int>> _buildJumps(List<List<int>> deltas) {
  return List<List<int>>.generate(64, (int sq) {
    final List<int> out = <int>[];
    final int r = sq >> 3;
    final int c = sq & 7;
    for (final List<int> d in deltas) {
      final int nr = r + d[0];
      final int nc = c + d[1];
      if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) out.add(nr * 8 + nc);
    }
    return out;
  });
}

/// Rays: 0..3 are the rook directions (up, down, left, right), 4..7 the
/// bishop directions.
final List<List<List<int>>> _rays = _buildRays();

const List<List<int>> _rayDirs = <List<int>>[
  <int>[-1, 0],
  <int>[1, 0],
  <int>[0, -1],
  <int>[0, 1],
  <int>[-1, -1],
  <int>[-1, 1],
  <int>[1, -1],
  <int>[1, 1],
];

List<List<List<int>>> _buildRays() {
  return List<List<List<int>>>.generate(8, (int d) {
    return List<List<int>>.generate(64, (int sq) {
      final List<int> out = <int>[];
      int r = (sq >> 3) + _rayDirs[d][0];
      int c = (sq & 7) + _rayDirs[d][1];
      while (r >= 0 && r < 8 && c >= 0 && c < 8) {
        out.add(r * 8 + c);
        r += _rayDirs[d][0];
        c += _rayDirs[d][1];
      }
      return out;
    });
  });
}

final List<int> _castleMask = _buildCastleMask();

List<int> _buildCastleMask() {
  final List<int> m = List<int>.filled(64, 15);
  m[0] = 15 & ~kBlackQueenSide;
  m[4] = 15 & ~(kBlackKingSide | kBlackQueenSide);
  m[7] = 15 & ~kBlackKingSide;
  m[56] = 15 & ~kWhiteQueenSide;
  m[60] = 15 & ~(kWhiteKingSide | kWhiteQueenSide);
  m[63] = 15 & ~kWhiteKingSide;
  return m;
}

/// A chess position with make / unmake.
class ChessPosition {
  ChessPosition() {
    _loadFen(kStartFen);
  }

  /// Builds a position from FEN; throws [FormatException] when malformed.
  ChessPosition.fromFen(String fen) {
    _loadFen(fen);
  }

  final List<int> board = List<int>.filled(64, 0);
  bool whiteToMove = true;
  int castling = 15;

  /// En passant target square (the square the pawn skipped), or -1.
  int ep = -1;
  int halfmove = 0;
  int fullmove = 1;
  final List<int> _king = <int>[60, 4];
  final List<int> _stack = <int>[];

  int get plyDepth => _stack.length ~/ 5;

  ChessPosition clone() {
    final ChessPosition c = ChessPosition.fromFen(toFen());
    return c;
  }

  // ── FEN ──────────────────────────────────────────────────────────────────

  void _loadFen(String fen) {
    final List<String> parts = fen.trim().split(RegExp(r'\s+'));
    if (parts.length < 4) throw FormatException('Bad FEN: $fen');
    board.fillRange(0, 64, 0);
    final List<String> rows = parts[0].split('/');
    if (rows.length != 8) throw FormatException('Bad FEN rows: $fen');
    int kings = 0;
    for (int r = 0; r < 8; r++) {
      int c = 0;
      for (final int u in rows[r].codeUnits) {
        final String ch = String.fromCharCode(u);
        final int? n = int.tryParse(ch);
        if (n != null) {
          c += n;
          continue;
        }
        final int type = switch (ch.toLowerCase()) {
          'p' => kPawn,
          'n' => kKnight,
          'b' => kBishop,
          'r' => kRook,
          'q' => kQueen,
          'k' => kKing,
          _ => throw FormatException('Bad FEN piece "$ch"'),
        };
        if (c > 7) throw FormatException('Bad FEN row: ${rows[r]}');
        final bool black = ch != ch.toUpperCase();
        board[r * 8 + c] = type | (black ? kBlackBit : 0);
        if (type == kKing) {
          _king[black ? 1 : 0] = r * 8 + c;
          kings++;
        }
        c++;
      }
      if (c != 8) throw FormatException('Bad FEN row width: ${rows[r]}');
    }
    if (kings != 2) throw const FormatException('A position needs two kings');
    whiteToMove = parts[1] == 'w';
    castling = 0;
    for (final int u in parts[2].codeUnits) {
      switch (String.fromCharCode(u)) {
        case 'K':
          castling |= kWhiteKingSide;
        case 'Q':
          castling |= kWhiteQueenSide;
        case 'k':
          castling |= kBlackKingSide;
        case 'q':
          castling |= kBlackQueenSide;
      }
    }
    ep = parts[3] == '-' ? -1 : squareIndex(parts[3]);
    halfmove = parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0;
    fullmove = parts.length > 5 ? int.tryParse(parts[5]) ?? 1 : 1;
    _stack.clear();
  }

  String toFen() {
    final StringBuffer sb = StringBuffer();
    for (int r = 0; r < 8; r++) {
      int empty = 0;
      for (int c = 0; c < 8; c++) {
        final int p = board[r * 8 + c];
        if (p == 0) {
          empty++;
          continue;
        }
        if (empty > 0) {
          sb.write(empty);
          empty = 0;
        }
        final String letter = switch (pieceType(p)) {
          kPawn => 'p',
          kKnight => 'n',
          kBishop => 'b',
          kRook => 'r',
          kQueen => 'q',
          _ => 'k',
        };
        sb.write(pieceIsWhite(p) ? letter.toUpperCase() : letter);
      }
      if (empty > 0) sb.write(empty);
      if (r < 7) sb.write('/');
    }
    sb
      ..write(whiteToMove ? ' w ' : ' b ')
      ..write(castling == 0
          ? '-'
          : '${castling & kWhiteKingSide != 0 ? 'K' : ''}'
              '${castling & kWhiteQueenSide != 0 ? 'Q' : ''}'
              '${castling & kBlackKingSide != 0 ? 'k' : ''}'
              '${castling & kBlackQueenSide != 0 ? 'q' : ''}')
      ..write(' ')
      ..write(ep < 0 ? '-' : squareName(ep))
      ..write(' $halfmove $fullmove');
    return sb.toString();
  }

  // ── Attacks ──────────────────────────────────────────────────────────────

  /// Is [sq] attacked by any piece of the side [byWhite]?
  bool isAttacked(int sq, bool byWhite) {
    final int colorBit = byWhite ? 0 : kBlackBit;
    final int r = sq >> 3;
    final int c = sq & 7;
    // Pawns: a white pawn attacks up the board (toward row 0).
    final int pr = byWhite ? r + 1 : r - 1;
    if (pr >= 0 && pr < 8) {
      final int pawn = kPawn | colorBit;
      if (c > 0 && board[pr * 8 + c - 1] == pawn) return true;
      if (c < 7 && board[pr * 8 + c + 1] == pawn) return true;
    }
    final int knight = kKnight | colorBit;
    for (final int t in _knightTargets[sq]) {
      if (board[t] == knight) return true;
    }
    final int king = kKing | colorBit;
    for (final int t in _kingTargets[sq]) {
      if (board[t] == king) return true;
    }
    final int rook = kRook | colorBit;
    final int bishop = kBishop | colorBit;
    final int queen = kQueen | colorBit;
    for (int d = 0; d < 8; d++) {
      for (final int t in _rays[d][sq]) {
        final int p = board[t];
        if (p == 0) continue;
        if (p == queen || p == (d < 4 ? rook : bishop)) return true;
        break;
      }
    }
    return false;
  }

  /// Is the side to move in check?
  bool get inCheck => isAttacked(_king[whiteToMove ? 0 : 1], !whiteToMove);

  bool isKingInCheck(bool white) => isAttacked(_king[white ? 0 : 1], !white);

  int kingSquare(bool white) => _king[white ? 0 : 1];

  // ── Move generation ──────────────────────────────────────────────────────

  List<int> pseudoMoves() {
    final List<int> out = <int>[];
    final bool white = whiteToMove;
    final int ownBit = white ? 0 : kBlackBit;
    for (int from = 0; from < 64; from++) {
      final int p = board[from];
      if (p == 0 || (p & kBlackBit) != ownBit) continue;
      switch (pieceType(p)) {
        case kPawn:
          _pawnMoves(from, white, out);
        case kKnight:
          for (final int t in _knightTargets[from]) {
            _addStep(from, t, ownBit, out);
          }
        case kBishop:
          _slide(from, 4, 8, ownBit, out);
        case kRook:
          _slide(from, 0, 4, ownBit, out);
        case kQueen:
          _slide(from, 0, 8, ownBit, out);
        case kKing:
          for (final int t in _kingTargets[from]) {
            _addStep(from, t, ownBit, out);
          }
          _castleMoves(from, white, out);
      }
    }
    return out;
  }

  void _addStep(int from, int to, int ownBit, List<int> out) {
    final int t = board[to];
    if (t == 0) {
      out.add(makeMoveInt(from, to));
    } else if ((t & kBlackBit) != ownBit) {
      out.add(makeMoveInt(from, to, flags: kFlagCapture));
    }
  }

  void _slide(int from, int d0, int d1, int ownBit, List<int> out) {
    for (int d = d0; d < d1; d++) {
      for (final int to in _rays[d][from]) {
        final int t = board[to];
        if (t == 0) {
          out.add(makeMoveInt(from, to));
          continue;
        }
        if ((t & kBlackBit) != ownBit) {
          out.add(makeMoveInt(from, to, flags: kFlagCapture));
        }
        break;
      }
    }
  }

  void _pawnMoves(int from, bool white, List<int> out) {
    final int dir = white ? -8 : 8;
    final int r = from >> 3;
    final int c = from & 7;
    final int startRow = white ? 6 : 1;
    final int lastRow = white ? 0 : 7;
    final int one = from + dir;
    if (one < 0 || one > 63) return;
    void add(int to, int flags) {
      if ((to >> 3) == lastRow) {
        for (final int promo in const <int>[kQueen, kRook, kBishop, kKnight]) {
          out.add(makeMoveInt(from, to, promo: promo, flags: flags));
        }
      } else {
        out.add(makeMoveInt(from, to, flags: flags));
      }
    }

    if (board[one] == 0) {
      add(one, 0);
      if (r == startRow && board[one + dir] == 0) {
        out.add(makeMoveInt(from, one + dir, flags: kFlagDoublePush));
      }
    }
    final int ownBit = white ? 0 : kBlackBit;
    for (final int dc in const <int>[-1, 1]) {
      final int nc = c + dc;
      if (nc < 0 || nc > 7) continue;
      final int to = one + dc;
      final int t = board[to];
      if (t != 0 && (t & kBlackBit) != ownBit) {
        add(to, kFlagCapture);
      } else if (t == 0 && to == ep) {
        // The pawn that just double-stepped sits beside us, behind [to].
        final int victim = board[from + dc];
        if (victim == (kPawn | (white ? kBlackBit : 0))) {
          out.add(makeMoveInt(from, to, flags: kFlagCapture | kFlagEnPassant));
        }
      }
    }
  }

  void _castleMoves(int from, bool white, List<int> out) {
    final int home = white ? 60 : 4;
    if (from != home) return;
    final int ks = white ? kWhiteKingSide : kBlackKingSide;
    final int qs = white ? kWhiteQueenSide : kBlackQueenSide;
    if ((castling & (ks | qs)) == 0) return;
    if (isAttacked(home, !white)) return;
    final int rook = kRook | (white ? 0 : kBlackBit);
    if ((castling & ks) != 0 &&
        board[home + 3] == rook &&
        board[home + 1] == 0 &&
        board[home + 2] == 0 &&
        !isAttacked(home + 1, !white)) {
      out.add(makeMoveInt(home, home + 2, flags: kFlagCastle));
    }
    if ((castling & qs) != 0 &&
        board[home - 4] == rook &&
        board[home - 1] == 0 &&
        board[home - 2] == 0 &&
        board[home - 3] == 0 &&
        !isAttacked(home - 1, !white)) {
      out.add(makeMoveInt(home, home - 2, flags: kFlagCastle));
    }
  }

  /// Every legal move for the side to move.
  List<int> legalMoves() {
    final List<int> pseudo = pseudoMoves();
    final List<int> out = <int>[];
    final bool mover = whiteToMove;
    for (final int m in pseudo) {
      make(m);
      if (!isAttacked(_king[mover ? 0 : 1], !mover)) out.add(m);
      unmake();
    }
    return out;
  }

  /// Is [m] legal here? (Compares from, to and promotion piece.)
  bool isLegal(int m) => legalMoves().contains(m);

  // ── Make / unmake ────────────────────────────────────────────────────────

  void make(int m) {
    final int from = moveFrom(m);
    final int to = moveTo(m);
    final int promo = movePromo(m);
    final int flags = moveFlags(m);
    final int p = board[from];
    final bool white = (p & kBlackBit) == 0;
    int captured = board[to];
    int capSq = to;
    if ((flags & kFlagEnPassant) != 0) {
      capSq = (from & ~7) | (to & 7);
      captured = board[capSq];
    }
    _stack
      ..add(m)
      ..add(captured)
      ..add(castling)
      ..add(ep)
      ..add(halfmove);
    board[capSq] = 0;
    board[from] = 0;
    board[to] = promo != 0 ? (promo | (white ? 0 : kBlackBit)) : p;
    if ((flags & kFlagCastle) != 0) {
      if (to > from) {
        board[to - 1] = board[to + 1];
        board[to + 1] = 0;
      } else {
        board[to + 1] = board[to - 2];
        board[to - 2] = 0;
      }
    }
    if (pieceType(p) == kKing) _king[white ? 0 : 1] = to;
    castling &= _castleMask[from] & _castleMask[to];
    ep = (flags & kFlagDoublePush) != 0 ? (from + to) >> 1 : -1;
    halfmove = (pieceType(p) == kPawn || captured != 0) ? 0 : halfmove + 1;
    if (!white) fullmove++;
    whiteToMove = !whiteToMove;
  }

  void unmake() {
    final int prevHalf = _stack.removeLast();
    final int prevEp = _stack.removeLast();
    final int prevCastling = _stack.removeLast();
    final int captured = _stack.removeLast();
    final int m = _stack.removeLast();
    final int from = moveFrom(m);
    final int to = moveTo(m);
    final int promo = movePromo(m);
    final int flags = moveFlags(m);
    whiteToMove = !whiteToMove;
    final bool white = whiteToMove;
    final int moved = board[to];
    final int p = promo != 0 ? (kPawn | (white ? 0 : kBlackBit)) : moved;
    board[from] = p;
    board[to] = 0;
    if ((flags & kFlagEnPassant) != 0) {
      board[(from & ~7) | (to & 7)] = captured;
    } else {
      board[to] = captured;
    }
    if ((flags & kFlagCastle) != 0) {
      if (to > from) {
        board[to + 1] = board[to - 1];
        board[to - 1] = 0;
      } else {
        board[to - 2] = board[to + 1];
        board[to + 1] = 0;
      }
    }
    if (pieceType(p) == kKing) _king[white ? 0 : 1] = from;
    castling = prevCastling;
    ep = prevEp;
    halfmove = prevHalf;
    if (!white) fullmove--;
  }

  // ── Counting ─────────────────────────────────────────────────────────────

  /// Number of leaf positions [depth] plies ahead (the standard move-
  /// generator test).
  int perft(int depth) {
    if (depth == 0) return 1;
    final List<int> moves = legalMoves();
    if (depth == 1) return moves.length;
    int n = 0;
    for (final int m in moves) {
      make(m);
      n += perft(depth - 1);
      unmake();
    }
    return n;
  }

  /// Neither side can ever deliver mate: bare kings, king and one minor
  /// piece, or only bishops that all stand on one colour of square.
  bool get insufficientMaterial {
    final List<int> bishopColors = <int>[];
    int minors = 0;
    for (int sq = 0; sq < 64; sq++) {
      final int p = board[sq];
      if (p == 0) continue;
      final int t = pieceType(p);
      if (t == kKing) continue;
      if (t == kBishop) {
        bishopColors.add(((sq >> 3) + (sq & 7)) & 1);
        minors++;
      } else if (t == kKnight) {
        minors++;
      } else {
        return false;
      }
    }
    if (minors <= 1) return true;
    if (bishopColors.length == minors) {
      return bishopColors.every((int c) => c == bishopColors.first);
    }
    return false;
  }

  /// A compact string that is equal for equal positions (piece placement,
  /// side to move, castling rights and an en passant square that can really
  /// be used) — the key for the repetition rule.
  String repetitionKey() {
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < 64; i++) {
      sb.writeCharCode(48 + board[i]);
    }
    sb
      ..write(whiteToMove ? 'w' : 'b')
      ..write(castling);
    if (ep >= 0) {
      for (final int m in legalMoves()) {
        if (moveIsEnPassant(m)) {
          sb.write('e$ep');
          break;
        }
      }
    }
    return sb.toString();
  }
}
