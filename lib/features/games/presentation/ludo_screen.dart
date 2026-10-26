import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../data/game_rooms_service.dart';
import '../data/games_store.dart';
import '../data/ludo_board_art.dart';
import '../data/ludo_rules.dart';
import '../data/room_moves.dart';
import '../ui/games_theme.dart';
import 'ludo_board_view.dart';
import 'online_lobby.dart';

/// LUDO. The board is the owner's picture (`assets/games/ludo/board.webp`),
/// the rules are in `data/ludo_rules.dart` (46-cell loop, exact finish, six to
/// leave the yard, extra roll on a six, safe squares, captures).
///
/// Local play takes 2 to 4 seats on one device: people share the phone and
/// computer players fill the empty seats. Online tables (a six-letter code)
/// stay at two players: the room has one host and one guest, and changing
/// that needs a backend change.
class LudoScreen extends StatefulWidget {
  /// [initialMode]: 0 opens the table menu, 1 starts against the computer,
  /// 2 starts pass-and-play on this device (the Games setup screen passes it).
  /// [players] is the number of seats (2 to 4); [humans] how many of them
  /// share this phone (0 = all of them in pass-and-play). [seed] fixes the
  /// dice, for tests.
  const LudoScreen({
    this.initialMode = 0,
    this.players = 2,
    this.humans = 0,
    this.seed,
    super.key,
  });

  final int initialMode;
  final int players;
  final int humans;
  final int? seed;

  @override
  State<LudoScreen> createState() => _LudoState();
}

class _LudoState extends State<LudoScreen> {
  late final LudoDice _dice = LudoDice(widget.seed);
  late List<int> seats;
  late List<List<int>> tok;
  int players = 2;
  int humans = 1;
  int turn = 0;
  int dice = 0;
  // The last number rolled, kept on the die between turns.
  int lastRoll = 0;
  // Bumped by every reset so a late computer turn or pass timer from the old
  // game cannot touch the new one.
  int _gen = 0;
  bool rolled = false;
  bool gameOver = false;
  int? winner;
  bool _recorded = false;
  // 0 menu, 1 against the computer, 2 pass and play, 3 online table.
  int mode = 0;
  String status = '';
  String hadiLine = '';

  // Menu choices.
  int _menuPlayers = 2;
  int _menuHumans = 2;

  // Online table.
  final GameRoomsService _rooms = GameRoomsService();
  String? roomCode;
  String mySide = 'host';
  int myIdx = 0;
  StreamSubscription<dynamic>? _roomSub;
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
  // True once the table has been seen, so a table that is not there yet is
  // not mistaken for "the other player left".
  bool _seenRoom = false;
  String? _syncError;

  static const List<String> _hadiLudo = <String>[
    'Hadi: The dice decide the roll; you decide the move.',
    'Hadi: A pawn sent home is not an ending; the board always invites return.',
    'Hadi: Patience. The six will come.',
    'Hadi: I protect my stars. Do you protect yours?',
    'Hadi: One careful step beats three hurried ones.',
  ];

  @override
  void initState() {
    super.initState();
    mode = widget.initialMode == 1 || widget.initialMode == 2
        ? widget.initialMode
        : 0;
    players = widget.players.clamp(2, 4);
    if (mode == 1) {
      humans = 1;
    } else {
      humans = widget.humans <= 0 ? players : widget.humans.clamp(1, players);
    }
    _menuPlayers = players;
    _menuHumans = players == 2 ? 2 : humans.clamp(2, players);
    _reset();
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    // Leaving the screen leaves the table, and a left table is deleted.
    final String? code = roomCode;
    if (mode == 3 && code != null) unawaited(_rooms.leave(code));
    super.dispose();
  }

  // ---------------------------------------------------------------- names

  bool _isHuman(int seat) => mode == 3 || seat < humans;

  String _label(int seat) {
    if (mode == 3) return 'Player ${seat + 1}';
    if (mode == 1) {
      if (seat == 0) return 'You';
      return seat == 1 ? 'Hadi' : 'Computer ${seat + 1}';
    }
    return _isHuman(seat)
        ? 'Player ${seat + 1}'
        : (seat == players - 1 && players - humans == 1
            ? 'Hadi'
            : 'Computer ${seat + 1}');
  }

  String _colourName(int seat) => LudoRules.colourNames[seats[seat]];

  static String _initials(String label) {
    final List<String> w = label.split(' ');
    if (w.length == 2 && int.tryParse(w[1]) != null) return '${w[0][0]}${w[1]}';
    return label.isEmpty ? '?' : label[0];
  }

  // ---------------------------------------------------------------- rules

  void _reset() {
    _gen++;
    seats = LudoRules.seatColours(players);
    tok = LudoRules.newTokens(players);
    turn = 0;
    dice = 0;
    lastRoll = 0;
    rolled = false;
    gameOver = false;
    winner = null;
    _recorded = false;
    hadiLine = '';
    status = _startStatus();
  }

  String _startStatus() {
    final String colours = seats
        .map((int c) => LudoRules.colourNames[c])
        .join(', ');
    if (mode == 1) {
      return players == 2
          ? 'You are Red — Hadi takes Yellow'
          : 'You are Red — ${players - 1} computer players join';
    }
    if (mode == 2) {
      if (players == 2 && humans == 2) {
        return 'Two players — Red and Yellow';
      }
      return '$players players, $humans on this phone — $colours';
    }
    return 'Choose your table below';
  }

  List<int> _legal() => LudoRules.validMoves(tok, turn, dice);

  bool get _canRoll {
    if (gameOver || rolled) return false;
    if (mode == 3) return turn == myIdx && roomCode != null;
    return mode != 0 && _isHuman(turn);
  }

  /// Applies a move for [seat] and moves the game on. Call inside setState.
  LudoMoveResult _play(int seat, int t, int roll) {
    final LudoMoveResult res = LudoRules.applyMove(tok, seats, seat, t, roll);
    final String who = _label(seat);
    final StringBuffer sb = StringBuffer('$who moved pawn ${t + 1}');
    for (final (int, int) c in res.captured) {
      sb.write(' and sent a ${_colourName(c.$1)} pawn back to its yard');
    }
    if (res.reachedHome) sb.write(' — home');
    if (res.won) {
      gameOver = true;
      winner = seat;
      status = '$who wins — all four pawns home';
      _recordEnd();
      return res;
    }
    status = sb.toString();
    _endTurn(extra: res.extraTurn);
    return res;
  }

  /// Passes the turn on (or keeps it, after a six). Call inside setState.
  void _endTurn({required bool extra}) {
    if (gameOver) return;
    if (!extra) turn = LudoRules.nextSeat(turn, players);
    rolled = false;
    dice = 0;
    if ((mode == 1 || mode == 2) && !_isHuman(turn)) {
      unawaited(_cpuTurn());
    }
  }

  /// Writes a finished local game on this device once.
  void _recordEnd() {
    if (_recorded || (mode != 1 && mode != 2)) return;
    _recorded = true;
    final int w = winner ?? 0;
    final String outcome = '${_colourName(w)} wins';
    final int n = players;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      recordBoardResult(
        context,
        gameId: 'ludo',
        title: 'Ludo',
        outcome: outcome,
        players: n,
      );
    });
  }

  void _roll() {
    if (!_canRoll) return;
    final int r = _dice.roll();
    setState(() {
      dice = r;
      lastRoll = r;
      rolled = true;
      final List<int> legal = _legal();
      if (legal.isEmpty) {
        status = LudoRules.onlyBaseTokens(tok, turn)
            ? '${_label(turn)} rolled $r — a 6 brings a pawn out, passing'
            : '${_label(turn)} rolled $r — no move, passing';
        final int passer = turn;
        final int gen = _gen;
        Future<void>.delayed(const Duration(milliseconds: 1100), () {
          if (!mounted || gen != _gen) return;
          setState(() {
            _endTurn(extra: false);
            // The opponent must hear about a pass too, or their board waits
            // on a turn that never comes.
            if (mode == 3 && roomCode != null) {
              _queueOnline(<String, dynamic>{
                'by': mySide, 'd': r, 'pass': true,
                'turn': passer, 'next': turn,
              });
            }
          });
        });
      } else {
        status = '${_label(turn)} rolled $r — choose a pawn';
      }
    });
  }

  void _move(int t) {
    if (!rolled || gameOver) return;
    if ((mode == 1 || mode == 2) && !_isHuman(turn)) return;
    if (mode == 3 && turn != myIdx) return;
    if (!_legal().contains(t)) return;
    final int d = dice;
    final int mover = turn;
    setState(() {
      _play(mover, t, d);
      if (mode == 3 && roomCode != null) {
        // Always sent, the winning move included, and the room is finished
        // after it: the opponent must see the last move and the result.
        _queueOnline(
          <String, dynamic>{
            'by': mySide, 'd': d, 't': t, 'turn': mover, 'next': turn,
          },
          result: gameOver ? '${_colourName(mover)} wins' : null,
        );
      }
    });
  }

  /// One computer turn: roll, look, move. Chains itself through sixes.
  Future<void> _cpuTurn() async {
    final int gen = _gen;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted || gen != _gen || gameOver) return;
    final int seat = turn;
    final int r = _dice.roll();
    setState(() {
      dice = r;
      lastRoll = r;
      rolled = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted || gen != _gen || gameOver) return;
    final List<int> legal = LudoRules.validMoves(tok, seat, r);
    if (legal.isEmpty) {
      setState(() {
        status = '${_label(seat)} rolled $r — no move';
        hadiLine = _hadiLudo[_hadiIndex(seat, r)];
      });
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted || gen != _gen) return;
      setState(() => _endTurn(extra: false));
      return;
    }
    final int t = LudoBot.choose(tok, seats, seat, r, legal);
    setState(() {
      hadiLine = _hadiLudo[_hadiIndex(seat, r)];
      _play(seat, t, r);
    });
  }

  // A fixed pick, so the line does not need a second source of randomness.
  int _hadiIndex(int seat, int r) => (seat + r + lastRoll) % _hadiLudo.length;

  // ---------------------------------------------------------------- online

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

  Future<void> _onlineSetup() async {
    final Map<String, String>? r =
        await OnlineLobby.show(context, 'ludo', _rooms);
    if (r == null || !mounted) return;
    _outbox.clear();
    _syncError = null;
    _opponentLeft = false;
    _seenRoom = false;
    setState(() {
      mode = 3;
      players = 2;
      humans = 2;
      roomCode = r['code'];
      mySide = r['side']!;
      myIdx = mySide == 'host' ? 0 : 1;
      _log = RoomMoves(mySide: mySide);
      _reset();
      status = mySide == 'host'
          ? 'Table $roomCode — waiting for your opponent…'
          : 'Joined $roomCode — you are Player 2 (Yellow)';
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

  /// A remote move that is safe to look at: every index in range.
  static bool _sane(Map<String, dynamic> m) {
    final Object? d = m['d'], t = m['t'], next = m['next'];
    final bool base = d is num && d >= 1 && d <= 6 &&
        next is num && (next == 0 || next == 1);
    if (!base) return false;
    return m['pass'] == true || (t is num && t >= 0 && t <= 3);
  }

  void _onRoom(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!mounted) return;
    final Map<String, dynamic>? data = snap.data();
    if (data == null) {
      // The table is gone: the other player left (leaving deletes it).
      if (_seenRoom && !snap.exists && !gameOver && !_opponentLeft) {
        setState(() {
          _opponentLeft = true;
          status = 'Your opponent left the table';
        });
      }
      return;
    }
    _seenRoom = true;
    final Object? guest = data['guest'];
    if (mySide == 'host' && guest != null && data['status'] == 'playing' &&
        status.startsWith('Table')) {
      setState(() => status = 'Red to roll');
    }
    for (final Map<String, dynamic> m in _log.incoming(data['moves'])) {
      if (!_sane(m)) continue;
      final int mover = 1 - myIdx;
      final int d = (m['d'] as num).toInt();
      if (m['pass'] == true) {
        setState(() {
          turn = (m['next'] as num).toInt();
          rolled = false;
          dice = 0;
          lastRoll = d;
        });
        continue;
      }
      final int t = (m['t'] as num).toInt();
      if (turn != mover || !LudoRules.validMoves(tok, mover, d).contains(t)) {
        setState(() => _syncError =
            'A move from your opponent did not fit your board, so the two '
            'boards are out of step. Leave the table and start a new one.');
        continue;
      }
      setState(() {
        dice = d;
        lastRoll = d;
        _play(mover, t, d);
      });
    }
    if (data['status'] == 'left' && !gameOver && !_opponentLeft) {
      _opponentLeft = true;
      setState(() => status = 'Your opponent left the table');
    }
  }

  void _leave() {
    if (mode == 3 && roomCode != null) {
      _roomSub?.cancel();
      _roomSub = null;
      unawaited(_rooms.leave(roomCode!));
      _outbox.clear();
      _syncError = null;
    }
    setState(() {
      mode = 0;
      roomCode = null;
      players = _menuPlayers;
      humans = _menuHumans;
      _reset();
    });
  }

  // ---------------------------------------------------------------- menu

  void _start(int newMode) {
    setState(() {
      mode = newMode;
      players = _menuPlayers;
      humans = newMode == 1 ? 1 : (players == 2 ? 2 : _menuHumans);
      _reset();
    });
  }

  // ---------------------------------------------------------------- sheets

  void _showSheet(String title, List<Widget> children) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF0A0F18),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext ctx) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(title, style: AppText.titleMedium),
                const SizedBox(height: 12),
                ...children,
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHowTo() {
    _showSheet('How to play Ludo', <Widget>[
      for (final String line in LudoRules.howToPlay)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(line, style: AppText.body.copyWith(height: 1.45)),
        ),
      const SizedBox(height: 4),
      Text(
        'Telling colours apart: every colour has a shape (red circle, blue '
        'square, yellow triangle, green diamond) and every pawn has a '
        'number.',
        style: AppText.bodyMuted.copyWith(height: 1.45),
      ),
    ]);
  }

  void _showSettings() {
    _showSheet('Table settings', <Widget>[
      if (mode != 3)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OutlineAction(
            label: 'Restart this game',
            icon: Icons.refresh,
            onPressed: () {
              Navigator.of(context).pop();
              setState(_reset);
            },
          ),
        ),
      OutlineAction(
        label: mode == 3 ? 'Leave the table' : 'Back to the table menu',
        icon: Icons.logout,
        onPressed: () {
          Navigator.of(context).pop();
          _leave();
        },
      ),
      const SizedBox(height: 10),
      Text(
        'No sound, no timer and no stakes of any kind.',
        style: AppText.bodyMuted,
      ),
    ]);
  }

  // ---------------------------------------------------------------- build

  Widget _banner() {
    final String name = _label(turn);
    String eyebrow;
    String title;
    if (gameOver) {
      eyebrow = 'GAME OVER';
      title = '${_label(winner ?? turn)} wins';
    } else {
      final bool mine = mode == 3 ? turn == myIdx : _isHuman(turn);
      eyebrow = name == 'You'
          ? "IT'S YOUR TURN"
          : (mine || mode == 3
              ? "IT'S ${name.toUpperCase()}'S TURN"
              : '${name.toUpperCase()} IS PLAYING');
      if (mode == 3 && roomCode != null && status.startsWith('Table')) {
        eyebrow = 'WAITING FOR PLAYER 2';
        title = 'Share the code $roomCode';
      } else if (mode == 3 && turn != myIdx) {
        title = 'Waiting for ${_label(turn)}';
      } else if (!mine) {
        title = rolled ? 'Rolled $dice' : 'Thinking…';
      } else if (!rolled) {
        title = 'Roll the Dice';
      } else {
        title = _legal().isEmpty ? 'No move — passing' : 'Choose a pawn';
      }
    }
    return Semantics(
      container: true,
      liveRegion: true,
      label: '$eyebrow. $title',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xCC05090F),
          border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.8)),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x40D4AF37), blurRadius: 14),
          ],
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.casino, color: AppColors.goldLight, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      eyebrow,
                      style: AppText.eyebrow.copyWith(fontSize: 11),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 26,
                        color: GamesTheme.champagne,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int s = 0; s < players; s++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _PlayerCard(
                label: _label(s) + (mode == 3 && s == myIdx ? ' (you)' : ''),
                initials: _initials(_label(s)),
                colour: seats[s],
                tokens: tok[s],
                active: !gameOver && s == turn,
                won: gameOver && s == winner,
              ),
            ),
          ),
      ],
    );
  }

  Widget _diceRow() {
    final bool online = mode == 3;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // The designs have a Chat button here. There is no chat in Ludo.
        _SmallAction(
          icon: Icons.help_outline,
          label: 'How to Play',
          onTap: _showHowTo,
        ),
        const SizedBox(width: 12),
        LudoDiceStage(
          value: LudoRules.faceValue(dice: dice, lastRoll: lastRoll),
          size: 104,
        ),
        const SizedBox(width: 12),
        _SmallAction(
          icon: Icons.settings_outlined,
          label: online ? 'Table' : 'Settings',
          onTap: _showSettings,
        ),
      ],
    );
  }

  Widget _moveButtons() {
    if (!rolled || gameOver || !_canMoveNow) return const SizedBox.shrink();
    final List<int> legal = _legal();
    if (legal.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final int t in legal)
            GameChip(
              label: 'Move pawn ${t + 1}',
              selected: false,
              onTap: () => _move(t),
            ),
        ],
      ),
    );
  }

  bool get _canMoveNow {
    if (mode == 3) return turn == myIdx;
    return (mode == 1 || mode == 2) && _isHuman(turn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: <Widget>[
          const ScreenHeader(title: 'Ludo', close: true),
          Center(
            child: Text(
              'THE SECOND CROWN · FOUR PAWNS, ONE HEART',
              style: AppText.eyebrow,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          if (mode == 0) ..._menu() else ..._game(),
        ],
      ),
    );
  }

  List<Widget> _menu() {
    final int p = _menuPlayers;
    return <Widget>[
      GamePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                'How many players?',
                style: AppText.titleMedium.copyWith(
                  color: GamesTheme.champagne,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final int n in <int>[2, 3, 4])
                  GameChip(
                    label: '$n players',
                    selected: p == n,
                    onTap: () => setState(() {
                      _menuPlayers = n;
                      if (_menuHumans > n) _menuHumans = n;
                      if (_menuHumans < 2) _menuHumans = 2;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Computer players take any seat nobody sits in.',
              style: AppText.bodyMuted.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      _modeCard(
        'Play Hadi',
        p == 2
            ? 'You (Red) against Hadi (Yellow)'
            : 'You against ${p - 1} computer players',
        Icons.casino_outlined,
        () => _start(1),
      ),
      const SizedBox(height: 10),
      _modeCard(
        'Pass and play',
        p == 2
            ? 'Red and Yellow, passing the phone'
            : '$_menuHumans of the $p seats share this phone',
        Icons.people_outline,
        () => _start(2),
      ),
      if (p > 2) ...<Widget>[
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text('People on this phone', style: AppText.bodyMuted),
            for (int n = 2; n <= p; n++)
              GameChip(
                label: '$n',
                selected: _menuHumans == n,
                onTap: () => setState(() => _menuHumans = n),
              ),
          ],
        ),
      ],
      const SizedBox(height: 10),
      _modeCard(
        'Play a friend online',
        'Create a table, share the six-letter code. Two players, no names.',
        Icons.wifi,
        _onlineSetup,
      ),
      const SizedBox(height: 14),
      LudoBoardView(
        seats: LudoRules.seatColours(p),
        tokens: LudoRules.newTokens(p),
      ),
      const SizedBox(height: 8),
      Text(
        'Online tables are for two players. Local tables take two to four.',
        style: AppText.bodyMuted.copyWith(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    ];
  }

  Widget _modeCard(String title, String sub, IconData icon, VoidCallback tap) {
    return GamePanel(
      onTap: tap,
      semanticsLabel: '$title. $sub',
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.goldLight, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(sub, style: AppText.bodyMuted.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gold),
        ],
      ),
    );
  }

  List<Widget> _game() {
    final Set<int> movable = rolled && !gameOver && _canMoveNow
        ? _legal().toSet()
        : const <int>{};
    return <Widget>[
      _banner(),
      const SizedBox(height: 10),
      _cards(),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(status, style: AppText.body.copyWith(fontSize: 13)),
            ),
            TextButton(
              onPressed: _leave,
              child: const Text(
                'Leave',
                style: TextStyle(color: AppColors.goldLight, fontSize: 12),
              ),
            ),
            // A restart is local only: in an online game it would leave the
            // two boards different, so it is not offered there.
            if (mode != 3)
              TextButton(
                onPressed: () => setState(_reset),
                child: const Text(
                  'Restart',
                  style: TextStyle(color: AppColors.goldLight, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      if (_syncError != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _syncError!,
                  style: AppText.bodyMuted.copyWith(
                    fontSize: 12,
                    color: Colors.orangeAccent,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => unawaited(_flush()),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: AppColors.goldLight, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      if (hadiLine.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            hadiLine,
            style: AppText.bodyMuted.copyWith(
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        ),
      const SizedBox(height: 8),
      LudoBoardView(
        seats: seats,
        tokens: tok,
        movableSeat: turn,
        movable: movable,
        onTapToken: _move,
      ),
      const SizedBox(height: 12),
      _diceRow(),
      const SizedBox(height: 12),
      Center(
        child: PlayButton(
          label: 'Roll Dice',
          icon: Icons.casino_outlined,
          onPressed: _canRoll ? _roll : null,
        ),
      ),
      _moveButtons(),
      const SizedBox(height: 8),
      if (rolled && !gameOver && _canMoveNow && _legal().isNotEmpty)
        Text(
          'Tap a glowing pawn to move, or use the buttons above.',
          textAlign: TextAlign.center,
          style: AppText.bodyMuted.copyWith(fontSize: 12),
        )
      else if (!gameOver && _canRoll && LudoRules.onlyBaseTokens(tok, turn))
        Text(
          'You need a 6 to bring a pawn out of its yard. '
          'Keep rolling until one comes.',
          key: const Key('ludo-six-hint'),
          textAlign: TextAlign.center,
          style: AppText.bodyMuted.copyWith(fontSize: 12),
        ),
    ];
  }
}

/// One player's card: initials in a round avatar, name, colour and shape, and
/// four dots for the pawns that are not home yet.
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.label,
    required this.initials,
    required this.colour,
    required this.tokens,
    required this.active,
    required this.won,
  });

  final String label;
  final String initials;
  final int colour;
  final List<int> tokens;
  final bool active;
  final bool won;

  @override
  Widget build(BuildContext context) {
    final int home = tokens.where((int p) => p == LudoRules.finished).length;
    final String name = LudoRules.colourNames[colour];
    return Semantics(
      container: true,
      label: '$label, $name, $home of 4 pawns home'
          '${active ? ', to play' : ''}${won ? ', winner' : ''}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xB305090F),
          border: Border.all(
            color: active || won
                ? AppColors.goldLight
                : AppColors.gold.withValues(alpha: 0.35),
            width: active || won ? 2 : 1,
          ),
          boxShadow: active
              ? const <BoxShadow>[
                  BoxShadow(color: Color(0x80FFD367), blurRadius: 14),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kLudoColours[colour].withValues(alpha: 0.28),
                    border: Border.all(color: AppColors.goldLight),
                  ),
                  child: Text(
                    initials,
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      color: GamesTheme.champagne,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (won)
                  const Positioned(
                    right: -8,
                    top: -10,
                    child: Icon(
                      Icons.workspace_premium,
                      color: AppColors.goldLight,
                      size: 18,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 14,
                  color: GamesTheme.champagne,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                LudoShapeMark(
                  colour: colour,
                  size: 9,
                  color: kLudoColours[colour],
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name,
                      style: AppText.caption.copyWith(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (final int p in tokens)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p == LudoRules.finished
                          ? Colors.transparent
                          : kLudoColours[colour],
                      border: Border.all(
                        color: kLudoColours[colour],
                        width: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A small round-cornered action (How to Play, Settings).
class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0x8005090F),
              border: Border.all(color: GamesTheme.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: AppColors.goldLight, size: 24),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppText.caption.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The die on its glowing ring. Before the first roll it shows the owner's
/// dice picture; after, the face that was rolled.
class LudoDiceStage extends StatelessWidget {
  const LudoDiceStage({required this.value, this.size = 104, super.key});

  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: value == 0 ? 'Die, not rolled yet' : 'Die showing $value',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: <Color>[Color(0x66FFD367), Color(0x00FFD367)],
          ),
          border: Border.all(
            color: AppColors.goldLight.withValues(alpha: 0.7),
            width: 1.6,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x80D4AF37), blurRadius: 22, spreadRadius: 2),
          ],
        ),
        child: value == 0
            ? Image.asset(
                LudoBoardArt.dice,
                width: size * 0.7,
                height: size * 0.7,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (BuildContext ctx, Object e, StackTrace? st) =>
                    DiceFace(value: 0, size: size * 0.6),
              )
            : DiceFace(value: value, size: size * 0.6),
      ),
    );
  }
}

/// A cream die face with dark pips, drawn in code.
class DiceFace extends StatelessWidget {
  const DiceFace({required this.value, this.size = 56, super.key});

  final int value;
  final double size;

  static const Map<int, List<int>> _pips = <int, List<int>>{
    1: <int>[4],
    2: <int>[0, 8],
    3: <int>[0, 4, 8],
    4: <int>[0, 2, 6, 8],
    5: <int>[0, 2, 4, 6, 8],
    6: <int>[0, 2, 3, 5, 6, 8],
  };

  @override
  Widget build(BuildContext context) {
    final List<int> on = _pips[value] ?? const <int>[];
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFF1CC), Color(0xFFE9C985)],
        ),
        border: Border.all(color: AppColors.goldLight),
      ),
      child: value == 0
          ? Center(
              child: Text(
                '?',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: const Color(0xFF5A3F12),
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : GridView.count(
              crossAxisCount: 3,
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                for (int i = 0; i < 9; i++)
                  Container(
                    margin: EdgeInsets.all(size * 0.035),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on.contains(i)
                          ? const Color(0xFF3A2A12)
                          : Colors.transparent,
                    ),
                  ),
              ],
            ),
    );
  }
}
