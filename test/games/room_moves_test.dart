import 'package:ar_rayaan/features/games/data/room_moves.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for the room document: applies a numbered move the way
/// `update({'moves.m000003': move})` does (a field set, not a list append).
class _FakeRoom {
  final Map<String, dynamic> moves = <String, dynamic>{};
  final List<String> calls = <String>[];
  String? result;
  int failNextSends = 0;

  Future<void> send(int seq, Map<String, dynamic> move) async {
    calls.add('send $seq');
    if (failNextSends > 0) {
      failNextSends--;
      throw StateError('offline');
    }
    moves[RoomMoves.keyOf(seq)] = Map<String, dynamic>.from(move);
  }

  Future<void> finish(String r) async {
    calls.add('finish $r');
    result = r;
  }
}

Map<String, dynamic> _move(String by, {int d = 3, int t = 1}) =>
    <String, dynamic>{'by': by, 'd': d, 't': t, 'turn': 0, 'next': 1};

void main() {
  group('RoomMoves keys', () {
    test('numbers sort in order as text and round-trip', () {
      expect(RoomMoves.keyOf(0), 'm000000');
      expect(RoomMoves.keyOf(12), 'm000012');
      expect(RoomMoves.seqOf('m000012'), 12);
      expect(RoomMoves.seqOf('x1'), isNull);
      expect(RoomMoves.seqOf('m12'), isNull);
      final List<String> keys = <String>[
        for (final int n in <int>[10, 2, 100, 1]) RoomMoves.keyOf(n),
      ]..sort();
      expect(keys.map(RoomMoves.seqOf).toList(), <int?>[1, 2, 10, 100]);
    });

    test('parse reads the numbered map, skips junk, and reads old lists', () {
      final Map<int, Map<String, dynamic>> m = RoomMoves.parse(
        <String, dynamic>{
          'm000001': <String, dynamic>{'by': 'host'},
          'm000000': <String, dynamic>{'by': 'guest'},
          'bogus': <String, dynamic>{'by': 'host'},
          'm000002': 'not a move',
        },
      );
      expect(m.keys.toList()..sort(), <int>[0, 1]);
      final Map<int, Map<String, dynamic>> legacy = RoomMoves.parse(
        <dynamic>[
          <String, dynamic>{'by': 'host'},
          <String, dynamic>{'by': 'guest'},
        ],
      );
      expect(legacy.keys.toList(), <int>[0, 1]);
      expect(RoomMoves.parse(null), isEmpty);
      expect(RoomMoves.parse(42), isEmpty);
    });
  });

  group('two clients over one room', () {
    test('a move repeated exactly is NOT dropped (the arrayUnion bug)', () async {
      final room = _FakeRoom();
      final host = RoomMoves(mySide: 'host');
      final guest = RoomMoves(mySide: 'guest');
      // The same die and token, three times in a row by the host (sixes),
      // and the identical reply from the guest each time.
      for (var i = 0; i < 3; i++) {
        await room.send(host.reserve(), _move('host', d: 6, t: 0));
        final seen = guest.incoming(room.moves);
        expect(seen.length, 1, reason: 'host move $i reached the guest');
        await room.send(guest.reserve(), _move('guest', d: 2, t: 1));
        final back = host.incoming(room.moves);
        expect(back.length, 1, reason: 'guest move $i reached the host');
      }
      expect(room.moves.length, 6);
    });

    test('a snapshot seen twice applies nothing twice', () async {
      final room = _FakeRoom();
      final guest = RoomMoves(mySide: 'guest');
      await room.send(0, _move('host'));
      expect(guest.incoming(room.moves).length, 1);
      expect(guest.incoming(room.moves), isEmpty);
    });

    test('own moves are skipped and the next number follows them', () async {
      final room = _FakeRoom();
      final host = RoomMoves(mySide: 'host');
      final a = host.reserve();
      final b = host.reserve(); // two moves before any echo (a six)
      expect(<int>[a, b], <int>[0, 1]);
      await room.send(a, _move('host'));
      await room.send(b, _move('host'));
      expect(host.incoming(room.moves), isEmpty);
      expect(host.reserve(), 2);
    });

    test('a hole pauses applying until the missing move arrives', () {
      final guest = RoomMoves(mySide: 'guest');
      final Map<String, dynamic> snap = <String, dynamic>{
        RoomMoves.keyOf(1): _move('host', t: 1),
      };
      expect(guest.incoming(snap), isEmpty);
      snap[RoomMoves.keyOf(0)] = _move('host', t: 0);
      final got = guest.incoming(snap);
      expect(got.map((m) => m['t']).toList(), <Object?>[0, 1]);
    });

    test('moves come out in number order whatever order the map holds', () {
      final guest = RoomMoves(mySide: 'guest');
      final Map<String, dynamic> snap = <String, dynamic>{
        RoomMoves.keyOf(2): _move('host', t: 2),
        RoomMoves.keyOf(0): _move('host', t: 0),
        RoomMoves.keyOf(1): _move('host', t: 1),
      };
      expect(guest.incoming(snap).map((m) => m['t']).toList(),
          <Object?>[0, 1, 2]);
    });

    test('reset starts a fresh table at zero', () {
      final host = RoomMoves(mySide: 'host');
      host.reserve();
      host.reset();
      expect(host.reserve(), 0);
    });
  });

  group('MoveOutbox', () {
    test('the winning move is sent, then the room is finished', () async {
      final room = _FakeRoom();
      final box = MoveOutbox(send: room.send, finish: room.finish);
      final log = RoomMoves(mySide: 'host');
      box.add(log.reserve(), _move('host'));
      box.add(log.reserve(), _move('host', d: 5), result: 'Red wins');
      expect(await box.flush(), isTrue);
      expect(room.calls, <String>['send 0', 'send 1', 'finish Red wins']);
      expect(room.result, 'Red wins');
      expect(room.moves.length, 2);
      expect(box.isEmpty, isTrue);
    });

    test('a failed delivery keeps the queue; retry delivers each move once',
        () async {
      final room = _FakeRoom()..failNextSends = 1;
      final box = MoveOutbox(send: room.send, finish: room.finish);
      final log = RoomMoves(mySide: 'host');
      box.add(log.reserve(), _move('host'), result: 'Draw');
      expect(await box.flush(), isFalse);
      expect(box.length, 1);
      expect(room.result, isNull);
      expect(await box.flush(), isTrue);
      expect(room.moves.length, 1);
      expect(room.result, 'Draw');
    });

    test('a retry after the move arrived but finish failed does not double it',
        () async {
      final room = _FakeRoom();
      var failFinish = true;
      final box = MoveOutbox(
        send: room.send,
        finish: (String r) async {
          if (failFinish) {
            failFinish = false;
            throw StateError('offline');
          }
          await room.finish(r);
        },
      );
      box.add(0, _move('host'), result: 'Red wins');
      expect(await box.flush(), isFalse);
      expect(room.moves.length, 1);
      expect(await box.flush(), isTrue);
      expect(room.moves.length, 1);
      expect(room.result, 'Red wins');
    });

    test('moves queued while a delivery runs are sent in order', () async {
      final room = _FakeRoom();
      final box = MoveOutbox(send: room.send, finish: room.finish);
      box.add(0, _move('host'));
      final first = box.flush();
      box.add(1, _move('host'));
      final second = box.flush();
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(room.calls, <String>['send 0', 'send 1']);
    });
  });
}
