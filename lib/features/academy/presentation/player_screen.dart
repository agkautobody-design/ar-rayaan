/// The Ar-Rayaan Player — Now Playing + queue + mixes + browse.
/// Official catalog only (vocals-only by law); empty state is honest
/// until Pack 1 ships. Mood-reactive backdrop rides the atmosphere layer.
library;

import '../../downloads/domain/download_catalog.dart' show kNasheedNoDownloadNote;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/core/safe_url.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../domain/atmosphere.dart';
import '../domain/player.dart';
import '../presentation/atmosphere_layer.dart';
import '../application/player_queue_provider.dart';
import '../application/stream_player_provider.dart';
import '../data/player_sources_pack.dart';
import 'add_to_playlist_sheet.dart';
import 'stream_player_panel.dart';
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
    // One player at a time: while a YouTube / Spotify link plays in its
    // panel, the (paused) bundled-audio card is not shown beside it.
    final bool streaming = ref.watch(streamQueueProvider).current != null;

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
                GestureDetector(
                  onTap: () => context.push(AppRoutes.myPlaylists),
                  child: GlassCard(
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.queue_music, color: AppColors.gold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('My Playlists',
                              style: AppText.titleMedium),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.gold),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Why there is no Download button on a nasheed.
                GlassCard(
                  key: const Key('player-no-download'),
                  child: Text(
                    kNasheedNoDownloadNote,
                    style: AppText.caption.copyWith(height: 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                const StreamPlayerPanel(),
                const SizedBox(height: 12),
                if (!streaming) ...<Widget>[
                  _NowPlayingCard(queue: queue),
                  const SizedBox(height: 12),
                ],
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
                            Text('No nasheed library yet',
                                style: AppText.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              'No licensed nasheed library is bundled yet. '
                              'Until one is, nasheeds are links to outside '
                              'sites. Request a nasheed you love and help '
                              'us choose.',
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
                IconButton(tooltip: 'Previous track',
                  icon: const Icon(Icons.skip_previous, color: AppColors.gold),
                  onPressed: queue.index > 0
                      ? () => notifier.skipPrevious()
                      : null,
                ),
                IconButton(tooltip: 'Play',
                  iconSize: 40,
                  color: AppColors.gold,
                  icon: const Icon(Icons.play_circle_filled),
                  onPressed: () => notifier.resume(),
                ),
                IconButton(tooltip: 'Pause',
                  icon: const Icon(Icons.pause_circle_filled,
                      color: AppColors.gold),
                  onPressed: () => notifier.pause(),
                ),
                IconButton(tooltip: 'Next track',
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
              Material(
            color: Colors.transparent,
            child: ListTile(
                dense: true,
                selected: i == queue.index,
                leading: Text('${i + 1}',
                    style: AppText.caption.copyWith(color: AppColors.gold)),
                title: Text(queue.tracks[i].title, style: AppText.body),
                onTap: () => notifier.playQueue(queue.tracks.sublist(i),
                    name: queue.playlistName),
              )),
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
        final List<String> moods = <String>[
          for (final String m in Mixes.kMoods)
            if (Mixes.seed(m, c, count: 1).isNotEmpty) m,
        ];
        // No mix has audio yet: say nothing rather than show dead chips.
        if (moods.isEmpty) return const SizedBox.shrink();
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Mixes', style: AppText.caption.copyWith(color: AppColors.gold)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                for (final String mood in moods)
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

class _BrowseSection extends ConsumerStatefulWidget {
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
  ConsumerState<_BrowseSection> createState() => _BrowseSectionState();
}

class _BrowseSectionState extends ConsumerState<_BrowseSection> {
  static const int _page = 25;
  int _limit = _page;

  /// The person's choice for the "Plays here" filter; null means "use the
  /// default" (on when at least one track plays in the app).
  bool? _onlyHere;

  /// Search text, occasion and voice-only filters for the larger catalogue.
  String _query = '';
  String? _occasion;
  bool _vocalsOnly = false;

  void _say(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Every tap does something you can see: it plays here, or says it is
  /// opening YouTube (a new tab on the web) before it does.
  Future<void> _tapTrack(
    Track t,
    List<Track> shown,
    Map<String, TrackSources> sources, {
    required String name,
  }) async {
    if (t.hasAudio) {
      final List<Track> playable =
          shown.where((Track x) => x.hasAudio).toList();
      final int i = playable.indexWhere((Track x) => x.id == t.id);
      ref.read(streamQueueProvider.notifier).stop();
      await ref
          .read(playerQueueProvider.notifier)
          .playQueue(playable.sublist(i < 0 ? 0 : i), name: name);
      if (!mounted) return;
      _say('Playing \u201c${t.title}\u201d. Controls are at the top of the '
          'page.');
      return;
    }
    final TrackSources? src = sources[t.id];
    if (src != null && src.preferred != null) {
      final List<StreamEntry> entries = <StreamEntry>[
        for (final Track x in shown)
          if (!x.hasAudio && sources[x.id]?.preferred != null)
            StreamEntry(
                title: x.title,
                artist: x.artist,
                link: sources[x.id]!.preferred!),
      ];
      final int at = entries.indexWhere(
          (StreamEntry e) => e.title == t.title && e.artist == t.artist);
      await playStreamEntries(ref, entries, at < 0 ? 0 : at);
      if (!mounted) return;
      _say('Playing \u201c${t.title}\u201d in the player at the top of the '
          'page.');
      return;
    }
    final Uri? official = SafeUrl.web(t.officialUrl);
    if (!t.hasOfficialLink || official == null) {
      _say('There is no link for \u201c${t.title}\u201d yet.');
      return;
    }
    _say('Opens a YouTube search in your browser');
    bool opened = false;
    try {
      opened = await launchUrl(official, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      _say('Could not open YouTube. If your browser blocked the new tab, '
          'allow pop-ups for this site.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Catalog catalog = widget.catalog;
    final String facet = widget.facet;
    final String? facetValue = widget.facetValue;
    final List<String> values = switch (facet) {
      'themes' => catalog.themes,
      'languages' => catalog.languages,
      'artists' => catalog.artists,
      _ => catalog.poets,
    };
    final List<Track> faceted = facetValue == null
        ? catalog.tracks
        : switch (facet) {
            'themes' => catalog.byTheme(facetValue),
            'languages' => catalog.byLanguage(facetValue),
            'artists' =>
              catalog.tracks.where((Track t) => t.artist == facetValue).toList(),
            _ => catalog.tracks
                .where((Track t) => t.poet == facetValue)
                .toList(),
          };
    final String q = _query.trim().toLowerCase();
    final List<String> occasions = catalog.tracks
        .map((Track t) => t.occasion)
        .where((String o) => o != 'general')
        .toSet()
        .toList()
      ..sort();
    final List<Track> filtered = faceted.where((Track t) {
      if (_occasion != null && t.occasion != _occasion) return false;
      if (_vocalsOnly && !t.isVocalsOnly) return false;
      if (q.isEmpty) return true;
      return t.title.toLowerCase().contains(q) ||
          t.artist.toLowerCase().contains(q);
    }).toList();
    final Map<String, TrackSources> sources =
        ref.watch(playerSourcesProvider).valueOrNull ??
            const <String, TrackSources>{};
    bool playsHere(Track t) => t.hasAudio || sources[t.id]?.preferred != null;
    final int playableCount = catalog.tracks.where(playsHere).length;
    final int playableInView = filtered.where(playsHere).length;
    final bool onlyHere = _onlyHere ?? playableCount > 0;
    // Tracks the app can play come first (own audio, then approved
    // YouTube / Spotify sources); the rest open a YouTube search.
    final List<Track> ordered = <Track>[
      ...filtered.where((Track t) => t.hasAudio),
      ...filtered
          .where((Track t) => !t.hasAudio && sources[t.id]?.preferred != null),
      ...filtered.where((Track t) => !playsHere(t)),
    ];
    final List<Track> shown =
        onlyHere ? ordered.where(playsHere).toList() : ordered;
    final int visible = shown.length < _limit ? shown.length : _limit;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            playableCount == 0
                ? 'None of these ${catalog.tracks.length} tracks play in the '
                    'app yet. Each one opens a YouTube search in your '
                    'browser. Ar-Rayaan does not host them.'
                : '$playableCount of ${catalog.tracks.length} tracks play '
                    'here, from the official channel. The rest open a '
                    'YouTube search in your browser. Ar-Rayaan does not host '
                    'or download them. \u201cVoice only\u201d is shown only '
                    'when the official upload says so; other tracks may use '
                    'instruments.',
            key: const Key('player-catalog-note'),
            style: AppText.caption,
          ),
          const SizedBox(height: 8),
          if (playableCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilterChip(
                key: const Key('player-plays-here'),
                label: Text('Plays here ($playableInView)'),
                selected: onlyHere,
                onSelected: (bool v) => setState(() {
                  _onlyHere = v;
                  _limit = _page;
                }),
              ),
            ),
          Wrap(spacing: 6, children: <Widget>[
            for (final String f in _BrowseSection._facets)
              ChoiceChip(
                label: Text(f[0].toUpperCase() + f.substring(1)),
                selected: facet == f,
                onSelected: (_) {
                  setState(() => _limit = _page);
                  widget.onFacet(f, null);
                },
              ),
          ]),
          if (values.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            SizedBox(
              height: 34,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: values.length,
                itemBuilder: (BuildContext context, int i) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(values[i]),
                    onPressed: () {
                      setState(() => _limit = _page);
                      widget.onFacet(facet, values[i]);
                    },
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Semantics(label: 'Search title or artist', child: TextField(
            key: const Key('player-search'),
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search),
              hintText: 'Search title or artist',
            ),
            onChanged: (String v) => setState(() {
              _query = v;
              _limit = _page;
            }),
          )),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, children: <Widget>[
            FilterChip(
              key: const Key('player-vocals-only'),
              label: const Text('Vocals / duff only'),
              selected: _vocalsOnly,
              onSelected: (bool v) => setState(() {
                _vocalsOnly = v;
                _limit = _page;
              }),
            ),
            for (final String o in occasions)
              FilterChip(
                label: Text(o[0].toUpperCase() + o.substring(1)),
                selected: _occasion == o,
                onSelected: (bool v) => setState(() {
                  _occasion = v ? o : null;
                  _limit = _page;
                }),
              ),
          ]),
          const Divider(height: 16),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                onlyHere
                    ? 'Nothing here plays in the app. Turn off \u201cPlays '
                        'here\u201d to see tracks that open YouTube.'
                    : 'No tracks here.',
                key: const Key('player-empty-view'),
                style: AppText.bodyMuted,
              ),
            ),
          for (final Track t in shown.take(visible))
            Material(
              color: Colors.transparent,
              child: ListTile(
                dense: true,
                title: Text(t.title, style: AppText.body),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      _PlayBadge(
                        here: playsHere(t),
                        service: t.hasAudio
                            ? null
                            : sources[t.id]?.preferred?.serviceLabel,
                      ),
                      Text('${t.artist} \u00b7 ${t.language}',
                          style: AppText.caption),
                      if (t.isVocalsOnly)
                        Text(
                            t.audioStyle == 'duff'
                                ? 'Voice and duff'
                                : 'Voice only',
                            style: AppText.caption
                                .copyWith(color: AppColors.gold)),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      tooltip: 'Add to a playlist',
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: const Icon(Icons.playlist_add,
                          color: AppColors.gold, size: 22),
                      onPressed: () => showAddToPlaylistSheet(
                        context,
                        ref,
                        catalogId: t.id,
                        title: t.title,
                        artist: t.artist,
                      ),
                    ),
                    Icon(
                      playsHere(t) ? Icons.play_arrow : Icons.open_in_new,
                      color: AppColors.gold
                          .withValues(alpha: playsHere(t) ? 1 : 0.6),
                      size: 20,
                    ),
                  ],
                ),
                onTap: () => _tapTrack(t, shown, sources,
                    name: facetValue ?? facet),
              ),
            ),
          if (visible < shown.length)
            Center(
              child: TextButton(
                key: const Key('player-show-more'),
                onPressed: () => setState(() => _limit += _page),
                child: Text(
                  'Show more (${shown.length - visible} left)',
                  style: const TextStyle(color: AppColors.gold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Plays here" or "Opens YouTube": which one a row is, said in words.
class _PlayBadge extends StatelessWidget {
  const _PlayBadge({required this.here, this.service});

  final bool here;
  final String? service;

  @override
  Widget build(BuildContext context) {
    final String label = here
        ? (service == null ? 'Plays here' : 'Plays here ($service)')
        : 'Opens YouTube';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: here ? AppColors.gold.withValues(alpha: 0.18) : null,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: here ? 0.8 : 0.4),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: here ? AppColors.gold : AppColors.sand,
          fontWeight: here ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}
