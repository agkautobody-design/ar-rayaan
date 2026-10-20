/// Hadith school — Imam an-Nawawi\u2019s Forty, taught one hadith per
/// lesson: the text, what it means, and the character it builds. The
/// collection itself lives in assets/hadith/nawawi40.json and is read
/// by the hadith feature; this school is the curriculum around it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_scaffold.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../hadith/application/hadith_providers.dart';

/// The teaching layer for the Forty: one entry per hadith in sequence.
/// Keep in sync with assets/hadith/nawawi40.json order (n 1..40).
class _HadithLesson {
  const _HadithLesson({
    required this.title,
    required this.meaning,
    required this.character,
  });

  final String title;
  final String meaning;
  final String character;
}

const List<_HadithLesson> kHadithLessons = <_HadithLesson>[
  _HadithLesson(
    title: 'Hadith 1 — Actions Are by Intentions',
    meaning:
        'The Prophet \ufdfa said: actions are only by intentions, and every person shall have only what they intended. Migration for Allah and His Messenger is for Allah; migration for worldly gain or marriage is for that. This hadith is one third of knowledge (as the scholars counted) because intention decides the value of everything that follows it.',
    character: 'Check the why before the what — one intention today, named.',
  ),
  _HadithLesson(
    title: 'Hadith 2 — The Core of the Matter',
    meaning:
        'Islam is built on five: the testimony that none is worthy of worship but Allah and Muhammad is His Messenger, establishing prayer, giving zakat, fasting Ramadan, and Hajj to the House for whoever can make the way. The Prophet \ufdfa said this to Jibril when he came as a man to teach the companions — the questions were for you.',
    character: 'Hold the five pillars daily; they are the frame of everything else.',
  ),
  _HadithLesson(
    title: 'Hadith 3 — The Levels of the Deen',
    meaning:
        'Jibril asked about Islam, then Iman, then Ihsan. Islam is the five pillars. Iman is belief in Allah, His angels, His books, His messengers, the Last Day, and decree — good and bad. Ihsan is to worship Allah as though you see Him — and though you do not see Him, He sees you. The deen has a body, a heart, and a beauty.',
    character: 'Practice one act of ihsan today: do something as if He is watching — He is.',
  ),
  _HadithLesson(
    title: 'Hadith 4 — Your Time of Life',
    meaning:
        'The Prophet \ufdfa said: you are in the evening of one day and the morning of the next — your health before your sickness, your wealth before your poverty, your life before your death, and your free time before your busyness. Five before five, none of which return once gone.',
    character: 'Name one of the five-before-five you still hold; spend it today.',
  ),
  _HadithLesson(
    title: 'Hadith 5 — The Allowed and the Forbidden Are Clear',
    meaning:
        'What is lawful is clear and what is unlawful is clear, and between them are doubtful matters unknown to many. Whoever guards the doubtful has protected their religion and honor. Leave what makes you doubt for what does not.',
    character: 'When a choice feels gray, choose the side your heart rests on.',
  ),
  _HadithLesson(
    title: 'Hadith 6 — The Muslim Is the One Whom People Are Safe From',
    meaning:
        'The Muslim is the one from whose tongue and hand the Muslims are safe. And the emigrant is the one who emigrates from what Allah has forbidden. The Prophet \ufdfa described the best of people as those whose goodness is hoped and whose harm is safe — safety is a character, not just a status.',
    character: 'Be someone whose hand and word people do not fear today.',
  ),
  _HadithLesson(
    title: 'Hadith 7 — Religion Is Sincere Counsel',
    meaning:
        'The Prophet \ufdfa said: the religion is sincere counsel. We asked: to whom? He said: to Allah, His Book, His Messenger, the leaders of the Muslims, and their common people. Counsel is not flattery — it is wanting good for the one you advise.',
    character: 'Give one sincere piece of advice today, gently, to someone who needs it.',
  ),
  _HadithLesson(
    title: 'Hadith 8 — The Sanctity of a Muslim',
    meaning:
        'Allah has made sacred the blood, wealth, and honor of every Muslim to every other Muslim. The Muslim is the brother of the Muslim — he does not wrong him, forsake him, or despise him. Whoever fulfills the rights of his brother, Allah will fulfill his.',
    character: 'Guard one Muslim\u2019s honor today — in speech, in silence, in a message.',
  ),
];

class HadithSchoolScreen extends ConsumerWidget {
  const HadithSchoolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hadiths = ref.watch(hadithCollectionProvider);
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Hadith School', close: true),
              Text('الحديث',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'Imam an-Nawawi\u2019s Forty — the hadith every Muslim should carry',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => context.go(AppRoutes.hadith),
                child: Text('Open the full Forty reader \u2192',
                    style: AppText.bodyMuted.copyWith(color: AppColors.gold)),
              ),
              const SizedBox(height: 18),
              for (int i = 0; i < kHadithLessons.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    strong: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(kHadithLessons[i].title,
                            style: AppText.titleMedium),
                        const SizedBox(height: 8),
                        hadiths.when(
                          data: (list) => i < list.length
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.night,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    list[i].arabic,
                                    textAlign: TextAlign.right,
                                    style: AppText.arabic.copyWith(
                                        fontSize: 18, color: AppColors.goldLight),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 8),
                        Text(kHadithLessons[i].meaning,
                            style: AppText.body.copyWith(height: 1.6)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.3)),
                          ),
                          child: Text('Carry it: ${kHadithLessons[i].character}',
                              style:
                                  AppText.bodyMuted.copyWith(fontSize: 12.5, height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'First eight of forty walk you through intention, the pillars, ihsan, time, doubtful matters, safety, counsel, and sanctity. The remaining thirty-two complete the curriculum in the reader.',
                style: AppText.bodyMuted.copyWith(fontSize: 11, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
