/// The embedded player panel shared by the Player and My Playlists.
library;

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/core/open_link.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../application/player_queue_provider.dart';
import '../application/stream_player_provider.dart';
import '../domain/personal_library.dart';
import '../domain/stream_link.dart';
import 'stream_embed.dart';

/// Start playing [entries] from [index]. On the web the embedded player
/// opens in the panel; elsewhere the service's own app opens. Returns false
/// when nothing could be started (no entries, or the service's app/browser
/// would not open), so the caller can say so instead of claiming "Playing".
Future<bool> playStreamEntries(
  WidgetRef ref,
  List<StreamEntry> entries,
  int index,
) async {
  if (entries.isEmpty) return false;
  final int i = index < 0
      ? 0
      : index >= entries.length
          ? entries.length - 1
          : index;
  // One thing plays at a time: stop the bundled audio first.
  await ref.read(playerQueueProvider.notifier).pause();
  if (streamEmbedSupported) {
    ref.read(streamQueueProvider.notifier).play(entries, i);
    return true;
  }
  try {
    return await launchUrl(entries[i].link.openUri,
        mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

class StreamPlayerPanel extends ConsumerWidget {
  const StreamPlayerPanel({super.key});

  static double _heightFor(StreamLink l) {
    if (l.service == StreamService.youtube) return 230;
    return l.kind == 'track' || l.kind == 'episode' ? 152 : 352;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StreamQueue q = ref.watch(streamQueueProvider);
    final StreamEntry? e = q.current;
    if (e == null) return const SizedBox.shrink();
    final StreamQueueNotifier notifier = ref.read(streamQueueProvider.notifier);
    return GlassCard(
      strong: true,
      key: const Key('stream-player-panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(e.title,
              style: AppText.titleMedium.copyWith(color: AppColors.gold),
              textAlign: TextAlign.center),
          if (e.artist.isNotEmpty)
            Text(e.artist, style: AppText.caption, textAlign: TextAlign.center),
          if (e.personal)
            Text(PersonalTrackPlayable.personalBadge,
                style: AppText.caption, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          buildStreamEmbed(
            src: e.link.embedUri,
            title: '${e.link.serviceLabel} player: ${e.title}',
            height: _heightFor(e.link),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                tooltip: 'Previous track',
                icon: const Icon(Icons.skip_previous, color: AppColors.gold),
                onPressed: q.hasPrevious ? notifier.previous : null,
              ),
              IconButton(
                tooltip: 'Next track',
                icon: const Icon(Icons.skip_next, color: AppColors.gold),
                onPressed: q.hasNext ? notifier.next : null,
              ),
              IconButton(
                tooltip: 'Close the player',
                icon: const Icon(Icons.close, color: AppColors.gold),
                onPressed: notifier.stop,
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => openLinkWithFeedback(context, e.link.openUri),
            icon: const Icon(Icons.open_in_new, color: AppColors.gold, size: 18),
            label: Text('Open in ${e.link.serviceLabel}',
                style: const TextStyle(color: AppColors.gold)),
          ),
          Text(
            'Plays from ${e.link.serviceLabel} inside Ar-Rayaan. '
            'Ar-Rayaan does not host this audio. Tap Next to move on.',
            style: AppText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
