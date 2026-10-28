import '../../../app/core/scholar_review.dart';
import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/child_mode.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../sources/presentation/content_policy_screen.dart';
import '../data/game_history.dart';
import '../data/games_store.dart';
import '../engine/game_registry.dart';
import '../ui/games_art.dart';
import '../ui/games_theme.dart';

/// /games/g/:id - one game's page: what it is, how to play, the ways to play
/// it, where its content comes from, and Play.
class GameDetailsScreen extends ConsumerWidget {
  const GameDetailsScreen({required this.gameId, super.key});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GameDef? g = gameById(gameId);
    if (g == null) return const _UnknownGame();
    final GamesState store = ref.watch(gamesStoreProvider);
    GameResult? last;
    for (final GameResult r in store.results) {
      if (r.gameId == g.id) {
        last = r;
        break;
      }
    }
    final bool hasSaved = store.saved.any((SavedGame s) => s.gameId == g.id);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          ArchHeader(title: g.title),
          GameBanner(gameId: g.id),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Text(
              g.blurb,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                color: GamesTheme.champagne,
                height: 1.4,
              ),
            ),
          ),
          _Block(
            title: 'How to play',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int i = 0; i < g.howToPlay.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: 26,
                          child: Text(
                            '${i + 1}.',
                            style: AppText.body.copyWith(
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            g.howToPlay[i],
                            style: AppText.body.copyWith(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _Block(
            title: 'Ways to play',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final PlayMode m in PlayMode.values)
                  if (g.offersMode(m, child: kChildMode.value))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            m.label,
                            style: AppText.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: GamesTheme.champagne,
                            ),
                          ),
                          Text(
                            m.blurb,
                            style: AppText.bodyMuted.copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                if (g.hasHints)
                  Text(
                    'Hints are free: $kHintsPerGame a game, never bought and '
                    'never earned. There is no timer.',
                    style: AppText.bodyMuted.copyWith(height: 1.5),
                  ),
              ],
            ),
          ),
          if (g.sourceNote != null)
            _Block(
              title: 'Where the content comes from',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    g.sourceNote!,
                    style: AppText.body.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${ContentPolicyScreen.reviewStatus}. No named scholar '
                    'has reviewed the app yet.',
                    style: AppText.bodyMuted.copyWith(height: 1.5),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () => context.open(AppRoutes.sourcesPolicy),
                      child: const Text(
                        'How we treat religious content',
                        style: TextStyle(color: AppColors.goldLight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (last != null)
            _Block(
              title: 'Last time',
              child: Text(
                '${shortDate(last.finishedMs)}: ${last.summary}',
                style: AppText.body,
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: <Widget>[
          if (hasSaved)
            OutlineAction(
              label: 'Continue',
              icon: Icons.play_arrow_rounded,
              onPressed: () => context.open('/games/g/${g.id}/play?resume=1'),
            ),
          PlayButton(
            label: hasSaved ? 'New game' : 'Play',
            icon: Icons.play_arrow_rounded,
            onPressed: () =>
                context.open(g.hasSetup ? '/games/g/${g.id}/setup' : g.route),
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

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GamePanel(
        ornate: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                title,
                style: AppText.titleMedium.copyWith(
                  color: GamesTheme.champagne,
                ),
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _UnknownGame extends StatelessWidget {
  const _UnknownGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          const ScreenHeader(title: 'Game', showSettings: false),
          const ScholarReviewNote(
            reviewKey: 'games',
            padding: const EdgeInsets.only(bottom: 8),
          ),
          const SizedBox(height: 24),
          Text(
            'That game is not in this version of the app.',
            style: AppText.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: PlayButton(
              label: 'All games',
              onPressed: () => context.go(AppRoutes.games),
            ),
          ),
        ],
      ),
    );
  }
}
