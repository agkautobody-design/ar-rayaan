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
import '../engine/game_registry.dart';
import '../engine/order_engine.dart';
import '../ui/games_theme.dart';
import '../ui/learning_widgets.dart';
import 'game_results_screen.dart';

/// /games/g/:id/play for the ordering games: the Seerah timeline, Prophets in
/// Order, and the Wudu and Salah steps. No timer. A wrong check costs
/// nothing and can be repeated; hints are free. After each round it shows
/// why the order is right and where it comes from.
class OrderPlayScreen extends ConsumerStatefulWidget {
  const OrderPlayScreen({required this.gameId, this.topic, super.key});

  final String gameId;

  /// `wudu` or `salah` for the steps game.
  final String? topic;

  @override
  ConsumerState<OrderPlayScreen> createState() => _OrderPlayState();
}

class _OrderPlayState extends ConsumerState<OrderPlayScreen> {
  final Random _rnd = Random();
  OrderSession? _s;
  bool _loading = true;
  bool _failed = false;
  GameResult? _result;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
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
      final bool hints = ref.read(gameSettingsProvider).showHints;
      setState(() {
        _s = OrderSession(rounds, _rnd, hints: hints);
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
    setState(() => _result = r);
  }

  String get _title {
    final String base = _def?.title ?? 'Put in order';
    if (widget.gameId != 'salah-wudu') return base;
    return widget.topic == 'salah' ? 'Salah Steps' : 'Wudu Steps';
  }

  String get _slot => switch (widget.gameId) {
        'seerah-timeline' => 'seerah_timeline_board',
        'prophets-order' => 'prophets_order_board',
        _ => widget.topic == 'salah' ? 'salah_steps_board' : 'wudu_steps_board',
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
          ResultSummaryView(result: r),
          const SizedBox(height: 12),
          Text(
            'Every round could be repeated until it was right. This is only a '
            'count of rounds, not a measure of anything else.',
            textAlign: TextAlign.center,
            style: AppText.bodyMuted.copyWith(height: 1.5),
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
          if (settings.showHints && !s.solved) ...<Widget>[
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
                for (int p = 0; p < shown.length; p++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: p == shown.length - 1 ? 0 : 8,
                    ),
                    child: _OrderCard(
                      position: p,
                      count: shown.length,
                      item: shown[p],
                      palette: pal,
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

  String _askText(OrderRound r) {
    final String order = r.items.map((OrderItem i) => i.label).join(', then ');
    return clip(
      'I just played an ordering game. The right order was: $order. '
      'Can you explain why, and what the source says?',
      480,
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.position,
    required this.count,
    required this.item,
    required this.palette,
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
          color: palette.fill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: rightPlace ? palette.good : palette.border,
            width: rightPlace ? 2 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
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
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 16,
                    height: 1.35,
                    color: palette.text,
                  ),
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
                constraints: const BoxConstraints(
                  minWidth: GamesTheme.minTap,
                  minHeight: GamesTheme.minTap,
                ),
                onPressed: position == 0 ? null : onUp,
                icon: Icon(Icons.keyboard_arrow_up, color: palette.accent),
              ),
              IconButton(
                tooltip: 'Move down',
                constraints: const BoxConstraints(
                  minWidth: GamesTheme.minTap,
                  minHeight: GamesTheme.minTap,
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
