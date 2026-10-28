import 'dart:async' show unawaited;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../data/game_history.dart';
import '../data/game_settings.dart';
import '../data/games_store.dart';
import '../data/learning_loader.dart';
import '../engine/word_engine.dart';
import '../ui/games_art.dart';
import '../ui/games_theme.dart';
import '../../hadi/data/hadi_game_ask.dart';
import '../ui/learning_widgets.dart';
import 'game_results_screen.dart';
import '../../../app/theme/widgets/focus_ring.dart';

const String _wordSource = 'The glossary of the Huda guides in the app: the '
    'plain, literal meanings it gives for these terms. Nothing here states '
    'a ruling.';

/// The Huda glossary terms with their meanings, as a sentence for Hadi.
String _askAbout(Iterable<WordClue> words) => HadiGameAsk.words(
      entries: <({String term, String meaning})>[
        for (final WordClue w in words) (term: w.term, meaning: w.clue),
      ],
      source: _wordSource,
    );

// ---------------------------------------------------------------------------
// Word Search
// ---------------------------------------------------------------------------

/// /games/g/wordsearch/play - find the glossary words hidden in a grid.
/// Tap the first letter, then the last. No timer; free hints.
class WordSearchScreen extends ConsumerStatefulWidget {
  const WordSearchScreen({super.key});

  @override
  ConsumerState<WordSearchScreen> createState() => _WordSearchState();
}

class _WordSearchState extends ConsumerState<WordSearchScreen> {
  final Random _rnd = Random();
  SearchSession? _s;
  Cell? _first;
  Cell? _hint;
  String _message = 'Tap the first letter of a word, then its last letter.';
  bool _recorded = false;

  void _ensure(BuildContext context) {
    if (_s != null) return;
    // At large text the grid is smaller so each cell stays easy to tap.
    final bool large = MediaQuery.textScalerOf(context).scale(10) > 13;
    final int size = large ? 8 : 10;
    final WordGrid? g = buildWordGrid(
      LearningLoader.wordPool(),
      _rnd,
      size: size,
      count: large ? 5 : 7,
    );
    if (g == null) return;
    _s = SearchSession(g, hints: ref.read(gameSettingsProvider).showHints);
  }

  void _tap(Cell c) {
    final SearchSession s = _s!;
    if (s.finished) return;
    final Cell? a = _first;
    setState(() {
      _hint = null;
      if (a == null) {
        _first = c;
        _message = 'Now tap the last letter of the word.';
        return;
      }
      if (a == c) {
        _first = null;
        _message = 'Tap the first letter of a word, then its last letter.';
        return;
      }
      _first = null;
      final PlacedWord? p = WordGrid.isLine(a, c) ? s.tryLine(a, c) : null;
      if (p == null) {
        _message = 'That is not one of the words. Try again; there is no limit.';
      } else {
        gameHaptic(ref);
        _message = 'Found ${p.clue.term}: ${p.clue.clue}.';
      }
    });
    if (s.finished && !_recorded) {
      _recorded = true;
      final int now = DateTime.now().millisecondsSinceEpoch;
      unawaited(ref.read(gamesStoreProvider.notifier).record(GameResult(
            id: 'wordsearch-$now',
            gameId: 'wordsearch',
            title: 'Word Search',
            finishedMs: now,
            outcome: 'Found all ${s.grid.placed.length} words',
          )));
    }
  }

  void _hintTap() {
    final SearchSession s = _s!;
    final PlacedWord? p = s.useHint();
    if (p == null) return;
    setState(() {
      _hint = p.start;
      _message = 'A word starts at row ${p.start.r + 1}, column '
          '${p.start.c + 1}.';
    });
  }

  void _again() {
    setState(() {
      _s = null;
      _first = null;
      _hint = null;
      _recorded = false;
      _message = 'Tap the first letter of a word, then its last letter.';
    });
  }

  @override
  Widget build(BuildContext context) {
    _ensure(context);
    final SearchSession? s = _s;
    final GameSettings settings = ref.watch(gameSettingsProvider);
    final GamePalette pal = GamePalette.of(settings.theme);
    if (s == null) {
      return const _WordsFailed(title: 'Word Search');
    }
    final Set<int> foundCells = <int>{
      for (final PlacedWord p in s.grid.placed)
        if (s.found.contains(p.clue.word))
          for (final Cell c in p.cells) c.r * 100 + c.c,
    };
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          const ScreenHeader(title: 'Word Search', close: true, showSettings: false),
          Text(
            '${s.found.length} OF ${s.grid.placed.length} FOUND',
            style: AppText.eyebrow,
          ),
          const SizedBox(height: 8),
          GameProgressBar(
            value: s.found.length / s.grid.placed.length,
            label: '${s.found.length} of ${s.grid.placed.length} found',
          ),
          if (settings.showHints && !s.finished) ...<Widget>[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlineAction(
                label: s.hintsLeft > 0
                    ? 'Hint (${s.hintsLeft} left)'
                    : 'No hints left',
                icon: Icons.lightbulb_outline,
                onPressed: s.hintsLeft > 0 ? _hintTap : null,
              ),
            ),
          ],
          const SizedBox(height: 12),
          GameBoardBackdrop(
            slot: ArtSlot.wordSearchGrid,
            palette: pal,
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints box) {
                final double cell = min(box.maxWidth / s.grid.size, 46);
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int r = 0; r < s.grid.size; r++)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            for (int c = 0; c < s.grid.size; c++)
                              _GridCell(
                                size: cell,
                                letter: s.grid.letters[r][c],
                                row: r,
                                col: c,
                                palette: pal,
                                found: foundCells.contains(r * 100 + c),
                                picked: _first == (r: r, c: c),
                                hinted: _hint == (r: r, c: c),
                                onTap: () => _tap((r: r, c: c)),
                              ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(_message, style: AppText.body.copyWith(height: 1.5)),
          ),
          const SizedBox(height: 12),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Words to find',
                  style: AppText.titleMedium.copyWith(
                    color: GamesTheme.champagne,
                  ),
                ),
                const SizedBox(height: 8),
                for (final PlacedWord p in s.grid.placed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          s.found.contains(p.clue.word)
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 18,
                          color: s.found.contains(p.clue.word)
                              ? GamesTheme.good
                              : AppColors.goldLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.found.contains(p.clue.word)
                                ? '${p.clue.term}: ${p.clue.clue}'
                                : '${p.clue.term} (${p.clue.word.length} letters)',
                            style: AppText.body.copyWith(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (s.finished) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'All found. Source: $_wordSource',
                    style: AppText.bodyMuted.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  AskHadiAboutButton(
                    question: _askAbout(
                      s.grid.placed.map((PlacedWord p) => p.clue),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: <Widget>[
          PlayButton(
            label: s.finished ? 'New puzzle' : 'Start over',
            icon: Icons.replay,
            onPressed: _again,
          ),
          OutlineAction(
            label: 'All games',
            onPressed: () => context.go(AppRoutes.games),
          ),
        ],
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.size,
    required this.letter,
    required this.row,
    required this.col,
    required this.palette,
    required this.found,
    required this.picked,
    required this.hinted,
    required this.onTap,
  });

  final double size;
  final String letter;
  final int row;
  final int col;
  final GamePalette palette;
  final bool found;
  final bool picked;
  final bool hinted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = picked
        ? palette.accent
        : found
            ? palette.good.withValues(alpha: 0.35)
            : palette.fill;
    final Color fg = picked ? palette.fill : palette.text;
    return Semantics(
      button: true,
      selected: picked,
      label: 'Row ${row + 1}, column ${col + 1}, letter $letter'
          '${found ? ', part of a found word' : ''}',
      excludeSemantics: true,
      onTap: onTap,
      child: FocusRing(borderRadius: 12, child: InkWell(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(
              color: hinted ? palette.accent : palette.border.withValues(alpha: 0.4),
              width: hinted ? 3 : 0.8,
            ),
          ),
          child: Text(
            letter.toUpperCase(),
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: max(14, size * 0.46),
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      )),
    );
  }
}

// ---------------------------------------------------------------------------
// Word Scramble
// ---------------------------------------------------------------------------

/// /games/g/scramble/play - put the letters of a glossary word back in order,
/// with its plain meaning as the clue. No timer; free hints.
class ScrambleScreen extends ConsumerStatefulWidget {
  const ScrambleScreen({super.key});

  @override
  ConsumerState<ScrambleScreen> createState() => _ScrambleState();
}

class _ScrambleState extends ConsumerState<ScrambleScreen> {
  final Random _rnd = Random();
  ScrambleSession? _s;
  String _message = '';
  GameResult? _result;

  void _ensure() {
    if (_s != null) return;
    final List<WordClue> pool = LearningLoader.wordPool()..shuffle(_rnd);
    final List<WordClue> words = pool.take(6).toList();
    if (words.length < 3) return;
    _s = ScrambleSession(
      words,
      _rnd,
      hints: ref.read(gameSettingsProvider).showHints,
    );
  }

  void _check() {
    final ScrambleSession s = _s!;
    final bool ok = s.check();
    gameHaptic(ref);
    setState(() {
      _message = ok
          ? ''
          : 'Not yet. Tap a placed letter to take it back, and try again. '
              'There is no limit.';
    });
  }

  void _finish() {
    final ScrambleSession s = _s!;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final GameResult r = GameResult(
      id: 'scramble-$now',
      gameId: 'scramble',
      title: 'Word Scramble',
      finishedMs: now,
      outcome: '${s.firstTry} of ${s.total} words right on the first check',
    );
    unawaited(ref.read(gamesStoreProvider.notifier).record(r));
    setState(() => _result = r);
  }

  void _again() {
    setState(() {
      _s = null;
      _result = null;
      _message = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    _ensure();
    final ScrambleSession? s = _s;
    if (s == null) return const _WordsFailed(title: 'Word Scramble');
    final GameResult? done = _result;
    if (done != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: <Widget>[
            const ScreenHeader(
              title: 'Word Scramble',
              close: true,
              showSettings: false,
            ),
            ResultSummaryView(result: done),
            const SizedBox(height: 12),
            Text(
              'Source: $_wordSource',
              textAlign: TextAlign.center,
              style: AppText.bodyMuted.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            Center(
              child: AskHadiAboutButton(question: _askAbout(s.words)),
            ),
          ],
        ),
        bottomNavigationBar: BottomActions(
          children: <Widget>[
            PlayButton(label: 'Play again', icon: Icons.replay, onPressed: _again),
            OutlineAction(
              label: 'All games',
              onPressed: () => context.go(AppRoutes.games),
            ),
          ],
        ),
      );
    }
    final GameSettings settings = ref.watch(gameSettingsProvider);
    final GamePalette pal = GamePalette.of(settings.theme);
    final WordClue w = s.current;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          const ScreenHeader(
            title: 'Word Scramble',
            close: true,
            showSettings: false,
          ),
          Text('WORD ${s.index + 1} OF ${s.total}', style: AppText.eyebrow),
          const SizedBox(height: 8),
          GameProgressBar(
            value: (s.index + (s.solved ? 1 : 0)) / s.total,
            label: 'Word ${s.index + 1} of ${s.total}',
          ),
          const SizedBox(height: 12),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('The meaning', style: AppText.eyebrow),
                const SizedBox(height: 6),
                Text(
                  '${w.clue} (${w.word.length} letters)',
                  style: AppText.body.copyWith(fontSize: 18, height: 1.4),
                ),
              ],
            ),
          ),
          if (settings.showHints && !s.solved) ...<Widget>[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlineAction(
                label: s.hintsLeft > 0
                    ? 'Hint (${s.hintsLeft} left)'
                    : 'No hints left',
                icon: Icons.lightbulb_outline,
                onPressed: s.hintsLeft > 0
                    ? () {
                        if (s.useHint()) {
                          gameHaptic(ref);
                          setState(() => _message = '');
                        }
                      }
                    : null,
              ),
            ),
          ],
          const SizedBox(height: 12),
          GameBoardBackdrop(
            slot: ArtSlot.scrambleTile,
            palette: pal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Your word', style: AppText.bodyMuted),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (int slot = 0; slot < w.word.length; slot++)
                      _Tile(
                        letter: slot < s.built.length
                            ? s.tiles[s.built[slot]]
                            : '',
                        palette: pal,
                        filled: slot < s.built.length,
                        good: s.solved,
                        label: slot < s.built.length
                            ? 'Letter ${slot + 1}: ${s.tiles[s.built[slot]]}. '
                                'Tap to take it back.'
                            : 'Empty place ${slot + 1}',
                        onTap: slot < s.built.length && !s.solved
                            ? () => setState(() => s.removeFrom(slot))
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Letters', style: AppText.bodyMuted),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (int i = 0; i < s.tiles.length; i++)
                      _Tile(
                        letter: s.tiles[i],
                        palette: pal,
                        filled: !s.isUsed(i),
                        good: false,
                        dim: s.isUsed(i),
                        label: s.isUsed(i)
                            ? 'Letter ${s.tiles[i]}, already placed'
                            : 'Letter ${s.tiles[i]}',
                        onTap: s.isUsed(i) || s.solved
                            ? null
                            : () => setState(() {
                                  s.tapTile(i);
                                  _message = '';
                                }),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (_message.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(_message, style: AppText.body.copyWith(height: 1.5)),
            ),
          ],
          if (s.solved) ...<Widget>[
            const SizedBox(height: 12),
            GamePanel(
              selected: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.check_circle, color: GamesTheme.good),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          w.term,
                          style: AppText.titleMedium.copyWith(
                            color: GamesTheme.champagne,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'It means: ${w.clue}.',
                    style: AppText.body.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Source: $_wordSource',
                    style: AppText.bodyMuted.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  AskHadiAboutButton(question: _askAbout(<WordClue>[w])),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: <Widget>[
          if (!s.solved)
            PlayButton(
              label: 'Check word',
              icon: Icons.check,
              onPressed: s.built.length == w.word.length ? _check : null,
            )
          else
            PlayButton(
              label: s.isLast ? 'See results' : 'Next word',
              icon: Icons.arrow_forward,
              onPressed: () {
                if (s.isLast) {
                  _finish();
                } else if (s.next()) {
                  setState(() => _message = '');
                }
              },
            ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.letter,
    required this.palette,
    required this.filled,
    required this.good,
    required this.label,
    required this.onTap,
    this.dim = false,
  });

  final String letter;
  final GamePalette palette;
  final bool filled;
  final bool good;
  final bool dim;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget box = Container(
      width: GamesTheme.minTap,
      height: GamesTheme.minTap,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? palette.fill : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: good ? palette.good : palette.border,
          width: good ? 2 : 1,
        ),
      ),
      child: Text(
        letter.toUpperCase(),
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: palette.text,
        ),
      ),
    );
    return Semantics(
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: FocusRing(borderRadius: 10, child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Opacity(opacity: dim ? 0.35 : 1, child: box),
      )),
    );
  }
}

class _WordsFailed extends StatelessWidget {
  const _WordsFailed({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: <Widget>[
          ScreenHeader(title: title, close: true, showSettings: false),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'The puzzle could not be made. Please go back and try again.',
                  textAlign: TextAlign.center,
                  style: AppText.body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
