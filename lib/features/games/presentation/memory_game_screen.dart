import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/focus_ring.dart';
import '../../../app/theme/widgets/needs_internet_view.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../data/game_history.dart';
import '../data/games_adapters.dart';
import '../data/games_store.dart';
import '../engine/memory_engine.dart';
import '../ui/games_theme.dart';
import 'game_results_screen.dart';
import 'games_screens.dart';

/// /games/memory - Names Memory: turn two cards, an Arabic Name and its
/// spelling. No timer; a match shows the meaning and where the Name is found.
class MemoryGameScreen extends ConsumerStatefulWidget {
  const MemoryGameScreen({this.players = 1, this.pairs = 8, super.key});

  final int players;
  final int pairs;

  @override
  ConsumerState<MemoryGameScreen> createState() => _MemoryState();
}

class _MemoryState extends ConsumerState<MemoryGameScreen> {
  final Random _rnd = Random();
  MemoryGame? _game;
  Timer? _timer;
  GameResult? _result;
  Name99? _lastMatch;
  final ScrollController _scroll = ScrollController();
  final GlobalKey _matchKey = GlobalKey();

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _clear() {
    _timer?.cancel();
    final MemoryGame? g = _game;
    if (g == null || !g.awaitingClear) return;
    setState(g.clearMismatch);
  }

  void _tap(int i, List<Name99> names) {
    final MemoryGame g = _game!;
    if (g.awaitingClear) _clear();
    final FlipOutcome out = g.flip(i);
    if (out == FlipOutcome.ignored) return;
    if (out == FlipOutcome.match) {
      final int n = g.cards[i].pairId;
      Name99? found;
      for (final Name99 e in names) {
        if (e.n == n) found = e;
      }
      _lastMatch = found;
      // The meaning and where the Name is found sit below the grid: on a
      // phone they would be off the screen, so bring them into view.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext? c = _matchKey.currentContext;
        if (c != null && c.mounted) {
          unawaited(
            Scrollable.ensureVisible(
              c,
              duration: const Duration(milliseconds: 250),
              alignment: 1,
            ),
          );
        }
      });
    } else if (out == FlipOutcome.mismatch) {
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 1600), _clear);
    }
    setState(() {});
    if (g.finished) _finish(g);
  }

  void _finish(MemoryGame g) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int pairs = g.cards.length ~/ 2;
    final GameResult r = GameResult(
      id: 'memory-$now',
      gameId: 'memory',
      title: 'Names Memory',
      finishedMs: now,
      correct: pairs,
      total: pairs,
      players: g.players,
      playerScores: g.players > 1 ? List<int>.of(g.scores) : <int>[],
      outcome: '${g.tries} tries',
    );
    unawaited(ref.read(gamesStoreProvider.notifier).record(r));
    setState(() => _result = r);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Name99>> async = ref.watch(namesProvider);
    return async.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      ),
      error: (Object e, StackTrace s) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            const ScreenHeader(
              title: 'Names Memory',
              close: true,
              showSettings: false,
            ),
            Expanded(
              child: NeedsInternetView(
                what: 'The 99 Names',
                onRetry: () => ref.invalidate(namesProvider),
              ),
            ),
          ],
        ),
      ),
      data: _loaded,
    );
  }

  Widget _loaded(List<Name99> names) {
    final List<MemoryName> rows = memoryNames(names);
    if (memoryCandidates(rows).length < 2) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            const ScreenHeader(
              title: 'Names Memory',
              close: true,
              showSettings: false,
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'The Names are not ready on this device yet.',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
    _game ??= MemoryGame(
      cards: buildMemoryDeck(rows, widget.pairs.clamp(2, 12), _rnd),
      players: widget.players.clamp(1, 4),
    );
    final MemoryGame g = _game!;
    final GameResult? done = _result;
    if (done != null) return _finishedPage(done);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          const ScreenHeader(
            title: 'Names Memory',
            close: true,
            showSettings: false,
          ),
          _status(g),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) {
              final int cols = box.maxWidth >= 520 ? 4 : 3;
              const double gap = 10;
              final double w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: <Widget>[
                  for (final MemoryCard c in g.cards)
                    SizedBox(
                      width: w,
                      height: w * 1.05,
                      child: _CardView(
                        card: c,
                        up: g.isUp(c.id),
                        matched: g.matched.contains(c.id),
                        onTap: g.matched.contains(c.id)
                            ? null
                            : () => _tap(c.id, names),
                      ),
                    ),
                ],
              );
            },
          ),
          if (g.awaitingClear) ...<Widget>[
            const SizedBox(height: 14),
            Center(
              child: OutlineAction(
                label: 'Turn the cards back',
                icon: Icons.flip,
                onPressed: _clear,
              ),
            ),
          ],
          if (_lastMatch != null && !g.awaitingClear) ...<Widget>[
            const SizedBox(height: 14),
            GamePanel(
              key: _matchKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('A match', style: AppText.eyebrow),
                  const SizedBox(height: 4),
                  if (_lastMatch!.arabic != null)
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        _lastMatch!.arabic!,
                        style: names99ArabicStyle(30),
                      ),
                    ),
                  Text(
                    _lastMatch!.name,
                    style: AppText.titleMedium.copyWith(
                      color: GamesTheme.champagne,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lastMatch!.meaning,
                    style: AppText.body.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Source: ${names99RefLabel(_lastMatch!.ref)}',
                    style: AppText.bodyMuted,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _status(MemoryGame g) {
    final int pairs = g.cards.length ~/ 2;
    if (g.players == 1) {
      return Semantics(
        liveRegion: true,
        child: Text(
          'PAIRS FOUND ${g.pairsFound} OF $pairs · TRIES ${g.tries}',
          style: AppText.eyebrow,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (int p = 0; p < g.players; p++)
          GamePanel(
            selected: g.turn == p,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              g.turn == p
                  ? 'Player ${p + 1}: ${g.scores[p]} · your turn'
                  : 'Player ${p + 1}: ${g.scores[p]}',
              style: AppText.body.copyWith(
                fontWeight: g.turn == p ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  Widget _finishedPage(GameResult r) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          const ScreenHeader(
            title: 'Names Memory',
            close: true,
            showSettings: false,
          ),
          ResultSummaryView(result: r),
          const SizedBox(height: 8),
          Text(
            'Every pair found. ${r.outcome ?? ''}',
            textAlign: TextAlign.center,
            style: AppText.bodyMuted,
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: <Widget>[
          PlayButton(
            label: 'Play again',
            icon: Icons.replay,
            onPressed: () => context.go('/games/g/memory/setup'),
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

class _CardView extends StatelessWidget {
  const _CardView({
    required this.card,
    required this.up,
    required this.matched,
    required this.onTap,
  });

  final MemoryCard card;
  final bool up;
  final bool matched;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(16);
    final String label = up
        ? '${card.face}${matched ? ', matched' : ''}'
        : 'Card ${card.id + 1}, face down';
    return Semantics(
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: FocusRing(
        borderRadius: 16,
        child: Material(
          type: MaterialType.transparency,
          child: FocusRing(borderRadius: 12, child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: up
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFF16263B), Color(0xFF0B1B2A)],
                      ),
                color: up ? GamesTheme.panelFill : null,
                border: Border.all(
                  color: matched ? GamesTheme.good : GamesTheme.border,
                  width: matched ? 2 : 1.2,
                ),
              ),
              child: Center(
                child: up
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: card.isArabic
                            ? Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  card.face,
                                  style: names99ArabicStyle(28),
                                ),
                              )
                            : Text(
                                card.face,
                                style: AppText.titleMedium.copyWith(
                                  color: GamesTheme.champagne,
                                ),
                              ),
                      )
                    : const Icon(
                        Icons.stars_outlined,
                        color: AppColors.gold,
                        size: 30,
                      ),
              ),
            ),
          )),
        ),
      ),
    );
  }
}
