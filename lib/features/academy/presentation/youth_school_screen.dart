/// Youth school — for the generation growing up with a phone in their
/// hand and the ummah in their heart: identity, friends, social media,
/// and money. Built on the modern hadith youth chapters and the
/// khutbahs on the phone and anxiety.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_scaffold.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _YouthLesson {
  const _YouthLesson({required this.title, required this.body, required this.practice});
  final String title;
  final String body;
  final String practice;
}

class _YouthUnit {
  const _YouthUnit({required this.title, required this.frame, required this.lessons});
  final String title;
  final String frame;
  final List<_YouthLesson> lessons;
}

const List<_YouthUnit> kYouthUnits = <_YouthUnit>[
  _YouthUnit(
    title: 'Identity — Who You Are',
    frame: 'Seventy percent of young Muslims have faced Islamophobia; the question 'who am I?' arrives earlier than it used to. The answer arrived first: you are a khaleefah — a successor of Adam (2:30), created with purpose, honored above much of creation (17:70).',
    lessons: <_YouthLesson>[
      _YouthLesson(
        title: 'The Honor You Were Born With',
        body: 'Allah says He honored the children of Adam (17:70) — not some of them, not the famous ones. The bullying at school, the stares on the street — they are real, and they are not the verdict. The verdict was issued by the One who made you.',
        practice: 'Write one sentence: 'Allah honored me because...' and finish it truthfully. Keep it where you will see it.',
      ),
      _YouthLesson(
        title: 'Chosen — Adam\'s Answer',
        body: 'When Allah announced the khilafah to the angels, they asked about one who sheds blood; He said: I know that which you do not know (2:30). You were created with a purpose the angels could not see. Doubt about your worth is not humility — it is a miscount.',
        practice: 'Name one thing you are good at that could serve the ummah — even small. That is the 'which you do not know' spoken over you.',
      ),
      _YouthLesson(
        title: 'The Best Generation',
        body: 'The Prophet \ufdfa said the best generation is his, then the next, then the next (Bukhari 2652). You are not a latecomer to the deen — you are the generation the hadith was waiting for.',
        practice: 'Pick one sunnah of the Prophet \ufdfa you can practice this week that your friends will notice — and let them ask about it.',
      ),
    ],
  ),
  _YouthUnit(
    title: 'The Phone — Your Twenty-First Century Companion',
    frame: 'The average teenager checks their phone over a hundred times a day. The Prophet \ufdfa said the strong is the one who controls himself (Bukhari 6114) — he just never imagined the controller would glow.',
    lessons: <_YouthLesson>[
      _YouthLesson(
        title: 'The Scroll That Eats the Hour',
        body: 'The five prayers are five anchors a day; the feed is a current that pulls you under for hours. The Prophet \ufdfa warned about a time when a man\'s own family would be safer from him than a stranger (Bukhari 2082) — screens make strangers of us at our own dinner tables.',
        practice: 'One meal this week: no phone at the table. Everyone. See who speaks first.',
      ),
      _YouthLesson(
        title: 'The Feed Is Not Real',
        body: 'You are comparing your inside to everyone else\'s outside. The filtered life is a storefront, not a home — and Allah looks at hearts (Bukhari 54), not likes. Imam Ghazali wrote nine hundred years ago about the dunya: it is like a dream; laugh a little, weep a little, and it is gone.',
        practice: 'Unfollow five accounts that make you feel small. Follow one that makes you want to pray.',
      ),
      _YouthLesson(
        title: 'Guarding the Gaze',
        body: 'Tell the believing men to lower their gaze and guard their chastity (24:30) — and the believing women likewise (24:31). The screen made the gaze the easiest sin in history; the verse did not change. Your eyes are an amanah too.',
        practice: 'Set one screen limit this week — a time, an app, a feed. Start small; the muscle grows.',
      ),
    ],
  ),
  _YouthUnit(
    title: 'Friends & Money',
    frame: 'The two currencies of youth: the people around you and the money you do not yet have. Both are tests.',
    lessons: <_YouthLesson>[
      _YouthLesson(
        title: 'You Are the Average of Your Five',
        body: 'A person is upon the religion of his friend — so let one of you look at whom he befriends (Tirmidhi 2378). The friend who drags you to prayer is worth more than the one who drags you to everything else. Choose the friend your future self will thank you for.',
        practice: 'Name your closest three friends. Which one would you become if you became exactly like them?',
      ),
      _YouthLesson(
        title: 'Halal Money — Even the Penny',
        body: 'The Prophet \ufdfa said: leave that which makes you doubt for that which does not (Tirmidhi 2518). The gig economy, the hustle, the side scheme — the barakah is in the clean dirham, even when the unclean one is bigger.',
        practice: 'Check one source of your money or a deal you are considering. Run the doubt test.',
      ),
      _YouthLesson(
        title: 'Seven Under the Shade',
        body: 'Seven whom Allah will shade on the Day there is no shade but His — among them a youth who grew up in the worship of Allah (Bukhari 660). The hadith names the youth specifically. Your energy, your free evenings, your strong memory — they are capital no billionaire can buy back.',
        practice: 'Spend thirty minutes this week on one act of worship you cannot do when you are older and busier — memorization, night prayer, learning Arabic.',
      ),
    ],
  ),
];

class YouthSchoolScreen extends StatelessWidget {
  const YouthSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Youth', close: true),
              Text('الشباب',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'Identity, the phone, friends, and money — the tests of a generation',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final _YouthUnit unit in kYouthUnits) ...<Widget>[
                Text(unit.title.toUpperCase(), style: AppText.eyebrow),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(unit.frame,
                      style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.55)),
                ),
                for (final _YouthLesson l in unit.lessons)
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
