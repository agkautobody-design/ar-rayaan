import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../data/game_history.dart';
import '../data/games_store.dart';
import '../engine/game_registry.dart';
import '../engine/quiz_engine.dart';
import '../ui/games_art.dart';
import '../ui/games_theme.dart';

/// The score of a finished game in plain words: "8 of 10", never a rank,
/// a trophy or a measure of faith. A game played together on one device is
/// shown as played together, in turn order, not ordered by score.
class ResultSummaryView extends StatelessWidget {
  const ResultSummaryView({required this.result, super.key});

  final GameResult result;

  @override
  Widget build(BuildContext context) {
    final bool together =
        result.players > 1 && result.playerScores.isNotEmpty;
    final bool memory = result.gameId == 'memory';
    final bool shortSummary = result.summary.length <= 12;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 12),
        const ResultTrophyArt(),
        Center(child: Text('FINISHED', style: AppText.eyebrow)),
        const SizedBox(height: 6),
        Center(
          child: Semantics(
            label: 'Result: ${result.summary}',
            child: ExcludeSemantics(
              child: Text(
                result.summary,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: shortSummary ? 44 : 26,
                  color: AppColors.goldLight,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          <String>[
            result.title,
            if (result.difficulty != null) result.difficulty!,
            shortDate(result.finishedMs),
          ].join(' · '),
          textAlign: TextAlign.center,
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: 6),
        // A zero is met kindly: the game is for learning, not for a mark.
        Text(
          RegExp(r'^0\b').hasMatch(result.summary)
              ? 'Every try teaches something. Have another go whenever you like.'
              : 'Well done for finishing. Play again whenever you like.',
          textAlign: TextAlign.center,
          style: AppText.body,
        ),
        const GoldDivider(),
        if (together) ...<Widget>[
          const SizedBox(height: 6),
          GamePanel(
            ornate: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Played together',
                  style: AppText.titleMedium.copyWith(
                    color: GamesTheme.champagne,
                  ),
                ),
                const SizedBox(height: 8),
                for (int p = 0; p < result.playerScores.length; p++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      memory
                          ? 'Player ${p + 1}: ${result.playerScores[p]} pairs'
                          : 'Player ${p + 1}: ${result.playerScores[p]} of '
                              '${questionsFor(result.total ?? 0, result.players, p)}',
                      style: AppText.body,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Every question with the answer given, the right answer, the reason and
/// the source.
class QuizReviewList extends StatelessWidget {
  const QuizReviewList({required this.session, super.key});

  final QuizSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < session.total; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ReviewCard(session: session, i: i),
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.session, required this.i});

  final QuizSession session;
  final int i;

  @override
  Widget build(BuildContext context) {
    final QuizQuestion q = session.questions[i];
    final int? pick = session.picks[i];
    final bool right = pick == q.answer;
    final String who = session.config.players > 1
        ? 'Player ${i % session.config.players + 1} · '
        : '';
    return GamePanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${who}QUESTION ${i + 1} · '
            '${pick == null ? 'NOT ANSWERED' : right ? 'CORRECT' : 'MISSED'}',
            style: AppText.eyebrow,
          ),
          const SizedBox(height: 6),
          Text(q.prompt, style: AppText.body.copyWith(height: 1.5)),
          const SizedBox(height: 8),
          if (pick != null && !right)
            Text(
              'Answer given: ${q.options[pick]}',
              style: AppText.bodyMuted,
            ),
          Text(
            'Right answer: ${q.options[q.answer]}',
            style: AppText.body.copyWith(color: AppColors.goldLight),
          ),
          const SizedBox(height: 6),
          Text(q.explanation, style: AppText.bodyMuted.copyWith(height: 1.5)),
          const SizedBox(height: 4),
          Text(
            'Source: ${q.citation}',
            style: AppText.bodyMuted.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// /games/g/:id/results?rid=... - a finished game from the history.
class GameResultScreen extends ConsumerWidget {
  const GameResultScreen({required this.gameId, this.resultId, super.key});

  final String gameId;
  final String? resultId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GamesState store = ref.watch(gamesStoreProvider);
    GameResult? r;
    for (final GameResult e in store.results) {
      if (e.id == resultId) r = e;
    }
    final GameDef? g = gameById(gameId);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          const ScreenHeader(title: 'Result', showSettings: false),
          if (r == null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                'This result is no longer on this device.',
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
            )
          else
            ResultSummaryView(result: r),
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: <Widget>[
          if (g != null)
            PlayButton(
              label: 'Play again',
              icon: Icons.replay,
              onPressed: () => context
                  .open(g.hasSetup ? '/games/g/${g.id}/setup' : g.route),
            ),
          OutlineAction(
            label: 'Game history',
            onPressed: () => context.open('/games/history'),
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
