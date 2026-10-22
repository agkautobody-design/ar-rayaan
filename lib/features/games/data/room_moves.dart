/// The move log of an online game room: numbered, ordered and idempotent.
///
/// Why not an array: the old log used `FieldValue.arrayUnion([move])`, which
/// adds an element only if an identical one is absent. In Ludo and chess the
/// same move map legitimately repeats (same die, same token; knight out,
/// back, out again), so a repeat was silently dropped and the opponent's
/// board drifted for the rest of the game.
///
/// Now every move is written under its own number, `moves.m000012`. Writing
/// the same number twice stores the same thing (a retry can never double a
/// move) and the numbers give the order, so the log is read back by number,
/// never by position. A hole in the numbers (a move not yet delivered)
/// pauses applying until it arrives.
///
/// Pure Dart (no Firestore types) so the protocol is unit-tested.
class RoomMoves {
  RoomMoves({required this.mySide});

  /// 'host' or 'guest'.
  final String mySide;

  int _cursor = 0;
  int _nextSend = 0;
  final Set<int> _mine = <int>{};

  /// Field name for move [seq] inside the room's `moves` map.
  static String keyOf(int seq) => 'm${seq.toString().padLeft(6, '0')}';

  /// Inverse of [keyOf]; null for any other key.
  static int? seqOf(String key) {
    final RegExpMatch? m = RegExp(r'^m(\d{6,})$').firstMatch(key);
    return m == null ? null : int.parse(m.group(1)!);
  }

  /// Reads a room's `moves` field into number -> move. Understands the
  /// numbered map and, for rooms made by an older build, the plain list
  /// (position = number). Anything malformed is skipped.
  static Map<int, Map<String, dynamic>> parse(Object? raw) {
    final Map<int, Map<String, dynamic>> out = <int, Map<String, dynamic>>{};
    if (raw is Map<dynamic, dynamic>) {
      for (final MapEntry<dynamic, dynamic> e in raw.entries) {
        final Object? k = e.key;
        final Object? v = e.value;
        if (k is! String || v is! Map<dynamic, dynamic>) continue;
        final int? seq = seqOf(k);
        if (seq == null) continue;
        out[seq] = Map<String, dynamic>.from(v);
      }
    } else if (raw is List<dynamic>) {
      for (var i = 0; i < raw.length; i++) {
        final Object? v = raw[i];
        if (v is Map<dynamic, dynamic>) out[i] = Map<String, dynamic>.from(v);
      }
    }
    return out;
  }

  /// The number the next local move must be written under. Call once per
  /// move; a retry of the same move must reuse the number it was given.
  int reserve() {
    final int seq = _nextSend > _cursor ? _nextSend : _cursor;
    _mine.add(seq);
    _nextSend = seq + 1;
    return seq;
  }

  /// Takes a snapshot of the room's `moves` field and returns, in order,
  /// the opponent's moves that have not been applied yet. Moves this side
  /// sent itself are already on its board and are skipped, as is anything
  /// seen before.
  List<Map<String, dynamic>> incoming(Object? raw) {
    final Map<int, Map<String, dynamic>> all = parse(raw);
    final List<Map<String, dynamic>> fresh = <Map<String, dynamic>>[];
    while (all.containsKey(_cursor)) {
      final Map<String, dynamic> m = all[_cursor]!;
      final bool own = _mine.contains(_cursor) || m['by'] == mySide;
      if (!own) fresh.add(m);
      _cursor++;
    }
    if (_nextSend < _cursor) _nextSend = _cursor;
    return fresh;
  }

  /// Forget everything (a new table).
  void reset() {
    _cursor = 0;
    _nextSend = 0;
    _mine.clear();
  }
}

/// Moves waiting to be delivered, sent strictly in order.
///
/// The move is sent first and the room is finished (if this move ended the
/// game) right after it, so the opponent always receives the final move
/// before the result. Nothing leaves the queue until it is delivered; a
/// failed delivery stops the queue, and [flush] can simply be called again:
/// every move carries its own number, so re-sending one that already
/// arrived changes nothing.
class MoveOutbox {
  MoveOutbox({required this.send, required this.finish});

  final Future<void> Function(int seq, Map<String, dynamic> move) send;
  final Future<void> Function(String result) finish;

  final List<_Pending> _queue = <_Pending>[];
  bool _running = false;
  Future<bool>? _inFlight;

  int get length => _queue.length;
  bool get isEmpty => _queue.isEmpty;

  void add(int seq, Map<String, dynamic> move, {String? result}) {
    _queue.add(_Pending(seq, move, result));
  }

  void clear() => _queue.clear();

  /// Delivers what is queued. Returns true when the queue is empty, false
  /// when a delivery failed (the rest stays queued). A call made while a
  /// delivery is already running joins it: the running loop also picks up
  /// anything added meanwhile.
  Future<bool> flush() {
    if (_running) return _inFlight!;
    _running = true;
    final Future<bool> f = _run();
    if (_running) _inFlight = f;
    return f;
  }

  Future<bool> _run() async {
    try {
      while (_queue.isNotEmpty) {
        final _Pending p = _queue.first;
        try {
          await send(p.seq, p.move);
          final String? result = p.result;
          if (result != null) await finish(result);
        } catch (_) {
          return false;
        }
        if (_queue.isNotEmpty && identical(_queue.first, p)) {
          _queue.removeAt(0);
        }
      }
      return true;
    } finally {
      _running = false;
      _inFlight = null;
    }
  }
}

class _Pending {
  const _Pending(this.seq, this.move, this.result);
  final int seq;
  final Map<String, dynamic> move;
  final String? result;
}
