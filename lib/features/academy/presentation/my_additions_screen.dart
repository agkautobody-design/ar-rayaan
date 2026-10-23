/// "My Additions" — the user's personal library (1b.3).
/// On-device only (Amanah: a player for the user's files, never a
/// distributor). Tagged "Personal — added by you"; excluded from mixes,
/// kids mode and the share catalog; household filter hides them on
/// shared devices. Design: locked glass-card grammar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/personal_library_provider.dart';
import '../application/player_queue_provider.dart';
import '../application/user_playlist_provider.dart';
import '../domain/personal_library.dart';
import '../domain/player.dart';
import '../domain/stream_link.dart';
import '../domain/user_playlist.dart';
import 'add_to_playlist_sheet.dart';

class MyAdditionsScreen extends ConsumerWidget {
  const MyAdditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PersonalTrack> library = ref.watch(personalLibraryProvider);
    final bool hidden = ref.watch(personalHiddenProvider);
    final List<PersonalTrack> visible = visiblePersonal(library, hidden);

    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              const ScreenHeader(title: 'My Additions'),
              _HouseholdCard(hidden: hidden),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Add a link to a track of your own. A YouTube or '
                      'Spotify link goes into one of your playlists and '
                      'plays in the player. A direct audio link '
                      '(for example an .mp3) is kept here.',
                      style: AppText.bodyMuted,
                    ),
                    TextButton.icon(
                      onPressed: () => context.push(AppRoutes.myPlaylists),
                      icon: const Icon(Icons.queue_music,
                          size: 18, color: AppColors.gold),
                      label: const Text('Open My Playlists',
                          style: TextStyle(color: AppColors.gold)),
                      style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (hidden)
                GlassCard(
                  child: Column(
                    children: <Widget>[
                      const Icon(Icons.visibility_off_outlined,
                          color: AppColors.gold, size: 30),
                      const SizedBox(height: 8),
                      Text('Personal tracks are hidden on this device',
                          style: AppText.titleMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text(
                        'For shared devices. Nothing is deleted — your '
                        'library stays on this device, out of sight.',
                        style: AppText.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else if (visible.isEmpty)
                GlassCard(
                  child: Column(
                    children: <Widget>[
                      const Icon(Icons.person_outline,
                          color: AppColors.gold, size: 30),
                      const SizedBox(height: 8),
                      Text('Your personal library is empty',
                          style: AppText.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Add a nasheed or recitation by link. Personal '
                        'tracks live on this device only — never uploaded, '
                        'never in mixes, kids mode, or the share catalog.',
                        style: AppText.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...visible.map((PersonalTrack t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TrackRow(track: t),
                    )),
            ],
          ),
        ),
      ),
      // Bottom-left: the Ask Hadi pill sits bottom-right and would cover it.
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: hidden
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.gold,
              onPressed: () => _showAddDialog(context, ref),
              icon: const Icon(Icons.add, color: AppColors.navy),
              label: const Text('Add by URL',
                  style: TextStyle(color: AppColors.navy)),
            ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final TextEditingController title = TextEditingController();
    final TextEditingController url = TextEditingController();
    String? error;
    final bool? added = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter set) => AlertDialog(
          backgroundColor: AppColors.navy,
          title: Text('Add by URL', style: AppText.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: title,
                  style: AppText.body,
                  maxLength: kMaxTitleLength,
                  decoration: const InputDecoration(
                      labelText: 'Title', hintText: 'e.g. Qasidah Burdah'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: url,
                  style: AppText.body,
                  decoration: InputDecoration(
                    labelText: 'Link (https://\u2026)',
                    hintText: 'YouTube, Spotify, or a direct audio link',
                    errorText: error,
                    errorMaxLines: 3,
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final String? problem =
                    validateAddition(title.text, url.text);
                if (problem != null) {
                  set(() => error = problem);
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    final String t = clipText(title.text, kMaxTitleLength);
    final String u = url.text.trim();
    title.dispose();
    url.dispose();
    if (added != true) return;
    final StreamLink? stream = StreamLink.parse(u);
    if (stream != null) {
      // YouTube and Spotify links live in a playlist: that is where the
      // player can play them. Ask which one.
      if (!context.mounted) return;
      final String? target = await pickPlaylist(context, ref,
          heading: 'Add \u201c$t\u201d to\u2026');
      if (target == null || !context.mounted) return;
      final bool ok = await ref
          .read(userPlaylistsProvider.notifier)
          .addLink(target, title: t, link: stream);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(ok
              ? 'Added to your playlist. It plays from My Playlists.'
              : 'Already in that playlist, or it is full.'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => context.push(AppRoutes.myPlaylists),
          ),
        ));
      return;
    }
    await ref
        .read(personalLibraryProvider.notifier)
        .add(title: t, source: u);
  }
}

/// What is wrong with a new addition, in words, or null when it is fine.
/// A title and a link are both needed; the link must be a YouTube or Spotify
/// link, or an http(s) address of an audio file.
String? validateAddition(String title, String link) {
  if (title.trim().isEmpty) return 'Give it a title.';
  final String u = link.trim();
  if (u.isEmpty) return 'Paste a link.';
  if (StreamLink.parse(u) != null) return null;
  final Uri? parsed = Uri.tryParse(u);
  final bool web = parsed != null &&
      (parsed.scheme == 'http' || parsed.scheme == 'https') &&
      parsed.host.isNotEmpty;
  if (!web) {
    return 'That is not a link I can use. Paste a YouTube or Spotify link, '
        'or a direct audio link starting with https://.';
  }
  return null;
}

class _HouseholdCard extends ConsumerWidget {
  const _HouseholdCard({required this.hidden});
  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.gold,
        title: Text('Hide personal tracks', style: AppText.titleMedium),
        subtitle: Text(
          'Household filter for shared devices',
          style: AppText.bodyMuted,
        ),
        value: hidden,
        onChanged: (bool v) =>
            ref.read(personalHiddenProvider.notifier).set(v),
      ),
    );
  }
}

class _TrackRow extends ConsumerWidget {
  const _TrackRow({required this.track});
  final PersonalTrack track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(track.title, style: AppText.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                PersonalTrackPlayable.personalBadge,
                style: AppText.bodyMuted.copyWith(fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              track.isUrl ? track.source : 'On this device: ${track.source}',
              style: AppText.bodyMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(tooltip: 'Play',
              icon: const Icon(Icons.play_arrow, color: AppColors.gold),
              onPressed: () {
                // Play through the same queue the Player drives; personal
                // tracks stay tagged personalImport everywhere downstream.
                ref.read(playerQueueProvider.notifier).playQueue(
                  <Track>[_toQueueTrack(track)],
                  name: 'My Additions',
                );
              },
            ),
            IconButton(tooltip: 'Remove from my additions',
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.gold),
              onPressed: () => ref
                  .read(personalLibraryProvider.notifier)
                  .remove(track.id),
            ),
          ],
        ),
      ),
    );
  }

  static Track _toQueueTrack(PersonalTrack t) => Track(
        id: t.id,
        title: t.title,
        artist: '',
        language: 'personal',
        theme: 'personal',
        mood: 'calm',
        audioUrl: t.source,
      );
}
