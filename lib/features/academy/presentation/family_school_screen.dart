/// Family Life school — the home as a place of worship: marriage,
/// children, and the daily mercy that runs a household. Built on the
/// modern hadith marriage/parents chapters and the khutbahs on
/// raising children and motherhood.
library;

import '../../../app/core/scholar_review.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _FamLesson {
  const _FamLesson({required this.title, required this.body, required this.practice});
  final String title;
  final String body;
  final String practice;
}

class _FamUnit {
  const _FamUnit({required this.title, required this.frame, required this.lessons});
  final String title;
  final String frame;
  final List<_FamLesson> lessons;
}

const List<_FamUnit> kFamilyUnits = <_FamUnit>[
  _FamUnit(
    title: 'Marriage — Half the Deen',
    frame: 'The Prophet \ufdfa said: when a servant marries, they have completed half of their religion — so let them fear Allah in the remaining half (Bayhaqi). The home is the smallest masjid.',
    lessons: <_FamLesson>[
      _FamLesson(
        title: 'Why Marriage at All',
        body: 'Marriage is described in the Qur\'an with four words: sukun (tranquility), mawaddah (affection), and rahmah (mercy) (30:21). Notice what is missing: passion, romance, excitement. The house runs on mercy the way the body runs on blood.',
        practice: 'Name one act of mercy — not affection, mercy — you can show your spouse or family member this week.',
      ),
      _FamLesson(
        title: 'The Best of You',
        body: 'The best of you is the one who is best to his wife (Tirmidhi 3895, hasan per Darussalam, sahih per al-Albani). And the most complete believer in faith is the one with the best character (Tirmidhi 1162, hasan per Darussalam). The measure of a Muslim is not the masjid face; it is the kitchen face.',
        practice: 'Be gentler at home today than you were at any meeting. Let the family see the best version first.',
      ),
      _FamLesson(
        title: 'Mercy Between You',
        body: 'Allah describes the spouses as \'garments\' for one another (2:187) — the closest thing to the skin, covering faults, providing warmth. The garment does not criticize the body it covers.',
        practice: 'Cover one fault of your spouse or family member today — in speech, in complaint, in your own heart.',
      ),
    ],
  ),
  _FamUnit(
    title: 'Children — The Trust',
    frame: 'Your children are an amanah — a trust. The Prophet \ufdfa said: each of you is a shepherd, and each of you is responsible for his flock (Bukhari 893).',
    lessons: <_FamLesson>[
      _FamLesson(
        title: 'The First Teacher',
        body: 'The mother of every person carries them in weakness upon weakness (31:14) — and the Prophet \ufdfa was asked who most deserves good company: your mother, three times, then your father (Bukhari 5971). The home is a madrasa whether you intend it or not.',
        practice: 'Do one unasked kindness for your mother this week — or, if she has passed, give sadaqah for her.',
      ),
      _FamLesson(
        title: 'Teaching the Prayer',
        body: 'Command your children to pray at seven and discipline them about it at ten, and separate their beds (Abu Dawud 495, hasan sahih per al-Albani). Before seven the prayer is invited, not enforced — love first, law second, so the law lands softer.',
        practice: 'If you have children: pray one prayer this week beside them, unhurried. If you are the child: pray one prayer your parents can see.',
      ),
      _FamLesson(
        title: 'Mercy, Not Severity',
        body: 'The Prophet \ufdfa said: Allah is Merciful and loves mercy in all things (Bukhari 6927). And he never struck a servant or a woman, and never struck anything with his hand except in battle (Muslim 2328). The strongest homes are the gentlest.',
        practice: 'Lower your voice with a child or family member today — once, deliberately, and notice what changes.',
      ),
      _FamLesson(
        title: 'The Best Provision',
        body: 'The best thing a father can give his child is good manners (Tirmidhi 1952, weak per Darussalam). And the most precious inheritance is taqwa — it is the only wealth that cannot be lost, taxed, or inherited away.',
        practice: 'Teach one adab today — how to eat, how to greet, how to knock — by doing it beside them.',
      ),
    ],
  ),
  _FamUnit(
    title: 'The Home as Worship',
    frame: 'The house is not a pause between acts of worship — it is one.',
    lessons: <_FamLesson>[
      _FamLesson(
        title: 'Serving the Family',
        body: 'Aisha was asked what the Prophet \ufdfa did at home. She said: he was in the service of his family (Bukhari 676). He mended his clothes, milked the goat, swept. The man who led the ummah led the dishes.',
        practice: 'Do one household task today before anyone asks — and let it be known only to Allah.',
      ),
      _FamLesson(
        title: 'The Family That Prays',
        body: 'The Prophet \ufdfa said: the one who remembers his Lord and the one who does not are like the living and the dead (Bukhari 6407). Dhikr at the door, before meals, at sleep — small phrases that keep the heart alive.',
        practice: 'Start one dhikr habit at home this week — after Fajr together, or before sleep as a family.',
      ),
      _FamLesson(
        title: 'Forgiveness in the House',
        body: 'The Prophet \ufdfa said: Allah has mercy on the man who is lenient when he sells, when he buys, and when he asks for what is owed (Bukhari 2076). The house needs this most: forgive the harsh word before the day ends.',
        practice: 'Tonight, say \'I forgive you\' or its equivalent to one family member — first to say it is the stronger.',
      ),
    ],
  ),
];

class FamilySchoolScreen extends StatelessWidget {
  const FamilySchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Family Life', close: true),
              const ScholarReviewNote(
                reviewKey: 'school.family-life',
                padding: EdgeInsets.only(bottom: 8),
              ),
              Text('الأسرة',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'Marriage, children, and the home as a place of worship',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final _FamUnit unit in kFamilyUnits) ...<Widget>[
                Text(unit.title.toUpperCase(), style: AppText.eyebrow),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(unit.frame,
                      style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.55)),
                ),
                for (final _FamLesson l in unit.lessons)
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
