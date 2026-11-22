import 'dart:async';

import 'package:flutter/material.dart' hide Text;

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../engine/puzzle_engines.dart';
import '../ui/games_theme.dart';
import 'puzzle_games.dart';

const List<Color> _tubeColours = <Color>[
  Color(0xFFE0524D),
  Color(0xFF3F8EDB),
  Color(0xFF4DB06A),
  Color(0xFFF0C23A),
  Color(0xFF9A5BD0),
  Color(0xFFEE8A3C),
];
const List<String> _tubeNames = <String>[
  'red',
  'blue',
  'green',
  'yellow',
  'purple',
  'orange',
];

// ------------------------------------------------------------ Colour Sort

class ColourSortScreen extends StatefulWidget {
  const ColourSortScreen({super.key, this.raceCode, this.raceSide, this.seed});
  final String? raceCode;
  final String? raceSide;
  final int? seed;

  @override
  State<ColourSortScreen> createState() => _ColourSortState();
}

class _ColourSortState extends State<ColourSortScreen> {
  late final PuzzleRace _race =
      PuzzleRace(widget.raceCode, widget.raceSide, widget.seed);
  late final ColourSort _g = ColourSort.generate(_race.rnd);
  int? _from;
  bool _done = false;

  @override
  void dispose() {
    _race.dispose();
    super.dispose();
  }

  void _tap(int t) {
    if (_done) return;
    if (_from == null) {
      if (_g.tubes[t].isNotEmpty) setState(() => _from = t);
      return;
    }
    final int f = _from!;
    setState(() => _from = null);
    if (f == t) return;
    if (_g.pour(f, t)) {
      if (_g.isSolved) {
        _race.finish(1, 1);
        _done = true;
      }
      setState(() {});
    }
  }

  String _label(int i) {
    final List<int> t = _g.tubes[i];
    return 'Tube ${i + 1}: ${t.isEmpty ? 'empty' : t.map((int c) => _tubeNames[c]).join(', ')}'
        '${_from == i ? ', selected' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return PuzzleFrame(
        title: 'Colour Sort',
        tagline: 'Pour. Match. Clear.',
        race: _race,
        myScore: 1,
        myTotal: 1,
        iFinished: true,
        children: <Widget>[
          puzzleDone(context,
              headline: 'Sorted in ${_g.moves} pours',
              detail: 'Every tube holds one colour.'),
        ],
      );
    }
    final bool stuck = _g.isStuck;
    return PuzzleFrame(
      title: 'Colour Sort',
      tagline: 'Pour. Match. Clear.',
      race: _race,
      children: <Widget>[
        Text('${_g.moves} POURS', style: AppText.eyebrow),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 14,
          children: <Widget>[
            for (int i = 0; i < _g.tubes.length; i++)
              Semantics(
                button: true,
                label: _label(i),
                child: GestureDetector(
                  onTap: () => _tap(i),
                  child: ExcludeSemantics(
                    child: Container(
                      width: 50,
                      height: 170,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0x33FFFFFF),
                        border: Border.all(
                          color: _from == i
                              ? AppColors.goldLight
                              : GamesTheme.border,
                          width: _from == i ? 3 : 1.4,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          for (final int c in _g.tubes[i].reversed)
                            Container(
                              height: 36,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: _tubeColours[c],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              // A letter too, so colour is never the only cue.
                              child: Text(_tubeNames[c][0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (stuck)
          Text('No pour is possible. Go back to the Games page and start again.',
              textAlign: TextAlign.center, style: AppText.bodyMuted),
        Text('Tap a tube, then the tube to pour into. Same colour on top, or an empty tube.',
            textAlign: TextAlign.center, style: AppText.bodyMuted),
      ],
    );
  }
}

// --------------------------------------------------------- Tower Builder

class TowerScreen extends StatefulWidget {
  const TowerScreen({super.key, this.raceCode, this.raceSide, this.seed});
  final String? raceCode;
  final String? raceSide;
  final int? seed;

  @override
  State<TowerScreen> createState() => _TowerState();
}

class _TowerState extends State<TowerScreen> {
  late final PuzzleRace _race =
      PuzzleRace(widget.raceCode, widget.raceSide, widget.seed);
  final Towers _t = Towers(5);
  int? _from;
  bool _done = false;

  @override
  void dispose() {
    _race.dispose();
    super.dispose();
  }

  void _tap(int p) {
    if (_done) return;
    if (_from == null) {
      if (_t.pegs[p].isNotEmpty) setState(() => _from = p);
      return;
    }
    final int f = _from!;
    setState(() => _from = null);
    if (_t.move(f, p)) {
      if (_t.isSolved) {
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
        title: 'Tower Builder',
        tagline: 'Patience, one disc at a time.',
        race: _race,
        myScore: 1,
        myTotal: 1,
        iFinished: true,
        children: <Widget>[
          puzzleDone(context,
              headline: 'Tower moved in ${_t.moves} moves',
              detail: 'The fewest possible is ${_t.best}.'),
        ],
      );
    }
    return PuzzleFrame(
      title: 'Tower Builder',
      tagline: 'Patience, one disc at a time.',
      race: _race,
      children: <Widget>[
        Text('${_t.moves} MOVES · FEWEST POSSIBLE ${_t.best}',
            style: AppText.eyebrow),
        const SizedBox(height: 12),
        Row(children: <Widget>[
          for (int p = 0; p < 3; p++)
            Expanded(
              child: Semantics(
                button: true,
                label: 'Peg ${p + 1}: ${_t.pegs[p].isEmpty ? 'empty' : 'discs ${_t.pegs[p].reversed.join(', ')} from the top'}'
                    '${_from == p ? ', selected' : ''}',
                child: GestureDetector(
                  onTap: () => _tap(p),
                  child: ExcludeSemantics(
                    child: Container(
                      height: 230,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0x33FFFFFF),
                        border: Border.all(
                          color: _from == p
                              ? AppColors.goldLight
                              : GamesTheme.border,
                          width: _from == p ? 3 : 1.4,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          for (final int d in _t.pegs[p].reversed)
                            Container(
                              width: 24.0 + d * 12,
                              height: 28,
                              margin: const EdgeInsets.only(bottom: 3),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Color.lerp(AppColors.goldLight,
                                    AppColors.goldDark, d / 5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$d',
                                  style: const TextStyle(
                                      color: Color(0xFF101C2E),
                                      fontWeight: FontWeight.w700)),
                            ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Text('Move the whole tower to the third peg. One disc at a time, and never a bigger disc on a smaller one.',
            textAlign: TextAlign.center, style: AppText.bodyMuted),
      ],
    );
  }
}

// ---------------------------------------------------------- Memory Numbers

class MemoryNumbersScreen extends StatefulWidget {
  const MemoryNumbersScreen(
      {super.key, this.raceCode, this.raceSide, this.seed});
  final String? raceCode;
  final String? raceSide;
  final int? seed;

  @override
  State<MemoryNumbersScreen> createState() => _MemoryNumbersState();
}

class _MemoryNumbersState extends State<MemoryNumbersScreen> {
  static const int rounds = 7; // 3 digits up to 9 digits
  late final PuzzleRace _race =
      PuzzleRace(widget.raceCode, widget.raceSide, widget.seed);
  late final List<String> _nums = <String>[
    for (int r = 0; r < rounds; r++) memoryNumber(_race.rnd, r + 3),
  ];
  int _round = 0, _cleared = 0;
  String _typed = '';
  bool _showing = true, _done = false, _failed = false;
  String? _wrong;
  Timer? _timer;

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
      _typed = '';
    });
    _timer = Timer(Duration(milliseconds: 1500 + 700 * _nums[_round].length),
        () {
      if (mounted) setState(() => _showing = false);
    });
  }

  void _key(String d) {
    if (_showing || _done) return;
    if (_typed.length >= _nums[_round].length) return;
    setState(() => _typed += d);
  }

  void _submit() {
    if (_showing || _done) return;
    if (_typed == _nums[_round]) {
      _cleared++;
      _race.report(_cleared, rounds, _cleared);
      if (_cleared == rounds) {
        _race.finish(rounds, rounds);
        setState(() => _done = true);
      } else {
        _round++;
        _show();
      }
    } else {
      _race.finish(rounds, _cleared);
      setState(() {
        _failed = true;
        _wrong = _nums[_round];
        _done = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return PuzzleFrame(
        title: 'Memory Numbers',
        tagline: 'Look. Hold it. Type it back.',
        race: _race,
        myScore: _cleared,
        myTotal: rounds,
        iFinished: true,
        children: <Widget>[
          puzzleDone(context,
              headline: _failed
                  ? 'You remembered $_cleared of $rounds numbers'
                  : 'All $rounds numbers remembered',
              detail: _failed
                  ? 'The number was $_wrong.'
                  : 'A strong memory.'),
        ],
      );
    }
    final String n = _nums[_round];
    return PuzzleFrame(
      title: 'Memory Numbers',
      tagline: 'Look. Hold it. Type it back.',
      race: _race,
      myScore: _cleared,
      myTotal: rounds,
      children: <Widget>[
        Text('NUMBER ${_round + 1} OF $rounds · ${n.length} DIGITS',
            style: AppText.eyebrow),
        const SizedBox(height: 10),
        GamePanel(
          child: SizedBox(
            height: 90,
            child: Center(
              child: _showing
                  ? Semantics(
                      liveRegion: true,
                      label: 'Remember this number: ${n.split('').join(' ')}',
                      child: Text(n,
                          style: AppText.titleMedium
                              .copyWith(fontSize: 38, letterSpacing: 6)),
                    )
                  : Text(
                      _typed.isEmpty
                          ? 'Type the number'
                          : _typed.padRight(n.length, '•'),
                      style: AppText.titleMedium
                          .copyWith(fontSize: 34, letterSpacing: 6)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!_showing) ...<Widget>[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String d in <String>[
                '1', '2', '3', '4', '5', '6', '7', '8', '9', '0'
              ])
                SizedBox(
                  width: 56,
                  height: 52,
                  child: GamePanel(
                    onTap: () => _key(d),
                    semanticsLabel: 'Digit $d',
                    padding: EdgeInsets.zero,
                    child: Center(
                        child: Text(d, style: AppText.titleMedium)),
                  ),
                ),
              SizedBox(
                width: 56,
                height: 52,
                child: GamePanel(
                  onTap: () => setState(() => _typed = _typed.isEmpty
                      ? ''
                      : _typed.substring(0, _typed.length - 1)),
                  semanticsLabel: 'Delete last digit',
                  padding: EdgeInsets.zero,
                  child: const Icon(Icons.backspace_outlined,
                      color: AppColors.goldLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PlayButton(
            label: 'Check',
            onPressed: _typed.length == n.length ? _submit : null,
          ),
        ] else
          Text('Remember it…',
              textAlign: TextAlign.center, style: AppText.bodyMuted),
      ],
    );
  }
}

// -------------------------------------------------------------- Clue Hunt

const List<IconData> _clueIcons = <IconData>[
  Icons.star_rounded,
  Icons.nightlight_round,
  Icons.wb_sunny_rounded,
  Icons.favorite_rounded,
  Icons.eco_rounded,
  Icons.diamond_rounded,
];
const List<String> _clueNames = <String>[
  'Star',
  'Crescent',
  'Sun',
  'Heart',
  'Leaf',
  'Gem',
];

class ClueHuntScreen extends StatefulWidget {
  const ClueHuntScreen({super.key, this.raceCode, this.raceSide, this.seed});
  final String? raceCode;
  final String? raceSide;
  final int? seed;

  @override
  State<ClueHuntScreen> createState() => _ClueHuntState();
}

class _ClueHuntState extends State<ClueHuntScreen> {
  static const int tries = 8;
  late final PuzzleRace _race =
      PuzzleRace(widget.raceCode, widget.raceSide, widget.seed);
  late final List<int> _code = clueCode(_race.rnd);
  final List<List<int>> _guesses = <List<int>>[];
  final List<ClueFeedback> _fb = <ClueFeedback>[];
  List<int> _cur = <int>[];
  bool _done = false, _won = false;

  @override
  void dispose() {
    _race.dispose();
    super.dispose();
  }

  void _pick(int s) {
    if (_done || _cur.length >= 4 || _cur.contains(s)) return;
    setState(() => _cur = <int>[..._cur, s]);
  }

  void _submit() {
    if (_cur.length != 4 || _done) return;
    final ClueFeedback f = clueFeedback(_code, _cur);
    setState(() {
      _guesses.add(_cur);
      _fb.add(f);
      _cur = <int>[];
    });
    _race.report(_guesses.length, tries, 0);
    if (f.place == 4) {
      _race.finish(tries, tries - _guesses.length + 1);
      setState(() {
        _won = true;
        _done = true;
      });
    } else if (_guesses.length == tries) {
      _race.finish(tries, 0);
      setState(() => _done = true);
    }
  }

  Widget _row(List<int> g, ClueFeedback? f) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Semantics(
          label: g.map((int s) => _clueNames[s]).join(', ') +
              (f == null
                  ? ''
                  : '. ${f.place} right and in place, ${f.misplaced} right but in the wrong place'),
          child: ExcludeSemantics(
            child: Row(children: <Widget>[
              for (final int s in g)
                Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(_clueIcons[s],
                        size: 30, color: AppColors.goldLight)),
              const Spacer(),
              if (f != null)
                Text('${f.place} in place · ${f.misplaced} elsewhere',
                    style: AppText.bodyMuted.copyWith(fontSize: 12.5)),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return PuzzleFrame(
        title: 'Clue Hunt',
        tagline: 'Read the clues. Find the code.',
        race: _race,
        myScore: _won ? 1 : 0,
        myTotal: 1,
        iFinished: true,
        children: <Widget>[
          puzzleDone(context,
              headline: _won
                  ? 'Found in ${_guesses.length} ${_guesses.length == 1 ? 'try' : 'tries'}'
                  : 'Not found this time',
              detail: _won
                  ? 'Well reasoned.'
                  : 'The code was ${_code.map((int s) => _clueNames[s]).join(', ')}.'),
        ],
      );
    }
    return PuzzleFrame(
      title: 'Clue Hunt',
      tagline: 'Read the clues. Find the code.',
      race: _race,
      children: <Widget>[
        Text('TRY ${_guesses.length + 1} OF $tries', style: AppText.eyebrow),
        const SizedBox(height: 10),
        GamePanel(
          child: Column(children: <Widget>[
            for (int i = 0; i < _guesses.length; i++) _row(_guesses[i], _fb[i]),
            if (_guesses.isEmpty)
              Text('A hidden code of four different symbols. After each try you see how many are in the right place and how many are right but elsewhere.',
                  style: AppText.bodyMuted.copyWith(height: 1.5)),
          ]),
        ),
        const SizedBox(height: 12),
        GamePanel(
          child: SizedBox(
            height: 40,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 0; i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: i < _cur.length
                          ? Icon(_clueIcons[_cur[i]],
                              size: 34, color: AppColors.goldLight)
                          : const Icon(Icons.circle_outlined,
                              size: 30, color: AppColors.textFaint),
                    ),
                ]),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            for (int s = 0; s < 6; s++)
              SizedBox(
                width: 70,
                height: 56,
                child: GamePanel(
                  onTap: _cur.contains(s) ? null : () => _pick(s),
                  semanticsLabel: _clueNames[s],
                  padding: EdgeInsets.zero,
                  child: Icon(_clueIcons[s],
                      size: 30,
                      color: _cur.contains(s)
                          ? AppColors.textFaint
                          : AppColors.goldLight),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: <Widget>[
          Expanded(
            child: OutlineAction(
              label: 'Clear',
              onPressed: _cur.isEmpty ? null : () => setState(() => _cur = <int>[]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PlayButton(
                label: 'Try this code',
                onPressed: _cur.length == 4 ? _submit : null),
          ),
        ]),
      ],
    );
  }
}

// ----------------------------------------------------------------- Sudoku

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key, this.raceCode, this.raceSide, this.seed});
  final String? raceCode;
  final String? raceSide;
  final int? seed;

  @override
  State<SudokuScreen> createState() => _SudokuState();
}

class _SudokuState extends State<SudokuScreen> {
  static const int maxMistakes = 3;
  late final PuzzleRace _race =
      PuzzleRace(widget.raceCode, widget.raceSide, widget.seed);
  late final SudokuPuzzle _p = SudokuPuzzle.generate(_race.rnd, clues: 42);
  late final List<int> _grid = List<int>.of(_p.puzzle);
  int? _sel;
  int _mistakes = 0;
  bool _done = false, _won = false;

  @override
  void dispose() {
    _race.dispose();
    super.dispose();
  }

  int get _filled => _grid.where((int v) => v != 0).length;

  void _put(int v) {
    final int? s = _sel;
    if (s == null || _done || _p.puzzle[s] != 0) return;
    if (_p.solution[s] == v) {
      setState(() => _grid[s] = v);
      _race.report(_filled - _p.puzzle.where((int x) => x != 0).length,
          81 - _p.puzzle.where((int x) => x != 0).length, 0);
      if (_filled == 81) {
        _race.finish(1, 1);
        setState(() {
          _won = true;
          _done = true;
        });
      }
    } else {
      setState(() => _mistakes++);
      if (_mistakes >= maxMistakes) {
        _race.finish(1, 0);
        setState(() => _done = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return PuzzleFrame(
        title: 'Sudoku',
        tagline: 'Strategy. Patience. A clear mind.',
        race: _race,
        myScore: _won ? 1 : 0,
        myTotal: 1,
        iFinished: true,
        children: <Widget>[
          puzzleDone(context,
              headline: _won ? 'Solved' : 'Three mistakes',
              detail: _won
                  ? 'Every row, column and box is complete.'
                  : 'Go back to the Games page to try a new one.'),
        ],
      );
    }
    final int? sel = _sel;
    return PuzzleFrame(
      title: 'Sudoku',
      tagline: 'Strategy. Patience. A clear mind.',
      race: _race,
      children: <Widget>[
        Text('MISTAKES $_mistakes / $maxMistakes', style: AppText.eyebrow),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (BuildContext _, BoxConstraints c) {
            final double cell = c.maxWidth / 9;
            return Stack(children: <Widget>[
              for (int i = 0; i < 81; i++)
                Positioned(
                  left: (i % 9) * cell,
                  top: (i ~/ 9) * cell,
                  width: cell,
                  height: cell,
                  child: Semantics(
                    button: true,
                    selected: sel == i,
                    label: 'Row ${i ~/ 9 + 1}, column ${i % 9 + 1}, '
                        '${_grid[i] == 0 ? 'empty' : _grid[i]}'
                        '${_p.puzzle[i] != 0 ? ', given' : ''}',
                    child: GestureDetector(
                      onTap: () => setState(() => _sel = i),
                      child: ExcludeSemantics(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sel == i
                                ? const Color(0x55D4AF37)
                                : (sel != null &&
                                        (sel ~/ 9 == i ~/ 9 ||
                                            sel % 9 == i % 9)
                                    ? const Color(0x22D4AF37)
                                    : Colors.transparent),
                            border: Border(
                              top: BorderSide(
                                  color: GamesTheme.border,
                                  width: (i ~/ 9) % 3 == 0 ? 1.8 : 0.5),
                              left: BorderSide(
                                  color: GamesTheme.border,
                                  width: (i % 9) % 3 == 0 ? 1.8 : 0.5),
                              right: i % 9 == 8
                                  ? const BorderSide(
                                      color: GamesTheme.border, width: 1.8)
                                  : BorderSide.none,
                              bottom: i ~/ 9 == 8
                                  ? const BorderSide(
                                      color: GamesTheme.border, width: 1.8)
                                  : BorderSide.none,
                            ),
                          ),
                          child: Text(
                            _grid[i] == 0 ? '' : '${_grid[i]}',
                            style: TextStyle(
                              fontSize: cell * 0.5,
                              fontWeight: _p.puzzle[i] != 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _p.puzzle[i] != 0
                                  ? AppColors.sand
                                  : AppColors.goldLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ]);
          }),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (int v = 1; v <= 9; v++)
              SizedBox(
                width: 36,
                height: 46,
                child: GamePanel(
                  onTap: () => _put(v),
                  semanticsLabel: 'Put $v',
                  padding: EdgeInsets.zero,
                  child: Center(
                      child: Text('$v',
                          style: AppText.titleMedium.copyWith(fontSize: 18))),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Tap a square, then a number. A wrong number counts as a mistake.',
            textAlign: TextAlign.center, style: AppText.bodyMuted),
      ],
    );
  }
}
