import 'package:ar_rayaan/features/games/chess/chess_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// The gold standard for a chess move generator: perft, the number of leaf
/// positions reachable in N plies, compared with the published counts
/// (chessprogramming.org "Perft Results"). Any wrong castling, en passant,
/// promotion, pin or check rule changes these numbers.
void main() {
  const Timeout long = Timeout(Duration(minutes: 3));

  void check(String name, String fen, List<int> counts) {
    test('perft: $name', () {
      for (int d = 1; d <= counts.length; d++) {
        final ChessPosition p = ChessPosition.fromFen(fen);
        expect(p.perft(d), counts[d - 1], reason: '$name depth $d');
        expect(p.toFen(), fen, reason: 'make/unmake must restore the position');
      }
    }, timeout: long);
  }

  check('start position (depth 5)', kStartFen, <int>[20, 400, 8902, 197281, 4865609]);
  check(
    'Kiwipete (castling, pins, en passant, promotion; depth 4)',
    'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
    <int>[48, 2039, 97862, 4085603],
  );
  check(
    'position 3 (en passant discovered check, endgame; depth 5)',
    '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
    <int>[14, 191, 2812, 43238, 674624],
  );
  check(
    'position 4 (promotions, castling rights lost; depth 4)',
    'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1',
    <int>[6, 264, 9467, 422333],
  );
  check(
    'position 4 mirrored (Black to move; depth 4)',
    'r2q1rk1/pP1p2pp/Q4n2/bbp1p3/Np6/1B3NBn/pPPP1PPP/R3K2R b KQ - 0 1',
    <int>[6, 264, 9467, 422333],
  );
  check(
    'position 5 (promotion with check, depth 4)',
    'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8',
    <int>[44, 1486, 62379, 2103487],
  );
  check(
    'position 6 (quiet middlegame; depth 3)',
    'r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10',
    <int>[46, 2079, 89890],
  );
}
