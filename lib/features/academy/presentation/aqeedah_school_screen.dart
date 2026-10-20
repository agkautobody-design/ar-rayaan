/// Aqeedah school — what a Muslim believes and why, taught from the
/// Qur\u2019an itself. Anchored on 55:1–2 (Ar-Rahman taught the Qur\u2019an).
/// The 99 Names deck and the Ghayb / Signs collections continue the
/// units as practice and narrative.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _AqLesson {
  const _AqLesson({
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

class _AqUnit {
  const _AqUnit({required this.title, required this.lessons});
  final String title;
  final List<_AqLesson> lessons;
}

const List<_AqUnit> kAqeedahUnits = <_AqUnit>[
  _AqUnit(
    title: 'Who Is Allah',
    lessons: <_AqLesson>[
      _AqLesson(
        title: 'The Most Merciful Taught the Book',
        body:
            "'The Most Merciful — He taught the Qur'an' (55:1–2). Before any rule, before any law, the Qur'an opens its knowledge of Allah with a mercy that teaches. Whatever you learn about Him, begin here: the One who taught you is the One who was Merciful to you first.",
        source: "Qur'an 55:1–2",
      ),
      _AqLesson(
        title: 'No Slumber, No Sleep',
        body:
            "'Allah — there is no god but He, the Ever-Living, the Sustainer... neither slumber nor sleep overtakes Him' (2:255). He is not a distant clockmaker; He sustains every atom now. This verse is called Ayat al-Kursi — many Muslims say it after every prayer; now you know what it says.",
        source: "Qur'an 2:255",
      ),
      _AqLesson(
        title: 'The Attribute We Say Most',
        body:
            "'In the name of Allah, the Most Merciful, the Especially Merciful' (1:1). Every surah but one opens with mercy named twice. Whatever else is true about Him, the name you say most often is the Merciful — that is the door He chose for you.",
        source: "Qur'an 1:1",
      ),
      _AqLesson(
        title: 'His Are the Most Beautiful Names',
        body:
            "'And to Allah belong the most beautiful names, so call upon Him by them' (7:180). The 99 Names are not a list to recite dryly — they are His self-descriptions, each one an answer to a human need. Al-Rahman answers the afraid; Al-Wakeel answers the burdened.",
        source: "Qur'an 7:180",
        actionRoute: '/games/names99',
        actionLabel: 'Meet them in the memory deck',
      ),
    ],
  ),
  _AqUnit(
    title: 'What He Sent',
    lessons: <_AqLesson>[
      _AqLesson(
        title: 'Not a New God — the Same Call',
        body:
            "'Indeed, the religion in the sight of Allah is Islam' (3:19) — submission. The messengers were not sent by different gods; every nation received the same call: worship Allah and avoid false gods (16:36). The chain you belong to is as old as Adam.",
        source: "Qur'an 3:19; 16:36",
      ),
      _AqLesson(
        title: 'The Unseen Is Not Unheard',
        body:
            "'That is the Book about which there is no doubt, a guidance for the God-conscious who believe in the unseen' (2:2-3). Faith begins where sight ends — angels, the Last Day, the reward. Believing in al-ghayb is not credulity; it is trust in the only One who has never lied.",
        source: "Qur'an 2:2-3",
      ),
      _AqLesson(
        title: 'A Messenger to Every Nation',
        body:
            "'And We certainly sent into every nation a messenger, saying: worship Allah and avoid false gods' (16:36). Ibrahim argued with a star; Musa stood before a sea; Isa healed by Allah's leave; Muhammad sealed the chain. One message, many voices, one Lord.",
        source: "Qur'an 16:36",
        actionRoute: '/stories',
        actionLabel: 'Walk their stories',
      ),
    ],
  ),
  _AqUnit(
    title: 'Why It Matters',
    lessons: <_AqLesson>[
      _AqLesson(
        title: 'He Is With You — the Three Ways',
        body:
            "'He is with you wherever you are' (57:4). And 'We are closer to him than his jugular vein' (50:16). And 'Fear not, I am with you both; I hear and I see' (20:46). He is with all creation by knowledge, with the believers by help, with His awliya by love. You are never actually alone.",
        source: "Qur'an 57:4; 50:16; 20:46",
      ),
      _AqLesson(
        title: 'The Balance',
        body:
            "'And the heaven He raised and imposed the balance, that you not transgress within the balance' (55:7-8). Justice is built into creation itself; aqeedah that does not end in fairness to people was never understood.",
        source: "Qur'an 55:7-8",
      ),
      _AqLesson(
        title: 'A Creed You Can Carry',
        body:
            "Aqeedah is not an exam to pass; it is a Person to know. What you believe about Allah decides what you believe about your own life. The more beautiful your picture of Him, the braver your worship becomes. Begin where this unit began: Ar-Rahman taught the Qur'an (55:1–2).",
        source: "Qur'an 55:1–2",
      ),
    ],
  ),
];

class AqeedahSchoolScreen extends StatelessWidget {
  const AqeedahSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Aqeedah', close: true),
              Text('العقيدة',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'Who Allah is · what He sent · why it changes a life',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final _AqUnit unit in kAqeedahUnits) ...<Widget>[
                Text(unit.title.toUpperCase(), style: AppText.eyebrow),
                const SizedBox(height: 8),
                for (final _AqLesson l in unit.lessons)
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
