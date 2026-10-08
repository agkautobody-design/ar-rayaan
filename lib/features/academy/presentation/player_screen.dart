/// The Ar-Rayaan Player — Now Playing + queue + mixes + browse.
/// Official catalog only (vocals-only by law); empty state is honest
/// until Pack 1 ships. Mood-reactive backdrop rides the atmosphere layer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../domain/atmosphere.dart';
import '../domain/player.dart';
import '../presentation/atmosphere_layer.dart';
import '../application/player_queue_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  String _facet = 'themes';
  String? _facetValue;

  @override
  Widget build(BuildContext context) {
    final PlayerQueue queue = ref.watch(playerQueueProvider);
    final catalogAsync = ref.watch(playerCatalogProvider);

    return Scaffold(
      body: AtmosphereLayer(
        emotion: _moodEmotion(queue.current?.mood),
        child: ScenicScaffold.pattern(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: <Widget>[
                const ScreenHeader(title: 'The Ar-Rayaan Player'),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.requestNasheed),
                  child: GlassCard(
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.favorite_border, color: AppColors.gold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Request a Nasheed',
                              style: AppText.titleMedium),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.gold),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.myAdditions),
                  child: GlassCard(
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.person_outline, color: AppColors.gold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('My Additions',
                              style: AppText.titleMedium),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.gold),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _NowPlayingCard(queue: queue),
                const SizedBox(height: 12),
                _MixesRow(),
                const SizedBox(height: 12),
                catalogAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('$e'),
                  data: (Catalog? catalog) {
                    if (catalog == null || catalog.tracks.isEmpty) {
                      return GlassCard(
                        child: Column(
                          children: <Widget>[
                            const Icon(Icons.music_note_outlined,
                                color: AppColors.gold, size: 30),
                            const SizedBox(height: 8),
                            Text('The library is being recorded',
                                style: AppText.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              'Pack 1 — commissioned naat and nasheed in '
                              'Arabic, Urdu, English and Indonesian — is '
                              'in production. Request a nasheed you love '
                              'and help us choose.',
                              style: AppText.bodyMuted,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    return _BrowseSection(
                      catalog: catalog,
                      facet: _facet,
                      facetValue: _facetValue,
                      onFacet: (String f, String? v) => setState(() {
                        _facet = f;
                        _facetValue = v;
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AtmosphereEmotion? _moodEmotion(String? mood) => switch (mood) {
        'morning' => AtmosphereEmotion.morning,
        'night' => AtmosphereEmotion.night,
        'study' => AtmosphereEmotion.peace,
        'travel' => AtmosphereEmotion.awe,
        'ramadan' => AtmosphereEmotion.solemn,
        _ => null,
      };
}

class _NowPlayingCard extends ConsumerWidget {
  const _NowPlayingCard({required this.queue});
  final PlayerQueue queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Track? t = queue.current;
    final notifier = ref.read(playerQueueProvider.notifier);
    return GlassCard(
      strong: true,
      child: Column(
        children: <Widget>[
          if (t == null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Nothing playing — choose a mix or a track.',
                  style: AppText.bodyMuted, textAlign: TextAlign.center),
            )
          else ...<Widget>[
            Text(t.title,
                style: AppText.titleMedium.copyWith(color: AppColors.gold),
                textAlign: TextAlign.center),
            Text('${t.artist}${t.poet != null ? ' · ${t.poet}' : ''}',
                style: AppText.caption, textAlign: TextAlign.center),
            if (t.licenseLine != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(t.licenseLine!,
                  style: AppText.caption, textAlign: TextAlign.center),
            ],
            if (t.lyricsLines.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              for (final String line in t.lyricsLines.take(3))
                Text(line,
                    style: AppText.bodyMuted, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: AppColors.gold),
                  onPressed: queue.index > 0
                      ? () => notifier.skipPrevious()
                      : null,
                ),
                IconButton(
                  iconSize: 40,
                  color: AppColors.gold,
                  icon: const Icon(Icons.play_circle_filled),
                  onPressed: () => notifier.resume(),
                ),
                IconButton(
                  icon: const Icon(Icons.pause_circle_filled,
                      color: AppColors.gold),
                  onPressed: () => notifier.pause(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: AppColors.gold),
                  onPressed: queue.index < queue.tracks.length - 1
                      ? () => notifier.skipNext()
                      : null,
                ),
              ],
            ),
            if (queue.playlistName != null)
              Text('Playlist: ${queue.playlistName}',
                  style: AppText.caption),
          ],
          if (queue.tracks.length > 1) ...<Widget>[
            const Divider(height: 20),
            for (var i = 0; i < queue.tracks.length && i < 6; i++)
              ListTile(
                dense: true,
                selected: i == queue.index,
                leading: Text('${i + 1}',
                    style: AppText.caption.copyWith(color: AppColors.gold)),
                title: Text(queue.tracks[i].title, style: AppText.body),
                onTap: () => notifier.playQueue(queue.tracks.sublist(i),
                    name: queue.playlistName),
              ),
          ],
        ],
      ),
    );
  }
}

class _MixesRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(playerCatalogProvider);
    return catalogAsync.maybeWhen(
      data: (Catalog? c) {
        if (c == null || c.tracks.isEmpty) return const SizedBox.shrink();
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Mixes', style: AppText.caption.copyWith(color: AppColors.gold)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                for (final String mood in Mixes.kMoods)
                  ActionChip(
                    label: Text(mood[0].toUpperCase() + mood.substring(1)),
                    onPressed: () => ref
                        .read(playerQueueProvider.notifier)
                        .playQueue(Mixes.seed(mood, c), name: mood),
                  ),
              ]),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _BrowseSection extends ConsumerWidget {
  const _BrowseSection({
    required this.catalog,
    required this.facet,
    required this.facetValue,
    required this.onFacet,
  });

  final Catalog catalog;
  final String facet;
  final String? facetValue;
  final void Function(String facet, String? value) onFacet;

  static const List<String> _facets = <String>[
    'themes', 'languages', 'artists', 'poets',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> values = switch (facet) {
      'themes' => catalog.themes,
      'languages' => catalog.languages,
      'artists' => catalog.artists,
      _ => catalog.poets,
    };
    final List<Track> shown = facetValue == null
        ? catalog.tracks
        : switch (facet) {
            'themes' => catalog.byTheme(facetValue!),
            'languages' => catalog.byLanguage(facetValue!),
            'artists' =>
              catalog.tracks.where((Track t) => t.artist == facetValue).toList(),
            _ => catalog.tracks
                .where((Track t) => t.poet == facetValue)
                .toList(),
          };
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(spacing: 6, children: <Widget>[
            for (final String f in _facets)
              ChoiceChip(
                label: Text(f[0].toUpperCase() + f.substring(1)),
                selected: facet == f,
                onSelected: (_) => onFacet(f, null),
              ),
          ]),
          if (values.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  for (final String v in values)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(v),
                        onPressed: () => onFacet(facet, v),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const Divider(height: 16),
          for (final Track t in shown.take(12))
            ListTile(
              dense: true,
              title: Text(t.title, style: AppText.body),
              subtitle: Text('${t.artist} · ${t.language}',
                  style: AppText.caption),
              trailing: const Icon(Icons.play_arrow,
                  color: AppColors.gold, size: 20),
              onTap: () {
                final int i = catalog.tracks.indexWhere((Track x) => x.id == t.id);
                ref.read(playerQueueProvider.notifier).playQueue(
                    catalog.tracks.sublist(i),
                    name: facetValue ?? facet);
              },
            ),
        ],
      ),
    );
  }
}
