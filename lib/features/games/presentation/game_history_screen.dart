import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../data/game_history.dart';
import '../data/games_store.dart';
import '../engine/game_registry.dart';
import '../ui/games_art.dart';
import '../ui/games_theme.dart';

/// /games/history - the games finished on this device, and the ones left
/// half-way. Local only: nothing here is sent anywhere.
class GameHistoryScreen extends ConsumerStatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  ConsumerState<GameHistoryScreen> createState() => _GameHistoryState();
}

class _GameHistoryState extends ConsumerState<GameHistoryScreen> {
  HistoryFilter _filter = HistoryFilter.all;

  Future<void> _confirmClear() async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        semanticLabel: 'Clear game history?',
        backgroundColor: AppColors.navy,
        title: Text('Clear game history?', style: AppText.titleMedium),
        content: Text(
          'This removes every finished and unfinished game from this '
          'device. It cannot be undone.',
          style: AppText.body,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Keep it',
              style: TextStyle(color: AppColors.goldLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      unawaited(ref.read(gamesStoreProvider.notifier).clearAll());
    }
  }

  @override
  Widget build(BuildContext context) {
    final GamesState store = ref.watch(gamesStoreProvider);
    final List<SavedGame> saved = <SavedGame>[
      for (final SavedGame s in store.saved)
        if (_filter == HistoryFilter.all ||
            _filter == HistoryFilter.ongoing ||
            (_filter == HistoryFilter.islamic &&
                gameById(s.gameId)?.category == GameCategory.islamic))
          s,
    ];
    final List<GameResult> results = <GameResult>[
      for (final GameResult r in store.results)
        if (_filter == HistoryFilter.all ||
            _filter == HistoryFilter.completed ||
            (_filter == HistoryFilter.islamic && r.isIslamic))
          r,
    ];
    final bool empty = saved.isEmpty && results.isEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          const ArchHeader(
            title: 'Game history',
            tagline: 'Kept on this device only',
            band: true,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final HistoryFilter f in HistoryFilter.values)
                GameChip(
                  label: f.label,
                  selected: _filter == f,
                  onTap: () => setState(() => _filter = f),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (empty)
            GamePanel(
              child: Text(
                _filter == HistoryFilter.all
                    ? 'No games yet. When you finish a game it appears here, '
                        'on this device only.'
                    : 'Nothing here yet.',
                style: AppText.body.copyWith(height: 1.5),
              ),
            ),
          for (final SavedGame s in saved) _SavedRow(saved: s),
          for (final GameResult r in results) _ResultRow(result: r),
          if (store.results.isNotEmpty || store.saved.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Center(
              child: OutlineAction(
                label: 'Clear history',
                icon: Icons.delete_outline,
                onPressed: _confirmClear,
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: <Widget>[
          PlayButton(
            label: 'All games',
            icon: Icons.sports_esports_outlined,
            onPressed: () => context.go(AppRoutes.games),
          ),
        ],
      ),
    );
  }
}

class _SavedRow extends StatelessWidget {
  const _SavedRow({required this.saved});

  final SavedGame saved;

  @override
  Widget build(BuildContext context) {
    final GameDef? g = gameById(saved.gameId);
    if (g == null) return const SizedBox.shrink();
    final String line = 'Not finished: ${saved.answered} of ${saved.total} '
        'answered, ${shortDate(saved.savedMs)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GamePanel(
        semanticsLabel: 'Continue ${g.title}. $line.',
        onTap: () => context.open('/games/g/${g.id}/play?resume=1'),
        child: Row(
          children: <Widget>[
            ArtThumb(gameId: g.id, iconKey: g.iconKey, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    g.title,
                    style: AppText.titleMedium.copyWith(
                      color: GamesTheme.champagne,
                    ),
                  ),
                  Text(line, style: AppText.bodyMuted),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Continue',
              style: AppText.label.copyWith(color: AppColors.goldLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result});

  final GameResult result;

  @override
  Widget build(BuildContext context) {
    final GameDef? g = gameById(result.gameId);
    final String line = <String>[
      shortDate(result.finishedMs),
      result.summary,
      if (result.difficulty != null) result.difficulty!,
      if (result.players > 1) '${result.players} players',
    ].where((String e) => e.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GamePanel(
        semanticsLabel: '${result.title}. $line.',
        onTap: () => context.open(
          '/games/g/${result.gameId}/results'
          '?rid=${Uri.encodeQueryComponent(result.id)}',
        ),
        child: Row(
          children: <Widget>[
            ArtThumb(
              gameId: result.gameId,
              iconKey: g?.iconKey ?? '',
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    result.title,
                    style: AppText.titleMedium.copyWith(
                      color: GamesTheme.champagne,
                    ),
                  ),
                  Text(line, style: AppText.bodyMuted),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}
