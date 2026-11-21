import 'dart:math';

/// Race a friend online: both players get the same game (the same seed, the
/// same settings) and see each other's progress as it happens.
///
/// It runs on the same online table as Ludo and Chess. Both players write to
/// the table's numbered `moves`, so each side has its own numbers: the host
/// writes the even ones, the guest the odd ones, and a number is never
/// written twice. Nothing about a person is written, only counts.
///
/// Pure Dart so the protocol is unit-tested.
abstract final class RaceProtocol {
  /// The table's `game` field for every race.
  static const String tableGame = 'race';

  /// The move number for a side's [n]th write (n starts at 0).
  static int seq(String side, int n) => n * 2 + (side == 'guest' ? 1 : 0);

  /// Which side wrote move [seq].
  static String sideOf(int seq) => seq.isEven ? 'host' : 'guest';

  static String otherSide(String side) => side == 'host' ? 'guest' : 'host';

  static int newSeed([Random? rnd]) =>
      (rnd ?? Random.secure()).nextInt(0x7fffffff);

  /// The host's first move: which game, its settings and the seed.
  static Map<String, dynamic> cfg(
    String gameId,
    Map<String, String> query,
    int seed,
  ) =>
      <String, dynamic>{'t': 'cfg', 'g': gameId, 'q': query, 's': seed};

  static Map<String, dynamic> prog(int answered, int total, int score) =>
      <String, dynamic>{'t': 'prog', 'a': answered, 'n': total, 'sc': score};

  /// [ms]: when this player finished (milliseconds since 1970), only used to
  /// break a tie: when two scores are equal the first to finish wins.
  static Map<String, dynamic> done(int total, int score, [int ms = 0]) =>
      <String, dynamic>{'t': 'done', 'n': total, 'sc': score, 'ms': ms};
}

/// The shared settings of a race.
class RaceConfig {
  const RaceConfig({
    required this.gameId,
    required this.query,
    required this.seed,
  });

  final String gameId;
  final Map<String, String> query;
  final int seed;

  /// Null unless [m] is a well-formed `cfg` move.
  static RaceConfig? tryParse(Map<String, dynamic>? m) {
    if (m == null || m['t'] != 'cfg') return null;
    final Object? g = m['g'];
    final Object? q = m['q'];
    final Object? s = m['s'];
    if (g is! String || !RegExp(r'^[a-z0-9-]{1,40}$').hasMatch(g)) return null;
    if (q is! Map<dynamic, dynamic> || s is! int) return null;
    final Map<String, String> query = <String, String>{};
    for (final MapEntry<dynamic, dynamic> e in q.entries) {
      final Object? k = e.key;
      final Object? v = e.value;
      if (k is String && v is String && k.length <= 20 && v.length <= 60) {
        query[k] = v;
      }
    }
    return RaceConfig(gameId: g, query: query, seed: s);
  }
}

/// How the other player is getting on.
class RaceOpponent {
  const RaceOpponent({
    this.answered = 0,
    this.total = 0,
    this.score = 0,
    this.finished = false,
    this.finishedMs = 0,
  });

  final int answered;
  final int total;
  final int score;
  final bool finished;
  final int finishedMs;

  @override
  bool operator ==(Object other) =>
      other is RaceOpponent &&
      other.answered == answered &&
      other.total == total &&
      other.score == score &&
      other.finished == finished &&
      other.finishedMs == finishedMs;

  @override
  int get hashCode =>
      Object.hash(answered, total, score, finished, finishedMs);
}

/// Everything a player can know about the race from the table.
class RaceState {
  const RaceState({
    this.config,
    this.opponent = const RaceOpponent(),
    this.joined = false,
    this.left = false,
  });

  /// Null until the host's settings have arrived.
  final RaceConfig? config;
  final RaceOpponent opponent;

  /// The second player has sat down.
  final bool joined;

  /// The table is gone: the other player left.
  final bool left;

  /// Reads the table. [moves] are number -> move, [status] the table status.
  static RaceState read({
    required String mySide,
    required Map<int, Map<String, dynamic>> moves,
    required String? status,
  }) {
    final String theirs = RaceProtocol.otherSide(mySide);
    RaceConfig? cfg;
    int bestSeq = -1;
    RaceOpponent opp = const RaceOpponent();
    final List<int> keys = moves.keys.toList()..sort();
    for (final int k in keys) {
      final Map<String, dynamic> m = moves[k]!;
      if (k == 0) cfg = RaceConfig.tryParse(m);
      if (RaceProtocol.sideOf(k) != theirs || k <= bestSeq) continue;
      final Object? t = m['t'];
      final Object? sc = m['sc'];
      final Object? n = m['n'];
      if (sc is! int || n is! int) continue;
      if (t == 'prog') {
        final Object? a = m['a'];
        if (a is! int) continue;
        bestSeq = k;
        opp = RaceOpponent(answered: a, total: n, score: sc);
      } else if (t == 'done') {
        bestSeq = k;
        final Object? ms = m['ms'];
        opp = RaceOpponent(
          answered: n,
          total: n,
          score: sc,
          finished: true,
          finishedMs: ms is int ? ms : 0,
        );
      }
    }
    return RaceState(
      config: cfg,
      opponent: opp,
      joined: status == 'playing' || status == 'done',
    );
  }

  RaceState gone() => RaceState(
        config: config,
        opponent: opponent,
        joined: joined,
        left: true,
      );
}
