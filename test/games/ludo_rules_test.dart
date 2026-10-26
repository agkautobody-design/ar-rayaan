import 'package:ar_rayaan/features/games/data/ludo_rules.dart';
import 'package:flutter_test/flutter_test.dart';

List<List<int>> _board(int players) => LudoRules.newTokens(players);

void main() {
  group('Ludo geometry', () {
    test('every colour travels the same distance and finishes at 49', () {
      for (int c = 0; c < 4; c++) {
        expect(
          LudoRules.trackLen[c] + LudoRules.columnLen[c],
          LudoRules.finished,
        );
      }
    });

    test('seat colours: 2 players face each other, 3 and 4 spread out', () {
      expect(LudoRules.seatColours(2), <int>[0, 2]);
      expect(LudoRules.seatColours(3).length, 3);
      expect(LudoRules.seatColours(4), <int>[0, 1, 2, 3]);
    });

    test('safe cells include every start and entry cell', () {
      for (final int c in LudoRules.startCell) {
        expect(LudoRules.isSafe(c), isTrue);
      }
      for (final int c in LudoRules.entryCell) {
        expect(LudoRules.isSafe(c), isTrue);
      }
    });

    test('how to play states the house rules', () {
      final String all = LudoRules.howToPlay.join(' ').toLowerCase();
      expect(all, contains('six'));
      expect(all, contains('exact'));
      expect(all, contains('safe'));
    });
  });

  group('Ludo moves', () {
    test('a yard pawn needs a six', () {
      final List<List<int>> t = _board(2);
      for (int r = 1; r <= 5; r++) {
        expect(LudoRules.validMoves(t, 0, r), isEmpty);
      }
      expect(LudoRules.validMoves(t, 0, 6), <int>[0, 1, 2, 3]);
      expect(LudoRules.onlyBaseTokens(t, 0), isTrue);
    });

    test('a six brings a pawn to its start cell and gives another roll', () {
      final List<List<int>> t = _board(2);
      final List<int> seats = LudoRules.seatColours(2);
      final LudoMoveResult r = LudoRules.applyMove(t, seats, 0, 0, 6);
      expect(r.to, 0);
      expect(t[0][0], 0);
      expect(r.extraTurn, isTrue);
      expect(LudoRules.loopCell(seats[0], 0), LudoRules.startCell[seats[0]]);
    });

    test('a non-six gives no extra turn', () {
      final List<List<int>> t = _board(2);
      t[0][0] = 5;
      final LudoMoveResult r =
          LudoRules.applyMove(t, LudoRules.seatColours(2), 0, 0, 3);
      expect(r.extraTurn, isFalse);
      expect(t[0][0], 8);
    });

    test('finish needs the exact count', () {
      final List<List<int>> t = _board(2);
      t[0][0] = 47;
      expect(LudoRules.validMoves(t, 0, 3), isNot(contains(0)));
      expect(LudoRules.validMoves(t, 0, 2), contains(0));
      expect(LudoRules.validMoves(t, 0, 1), contains(0));
      final LudoMoveResult r =
          LudoRules.applyMove(t, LudoRules.seatColours(2), 0, 0, 2);
      expect(r.reachedHome, isTrue);
      expect(t[0][0], LudoRules.finished);
    });

    test('a finished pawn never moves', () {
      final List<List<int>> t = _board(2);
      t[0][0] = LudoRules.finished;
      for (int r = 1; r <= 6; r++) {
        expect(LudoRules.validMoves(t, 0, r), isNot(contains(0)));
      }
    });

    test('the loop is shared: a token reaches its column after trackLen', () {
      for (int c = 0; c < 4; c++) {
        expect(LudoRules.loopCell(c, LudoRules.trackLen[c] - 1), isNotNull);
        expect(LudoRules.loopCell(c, LudoRules.trackLen[c]), isNull);
        expect(LudoRules.columnIndex(c, LudoRules.trackLen[c]), 0);
        expect(LudoRules.columnIndex(c, LudoRules.finished), isNull);
      }
    });
  });

  group('Ludo capture and safety', () {
    // Seats 0 and 1 on a 2 player board are colours 0 and 2.
    test('landing on a lone opponent on a plain cell captures it', () {
      final List<int> seats = LudoRules.seatColours(2);
      final List<List<int>> t = _board(2);
      // Find a plain cell and place the opponent there.
      const int cell = 8;
      expect(LudoRules.isSafe(cell), isFalse);
      final int oppP =
          (cell - LudoRules.startCell[seats[1]] + LudoRules.loopLen) %
              LudoRules.loopLen;
      t[1][0] = oppP;
      expect(LudoRules.loopCell(seats[1], oppP), cell);
      final int myP =
          (cell - LudoRules.startCell[seats[0]] + LudoRules.loopLen) %
              LudoRules.loopLen;
      t[0][0] = myP - 2;
      final LudoMoveResult r = LudoRules.applyMove(t, seats, 0, 0, 2);
      expect(r.captured, <(int, int)>[(1, 0)]);
      expect(t[1][0], LudoRules.inBase);
      expect(r.extraTurn, isFalse, reason: 'a capture gives no extra roll');
    });

    test('a safe cell protects the pawn on it', () {
      final List<int> seats = LudoRules.seatColours(2);
      final List<List<int>> t = _board(2);
      final int cell = LudoRules.safeCells.first;
      expect(LudoRules.capturesAt(t, seats, 0, cell), isEmpty);
      t[1][0] = (cell - LudoRules.startCell[seats[1]] + LudoRules.loopLen) %
          LudoRules.loopLen;
      expect(LudoRules.capturesAt(t, seats, 0, cell), isEmpty);
    });

    test('two pawns of one colour on a cell protect each other', () {
      final List<int> seats = LudoRules.seatColours(2);
      final List<List<int>> t = _board(2);
      const int cell = 8;
      expect(LudoRules.isSafe(cell), isFalse);
      final int p = (cell - LudoRules.startCell[seats[1]] + LudoRules.loopLen) %
          LudoRules.loopLen;
      t[1][0] = p;
      expect(LudoRules.capturesAt(t, seats, 0, cell), hasLength(1));
      t[1][1] = p;
      expect(LudoRules.isProtected(t, seats, 1, cell), isTrue);
      expect(LudoRules.capturesAt(t, seats, 0, cell), isEmpty);
    });

    test('home column pawns cannot be captured', () {
      final List<int> seats = LudoRules.seatColours(2);
      final List<List<int>> t = _board(2);
      t[1][0] = LudoRules.trackLen[seats[1]] + 1;
      for (int c = 0; c < LudoRules.loopLen; c++) {
        expect(LudoRules.capturesAt(t, seats, 0, c), isEmpty);
      }
    });
  });

  group('Ludo winning and turns', () {
    test('four pawns home wins and no extra turn is granted', () {
      final List<int> seats = LudoRules.seatColours(2);
      final List<List<int>> t = _board(2);
      t[0] = <int>[49, 49, 49, 43];
      final LudoMoveResult r = LudoRules.applyMove(t, seats, 0, 3, 6);
      expect(r.won, isTrue);
      expect(r.extraTurn, isFalse);
      expect(LudoRules.hasWon(t, 0), isTrue);
      expect(LudoRules.homeCount(t, 0), 4);
    });

    test('turns pass round the seats', () {
      expect(LudoRules.nextSeat(0, 3), 1);
      expect(LudoRules.nextSeat(2, 3), 0);
      expect(LudoRules.nextSeat(3, 4), 0);
    });

    test('face value keeps the last roll on the die', () {
      expect(LudoRules.faceValue(dice: 0, lastRoll: 4), 4);
      expect(LudoRules.faceValue(dice: 2, lastRoll: 4), 2);
    });
  });

  group('Ludo dice and bot', () {
    test('the same seed gives the same rolls, all within 1 to 6', () {
      final LudoDice a = LudoDice(42);
      final LudoDice b = LudoDice(42);
      final List<int> ra = <int>[for (int i = 0; i < 200; i++) a.roll()];
      final List<int> rb = <int>[for (int i = 0; i < 200; i++) b.roll()];
      expect(ra, rb);
      expect(ra.every((int v) => v >= 1 && v <= 6), isTrue);
      expect(ra.toSet().length, 6);
    });

    test('the bot is deterministic and prefers a capture', () {
      final List<int> seats = LudoRules.seatColours(2);
      final List<List<int>> t = _board(2);
      const int cell = 8;
      expect(LudoRules.isSafe(cell), isFalse);
      t[1][0] = (cell - LudoRules.startCell[seats[1]] + LudoRules.loopLen) %
          LudoRules.loopLen;
      final int myP = (cell - LudoRules.startCell[seats[0]] +
              LudoRules.loopLen) %
          LudoRules.loopLen;
      t[0][0] = 20;
      t[0][1] = myP - 3;
      final List<int> legal = LudoRules.validMoves(t, 0, 3);
      final int a = LudoBot.choose(t, seats, 0, 3, legal);
      final int b = LudoBot.choose(t, seats, 0, 3, legal);
      expect(a, b);
      expect(a, 1);
    });

    test('the bot brings a pawn out on a six when it can', () {
      final List<int> seats = LudoRules.seatColours(2);
      final List<List<int>> t = _board(2);
      final List<int> legal = LudoRules.validMoves(t, 0, 6);
      expect(LudoBot.choose(t, seats, 0, 6, legal), legal.first);
    });
  });

  group('Ludo full games with computer seats', () {
    for (final int players in <int>[2, 3, 4]) {
      test('$players player game finishes with a winner', () {
        final List<int> seats = LudoRules.seatColours(players);
        final List<List<int>> t = _board(players);
        final LudoDice dice = LudoDice(7 + players);
        int seat = 0;
        int winner = -1;
        for (int turn = 0; turn < 20000 && winner < 0; turn++) {
          final int roll = dice.roll();
          final List<int> legal = LudoRules.validMoves(t, seat, roll);
          if (legal.isEmpty) {
            seat = LudoRules.nextSeat(seat, players);
            continue;
          }
          final int pick = LudoBot.choose(t, seats, seat, roll, legal);
          final LudoMoveResult r =
              LudoRules.applyMove(t, seats, seat, pick, roll);
          for (final List<int> row in t) {
            for (final int p in row) {
              expect(p >= LudoRules.inBase && p <= LudoRules.finished, isTrue);
            }
          }
          if (r.won) {
            winner = seat;
          } else if (!r.extraTurn) {
            seat = LudoRules.nextSeat(seat, players);
          }
        }
        expect(winner, greaterThan(-1));
        expect(LudoRules.hasWon(t, winner), isTrue);
      });
    }
  });
}
