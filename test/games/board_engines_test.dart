import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:ar_rayaan/features/games/engine/board_engines.dart';

void main() {
  group('Four in a Row', () {
    test('tokens fall to the bottom and stack', () {
      final ConnectFour g = ConnectFour();
      expect(g.drop(3), 5);
      expect(g.drop(3), 4);
      expect(g.at(5, 3), 1);
      expect(g.at(4, 3), 2);
    });

    test('four across, down and diagonally win', () {
      ConnectFour g = ConnectFour();
      for (final int c in <int>[0, 0, 1, 1, 2, 2, 3]) {
        g.drop(c);
      }
      expect(g.winner, 1);
      expect(g.line.length, 4);
      expect(g.canDrop(4), isFalse);

      g = ConnectFour();
      for (final int c in <int>[0, 1, 0, 1, 0, 1, 0]) {
        g.drop(c);
      }
      expect(g.winner, 1);

      g = ConnectFour();
      // Diagonal for player 1: (5,0) (4,1) (3,2) (2,3)
      for (final int c in <int>[0, 1, 1, 2, 3, 2, 2, 3, 6, 3, 3]) {
        g.drop(c);
      }
      expect(g.winner, 1);
    });

    test('a full column refuses', () {
      final ConnectFour g = ConnectFour();
      for (int i = 0; i < 6; i++) {
        g.drop(0 + (i % 2 == 0 ? 0 : 0));
      }
      expect(g.drop(0), -1);
    });

    test('the computer takes a win and blocks a loss', () {
      final ConnectFour win = ConnectFour();
      for (final int c in <int>[0, 6, 1, 6, 2, 5]) {
        win.drop(c);
      }
      // Player 1 to move, can win at column 3.
      expect(win.computerMove(Random(1), depth: 3), 3);

      final ConnectFour block = ConnectFour();
      for (final int c in <int>[6, 0, 6, 1, 5, 2]) {
        block.drop(c);
      }
      // Player 1 to move; player 2 threatens 0,1,2 -> column 3.
      expect(block.computerMove(Random(1), depth: 3), 3);
    });
  });

  group('Draughts', () {
    test('the start position has 12 men a side and 7 first moves', () {
      final Draughts d = Draughts();
      expect(d.count(1), 12);
      expect(d.count(2), 12);
      expect(d.moves().length, 7);
      expect(d.winner, 0);
    });

    test('a capture is compulsory', () {
      final List<int> b = List<int>.filled(64, 0);
      b[5 * 8 + 2] = 1; // side 1 man
      b[4 * 8 + 3] = 2; // enemy next to it
      b[7 * 8 + 0] = 1; // another man with a quiet move
      final Draughts d = Draughts.of(b);
      final List<List<int>> ms = d.moves();
      expect(ms.length, 1);
      expect(ms.single, <int>[5 * 8 + 2, 3 * 8 + 4]);
      expect(d.play(<int>[7 * 8 + 0, 6 * 8 + 1]), isFalse);
      expect(d.play(ms.single), isTrue);
      expect(d.board[4 * 8 + 3], 0);
      expect(d.count(2), 0);
    });

    test('a capture continues, and a man that reaches the end is crowned', () {
      final List<int> b = List<int>.filled(64, 0);
      b[5 * 8 + 2] = 1;
      b[4 * 8 + 3] = 2;
      b[2 * 8 + 3] = 2;
      b[0 * 8 + 0] = 2;
      final Draughts d = Draughts.of(b);
      final List<List<int>> ms = d.moves();
      expect(ms.length, 1);
      expect(ms.single, <int>[42, 3 * 8 + 4, 1 * 8 + 2]);
      d.play(ms.single);
      expect(d.board[1 * 8 + 2], 1);
      // Man that steps onto the far row is crowned.
      final List<int> b2 = List<int>.filled(64, 0);
      b2[1 * 8 + 2] = 1;
      b2[7 * 8 + 6] = 2;
      final Draughts e = Draughts.of(b2);
      e.play(<int>[1 * 8 + 2, 0 * 8 + 1]);
      expect(e.board[1], 3);
    });

    test('a side with no moves has lost', () {
      final List<int> b = List<int>.filled(64, 0);
      b[0 * 8 + 1] = 1; // side 1 man on the top row cannot move forward
      b[7 * 8 + 0] = 2; // side 2 man on the bottom row cannot move
      final Draughts d = Draughts.of(b, turn: 2);
      expect(d.moves(), isEmpty);
      expect(d.winner, 1);
    });

    test('the computer always plays a legal move', () {
      final Random rnd = Random(3);
      final Draughts d = Draughts();
      for (int i = 0; i < 60 && d.winner == 0; i++) {
        final List<int>? m = d.computerMove(rnd, depth: i.isEven ? 1 : 3);
        expect(m, isNotNull);
        expect(d.play(m!), isTrue);
      }
    });
  });
}
