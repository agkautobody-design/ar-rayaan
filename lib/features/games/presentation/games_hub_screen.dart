import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/child_mode.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/whole_word_text.dart';
import '../../academy/application/academy_providers.dart';
import '../../elder/application/elder_mode.dart';
import '../data/game_history.dart';
import '../data/games_store.dart';
import '../engine/game_registry.dart';
import '../games_flags.dart';
import '../ui/games_art.dart';
import '../ui/games_theme.dart';

/// /games - the Games hub: filter chips, the person's own "Continue
/// playing", then a section for each kind of game. Every game on it comes
/// from the registry; nothing is rated, ranked or counted.
class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  HubFilter _filter = HubFilter.all;
  bool _elderMore = false;

  @override
  Widget build(BuildContext context) {
    final bool elder = ref.watch(elderModeProvider);
    final bool showAcademy = ref.watch(academyFlagProvider).valueOrNull ?? true;
    final GamesState store = ref.watch(gamesStoreProvider);
    final List<GameDef> games = visibleGames(showAcademy: showAcademy);
    // Child mode: only the short, curated list (see [kChildGameIds]).
    final bool childMode = kChildMode.value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: <Widget>[
          const ArchHeader(
            title: 'Games',
            tagline: 'Build your knowledge through play',
          ),
          if (childMode)
            ..._childBody(games)
          else if (elder)
            ..._elderBody(games, store)
          else
            ..._normalBody(games, store),
        ],
      ),
    );
  }

  /// Child mode: a short list of games for children, nothing else (no
  /// filters, no history, no settings, no friends, no unfinished-games strip).
  List<Widget> _childBody(List<GameDef> games) {
    final List<GameDef> mine = <GameDef>[
      for (final String id in kChildGameIds)
        for (final GameDef g in games)
          if (g.id == id) g,
    ];
    return <Widget>[
      const SizedBox(height: 4),
      for (final GameDef g in mine)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GameTile(game: g, large: true),
        ),
      const SizedBox(height: 8),
      Text(
        'No ads, no coins, no scores. Play as long as you like.',
        style: AppText.bodyMuted.copyWith(height: 1.5),
      ),
    ];
  }

  List<Widget> _normalBody(List<GameDef> games, GamesState store) {
    final List<GameDef> shown = gamesForFilter(games, _filter);
    final List<SavedGame> saved = <SavedGame>[
      for (final SavedGame s in store.saved)
        if (shown.any((GameDef g) => g.id == s.gameId)) s,
    ];
    return <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final HubFilter f in HubFilter.values)
            GameChip(
              label: f.label,
              selected: _filter == f,
              onTap: () => setState(() => _filter = f),
            ),
        ],
      ),
      if (saved.isNotEmpty) ...<Widget>[
        const SectionHeading(
          title: 'Continue playing',
          note: 'Games you started and did not finish',
        ),
        for (final SavedGame s in saved) _ContinueTile(saved: s),
      ],
      if (_filter == HubFilter.all)
        for (final GameCategory c in GameCategory.values)
          ..._section(
            c.label,
            c.sectionBlurb,
            <GameDef>[
              for (final GameDef g in shown)
                if (g.category == c) g,
            ],
            art: GamesArt.slotForCategory(c),
          )
      else
        ..._section(
          _filter.label,
          null,
          shown,
          art: switch (_filter) {
            HubFilter.islamic => ArtSlot.categoryIslamic,
            HubFilter.strategy => ArtSlot.categoryBoard,
            HubFilter.family => ArtSlot.categoryFamily,
            HubFilter.words => ArtSlot.categoryWords,
            HubFilter.all => null,
          },
        ),
      const SizedBox(height: 12),
      const GoldDivider(),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 10,
        children: <Widget>[
          OutlineAction(
            label: 'Game history',
            icon: Icons.history,
            onPressed: () => context.open('/games/history'),
          ),
          OutlineAction(
            label: 'Game settings',
            icon: Icons.tune,
            onPressed: () => context.open('/games/settings'),
          ),
          if (kGamesCommunityEnabled && !kChildMode.value)
            OutlineAction(
              label: 'Play with friends',
              icon: Icons.people_outline,
              onPressed: () => context.open('/games/community'),
            ),
        ],
      ),
      const SizedBox(height: 14),
      Text(
        'No ads, no coins, no ratings. Hints are free. Nothing here is '
        'scored by worship. Your history stays on this device.',
        style: AppText.bodyMuted.copyWith(height: 1.5),
      ),
    ];
  }

  List<Widget> _section(
    String title,
    String? note,
    List<GameDef> games, {
    ArtSlot? art,
  }) {
    if (games.isEmpty) return const <Widget>[];
    return <Widget>[
      SectionHeading(title: title, note: note, art: art),
      for (final GameDef g in games)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GameTile(game: g),
        ),
    ];
  }

  /// Elder Mode: three large cards and a button for the rest. No filters,
  /// no strip of unfinished games beyond one card, no small print.
  List<Widget> _elderBody(List<GameDef> games, GamesState store) {
    final List<GameDef> big = <GameDef>[
      for (final GameDef g in games)
        if (g.elderFeatured) g,
    ];
    final List<GameDef> rest = <GameDef>[
      for (final GameDef g in games)
        if (!g.elderFeatured) g,
    ];
    return <Widget>[
      const SizedBox(height: 4),
      if (store.saved.isNotEmpty) _ContinueTile(saved: store.saved.first),
      for (final GameDef g in big)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GameTile(game: g, large: true),
        ),
      const SizedBox(height: 4),
      OutlineAction(
        label: _elderMore ? 'Fewer games' : 'More games',
        icon: _elderMore ? Icons.expand_less : Icons.expand_more,
        onPressed: () => setState(() => _elderMore = !_elderMore),
      ),
      if (_elderMore) ...<Widget>[
        const SizedBox(height: 14),
        for (final GameDef g in rest)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GameTile(game: g, large: true),
          ),
      ],
    ];
  }
}

/// One game in the hub: a badge, the title and a line about it, and the
/// ways to play it. Opens the game's page.
class GameTile extends StatelessWidget {
  const GameTile({required this.game, this.large = false, super.key});

  final GameDef game;

  /// Bigger type and badge (Elder Mode).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final List<String> modes = <String>[
      for (final PlayMode m in PlayMode.values)
        if (game.offersMode(m, child: kChildMode.value)) m.label,
    ];
    // On a narrow or zoomed screen the picture and the chevron give their
    // room to the words: a title must never wrap one letter to a line.
    final bool squeezed = MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3;
    return GamePanel(
      semanticsLabel: '${game.title}. ${game.blurb}. ${modes.join(', ')}.',
      onTap: () => context.open('/games/g/${game.id}'),
      padding: EdgeInsets.all(large ? (squeezed ? 14 : 20) : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!squeezed) ...<Widget>[
            ArtThumb(
              gameId: game.id,
              iconKey: game.iconKey,
              size: large ? 64 : 52,
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                WholeWordText(
                  game.title,
                  style: AppText.titleMedium.copyWith(
                    color: GamesTheme.champagne,
                    fontSize: large ? 24 : 18,
                  ),
                ),
                const SizedBox(height: 2),
                WholeWordText(
                  game.blurb,
                  style: AppText.body.copyWith(
                    color: AppColors.textMuted,
                    fontSize: large ? 17 : 13,
                    height: 1.4,
                  ),
                ),
                if (!large) ...<Widget>[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      for (final String m in modes) _Tag(label: m),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!squeezed)
            const Padding(
              padding: EdgeInsets.only(top: 14, left: 4),
              child: Icon(Icons.chevron_right, color: AppColors.gold),
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(color: AppColors.goldLight),
      ),
    );
  }
}

/// An unfinished quiz: where you were, and a bar showing how far.
class _ContinueTile extends StatelessWidget {
  const _ContinueTile({required this.saved});

  final SavedGame saved;

  @override
  Widget build(BuildContext context) {
    final GameDef? g = gameById(saved.gameId);
    if (g == null) return const SizedBox.shrink();
    final String where = '${saved.answered} of ${saved.total} answered';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GamePanel(
        semanticsLabel: 'Continue ${g.title}. $where.',
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
                  const SizedBox(height: 2),
                  Text(where, style: AppText.bodyMuted),
                  const SizedBox(height: 8),
                  GameProgressBar(
                    value: saved.total == 0 ? 0 : saved.answered / saved.total,
                    label: where,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.play_arrow_rounded, color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}
