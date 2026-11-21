import 'package:flutter_test/flutter_test.dart';

import 'package:ar_rayaan/features/games/data/race_protocol.dart';

void main() {
  test('each side has its own move numbers', () {
    expect(RaceProtocol.seq('host', 0), 0);
    expect(RaceProtocol.seq('guest', 0), 1);
    expect(RaceProtocol.seq('host', 3), 6);
    expect(RaceProtocol.seq('guest', 3), 7);
    expect(RaceProtocol.sideOf(6), 'host');
    expect(RaceProtocol.sideOf(7), 'guest');
  });

  test('cfg round-trips and rejects junk', () {
    final Map<String, dynamic> m =
        RaceProtocol.cfg('hadith', <String, String>{'n': '10'}, 42);
    final RaceConfig? c = RaceConfig.tryParse(m);
    expect(c!.gameId, 'hadith');
    expect(c.query['n'], '10');
    expect(c.seed, 42);
    expect(RaceConfig.tryParse(<String, dynamic>{'t': 'prog'}), isNull);
    expect(
        RaceConfig.tryParse(
            <String, dynamic>{'t': 'cfg', 'g': '../x', 'q': {}, 's': 1}),
        isNull);
    expect(
        RaceConfig.tryParse(
            <String, dynamic>{'t': 'cfg', 'g': 'qk', 'q': 'x', 's': 1}),
        isNull);
  });

  test('a player reads the other side only, newest move wins', () {
    final Map<int, Map<String, dynamic>> moves = <int, Map<String, dynamic>>{
      0: RaceProtocol.cfg('qk', <String, String>{}, 7),
      1: RaceProtocol.prog(1, 10, 1), // guest
      2: RaceProtocol.prog(1, 10, 1), // host
      3: RaceProtocol.prog(2, 10, 1), // guest
      4: RaceProtocol.prog(5, 10, 4), // host
    };
    final RaceState host =
        RaceState.read(mySide: 'host', moves: moves, status: 'playing');
    expect(host.config!.seed, 7);
    expect(host.joined, isTrue);
    expect(host.opponent.answered, 2);
    expect(host.opponent.score, 1);
    final RaceState guest =
        RaceState.read(mySide: 'guest', moves: moves, status: 'playing');
    expect(guest.opponent.answered, 5);
    expect(guest.opponent.score, 4);
  });

  test('done marks the opponent finished; waiting table is not joined', () {
    final Map<int, Map<String, dynamic>> moves = <int, Map<String, dynamic>>{
      0: RaceProtocol.cfg('qk', <String, String>{}, 7),
      1: RaceProtocol.done(10, 8),
    };
    final RaceState s =
        RaceState.read(mySide: 'host', moves: moves, status: 'playing');
    expect(s.opponent.finished, isTrue);
    expect(s.opponent.score, 8);
    expect(
        RaceState.read(mySide: 'host', moves: moves, status: 'waiting').joined,
        isFalse);
    expect(s.gone().left, isTrue);
  });

  test('malformed moves from the other side are ignored', () {
    final RaceState s = RaceState.read(
      mySide: 'host',
      moves: <int, Map<String, dynamic>>{
        1: <String, dynamic>{'t': 'prog', 'a': 'x', 'n': 1, 'sc': 1},
        3: <String, dynamic>{'t': 'weird'},
      },
      status: 'playing',
    );
    expect(s.opponent, const RaceOpponent());
  });

  test('done carries the finish time and it is read back', () {
    final RaceState s = RaceState.read(
      mySide: 'host',
      moves: <int, Map<String, dynamic>>{1: RaceProtocol.done(10, 8, 12345)},
      status: 'playing',
    );
    expect(s.opponent.finishedMs, 12345);
  });
}
