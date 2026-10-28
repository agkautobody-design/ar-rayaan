import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../application/story_narrator.dart';
import '../application/story_text_size.dart';

/// Listen / Pause, a slow-or-normal pace and the Bigger text switch, for the
/// chapter whose spoken text is [text]. Changing chapter stops the voice.
class StoryListenBar extends ConsumerStatefulWidget {
  const StoryListenBar({required this.text, super.key});

  final String text;

  @override
  ConsumerState<StoryListenBar> createState() => _StoryListenBarState();
}

class _StoryListenBarState extends ConsumerState<StoryListenBar> {
  @override
  void didUpdateWidget(StoryListenBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      unawaited(ref.read(storyNarratorProvider.notifier).stop());
    }
  }

  @override
  Widget build(BuildContext context) {
    final NarratorState n = ref.watch(storyNarratorProvider);
    final bool big = ref.watch(storyBigTextProvider);
    final bool mine = n.text == widget.text;
    final bool playing = mine && n.status == NarratorStatus.playing;
    final bool paused = mine && n.status == NarratorStatus.paused;
    final String label = playing ? 'Pause' : (paused ? 'Resume' : 'Listen');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              FilledButton.icon(
                key: const Key('story-listen'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: AppColors.gold,
                  foregroundColor: const Color(0xFF0A0F18),
                ),
                onPressed: () => unawaited(
                  ref.read(storyNarratorProvider.notifier).toggle(widget.text),
                ),
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                label: Text(label),
              ),
              ChoiceChip(
                key: const Key('story-pace-slow'),
                label: const Text('Slow'),
                selected: n.slow,
                onSelected: (_) => unawaited(
                  ref.read(storyNarratorProvider.notifier).setSlow(true),
                ),
              ),
              ChoiceChip(
                key: const Key('story-pace-normal'),
                label: const Text('Normal'),
                selected: !n.slow,
                onSelected: (_) => unawaited(
                  ref.read(storyNarratorProvider.notifier).setSlow(false),
                ),
              ),
              FilterChip(
                key: const Key('story-bigger-text'),
                label: const Text('Bigger text'),
                selected: big,
                onSelected: (bool v) =>
                    unawaited(ref.read(storyBigTextProvider.notifier).set(v)),
              ),
            ],
          ),
          if (n.unavailable)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Reading aloud is not available on this device or browser.',
                key: const Key('story-listen-unavailable'),
                style: AppText.bodyMuted.copyWith(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
