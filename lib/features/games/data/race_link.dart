import 'dart:async';

import 'package:flutter/foundation.dart';

import 'game_rooms_service.dart';
import 'race_protocol.dart';
import 'room_moves.dart';

/// One player's live connection to a race table. Listens to the table and
/// shows the other player's progress in [state]; [report] and [finish] send
/// this player's. Every send is best effort: a lost update never stops the
/// game, the next one carries the same counts.
class RaceLink {
  /// [startN]: the host's first move (the settings) is number 0, so a link
  /// opened after that starts at 1. The guest starts at 0.
  RaceLink({
    required this.code,
    required this.side,
    int? startN,
    GameRoomsService? rooms,
  })  : _n = startN ?? (side == 'host' ? 0 : 0),
        _rooms = rooms ?? GameRoomsService();

  final String code;
  final String side;
  final GameRoomsService _rooms;

  final ValueNotifier<RaceState> state =
      ValueNotifier<RaceState>(const RaceState());

  StreamSubscription<dynamic>? _sub;
  int _n;
  bool _disposed = false;

  /// Starts listening. Safe to call once.
  void listen() {
    final Stream<dynamic>? s = _rooms.watch(code);
    if (s == null) return;
    _sub = s.listen((dynamic snap) {
      if (_disposed) return;
      final bool exists = snap.exists as bool;
      if (!exists) {
        state.value = state.value.gone();
        return;
      }
      final Map<String, dynamic>? data = snap.data() as Map<String, dynamic>?;
      if (data == null) return;
      state.value = RaceState.read(
        mySide: side,
        moves: RoomMoves.parse(data['moves']),
        status: data['status'] as String?,
      );
    }, onError: (Object _) {});
  }

  Future<void> _send(Map<String, dynamic> move) async {
    final int seq = RaceProtocol.seq(side, _n++);
    try {
      await _rooms.sendMove(code, seq, move);
    } catch (_) {}
  }

  /// The host's settings, written once as the first move.
  Future<void> sendConfig(
    String gameId,
    Map<String, String> query,
    int seed,
  ) =>
      _send(RaceProtocol.cfg(gameId, query, seed));

  Future<void> report(int answered, int total, int score) =>
      _send(RaceProtocol.prog(answered, total, score));

  /// When this player finished (ms since 1970), 0 until then.
  int myFinishedMs = 0;

  Future<void> finish(int total, int score) {
    myFinishedMs = DateTime.now().millisecondsSinceEpoch;
    return _send(RaceProtocol.done(total, score, myFinishedMs));
  }

  /// Leaves the table (deletes it, as every table is).
  Future<void> leave() => _rooms.leave(code);

  void dispose() {
    _disposed = true;
    unawaited(_sub?.cancel());
    state.dispose();
  }
}
