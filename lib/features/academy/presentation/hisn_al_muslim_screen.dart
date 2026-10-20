/// Hisn al-Muslim — the Fortress of the Muslim. Every authentic dua
/// and dhikr in the library, categorized for the moment you are in.
/// The duas themselves live in assets/stories/dailyduas.json and open
/// in the full reader; this screen is the fortress gate.
library;

import '../../stories/domain/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../stories/data/stories_repository.dart';

class _HisnCategory {
  const _HisnCategory({required this.title, required this.keyword});

  final String title;
  final String keyword;
}

const List<_HisnCategory> kHisnCategories = <_HisnCategory>[
  _HisnCategory(title: 'Morning & Evening', keyword: 'morning'),
  _HisnCategory(title: 'Waking & Sleeping', keyword: 'sleep'),
  _HisnCategory(title: 'Leaving & Entering Home', keyword: 'home'),
  _HisnCategory(title: 'Eating & Drinking', keyword: 'eat'),
  _HisnCategory(title: 'Travel', keyword: 'travel'),
  _HisnCategory(title: 'Hardship & Distress', keyword: 'distress'),
  _HisnCategory(title: 'Prayer & Worship', keyword: 'prayer'),
  _HisnCategory(title: 'Protection', keyword: 'protection'),
];

class HisnAlMuslimScreen extends ConsumerWidget {
  const HisnAlMuslimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesProvider);
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: stories.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold)),
            error: (e, _) => Center(
                child: Text('The fortress could not load.',
                    style: AppText.bodyMuted)),
            data: (all) {
              final repo = ref.read(storiesRepositoryProvider);
              final List<Story> duas = repo.byCollection(all, 'dailyduas');
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: <Widget>[
                  const ScreenHeader(title: 'Hisn al-Muslim', close: true),
                  Text('حصن المسلم',
                      style: AppText.arabic.copyWith(
                          fontSize: 28, color: AppColors.gold)),
                  const SizedBox(height: 6),
                  Text(
                    'The Fortress of the Muslim — every authentic dua and dhikr, for the moment you are in',
                    style: AppText.bodyMuted,
                  ),
                  const SizedBox(height: 18),
                  for (final _HisnCategory cat in kHisnCategories) ...<Widget>[
                    Text(cat.title.toUpperCase(), style: AppText.eyebrow),
                    const SizedBox(height: 8),
                    for (final Story d in duas.where((Story s) =>
                        (s.subtitle + s.title + s.kicker)
                            .toLowerCase()
                            .contains(cat.keyword)))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(d.title,
                                  style: AppText.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5)),
                              const SizedBox(height: 4),
                              Text(d.subtitle,
                                  style: AppText.bodyMuted
                                      .copyWith(fontSize: 11.5, height: 1.5)),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(d.sourceLabel,
                                      style: AppText.bodyMuted
                                          .copyWith(fontSize: 10)),
                                  GestureDetector(
                                    onTap: () => context
                                        .go(AppRoutes.storyReader, extra: d),
                                    child: Text('Open \u2192',
                                        style: AppText.bodyMuted.copyWith(
                                            color: AppColors.gold,
                                            fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    '${duas.length} authentic duas in the fortress. The Du\'a School in the Academy teaches their meaning; this is the reference for the moment you are in.',
                    style: AppText.bodyMuted.copyWith(fontSize: 11, height: 1.5),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
