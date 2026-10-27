/// Hisn al-Muslim — the Fortress of the Muslim. Every authentic dua
/// and dhikr in the library, categorized for the moment you are in.
/// The duas themselves live in assets/stories/dailyduas.json and open
/// in the full reader; this screen is the fortress gate.
library;

import '../../../app/core/scholar_review.dart';
import '../../stories/domain/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../stories/data/stories_repository.dart';

class _HisnCategory {
  const _HisnCategory({required this.title, required this.id});

  final String title;

  /// Matches `hisnCategory` in assets/stories/dailyduas.json.
  final String id;
}

/// The gates of the fortress. Every dua in dailyduas.json names exactly
/// one of these ids explicitly (no keyword guessing), and anything
/// without a known id is shown under "More duas" rather than lost.
const List<_HisnCategory> kHisnCategories = <_HisnCategory>[
  _HisnCategory(title: 'Morning & Evening', id: 'morning-evening'),
  _HisnCategory(title: 'Waking & Sleeping', id: 'waking-sleeping'),
  _HisnCategory(title: 'Leaving & Entering Home', id: 'home'),
  _HisnCategory(title: 'Eating & Drinking', id: 'food'),
  _HisnCategory(title: 'Travel', id: 'travel'),
  _HisnCategory(title: 'Hardship & Distress', id: 'hardship'),
  _HisnCategory(title: 'Prayer & Worship', id: 'prayer'),
  _HisnCategory(title: 'Fasting', id: 'fasting'),
  _HisnCategory(title: 'Family & Protection', id: 'family'),
  _HisnCategory(title: 'Decisions', id: 'decisions'),
  _HisnCategory(title: 'Rain', id: 'rain'),
];

/// Groups [duas] by gate (duplicates removed). Public for tests.
Map<String, List<Story>> groupHisnDuas(List<Story> duas) {
  final Set<String> known = <String>{
    for (final _HisnCategory c in kHisnCategories) c.id,
  };
  final Map<String, List<Story>> out = <String, List<Story>>{
    for (final _HisnCategory c in kHisnCategories) c.id: <Story>[],
    'more': <Story>[],
  };
  for (final Story s in duas) {
    if (s.duplicateOf != null) continue;
    final String? id = s.hisnCategory;
    final String key = (id != null && known.contains(id)) ? id : 'more';
    out[key]!.add(s);
  }
  return out;
}

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
              final Map<String, List<Story>> grouped = groupHisnDuas(duas);
              final List<_HisnCategory> gates = <_HisnCategory>[
                ...kHisnCategories,
                const _HisnCategory(title: 'More duas', id: 'more'),
              ];
              final int distinct = grouped.values
                  .fold(0, (int n, List<Story> l) => n + l.length);
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: <Widget>[
                  const ScreenHeader(title: 'Hisn al-Muslim', close: true),
                  const ScholarReviewNote(
                    reviewKey: 'school.hisn',
                    padding: EdgeInsets.only(bottom: 8),
                  ),
                  Text('حصن المسلم',
                      style: AppText.arabic.copyWith(
                          fontSize: 28, color: AppColors.gold)),
                  const SizedBox(height: 6),
                  Text(
                    'The Fortress of the Muslim — duas and dhikr from the Qur\'an and Sunnah, for the moment you are in. Each shows its source and strength.',
                    style: AppText.bodyMuted,
                  ),
                  const SizedBox(height: 18),
                  for (final _HisnCategory cat in gates)
                    if (grouped[cat.id]!.isNotEmpty) ...<Widget>[
                    Text(cat.title.toUpperCase(), style: AppText.eyebrow),
                    const SizedBox(height: 8),
                    for (final Story d in grouped[cat.id]!)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          blur: false,
                          onTap: () =>
                              context.open(AppRoutes.storyReader, extra: d),
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
                                      .copyWith(fontSize: 12, height: 1.5)),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(d.sourceLabel,
                                      style: AppText.bodyMuted
                                          .copyWith(fontSize: 12)),
                                  GestureDetector(
                                    onTap: () => context
                                        .open(AppRoutes.storyReader, extra: d),
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
                    '$distinct duas in ${gates.where((c) => grouped[c.id]!.isNotEmpty).length} gates. The Du\'a School in the Academy teaches their meaning; this is the reference for the moment you are in.',
                    style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
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
