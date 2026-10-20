/// Hajj & Umrah pack — the journey in order: intention and ihram,
/// the rites, the days. Each station opens the existing huda guide for
/// it; the pack is the road map, the guides are the detailed maps.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_scaffold.dart';
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
        guideId: 'huda-hajj-ihram',
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
        guideId: 'huda-hajj-tawaf',
      ),
      _HajjStation(
        title: 'Sa\u2019i — Between Safa and Marwah',
        note: 'Seven lengths between the two hills, in memory of Hagar\u2019s search. The guide covers the stations, the dua, the pace.',
        guideId: 'huda-hajj-sai',
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
        guideId: 'huda-hajj-arafat',
      ),
      _HajjStation(
        title: 'Muzdalifah and Mina',
        note: 'The night at Mash\u2019ar al-Haram and the days of stoning the jamarat — the rites of completion and the farewell tawaf.',
        guideId: 'huda-hajj-mina-muzdalifah',
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
  _HajjDay(
    title: 'The Madhhab Differences',
    frame:
        'The four schools agree on the pillars and differ on details — the timing of ihram, the wajib acts, the women\u2019s rules. The guide lays them out without declaring war.',
    stations: <_HajjStation>[
      _HajjStation(
        title: 'Differences Between the Schools',
        note: 'Where Hanafi, Maliki, Shafi\u2019i, and Hanbali differ on the rites — and how to follow your school or your group leader with confidence.',
        guideId: 'huda-hajj-differences',
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
                                  return Text(
                                    'Guide coming soon',
                                    style: AppText.bodyMuted.copyWith(
                                        fontSize: 11,
                                        color: AppColors.gold),
                                  );
                                }
                                return GestureDetector(
                                  onTap: () =>
                                      context.push('/guides/read', extra: guide),
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
