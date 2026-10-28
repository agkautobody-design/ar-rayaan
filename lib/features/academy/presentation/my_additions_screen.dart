/// "My Additions" — the user's personal library (1b.3).
/// On-device only (Amanah: a player for the user's files, never a
/// distributor). Tagged "Personal — added by you"; excluded from mixes,
/// kids mode and the share catalog; household filter hides them on
/// shared devices. Design: locked glass-card grammar.
library;

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
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
import '../application/stream_player_provider.dart';
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
    String? titleError;
    String? linkError;
    final bool? added = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter set) => AlertDialog(
          semanticLabel: 'Add by URL',
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
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Qasidah Burdah',
                    errorText: titleError,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: url,
                  style: AppText.body,
                  decoration: InputDecoration(
                    labelText: 'Link (https://\u2026)',
                    hintText: 'YouTube, Spotify, or a direct audio link',
                    errorText: linkError,
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
                final String? te = personalTitleError(title.text);
                final String? le = personalLinkError(url.text);
                if (te != null || le != null) {
                  set(() {
                    titleError = te;
                    linkError = le;
                  });
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

/// Why a pasted link cannot be added, or null when it can. The same plain
/// wording style as the playlist link dialog, kept inside the dialog so a
/// bad paste never closes it silently.
String? personalLinkError(String raw) {
  final Uri? u = Uri.tryParse(raw.trim());
  final bool ok = u != null &&
      (u.scheme == 'http' || u.scheme == 'https') &&
      u.host.isNotEmpty;
  return ok
      ? null
      : 'That is not a link I can play. It should start with https://';
}

/// What is wrong with a new addition (title first, then the link), or null
/// when it can be added. YouTube and Spotify links are https links too.
String? validateAddition(String title, String link) =>
    personalTitleError(title) ?? personalLinkError(link);

/// Why the title cannot be used, or null when it can.
String? personalTitleError(String raw) =>
    raw.trim().isEmpty ? 'Give it a title.' : null;

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
              onPressed: () async {
                // One thing plays at a time: close a link player first.
                ref.read(streamQueueProvider.notifier).stop();
                // Play through the same queue the Player drives; personal
                // tracks stay tagged personalImport everywhere downstream.
                await ref.read(playerQueueProvider.notifier).playQueue(
                  <Track>[_toQueueTrack(track)],
                  name: 'My Additions',
                );
                if (!context.mounted) return;
                // The controls live on the Player page: say so, with a way
                // there, instead of tapping Play and seeing nothing happen.
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('Playing \u201c${track.title}\u201d.'),
                      action: SnackBarAction(
                        label: 'Open Player',
                        onPressed: () => context.open(AppRoutes.player),
                      ),
                    ),
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
