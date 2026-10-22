/// "Add to a playlist" bottom sheet, used from the Player's track list.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../application/user_playlist_provider.dart';
import '../domain/user_playlist.dart';

Future<void> showAddToPlaylistSheet(
  BuildContext context,
  WidgetRef ref, {
  required String catalogId,
  required String title,
  required String artist,
}) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final String? picked = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.navy,
    builder: (BuildContext ctx) => Consumer(
      builder: (BuildContext _, WidgetRef r, Widget? __) {
        final List<UserPlaylist> lists = r.watch(userPlaylistsProvider);
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Add “$title” to…', style: AppText.titleMedium),
              ),
              for (final UserPlaylist p in lists)
                ListTile(
                  leading:
                      const Icon(Icons.queue_music, color: AppColors.gold),
                  title: Text(p.name, style: AppText.body),
                  subtitle: Text('${p.items.length} tracks',
                      style: AppText.caption),
                  onTap: () => Navigator.of(ctx).pop(p.id),
                ),
              ListTile(
                leading: const Icon(Icons.add, color: AppColors.gold),
                title: Text('New playlist', style: AppText.body),
                onTap: () => Navigator.of(ctx).pop('__new__'),
              ),
            ],
          ),
        );
      },
    ),
  );
  if (picked == null) return;
  String? target = picked;
  if (picked == '__new__') {
    if (!context.mounted) return;
    final String? name = await askForName(context, title: 'New playlist');
    if (name == null) return;
    target = await ref.read(userPlaylistsProvider.notifier).create(name);
    if (target == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not create the playlist.')));
      return;
    }
  }
  final bool added = await ref
      .read(userPlaylistsProvider.notifier)
      .addCatalogTrack(target,
          catalogId: catalogId, title: title, artist: artist);
  messenger.showSnackBar(SnackBar(
      content: Text(added
          ? 'Added to your playlist.'
          : 'Already in that playlist, or it is full.')));
}

/// Ask for a short name; null when cancelled or blank.
Future<String?> askForName(BuildContext context,
    {required String title, String initial = ''}) async {
  final TextEditingController c = TextEditingController(text: initial);
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text(title, style: AppText.titleMedium),
      content: TextField(
        controller: c,
        autofocus: true,
        maxLength: kMaxNameLength,
        style: AppText.body,
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save')),
      ],
    ),
  );
  final String n = clipText(c.text, kMaxNameLength);
  c.dispose();
  if (ok != true || n.isEmpty) return null;
  return n;
}
