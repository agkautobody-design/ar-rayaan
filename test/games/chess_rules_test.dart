import 'dart:math';

import 'package:ar_rayaan/features/games/chess/chess_engine.dart';
import 'package:ar_rayaan/features/games/chess/chess_game.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every rule of the game, one position at a time.
void main() {
  /// Plays 'e2e4'-style moves (or SAN-free UCI) and fails if one is illegal.
  ChessGame play(List<String> uci, {String? fen}) {
    final ChessGame g = ChessGame(fen: fen);
    for (final String s in uci) {
      final int? m = g.parseUci(s);
      expect(m, isNotNull, reason: 'illegal or unparsable $s');
      expect(g.play(m!), isTrue, reason: s);
    }
    return g;
  }

  List<String> legalUci(ChessGame g) =>
      <String>[for (final int m in g.legalMoves()) moveToUci(m)];

  group('castling', () {
    const String rooks = 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1';

    test('both sides castle both ways when the path is clear', () {
      final ChessGame g = ChessGame(fen: rooks);
      expect(legalUci(g), contains('e1g1'));
      expect(legalUci(g), contains('e1c1'));
      final ChessGame b = ChessGame(fen: 'r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1');
      expect(legalUci(b), contains('e8g8'));
      expect(legalUci(b), contains('e8c8'));
    });

    test('kingside castling puts king on g1 and rook on f1, and is undone', () {
      final ChessGame g = play(<String>['e1g1'], fen: rooks);
      expect(g.pos.toFen(), 'r3k2r/8/8/8/8/8/8/R4RK1 b kq - 1 1');
      expect(g.san.last, 'O-O');
      expect(g.undo(), isTrue);
      expect(g.pos.toFen(), rooks);
    });

    test('queenside castling puts king on c1 and rook on d1, and is undone', () {
      final ChessGame g = play(<String>['e1c1'], fen: rooks);
      expect(g.pos.toFen(), 'r3k2r/8/8/8/8/8/8/2KR3R b kq - 1 1');
      expect(g.san.last, 'O-O-O');
      g.undo();
      expect(g.pos.toFen(), rooks);
    });

    test('Black castles too', () {
      final ChessGame g = play(<String>['a1a2', 'e8g8'], fen: rooks);
      expect(g.pos.toFen(), 'r4rk1/8/8/8/8/8/R7/4K2R w K - 2 2');
    });

    test('the start position has no castling (pieces in the way)', () {
      final ChessGame g = ChessGame();
      expect(legalUci(g), isNotEmpty);
      expect(legalUci(g).contains('e1g1'), isFalse);
      expect(legalUci(g).contains('e1c1'), isFalse);
    });

    test('not out of check', () {
      final ChessGame g = ChessGame(
        fen: 'r3k2r/8/8/8/4r3/8/8/R3K2R w KQkq - 0 1',
      );
      expect(g.inCheck, isTrue);
      expect(legalUci(g).contains('e1g1'), isFalse);
      expect(legalUci(g).contains('e1c1'), isFalse);
    });

    test('not through an attacked square', () {
      // Black rook on f4 guards f1: kingside is off, queenside is fine.
      final ChessGame g = ChessGame(
        fen: '4k3/8/8/8/5r2/8/8/R3K2R w KQ - 0 1',
      );
      expect(legalUci(g).contains('e1g1'), isFalse);
      expect(legalUci(g), contains('e1c1'));
    });

    test('not into check', () {
      final ChessGame g = ChessGame(
        fen: '4k3/8/8/8/6r1/8/8/R3K2R w KQ - 0 1',
      );
      expect(legalUci(g).contains('e1g1'), isFalse);
      expect(legalUci(g), contains('e1c1'));
    });

    test('the rook may pass over an attacked b1 (only the king cares)', () {
      final ChessGame g = ChessGame(
        fen: '4k3/8/8/8/1r6/8/8/R3K2R w KQ - 0 1',
      );
      expect(legalUci(g), contains('e1c1'));
      expect(legalUci(g), contains('e1g1'));
    });

    test('moving the king or a rook gives up the right', () {
      final ChessGame k = play(<String>['e1e2', 'a8a7', 'e2e1', 'a7a8'],
          fen: rooks);
      expect(k.pos.toFen().split(' ')[2], 'k');
      final ChessGame r = play(<String>['h1h2', 'h8h7', 'h2h1', 'h7h8'],
          fen: rooks);
      expect(r.pos.toFen().split(' ')[2], 'Qq');
    });

    test('a captured rook takes its castling right with it', () {
      final ChessGame g = play(<String>['a1a8'],
          fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
      expect(g.pos.toFen().split(' ')[2], 'Kk');
    });
  });

  group('en passant', () {
    test('available straight after the double step, with its notation', () {
      final ChessGame g = play(<String>['e2e4', 'a7a6', 'e4e5', 'd7d5']);
      expect(g.pos.ep, squareIndex('d6'));
      final int? m = g.parseUci('e5d6');
      expect(m, isNotNull);
      expect(moveIsEnPassant(m!), isTrue);
      g.play(m);
      expect(g.san.last, 'exd6');
      expect(g.pos.board[squareIndex('d5')], 0);
      expect(g.pos.board[squareIndex('d6')], kPawn);
      expect(g.capturedByPly.last, kPawn | kBlackBit);
    });

    test('undone, the captured pawn returns', () {
      final ChessGame g = play(<String>['e2e4', 'a7a6', 'e4e5', 'd7d5']);
      final String before = g.pos.toFen();
      g.play(g.parseUci('e5d6')!);
      g.undo();
      expect(g.pos.toFen(), before);
    });

    test('only on the very next move', () {
      final ChessGame g = play(
        <String>['e2e4', 'a7a6', 'e4e5', 'd7d5', 'g1f3', 'a6a5'],
      );
      expect(g.parseUci('e5d6'), isNull);
    });

    test('Black can capture en passant too', () {
      final ChessGame g = play(<String>['a2a3', 'e7e5', 'a3a4', 'e5e4', 'd2d4']);
      expect(g.pos.ep, squareIndex('d3'));
      g.play(g.parseUci('e4d3')!);
      expect(g.pos.board[squareIndex('d4')], 0);
      expect(g.san.last, 'exd3');
    });

    test('never when it would expose the king along the rank', () {
      // b5xc6 e.p. would clear both pawns off the fifth rank and leave the
      // white king on a5 facing the rook on h5.
      final ChessGame g = ChessGame(fen: '8/8/8/KPp4r/8/8/8/7k w - c6 0 1');
      expect(g.parseUci('b5c6'), isNull);
      expect(legalUci(g).where((String s) => s.startsWith('b5')).toList(),
          <String>['b5b6']);
    });
  });

  group('promotion', () {
    const String fen = '8/P7/8/8/8/8/8/k6K w - - 0 1';

    test('offers all four pieces and needs a choice', () {
      final ChessGame g = ChessGame(fen: fen);
      expect(g.needsPromotion(squareIndex('a7'), squareIndex('a8')), isTrue);
      expect(g.findMove(squareIndex('a7'), squareIndex('a8')), isNull);
      expect(
        <String>[for (final String s in legalUci(g)) if (s.startsWith('a7')) s],
        <String>['a7a8q', 'a7a8r', 'a7a8b', 'a7a8n'],
      );
    });

    test('promotes to the chosen piece, including a knight', () {
      for (final MapEntry<String, int> e in <String, int>{
        'q': kQueen,
        'r': kRook,
        'b': kBishop,
        'n': kKnight,
      }.entries) {
        final ChessGame g = play(<String>['a7a8${e.key}'], fen: fen);
        expect(g.pos.board[squareIndex('a8')], e.value, reason: e.key);
        g.undo();
        expect(g.pos.board[squareIndex('a7')], kPawn, reason: e.key);
        expect(g.pos.toFen(), fen);
      }
    });

    test('notation of a promotion and a capturing promotion with check', () {
      expect(play(<String>['a7a8n'], fen: fen).san.last, 'a8=N');
      final ChessGame g = play(
        <String>['b7a8q'],
        fen: 'n3k3/1P6/8/8/8/8/8/4K3 w - - 0 1',
      );
      expect(g.san.last, 'bxa8=Q+');
    });

    test('Black promotes on the first rank', () {
      final ChessGame g = play(<String>['a2a1q'],
          fen: '7k/8/8/8/8/8/p7/7K b - - 0 1');
      expect(g.pos.board[squareIndex('a1')], kQueen | kBlackBit);
    });
  });

  group('check, mate, stalemate', () {
    test("fool's mate is checkmate and Black wins", () {
      final ChessGame g = play(<String>['f2f3', 'e7e5', 'g2g4', 'd8h4']);
      expect(g.status, ChessStatus.checkmate);
      expect(g.whiteWon, isFalse);
      expect(g.san.last, 'Qh4#');
      expect(g.isOver, isTrue);
      expect(g.legalMoves(), isEmpty);
    });

    test("scholar's mate is checkmate and White wins", () {
      final ChessGame g = play(<String>[
        'e2e4', 'e7e5', 'f1c4', 'b8c6', 'd1h5', 'g8f6', 'h5f7',
      ]);
      expect(g.status, ChessStatus.checkmate);
      expect(g.whiteWon, isTrue);
      expect(g.san.last, 'Qxf7#');
    });

    test('a check is announced and must be answered', () {
      final ChessGame g = play(<String>['e2e4', 'f7f6', 'd1h5']);
      expect(g.inCheck, isTrue);
      expect(g.san.last, 'Qh5+');
      expect(g.status, ChessStatus.ongoing);
      // Only a move that answers the check is legal: block on g6 (e7 is
      // taken by Black's own pawn and f7 is covered by the queen).
      expect(legalUci(g), <String>['g7g6']);
    });

    test('stalemate is a draw', () {
      final ChessGame g = ChessGame(fen: '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1');
      expect(g.status, ChessStatus.stalemate);
      expect(g.whiteWon, isNull);
      expect(g.inCheck, isFalse);
      expect(g.isOver, isTrue);
    });

    test('a pinned piece cannot leave the line', () {
      final ChessGame g = ChessGame(fen: '4k3/4r3/8/8/8/8/4R3/4K3 w - - 0 1');
      // The rook on e2 is pinned to the king by the rook on e7 only along
      // the e-file.
      expect(
        legalUci(g).where((String s) => s.startsWith('e2')).every(
              (String s) => s[2] == 'e',
            ),
        isTrue,
      );
    });
  });

  group('draws', () {
    test('threefold repetition, counted on the third occurrence', () {
      final ChessGame g = ChessGame();
      const List<String> shuffle = <String>['g1f3', 'g8f6', 'f3g1', 'f6g8'];
      for (final String s in shuffle) {
        g.play(g.parseUci(s)!);
      }
      expect(g.status, ChessStatus.ongoing, reason: 'twice is not enough');
      for (final String s in shuffle) {
        g.play(g.parseUci(s)!);
      }
      expect(g.status, ChessStatus.threefold);
      expect(g.whiteWon, isNull);
      expect(g.play(g.legalMoves().first), isFalse, reason: 'game is over');
    });

    test('castling rights count: a different right is a different position', () {
      final ChessGame g = ChessGame(fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
      final String a = g.pos.repetitionKey();
      g.play(g.parseUci('a1a2')!);
      g.play(g.parseUci('a8a7')!);
      g.play(g.parseUci('a2a1')!);
      g.play(g.parseUci('a7a8')!);
      expect(g.pos.repetitionKey() == a, isFalse);
    });

    test('fifty-move rule: a hundred half-moves without capture or pawn', () {
      final ChessGame g = ChessGame(fen: '4k3/8/8/8/8/8/R7/4K3 w - - 98 80');
      g.play(g.parseUci('a2a3')!);
      expect(g.status, ChessStatus.ongoing, reason: '99 half-moves');
      g.play(g.parseUci('e8e7')!);
      expect(g.status, ChessStatus.fiftyMove);
      expect(g.whiteWon, isNull);
    });

    test('a pawn move resets the fifty-move count', () {
      final ChessGame g = ChessGame(fen: '4k3/8/8/8/8/8/4P3/4K3 w - - 90 80');
      expect(g.pos.halfmove, 90);
      g.play(g.parseUci('e1d1')!);
      expect(g.pos.halfmove, 91);
      g.play(g.parseUci('e8d8')!);
      g.play(g.parseUci('e2e4')!);
      expect(g.pos.halfmove, 0);
    });

    test('insufficient material', () {
      bool insufficient(String fen) =>
          ChessPosition.fromFen(fen).insufficientMaterial;
      expect(insufficient('4k3/8/8/8/8/8/8/4K3 w - - 0 1'), isTrue);
      expect(insufficient('4k3/8/8/8/8/8/8/3BK3 w - - 0 1'), isTrue);
      expect(insufficient('4k3/8/8/8/8/8/8/3NK3 w - - 0 1'), isTrue);
      expect(insufficient('4k3/8/8/8/8/8/8/2B1K1b1 w - - 0 1'), isTrue,
          reason: 'bishops on the same colour');
      expect(insufficient('2b1k3/8/8/8/8/8/8/2B1K3 w - - 0 1'), isFalse,
          reason: 'bishops on opposite colours can mate');
      expect(insufficient('4k3/8/8/8/8/8/8/2NNK3 w - - 0 1'), isFalse);
      expect(insufficient('4k3/8/8/8/8/8/P7/4K3 w - - 0 1'), isFalse);
      expect(insufficient('4k3/8/8/8/8/8/8/R3K3 w - - 0 1'), isFalse);
      expect(insufficient('4k3/8/8/8/8/8/8/Q3K3 w - - 0 1'), isFalse);
      expect(ChessGame(fen: '4k3/8/8/8/8/8/8/3BK3 w - - 0 1').status,
          ChessStatus.insufficient);
    });

    test('capturing down to bare kings ends the game as a draw', () {
      final ChessGame g = ChessGame(fen: '4k3/8/8/8/8/2n5/8/3NK3 w - - 0 1');
      g.play(g.parseUci('d1c3')!);
      expect(g.status, ChessStatus.insufficient);
    });
  });

  group('resigning, an agreed draw and the clock', () {
    test('resigning ends the game for the other side', () {
      final ChessGame g = play(<String>['e2e4']);
      g.resign(whiteResigns: false);
      expect(g.status, ChessStatus.resigned);
      expect(g.whiteWon, isTrue);
      expect(g.canUndo, isFalse);
      expect(g.play(g.legalMoves().first), isFalse);
    });

    test('an agreed draw is a draw', () {
      final ChessGame g = ChessGame()..agreeDraw();
      expect(g.status, ChessStatus.drawAgreed);
      expect(g.whiteWon, isNull);
    });

    test('running out of time loses, unless the other side cannot mate', () {
      final ChessGame g = ChessGame()..flag(white: true);
      expect(g.status, ChessStatus.timeout);
      expect(g.whiteWon, isFalse);
      // The other side has a bare king and can never mate: a draw.
      final ChessGame d = ChessGame(fen: '4k3/8/8/8/8/8/8/R3K3 w - - 0 1')
        ..flag(white: true);
      expect(d.status, ChessStatus.timeout);
      expect(d.whiteWon, isNull);
    });
  });

  group('undo and redo', () {
    test('undo restores every position exactly, redo replays it', () {
      final Random rnd = Random(2026);
      final ChessGame g = ChessGame();
      final List<String> fens = <String>[g.pos.toFen()];
      while (!g.isOver && g.moves.length < 90) {
        final List<int> legal = g.legalMoves();
        g.play(legal[rnd.nextInt(legal.length)]);
        fens.add(g.pos.toFen());
      }
      final int n = g.moves.length;
      expect(n, greaterThan(20));
      for (int i = n - 1; i >= 0; i--) {
        expect(g.undo(), isTrue);
        expect(g.pos.toFen(), fens[i], reason: 'after undoing to ply $i');
        expect(g.status, ChessStatus.ongoing);
      }
      expect(g.undo(), isFalse);
      expect(g.canUndo, isFalse);
      for (int i = 1; i <= n; i++) {
        expect(g.redo(), isTrue);
        expect(g.pos.toFen(), fens[i], reason: 'after redoing to ply $i');
      }
      expect(g.redo(), isFalse);
    });

    test('a new move clears the redo list', () {
      final ChessGame g = play(<String>['e2e4', 'e7e5']);
      g.undo();
      expect(g.canRedo, isTrue);
      g.play(g.parseUci('c7c5')!);
      expect(g.canRedo, isFalse);
    });

    test('undoing a checkmate reopens the game', () {
      final ChessGame g = play(<String>['f2f3', 'e7e5', 'g2g4', 'd8h4']);
      expect(g.isOver, isTrue);
      expect(g.undo(), isTrue);
      expect(g.status, ChessStatus.ongoing);
      expect(g.whiteWon, isNull);
      expect(g.redo(), isTrue);
      expect(g.status, ChessStatus.checkmate);
    });

    test('undoing the third repetition reopens the game', () {
      final ChessGame g = ChessGame();
      for (int i = 0; i < 2; i++) {
        for (final String s in <String>['g1f3', 'g8f6', 'f3g1', 'f6g8']) {
          g.play(g.parseUci(s)!);
        }
      }
      expect(g.status, ChessStatus.threefold);
      g.undo();
      expect(g.status, ChessStatus.ongoing);
    });
  });

  group('notation, FEN and saving', () {
    test('standard algebraic notation with disambiguation', () {
      final ChessGame files = ChessGame(fen: '4k3/8/8/8/8/8/8/1N2KN2 w - - 0 1');
      expect(files.parseUci('b1d2'), isNotNull);
      final ChessGame a = play(<String>['b1d2'], fen: '4k3/8/8/8/8/8/8/1N2KN2 w - - 0 1');
      expect(a.san.last, 'Nbd2');
      final ChessGame b = play(<String>['f1d2'], fen: '4k3/8/8/8/8/8/8/1N2KN2 w - - 0 1');
      expect(b.san.last, 'Nfd2');
      final ChessGame r1 = play(<String>['a1b3'], fen: '4k3/8/8/N7/8/8/8/N3K3 w - - 0 1');
      expect(r1.san.last, 'N1b3');
      final ChessGame r5 = play(<String>['a5b3'], fen: '4k3/8/8/N7/8/8/8/N3K3 w - - 0 1');
      expect(r5.san.last, 'N5b3');
      expect(play(<String>['g1f3']).san.last, 'Nf3');
      expect(play(<String>['e2e4', 'd7d5', 'e4d5']).san.last, 'exd5');
    });

    test('spoken descriptions for a screen reader', () {
      final ChessGame g = play(<String>['g1f3']);
      expect(g.spoken.last, 'White knight from g1 to f3');
      final ChessGame c = play(<String>['e1g1'],
          fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
      expect(c.spoken.last, 'White castles kingside');
      final ChessGame m = play(<String>['f2f3', 'e7e5', 'g2g4', 'd8h4']);
      expect(m.spoken.last, 'Black queen from d8 to h4, checkmate');
    });

    test('FEN round trip', () {
      for (final String fen in <String>[
        kStartFen,
        'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
        '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
        'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2',
      ]) {
        expect(ChessPosition.fromFen(fen).toFen(), fen);
      }
    });

    test('a bad FEN is rejected', () {
      for (final String bad in <String>[
        '',
        'nonsense',
        '8/8/8/8/8/8/8 w - - 0 1',
        '8/8/8/8/8/8/8/8 w - - 0 1',
        'rnbqkbnr/pppppppp/9/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNX w KQkq - 0 1',
      ]) {
        var threw = false;
        try {
          ChessPosition.fromFen(bad);
        } on FormatException {
          threw = true;
        }
        expect(threw, isTrue, reason: bad);
      }
    });

    test('a saved game rebuilds to the same position; damage stops quietly', () {
      final ChessGame g = play(<String>[
        'e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1b5', 'a7a6', 'b5c6', 'd7c6', 'e1g1',
      ]);
      final ChessGame back = ChessGame.fromUciList(g.toUciList());
      expect(back.pos.toFen(), g.pos.toFen());
      expect(back.san, g.san);
      final ChessGame damaged = ChessGame.fromUciList(
        <String>['e2e4', 'e7e5', 'zz99', 'g1f3'],
      );
      expect(damaged.moves.length, 2);
    });

    test('UCI names', () {
      expect(moveToUci(ChessGame().parseUci('e2e4')!), 'e2e4');
      expect(squareName(0), 'a8');
      expect(squareName(63), 'h1');
      expect(squareIndex('e4'), 36);
      expect(squareIndex('i9'), -1);
    });
  });
}
