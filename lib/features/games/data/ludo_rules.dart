/// Pure Ludo rules that need no widgets, so they can be unit tested.
///
/// The board is the owner's standard 15 x 15 Ludo board (see
/// `ludo_board_art.dart` for where each square is on the picture): a shared
/// loop of 52 squares and, per colour, a home column of 5 squares leading to
/// the centre. Colours sit at fixed places, clockwise from the top left:
/// red (0), blue (1), yellow (2), green (3). A "seat" is a player's place in
/// the game (0 .. players-1); each seat plays one colour. Two players sit
/// opposite each other (red and yellow).
///
/// Loop squares are numbered 0..51 clockwise, starting at the top of the top
/// arm (col 8, row 0). Each colour's start square is 13 squares after the
/// previous colour's.
///
/// Token state, per colour-independent progress `p`:
///  * -1 ............ in the yard
///  * 0 .. 50 ........ on the shared loop, counted from the colour's own start
///    (51 squares: the square just behind the start is never walked)
///  * 51 .. 55 ....... in the colour's home column (5 squares)
///  * 56 ............ home (finished)
/// Every colour travels exactly the same distance.
///
/// HOUSE RULES implemented (shown on the How to Play screen, see [howToPlay]):
///  * A six brings a token out of the yard onto your start square.
///  * A six gives another roll. There is no penalty for three sixes.
///  * Landing on a lone opponent token sends it back to its yard, unless it
///    stands on a safe square. Capturing does not give an extra roll.
///  * Two or more tokens of one colour on one square protect each other.
///  * Safe squares: the four start squares and the four gold stars. Tokens may
///    share a safe square and never capture there.
///  * Exact finish: a token needs the exact number to reach home; a larger
///    roll cannot move it.
///  * You must move if any token can move. First to bring all four home wins;
///    the game ends then.
///  * No stakes of any kind.
import 'dart:math';

abstract final class LudoRules {
  static const int inBase = -1;

  /// Progress of a token that is home.
  static const int finished = 56;

  /// Cells on the shared loop.
  static const int loopLen = 52;

  /// Colour order = seat order of a full table, clockwise from top left.
  static const List<String> colourNames = <String>[
    'Red',
    'Blue',
    'Yellow',
    'Green',
  ];

  /// Loop square where each colour's tokens enter the track (colour-indexed):
  /// red (8,1), blue (13,8), yellow (6,13), green (1,6).
  static const List<int> startCell = <int>[1, 14, 27, 40];

  /// Loop square after which a colour turns into its home column.
  static const List<int> entryCell = <int>[51, 12, 25, 38];

  /// Squares a colour walks on the shared loop (start .. entry, inclusive).
  static const List<int> trackLen = <int>[51, 51, 51, 51];

  /// Squares in each colour's home column.
  static const List<int> columnLen = <int>[5, 5, 5, 5];

  /// Safe loop squares: the four starts and the four gold stars
  /// ((6,2), (12,6), (8,12), (2,8) on the board).
  static const Set<int> safeCells = <int>{1, 9, 14, 22, 27, 35, 40, 48};

  /// The colours that play at a table of [players] (2 to 4): opposite corners
  /// first, so two players face each other.
  static List<int> seatColours(int players) {
    switch (players) {
      case 2:
        return const <int>[0, 2];
      case 3:
        return const <int>[0, 1, 2];
      default:
        return const <int>[0, 1, 2, 3];
    }
  }

  static const List<String> howToPlay = <String>[
    'Roll the die. You need a six to bring a pawn out of its yard.',
    'A six gives you another roll. There is no penalty for three sixes.',
    'Move one pawn the number rolled. If any pawn can move, you must move.',
    'Land on a lone opponent pawn to send it back to its yard. Capturing does '
        'not give an extra roll.',
    'Safe squares (the four start squares and the gold stars) cannot be '
        'captured on. Two of your pawns on one square also protect each other.',
    'To reach home a pawn needs the exact number. A bigger roll cannot move it.',
    'First to bring all four pawns home wins. Two to four players; computer '
        'players fill empty seats. No stakes of any kind.',
  ];

  /// The tokens of [player] (a seat) that can move with [roll]. A token in
  /// the yard needs a 6; a finished token never moves; every other token
  /// needs to stay at or below home (exact finish).
  static List<int> validMoves(List<List<int>> tok, int player, int roll) {
    final List<int> out = <int>[];
    for (int t = 0; t < tok[player].length; t++) {
      final int p = tok[player][t];
      if (p == finished) continue;
      if (p == inBase) {
        if (roll == 6) out.add(t);
        continue;
      }
      if (p + roll <= finished) out.add(t);
    }
    return out;
  }

  /// True when every token of [player] is still in the yard, so only a 6 can
  /// help. Used to tell a new player WHY a roll passed.
  static bool onlyBaseTokens(List<List<int>> tok, int player) =>
      tok[player].every((int p) => p == inBase);

  /// What the dice face shows: the roll in play, else the last roll, so the
  /// number does not vanish back to "?" the moment a turn passes. 0 = none yet.
  static int faceValue({required int dice, required int lastRoll}) =>
      dice != 0 ? dice : lastRoll;

  /// The loop cell a token of [colour] stands on at progress [p], or null when
  /// it is in the yard, in the home column or home.
  static int? loopCell(int colour, int p) {
    if (p < 0 || p >= trackLen[colour]) return null;
    return (startCell[colour] + p) % loopLen;
  }

  /// Index of the home-column cell at progress [p], or null.
  static int? columnIndex(int colour, int p) {
    final int i = p - trackLen[colour];
    if (i < 0 || p >= finished) return null;
    return i;
  }

  static bool isSafe(int cell) => safeCells.contains(cell);

  /// True when tokens of [seat] on loop [cell] cannot be captured: the cell
  /// is safe, or two or more of the seat's tokens share it.
  static bool isProtected(
    List<List<int>> tok,
    List<int> seats,
    int seat,
    int cell,
  ) {
    if (isSafe(cell)) return true;
    int n = 0;
    for (final int p in tok[seat]) {
      if (loopCell(seats[seat], p) == cell) n++;
    }
    return n >= 2;
  }

  /// The (seat, token) pairs an arriving token would send home if it ended
  /// on [cell] (not counting tokens of [mover]).
  static List<(int, int)> capturesAt(
    List<List<int>> tok,
    List<int> seats,
    int mover,
    int cell,
  ) {
    if (isSafe(cell)) return const <(int, int)>[];
    final List<(int, int)> out = <(int, int)>[];
    for (int s = 0; s < seats.length; s++) {
      if (s == mover) continue;
      if (isProtected(tok, seats, s, cell)) continue;
      for (int t = 0; t < tok[s].length; t++) {
        if (loopCell(seats[s], tok[s][t]) == cell) out.add((s, t));
      }
    }
    return out;
  }

  /// Plays token [t] of [seat] with [roll]. Mutates [tok]. Returns what
  /// happened. Call only with a move from [validMoves].
  static LudoMoveResult applyMove(
    List<List<int>> tok,
    List<int> seats,
    int seat,
    int t,
    int roll,
  ) {
    final int from = tok[seat][t];
    final int to = from == inBase ? 0 : from + roll;
    tok[seat][t] = to;
    final List<(int, int)> captured = <(int, int)>[];
    final int? cell = loopCell(seats[seat], to);
    if (cell != null) {
      for (final (int, int) c in capturesAt(tok, seats, seat, cell)) {
        tok[c.$1][c.$2] = inBase;
        captured.add(c);
      }
    }
    final bool reachedHome = to == finished;
    final bool won = hasWon(tok, seat);
    return LudoMoveResult(
      from: from,
      to: to,
      captured: captured,
      reachedHome: reachedHome,
      won: won,
      extraTurn: roll == 6 && !won,
    );
  }

  static bool hasWon(List<List<int>> tok, int seat) =>
      tok[seat].every((int p) => p == finished);

  /// A fresh board for [players] seats: every token in its yard.
  static List<List<int>> newTokens(int players) =>
      List<List<int>>.generate(players, (_) => List<int>.filled(4, inBase));

  /// Next seat after [seat] (clockwise).
  static int nextSeat(int seat, int players) => (seat + 1) % players;

  /// How many tokens of [seat] are home.
  static int homeCount(List<List<int>> tok, int seat) =>
      tok[seat].where((int p) => p == finished).length;
}

/// What one move did.
class LudoMoveResult {
  const LudoMoveResult({
    required this.from,
    required this.to,
    required this.captured,
    required this.reachedHome,
    required this.won,
    required this.extraTurn,
  });

  final int from;
  final int to;

  /// (seat, token) pairs sent back to their yards.
  final List<(int, int)> captured;
  final bool reachedHome;
  final bool won;

  /// The mover rolls again (a six), unless that move won the game.
  final bool extraTurn;
}

/// A die with a seed, so tests (and a replay) get the same rolls.
class LudoDice {
  LudoDice([int? seed]) : _rnd = seed == null ? Random() : Random(seed);

  final Random _rnd;

  /// 1 to 6, evenly.
  int roll() => 1 + _rnd.nextInt(6);
}

/// The computer player: a plain scoring rule, no randomness, so the same
/// position always gets the same move (tests rely on it).
abstract final class LudoBot {
  /// Picks one of [legal] (non-empty) for [seat].
  static int choose(
    List<List<int>> tok,
    List<int> seats,
    int seat,
    int roll,
    List<int> legal,
  ) {
    assert(legal.isNotEmpty);
    int best = legal.first;
    double bestScore = -1e9;
    for (final int t in legal) {
      final double s = _score(tok, seats, seat, t, roll);
      if (s > bestScore) {
        bestScore = s;
        best = t;
      }
    }
    return best;
  }

  static double _score(
    List<List<int>> tok,
    List<int> seats,
    int seat,
    int t,
    int roll,
  ) {
    final int colour = seats[seat];
    final int p = tok[seat][t];
    final int to = p == LudoRules.inBase ? 0 : p + roll;
    double s = to * 0.1;
    if (to == LudoRules.finished) s += 100;
    if (p == LudoRules.inBase) s += 40;
    if (p >= 0 && p < LudoRules.trackLen[colour] &&
        to >= LudoRules.trackLen[colour]) {
      s += 30;
    }
    final int? cell = LudoRules.loopCell(colour, to);
    if (cell != null) {
      final List<(int, int)> caps =
          LudoRules.capturesAt(tok, seats, seat, cell);
      for (final (int, int) c in caps) {
        s += 60 + tok[c.$1][c.$2] * 0.5;
      }
      if (LudoRules.isSafe(cell)) s += 15;
      if (!LudoRules.isSafe(cell) && _threatened(tok, seats, seat, cell)) {
        s -= 18;
      }
    }
    // Run a token away from a threat.
    final int? here = LudoRules.loopCell(colour, p);
    if (here != null &&
        !LudoRules.isProtected(tok, seats, seat, here) &&
        _threatened(tok, seats, seat, here)) {
      s += 20;
    }
    return s;
  }

  /// True when an opponent token stands 1 to 6 cells behind [cell].
  static bool _threatened(
    List<List<int>> tok,
    List<int> seats,
    int seat,
    int cell,
  ) {
    for (int o = 0; o < seats.length; o++) {
      if (o == seat) continue;
      for (final int p in tok[o]) {
        final int? c = LudoRules.loopCell(seats[o], p);
        if (c == null) continue;
        final int gap = (cell - c + LudoRules.loopLen) % LudoRules.loopLen;
        if (gap >= 1 && gap <= 6) return true;
      }
    }
    return false;
  }
}
