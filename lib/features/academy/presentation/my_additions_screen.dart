/// "My Additions" — the user's personal library (1b.3).
/// On-device only (Amanah: a player for the user's files, never a
/// distributor). Tagged "Personal — added by you"; excluded from mixes,
/// kids mode and the share catalog; household filter hides them on
/// shared devices. Design: locked glass-card grammar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/personal_library_provider.dart';
import '../application/player_queue_provider.dart';
import '../domain/personal_library.dart';
import '../domain/player.dart';

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
    final bool? added = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppColors.navy,
        title: Text('Add by URL', style: AppText.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: title,
              style: AppText.body,
              decoration: const InputDecoration(
                  labelText: 'Title', hintText: 'e.g. Qasidah Burdah'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: url,
              style: AppText.body,
              decoration: const InputDecoration(
                  labelText: 'Link (https://…)',
                  hintText: 'https://example.com/track.mp3'),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (added != true) return;
    final String t = title.text.trim();
    final String u = url.text.trim();
    if (t.isEmpty || !u.startsWith('http')) return; // honest validation
    await ref
        .read(personalLibraryProvider.notifier)
        .add(title: t, source: u);
  }
}

class _HouseholdCard extends ConsumerWidget {
  const _HouseholdCard({required this.hidden});
  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: SwitchMaterial(
              color: Colors.transparent,
              child: ListTile(
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
      )),
    );
  }
}

class _TrackRow extends ConsumerWidget {
  const _TrackRow({required this.track});
  final PersonalTrack track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: Material(
              color: Colors.transparent,
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
                style: AppText.bodyMuted.copyWith(fontSize: 11),
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
            IconButton(
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
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.gold),
              onPressed: () => ref
                  .read(personalLibraryProvider.notifier)
                  .remove(track.id),
            ),
          ],
        ),
      )),
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
