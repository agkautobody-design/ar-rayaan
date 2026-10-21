import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/router.dart';
import '../data/stories_repository.dart';
import '../data/story_layers_repository.dart';
import 'source_label_chip.dart';

class StoriesScreen extends ConsumerWidget {
  const StoriesScreen({super.key});

  static const _collections = [
    ('prophets', 'Stories of the Prophets', 'Peace be upon them all'),
    ('women', 'Women of Islam', 'The hearts that carried the light'),
    ('seerah', 'The Seerah', 'The life of the Prophet \u0635\u0644\u0649 \u0627\u0644\u0644\u0647 \u0639\u0644\u064a\u0647 \u0648\u0633\u0644\u0645'),
    ('companions', 'The Companions', 'The generation that held the light'),
    ('ghayb', 'Al-Ghayb — The Unseen', 'Angels, jinn, the Last Day, and the 2am questions'),
    ('signs', 'Signs & the Last Day', 'What is coming, with certainty'),
    ('tales', 'Tales of the Ummah', 'Stories of the generations between'),
    ('khutbahs', 'Khutbahs', 'Sermons for the classics and for today'),
    ('modernhadith', 'Hadiths for Our Times', 'The pressures of this age, answered'),
    ('dailyduas', 'Daily Duas', 'For waking, eating, travel, hardship, and home'),
    ('newmuslim', 'The New Muslim Path', 'Thirty gentle days, one step at a time'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: stories.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GestureDetector(
              onTap: () async {
                // Clear the content-sync cache and rebuild the library.
                final prefs = await SharedPreferences.getInstance();
                for (final k in prefs.getKeys()) {
                  if (k.startsWith('cp_') || k.startsWith('cv_')) {
                    await prefs.remove(k);
                  }
                }
                ref.invalidate(storiesProvider);
              },
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('The library could not load.', style: AppText.body),
                const SizedBox(height: 6),
                Text('$e', textAlign: TextAlign.center,
                    style: AppText.bodyMuted.copyWith(fontSize: 12)),
                const SizedBox(height: 10),
                Text('TAP TO RETRY',
                    style: AppText.eyebrow.copyWith(color: AppColors.goldLight)),
              ]),
            ),
          ),
        ),
        data: (all) {
          final repo = ref.read(storiesRepositoryProvider);
          final Set<String> deeper =
              ref.watch(storyIdsWithLayersProvider).valueOrNull ?? <String>{};
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              const ScreenHeader(title: 'Stories', close: true),
              if (all.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      for (final k in prefs.getKeys()) {
                        if (k.startsWith('cp_') || k.startsWith('cv_')) {
                          await prefs.remove(k);
                        }
                      }
                      ref.invalidate(storiesProvider);
                    },
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('The shelves are empty — the packs did not load.',
                          style: AppText.body),
                      const SizedBox(height: 8),
                      Text('TAP TO RETRY',
                          style: AppText.eyebrow.copyWith(color: AppColors.goldLight)),
                    ]),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text('${all.length} STORIES LOADED',
                      style: AppText.eyebrow),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  'READ WITH YOUR HEART',
                  style: AppText.eyebrow,
                ),
              ),
              for (final (key, title, subtitle) in _collections) ...[
                if (repo.byCollection(all, key).isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppText.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppText.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                  for (final story in repo.byCollection(all, key))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        onTap: () =>
                            context.go(AppRoutes.storyReader, extra: story),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Icon(
                                Icons.auto_stories_outlined,
                                size: 20,
                                color: AppColors.goldLight,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(story.title, style: AppText.titleMedium),
                                  const SizedBox(height: 2),
                                  Text(
                                    story.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.bodyMuted,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (deeper.contains(story.id))
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Tooltip(
                                  message: 'Has a Go deeper section',
                                  child: Icon(
                                    Icons.layers_outlined,
                                    size: 18,
                                    color: AppColors.goldLight,
                                    semanticLabel: 'Has a Go deeper section',
                                  ),
                                ),
                              ),
                            SourceLabelChip(label: story.sourceLabel),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
