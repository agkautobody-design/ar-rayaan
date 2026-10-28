/// End-of-Life school — preparing for death with dignity: the estate,
/// the will, the janazah, and the last words. The most honesty-first
/// school in the academy; written in the app\u2019s dignity register,
/// never morbid, always hope-forward.
library;

import '../../../app/core/scholar_review.dart';
import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _EolLesson {
  const _EolLesson({required this.title, required this.body, required this.practice});
  final String title;
  final String body;
  final String practice;
}

class _EolUnit {
  const _EolUnit({required this.title, required this.frame, required this.lessons});
  final String title;
  final String frame;
  final List<_EolLesson> lessons;
}

const List<_EolUnit> kEndOfLifeUnits = <_EolUnit>[
  _EolUnit(
    title: 'Preparing Before the Hour',
    frame: 'The Prophet \ufdfa said: remember often the destroyer of pleasures — death (Tirmidhi 2307, hasan per Darussalam). Not to darken the day, but to brighten the scale.',
    lessons: <_EolLesson>[
      _EolLesson(
        title: 'Every Soul Will Taste It',
        body: 'Every soul will taste death, and only on the Day of Judgment will you be paid in full (3:185). The verse is not a threat; it is the calendar. The one who knows the appointment prepares for it — and preparation is worship.',
        practice: 'Write one sentence: \'If I knew I had a year, I would...\' Then start one item on that list this week.',
      ),
      _EolLesson(
        title: 'The Will — Writing It Is a Sunna',
        body: 'The Prophet \ufdfa said: it is not right for a Muslim who has something to bequeath to sleep two nights without having his will written (Bukhari 2738). Two nights. The will is not for the dying; it is for the living who will grieve you.\n\nTwo limits apply. First, no more than a third: Sa\u2019d ibn Abi Waqqas asked to leave half and was told it was too much; of one third the Prophet \ufdfa said, \u2018One-third, yet even one-third is too much\u2019 (Bukhari 2744). Second, no bequest to an heir: \u2018Allah has given everyone who has a right his due, so no bequest may be made to an heir\u2019 (Abu Dawud 2870, hasan sahih per al-Albani; Tirmidhi 2120, sahih per al-Albani). The heirs\u2019 shares are fixed by Allah in Surah an-Nisa\u2019, and the will is for people who are not heirs, for debts and for charity.\n\nThe schools: the one-third limit is held in all four schools. The majority hold that a bequest to an heir is not valid unless the other heirs agree after the death. Scholar review needed: ask a scholar of your school before you write it.',
        practice: 'Draft your will this month — even a page: debts, guardianship, the small bequests. Templates exist; the intention is the act.',
      ),
      _EolLesson(
        title: 'The Estate — Fair Before the End',
        body: 'Allah commands you concerning your children: the male receives the share of two females (4:11). That is one rule among several. The shares depend on who survives you (spouse, parents, children, siblings) and are set in Surah an-Nisa\u2019 (4:11, 4:12 and 4:176), so they are Allah\u2019s math, not the family\u2019s negotiation. Debts and the will (up to one third, and not for an heir) are settled before the shares are divided. Working it out for a real family is a scholar\u2019s task: scholar review needed here.',
        practice: 'Learn the inheritance shares of your own household this month — ask a scholar, write it down.',
      ),
      _EolLesson(
        title: 'Plant What Outlives You',
        body: 'When a person dies, their deeds end except three: ongoing charity, knowledge that benefits, and a righteous child who prays for them (Muslim 1631). The grave is not a wall; it is a garden you can still plant.',
        practice: 'Name one sadaqah jariyah you can start this year — even a recurring small gift. Write it down.',
      ),
    ],
  ),
  _EolUnit(
    title: 'The Final Days',
    frame: 'How the believer meets the end is a lesson the living need before the dying.',
    lessons: <_EolLesson>[
      _EolLesson(
        title: 'La Ilaha Illa Allah — the Last Word',
        body: 'The Prophet \ufdfa said: whoever\u2019s last words are la ilaha illa Allah enters Paradise (Abu Dawud 3116, sahih per al-Albani). And he advised: prompt your dying to say it, gently, without burden — the tongue loosens at the end, and the heart follows.',
        practice: 'Memorize the exact words to say beside a dying person. One day you will be the one holding the hand.',
      ),
      _EolLesson(
        title: 'The Prayer Over the Dead',
        body: 'The janazah prayer is offered standing, without bowing or prostration. Four takbirs, salawat on the Prophet, dua for the deceased, and the salah is complete. The community carries the dead to their Lord on its shoulders.',
        practice: 'Attend one janazah this month — even of someone you did not know. The angels attend every one.',
      ),
      _EolLesson(
        title: 'Grieving Is Allowed',
        body: 'The Prophet \ufdfa wept at the death of his son Ibrahim and said: the eyes weep and the heart grieves, and we say only what pleases our Lord — and we are surely saddened by your departure, Ibrahim (Bukhari 1303). Tears are not weakness; the prohibition was only of wailing and despair.',
        practice: 'If you are grieving, give yourself permission — and give the same permission to someone else this week.',
      ),
    ],
  ),
  _EolUnit(
    title: 'Hope Forward',
    frame: 'The school ends where the grave begins: with light.',
    lessons: <_EolLesson>[
      _EolLesson(
        title: 'The Grave Is a Garden',
        body: 'The Prophet \ufdfa said the grave is either a garden from the gardens of Paradise or a pit from the pits of Fire (Tirmidhi 2460, weak per Darussalam — hold it as a reminder, not a ruling). What you send ahead decides which — and the sending is still in your hands.',
        practice: 'Do one deed today that you would want to meet you in the grave — a secret sadaqah, a forgiven debt, a repaired relationship.',
      ),
      _EolLesson(
        title: 'The Meeting You Are Walking Toward',
        body: 'Whoever loves to meet Allah, Allah loves to meet him (Tirmidhi 2309, sahih per Darussalam). The companions lived with this hadith the way travelers live with a map — not in dread of the road, but in anticipation of the arrival.',
        practice: 'Say before sleep: \'O Allah, if You take my soul tonight, forgive it. If You leave it, protect it.\' Three weeks of this changes the night.',
      ),
    ],
  ),
];

class EndOfLifeSchoolScreen extends StatelessWidget {
  const EndOfLifeSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'End of Life', close: true),
              const ScholarReviewNote(
                reviewKey: 'school.end-of-life',
                padding: EdgeInsets.only(bottom: 8),
              ),
              Text('آخر العمر',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'The will, the janazah, the last words — preparing to meet Allah with dignity',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final _EolUnit unit in kEndOfLifeUnits) ...<Widget>[
                Text(unit.title.toUpperCase(), style: AppText.eyebrow),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(unit.frame,
                      style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.55)),
                ),
                for (final _EolLesson l in unit.lessons)
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
