import 'dart:async' show unawaited;
import 'dart:math';

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
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
import '../engine/game_registry.dart';
import '../engine/order_engine.dart';
import '../ui/games_art.dart';
import '../ui/games_theme.dart';
import '../../hadi/data/hadi_game_ask.dart';
import '../ui/learning_widgets.dart';
import '../data/race_link.dart';
import 'game_results_screen.dart';
import 'race_banner.dart';

/// /games/g/:id/play for the ordering games: the Seerah timeline, Prophets in
/// Order, and the Wudu and Salah steps. No timer. A wrong check costs
/// nothing and can be repeated; hints are free. After each round it shows
/// why the order is right and where it comes from.
class OrderPlayScreen extends ConsumerStatefulWidget {
  const OrderPlayScreen({
    required this.gameId,
    this.topic,
    this.raceCode,
    this.raceSide,
    this.seed,
    super.key,
  });

  /// Racing a friend online (see [RaceLink]): table code, side, shared seed.
  final String? raceCode;
  final String? raceSide;
  final int? seed;

  final String gameId;

  /// `wudu` or `salah` for the steps game.
  final String? topic;

  @override
  ConsumerState<OrderPlayScreen> createState() => _OrderPlayState();
}

class _OrderPlayState extends ConsumerState<OrderPlayScreen> {
  late final Random _rnd =
      widget.seed != null ? Random(widget.seed) : Random();
  RaceLink? _race;
  OrderSession? _s;
  final Stopwatch _clock = Stopwatch();
  bool _loading = true;
  bool _failed = false;
  GameResult? _result;

  @override
  void initState() {
    super.initState();
    final String? code = widget.raceCode;
    if (code != null && widget.raceSide != null) {
      _race = RaceLink(
        code: code,
        side: widget.raceSide!,
        startN: widget.raceSide == 'host' ? 1 : 0,
      )..listen();
    }
    unawaited(_load());
  }

  @override
  void dispose() {
    final RaceLink? r = _race;
    if (r != null) {
      if (_result == null || r.state.value.opponent.finished) {
        unawaited(r.leave());
      }
      r.dispose();
    }
    super.dispose();
  }

  GameDef? get _def => gameById(widget.gameId);

  Future<void> _load() async {
    try {
      final List<OrderRound> rounds = await LearningLoader.orderRounds(
        widget.gameId,
        widget.topic ?? 'wudu',
        _rnd,
      );
      if (rounds.isEmpty) throw StateError('no rounds');
      if (!mounted) return;
      final bool hints =
          _race == null && ref.read(gameSettingsProvider).showHints;
      setState(() {
        _s = OrderSession(rounds, _rnd, hints: hints);
        _clock
          ..reset()
          ..start();
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _failed = false;
    });
    unawaited(_load());
  }

  void _check() {
    final OrderSession s = _s!;
    s.check();
    gameHaptic(ref);
    setState(() {});
    if (s.solved) {
      unawaited(_race?.report(s.index + 1, s.total, s.firstTry) ??
          Future<void>.value());
    }
  }

  void _finish() {
    final OrderSession s = _s!;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final GameResult r = GameResult(
      id: '${widget.gameId}-$now',
      gameId: widget.gameId,
      title: _title,
      finishedMs: now,
      outcome: '${s.firstTry} of ${s.total} rounds right on the first check',
    );
    unawaited(ref.read(gamesStoreProvider.notifier).record(r));
    unawaited(_race?.finish(s.total, s.firstTry) ?? Future<void>.value());
    setState(() => _result = r);
  }

  String get _title {
    final String base = _def?.title ?? 'Put in order';
    if (widget.gameId != 'salah-wudu') return base;
    return widget.topic == 'salah' ? 'Salah Steps' : 'Wudu Steps';
  }

  ArtSlot get _slot => switch (widget.gameId) {
        'seerah-timeline' => ArtSlot.seerahTimelineBoard,
        'prophets-order' => ArtSlot.prophetsOrderBoard,
        'hajj-map' => ArtSlot.hajjMap,
        'islamic-history' => ArtSlot.seerahTimelineBoard,
        _ => widget.topic == 'salah'
            ? ArtSlot.salahStepsBoard
            : ArtSlot.wuduStepsBoard,
      };

  @override
  Widget build(BuildContext context) {
    final String title = _title;
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            ScreenHeader(title: title, close: true, showSettings: false),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ),
          ],
        ),
      );
    }
    final OrderSession? s = _s;
    if (_failed || s == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            ScreenHeader(title: title, close: true, showSettings: false),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'The rounds could not be made. Please try again.',
                        textAlign: TextAlign.center,
                        style: AppText.body,
                      ),
                      const SizedBox(height: 16),
                      PlayButton(label: 'Try again', onPressed: _retry),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final GameResult? done = _result;
    if (done != null) return _finishedPage(done, title);
    return _roundPage(s, title);
  }

  Widget _finishedPage(GameResult r, String title) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          ScreenHeader(title: title, close: true, showSettings: false),
          if (_race != null)
            RaceBanner(
              link: _race!,
              myScore: _s?.firstTry ?? 0,
              myTotal: _s?.total ?? 0,
              iFinished: true,
            ),
          _OrderResult(
            title: title,
            session: _s!,
            elapsed: _clock.elapsed,
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: <Widget>[
          PlayButton(
            label: 'Play again',
            icon: Icons.replay,
            onPressed: () => context.go(
              _def?.hasSetup ?? false
                  ? '/games/g/${widget.gameId}/setup'
                  : '/games/g/${widget.gameId}/play',
            ),
          ),
          OutlineAction(
            label: 'All games',
            onPressed: () => context.go(AppRoutes.games),
          ),
        ],
      ),
    );
  }

  Widget _roundPage(OrderSession s, String title) {
    final GameSettings settings = ref.watch(gameSettingsProvider);
    final GamePalette pal = GamePalette.of(settings.theme);
    final OrderRound round = s.round;
    final List<OrderItem> shown = s.shown;
    final bool wrongShown = !s.solved && s.misses > 0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          ScreenHeader(title: title, close: true, showSettings: false),
          if (_race != null)
            RaceBanner(link: _race!, myScore: s.firstTry, myTotal: s.total),
          Text('ROUND ${s.index + 1} OF ${s.total}', style: AppText.eyebrow),
          const SizedBox(height: 8),
          GameProgressBar(
            value: (s.index + (s.solved ? 1 : 0)) / s.total,
            label: 'Round ${s.index + 1} of ${s.total}',
          ),
          const SizedBox(height: 12),
          Text(
            round.prompt,
            style: AppText.body.copyWith(fontSize: 17, height: 1.5),
          ),
          if (settings.showHints && _race == null && !s.solved) ...<Widget>[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlineAction(
                label: s.hintsLeft > 0
                    ? 'Hint (${s.hintsLeft} left)'
                    : 'No hints left',
                icon: Icons.lightbulb_outline,
                onPressed: s.canUseHint
                    ? () {
                        s.useHint();
                        gameHaptic(ref);
                        setState(() {});
                      }
                    : null,
              ),
            ),
          ],
          const SizedBox(height: 12),
          GameBoardBackdrop(
            slot: _slot,
            palette: pal,
            child: Column(
              children: <Widget>[
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: shown.length,
                  proxyDecorator: (Widget child, int i, Animation<double> a) =>
                      Material(color: Colors.transparent, child: child),
                  onReorder: (int from, int to) {
                    if (s.solved) return;
                    int at = from;
                    final int target = to > from ? to - 1 : to;
                    bool moved = false;
                    while (at < target && s.moveDown(at)) {
                      at++;
                      moved = true;
                    }
                    while (at > target && s.moveUp(at)) {
                      at--;
                      moved = true;
                    }
                    if (moved) {
                      gameHaptic(ref);
                      setState(() {});
                    }
                  },
                  itemBuilder: (BuildContext context, int p) => Padding(
                    key: ValueKey<String>(shown[p].id),
                    padding: EdgeInsets.only(
                      bottom: p == shown.length - 1 ? 0 : 8,
                    ),
                    child: _OrderCard(
                      position: p,
                      count: shown.length,
                      item: shown[p],
                      palette: pal,
                      art: _artPath(shown[p]),
                      showDetail: s.solved,
                      locked: s.locked.contains(p),
                      solved: s.solved,
                      rightPlace: (wrongShown || s.solved) &&
                          s.arrangement[p] == p,
                      onUp: () {
                        if (s.moveUp(p)) {
                          gameHaptic(ref);
                          setState(() {});
                        }
                      },
                      onDown: () {
                        if (s.moveDown(p)) {
                          gameHaptic(ref);
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (wrongShown) ...<Widget>[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                '${s.rightPlaces} of ${shown.length} are in the right place. '
                'Move the others and check again. There is no limit.',
                style: AppText.body.copyWith(height: 1.5),
              ),
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
                          'In the right order',
                          style: AppText.titleMedium.copyWith(
                            color: GamesTheme.champagne,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    round.explanation,
                    style: AppText.body.copyWith(height: 1.5),
                  ),
                  if (round.note != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      round.note!,
                      style: AppText.bodyMuted.copyWith(height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Source: ${round.citation}',
                    style: AppText.bodyMuted.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  AskHadiAboutButton(question: _askText(round)),
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
              label: 'Check order',
              icon: Icons.check,
              onPressed: _check,
            )
          else
            PlayButton(
              label: s.isLast ? 'See results' : 'Next round',
              icon: Icons.arrow_forward,
              onPressed: () {
                if (s.isLast) {
                  _finish();
                } else if (s.next()) {
                  setState(() {});
                }
              },
            ),
        ],
      ),
    );
  }

  /// A name for a card's picture: the words of its label, lower case, joined
  /// by dashes ("Wash hands" is "wash-hands").
  static String _slug(String label) => label
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  /// Where the card's picture lives, once one has been supplied:
  /// assets/games/order/<game>/<slug>.webp. Cards without one show no picture.
  String _artPath(OrderItem i) =>
      'assets/games/order/${widget.gameId}/${_slug(i.label)}.webp';

  String _askText(OrderRound r) => HadiGameAsk.order(
        items: <String>[for (final OrderItem i in r.items) i.label],
        explanation: r.explanation,
        citation: r.citation,
      );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.position,
    required this.count,
    required this.item,
    required this.palette,
    required this.art,
    required this.showDetail,
    required this.locked,
    required this.solved,
    required this.rightPlace,
    required this.onUp,
    required this.onDown,
  });

  final int position;
  final int count;
  final OrderItem item;
  final GamePalette palette;
  final String art;
  final bool showDetail;
  final bool locked;
  final bool solved;
  final bool rightPlace;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    final bool canMove = !solved && !locked;
    return Semantics(
      container: true,
      label: 'Place ${position + 1} of $count: ${item.label}'
          '${locked ? '. Fixed by a hint' : ''}'
          '${rightPlace ? '. In the right place' : ''}',
      child: Container(
        constraints: const BoxConstraints(minHeight: GamesTheme.minTap),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 4, 6),
        decoration: BoxDecoration(
          color: palette.fill.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: rightPlace ? palette.good : palette.border,
            width: rightPlace ? 2 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            if (canMove)
              ReorderableDragStartListener(
                index: position,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ExcludeSemantics(
                    child: Icon(Icons.drag_indicator,
                        size: 22, color: palette.accent),
                  ),
                ),
              ),
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  art,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (BuildContext c, Object e, StackTrace? st) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
            ExcludeSemantics(
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.accent),
                ),
                child: Text(
                  '${position + 1}',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.label,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 16,
                        height: 1.35,
                        color: palette.text,
                      ),
                    ),
                    if (showDetail && item.detail != null)
                      Text(
                        item.detail!,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          height: 1.35,
                          color: palette.text.withValues(alpha: 0.75),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (locked)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.lock_outline, size: 20, color: palette.accent),
              )
            else if (rightPlace)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.check_circle, size: 20, color: palette.good),
              ),
            if (canMove) ...<Widget>[
              IconButton(
                tooltip: 'Move up',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 56,
                  minHeight: 56,
                ),
                onPressed: position == 0 ? null : onUp,
                icon: Icon(Icons.keyboard_arrow_up, color: palette.accent),
              ),
              IconButton(
                tooltip: 'Move down',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 56,
                  minHeight: 56,
                ),
                onPressed: position == count - 1 ? null : onDown,
                icon: Icon(Icons.keyboard_arrow_down, color: palette.accent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


/// The finish page, as designed: a heading, steps and accuracy and time, then
/// every round in its right order.
class _OrderResult extends StatelessWidget {
  const _OrderResult({
    required this.title,
    required this.session,
    required this.elapsed,
  });

  final String title;
  final OrderSession session;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final int total = session.total;
    final int first = session.firstTry;
    final int pct = total == 0 ? 0 : (first * 100 / total).round();
    final String time =
        '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    Widget stat(IconData icon, String big, String small) => Expanded(
          child: Column(
            children: <Widget>[
              Icon(icon, color: AppColors.goldLight),
              const SizedBox(height: 4),
              Text(big, style: AppText.titleMedium),
              Text(small, style: AppText.caption, textAlign: TextAlign.center),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        Text('$title complete',
            textAlign: TextAlign.center, style: AppText.displayMedium),
        const SizedBox(height: 6),
        Text(
          first == total
              ? 'Alhamdulillah! Every round was right on the first check.'
              : 'Well done. Every round is now in its right order.',
          textAlign: TextAlign.center,
          style: AppText.bodyMuted.copyWith(height: 1.5),
        ),
        const SizedBox(height: 14),
        GamePanel(
          child: Row(
            children: <Widget>[
              stat(Icons.layers_outlined, '$first/$total', 'Right first check'),
              stat(Icons.track_changes, '$pct%', 'Accuracy'),
              stat(Icons.timer_outlined, time, 'Time taken'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionHeading(title: 'The correct order'),
        for (final OrderRound r in session.rounds)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GamePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(r.prompt,
                      style: AppText.bodyMuted.copyWith(height: 1.4)),
                  const SizedBox(height: 8),
                  for (int k = 0; k < r.items.length; k++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${k + 1}. ${r.items[k].label}',
                          style: AppText.body),
                    ),
                  const SizedBox(height: 6),
                  Text(r.explanation,
                      style: AppText.bodyMuted.copyWith(height: 1.5)),
                  const SizedBox(height: 4),
                  Text('Source: ${r.citation}', style: AppText.caption),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
