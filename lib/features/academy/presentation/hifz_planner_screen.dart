/// Hifz planner screen — pace, projection, today's three lanes.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../domain/hifz_planner.dart';

class HifzPlannerScreen extends StatefulWidget {
  const HifzPlannerScreen({super.key});

  @override
  State<HifzPlannerScreen> createState() => _HifzPlannerScreenState();
}

class _HifzPlannerScreenState extends State<HifzPlannerScreen> {
  int _targetSurah = 18;
  int _dailyAyat = 3;

  @override
  Widget build(BuildContext context) {
    final HifzPlan plan = HifzPlan(
      targetSurah: _targetSurah,
      dailyNewAyat: _dailyAyat,
    );
    final int ayat = ayatInSurah(_targetSurah);
    final DateTime done = plan.projectedCompletion(ayat, DateTime.now());

    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              const ScreenHeader(title: 'Hifz Planner'),
              GlassCard(
                strong: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Your pace', style: AppText.caption),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _Step(label: 'Surah', value: _targetSurah,
                              min: 1, max: 114,
                              onChanged: (v) => setState(() => _targetSurah = v)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _Step(label: 'New ayat/day', value: _dailyAyat,
                              min: 1, max: 20,
                              onChanged: (v) => setState(() => _dailyAyat = v)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Surah $_targetSurah has $ayat ayat. At $_dailyAyat ayat a day it completes around '
                      '${done.year}-${done.month.toString().padLeft(2, '0')}-${done.day.toString().padLeft(2, '0')}. '
                      'A teacher may set a different pace — this is your compass, not your judge.',
                      style: AppText.bodyMuted.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Today’s three lanes',
                        style: AppText.titleMedium
                            .copyWith(color: AppColors.gold)),
                    const SizedBox(height: 10),
                    for (final (i, String lane)
                        in plan.todaysLanes().indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('${i + 1}.  ',
                                style: AppText.body
                                    .copyWith(color: AppColors.gold)),
                            Expanded(child: Text(lane, style: AppText.body)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Text(
                  'Revision is the heart of memorization. The Prophet \ufdfa said: “Commit yourselves to the Qur’an, for it escapes from people’s memory faster than a camel from its tether” (Bukhari 5033, paraphrased). Recite today’s blocks to your checker.',
                  style: AppText.bodyMuted.copyWith(height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                strong: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("Where to begin",
                        style: AppText.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      "Start with what you already pray: Al-Fatihah and the short surahs of Juz Amma "
                      "(Al-Ikhlas, Al-Falaq, An-Nas). What you recite every day is the easiest to keep. "
                      "Al-Kahf, the default target here, is a longer surah \u2014 set the surah above to the one you are working on.",
                      style: AppText.bodyMuted.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    Text("[Interpretive: start-where-you-pray method]",
                        style: AppText.bodyMuted.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.value, required this.min, required this.max, required this.onChanged});
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppText.caption),
        Row(
          children: <Widget>[
            IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.gold, size: 20),
                onPressed: value > min ? () => onChanged(value - 1) : null),
            Text('$value', style: AppText.body.copyWith(color: AppColors.gold)),
            IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.gold, size: 20),
                onPressed: value < max ? () => onChanged(value + 1) : null),
          ],
        ),
      ],
    );
  }
}
