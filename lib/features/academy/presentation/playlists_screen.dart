/// "My Playlists" — the person's own playlists, played inside Ar-Rayaan.
///
/// Catalogue tracks play from the approved sources only (bundled audio, or
/// an approved YouTube / Spotify source in the embedded player). A pasted
/// link is personal: on this device only, tagged, and hidden by the
/// household filter.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/core/safe_url.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/personal_library_provider.dart';
import '../application/player_queue_provider.dart';
import '../application/stream_player_provider.dart';
import '../application/user_playlist_provider.dart';
import '../data/player_sources_pack.dart';
import '../domain/personal_library.dart';
import '../domain/player.dart';
import '../domain/stream_link.dart';
import '../domain/user_playlist.dart';
import 'add_to_playlist_sheet.dart';
import 'stream_player_panel.dart';

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  String? _selected;

  UserPlaylist? _pick(List<UserPlaylist> lists) {
    for (final UserPlaylist p in lists) {
      if (p.id == _selected) return p;
    }
    return lists.isEmpty ? null : lists.first;
  }

  @override
  Widget build(BuildContext context) {
    final List<UserPlaylist> lists = ref.watch(userPlaylistsProvider);
    final bool hidden = ref.watch(personalHiddenProvider);
    final Map<String, TrackSources> sources =
        ref.watch(playerSourcesProvider).valueOrNull ??
            const <String, TrackSources>{};
    final Catalog? catalog = ref.watch(playerCatalogProvider).valueOrNull;

    final UserPlaylist? current = _pick(lists);

    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
            children: <Widget>[
              const ScreenHeader(title: 'My Playlists'),
              const StreamPlayerPanel(),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                      for (final UserPlaylist p in lists)
                        ChoiceChip(
                          label: Text(p.name),
                          selected: p.id == current?.id,
                          onSelected: (_) => setState(() => _selected = p.id),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.add,
                            size: 18, color: AppColors.gold),
                        label: const Text('New playlist'),
                        onPressed: _newPlaylist,
                      ),
                    ]),
                    if (current != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Row(children: <Widget>[
                        TextButton(
                          onPressed: () => _rename(current),
                          child: const Text('Rename',
                              style: TextStyle(color: AppColors.gold)),
                        ),
                        TextButton(
                          onPressed: () => _delete(current),
                          child: const Text('Delete playlist',
                              style: TextStyle(color: AppColors.gold)),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (current == null)
                GlassCard(
                  child: Column(children: <Widget>[
                    const Icon(Icons.queue_music,
                        color: AppColors.gold, size: 30),
                    const SizedBox(height: 8),
                    Text('No playlists yet', style: AppText.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Make a playlist, then add tracks from the Player. '
                      'Your playlists stay on this device.',
                      style: AppText.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                  ]),
                )
              else
                _Items(
                  playlist: current,
                  sources: sources,
                  catalog: catalog,
                  hidden: hidden,
                ),
            ],
          ),
        ),
      ),
      // Bottom-left: the Ask Hadi pill sits bottom-right and would cover it.
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: current == null || hidden
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.gold,
              onPressed: () => _addLink(current),
              icon: const Icon(Icons.add_link, color: AppColors.navy),
              label: const Text('Add a link',
                  style: TextStyle(color: AppColors.navy)),
            ),
    );
  }

  Future<void> _newPlaylist() async {
    final String? name = await askForName(context, title: 'New playlist');
    if (name == null) return;
    final String? id = await ref.read(userPlaylistsProvider.notifier).create(name);
    if (id != null && mounted) setState(() => _selected = id);
  }

  Future<void> _rename(UserPlaylist p) async {
    final String? name =
        await askForName(context, title: 'Rename playlist', initial: p.name);
    if (name == null) return;
    await ref.read(userPlaylistsProvider.notifier).rename(p.id, name);
  }

  Future<void> _delete(UserPlaylist p) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppColors.navy,
        title: Text('Delete “${p.name}”?', style: AppText.titleMedium),
        content: Text(
            'This removes the playlist from this device. The tracks '
            'themselves are not affected.',
            style: AppText.body),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep it')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(userPlaylistsProvider.notifier).delete(p.id);
    if (mounted) setState(() => _selected = null);
  }

  Future<void> _addLink(UserPlaylist p) async {
    final TextEditingController title = TextEditingController();
    final TextEditingController link = TextEditingController();
    String? error;
    final StreamLink? parsed = await showDialog<StreamLink>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter set) => AlertDialog(
          backgroundColor: AppColors.navy,
          title: Text('Add a link', style: AppText.titleMedium),
          content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text(
              'A YouTube or Spotify link. It stays on this device, is '
              'labelled “Personal — added by you”, and is never in mixes '
              'or the share catalogue.',
              style: AppText.caption,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: title,
              maxLength: kMaxTitleLength,
              style: AppText.body,
              decoration: const InputDecoration(
                  labelText: 'Title', hintText: 'e.g. Tala’a al-Badru'),
            ),
            TextField(
              controller: link,
              style: AppText.body,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'YouTube or Spotify link',
                errorText: error,
              ),
            ),
          ]),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final StreamLink? l = StreamLink.parse(link.text);
                if (l == null) {
                  set(() => error =
                      'That is not a YouTube or Spotify link I can play.');
                  return;
                }
                Navigator.of(ctx).pop(l);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    final String t = clipText(title.text, kMaxTitleLength);
    title.dispose();
    link.dispose();
    if (parsed == null) return;
    final bool added = await ref.read(userPlaylistsProvider.notifier).addLink(
          p.id,
          title: t.isEmpty ? '${parsed.serviceLabel} link' : t,
          link: parsed,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added
            ? 'Added to “${p.name}”.'
            : 'Already in that playlist, or it is full.')));
  }
}

class _Items extends ConsumerWidget {
  const _Items({
    required this.playlist,
    required this.sources,
    required this.catalog,
    required this.hidden,
  });

  final UserPlaylist playlist;
  final Map<String, TrackSources> sources;
  final Catalog? catalog;
  final bool hidden;

  Track? _track(String? id) {
    if (id == null || catalog == null) return null;
    for (final Track t in catalog!.tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PlaylistItem> items = playlist.items
        .where((PlaylistItem i) => !(hidden && i.isPersonal))
        .toList();
    if (items.isEmpty) {
      return GlassCard(
        child: Text(
          hidden && playlist.items.isNotEmpty
              ? 'Personal links are hidden on this device.'
              : 'This playlist is empty. In the Player, tap the playlist '
                  'button next to a track to add it here.',
          style: AppText.bodyMuted,
          textAlign: TextAlign.center,
        ),
      );
    }
    // The in-app playable entries, in order, so Next walks through them.
    final List<StreamEntry> entries = <StreamEntry>[
      for (final PlaylistItem i in items)
        if (entryForItem(i, sources, personalHidden: hidden)
            case final StreamEntry e)
          e,
    ];
    return GlassCard(
      child: Column(
        children: <Widget>[
          for (final PlaylistItem i in items)
            _row(context, ref, i, entries),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, PlaylistItem i,
      List<StreamEntry> entries) {
    final Track? track = _track(i.catalogId);
    final StreamEntry? entry =
        entryForItem(i, sources, personalHidden: hidden);
    final bool bundled = track != null && track.hasAudio;
    final Uri? outside =
        track == null ? null : SafeUrl.web(track.officialUrl);

    final String note = i.isPersonal
        ? PersonalTrackPlayable.personalBadge
        : bundled
            ? 'Plays in Ar-Rayaan'
            : entry != null
                ? 'Plays from ${entry.link.serviceLabel}'
                : 'Not available in the app yet — opens a YouTube search';

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(i.title, style: AppText.body),
      subtitle: Text(
        i.artist.isEmpty ? note : '${i.artist} · $note',
        style: AppText.caption,
      ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        IconButton(
          tooltip: bundled || entry != null ? 'Play' : 'Open outside the app',
          icon: Icon(
            bundled || entry != null ? Icons.play_arrow : Icons.open_in_new,
            color: AppColors.gold,
          ),
          onPressed: () async {
            if (bundled) {
              ref.read(streamQueueProvider.notifier).stop();
              await ref
                  .read(playerQueueProvider.notifier)
                  .playQueue(<Track>[track], name: playlist.name);
            } else if (entry != null) {
              final int at = entries.indexWhere((StreamEntry x) =>
                  x.link == entry.link && x.title == entry.title);
              await playStreamEntries(ref, entries, at < 0 ? 0 : at);
            } else if (outside != null) {
              await launchUrl(outside, mode: LaunchMode.externalApplication);
            }
          },
        ),
        IconButton(
          tooltip: 'Remove from this playlist',
          icon: const Icon(Icons.delete_outline, color: AppColors.gold),
          onPressed: () => ref
              .read(userPlaylistsProvider.notifier)
              .removeItem(playlist.id, i.id),
        ),
      ]),
    );
  }
}
