import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../stories/application/saved_stories_controller.dart';
import '../../stories/data/stories_repository.dart';
import '../../stories/domain/story.dart';

/// The Bookmarks surface: the stories saved on this device (Hadi saves them
/// on request). Journey and Profile both open this - "Bookmarks" used to
/// just open the whole Stories library, which showed nothing of what was
/// saved.
Future<void> showSavedStories(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0A0F18),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext ctx) => const SavedStoriesSheet(),
  );
}

class SavedStoriesSheet extends ConsumerWidget {
  const SavedStoriesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<String> saved = ref.watch(savedStoriesProvider);
    final AsyncValue<List<Story>> stories = ref.watch(storiesProvider);
    final List<Story> mine = (stories.valueOrNull ?? <Story>[])
        .where((Story s) => saved.contains(s.id))
        .toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('BOOKMARKS', style: AppText.eyebrow),
            const SizedBox(height: 10),
            if (mine.isEmpty)
              Text(
                saved.isEmpty
                    ? 'Nothing saved yet. Ask Hādi to bookmark a story and it will appear here.'
                    : 'Your saved stories are still loading.',
                style: AppText.bodyMuted.copyWith(height: 1.5),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    for (final Story s in mine)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go(AppRoutes.storyReader, extra: s);
                          },
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.bookmark,
                                  size: 18, color: AppColors.goldLight),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(s.title, style: AppText.body),
                              ),
                              const Icon(Icons.chevron_right,
                                  size: 16, color: AppColors.gold),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
