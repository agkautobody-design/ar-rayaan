/// Women\u2019s school — the women of the Qur\u2019an and the Prophet\u2019s
/// household as the curriculum: iman that built, scholarship that
/// taught, and standing that changed history. Every story id references
/// an existing library entry.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_scaffold.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _WomStory {
  const _WomStory({required this.id, required this.title, required this.note});

  final String id;
  final String title;
  final String note;
}

class _WomUnit {
  const _WomUnit({required this.title, required this.frame, required this.lessons});
  final String title;
  final String frame;
  final List<_WomLesson> lessons;
}

class _WomLesson {
  const _WomLesson({required this.title, required this.body, required this.practice, this.storyId});
  final String title;
  final String body;
  final String practice;
  final String? storyId;
}

const List<_WomUnit> kWomenUnits = <_WomUnit>[
  _WomUnit(
    title: 'Iman That Built',
    frame: 'The first believers, the first martyrs, the first to build the ummah were women.',
    lessons: <_WomLesson>[
      _WomLesson(
        title: 'Khadijah — The First Believer',
        body: 'The first person to believe was a woman — a merchant of Quraysh who married the trustworthy orphan and financed the mission when no one else would. When the Prophet ﭑ came down from Hira trembling, she wrapped him and said: Allah will never disgrace you.',
        practice: 'Who believed in you before anyone else did? Thank them this week — by name.',
        storyId: 'woman-khadijah',
      ),
      _WomLesson(
        title: 'Asiya — The Palace of Pharaoh',
        body: 'She lived in the house of the tyrant and was heartbroken in it — and Allah showed her her house in Paradise (66:11). Sometimes the palace is the test, not the prize.',
        practice: 'What 'house' are you in that feels wrong — and what house are you building instead?',
        storyId: 'woman-asiya',
      ),
      _WomLesson(
        title: 'Maryam — The Palm Tree',
        body: 'Alone, in labor, accused — and the angels spoke to her (19:16-33). Allah named an entire surah after a woman; her name appears more times in the Qur\'an than in the entire Bible. Solitude with Allah is never abandonment.',
        practice: 'When have you felt alone but not abandoned? Write one sentence about that moment.',
        storyId: 'woman-maryam',
      ),
      _WomLesson(
        title: 'Hagar — She Ran Seven Times',
        body: 'Alone in a barren valley with a crying child — and 'He will not waste us' became the walk between Safa and Marwah that every pilgrim still walks (2:158). Her tawakkul built a rite.',
        practice: 'Where are you running between the hills right now? Keep running — the water comes.',
        storyId: 'woman-hagar',
      ),
    ],
  ),
  _WomUnit(
    title: 'Scholarship That Taught',
    frame: 'The ummah\u2019s first scholars were the women of the Prophet\u2019s house — and the chain never broke.',
    lessons: <_WomLesson>[
      _WomLesson(
        title: 'Aisha — The Scholar of Scholars',
        body: 'The companions asked her about inheritance, medicine, poetry, and the Prophet\u2019s household. Her student Urwa said he had never seen anyone more knowledgeable in fiqh, medicine, or poetry. She taught with her door open and her mind sharper.',
        practice: 'Learn one thing deeply enough this month to teach it to someone else.',
        storyId: 'woman-aisha',
      ),
      _WomLesson(
        title: 'Fatima — The Brightest House',
        body: 'The Prophet ﭑ called her the leader of the women of Paradise — and she still ground barley until her hands bled and asked for a servant (Bukhari 3423). The highest rank and the grinding stone lived in the same hands.',
        practice: 'Name one hard daily task you do that no one celebrates. It is written.',
        storyId: 'woman-fatima',
      ),
      _WomLesson(
        title: 'Hafsa — The Keeper of the Book',
        body: 'After the Prophet\u2019s passing, the first written Qur\'an was kept with Hafsa — the ummah\u2019s first librarian was a widow. Uthman\u2019s standard copies were made from her sheets.',
        practice: 'Guard one thing of value this week — a book, a memory, a person\u2019s secret.',
        storyId: 'woman-hafsa',
      ),
      _WomLesson(
        title: 'Umm Ayman — The One They Forgot to List',
        body: 'She raised the Prophet ﭑ after his parents died — and he called her 'my mother after my mother.' The barakah of a household often lives with the person no one thinks to mention.',
        practice: 'Thank one person who raised, fed, or cleaned for you — the invisible ones first.',
        storyId: 'woman-umm-ayman',
      ),
    ],
  ),
  _WomUnit(
    title: 'Standing That Changed History',
    frame: 'When the line broke, the women held it.',
    lessons: <_WomLesson>[
      _WomLesson(
        title: 'Sumayyah — The First to Give Everything',
        body: 'The first martyr of Islam was a slave woman. Abu Jahl\u2019s spear could not make her curse the Prophet — so she became the ummah\u2019s first lesson in standing.',
        practice: 'What does 'standing for something' cost, and what does it buy? Answer aloud.',
        storyId: 'woman-sumayyah',
      ),
      _WomLesson(
        title: 'Nusaybah bint Ka\'b — Umm Ammarah',
        body: 'At Uhud, when the line broke and men fled, she stood between the Prophet ﭑ and the swords — shielding him with her body until she was cut. The Prophet ﭑ said: wherever I turned, she was there.',
        practice: 'Who do you shield? Name them, and stand there this week.',
        storyId: 'woman-umm-ammarah',
      ),
      _WomLesson(
        title: 'Khawlah — Whose Question Changed the Law',
        body: 'She stood before the caliph Umar and argued her case with the Qur\'an until the law was corrected (58:1 is her verse). Standing before authority with the Book in hand is a woman\u2019s right and a believer\u2019s duty.',
        practice: 'If you could correct one wrong with one honest argument, what would you say?',
        storyId: 'woman-khawlah',
      ),
      _WomLesson(
        title: 'Asma — She Who Carried the Food',
        body: 'During the Prophet\u2019s Hijrah, she tied the food and water to her waist and climbed the mountain — and the Qur\'an remembered her (9:40). Sometimes the logistics of a revolution are carried on one woman\u2019s belt.',
        practice: 'What are you carrying for someone else\u2019s journey? Keep carrying it.',
        storyId: 'woman-asma',
      ),
      _WomLesson(
        title: 'Umm Salama — Whose Question Became a Verse',
        body: 'She said the dua of the afflicted — 'to Allah we belong and to Him we return' — and her heartache became revelation (2:156). Her later question about 'the men only' brought the verse that included the women (33:35).',
        practice: 'What dua could turn your hardest day into an address to Allah? Say it tonight.',
        storyId: 'woman-umm-salama',
      ),
    ],
  ),
  _WomUnit(
    title: 'The Wives — The Mothers of the Believers',
    frame: 'The Prophet\u2019s wives were not a footnote; they were the teachers of a generation.',
    lessons: <_WomLesson>[
      _WomLesson(
        title: 'Khadijah — The First Believer',
        body: 'The first person to believe was a woman — a merchant who financed the mission when no one else would. When the Prophet ﭑ came down from Hira trembling, she wrapped him and said: Allah will never disgrace you.',
        practice: 'Who believed in you before anyone else did? Thank them this week — by name.',
        storyId: 'woman-khadijah',
      ),
      _WomLesson(
        title: 'Aisha — The Scholar of Scholars',
        body: 'The companions asked her about inheritance, medicine, poetry, and the Prophet\u2019s household. Her student Urwa said he had never seen anyone more knowledgeable in fiqh, medicine, or poetry.',
        practice: 'Learn one thing deeply enough this month to teach it to someone else.',
        storyId: 'woman-aisha',
      ),
      _WomLesson(
        title: 'Zaynab — Generosity That Hurt',
        body: 'She gave so much to the poor that the Prophet ﭑ told her to keep something for herself — and she answered that what she gave, Allah would replace. The wife who out-gave the household.',
        practice: 'Give one thing this week that actually costs you — and tell no one.',
        storyId: 'woman-zaynab',
      ),
      _WomLesson(
        title: 'Juwayriyya — The Captive Who Freed a Hundred',
        body: 'Taken in battle, she asked the Prophet ﭑ for her freedom; he offered more — marriage. Her mahr freed her whole clan. The captivity narrative ended in a wedding that freed a hundred families.',
        practice: 'Who in your life is a captive of circumstance — and what could you free them from this month?',
        storyId: 'woman-juwayriyya',
      ),
      _WomLesson(
        title: 'Hafsa — The Keeper of the Book',
        body: 'After the Prophet\u2019s passing, the first written Qur\u2019an was kept with Hafsa — the ummah\u2019s first librarian was a widow.',
        practice: 'Guard one thing of value this week — a book, a memory, a person\u2019s secret.',
        storyId: 'woman-hafsa',
      ),
      _WomLesson(
        title: 'Safiyya — The Woman Who Answered',
        body: 'Mocked for her Jewish ancestry, she answered the Prophet\u2019s question with the truth: 'Aaron is my father, Moses my uncle, and Muhammad my husband.' The answer that silenced the mockers.',
        practice: 'When mocked for your faith or background, answer with the truth — once, calmly, and stop.',
        storyId: 'woman-safiyya',
      ),
      _WomLesson(
        title: 'Bilqis — The Queen Who Knew a Letter',
        body: 'She ruled a kingdom, and a letter from Sulayman rearranged her throne. She kept her crown and found her Lord — the only woman in the Qur\u2019an whose submission is recorded in her own words.',
        practice: 'What letter has reached you recently that deserves an answer like Bilqis\u2019s?',
        storyId: 'woman-bilqis',
      ),
    ],
  ),
];

class WomensSchoolScreen extends StatelessWidget {
  const WomensSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Women in the Deen', close: true),
              Text('النساء',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'The women of the Quran and the Prophet\u2019s household — iman, scholarship, and standing',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final _WomUnit unit in kWomenUnits) ...<Widget>[
                Text(unit.title.toUpperCase(), style: AppText.eyebrow),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(unit.frame,
                      style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.55)),
                ),
                for (final _WomLesson l in unit.lessons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      strong: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l.title, style: AppText.titleMedium),
                          const SizedBox(height: 6),
                          Text(l.body, style: AppText.body.copyWith(height: 1.65, fontSize: 13)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.3)),
                            ),
                            child: Text('Practice: ${l.practice}',
                                style: AppText.bodyMuted.copyWith(
                                    fontSize: 12, height: 1.5, color: AppColors.gold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
