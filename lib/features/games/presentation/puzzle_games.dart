import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../data/race_link.dart';
import '../engine/maze_boards.dart';
import '../engine/puzzle_engines.dart';
import '../ui/games_theme.dart';
import 'race_banner.dart';

/// The race plumbing every puzzle shares. Both friends get the same puzzle
/// (one seed) and see each other's progress; with no race code this does
/// nothing, so the game is the same alone.
class PuzzleRace {
  PuzzleRace(String? code, String? side, this.seed) {
    if (code != null && side != null) {
      link = RaceLink(code: code, side: side, startN: side == 'host' ? 1 : 0)
        ..listen();
    }
  }

  final int? seed;
  RaceLink? link;
  bool finished = false;

  /// A random source: the shared seed in a race, otherwise a fresh one.
  Random get rnd => seed != null ? Random(seed) : Random();

  void report(int done, int total, int score) {
    unawaited(link?.report(done, total, score) ?? Future<void>.value());
  }

  void finish(int total, int score) {
    finished = true;
    unawaited(link?.finish(total, score) ?? Future<void>.value());
  }

  void dispose() {
    final RaceLink? r = link;
    if (r == null) return;
    if (!finished || r.state.value.opponent.finished) {
      unawaited(r.leave());
    }
    r.dispose();
  }
}

/// The page every puzzle sits in: header, race banner, then [children].
class PuzzleFrame extends StatelessWidget {
  const PuzzleFrame({
    required this.title,
    required this.children,
    this.tagline,
    this.race,
    this.myScore = 0,
    this.myTotal = 1,
    this.iFinished = false,
    super.key,
  });

  final String title;
  final String? tagline;
  final List<Widget> children;
  final PuzzleRace? race;
  final int myScore;
  final int myTotal;
  final bool iFinished;

  @override
  Widget build(BuildContext context) {
    final RaceLink? link = race?.link;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: <Widget>[
          ArchHeader(title: title, tagline: tagline, close: true, band: true),
          if (link != null)
            RaceBanner(
              link: link,
              myScore: myScore,
              myTotal: myTotal,
              iFinished: iFinished,
            ),
          ...children,
        ],
      ),
    );
  }
}

/// The end card of a puzzle.
Widget puzzleDone(
  BuildContext context, {
  required String headline,
  required String detail,
}) {
  return Column(children: <Widget>[
    GamePanel(
      child: Column(children: <Widget>[
        Text(headline, style: AppText.titleMedium),
        const SizedBox(height: 6),
        Text(detail,
            textAlign: TextAlign.center,
            style: AppText.bodyMuted.copyWith(height: 1.5)),
      ]),
    ),
    const SizedBox(height: 12),
    PlayButton(label: 'Back to Games', onPressed: () => context.go(AppRoutes.games)),
  ]);
}

Widget _pad(Widget w, [double b = 10]) =>
    Padding(padding: EdgeInsets.only(bottom: b), child: w);

// ------------------------------------------------------------------ Maze

class MazeScreen extends StatefulWidget {
  const MazeScreen({super.key, this.raceCode, this.raceSide, this.seed});
  final String? raceCode;
  final String? raceSide;
  final int? seed;

  @override
  State<MazeScreen> createState() => _MazeState();
}

class _MazeState extends State<MazeScreen> {
  late final PuzzleRace _race =
      PuzzleRace(widget.raceCode, widget.raceSide, widget.seed);

  /// The same boards, in the same order, for everyone: smallest first.
  late final List<Maze> _mazes = <Maze>[
    for (final MazeBoard b in kMazeBoards) Maze.fromOpen(b.size, b.open),
  ];
  int _level = 0, _cell = 0, _moves = 0;
  bool _done = false;
  Offset _drag = Offset.zero;
  bool _swiped = false;

  /// Slide a finger and the walker follows: one cell for each cell's width
  /// of travel, turning when the finger turns.
  void _onSlide(Offset delta, double step) {
    _drag += delta;
    for (int i = 0; i < 40; i++) {
      final bool horizontal = _drag.dx.abs() >= _drag.dy.abs();
      final double travel = horizontal ? _drag.dx : _drag.dy;
      if (travel.abs() < step) return;
      final int dir = horizontal
          ? (travel > 0 ? Maze.right : Maze.left)
          : (travel > 0 ? Maze.down : Maze.up);
      _swiped = true;
      _drag = horizontal
          ? Offset(_drag.dx - step * travel.sign, _drag.dy)
          : Offset(_drag.dx, _drag.dy - step * travel.sign);
      _go(dir);
    }
  }

  /// A quick flick that was too short to cross a cell still moves one.
  void _onSlideEnd() {
    if (!_swiped && _drag.distance >= 16) {
      if (_drag.dx.abs() > _drag.dy.abs()) {
        _go(_drag.dx > 0 ? Maze.right : Maze.left);
      } else {
        _go(_drag.dy > 0 ? Maze.down : Maze.up);
      }
    }
    _drag = Offset.zero;
    _swiped = false;
  }

  @override
  void dispose() {
    _race.dispose();
    super.dispose();
  }

  MazeBoard get _board => kMazeBoards[_level];

  Maze get _maze => _mazes[_level];

  void _go(int dir) {
    if (_done) return;
    final int to = _maze.move(_cell, dir);
    if (to == _cell) return;
    setState(() {
      _cell = to;
      _moves++;
    });
    if (_cell == _maze.exit) {
      if (_level == _mazes.length - 1) {
        _race.finish(_mazes.length, _mazes.length);
        setState(() => _done = true);
      } else {
        _race.report(_level + 1, _mazes.length, _level + 1);
        setState(() {
          _level++;
          _cell = 0;
        });
        if (_level + 1 < kMazeBoards.length) {
          unawaited(precacheImage(
              AssetImage(kMazeBoards[_level + 1].asset), context));
        }
      }
    }
  }

  String get _open {
    final List<String> o = <String>[
      if (_maze.canMove(_cell, Maze.up)) 'up',
      if (_maze.canMove(_cell, Maze.right)) 'right',
      if (_maze.canMove(_cell, Maze.down)) 'down',
      if (_maze.canMove(_cell, Maze.left)) 'left',
    ];
    return o.join(', ');
  }

  Widget _pad4(IconData icon, String label, int dir) => Semantics(
        button: true,
        label: 'Move $label',
        child: SizedBox(
          width: 64,
          height: 56,
          child: GamePanel(
            onTap: () => _go(dir),
            padding: EdgeInsets.zero,
            child: Icon(icon, color: AppColors.goldLight),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return PuzzleFrame(
        title: 'Maze Escape',
        tagline: 'Find the way out',
        race: _race,
        myScore: _mazes.length,
        myTotal: _mazes.length,
        iFinished: true,
        children: <Widget>[
          puzzleDone(context,
              headline: 'Out of all ${_mazes.length} mazes',
              detail: '$_moves moves in all. Patience finds the way.'),
        ],
      );
    }
    final int size = _maze.size;
    return Focus(
      autofocus: true,
      onKeyEvent: (FocusNode n, KeyEvent e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        final LogicalKeyboardKey k = e.logicalKey;
        if (k == LogicalKeyboardKey.arrowUp) {
          _go(Maze.up);
        } else if (k == LogicalKeyboardKey.arrowDown) {
          _go(Maze.down);
        } else if (k == LogicalKeyboardKey.arrowLeft) {
          _go(Maze.left);
        } else if (k == LogicalKeyboardKey.arrowRight) {
          _go(Maze.right);
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: PuzzleFrame(
        title: 'Maze Escape',
        tagline: 'Find the way out',
        race: _race,
        myScore: _level,
        myTotal: _mazes.length,
        children: <Widget>[
          Text('MAZE ${_level + 1} OF ${_mazes.length} · $_moves MOVES',
              style: AppText.eyebrow),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
            final double step = max(12.0, box.maxWidth / size * 0.85);
            // The pointer events drive the walker (so a turn mid-slide
            // works); the drag recognisers only claim the touch so the page
            // does not scroll under the finger.
            return Listener(
              onPointerDown: (_) {
                _drag = Offset.zero;
                _swiped = false;
              },
              onPointerMove: (PointerMoveEvent e) => _onSlide(e.delta, step),
              onPointerUp: (_) => _onSlideEnd(),
              onPointerCancel: (_) => _onSlideEnd(),
              child: GestureDetector(
              onHorizontalDragUpdate: (_) {},
              onVerticalDragUpdate: (_) {},
              child: Semantics(
                label: 'Maze ${_level + 1}. You are in row '
                    '${_cell ~/ size + 1}, column ${_cell % size + 1} of '
                    '$size. The exit is at row $size, column $size. You can '
                    'move: $_open.',
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ExcludeSemantics(
                    child: _MazeBoardView(board: _board, cell: _cell),
                  ),
                ),
              ),
            ));
          }),
          const SizedBox(height: 14),
          Center(child: _pad4(Icons.keyboard_arrow_up, 'up', Maze.up)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            _pad4(Icons.keyboard_arrow_left, 'left', Maze.left),
            const SizedBox(width: 6),
            _pad4(Icons.keyboard_arrow_down, 'down', Maze.down),
            const SizedBox(width: 6),
            _pad4(Icons.keyboard_arrow_right, 'right', Maze.right),
          ]),
          const SizedBox(height: 10),
          Text('Slide your finger to walk to the star at the bottom right, or use the arrows.',
              textAlign: TextAlign.center, style: AppText.bodyMuted),
        ],
      ),
    );
  }
}

/// One board: the owner's picture, with the walker laid over its start cell.
class _MazeBoardView extends StatelessWidget {
  const _MazeBoardView({required this.board, required this.cell});
  final MazeBoard board;
  final int cell;

  @override
  Widget build(BuildContext context) {
    final int row = cell ~/ board.size, col = cell % board.size;
    final (double cx, double cy) = board.centre(row, col);
    final (double cw, double ch) = board.cell;
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
      final double s = box.maxWidth;
      final double d = min(cw, ch) * s * 0.46;
      return Stack(children: <Widget>[
        Positioned.fill(
          child: Image.asset(board.asset,
              key: ValueKey<String>(board.asset),
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          left: cx * s - d / 2,
          top: cy * s - d / 2,
          width: d,
          height: d,
          child: DecoratedBox(
            key: const ValueKey<String>('maze-walker'),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF1B8),
              boxShadow: <BoxShadow>[
                BoxShadow(
                    color: const Color(0xFFFFD866).withValues(alpha: 0.85),
                    blurRadius: d * 0.7,
                    spreadRadius: d * 0.08),
              ],
            ),
          ),
        ),
      ]);
    });
  }
}

// ------------------------------------------------------------- Math Quest

class MathQuestScreen extends StatefulWidget {
  const MathQuestScreen({
    super.key,
    this.raceCode,
    this.raceSide,
    this.seed,
    this.title = 'Math Quest',
    this.tagline = 'Think it through',
    this.build = buildMathQuestions,
  });
  final String? raceCode;
  final String? raceSide;
  final int? seed;
  final String title;
  final String tagline;
  final List<MathQuestion> Function(Random rnd) build;

  @override
  State<MathQuestScreen> createState() => _MathQuestState();
}

class _MathQuestState extends State<MathQuestScreen> {
  late final PuzzleRace _race =
      PuzzleRace(widget.raceCode, widget.raceSide, widget.seed);
  late final List<MathQuestion> _qs = widget.build(_race.rnd);
  int _i = 0, _score = 0;
  int? _picked;
  bool _done = false;

  @override
  void dispose() {
    _race.dispose();
    super.dispose();
  }

  void _next() {
    if (_picked == _qs[_i].answer) _score++;
    _race.report(_i + 1, _qs.length, _score);
    if (_i == _qs.length - 1) {
      _race.finish(_qs.length, _score);
      setState(() => _done = true);
    } else {
      setState(() {
        _picked = null;
        _i++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return PuzzleFrame(
        title: widget.title,
        tagline: widget.tagline,
        race: _race,
        myScore: _score,
        myTotal: _qs.length,
        iFinished: true,
        children: <Widget>[
          puzzleDone(context,
              headline: 'Score: $_score of ${_qs.length}',
              detail: 'Well played. Keep practising and it grows.'),
        ],
      );
    }
    final MathQuestion q = _qs[_i];
    final bool answered = _picked != null;
    return PuzzleFrame(
      title: widget.title,
      tagline: widget.tagline,
      race: _race,
      myScore: _score,
      myTotal: _qs.length,
      children: <Widget>[
        Text('QUESTION ${_i + 1} OF ${_qs.length} · SCORE $_score',
            style: AppText.eyebrow),
        const SizedBox(height: 10),
        GamePanel(
          child: Center(
            child: Text(q.text,
                style: AppText.titleMedium.copyWith(fontSize: 26)),
          ),
        ),
        const SizedBox(height: 12),
        for (int o = 0; o < q.options.length; o++)
          _pad(
            Builder(builder: (BuildContext _) {
              final bool right = answered && o == q.answer;
              final bool wrong = answered && o == _picked && o != q.answer;
              final String? tag = right
                  ? 'Correct answer'
                  : (wrong ? 'Your answer' : null);
              final Color? edge = right
                  ? const Color(0xFF7FD1A8)
                  : (wrong ? const Color(0xFFE8A07F) : null);
              final Widget card = GamePanel(
                onTap: answered ? null : () => setState(() => _picked = o),
                semanticsLabel:
                    tag == null ? null : '${q.options[o]}. $tag',
                child: Row(children: <Widget>[
                  if (edge != null) ...<Widget>[
                    Icon(right ? Icons.check_circle : Icons.cancel,
                        size: 20, color: edge),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                        tag == null
                            ? q.options[o].toString()
                            : '${q.options[o]} · $tag',
                        style: AppText.body.copyWith(fontSize: 16)),
                  ),
                ]),
              );
              if (edge == null) return card;
              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: edge, width: 2),
                ),
                child: card,
              );
            }),
            8,
          ),
        if (answered)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _next,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_ios,
                  size: 13, color: AppColors.gold),
              label: Text(_i == _qs.length - 1 ? 'Finish' : 'Next',
                  style: AppText.bodyMuted),
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------- Pattern Sequence

/// The owner's six gold pieces, in the same order as [_patternNames].
const List<String> _patternPieces = <String>[
  'assets/games/pattern/piece_0.webp',
  'assets/games/pattern/piece_1.webp',
  'assets/games/pattern/piece_2.webp',
  'assets/games/pattern/piece_3.webp',
  'assets/games/pattern/piece_4.webp',
  'assets/games/pattern/piece_5.webp',
];
const List<String> _patternNames = <String>[
  'Twelve-point star',
  'Eight-point rosette',
  'Lotus',
  'Knot',
  'Hexagon',
  'Eight-point star',
];

Widget _patternPiece(int s, double size) => Image.asset(
      _patternPieces[s],
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );

class PatternScreen extends StatefulWidget {
  const PatternScreen({super.key, this.raceCode, this.raceSide, this.seed});
  final String? raceCode;
  final String? raceSide;
  final int? seed;

  @override
  State<PatternScreen> createState() => _PatternState();
}

class _PatternState extends State<PatternScreen> {
  static const int rounds = 6;
  late final PuzzleRace _race =
      PuzzleRace(widget.raceCode, widget.raceSide, widget.seed);
  late final List<int> _full = patternSequence(_race.rnd, rounds);
  int _round = 1, _cleared = 0, _typed = 0;
  int? _lit;
  bool _showing = true, _done = false, _failed = false;
  Timer? _timer;

  List<int> get _seq => patternForRound(_full, _round);

  @override
  void initState() {
    super.initState();
    _show();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _race.dispose();
    super.dispose();
  }

  void _show() {
    _timer?.cancel();
    setState(() {
      _showing = true;
      _typed = 0;
      _lit = null;
    });
    int step = 0;
    final List<int> seq = _seq;
    _timer = Timer.periodic(const Duration(milliseconds: 750), (Timer t) {
      if (!mounted) return;
      if (step >= seq.length * 2) {
        t.cancel();
        setState(() {
          _lit = null;
          _showing = false;
        });
        return;
      }
      setState(() => _lit = step.isEven ? seq[step ~/ 2] : null);
      step++;
    });
  }

  void _tap(int s) {
    if (_showing || _done) return;
    if (s != _seq[_typed]) {
      _race.finish(rounds, _cleared);
      setState(() {
        _failed = true;
        _done = true;
      });
      return;
    }
    setState(() => _typed++);
    if (_typed == _seq.length) {
      _cleared++;
      _race.report(_cleared, rounds, _cleared);
      if (_cleared == rounds) {
        _race.finish(rounds, rounds);
        setState(() => _done = true);
      } else {
        _round++;
        _show();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return PuzzleFrame(
        title: 'Pattern Sequence',
        tagline: 'Watch. Remember. Repeat.',
        race: _race,
        myScore: _cleared,
        myTotal: rounds,
        iFinished: true,
        children: <Widget>[
          puzzleDone(context,
              headline: _failed
                  ? 'You cleared $_cleared of $rounds rounds'
                  : 'All $rounds rounds cleared',
              detail: _failed
                  ? 'That was not the next symbol. Try again to go further.'
                  : 'Sharp eyes and a steady memory.'),
        ],
      );
    }
    return PuzzleFrame(
      title: 'Pattern Sequence',
      tagline: 'Watch. Remember. Repeat.',
      race: _race,
      myScore: _cleared,
      myTotal: rounds,
      children: <Widget>[
        Text('ROUND $_round OF $rounds', style: AppText.eyebrow),
        const SizedBox(height: 10),
        GamePanel(
          child: SizedBox(
            height: 120,
            child: Center(
              child: _showing
                  ? (_lit == null
                      ? Text('Watch the symbols…', style: AppText.bodyMuted)
                      : Semantics(
                          liveRegion: true,
                          label: _patternNames[_lit!],
                          child: _patternPiece(_lit!, 104),
                        ))
                  : Text(
                      'Now repeat them: symbol ${_typed + 1} of ${_seq.length}',
                      style: AppText.body),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            for (int s = 0; s < kPatternSymbols; s++)
              Semantics(
                button: true,
                label: _patternNames[s],
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: GamePanel(
                    onTap: _showing ? null : () => _tap(s),
                    padding: const EdgeInsets.all(4),
                    child: Opacity(
                      opacity: _showing ? 0.4 : 1,
                      child: _patternPiece(s, 88),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (!_showing)
          Center(
            child: TextButton(
              onPressed: _typed == 0 ? _show : null,
              child: Text('Watch again', style: AppText.bodyMuted),
            ),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------- Sliding Tile

class SlidingTileScreen extends StatefulWidget {
  const SlidingTileScreen(
      {super.key, this.raceCode, this.raceSide, this.seed});
  final String? raceCode;
  final String? raceSide;
  final int? seed;

  @override
  State<SlidingTileScreen> createState() => _SlidingState();
}

class _SlidingState extends State<SlidingTileScreen> {
  late final PuzzleRace _race =
      PuzzleRace(widget.raceCode, widget.raceSide, widget.seed);
  late final SlidingPuzzle _p = SlidingPuzzle.shuffled(_race.rnd);
  bool _done = false;

  @override
  void dispose() {
    _race.dispose();
    super.dispose();
  }

  void _tap(int i) {
    if (_done) return;
    if (_p.tap(i)) {
      if (_p.isSolved) {
        _race.finish(1, 1);
        _done = true;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return PuzzleFrame(
        title: 'Sliding Tile',
        tagline: 'Slide the tiles into order',
        race: _race,
        myScore: 1,
        myTotal: 1,
        iFinished: true,
        children: <Widget>[
          puzzleDone(context,
              headline: 'Solved in ${_p.moves} moves',
              detail: 'Every tile is back in its place.'),
        ],
      );
    }
    return PuzzleFrame(
      title: 'Sliding Tile',
      tagline: 'Slide the tiles into order',
      race: _race,
      children: <Widget>[
        Text('${_p.moves} MOVES', style: AppText.eyebrow),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.count(
            crossAxisCount: SlidingPuzzle.side,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              for (int i = 0; i < _p.tiles.length; i++)
                _p.tiles[i] == 0
                    ? const SizedBox.shrink()
                    : Semantics(
                        button: true,
                        label: 'Tile ${_p.tiles[i]}, row '
                            '${i ~/ SlidingPuzzle.side + 1}, column '
                            '${i % SlidingPuzzle.side + 1}',
                        child: GamePanel(
                          onTap: () => _tap(i),
                          padding: EdgeInsets.zero,
                          child: Center(
                            child: ExcludeSemantics(
                              child: Text('${_p.tiles[i]}',
                                  style: AppText.titleMedium
                                      .copyWith(fontSize: 24)),
                            ),
                          ),
                        ),
                      ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text('Slide the tiles into order, 1 to 15. Tap a tile next to the gap.',
            textAlign: TextAlign.center, style: AppText.bodyMuted),
      ],
    );
  }
}

// ------------------------------------------------------------ Number Merge

class NumberMergeScreen extends StatefulWidget {
  const NumberMergeScreen(
      {super.key, this.raceCode, this.raceSide, this.seed});
  final String? raceCode;
  final String? raceSide;
  final int? seed;

  @override
  State<NumberMergeScreen> createState() => _MergeState();
}

class _MergeState extends State<NumberMergeScreen> {
  /// In a race the goal is the 256 tile (8 steps: 2, 4 … 256).
  static const int raceGoal = 256;
  late final PuzzleRace _race =
      PuzzleRace(widget.raceCode, widget.raceSide, widget.seed);
  late final MergeGame _g = MergeGame(_race.rnd);
  bool _done = false;
  Offset _drag = Offset.zero;

  @override
  void dispose() {
    _race.dispose();
    super.dispose();
  }

  int get _steps => (log(max(_g.best, 2)) / ln2).round();

  void _slide(String dir) {
    if (_done) return;
    if (_g.slide(dir)) {
      final bool racing = _race.link != null;
      if (racing) _race.report(min(_steps, 8), 8, min(_steps, 8));
      if (racing && _g.best >= raceGoal) {
        _race.finish(8, 8);
        _done = true;
      } else if (!_g.canMove) {
        _race.finish(8, min(_steps, 8));
        _done = true;
      }
    }
    setState(() {});
  }

  Color _tint(int v) {
    if (v == 0) return const Color(0x33FFFFFF);
    final double t = (log(v) / ln2 / 11).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFFEAD6B4), const Color(0xFFD4741E), t)!;
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      final bool won = _g.best >= raceGoal && _race.link != null;
      return PuzzleFrame(
        title: 'Number Merge',
        tagline: 'Join the numbers',
        race: _race,
        myScore: min(_steps, 8),
        myTotal: 8,
        iFinished: true,
        children: <Widget>[
          puzzleDone(context,
              headline: won ? 'You made $raceGoal' : 'No moves left',
              detail: 'Biggest tile: ${_g.best}. Total: ${_g.score}.'),
        ],
      );
    }
    return Focus(
      autofocus: true,
      onKeyEvent: (FocusNode n, KeyEvent e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        final LogicalKeyboardKey k = e.logicalKey;
        if (k == LogicalKeyboardKey.arrowUp) {
          _slide('up');
        } else if (k == LogicalKeyboardKey.arrowDown) {
          _slide('down');
        } else if (k == LogicalKeyboardKey.arrowLeft) {
          _slide('left');
        } else if (k == LogicalKeyboardKey.arrowRight) {
          _slide('right');
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: PuzzleFrame(
        title: 'Number Merge',
        tagline: 'Join the numbers',
        race: _race,
        myScore: min(_steps, 8),
        myTotal: 8,
        children: <Widget>[
          Text(
              'TOTAL ${_g.score} · BIGGEST ${_g.best}'
              '${_race.link != null ? ' · FIRST TO $raceGoal WINS' : ''}',
              style: AppText.eyebrow),
          const SizedBox(height: 10),
          GestureDetector(
            onPanStart: (_) => _drag = Offset.zero,
            onPanUpdate: (DragUpdateDetails d) => _drag += d.delta,
            onPanEnd: (_) {
              if (_drag.distance < 24) return;
              if (_drag.dx.abs() > _drag.dy.abs()) {
                _slide(_drag.dx > 0 ? 'right' : 'left');
              } else {
                _slide(_drag.dy > 0 ? 'down' : 'up');
              }
            },
            child: Semantics(
              label: 'Board. ${[
                for (int r = 0; r < 4; r++)
                  'Row ${r + 1}: ${[
                    for (int c = 0; c < 4; c++)
                      _g.at(r, c) == 0 ? 'empty' : '${_g.at(r, c)}'
                  ].join(', ')}'
              ].join('. ')}',
              child: AspectRatio(
                aspectRatio: 1,
                child: ExcludeSemantics(
                  child: GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      for (final int v in _g.cells)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: _tint(v),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: v == 0
                                ? const SizedBox.shrink()
                                : Text('$v',
                                    style: const TextStyle(
                                        color: Color(0xFF101C2E),
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            for (final MapEntry<String, IconData> b
                in <String, IconData>{
              'left': Icons.keyboard_arrow_left,
              'up': Icons.keyboard_arrow_up,
              'down': Icons.keyboard_arrow_down,
              'right': Icons.keyboard_arrow_right,
            }.entries)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Semantics(
                  button: true,
                  label: 'Slide ${b.key}',
                  child: SizedBox(
                    width: 64,
                    height: 52,
                    child: GamePanel(
                      onTap: () => _slide(b.key),
                      padding: EdgeInsets.zero,
                      child: Icon(b.value, color: AppColors.goldLight),
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          Text('Swipe, or use the arrows. Equal tiles join into one.',
              textAlign: TextAlign.center, style: AppText.bodyMuted),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- Logic Grid

const List<String> _gridNames = <String>['Ahmad', 'Bilal', 'Maryam', 'Sara'];

class LogicGridScreen extends StatefulWidget {
  const LogicGridScreen({super.key, this.raceCode, this.raceSide, this.seed});
  final String? raceCode;
  final String? raceSide;
  final int? seed;

  @override
  State<LogicGridScreen> createState() => _LogicGridState();
}

class _LogicGridState extends State<LogicGridScreen> {
  late final PuzzleRace _race =
      PuzzleRace(widget.raceCode, widget.raceSide, widget.seed);
  late final LogicGridPuzzle _p = LogicGridPuzzle.generate(_race.rnd);
  final List<int?> _guess = List<int?>.filled(LogicGridPuzzle.n, null);
  String? _msg;
  bool _done = false;

  @override
  void dispose() {
    _race.dispose();
    super.dispose();
  }

  String _clueText(GridClue c) {
    final String who = _gridNames[c.item];
    final int h = c.house + 1;
    return switch (c.kind) {
      'not' => '$who does not live in house $h.',
      'in' => '$who lives in house $h.',
      _ => '$who lives right next to house $h.',
    };
  }

  void _check() {
    if (_guess.contains(null)) {
      setState(() => _msg = 'Choose a house for everyone first.');
      return;
    }
    if (_guess.toSet().length < LogicGridPuzzle.n) {
      setState(() => _msg = 'Each house holds one person. Two share a house.');
      return;
    }
    final List<int> g = <int>[for (final int? v in _guess) v!];
    final int broken =
        _p.clues.where((GridClue c) => !LogicGridPuzzle.holds(c, g)).length;
    if (broken == 0) {
      _race.finish(1, 1);
      setState(() => _done = true);
    } else {
      setState(() => _msg = broken == 1
          ? 'Not yet: one clue is not satisfied.'
          : 'Not yet: $broken clues are not satisfied.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return PuzzleFrame(
        title: 'Logic Grid',
        tagline: 'Strategy. Patience. A clear mind.',
        race: _race,
        myScore: 1,
        myTotal: 1,
        iFinished: true,
        children: <Widget>[
          puzzleDone(context,
              headline: 'Solved',
              detail: 'Every clue fits. Clear thinking wins.'),
        ],
      );
    }
    return PuzzleFrame(
      title: 'Logic Grid',
      tagline: 'Strategy. Patience. A clear mind.',
      race: _race,
      children: <Widget>[
        Text('FOUR PEOPLE, FOUR HOUSES IN A ROW', style: AppText.eyebrow),
        const SizedBox(height: 10),
        GamePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final GridClue c in _p.clues)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text('• ${_clueText(c)}',
                      style: AppText.body.copyWith(height: 1.4)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < LogicGridPuzzle.n; i++)
          _pad(
            GamePanel(
              child: Row(children: <Widget>[
                SizedBox(
                    width: 72,
                    child: Text(_gridNames[i], style: AppText.body)),
                Expanded(
                  child: Wrap(spacing: 6, runSpacing: 6, children: <Widget>[
                    for (int h = 0; h < LogicGridPuzzle.n; h++)
                      Semantics(
                        button: true,
                        selected: _guess[i] == h,
                        label: '${_gridNames[i]} in house ${h + 1}',
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _guess[i] = h;
                            _msg = null;
                          }),
                          child: ExcludeSemantics(
                            child: Container(
                              width: 46,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: _guess[i] == h
                                    ? AppColors.gold
                                    : Colors.transparent,
                                border: Border.all(
                                    color: AppColors.goldLight, width: 1.2),
                              ),
                              child: Text('${h + 1}',
                                  style: TextStyle(
                                      color: _guess[i] == h
                                          ? AppColors.navy
                                          : AppColors.sand,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
            8,
          ),
        if (_msg != null) _pad(Text(_msg!, style: AppText.bodyMuted)),
        PlayButton(label: 'Check my answer', onPressed: _check),
      ],
    );
  }
}
