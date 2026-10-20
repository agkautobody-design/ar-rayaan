/// Arabic Language school — the language of the Qur’an, taught from
/// Qur’anic examples wherever a word is certain. Unit 1 (greetings,
/// family, the definite article) starts the reader on real Arabic, not
/// transliteration.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_scaffold.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _ArLesson {
  const _ArLesson({
    required this.title,
    required this.arabic,
    required this.body,
    required this.source,
    this.actionRoute,
    this.actionLabel,
  });

  final String title;
  final String arabic;
  final String body;
  final String source;
  final String? actionRoute;
  final String? actionLabel;
}

class _ArUnit {
  const _ArUnit({required this.title, required this.lessons});
  final String title;
  final List<_ArLesson> lessons;
}

const List<_ArUnit> kArabicUnits = <_ArUnit>[
  _ArUnit(
    title: 'First Words, Real Words',
    lessons: <_ArLesson>[
      _ArLesson(
        title: 'The Greeting Is a Qur’anic Sentence',
        arabic: 'السَلامُ عَلَيكُمْ',
        body: 'As-salamu alaykum — peace be upon you — is a Qur’anic formula (6:54: peace be upon you for what you patiently endured). The reply, wa alaykum as-salam, mirrors it. Every time you greet a Muslim, you are speaking Qur’anic Arabic.',
        source: 'Qur’an 6:54',
      ),
      _ArLesson(
        title: 'Family Words You Already Own',
        arabic: 'أَبٌ / أُمٌّ / ابْنٌ / بنتٌ',
        body: 'Ab (father), umm (mother), ibnu/bint (son/daughter) — the same roots that carry the Qur’an’s family passages (12:100; 71:28). Learn these four and you can read entire family verses without translation.',
        source: 'Qur’an 12:100; 71:28',
      ),
      _ArLesson(
        title: 'The Definite Article: Al-',
        arabic: 'الكِتَابُ — كِتَابٌ',
        body: 'Al- makes a word definite: al-kitabu (the book) vs kitabun (a book). You have seen it thousands of times — al-Fatiha, al-hamdu, al-Rahman. Today, name it.',
        source: 'Grammar note',
      ),
      _ArLesson(
        title: 'Allah Is the Name, Rabb Is the Word',
        arabic: 'اللّهُ رَبُّ الْعَالَمينَ',
        body: 'Allah is the proper Name; rabb is the noun (Lord, Nurturer). You cannot change rabb into ar-rabb the way you can add al- to kitab — some words resist the article. Qur’anic Arabic teaches its own rules.',
        source: 'Qur’an 1:2',
        actionRoute: '/quran',
        actionLabel: 'See it in Al-Fatiha',
      ),
    ],
  ),
  _ArUnit(
    title: 'Reading Whole Verses',
    lessons: <_ArLesson>[
      _ArLesson(
        title: 'Al-Fatiha, Word by Word',
        arabic: 'الْحَمْدُ لِلّهِ رَبِّ الْعَالَمينَ',
        body: 'Al-hamdu (the praise) lillahi (belongs to Allah) rabbi (Lord of) al-alamin (the worlds). Every word here is one you can now name. Read the line slowly — you are reading Arabic, not transliteration.',
        source: 'Qur’an 1:2',
        actionRoute: '/quran',
        actionLabel: 'Recite it in the reader',
      ),
      _ArLesson(
        title: 'The Formula You Say 17 Times a Day',
        arabic: 'إِيَّاكَ نَعْبُدُ',
        body: 'Iyyaka na’budu — You alone we worship. Iyyaka carries the kasra twice (to You alone), and na’budu is the present-tense verb. Salah is a daily Arabic lesson the body never forgets.',
        source: 'Qur’an 1:5',
      ),
      _ArLesson(
        title: 'Slow Is the Standard',
        arabic: 'وَرَتِّلِ القُرْآنَ تَرْتِيلاً',
        body: 'And recite the Qur’an with measured recitation (73:4). Slow enough to hear each letter. Arabic learned slowly stays; Arabic rushed evaporates.',
        source: 'Qur’an 73:4',
      ),
    ],
  ),
];

class ArabicLanguageSchoolScreen extends StatelessWidget {
  const ArabicLanguageSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Arabic Language', close: true),
              Text('العربية',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'The language of the Qur’an — from the words you already say',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final _ArUnit unit in kArabicUnits) ...<Widget>[
                Text(unit.title.toUpperCase(), style: AppText.eyebrow),
                const SizedBox(height: 8),
                for (final _ArLesson l in unit.lessons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      strong: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l.title, style: AppText.titleMedium),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.night,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(l.arabic,
                                textAlign: TextAlign.right,
                                style: AppText.arabic
                                    .copyWith(fontSize: 22, color: AppColors.goldLight)),
                          ),
                          const SizedBox(height: 8),
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
              Text(
                'Unit 1 begins the sequence: words → sentences → grammar, all from the Qur’an itself. Deeper units arrive in the next wave.',
                style: AppText.bodyMuted.copyWith(fontSize: 11, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
