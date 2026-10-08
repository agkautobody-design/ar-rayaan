/// Duʿa & Adhkar school — the teaching wrapper over the adhkar module.
/// The adhkar CONTENT is owned by features/adhkar (formats, doesn't
/// duplicate); this screen adds the pedagogy: what the words mean,
/// when the Prophet ﷺ taught them, and a memory nudge that routes to
/// the module itself.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _DuaLesson {
  const _DuaLesson({
    required this.title,
    required this.arabic,
    required this.meaning,
    required this.when,
    required this.source,
  });

  final String title;
  final String arabic;
  final String meaning;
  final String when;
  final String source;
}

const List<_DuaLesson> kDuaLessons = <_DuaLesson>[
  _DuaLesson(
    title: 'Ayat al-Kursi — after Fajr, protection',
    arabic:
        'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ',
    meaning:
        'Allah — there is no god but He, the Ever-Living, the Sustainer. Neither drowsiness nor sleep overtakes Him… (2:255) — the Prophet ﷺ said nothing prevents him who recites it from entering Paradise but death (Nasai).',
    when: 'After each obligatory prayer, and morning/evening.',
    source: 'Qur’an 2:255 · An-Nasa’i 9927 (wording per Ibn Hibban)',
  ),
  _DuaLesson(
    title: 'Sayyid al-Istighfar — the master of seeking forgiveness',
    arabic:
        'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ',
    meaning:
        'O Allah, You are my Lord; there is no god but You. You created me and I am Your servant… Whoever says it with conviction morning or evening and dies that day enters Paradise (Bukhari 6306).',
    when: 'Morning and evening.',
    source: 'Bukhari 6306',
  ),
  _DuaLesson(
    title: 'Before sleeping',
    arabic:
        'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
    meaning:
        'In Your name, O Allah, I die and I live. The Prophet ﷺ would place his right hand under his cheek and say it (Bukhari 6314).',
    when: 'On lying down to sleep.',
    source: 'Bukhari 6314',
  ),
  _DuaLesson(
    title: 'Before eating',
    arabic: 'بِسْمِ اللَّهِ',
    meaning:
        'In the name of Allah. The Prophet ﷺ said: mention Allah’s name, eat with your right hand, and eat from what is nearest (Muslim 2022).',
    when: 'Before the first bite.',
    source: 'Muslim 2022',
  ),
];

class DuaSchoolScreen extends StatelessWidget {
  const DuaSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              const ScreenHeader(title: 'Duʿa & Adhkar'),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'A dua you understand is worth more than a hundred recited blindly. Learn the meaning here; practice inside the Dhikr & Duʿa module, anchored to your prayer times. [Content pending scholar review.]',
                  style: AppText.bodyMuted.copyWith(height: 1.5),
                ),
              ),
              for (final _DuaLesson l in kDuaLessons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    strong: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(l.title,
                            style: AppText.titleMedium
                                .copyWith(color: AppColors.gold)),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            l.arabic,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 22,
                              height: 1.6,
                              color: AppColors.sand,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(l.meaning,
                            style: AppText.body.copyWith(height: 1.5)),
                        const SizedBox(height: 8),
                        Text('When: ${l.when}',
                            style: AppText.caption),
                        Text('Source: ${l.source}',
                            style: AppText.caption
                                .copyWith(color: AppColors.gold)),
                      ],
                    ),
                  ),
                ),
              GlassCard(
                onTap: () => context.go('/adhkar'),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.wb_sunny_outlined, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Open Dhikr & Duʿa to practice',
                          style: AppText.body),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.gold),
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
