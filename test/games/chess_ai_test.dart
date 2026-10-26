import 'package:ar_rayaan/features/games/chess/chess_ai.dart';
import 'package:ar_rayaan/features/games/chess/chess_engine.dart';
import 'package:ar_rayaan/features/games/chess/chess_game.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hadi's three levels: legal, deterministic for a seed, sensible, and cut
/// into small slices so the screen never freezes.
void main() {
  ChessGame after(List<String> uci) {
    final ChessGame g = ChessGame();
    for (final String s in uci) {
      g.play(g.parseUci(s)!);
    }
    return g;
  }

  test('every level plays only legal moves for a whole game', () {
    for (final ChessLevel lv in ChessLevel.values) {
      final ChessGame g = ChessGame();
      int plies = 0;
      while (!g.isOver && plies < 40) {
        final int? m = ChessAi(level: lv, seed: 11 + plies)
            .chooseMoveSync(g.pos);
        expect(m, isNotNull, reason: lv.name);
        expect(g.play(m!), isTrue, reason: '${lv.name} ply $plies');
        plies++;
      }
    }
  });

  test('the same position, level and seed always give the same move', () {
    final ChessGame g = after(<String>['e2e4', 'e7e5']);
    for (final ChessLevel lv in ChessLevel.values) {
      final int? a = ChessAi(level: lv, seed: 42).chooseMoveSync(g.pos);
      final int? b = ChessAi(level: lv, seed: 42).chooseMoveSync(g.pos);
      expect(a, b, reason: lv.name);
    }
  });

  test('different seeds can give different Beginner moves', () {
    final Set<int?> seen = <int?>{
      for (int seed = 1; seed <= 12; seed++)
        ChessAi(level: ChessLevel.beginner, seed: seed)
            .chooseMoveSync(ChessPosition()),
    };
    expect(seen.length, greaterThan(1));
  });

  test('every level plays a mate in one when it is there', () {
    // Scholar's mate set-up: Qxf7 is checkmate.
    const String fen =
        'r1bqkbnr/pppp1ppp/2n5/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4';
    for (final ChessLevel lv in ChessLevel.values) {
      for (int seed = 1; seed <= 5; seed++) {
        final int? m = ChessAi(level: lv, seed: seed)
            .chooseMoveSync(ChessPosition.fromFen(fen));
        expect(moveToUci(m!), 'h5f7', reason: '${lv.name} seed $seed');
      }
    }
  });

  test('Intermediate and Advanced take a free queen; Advanced sees a fork', () {
    // The black queen on d5 hangs to the white rook on d1.
    const String free = '4k3/8/8/3q4/8/8/8/3RK3 w - - 0 1';
    for (final ChessLevel lv in <ChessLevel>[
      ChessLevel.intermediate,
      ChessLevel.advanced,
    ]) {
      final int? m = ChessAi(level: lv, seed: 3)
          .chooseMoveSync(ChessPosition.fromFen(free));
      expect(moveToUci(m!), 'd1d5', reason: lv.name);
    }
    // A knight fork: Nc7+ attacks king e8 and rook a8.
    const String fork = 'r3k3/8/8/3N4/8/8/8/4K3 w - - 0 1';
    final int? f = ChessAi(level: ChessLevel.advanced, seed: 3)
        .chooseMoveSync(ChessPosition.fromFen(fork));
    expect(moveToUci(f!), 'd5c7');
  });

  test('Advanced does not hang its queen to a pawn', () {
    // Black to move; Qd4 would be captured by the pawn on e3.
    const String fen = '4k3/8/8/8/8/4P3/8/4K2q b - - 0 1';
    final ChessPosition p = ChessPosition.fromFen(fen);
    final int? m = ChessAi(level: ChessLevel.advanced, seed: 5)
        .chooseMoveSync(p);
    expect(moveToUci(m!).endsWith('d4'), isFalse);
  });

  test('a position with no legal move gives no move', () {
    final ChessPosition mated = ChessPosition.fromFen(
      '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1',
    );
    expect(ChessAi(level: ChessLevel.advanced).chooseMoveSync(mated), isNull);
  });

  test('the search works in small slices and never in one long block', () {
    final ChessPosition pos = ChessPosition.fromFen(
      'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
    );
    for (final ChessLevel lv in ChessLevel.values) {
      final ChessSearch s = ChessSearch(pos, level: lv, seed: 9);
      int steps = 0;
      int worst = 0;
      int last = 0;
      while (!s.step()) {
        steps++;
        worst = worst > s.nodes - last ? worst : s.nodes - last;
        last = s.nodes;
      }
      expect(s.best, isNotNull);
      // A slice may overshoot by one root move's budget, never by more.
      expect(worst, lessThanOrEqualTo(3000 + 41000), reason: lv.name);
      if (lv == ChessLevel.advanced) {
        expect(steps, greaterThan(1), reason: 'Advanced is time-sliced');
      }
      expect(s.nodes, lessThanOrEqualTo(300000), reason: lv.name);
    }
  });

  test('slice size does not change the chosen move', () {
    final ChessPosition p = ChessPosition.fromFen(
      'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
    );
    for (final ChessLevel lv in ChessLevel.values) {
      int? pick(int slice) {
        final ChessSearch s =
            ChessSearch(p, level: lv, seed: 4, sliceNodes: slice);
        while (!s.step()) {}
        return s.best;
      }

      expect(pick(200), pick(100000), reason: lv.name);
    }
  });

  test('chooseMove (async, sliced) agrees with the synchronous search', () async {
    final ChessPosition p = ChessPosition();
    final int? a = await ChessAi(level: ChessLevel.intermediate, seed: 8)
        .chooseMove(p);
    final int? b = ChessAi(level: ChessLevel.intermediate, seed: 8)
        .chooseMoveSync(p);
    expect(a, b);
  });

  test('a cancelled search returns nothing', () async {
    final int? m = await ChessAi(level: ChessLevel.advanced, seed: 8)
        .chooseMove(ChessPosition(), isCancelled: () => true);
    expect(m, isNull);
  });

  test('the hint is the engine\'s own legal move', () async {
    final ChessGame g = ChessGame();
    final int? h = await chessHint(g.pos);
    expect(h, isNotNull);
    expect(g.legalMoves().contains(h), isTrue);
    final int? again = await chessHint(g.pos);
    expect(again, h, reason: 'a hint is repeatable');
  });

  test('evaluation is symmetric: the start position is level', () {
    expect(evaluatePosition(ChessPosition()), 0);
    final ChessPosition up = ChessPosition.fromFen(
      'rnb1kbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    );
    expect(evaluatePosition(up), greaterThan(800));
  });

  test('Hadi accepts a draw only in a quiet, balanced game', () {
    final ChessPosition level = ChessPosition();
    expect(
      chessAcceptsDraw(level, computerIsWhite: false, plies: 4),
      isFalse,
      reason: 'too early',
    );
    expect(
      chessAcceptsDraw(level, computerIsWhite: false, plies: 30),
      isTrue,
    );
    final ChessPosition ahead = ChessPosition.fromFen(
      'rnb1kbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    );
    expect(
      chessAcceptsDraw(ahead, computerIsWhite: true, plies: 30),
      isFalse,
    );
  });
}
