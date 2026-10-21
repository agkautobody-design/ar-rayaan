/// Character school — the heart\u2019s traits, one lesson per virtue:
/// what it is, what it fixes, and one practice for today. Built on the
/// khutbahs and modern hadith already in the library.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _CharLesson {
  const _CharLesson({required this.title, required this.body, required this.practice});

  final String title;
  final String body;
  final String practice;
}

class _CharUnit {
  const _CharUnit({required this.title, required this.frame, required this.lessons});
  final String title;
  final String frame;
  final List<_CharLesson> lessons;
}

const List<_CharUnit> kCharacterUnits = <_CharUnit>[
  _CharUnit(
    title: 'The Weight You Carry',
    frame: 'Akhlaq is not decoration — it is the load-bearing structure of a life. These are the traits that hold everything else up.',
    lessons: <_CharLesson>[
      _CharLesson(
        title: 'Sincerity — Cleaning the Why',
        body: 'Actions are only by intentions (Bukhari 1). The same prayer can be worship or theater depending on the why. The Prophet ﷺ called the first three generations the best because their deeds were built on ikhlas — and he warned that one day people would act for other than Allah\u2019s face.',
        practice: 'Before one deed today, say \'for You alone\' in your heart — then do it quietly.',
      ),
      _CharLesson(
        title: 'Patience — The Standing Muscle',
        body: 'Allah is with the patient (2:153). Patience is not the absence of pain; it is the presence of staying. Ya\u2019qub said \'I only complain of my suffering to Allah\' (12:86) — grief and patience in the same sentence, and the Qur\'an called his patience beautiful.',
        practice: 'Name one thing testing you this week. Stay in it one more day without quitting the dua.',
      ),
      _CharLesson(
        title: 'Gratitude — The Increase Clause',
        body: 'If you are grateful, I will surely increase you (14:7). Gratitude is not a mood — it is a contract with increase written into it. The Prophet ﷺ called the one who eats and praises Allah like one who fasts patiently and praises.',
        practice: 'Name three things before sleep tonight that you never earned and could never count.',
      ),
      _CharLesson(
        title: 'Truthfulness — The Handshake With Reality',
        body: 'Truthfulness leads to righteousness, and righteousness leads to Paradise (Bukhari 6094). And a man keeps speaking truth until Allah records him as truthful — the trait becomes the title. Lies, the hadith warns, lead the other direction.',
        practice: 'Today, correct one small untruth — even one you could have left standing.',
      ),
    ],
  ),
  _CharUnit(
    title: 'The Heart\u2019s Enemies',
    frame: 'Four viruses the Prophet ﷺ named by name — and their cures.',
    lessons: <_CharLesson>[
      _CharLesson(
        title: 'Anger — The Ember',
        body: 'The strong is not the wrestler; the strong is the one who controls himself at anger (Bukhari 6114). The Prophet ﷺ prescribed the physical cures: change posture, seek refuge from Shaytan, and if standing, sit; if sitting, lie down. Anger is cooled by the body before the mind.',
        practice: 'Next time the heat rises: sit down if standing, say a\u2019udhu billah, and wait ninety seconds.',
      ),
      _CharLesson(
        title: 'Envy — The Second Look',
        body: 'Envy eats good deeds as fire eats dry wood — a report graded weak, so hold it as a reminder (Abu Dawud 4903, weak per al-Albani). The cure the Prophet ﷺ taught is not pretending the blessing isn\u2019t real — it is praying for the one who has it: \'O Allah, bless them in it.\' The prayer converts the poison.',
        practice: 'Find one person whose blessing stung you. Make dua for them by name today.',
      ),
      _CharLesson(
        title: 'Arrogance — The False Height',
        body: 'No one with an atom\u2019s weight of arrogance enters Paradise (Muslim 91). The Prophet ﷺ defined it as refusing truth and despising people. Musa was called to speak despite his stutter; the Messenger ﷺ wept for his people. Greatness in this deen bends low.',
        practice: 'Do one anonymous good deed this week — let no one know, including the one who benefits.',
      ),
      _CharLesson(
        title: 'Despair — The Closed Door',
        body: 'Say: O My servants who have transgressed against themselves, do not despair of the mercy of Allah. Indeed, Allah forgives all sins (39:53). The devil\u2019s greatest lie is not that sin is small — it is that mercy is smaller.',
        practice: 'If you carry an old regret, say the verse tonight before sleep — once, meaning it.',
      ),
    ],
  ),
  _CharUnit(
    title: 'The Social Heart',
    frame: 'Character becomes akhlaq only when other people are involved.',
    lessons: <_CharLesson>[
      _CharLesson(
        title: 'The Tongue — Your Daily Ledger',
        body: 'Whoever believes in Allah and the Last Day should speak good or remain silent (Bukhari 6018). And whoever guarantees me what is between his jaws and his legs, I guarantee Paradise. A whole day can be built on that one guarantee.',
        practice: 'Run today\u2019s speech through one filter: would I say it with the person standing here?',
      ),
      _CharLesson(
        title: 'Forgiveness — Releasing the Debtor',
        body: 'The Prophet ﷺ was asked to curse the people of Taif and he prayed for their children instead. Allah described the servants of the Merciful as those who pardon people (3:134) — and the reward for pardoning is measured by Allah, who loves to pardon.',
        practice: 'Release one person from a debt of yours tonight — in your heart first, then in your behavior.',
      ),
      _CharLesson(
        title: 'Kindness — The Missing Dates',
        body: 'Aisha was asked what the Prophet ﷺ did at home. She said: he was in the service of his family (Bukhari 676). The strongest man in the room served. Kindness is not weakness; in his house it was leadership.',
        practice: 'Serve one person in your home today before being asked.',
      ),
      _CharLesson(
        title: 'Brotherhood — The Whole Body',
        body: 'The believers are like one body — if the eye aches the whole body aches (Bukhari 6011). And the Muslim is the brother of the Muslim: he does not wrong him, forsake him, or despise him. The ummah is not a membership; it is a shared nervous system.',
        practice: 'Check on one brother or sister you have not spoken to this month — a message is enough.',
      ),
    ],
  ),
];

class CharacterSchoolScreen extends StatelessWidget {
  const CharacterSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Character & Akhlaq', close: true),
              Text('الأخلاق',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'The heart\u2019s traits — what builds them, what attacks them, what to practice today',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final _CharUnit unit in kCharacterUnits) ...<Widget>[
                Text(unit.title.toUpperCase(), style: AppText.eyebrow),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(unit.frame,
                      style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.55)),
                ),
                for (final _CharLesson l in unit.lessons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      blur: false,
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
