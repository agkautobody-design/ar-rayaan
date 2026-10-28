import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/child_mode.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../elder/application/elder_mode.dart';
import '../chess/chess_ai.dart';
import '../chess/chess_board_view.dart';
import '../chess/chess_engine.dart';
import '../chess/chess_game.dart';
import '../chess/chess_settings.dart';
import '../chess/chess_settings_sheet.dart';
import '../data/game_rooms_service.dart';
import '../data/games_store.dart';
import '../data/room_moves.dart';
import '../ui/games_theme.dart';
import 'online_lobby.dart';
import '../../../app/theme/widgets/focus_ring.dart';

/// SHATRANJ. A complete game of chess: every rule (castling, en passant,
/// promotion to the piece you choose, check, checkmate, stalemate, threefold
/// repetition, the fifty-move rule, insufficient material), undo and redo,
/// three computer levels, hints from the engine, a draw offer and resigning,
/// an optional clock, pass-and-play on one device, and online tables by code.
///
/// [initialMode]: 0 opens the table menu, 1 starts against Hadi, 2 starts
/// two players on this device. [level] is Hadi's strength, [playAs] is
/// 'white', 'black' or 'random', [minutes] is the clock per player (0 = no
/// clock), [seed] fixes Hadi's choices (for tests).
class ShatranjScreen extends ConsumerStatefulWidget {
  const ShatranjScreen({
    this.initialMode = 0,
    this.level = ChessLevel.intermediate,
    this.playAs = 'white',
    this.minutes = 0,
    this.seed,
    super.key,
  });

  final int initialMode;
  final ChessLevel level;
  final String playAs;
  final int minutes;
  final int? seed;

  @override
  ConsumerState<ShatranjScreen> createState() => _ShatranjState();
}

class _ShatranjState extends ConsumerState<ShatranjScreen> {
  ChessGame game = ChessGame();
  int mode = 0; // 0 = menu, 1 = vs Hadi, 2 = two players, 3 = online
  bool humanWhite = true;
  ChessLevel level = ChessLevel.intermediate;
  int minutes = 0;
  int whiteMs = 0;
  int blackMs = 0;
  Timer? _clock;

  // Options chosen on the table menu.
  ChessLevel _optLevel = ChessLevel.intermediate;
  String _optAs = 'white';
  int _optMinutes = 0;

  int? sel;
  Set<int> targets = <int>{};
  int? hintFrom;
  int? hintTo;
  bool aiThinking = false;
  bool hintThinking = false;
  int _token = 0;
  late final int _seed = widget.seed ?? DateTime.now().millisecondsSinceEpoch;
  late final Random _rnd = Random(_seed);
  String hadiLine = '';
  String _notice = '';
  bool _recorded = false;

  final GameRoomsService _rooms = GameRoomsService();
  String? roomCode;
  String mySide = 'host';
  StreamSubscription<dynamic>? _roomSub;
  String _onlineNote = '';

  // Online play: moves are numbered (see RoomMoves), queued and sent in
  // order; one that cannot be delivered stays queued for a retry.
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
  // True once the table has been seen, so a table that is not there yet
  // (a cache that is still empty) is not mistaken for "the other player left".
  bool _seenRoom = false;
  String? _syncError;

  // Hadi's lines, by what the move just played was, so the words fit the move.
  static const List<String> _hadiOpening = <String>[
    'Hadi: Every opening is a doorway. Choose yours well.',
    'Hadi: Bring your pieces out and keep the centre in sight.',
  ];
  static const List<String> _hadiMiddle = <String>[
    'Hadi: The middle game rewards the patient heart.',
    'Hadi: Your move carries intention. Make it a good one.',
    'Hadi: Even the queen bows to the plan, not the power.',
  ];
  static const List<String> _hadiCapture = <String>[
    'Hadi: A capture changes the balance. Check what it leaves undefended.',
    'Hadi: Taking a piece is never free. Look at what the capture opens.',
  ];
  static const String _hadiCheck =
      'Hadi: Check. Your king must answer it now: move it, block the attack or capture the attacker.';
  static const String _hadiCastle =
      'Hadi: Castling tucks the king away and wakes the rook.';
  static const String _hadiPromo =
      'Hadi: A pawn that crosses the whole board becomes a new piece.';

  /// The line for move [m], just played (so [game] already holds it).
  String _hadiLineFor(int m) {
    final String san = game.san.isEmpty ? '' : game.san.last;
    final int n = game.moves.length;
    if (san.contains('=')) return _hadiPromo;
    if (san.contains('+') || san.contains('#')) return _hadiCheck;
    if (moveIsCastle(m)) return _hadiCastle;
    if (moveIsCapture(m)) return _hadiCapture[(n ~/ 2) % _hadiCapture.length];
    if (n <= 12) return _hadiOpening[(n ~/ 2) % _hadiOpening.length];
    return _hadiMiddle[(n ~/ 2) % _hadiMiddle.length];
  }

  @override
  void initState() {
    super.initState();
    _optLevel = widget.level;
    _optAs = widget.playAs;
    _optMinutes = widget.minutes;
    if (widget.initialMode == 1 || widget.initialMode == 2) {
      _begin(widget.initialMode);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeAi();
      });
    }
  }

  @override
  void dispose() {
    _token++;
    _clock?.cancel();
    unawaited(_roomSub?.cancel());
    // Leaving the screen leaves the table, and a left table is deleted.
    final String? code = roomCode;
    if (mode == 3 && code != null) unawaited(_rooms.leave(code));
    super.dispose();
  }

  ChessSettings get _settings => ref.read(chessSettingsProvider);

  // ── Starting, leaving, saving ────────────────────────────────────────────

  void _begin(int m, {ChessGame? resume, bool? asWhite}) {
    _token++;
    mode = m;
    game = resume ?? ChessGame();
    level = _optLevel;
    minutes = m == 3 ? 0 : _optMinutes;
    humanWhite = asWhite ??
        switch (_optAs) {
          'black' => false,
          'random' => _rnd.nextBool(),
          _ => true,
        };
    whiteMs = blackMs = minutes * 60 * 1000;
    sel = null;
    targets = <int>{};
    hintFrom = hintTo = null;
    aiThinking = false;
    hintThinking = false;
    hadiLine = '';
    _notice = '';
    _recorded = false;
    _startClock();
  }

  void _startClock() {
    _clock?.cancel();
    _clock = null;
    if (minutes <= 0 || (mode != 1 && mode != 2)) return;
    _clock = Timer.periodic(const Duration(seconds: 1), (Timer t) => _tick());
  }

  void _tick() {
    if (!mounted || game.isOver || mode == 0) return;
    setState(() {
      if (game.whiteToMove) {
        whiteMs -= 1000;
      } else {
        blackMs -= 1000;
      }
      final bool white = game.whiteToMove;
      if ((white ? whiteMs : blackMs) <= 0) {
        if (white) {
          whiteMs = 0;
        } else {
          blackMs = 0;
        }
        _token++;
        aiThinking = false;
        game.flag(white: white);
        _onEnded();
      }
    });
  }

  void _saveGame() {
    if (mode != 1 && mode != 2) return;
    final ChessSettingsController c = ref.read(chessSettingsProvider.notifier);
    if (game.isOver || game.moves.isEmpty || !_settings.autoSave) {
      if (game.isOver) c.clearSaved();
      return;
    }
    if (minutes > 0) return; // a clock cannot be paused: not saved
    c.saveGame(
      SavedChess(
        mode: mode,
        level: level.name,
        humanWhite: humanWhite,
        uci: game.toUciList(),
        fen: game.startFen == kStartFen ? null : game.startFen,
      ),
    );
  }

  void _resume(SavedChess s) {
    ChessLevel lv = ChessLevel.intermediate;
    for (final ChessLevel l in ChessLevel.values) {
      if (l.name == s.level) lv = l;
    }
    setState(() {
      _optLevel = lv;
      _optMinutes = 0;
      _begin(
        s.mode,
        resume: ChessGame.fromUciList(s.uci, fen: s.fen),
        asWhite: s.humanWhite,
      );
      _notice = 'Game resumed.';
    });
    _maybeAi();
  }

  void _leave() {
    _token++;
    if (mode == 3 && roomCode != null) {
      unawaited(_roomSub?.cancel());
      _roomSub = null;
      unawaited(_rooms.leave(roomCode!));
      _outbox.clear();
      _syncError = null;
    }
    _clock?.cancel();
    _clock = null;
    setState(() {
      mode = 0;
      roomCode = null;
      aiThinking = false;
      hintThinking = false;
      sel = null;
      targets = <int>{};
      hintFrom = hintTo = null;
      game = ChessGame();
      _notice = '';
      _onlineNote = '';
    });
  }

  // ── Who is who ───────────────────────────────────────────────────────────

  bool get _flipped => switch (mode) {
        1 => !humanWhite,
        3 => mySide != 'host',
        _ => false,
      };

  bool get _isMyTurn {
    if (game.isOver || mode == 0) return false;
    return switch (mode) {
      1 => game.whiteToMove == humanWhite && !aiThinking,
      3 => (mySide == 'host') == game.whiteToMove && _onlineReady,
      _ => true,
    };
  }

  bool get _onlineReady => !_onlineNote.startsWith('Table') && !_opponentLeft;

  // ── Status text ──────────────────────────────────────────────────────────

  String get _winnerName => game.whiteWon == true ? 'White' : 'Black';

  String _sideName(bool white) => white ? 'White' : 'Black';

  String get _status {
    if (mode == 0) return 'Choose your opponent below';
    if (mode == 3 && _onlineNote.isNotEmpty) return _onlineNote;
    if (game.isOver) {
      switch (game.status) {
        case ChessStatus.checkmate:
          if (mode == 1) {
            return game.whiteWon == humanWhite
                ? 'Checkmate. You win. Hadi smiles: beautifully played.'
                : 'Checkmate. Hadi wins this one. Every game teaches '
                    'something.';
          }
          return 'Checkmate. $_winnerName wins.';
        case ChessStatus.stalemate:
          return 'Stalemate. A drawn peace.';
        case ChessStatus.threefold:
          return 'Draw. The same position has come up three times.';
        case ChessStatus.fiftyMove:
          return 'Draw. Fifty moves with no capture and no pawn move.';
        case ChessStatus.insufficient:
          return 'Draw. Neither side has enough pieces left to checkmate.';
        case ChessStatus.resigned:
          return '${_sideName(game.whiteWon != true)} resigned. '
              '$_winnerName wins.';
        case ChessStatus.drawAgreed:
          return 'Draw agreed.';
        case ChessStatus.timeout:
          return game.whiteWon == null
              ? 'Time ran out. A draw, as neither side could checkmate.'
              : '${_sideName(game.whiteWon != true)} ran out of time. '
                  '$_winnerName wins.';
        case ChessStatus.ongoing:
          break;
      }
    }
    if (game.moves.isEmpty && !game.isOver) {
      if (mode == 1) {
        return humanWhite
            ? 'You are White. Hadi takes Black.'
            : 'You are Black. Hadi takes White.';
      }
      if (mode == 2) return 'Two players, one board. White to move.';
    }
    if (mode == 1) {
      if (aiThinking) return 'Hadi is thinking…';
      if (game.inCheck) return 'You are in check.';
      return 'Your move.';
    }
    final String side = _sideName(game.whiteToMove);
    return game.inCheck ? '$side is in check.' : '$side to move.';
  }

  /// What a screen reader announces when the status changes.
  String get _statusSpoken {
    final String last = game.spoken.isEmpty ? '' : '${game.spoken.last}. ';
    return '$last$_status';
  }

  String _outcomeForHistory() {
    switch (game.status) {
      case ChessStatus.checkmate:
        return 'Checkmate: $_winnerName wins';
      case ChessStatus.stalemate:
        return 'Stalemate: a draw';
      case ChessStatus.threefold:
        return 'Draw: threefold repetition';
      case ChessStatus.fiftyMove:
        return 'Draw: fifty-move rule';
      case ChessStatus.insufficient:
        return 'Draw: not enough material';
      case ChessStatus.resigned:
        return '${_sideName(game.whiteWon != true)} resigned: '
            '$_winnerName wins';
      case ChessStatus.drawAgreed:
        return 'Draw: agreed';
      case ChessStatus.timeout:
        return game.whiteWon == null
            ? 'Draw: time ran out'
            : 'Time: $_winnerName wins';
      case ChessStatus.ongoing:
        return 'Unfinished';
    }
  }

  // ── Playing ──────────────────────────────────────────────────────────────

  void _onEnded() {
    _clock?.cancel();
    _clock = null;
    _saveGame();
    if (_recorded || (mode != 1 && mode != 2 && mode != 3)) return;
    _recorded = true;
    final String outcome = _outcomeForHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      recordBoardResult(
        context,
        gameId: 'chess',
        title: 'Shatranj (chess)',
        outcome: outcome,
      );
    });
  }

  void _click() {
    if (_settings.sound) {
      unawaited(SystemSound.play(SystemSoundType.click));
    }
  }

  void _afterMove() {
    sel = null;
    targets = <int>{};
    hintFrom = hintTo = null;
    _notice = '';
    _click();
    if (game.isOver) {
      _onEnded();
    } else {
      _saveGame();
    }
  }

  void _playLocal(int m) {
    if (!game.play(m)) return;
    setState(_afterMove);
    if (mode == 3 && roomCode != null) {
      String? result;
      if (game.status == ChessStatus.checkmate) {
        result = game.whiteWon == true ? 'White wins' : 'Black wins';
      } else if (game.isOver) {
        result = 'Draw';
      }
      final int promo = movePromo(m);
      _queueOnline(
        <String, dynamic>{
          't': 'm',
          'by': mySide,
          'from': squareName(moveFrom(m)),
          'to': squareName(moveTo(m)),
          if (promo != 0) 'p': _promoLetter(promo),
        },
        result: result,
      );
      return;
    }
    _maybeAi();
  }

  String _promoLetter(int promo) => switch (promo) {
        kRook => 'r',
        kBishop => 'b',
        kKnight => 'n',
        _ => 'q',
      };

  int _promoFromLetter(Object? v) => switch (v) {
        'r' => kRook,
        'b' => kBishop,
        'n' => kKnight,
        _ => kQueen,
      };

  void _maybeAi() {
    if (!mounted ||
        mode != 1 ||
        game.isOver ||
        game.whiteToMove == humanWhite ||
        aiThinking) {
      return;
    }
    unawaited(_aiTurn());
  }

  Future<void> _aiTurn() async {
    final int token = ++_token;
    setState(() => aiThinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted || token != _token) return;
    final ChessAi ai = ChessAi(level: level, seed: _seed + game.moves.length);
    final int? m = await ai.chooseMove(
      game.pos,
      isCancelled: () => !mounted || token != _token,
    );
    if (!mounted || token != _token) return;
    setState(() {
      aiThinking = false;
      if (m != null) game.play(m);
      _afterMove();
      if (!game.isOver && m != null) {
        hadiLine = _hadiLineFor(m);
      }
    });
  }

  Future<void> _tap(int i) async {
    if (mode == 0 || !_isMyTurn) return;
    final int piece = game.pos.board[i];
    final bool own = piece != 0 && pieceIsWhite(piece) == game.whiteToMove;
    final int? from = sel;
    if (from == null || own) {
      if (!own) return;
      if (from == i) {
        setState(() {
          sel = null;
          targets = <int>{};
        });
        return;
      }
      final List<int> moves = game.legalFrom(i);
      setState(() {
        sel = i;
        hintFrom = hintTo = null;
        targets = _settings.showLegalMoves
            ? <int>{for (final int m in moves) moveTo(m)}
            : <int>{};
        if (moves.isEmpty) _notice = 'That piece has no legal move.';
      });
      return;
    }
    if (!game.legalFrom(from).any((int m) => moveTo(m) == i)) {
      setState(() => _notice = 'That move is not allowed.');
      return;
    }
    int promo = 0;
    if (game.needsPromotion(from, i)) {
      promo = _settings.autoQueen ? kQueen : await _askPromotion();
      if (promo == 0 || !mounted) return;
    }
    final int? m = game.findMove(from, i, promo: promo);
    if (m != null) _playLocal(m);
  }

  Future<int> _askPromotion() async {
    final int? choice = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.night,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext c) {
        final bool white = game.whiteToMove;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text('Promote your pawn', style: AppText.titleMedium),
                ),
                const SizedBox(height: 4),
                Text('Choose the piece it becomes.', style: AppText.bodyMuted),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    for (final int t in const <int>[
                      kQueen,
                      kRook,
                      kBishop,
                      kKnight,
                    ])
                      _PromoChoice(
                        piece: t | (white ? 0 : kBlackBit),
                        style: _settings.pieces,
                        onTap: () => Navigator.of(c).pop(t),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return choice ?? 0;
  }

  // ── The buttons under the board ──────────────────────────────────────────

  bool get _timed => minutes > 0;

  bool get _canUndoUi {
    if (mode != 1 && mode != 2) return false;
    if (_timed || !game.canUndo) return false;
    if (mode == 1 && !humanWhite && game.moves.length <= 1) return false;
    return true;
  }

  bool get _canRedoUi => (mode == 1 || mode == 2) && !_timed && game.canRedo;

  void _undo() {
    if (!_canUndoUi) return;
    _token++;
    setState(() {
      aiThinking = false;
      hintThinking = false;
      if (mode == 1) {
        do {
          game.undo();
        } while (game.canUndo && game.whiteToMove != humanWhite);
      } else {
        game.undo();
      }
      sel = null;
      targets = <int>{};
      hintFrom = hintTo = null;
      _notice = 'Move taken back.';
      _recorded = false;
    });
    _saveGame();
    _maybeAi();
  }

  void _redo() {
    if (!_canRedoUi) return;
    setState(() {
      if (mode == 1) {
        do {
          game.redo();
        } while (game.canRedo && game.whiteToMove != humanWhite);
      } else {
        game.redo();
      }
      sel = null;
      targets = <int>{};
      hintFrom = hintTo = null;
      _notice = 'Move played again.';
    });
    if (game.isOver) _onEnded();
    _saveGame();
    _maybeAi();
  }

  Future<void> _hint() async {
    if (game.isOver || hintThinking || aiThinking) return;
    if (mode == 1 && !_isMyTurn) return;
    final int token = _token;
    setState(() {
      hintThinking = true;
      _notice = 'Looking for a good move…';
    });
    final int? m = await chessHint(
      game.pos,
      isCancelled: () => !mounted || token != _token,
    );
    if (!mounted || token != _token) return;
    setState(() {
      hintThinking = false;
      if (m == null) {
        _notice = 'There is no legal move.';
        return;
      }
      hintFrom = moveFrom(m);
      hintTo = moveTo(m);
      sel = null;
      targets = <int>{};
      final int p = game.pos.board[moveFrom(m)];
      _notice = 'Hint: ${pieceName(pieceType(p))} from '
          '${squareName(moveFrom(m))} to ${squareName(moveTo(m))}.';
    });
  }

  Future<bool> _confirm(
    String title,
    String body,
    String yes,
    String no,
  ) async {
    final bool? r = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        backgroundColor: AppColors.navy,
        title: Text(title, style: AppText.titleMedium),
        content: Text(body, style: AppText.body),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(no),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(yes),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _offerDraw() async {
    if (game.isOver || (mode != 1 && mode != 2)) return;
    if (mode == 2) {
      final String offerer = _sideName(game.whiteToMove);
      final String other = _sideName(!game.whiteToMove);
      final bool yes = await _confirm(
        '$offerer offers a draw',
        '$other, do you accept? A draw ends the game as a tie.',
        'Accept draw',
        'Decline',
      );
      if (!mounted) return;
      setState(() {
        if (yes) {
          game.agreeDraw();
          _onEnded();
        } else {
          _notice = '$other declined the draw. Play on.';
        }
      });
      return;
    }
    final bool yes = await _confirm(
      'Offer Hadi a draw?',
      'Hadi accepts when the game is balanced and well under way.',
      'Offer draw',
      'Cancel',
    );
    if (!yes || !mounted) return;
    setState(() {
      final bool takes = chessAcceptsDraw(
        game.pos,
        computerIsWhite: !humanWhite,
        plies: game.moves.length,
      );
      if (takes) {
        game.agreeDraw();
        _token++;
        aiThinking = false;
        _onEnded();
      } else {
        _notice = 'Hadi declines the draw. Play on.';
      }
    });
  }

  Future<void> _resign() async {
    if (game.isOver || (mode != 1 && mode != 2)) return;
    final bool white = mode == 1 ? humanWhite : game.whiteToMove;
    if (_settings.confirmResign) {
      final bool yes = await _confirm(
        mode == 1 ? 'Resign this game?' : '${_sideName(white)} resigns?',
        'The game ends and ${_sideName(!white)} wins. You can start a new '
            'game straight away.',
        'Resign',
        'Keep playing',
      );
      if (!yes || !mounted) return;
    }
    setState(() {
      _token++;
      aiThinking = false;
      game.resign(whiteResigns: white);
      _onEnded();
    });
  }

  // ── Online ───────────────────────────────────────────────────────────────

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
        await OnlineLobby.show(context, 'shatranj', _rooms);
    if (r == null || !mounted) return;
    _outbox.clear();
    _syncError = null;
    _opponentLeft = false;
    _seenRoom = false;
    setState(() {
      _begin(3);
      roomCode = r['code'];
      mySide = r['side']!;
      _log = RoomMoves(mySide: mySide);
      _onlineNote = mySide == 'host'
          ? 'Table $roomCode: waiting for your opponent to join…'
          : '';
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

  bool _validSquare(Object? v) =>
      v is String &&
      v.length == 2 &&
      'abcdefgh'.contains(v[0]) &&
      '12345678'.contains(v[1]);

  void _onRoom(DocumentSnapshot<Map<String, dynamic>> snap) {
    final Map<String, dynamic>? data = snap.data();
    if (!mounted) return;
    if (data == null) {
      // The table is gone: the other player left (leaving deletes it).
      if (_seenRoom && !snap.exists && !_opponentLeft && !game.isOver) {
        setState(() {
          _opponentLeft = true;
          _onlineNote = 'Your opponent left the table.';
        });
      }
      return;
    }
    _seenRoom = true;
    final Object? guest = data['guest'];
    if (mySide == 'host' &&
        guest != null &&
        _onlineNote.startsWith('Table') &&
        data['status'] == 'playing') {
      _onlineNote = '';
    }
    for (final Map<String, dynamic> m in _log.incoming(data['moves'])) {
      if (m['t'] != 'm' || !_validSquare(m['from']) || !_validSquare(m['to'])) {
        continue;
      }
      final int? move = game.findMove(
        squareIndex(m['from'] as String),
        squareIndex(m['to'] as String),
        promo: m['p'] == null ? 0 : _promoFromLetter(m['p']),
      );
      if (move == null || !game.play(move)) {
        _syncError = 'A move from your opponent did not fit your board, so '
            'the two boards are out of step. Leave the table and start a '
            'new one.';
        continue;
      }
      sel = null;
      targets = <int>{};
      _click();
    }
    if (game.isOver) _onEnded();
    if (data['status'] == 'left' && !_opponentLeft && !game.isOver) {
      _opponentLeft = true;
      _onlineNote = 'Your opponent left the table.';
    }
    if (mounted) setState(() {});
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool elder = ref.watch(elderModeProvider);
    final ChessSettings settings = ref.watch(chessSettingsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: <Widget>[
          const ScreenHeader(title: 'Shatranj', close: true, showSettings: false),
          Center(
            child: Text(
              'THE CROWN JEWEL · PLAYED FOR FOURTEEN CENTURIES',
              textAlign: TextAlign.center,
              style: AppText.eyebrow,
            ),
          ),
          const SizedBox(height: 12),
          if (mode == 0)
            ..._menu(settings)
          else
            ..._table(settings, elder),
        ],
      ),
    );
  }

  List<Widget> _menu(ChessSettings settings) {
    final SavedChess? saved =
        ref.read(chessSettingsProvider.notifier).loadSaved();
    return <Widget>[
      if (saved != null && settings.autoSave) ...<Widget>[
        _modeButton(
          'Resume your game',
          saved.mode == 1
              ? 'Against Hadi, ${saved.uci.length} moves played'
              : 'Two players, ${saved.uci.length} moves played',
          Icons.restore,
          () => _resume(saved),
        ),
        const SizedBox(height: 10),
      ],
      _modeButton(
        'Play Hadi',
        'The engine wears his voice. A real game, honestly played.',
        Icons.auto_awesome,
        () {
          setState(() => _begin(1));
          _maybeAi();
        },
      ),
      const SizedBox(height: 10),
      _modeButton(
        'Two players',
        'One board, two minds, pass and play.',
        Icons.people_outline,
        () => setState(() => _begin(2)),
      ),
      // A child is never offered the online table: it is a parent's choice.
      if (!kChildMode.value) ...<Widget>[
        const SizedBox(height: 10),
        _modeButton(
          'Play a friend online',
          'Create a table, share the code. Across the street or the ocean.',
          Icons.wifi,
          _onlineSetup,
        ),
      ],
      const SizedBox(height: 10),
      GamePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text('Game options', style: AppText.titleMedium),
            ),
            const SizedBox(height: 10),
            Text('Hadi’s strength', style: AppText.label),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final ChessLevel l in ChessLevel.values)
                  GameChip(
                    label: l.label,
                    selected: _optLevel == l,
                    onTap: () => setState(() => _optLevel = l),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_optLevel.blurb, style: AppText.bodyMuted),
            const SizedBox(height: 12),
            Text('Play as', style: AppText.label),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String a in const <String>[
                  'white',
                  'black',
                  'random',
                ])
                  GameChip(
                    label: '${a[0].toUpperCase()}${a.substring(1)}',
                    selected: _optAs == a,
                    onTap: () => setState(() => _optAs = a),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Clock per player', style: AppText.label),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final int t in const <int>[0, 5, 10, 15, 30])
                  GameChip(
                    label: t == 0 ? 'No clock' : '$t min',
                    selected: _optMinutes == t,
                    onTap: () => setState(() => _optMinutes = t),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'There is no clock unless you choose one. With a clock, undo '
              'and saving a game are off.',
              style: AppText.bodyMuted,
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      _modeButton(
        'Chess settings',
        'Board theme, pieces, sound and more.',
        Icons.tune,
        () => unawaited(showChessSettings(context)),
      ),
      const SizedBox(height: 10),
      GlassCard(
        child: Text(
          'Online tables need an internet connection and a build with the '
          'online hall switched on; if it is unavailable you will be told '
          'when you try. Online games have no undo, hints, clock or draw '
          'offers yet.',
          style: AppText.bodyMuted.copyWith(height: 1.5),
        ),
      ),
    ];
  }

  List<Widget> _table(ChessSettings settings, bool elder) {
    final List<int> board = game.pos.board;
    final int? last = game.moves.isEmpty ? null : game.moves.last;
    final int? checkSq =
        game.inCheck ? game.pos.kingSquare(game.whiteToMove) : null;
    return <Widget>[
      _playerCards(),
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
              child: Semantics(
                liveRegion: true,
                container: true,
                label: _statusSpoken,
                child: ExcludeSemantics(
                  child: Text(
                    _status,
                    style: AppText.body.copyWith(fontSize: 14),
                  ),
                ),
              ),
            ),
            if (aiThinking || hintThinking)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
          ],
        ),
      ),
      if (_notice.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Semantics(
            liveRegion: true,
            child: Text(
              _notice,
              style: AppText.bodyMuted.copyWith(color: AppColors.goldLight),
            ),
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
                  style: TextStyle(color: AppColors.goldLight, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      if (hadiLine.isNotEmpty && mode == 1)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            hadiLine,
            style: AppText.bodyMuted.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      const SizedBox(height: 8),
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ChessBoardView(
            board: board,
            theme: settings.theme,
            pieceStyle: settings.pieces,
            flipped: _flipped,
            selected: sel,
            targets: targets,
            lastFrom: last == null ? null : moveFrom(last),
            lastTo: last == null ? null : moveTo(last),
            checkSquare: checkSq,
            hintFrom: hintFrom,
            hintTo: hintTo,
            onTap: (int i) => unawaited(_tap(i)),
          ),
        ),
      ),
      const SizedBox(height: 10),
      _captured(settings),
      _buttons(elder),
      if (game.isOver) _endPanel(),
      const SizedBox(height: 8),
      _moveList(elder),
    ];
  }

  // ── Pieces of the table ──────────────────────────────────────────────────

  String _clockText(int ms) {
    final int s = max(0, ms) ~/ 1000;
    final String mm = (s ~/ 60).toString().padLeft(2, '0');
    final String ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Widget _playerCards() {
    String nameOf(bool white) {
      if (mode == 1) return white == humanWhite ? 'You' : 'Hadi';
      if (mode == 3) return white == (mySide == 'host') ? 'You' : 'Opponent';
      return white ? 'Player 1' : 'Player 2';
    }

    Widget card(bool white) {
      final bool active = !game.isOver && game.whiteToMove == white;
      final int ms = white ? whiteMs : blackMs;
      final bool isHadi = mode == 1 && white != humanWhite;
      return Expanded(
        child: _PlayerCard(
          name: nameOf(white),
          side: white ? 'White' : 'Black',
          icon: isHadi ? Icons.auto_awesome : Icons.person_outline,
          active: active,
          clock: _timed && mode != 3 ? _clockText(ms) : null,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        card(true),
        const SizedBox(width: 10),
        card(false),
      ],
    );
  }

  static const List<int> _worth = <int>[0, 1, 3, 3, 5, 9, 0];

  Widget _captured(ChessSettings settings) {
    final List<int> byWhite = <int>[];
    final List<int> byBlack = <int>[];
    for (int i = 0; i < game.capturedByPly.length; i++) {
      final int p = game.capturedByPly[i];
      if (p == 0) continue;
      // Ply 0 is White's move: what it takes is Black's piece.
      (i.isEven ? byWhite : byBlack).add(p);
    }
    if (byWhite.isEmpty && byBlack.isEmpty) return const SizedBox.shrink();
    int sum(List<int> l) =>
        l.fold<int>(0, (int a, int p) => a + _worth[pieceType(p)]);
    int rank(int p) => -_worth[pieceType(p)];
    byWhite.sort((int a, int b) => rank(a).compareTo(rank(b)));
    byBlack.sort((int a, int b) => rank(a).compareTo(rank(b)));
    final int diff = sum(byWhite) - sum(byBlack);
    Widget row(String who, List<int> l, int plus) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Semantics(
          label: l.isEmpty
              ? '$who has captured nothing'
              : '$who has captured ${l.map((int p) => pieceName(pieceType(p))).join(', ')}',
          excludeSemantics: true,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 2,
            runSpacing: 2,
            children: <Widget>[
              Text('$who took', style: AppText.bodyMuted),
              const SizedBox(width: 6),
              if (l.isEmpty) Text('nothing yet', style: AppText.bodyMuted),
              for (final int p in l)
                ChessPieceView(piece: p, style: settings.pieces, size: 24),
              if (plus > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    '+$plus',
                    style: AppText.bodyMuted.copyWith(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          row('White', byWhite, diff),
          row('Black', byBlack, -diff),
        ],
      ),
    );
  }

  Widget _buttons(bool elder) {
    final bool local = mode == 1 || mode == 2;
    final bool playing = !game.isOver;
    final bool hintOk = local && playing && (mode == 2 || _isMyTurn);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: <Widget>[
          if (local)
            _RoundAction(
              icon: Icons.undo,
              label: 'Undo',
              big: elder,
              onTap: _canUndoUi ? _undo : null,
            ),
          if (local)
            _RoundAction(
              icon: Icons.redo,
              label: 'Redo',
              big: elder,
              onTap: _canRedoUi ? _redo : null,
            ),
          if (local)
            _RoundAction(
              icon: Icons.lightbulb_outline,
              label: 'Hint',
              big: elder,
              onTap: hintOk && !hintThinking ? () => unawaited(_hint()) : null,
            ),
          if (local)
            _RoundAction(
              icon: Icons.handshake_outlined,
              label: 'Draw',
              big: elder,
              onTap: playing ? () => unawaited(_offerDraw()) : null,
            ),
          if (local)
            _RoundAction(
              icon: Icons.flag_outlined,
              label: 'Resign',
              big: elder,
              onTap: playing ? () => unawaited(_resign()) : null,
            ),
          _RoundAction(
            icon: Icons.settings_outlined,
            label: 'Settings',
            big: elder,
            onTap: () => unawaited(showChessSettings(context)),
          ),
          _RoundAction(
            icon: Icons.logout,
            label: 'Leave',
            big: elder,
            onTap: _leave,
          ),
          // A restart is local only: online it would leave the two boards
          // different, so it is not offered there.
          if (local)
            _RoundAction(
              icon: Icons.refresh,
              label: 'Restart',
              big: elder,
              onTap: () {
                setState(() => _begin(mode));
                _maybeAi();
              },
            ),
        ],
      ),
    );
  }

  Widget _endPanel() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: GamePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text('Game over', style: AppText.titleMedium),
            ),
            const SizedBox(height: 4),
            Text(_status, style: AppText.body),
            if (mode == 1 || mode == 2) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  PlayButton(
                    label: 'Play again',
                    onPressed: () {
                      setState(() => _begin(mode));
                      _maybeAi();
                    },
                  ),
                  OutlineAction(label: 'Back to menu', onPressed: _leave),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _moveList(bool elder) {
    final List<String> san = game.san;
    if (san.isEmpty) return const SizedBox.shrink();
    final List<String> rows = <String>[];
    for (int i = 0; i < san.length; i += 2) {
      final String w = san[i];
      final String b = i + 1 < san.length ? san[i + 1] : '';
      rows.add('${i ~/ 2 + 1}. $w${b.isEmpty ? '' : ' $b'}');
    }
    return GamePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text('Moves', style: AppText.label),
          ),
          const SizedBox(height: 6),
          Semantics(
            label: 'Move list. ${game.spoken.join('. ')}',
            excludeSemantics: true,
            child: Wrap(
              spacing: 14,
              runSpacing: 4,
              children: <Widget>[
                for (final String r in rows)
                  Text(
                    r,
                    style: AppText.body.copyWith(
                      fontSize: elder ? 16 : 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(
    String title,
    String sub,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: AppColors.goldLight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                Text(sub, style: AppText.bodyMuted),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gold),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.name,
    required this.side,
    required this.icon,
    required this.active,
    required this.clock,
  });

  final String name;
  final String side;
  final IconData icon;
  final bool active;

  /// 'mm:ss' for a timed game, null for no clock.
  final String? clock;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$name, $side${clock == null ? '' : ', clock $clock'}'
          '${active ? ', to move' : ''}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: GamesTheme.panelFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? GamesTheme.borderBright : GamesTheme.border,
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: side == 'White'
                    ? const LinearGradient(
                        colors: <Color>[Color(0xFFFBF3DC), Color(0xFFD9C89A)],
                      )
                    : const LinearGradient(
                        colors: <Color>[Color(0xFF3A3322), Color(0xFF0D0B06)],
                      ),
                border: Border.all(color: AppColors.gold),
              ),
              child: Icon(
                icon,
                size: 22,
                color: side == 'White' ? AppColors.night : AppColors.goldLight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (clock != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        clock!,
                        style: AppText.titleMedium.copyWith(
                          color: AppColors.goldLight,
                        ),
                      ),
                    )
                  else
                    Text(side, style: AppText.bodyMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.big,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final bool on = onTap != null;
    final double d = big ? 64 : 54;
    return Semantics(
      button: true,
      enabled: on,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: big ? 84 : 72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Material(
              type: MaterialType.transparency,
              child: FocusRing(borderRadius: 12, child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: on ? 0.9 : 0.3),
                      width: 1.4,
                    ),
                    color: AppColors.night.withValues(alpha: 0.6),
                  ),
                  child: Icon(
                    icon,
                    size: big ? 30 : 26,
                    color: on
                        ? AppColors.goldLight
                        : AppColors.goldLight.withValues(alpha: 0.35),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.bodyMuted.copyWith(
                color: on ? AppColors.sand : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoChoice extends StatelessWidget {
  const _PromoChoice({
    required this.piece,
    required this.style,
    required this.onTap,
  });

  final int piece;
  final ChessPieceStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String name = pieceName(pieceType(piece));
    final String label = '${name[0].toUpperCase()}${name.substring(1)}';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: FocusRing(borderRadius: 14, child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 78,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GamesTheme.border),
            color: GamesTheme.panelFill,
          ),
          child: Column(
            children: <Widget>[
              ChessPieceView(piece: piece, style: style, size: 52),
              const SizedBox(height: 4),
              Text(label, style: AppText.bodyMuted),
            ],
          ),
        ),
      )),
    );
  }
}
