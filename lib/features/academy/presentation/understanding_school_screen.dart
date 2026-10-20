/// Understanding school — how the Qur'an came, how to read it with
/// meaning, and how it lives in a day. The CONTENT (reader, recitation,
/// tafsir path) is owned by features/quran; this screen teaches the
/// understanding itself: gentle, sourced, Loop-shaped.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _ULesson {
  const _ULesson({
    required this.title,
    required this.body,
    required this.source,
    this.actionRoute,
    this.actionLabel,
  });

  final String title;
  final String body;
  final String source;
  final String? actionRoute;
  final String? actionLabel;
}

class _UUnit {
  const _UUnit({required this.title, required this.lessons});
  final String title;
  final List<_ULesson> lessons;
}

const List<_UUnit> kUnderstandingUnits = <_UUnit>[
  _UUnit(
    title: 'How the Qur\'an Came',
    lessons: <_ULesson>[
      _ULesson(
        title: 'A Revelation, Not a Book First',
        body:
            'The Qur\'an arrived as sound before it was paper: Jibril brought it to the Prophet \ufdfa over twenty-three years, and the first word of the first revelation was Iqra — read (96:1). It lived in recitation and memory long before it lived on shelves.',
        source: "Qur'an 96:1",
        actionRoute: '/quran',
        actionLabel: 'Open the reader',
      ),
      _ULesson(
        title: 'Guarded, Word by Word',
        body:
            "'Indeed, it is We who sent down the Qur'an, and indeed We will be its guardian' (15:9). The protection Allah promised was not of a copy but of the text itself — memorized by millions, letter by letter, in every generation.",
        source: "Qur'an 15:9",
      ),
      _ULesson(
        title: 'Why Arabic',
        body:
            "'We have sent it down as an Arabic Qur'an that you might understand' (12:2). The language is not a barrier around the meaning — it is the vessel of it. Even a little Arabic learned with love changes how the verses land.",
        source: "Qur'an 12:2",
      ),
    ],
  ),
  _UUnit(
    title: 'Reading With Meaning',
    lessons: <_ULesson>[
      _ULesson(
        title: 'Translation Is a Bridge, Not the Land',
        body:
            'Every translation is an interpretation wearing the translator\'s glasses. Read yours with gratitude and with a light grip — when a word carries your whole heart, check what the Arabic actually says. The app shows both for exactly this reason.',
        source: 'Reading practice',
      ),
      _ULesson(
        title: 'Recite With Measured Beauty',
        body:
            "'And recite the Qur'an with measured recitation' (73:4). Slow enough to hear yourself. Understanding grows in the pause between verses, not in the race through them.",
        source: "Qur'an 73:4",
        actionRoute: '/quran',
        actionLabel: 'Practice in the reader',
      ),
      _ULesson(
        title: 'None Touch It Except the Purified',
        body:
            "'Indeed, it is a noble Qur'an, in a Register well-protected; none touch it except the purified' (56:77-79). Begin with wudu, begin with ta'awwudh, begin with His name — the body taught the reverence the heart then keeps.",
        source: "Qur'an 56:77-79",
      ),
    ],
  ),
  _UUnit(
    title: 'The Qur\'an in a Day',
    lessons: <_ULesson>[
      _ULesson(
        title: 'A Fixed Portion, However Small',
        body:
            'The most beloved deeds to Allah are the most consistent, even if small (Bukhari 6464). One page a day finishes the Qur\'an in about eight months. Small and daily beats large and abandoned — always.',
        source: 'Sahih al-Bukhari 6464',
      ),
      _ULesson(
        title: 'Healing and Mercy',
        body:
            "'And We send down of the Qur'an that which is healing and mercy for the believers' (17:82). Some verses are medicine for specific griefs — the Prophet \ufdfa recited over the sick. Find the verse that answers your season and keep it near.",
        source: "Qur'an 17:82",
      ),
      _ULesson(
        title: 'The Complaint of the Qur\'an',
        body:
            "The Prophet \ufdfa said the Qur'an will complain on the Last Day: 'My Lord, my people abandoned me' (25:30). Abandonment is not only never opening it — it is opening it and hearing nothing. Read one verse today as if it were addressed to you. It is.",
        source: "Qur'an 25:30",
      ),
    ],
  ),
];

class UnderstandingSchoolScreen extends StatelessWidget {
  const UnderstandingSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Understanding the Qur\'an', close: true),
              Text('مدرسة الفهم', style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'How it came · how to read it · how it lives in your day',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final _UUnit unit in kUnderstandingUnits) ...<Widget>[
                Text(unit.title.toUpperCase(), style: AppText.eyebrow),
                const SizedBox(height: 8),
                for (final _ULesson l in unit.lessons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      strong: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l.title, style: AppText.titleMedium),
                          const SizedBox(height: 6),
                          Text(l.body, style: AppText.body.copyWith(height: 1.65)),
                          const SizedBox(height: 8),
                          Text(l.source, style: AppText.bodyMuted.copyWith(fontSize: 10.5)),
                          if (l.actionRoute != null) ...<Widget>[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => context.go(l.actionRoute!),
                              child: Text(l.actionLabel ?? 'Open',
                                  style: AppText.bodyMuted.copyWith(color: AppColors.gold)),
                            ),
                          ],
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
    );
  }
}
