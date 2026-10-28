/// Hajj & Umrah pack — the journey in order: intention and ihram,
/// the rites, the days. Each station opens the existing huda guide for
/// it; the pack is the road map, the guides are the detailed maps.
library;

import '../../../app/core/scholar_review.dart';
import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../huda/presentation/huda_screens.dart';

class _HajjStation {
  const _HajjStation({
    required this.title,
    required this.note,
    required this.guideId,
  });

  final String title;
  final String note;
  final String guideId;
}

class _HajjDay {
  const _HajjDay({required this.title, required this.frame, required this.stations});
  final String title;
  final String frame;
  final List<_HajjStation> stations;
}

const List<_HajjDay> kHajjJourney = <_HajjDay>[
  _HajjDay(
    title: 'Before You Travel',
    frame:
        'Hajj is answered with the body before the heart: intention, provisions, and the state of ihram entered before the miqat. The journey begins in the intention.',
    stations: <_HajjStation>[
      _HajjStation(
        title: 'The Intention and the Ihram',
        note: 'Labbayk Allahumma Hajj — the talbiya begins everything. What ihram is, when to enter it, what it forbids.',
        guideId: 'huda-ihram',
      ),
      _HajjStation(
        title: 'Who Must Go, and When',
        note: 'The obligation, the conditions of ability, what to settle before departure, and the reward of an accepted Hajj.',
        guideId: 'huda-hajj-intro',
      ),
    ],
  ),
  _HajjDay(
    title: 'The Arrival — Tawaf and Sa\u2019i',
    frame:
        'The House of Allah receives the pilgrim with two acts: the circling of tawaf and the walk of Sa\u2019i — Hagar\u2019s search between Safa and Marwah, made worship.',
    stations: <_HajjStation>[
      _HajjStation(
        title: 'Tawaf — Circling the House',
        note: 'Seven circuits around the Kaaba, beginning at the Black Stone, in a state of purity. The detailed guide walks every circuit.',
        guideId: 'huda-tawaf',
      ),
      _HajjStation(
        title: 'Sa\u2019i — Between Safa and Marwah',
        note: 'Seven lengths between the two hills, in memory of Hagar\u2019s search. One guide, \u201cTawaf & Sa\u2019i\u201d, teaches both rites together.',
        guideId: 'huda-tawaf',
      ),
    ],
  ),
  _HajjDay(
    title: 'The Days of Hajj — Arafat to the Stoning',
    frame:
        'The days the Prophet \ufdfa called the essence of Hajj: standing at Arafat where the religion was perfected (5:3), the night at Muzdalifah, and the days of stoning and sacrifice at Mina.',
    stations: <_HajjStation>[
      _HajjStation(
        title: 'The Day of Arafat — 9 Dhul Hijjah',
        note: 'The standing. The Prophet \ufdfa said Hajj is Arafat — no Hajj without this day. The guide covers the dua, the standing, the departure.',
        guideId: 'huda-arafat',
      ),
      _HajjStation(
        title: 'Muzdalifah and Mina',
        note: 'The night at Muzdalifah, the stoning, sacrifice and release, the days of Tashreeq at Mina and the farewell tawaf — walked through day by day in the Hajj walkthrough.',
        guideId: 'huda-hajj-overview',
      ),
    ],
  ),
  _HajjDay(
    title: 'Umrah — The Short Journey',
    frame:
        'Umrah can be done any time of year: ihram, tawaf, sa\u2019i, and cutting the hair — completed in hours. The guide walks it step by step.',
    stations: <_HajjStation>[
      _HajjStation(
        title: 'How to Perform Umrah',
        note: 'The complete sequence from miqat to halq — the Prophet \ufdfa performed Umrah four times; the guide makes it simple.',
        guideId: 'huda-umrah',
      ),
    ],
  ),
];

class HajjUmrahPackScreen extends ConsumerWidget {
  const HajjUmrahPackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guides = ref.watch(guidesProvider);
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: guides.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold)),
            error: (e, _) => Center(
                child: Text('The journey could not load.',
                    style: AppText.bodyMuted)),
            data: (all) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: <Widget>[
                const ScreenHeader(title: 'Hajj & Umrah', close: true),
                const ScholarReviewNote(
                  reviewKey: 'school.hajj-umrah',
                  padding: EdgeInsets.only(bottom: 8),
                ),
                Text('الحج والعمرة',
                    style: AppText.arabic.copyWith(
                        fontSize: 28, color: AppColors.gold)),
                const SizedBox(height: 6),
                Text(
                  'The journey in order — intention, the rites, the days, the Umrah',
                  style: AppText.bodyMuted,
                ),
                const SizedBox(height: 18),
                for (final _HajjDay day in kHajjJourney) ...<Widget>[
                  Text(day.title.toUpperCase(), style: AppText.eyebrow),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(day.frame,
                        style: AppText.bodyMuted.copyWith(
                            fontSize: 12, height: 1.55)),
                  ),
                  for (final _HajjStation st in day.stations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        strong: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(st.title,
                                style: AppText.titleMedium),
                            const SizedBox(height: 4),
                            Text(st.note,
                                style: AppText.bodyMuted.copyWith(
                                    fontSize: 12, height: 1.55)),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                final Guide? guide = all
                                    .where((Guide g) => g.id == st.guideId)
                                    .firstOrNull;
                                if (guide == null) {
                                  // Never reached for shipped stations (a
                                  // test pins every guideId to a real guide);
                                  // kept as a quiet fallback, not a promise.
                                  return const SizedBox.shrink();
                                }
                                return GestureDetector(
                                  onTap: () =>
                                      context.push(
                                          '/huda/guide?id=${Uri.encodeQueryComponent(guide.id)}',
                                          extra: guide),
                                  child: Text('Open the guide \u2192',
                                      style: AppText.bodyMuted.copyWith(
                                          color: AppColors.gold, fontSize: 12)),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
