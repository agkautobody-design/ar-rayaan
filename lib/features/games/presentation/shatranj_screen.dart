import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/screen_header.dart';
import 'chess_pieces.dart';
import '../data/game_rooms_service.dart';
import 'online_lobby.dart';

/// SHATRANJ — the crown jewel. A complete chess engine (legal moves, king
/// safety, alpha-beta search) beneath an immersive golden board.
/// v1 rules: standard movement, auto-queen promotion; castling and en
/// passant arrive in v2. Play Hadi (the engine, with his voice) or a friend
/// beside you. Online rooms arrive with the family cloud.
class ShatranjScreen extends StatefulWidget {
  const ShatranjScreen({super.key});

  @override
  State<ShatranjScreen> createState() => _ShatranjState();
}

class _ShatranjState extends State<ShatranjScreen> {
  late List<String> b;
  bool whiteToMove = true;
  int? sel;
  List<List<int>> legalSel = [];
  final List<String> moveLog = [];
  final List<String> captured = [];
  String status = 'Choose your opponent below';
  int mode = 0; // 0 = menu, 1 = vs Hadi, 2 = two players
  final _rnd = Random();
  bool aiThinking = false;
  String hadiLine = '';
  final _rooms = GameRoomsService();
  String? roomCode;
  String mySide = 'host';
  int appliedMoves = 0;
  Stream<dynamic>? _roomStream;

  static const _hadiLines = [
    'Hadi studies the board the way he studies a hadith — patiently.',
    'Hadi: Every opening is a doorway. Choose yours well.',
    'Hadi: The middle game rewards the patient heart.',
    'Hadi: A sacrifice given for position is sadaqah on the board.',
    'Hadi: I would rather lose beautifully than win without principle.',
    'Hadi: Your move carries intention — make it a good one.',
    'Hadi: Even the queen bows to the plan, not the power.',
  ];

  static const _glyph = {
    'K': '\u2654', 'Q': '\u2655', 'R': '\u2656', 'B': '\u2657',
    'N': '\u2658', 'P': '\u2659',
    'k': '\u265A', 'q': '\u265B', 'r': '\u265C', 'b': '\u265D',
    'n': '\u265E', 'p': '\u265F',
  };

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    const back = 'RNBQKBNR';
    b = List.generate(64, (i) {
      if (i < 8) return back[i].toLowerCase();
      if (i < 16) return 'p';
      if (i >= 56) return back[i - 56];
      if (i >= 48) return 'P';
      return '';
    });
    whiteToMove = true;
    sel = null;
    legalSel = [];
    moveLog.clear();
    captured.clear();
    status = mode == 1
        ? 'You are White — Hadi takes Black'
        : mode == 2
            ? 'Two players, one board'
            : 'Choose your opponent below';
    hadiLine = '';
  }

  bool _isWhite(String p) => p.isNotEmpty && p == p.toUpperCase();

  List<int> _attacksOnKing(List<String> board, bool whiteKing) {
    final k = whiteKing ? 'K' : 'k';
    final kp = board.indexOf(k);
    final out = <int>[];
    for (var i = 0; i < 64; i++) {
      final p = board[i];
      if (p.isEmpty) continue;
      if (_isWhite(p) == whiteKing) continue;
      for (final t in _pseudo(board, i)) {
        if (t == kp) out.add(i);
      }
    }
    return out;
  }

  List<int> _pseudo(List<String> board, int from) {
    final p = board[from];
    if (p.isEmpty) return [];
    final out = <int>[];
    final frow = from ~/ 8, fcol = from % 8;
    final white = _isWhite(p);
    void add(int r, int c) {
      if (r < 0 || r > 7 || c < 0 || c > 7) return;
      final t = r * 8 + c;
      if (board[t].isEmpty || _isWhite(board[t]) != white) out.add(t);
    }

    switch (p.toUpperCase()) {
      case 'P':
        final dir = white ? -1 : 1;
        final startRow = white ? 6 : 1;
        if (frow + dir >= 0 && frow + dir < 8) {
          if (board[(frow + dir) * 8 + fcol].isEmpty) {
            out.add((frow + dir) * 8 + fcol);
            if (frow == startRow &&
                board[(frow + 2 * dir) * 8 + fcol].isEmpty) {
              out.add((frow + 2 * dir) * 8 + fcol);
            }
          }
          for (final dc in [-1, 1]) {
            final c = fcol + dc;
            if (c >= 0 && c < 8) {
              final t = (frow + dir) * 8 + c;
              if (board[t].isNotEmpty && _isWhite(board[t]) != white) out.add(t);
            }
          }
        }
      case 'N':
        for (final d in [
          [-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]
        ]) {
          add(frow + d[0], fcol + d[1]);
        }
      case 'B':
        _slide(board, from, out, [
          [-1, -1], [-1, 1], [1, -1], [1, 1]
        ]);
      case 'R':
        _slide(board, from, out, [
          [-1, 0], [1, 0], [0, -1], [0, 1]
        ]);
      case 'Q':
        _slide(board, from, out, [
          [-1, -1], [-1, 1], [1, -1], [1, 1], [-1, 0], [1, 0], [0, -1], [0, 1]
        ]);
      case 'K':
        for (var dr = -1; dr <= 1; dr++) {
          for (var dc = -1; dc <= 1; dc++) {
            if (dr == 0 && dc == 0) continue;
            add(frow + dr, fcol + dc);
          }
        }
    }
    return out;
  }

  void _slide(List<String> board, int from, List<int> out, List<List<int>> dirs) {
    final white = _isWhite(board[from]);
    final frow = from ~/ 8, fcol = from % 8;
    for (final d in dirs) {
      var r = frow + d[0], c = fcol + d[1];
      while (r >= 0 && r < 8 && c >= 0 && c < 8) {
        final t = r * 8 + c;
        if (board[t].isEmpty) {
          out.add(t);
        } else {
          if (_isWhite(board[t]) != white) out.add(t);
          break;
        }
        r += d[0];
        c += d[1];
      }
    }
  }

  List<int> _legal(List<String> board, int from) {
    final white = _isWhite(board[from]);
    final out = <int>[];
    for (final t in _pseudo(board, from)) {
      final copy = List<String>.from(board);
      copy[t] = copy[from];
      copy[from] = '';
      if (copy[t] == 'P' && t ~/ 8 == 0) copy[t] = 'Q';
      if (copy[t] == 'p' && t ~/ 8 == 7) copy[t] = 'q';
      if (_attacksOnKing(copy, white).isEmpty) out.add(t);
    }
    return out;
  }

  double _eval(List<String> board) {
    const v = {'P': 100, 'N': 320, 'B': 330, 'R': 500, 'Q': 900, 'K': 0};
    var s = 0.0;
    for (var i = 0; i < 64; i++) {
      final p = board[i];
      if (p.isEmpty) continue;
      var val = v[p.toUpperCase()]!.toDouble();
      val += (3.5 - (i ~/ 8 - 3.5).abs()) + (3.5 - (i % 8 - 3.5).abs());
      s += _isWhite(p) ? val : -val;
    }
    return s;
  }

  double _search(List<String> board, int depth, double alpha, double beta,
      bool maximizingWhite) {
    if (depth == 0) return _eval(board);
    final moves = <List<int>>[];
    for (var i = 0; i < 64; i++) {
      if (board[i].isEmpty || _isWhite(board[i]) != maximizingWhite) continue;
      for (final t in _legal(board, i)) {
        moves.add([i, t]);
      }
    }
    if (moves.isEmpty) {
      final inCheck =
          _attacksOnKing(board, maximizingWhite).isNotEmpty;
      return inCheck ? (maximizingWhite ? -99999.0 : 99999.0) : 0.0;
    }
    if (maximizingWhite) {
      var best = -1e9;
      for (final m in moves) {
        final copy = List<String>.from(board);
        _applyOn(copy, m[0], m[1]);
        best = max(best, _search(copy, depth - 1, alpha, beta, false));
        alpha = max(alpha, best);
        if (beta <= alpha) break;
      }
      return best;
    } else {
      var best = 1e9;
      for (final m in moves) {
        final copy = List<String>.from(board);
        _applyOn(copy, m[0], m[1]);
        best = min(best, _search(copy, depth - 1, alpha, beta, true));
        beta = min(beta, best);
        if (beta <= alpha) break;
      }
      return best;
    }
  }

  void _applyOn(List<String> board, int from, int to) {
    board[to] = board[from];
    board[from] = '';
    if (board[to] == 'P' && to ~/ 8 == 0) board[to] = 'Q';
    if (board[to] == 'p' && to ~/ 8 == 7) board[to] = 'q';
  }

  void _aiMove() async {
    setState(() => aiThinking = true);
    await Future.delayed(const Duration(milliseconds: 350));
    final moves = <List<int>>[];
    for (var i = 0; i < 64; i++) {
      if (b[i].isEmpty || _isWhite(b[i])) continue;
      for (final t in _legal(b, i)) {
        moves.add([i, t]);
      }
    }
    if (moves.isEmpty) {
      setState(() {
        aiThinking = false;
        status = _attacksOnKing(b, false).isNotEmpty
            ? 'Checkmate — you win. Hadi smiles: beautifully played.'
            : 'Stalemate — a drawn peace.';
      });
      return;
    }
    List<int>? best;
    var bestScore = 1e9;
    moves.shuffle(_rnd);
    for (final m in moves) {
      final copy = List<String>.from(b);
      _applyOn(copy, m[0], m[1]);
      final s = _search(copy, 2, -1e9, 1e9, true);
      if (s < bestScore) {
        bestScore = s;
        best = m;
      }
    }
    _commit(best![0], best[1]);
    setState(() {
      aiThinking = false;
      hadiLine = _hadiLines[_rnd.nextInt(_hadiLines.length)];
    });
  }

  void _commit(int from, int to) {
    final piece = b[from];
    if (b[to].isNotEmpty) captured.add(b[to]);
    _applyOn(b, from, to);
    moveLog.add('${_sq(from)}${_sq(to)}');
    whiteToMove = !whiteToMove;
    sel = null;
    legalSel = [];
    final inCheck = _attacksOnKing(b, whiteToMove).isNotEmpty;
    final anyMoves = _anyLegal(whiteToMove);
    if (!anyMoves) {
      status = inCheck
          ? 'Checkmate — ${whiteToMove ? 'Black' : 'White'} wins'
          : 'Stalemate — a drawn peace';
    } else if (inCheck) {
      status = '${whiteToMove ? 'White' : 'Black'} is in check';
    } else {
      status = whiteToMove ? 'White to move' : 'Black to move';
    }
  }

  bool _anyLegal(bool white) {
    for (var i = 0; i < 64; i++) {
      if (b[i].isEmpty || _isWhite(b[i]) != white) continue;
      if (_legal(b, i).isNotEmpty) return true;
    }
    return false;
  }

  String _sq(int i) =>
      '${'abcdefgh'[i % 8]}${8 - (i ~/ 8)}';

  void _tap(int i) {
    if (mode == 0 || aiThinking) return;
    if (status.startsWith('Checkmate') || status.startsWith('Stalemate')) return;
    if (mode == 1 && !whiteToMove) return;
    if (mode == 3 && !_isMyTurnOnline) return;
    final white = _isWhite(b[i]);
    if (sel == null) {
      if (b[i].isNotEmpty && white == whiteToMove) {
        setState(() {
          sel = i;
          legalSel = _legal(b, i).map((t) => [i, t]).toList();
        });
      }
      return;
    }
    if (b[i].isNotEmpty && white == whiteToMove) {
      setState(() {
        sel = i;
        legalSel = _legal(b, i).map((t) => [i, t]).toList();
      });
      return;
    }
    final ok = legalSel.any((m) => m[1] == i);
    if (!ok) return;
    final from = sel!;
    _commit(from, i);
    setState(() {});
    if (mode == 3) {
      _rooms.sendMove(roomCode!, {
        't': 'm', 'from': _sq(from), 'to': _sq(i),
      });
      if (status.startsWith('Checkmate')) {
        _rooms.finish(roomCode!, mySide == 'host' ? 'White wins' : 'Black wins');
      } else if (status.startsWith('Stalemate')) {
        _rooms.finish(roomCode!, 'Draw');
      }
      return;
    }
    if (mode == 1 && !status.startsWith('Checkmate') && !status.startsWith('Stalemate')) {
      _aiMove();
    }
  }

  int _sqToIdx(String sq) =>
      (8 - int.parse(sq[1])) * 8 + 'abcdefgh'.indexOf(sq[0]);

  Future<void> _onlineSetup() async {
    final r = await OnlineLobby.show(context, 'shatranj', _rooms);
    if (r == null || !mounted) return;
    setState(() {
      mode = 3;
      roomCode = r['code'];
      mySide = r['side']!;
      _reset();
      appliedMoves = 0;
      status = mySide == 'host'
          ? 'Table \${roomCode} — waiting for your opponent to join\u2026'
          : 'Joined table \${roomCode} — you are Black';
    });
    _roomStream = _rooms.watch(roomCode!);
    _roomStream!.listen((snap) {
      final data = (snap as dynamic).data() as Map<String, dynamic>?;
      if (data == null || !mounted) return;
      final moves = (data['moves'] as List<dynamic>? ?? []);
      final guest = data['guest'] as Map<String, dynamic>?;
      if (mySide == 'host' && guest != null &&
          status.startsWith('Table') && data['status'] == 'playing') {
        setState(() => status = 'White to move');
      }
      while (appliedMoves < moves.length) {
        final m = Map<String, dynamic>.from(moves[appliedMoves] as Map);
        appliedMoves++;
        if (m['t'] == 'm') {
          _commit(_sqToIdx(m['from'] as String), _sqToIdx(m['to'] as String));
        }
      }
      if (mounted) setState(() {});
    });
  }

  bool get _isMyTurnOnline =>
      mode != 3 || (mySide == 'host') == whiteToMove;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const ScreenHeader(title: 'Shatranj', close: true),
          Center(child: Text('THE CROWN JEWEL \u00b7 PLAYED FOR FOURTEEN CENTURIES', style: AppText.eyebrow)),
          const SizedBox(height: 12),
          if (mode == 0)
            Column(children: [
              _modeButton('Play Hadi', 'The engine wears his voice — a real game, honestly played',
                  Icons.auto_awesome, () => setState(() { mode = 1; _reset(); })),
              const SizedBox(height: 10),
              _modeButton('Two players', 'One board, two minds, pass and play',
                  Icons.people_outline, () => setState(() { mode = 2; _reset(); })),
              const SizedBox(height: 10),
              _modeButton('Play a friend online', 'Create a table, share the code — across the street or the ocean',
                  Icons.wifi, _onlineSetup),
              const SizedBox(height: 10),
              GlassCard(child: Text(
                'Online rooms — play a friend across the city or the ocean — arrive with the family cloud, in shaa Allah. Castling and en passant follow in v2.',
                style: AppText.bodyMuted.copyWith(height: 1.5))),
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
                if (aiThinking)
                  const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
                TextButton(
                  onPressed: () {
                    if (mode == 3 && roomCode != null) _rooms.leave(roomCode!);
                    setState(() { mode = 0; roomCode = null; _reset(); });
                  },
                  child: const Text('Leave', style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => setState(() => _reset()),
                  child: const Text('Restart', style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
                ),
              ]),
            ),
            if (hadiLine.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(hadiLine, style: AppText.bodyMuted.copyWith(fontStyle: FontStyle.italic, fontSize: 12)),
              ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 24, offset: const Offset(0, 14)),
                  BoxShadow(color: AppColors.gold.withValues(alpha: 0.10), blurRadius: 42, spreadRadius: 2),
                ],
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1.4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    for (var r = 0; r < 8; r++)
                      Row(children: [
                        for (var c = 0; c < 8; c++)
                          Expanded(child: _square(r * 8 + c)),
                      ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (captured.isNotEmpty)
              SizedBox(
              height: 20,
              child: ListView(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                children: [
                  for (final p in captured)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: CustomPaint(
                        painter: ChessPiecePainter(p),
                        size: const Size.square(18),
                      ),
                    ),
                ],
              ),
            ),
            if (moveLog.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  moveLog.length <= 10
                      ? moveLog.join('  \u00b7  ')
                      : moveLog.sublist(moveLog.length - 10).join('  \u00b7  '),
                  style: AppText.bodyMuted.copyWith(fontSize: 11),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _modeButton(String title, String sub, IconData icon, VoidCallback onTap) {
    return GlassCard(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, color: AppColors.goldLight, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 14.5)),
          Text(sub, style: AppText.bodyMuted.copyWith(fontSize: 11.5)),
        ])),
        const Icon(Icons.chevron_right, color: AppColors.gold),
      ]),
    );
  }

  Widget _square(int i) {
    final row = i ~/ 8, col = i % 8;
    final light = (row + col) % 2 == 0;
    final isSel = sel == i;
    final isLegal = legalSel.any((m) => m[1] == i);
    final piece = b[i];
    final inCheckSq = piece.isNotEmpty &&
        ((piece == 'K' && _attacksOnKing(b, true).isNotEmpty) ||
            (piece == 'k' && _attacksOnKing(b, false).isNotEmpty));

    return GestureDetector(
      onTap: () => _tap(i),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSel
                  ? [const Color(0xFF6B5518), const Color(0xFF8C6D1F)]
                  : light
                      ? [const Color(0xFFEBD9A9), const Color(0xFFDCC488)]
                      : [const Color(0xFF8A6A2F), const Color(0xFF6E5223)],
            ),
            boxShadow: isLegal
                ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.8), blurRadius: 8)]
                : null,
            border: Border.all(
              color: isSel
                  ? AppColors.gold
                  : isLegal
                      ? AppColors.gold.withValues(alpha: 0.7)
                      : inCheckSq
                          ? Colors.redAccent
                          : Colors.transparent,
              width: isSel || isLegal || inCheckSq ? 1.6 : 0.4,
            ),
          ),
          child: Center(
            child: piece.isEmpty
                ? (isLegal
                    ? Container(width: 10, height: 10,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: AppColors.gold.withValues(alpha: 0.85)))
                    : const SizedBox.shrink())
                : Padding(
                    padding: const EdgeInsets.all(3),
                    child: CustomPaint(
                      painter: ChessPiecePainter(piece),
                      size: const Size.square(40),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
