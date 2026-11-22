import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide Text;
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../engine/board_engines.dart';
import '../ui/games_theme.dart';
import 'puzzle_games.dart';

/// How the player wants to play a two-sided board game on this device.
class _Mode {
  const _Mode(this.vsComputer, this.level);
  final bool vsComputer;
  final int level; // 1 easy, 3 medium, 5 hard
}

/// The first page of a board game: against the computer (with a level), or
/// two people on one device.
class _ModePicker extends StatelessWidget {
  const _ModePicker({
    required this.title,
    required this.tagline,
    required this.onPick,
  });

  final String title;
  final String tagline;
  final ValueChanged<_Mode> onPick;

  @override
  Widget build(BuildContext context) {
    return PuzzleFrame(
      title: title,
      tagline: tagline,
      children: <Widget>[
        Text('HOW DO YOU WANT TO PLAY?', style: AppText.eyebrow),
        const SizedBox(height: 10),
        for (final (String, String, _Mode) o in <(String, String, _Mode)>[
          ('Against the computer · Easy', 'A gentle opponent', const _Mode(true, 1)),
          ('Against the computer · Medium', 'Thinks a few moves ahead', const _Mode(true, 3)),
          ('Against the computer · Hard', 'Thinks further ahead', const _Mode(true, 5)),
          ('Two players, one device', 'Pass the device between turns', const _Mode(false, 3)),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GamePanel(
              onTap: () => onPick(o.$3),
              semanticsLabel: '${o.$1}. ${o.$2}',
              child: Row(children: <Widget>[
                const Icon(Icons.sports_esports_outlined,
                    color: AppColors.goldLight),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(o.$1, style: AppText.body),
                      Text(o.$2, style: AppText.bodyMuted),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.goldLight),
              ]),
            ),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------- Four in a Row

class ConnectFourScreen extends StatefulWidget {
  const ConnectFourScreen({super.key});

  @override
  State<ConnectFourScreen> createState() => _ConnectFourState();
}

class _ConnectFourState extends State<ConnectFourScreen> {
  _Mode? _mode;
  ConnectFour _g = ConnectFour();
  final Random _rnd = Random();
  Timer? _timer;
  bool _thinking = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _myTurn => _mode == null || !_mode!.vsComputer || _g.turn == 1;

  void _drop(int c) {
    if (_g.winner != 0 || _thinking || !_myTurn) return;
    if (_g.drop(c) < 0) return;
    setState(() {});
    _maybeComputer();
  }

  void _maybeComputer() {
    final _Mode m = _mode!;
    if (!m.vsComputer || _g.winner != 0 || _g.isFull || _g.turn != 2) return;
    setState(() => _thinking = true);
    _timer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final int c = _g.computerMove(_rnd, depth: m.level);
      if (c >= 0) _g.drop(c);
      setState(() => _thinking = false);
    });
  }

  String get _status {
    if (_g.winner != 0) {
      if (_mode!.vsComputer) return _g.winner == 1 ? 'You win' : 'The computer wins';
      return 'Player ${_g.winner} wins';
    }
    if (_g.isFull) return 'A draw';
    if (_mode!.vsComputer) return _g.turn == 1 ? 'Your turn' : 'The computer is thinking…';
    return 'Player ${_g.turn}, your turn';
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == null) {
      return _ModePicker(
        title: 'Four in a Row',
        tagline: 'Strategy. Patience. A clear mind.',
        onPick: (_Mode m) => setState(() => _mode = m),
      );
    }
    final bool over = _g.winner != 0 || _g.isFull;
    return PuzzleFrame(
      title: 'Four in a Row',
      tagline: 'Strategy. Patience. A clear mind.',
      children: <Widget>[
        Semantics(
          liveRegion: true,
          child: Text(_status.toUpperCase(), style: AppText.eyebrow),
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: ConnectFour.cols / ConnectFour.rows,
          child: LayoutBuilder(builder: (BuildContext _, BoxConstraints bc) {
            final double cell = bc.maxWidth / ConnectFour.cols;
            return Stack(children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xCC010F16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: GamesTheme.border, width: 1.6),
                  ),
                ),
              ),
              for (int c = 0; c < ConnectFour.cols; c++)
                Positioned(
                  left: c * cell,
                  top: 0,
                  width: cell,
                  height: bc.maxHeight,
                  child: Semantics(
                    button: true,
                    label: 'Drop in column ${c + 1}'
                        '${_g.canDrop(c) ? '' : ', full'}',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _drop(c),
                      child: ExcludeSemantics(
                        child: Column(children: <Widget>[
                          for (int r = 0; r < ConnectFour.rows; r++)
                            SizedBox(
                              height: bc.maxHeight / ConnectFour.rows,
                              child: Center(
                                child: Container(
                                  width: cell * 0.78,
                                  height: cell * 0.78,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _g.at(r, c) == 0
                                        ? const Color(0xFF05090F)
                                        : (_g.at(r, c) == 1
                                            ? const Color(0xFFE2A63F)
                                            : const Color(0xFFF6EBCB)),
                                    border: Border.all(
                                      color: _g.line.contains(r * 7 + c)
                                          ? Colors.white
                                          : GamesTheme.border,
                                      width: _g.line.contains(r * 7 + c) ? 3 : 1,
                                    ),
                                  ),
                                  child: _g.at(r, c) == 0
                                      ? null
                                      : Center(
                                          child: Text(
                                              _g.at(r, c) == 1 ? 'G' : 'C',
                                              style: const TextStyle(
                                                  color: Color(0xFF3A2A06),
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                ),
                              ),
                            ),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]);
          }),
        ),
        const SizedBox(height: 10),
        Text('Gold (G) goes first, cream (C) second. Tap a column to drop a token. Four in a line wins.',
            textAlign: TextAlign.center, style: AppText.bodyMuted),
        const SizedBox(height: 10),
        if (over)
          PlayButton(
            label: 'Play again',
            onPressed: () => setState(() {
              _g = ConnectFour();
              _thinking = false;
            }),
          ),
        const SizedBox(height: 8),
        OutlineAction(
          label: 'Back to Games',
          onPressed: () => context.go(AppRoutes.games),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- Draughts

class DraughtsScreen extends StatefulWidget {
  const DraughtsScreen({super.key});

  @override
  State<DraughtsScreen> createState() => _DraughtsState();
}

class _DraughtsState extends State<DraughtsScreen> {
  _Mode? _mode;
  Draughts _g = Draughts();
  final Random _rnd = Random();
  Timer? _timer;
  int? _sel;
  bool _thinking = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<List<int>> get _moves => _g.moves();

  void _tap(int i) {
    if (_g.winner != 0 || _thinking) return;
    if (_mode!.vsComputer && _g.turn != 1) return;
    final int? s = _sel;
    if (s != null) {
      // A move that starts at s and whose next stop is i.
      final List<List<int>> hits = <List<int>>[
        for (final List<int> m in _moves)
          if (m.first == s && m[1] == i) m,
      ];
      if (hits.isNotEmpty) {
        // A capture that can end in different places is played to its end.
        _g.play(hits.first);
        setState(() => _sel = null);
        _maybeComputer();
        return;
      }
    }
    final bool mine = Draughts.side(_g.board[i]) == _g.turn &&
        _moves.any((List<int> m) => m.first == i);
    setState(() => _sel = mine ? i : null);
  }

  void _maybeComputer() {
    final _Mode m = _mode!;
    if (!m.vsComputer || _g.winner != 0 || _g.turn != 2) return;
    setState(() => _thinking = true);
    _timer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final List<int>? mv = _g.computerMove(_rnd, depth: m.level);
      if (mv != null) _g.play(mv);
      setState(() => _thinking = false);
    });
  }

  String get _status {
    final int w = _g.winner;
    if (w != 0) {
      if (_mode!.vsComputer) return w == 1 ? 'You win' : 'The computer wins';
      return 'Player $w wins';
    }
    final bool mustCapture =
        _moves.isNotEmpty && (_moves.first.first ~/ 8 - _moves.first[1] ~/ 8).abs() == 2;
    final String who = _mode!.vsComputer
        ? (_g.turn == 1 ? 'Your turn' : 'The computer is thinking…')
        : 'Player ${_g.turn}, your turn';
    return mustCapture ? '$who · you must capture' : who;
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == null) {
      return _ModePicker(
        title: 'Checkers',
        tagline: 'A classic game for focus, strategy and patience.',
        onPick: (_Mode m) => setState(() => _mode = m),
      );
    }
    final Set<int> targets = <int>{
      if (_sel != null)
        for (final List<int> m in _moves)
          if (m.first == _sel) m[1],
    };
    final bool over = _g.winner != 0;
    return PuzzleFrame(
      title: 'Checkers',
      tagline: 'A classic game for focus, strategy and patience.',
      children: <Widget>[
        Semantics(
          liveRegion: true,
          child: Text(_status.toUpperCase(), style: AppText.eyebrow),
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.count(
            crossAxisCount: 8,
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              for (int i = 0; i < 64; i++)
                Semantics(
                  button: true,
                  selected: _sel == i,
                  label: 'Row ${i ~/ 8 + 1}, column ${i % 8 + 1}, '
                      '${_pieceName(_g.board[i])}'
                      '${targets.contains(i) ? ', you can move here' : ''}',
                  child: GestureDetector(
                    onTap: () => _tap(i),
                    child: ExcludeSemantics(
                      child: Container(
                        decoration: BoxDecoration(
                          color: (i ~/ 8 + i % 8).isOdd
                              ? const Color(0xFF1B2A44)
                              : const Color(0xFFEAD6B4),
                          border: _sel == i
                              ? Border.all(color: AppColors.goldLight, width: 3)
                              : (targets.contains(i)
                                  ? Border.all(color: const Color(0xFF7FD1A8), width: 3)
                                  : null),
                        ),
                        child: _g.board[i] == 0
                            ? null
                            : Center(
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Draughts.side(_g.board[i]) == 1
                                        ? const Color(0xFFF6EBCB)
                                        : const Color(0xFF05090F),
                                    border: Border.all(
                                        color: AppColors.gold, width: 2),
                                  ),
                                  child: Draughts.isKing(_g.board[i])
                                      ? Icon(Icons.workspace_premium,
                                          size: 18,
                                          color: Draughts.side(_g.board[i]) == 1
                                              ? const Color(0xFF3A2A06)
                                              : AppColors.goldLight)
                                      : null,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text('Cream: ${_g.count(1)}   ·   Dark: ${_g.count(2)}',
              style: AppText.bodyMuted),
        ]),
        const SizedBox(height: 6),
        Text('Tap a piece, then a green square. A capture is compulsory. Reach the far row to be crowned.',
            textAlign: TextAlign.center, style: AppText.bodyMuted),
        const SizedBox(height: 10),
        if (over)
          PlayButton(
            label: 'Play again',
            onPressed: () => setState(() {
              _g = Draughts();
              _sel = null;
              _thinking = false;
            }),
          ),
        const SizedBox(height: 8),
        OutlineAction(
          label: 'Back to Games',
          onPressed: () => context.go(AppRoutes.games),
        ),
      ],
    );
  }

  static String _pieceName(int p) => switch (p) {
        0 => 'empty',
        1 => 'cream man',
        2 => 'dark man',
        3 => 'cream king',
        _ => 'dark king',
      };
}
