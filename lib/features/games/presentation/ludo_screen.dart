import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../data/game_rooms_service.dart';
import '../data/ludo_rules.dart';
import '../data/room_moves.dart';
import 'online_lobby.dart';

/// LUDO — the second crown. The classic 52-cell track, four safe stars per
/// lap, captures, and the exact roll to reach the heart of the board.
/// v1: two players (You vs Hadi, or pass-and-play). Four-player boards and
/// online rooms arrive with the family cloud, in shaa Allah.
class LudoScreen extends StatefulWidget {
  const LudoScreen({super.key});

  @override
  State<LudoScreen> createState() => _LudoState();
}

class _LudoState extends State<LudoScreen> {
  // The 52-cell classic track (row, col) on the 15x15 board.
  static const track = <List<int>>[
    [6, 1], [6, 2], [6, 3], [6, 4], [6, 5],
    [5, 6], [4, 6], [3, 6], [2, 6], [1, 6], [0, 6],
    [0, 7],
    [0, 8], [1, 8], [2, 8], [3, 8], [4, 8], [5, 8],
    [6, 9], [6, 10], [6, 11], [6, 12], [6, 13], [6, 14],
    [7, 14],
    [8, 14], [8, 13], [8, 12], [8, 11], [8, 10], [8, 9],
    [9, 8], [10, 8], [11, 8], [12, 8], [13, 8], [14, 8],
    [14, 7],
    [14, 6], [13, 6], [12, 6], [11, 6], [10, 6], [9, 6],
    [8, 5], [8, 4], [8, 3], [8, 2], [8, 1], [8, 0],
    [7, 0],
    [6, 0],
  ];
  static const safe = {0, 8, 13, 21, 26, 34, 39, 47};
  static const starts = [0, 13, 26, 39];
  static const homes = <List<List<int>>>[
    [[7, 1], [7, 2], [7, 3], [7, 4], [7, 5], [7, 6]],
    [[1, 7], [2, 7], [3, 7], [4, 7], [5, 7], [6, 7]],
    [[7, 13], [7, 12], [7, 11], [7, 10], [7, 9], [7, 8]],
    [[13, 7], [12, 7], [11, 7], [10, 7], [9, 7], [8, 7]],
  ];
  static const bases = [
    [0, 0], [0, 12], [12, 0], [12, 12],
  ];
  static const names = ['Red', 'Green', 'Yellow', 'Blue'];
  static const cols = [
    Color(0xFFC0392B), Color(0xFF1E8449),
    Color(0xFFB7950B), Color(0xFF2471A3),
  ];

  // token state: [player][token] = -1 base, 0..51 track, 52..57 home column, 58 finished
  late List<List<int>> tok;
  int turn = 0;
  int dice = 0;
  // The last number rolled, kept on the die between turns.
  int lastRoll = 0;
  // Bumped by every reset so a late Hadi turn or pass timer from the old
  // game cannot touch the new one.
  int _gen = 0;
  bool rolled = false;
  bool usedRoll = true;
  int mode = 0; // 0 menu, 1 vs Hadi, 2 two players
  final _rnd = Random();
  String status = 'Choose your table below';
  int? selToken;
  String hadiLine = '';
  bool gameOver = false;
  final _rooms = GameRoomsService();
  String? roomCode;
  String mySide = 'host';
  int myIdx = 0;
  StreamSubscription<dynamic>? _roomSub;

  // Online play: moves are numbered (see RoomMoves), queued, and sent in
  // order. A move that could not be delivered stays queued and the person
  // can retry; sending the same number twice is harmless.
  RoomMoves _log = RoomMoves(mySide: 'host');
  late final MoveOutbox _outbox = MoveOutbox(
    send: (int seq, Map<String, dynamic> move) async {
      final String? code = roomCode;
      if (code != null) await _rooms.sendMove(code, seq, move);
    },
    finish: (String result) async {
      final String? code = roomCode;
      if (code != null) await _rooms.finish(code, result);
    },
  );
  bool _opponentLeft = false;
  String? _syncError;

  static const _hadiLudo = [
    'Hadi: The dice belong to Allah — the moves belong to you.',
    'Hadi: A token sent home is not an ending; the board always invites return.',
    'Hadi: Patience — the six will come, as rizq comes: on time.',
    'Hadi: I protect my stars. Do you protect yours?',
    'Hadi: One careful step beats three hurried ones.',
  ];

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    super.dispose();
  }

  /// Queues a move for the room and starts sending. [result] is set on the
  /// winning move so the room is finished right after it is delivered.
  void _queueOnline(Map<String, dynamic> move, {String? result}) {
    _outbox.add(_log.reserve(), move, result: result);
    unawaited(_flush());
  }

  Future<void> _flush() async {
    if (_outbox.isEmpty) return;
    final bool ok = await _outbox.flush();
    if (!mounted) return;
    if (ok) {
      if (_syncError != null) setState(() => _syncError = null);
    } else if (!_outbox.isEmpty) {
      setState(() => _syncError =
          'Your move has not reached your opponent yet. Check your '
          'connection, then retry.');
    }
  }

  void _reset() {
    _gen++;
    lastRoll = 0;
    tok = List.generate(4, (_) => List.filled(4, -1));
    turn = 0;
    dice = 0;
    rolled = false;
    usedRoll = true;
    selToken = null;
    gameOver = false;
    hadiLine = '';
    status = mode == 1
        ? 'You are Red — Hadi takes Green'
        : mode == 2
            ? 'Two players — Red and Green'
            : 'Choose your table below';
  }

  int _abs(int player, int rel) => (starts[player] + rel) % 52;

  List<int> _validMoves(int player, int roll) =>
      LudoRules.validMoves(tok, player, roll);

  void _apply(int player, int t, int roll) {
    final p = tok[player][t];
    if (p == -1) {
      tok[player][t] = 0;
    } else if (p <= 51) {
      final np = p + roll;
      if (np <= 51) {
        tok[player][t] = np;
        final sq = _abs(player, np);
        if (!safe.contains(sq)) {
          for (var pl = 0; pl < 4; pl++) {
            if (pl == player) continue;
            for (var tt = 0; tt < 4; tt++) {
              final q = tok[pl][tt];
              if (q >= 0 && q <= 51 && _abs(pl, q) == sq) {
                tok[pl][tt] = -1;
              }
            }
          }
        }
      } else {
        tok[player][t] = 52 + (np - 52);
      }
    } else {
      tok[player][t] = p + roll;
    }
    if (tok[player][t] == 58) {
      if (tok[player].every((x) => x == 58)) {
        gameOver = true;
        status = '${names[player]} wins — all four tokens home';
        return;
      }
    }
  }

  void _nextTurn({bool extra = false}) {
    if (gameOver) return;
    if (!extra) turn = (turn + 1) % (mode == 2 ? 2 : 2);
    rolled = false;
    usedRoll = false;
    dice = 0;
    selToken = null;
    status = '${names[turn]} to roll';
    if (mode == 1 && turn == 1) _aiTurn();
  }

  void _roll() {
    if (gameOver || rolled) return;
    if (mode == 3 && turn != myIdx) return;
    setState(() {
      dice = 1 + _rnd.nextInt(6);
      lastRoll = dice;
      rolled = true;
      selToken = null;
      final valid = _validMoves(turn, dice);
      if (valid.isEmpty) {
        status = LudoRules.onlyBaseTokens(tok, turn)
            ? '${names[turn]} rolled $dice — a 6 brings a token out, passing'
            : '${names[turn]} rolled $dice — no move, passing';
        final int passer = turn;
        final int passRoll = dice;
        final int gen = _gen;
        Future<void>.delayed(const Duration(milliseconds: 1100), () {
          if (!mounted || gen != _gen) return;
          setState(() {
            _nextTurn();
            // The opponent must hear about a pass too, or their board waits
            // on a turn that never comes.
            if (mode == 3 && roomCode != null) {
              _queueOnline(<String, dynamic>{
                'by': mySide, 'd': passRoll, 'pass': true,
                'turn': passer, 'next': turn,
              });
            }
          });
        });
      } else {
        status = '${names[turn]} rolled $dice — choose a token';
      }
    });
  }

  void _move(int t) {
    if (!rolled || gameOver) return;
    // Hadi's tokens move only by Hadi's own turn: a tap on a green token
    // while he is thinking used to move it for him (and he then moved twice).
    if (mode == 1 && turn == 1) return;
    if (mode == 3 && turn != myIdx) return;
    if (!_validMoves(turn, dice).contains(t)) return;
    final d = dice;
    final mover = turn;
    setState(() {
      _apply(turn, t, d);
      // _nextTurn leaves the turn alone when the game is over.
      _nextTurn(extra: d == 6);
      if (mode == 3 && roomCode != null) {
        // Always sent, the winning move included, and the room is finished
        // after it: the opponent must see the last move and the result.
        _queueOnline(
          <String, dynamic>{
            'by': mySide, 'd': d, 't': t, 'turn': mover, 'next': turn,
          },
          result: gameOver ? '${names[mover]} wins' : null,
        );
      }
    });
  }

  void _aiTurn() async {
    final int gen = _gen;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted || gameOver || gen != _gen) return;
    setState(() => _rollSilent());
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted || gameOver || gen != _gen) return;
    final valid = _validMoves(1, dice);
    if (valid.isEmpty) {
      setState(() {
        status = 'Hadi rolled $dice — no move';
        hadiLine = _hadiLudo[_rnd.nextInt(_hadiLudo.length)];
      });
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted && gen == _gen) setState(() => _nextTurn());
      return;
    }
    int best = valid.first, bestScore = -1;
    for (final t in valid) {
      var s = _rnd.nextInt(3);
      final p = tok[1][t];
      if (p == -1) s += 6;
      if (p >= 0 && p <= 51) {
        final np = p + dice;
        if (np <= 51) {
          final sq = _abs(1, np);
          var capturable = 0;
          for (var pl = 0; pl < 4; pl++) {
            if (pl == 1) continue;
            for (var tt = 0; tt < 4; tt++) {
              final q = tok[pl][tt];
              if (q >= 0 && q <= 51 && _abs(pl, q) == sq) capturable++;
            }
          }
          s += capturable * 12;
          if (!safe.contains(sq)) s -= 2;
        } else {
          s += 8;
        }
      }
      if (p >= 52) s += 5;
      if (s > bestScore) {
        bestScore = s;
        best = t;
      }
    }
    setState(() {
      _apply(1, best, dice);
      hadiLine = _hadiLudo[_rnd.nextInt(_hadiLudo.length)];
      if (!gameOver) _nextTurn(extra: dice == 6);
    });
  }

  void _rollSilent() {
    dice = 1 + _rnd.nextInt(6);
    lastRoll = dice;
    rolled = true;
  }

  Future<void> _onlineSetup() async {
    final r = await OnlineLobby.show(context, 'ludo', _rooms);
    if (r == null || !mounted) return;
    _outbox.clear();
    _syncError = null;
    _opponentLeft = false;
    setState(() {
      mode = 3;
      roomCode = r['code'];
      mySide = r['side']!;
      myIdx = mySide == 'host' ? 0 : 1;
      _log = RoomMoves(mySide: mySide);
      _reset();
      turn = 0;
      status = mySide == 'host'
          ? 'Table ${roomCode} — waiting for your opponent\u2026'
          : 'Joined ${roomCode} — you are Green';
    });
    await _roomSub?.cancel();
    _roomSub = _rooms.watch(roomCode!)?.listen(
      _onRoom,
      onError: (Object e) {
        if (!mounted) return;
        setState(() => _syncError =
            'The connection to the table dropped. It will resume when you '
            'are back online.');
      },
    );
  }

  /// A remote move that is safe to apply: every index in range.
  static bool _sane(Map<String, dynamic> m) {
    final Object? d = m['d'], t = m['t'], next = m['next'];
    final bool base = d is num && d >= 1 && d <= 6 &&
        next is num && (next == 0 || next == 1);
    if (!base) return false;
    return m['pass'] == true || (t is num && t >= 0 && t <= 3);
  }

  void _onRoom(DocumentSnapshot<Map<String, dynamic>> snap) {
    final Map<String, dynamic>? data = snap.data();
    if (data == null || !mounted) return;
    final guest = data['guest'];
    if (mySide == 'host' && guest != null && data['status'] == 'playing' &&
        status.startsWith('Table')) {
      setState(() => status = 'Red to roll');
    }
    for (final Map<String, dynamic> m in _log.incoming(data['moves'])) {
      if (!_sane(m)) continue;
      final int mover = 1 - myIdx;
      if (m['pass'] == true) {
        setState(() {
          turn = (m['next'] as num).toInt();
          rolled = false;
          dice = 0;
          status = '${names[turn]} to roll';
        });
        continue;
      }
      setState(() {
        dice = (m['d'] as num).toInt();
        _apply(mover, (m['t'] as num).toInt(), dice);
        if (!gameOver) {
          turn = (m['next'] as num).toInt();
          rolled = false;
          dice = 0;
          status = '${names[turn]} to roll';
        }
      });
    }
    if (data['status'] == 'left' && !gameOver && !_opponentLeft) {
      _opponentLeft = true;
      setState(() => status = 'Your opponent left the table');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const ScreenHeader(title: 'Ludo', close: true),
          Center(child: Text('THE SECOND CROWN \u00b7 FOUR TOKENS, ONE HEART', style: AppText.eyebrow)),
          const SizedBox(height: 12),
          if (mode == 0)
            Column(children: [
              _mode('Play Hadi', 'Green takes the dice against you', Icons.casino_outlined, () => setState(() { mode = 1; _reset(); })),
              const SizedBox(height: 10),
              _mode('Two players', 'Red and Green, passing the phone', Icons.people_outline, () => setState(() { mode = 2; _reset(); })),
              const SizedBox(height: 10),
              _mode('Play a friend online', 'Create a table, share the six-letter code',
                  Icons.wifi, _onlineSetup),
              const SizedBox(height: 10),
              board(),
              const SizedBox(height: 8),
              Text('Four-player tables and online rooms arrive with the family cloud.',
                  style: AppText.bodyMuted.copyWith(fontSize: 12)),
            ])
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Expanded(child: Text(status, style: AppText.body.copyWith(fontSize: 13))),
                TextButton(
                  onPressed: () {
                    if (mode == 3 && roomCode != null) {
                      unawaited(_rooms.leave(roomCode!));
                      _roomSub?.cancel();
                      _roomSub = null;
                      _outbox.clear();
                      _syncError = null;
                    }
                    setState(() { mode = 0; roomCode = null; _reset(); });
                  },
                  child: const Text('Leave', style: TextStyle(color: AppColors.goldLight, fontSize: 12))),
                // A restart is local only: in an online game it would leave
                // the two boards different, so it is not offered there.
                if (mode != 3)
                  TextButton(
                    onPressed: () => setState(() => _reset()),
                    child: const Text('Restart', style: TextStyle(color: AppColors.goldLight, fontSize: 12))),
              ]),
            ),
            if (_syncError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  Expanded(
                    child: Text(_syncError!,
                        style: AppText.bodyMuted.copyWith(
                            fontSize: 12, color: Colors.orangeAccent)),
                  ),
                  TextButton(
                    onPressed: () => unawaited(_flush()),
                    child: const Text('Retry',
                        style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
                  ),
                ]),
              ),
            if (hadiLine.isNotEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(hadiLine, style: AppText.bodyMuted.copyWith(fontStyle: FontStyle.italic, fontSize: 12))),
            const SizedBox(height: 8),
            board(),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 54, height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF0A0F18),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
                child: DiceFace(
                    value: LudoRules.faceValue(dice: dice, lastRoll: lastRoll)),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: (rolled || gameOver || (mode == 1 && turn == 1)) ? null : _roll,
                icon: const Icon(Icons.casino_outlined, size: 18),
                label: const Text('Roll'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: const Color(0xFF0A0F18),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            if (rolled && !gameOver)
              Text('Tap a glowing token to move',
                  textAlign: TextAlign.center,
                  style: AppText.bodyMuted.copyWith(fontSize: 12))
            else if (!gameOver && LudoRules.onlyBaseTokens(tok, turn))
              Text(
                'You need a 6 to bring a token out of its base. '
                'Keep rolling until one comes.',
                key: const Key('ludo-six-hint'),
                textAlign: TextAlign.center,
                style: AppText.bodyMuted.copyWith(fontSize: 12),
              ),
          ],
        ],
      ),
    );
  }

  Widget _mode(String t, String s, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          color: const Color(0x1405090F),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.goldLight, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: AppText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(s, style: AppText.bodyMuted.copyWith(fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.gold),
        ]),
      ),
    );
  }

  Widget board() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 22, offset: const Offset(0, 12))],
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 15),
            itemCount: 225,
            itemBuilder: (context, i) {
              final r = i ~/ 15, c = i % 15;
              return _cell(r, c);
            },
          ),
        ),
      ),
    );
  }

  Widget _cell(int r, int c) {
    Color bg = const Color(0xFFF3E9D2);
    var star = false;
    for (var k = 0; k < 52; k++) {
      if (track[k][0] == r && track[k][1] == c) {
        if (safe.contains(k)) star = true;
        bg = const Color(0xFFEFE3C4);
      }
    }
    for (var pl = 0; pl < 4; pl++) {
      for (var h = 0; h < 6; h++) {
        if (homes[pl][h][0] == r && homes[pl][h][1] == c) bg = cols[pl].withValues(alpha: 0.85);
      }
      final br = bases[pl][0], bc = bases[pl][1];
      if (r >= br && r <= br + 2 && c >= bc && c <= bc + 2) bg = cols[pl].withValues(alpha: 0.92);
    }
    if (r >= 6 && r <= 8 && c >= 6 && c <= 8) {
      final q = (r - 6) * 3 + (c - 6);
      bg = [cols[0], cols[1], cols[2], cols[3]][((q ~/ 3) + (q % 3)) % 4].withValues(alpha: 0.9);
    }

    final tokensHere = <int>[];
    for (var pl = 0; pl < 4; pl++) {
      for (var t = 0; t < 4; t++) {
        final p = tok[pl][t];
        int? rr, cc;
        if (p == -1) {
          rr = bases[pl][0] + 1;
          cc = bases[pl][1] + 1;
        } else if (p <= 51) {
          final a = _abs(pl, p);
          rr = track[a][0];
          cc = track[a][1];
        } else if (p <= 57) {
          rr = homes[pl][p - 52][0];
          cc = homes[pl][p - 52][1];
        }
        if (rr == r && cc == c && p != 58) tokensHere.add(pl * 4 + t);
      }
    }

    final canMove = rolled && !gameOver &&
        tokensHere.any((x) => x ~/ 4 == turn && _validMoves(turn, dice).contains(x % 4));

    return GestureDetector(
      onTap: () {
        for (final x in tokensHere) {
          if (x ~/ 4 == turn) {
            _move(x % 4);
            return;
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: Colors.black.withValues(alpha: 0.18), width: 0.3),
          boxShadow: canMove
              ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.9), blurRadius: 7)]
              : null,
        ),
        child: Stack(alignment: Alignment.center, children: [
          if (star) Icon(Icons.star, size: 9, color: Colors.brown.withValues(alpha: 0.65)),
          if (tokensHere.isNotEmpty)
            Wrap(alignment: WrapAlignment.center, spacing: 1, runSpacing: 1, children: [
              for (final x in tokensHere.take(4))
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.4, -0.4),
                      colors: [Colors.white.withValues(alpha: 0.9), cols[x ~/ 4]],
                    ),
                    border: Border.all(
                      color: (x ~/ 4) == turn
                          ? AppColors.gold
                          : Colors.white.withValues(alpha: 0.85),
                      width: (x ~/ 4) == turn ? 1.4 : 0.8),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 1.5)],
                  ),
                ),
            ]),
        ]),
      ),
    );
  }
}


/// The dice, painted in gold with real pips - no font tricks.
class DiceFace extends StatelessWidget {
  final int value;
  const DiceFace({super.key, required this.value});

  static const _pips = {
    1: [4], 2: [0, 8], 3: [0, 4, 8], 4: [0, 2, 6, 8],
    5: [0, 2, 4, 6, 8], 6: [0, 2, 3, 5, 6, 8],
  };


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF171310), Color(0xFF0A0F18)]),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
      ),
      child: value == 0
          ? const Center(child: Text('?',
              style: TextStyle(color: AppColors.goldLight, fontSize: 22)))
          : GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < 9; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (_pips[value] ?? const []).contains(i)
                          ? AppColors.goldLight
                          : Colors.transparent,
                    ),
                  ),
              ],
            ),
    );
  }
}
