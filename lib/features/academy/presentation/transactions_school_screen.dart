/// Transactions school — halal earnings, riba, zakat in practice, and
/// honest trade. Built on the huda wealth guides and the khutbahs on
/// anxiety, debt, and burnout.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _TrxLesson {
  const _TrxLesson({required this.title, required this.body, required this.practice});
  final String title;
  final String body;
  final String practice;
}

class _TrxUnit {
  const _TrxUnit({required this.title, required this.frame, required this.lessons});
  final String title;
  final String frame;
  final List<_TrxLesson> lessons;
}

const List<_TrxUnit> kTransactionUnits = <_TrxUnit>[
  _TrxUnit(
    title: 'Halal Earnings',
    frame: 'The halal dirham is not just legal — it is blessed. The barakah is in the honesty, not the amount.',
    lessons: <_TrxLesson>[
      _TrxLesson(
        title: 'Do Not Consume Unjustly',
        body: 'And do not consume one another\u2019s wealth unjustly, nor use it to bribe judges (2:188). Even when the trade is by mutual consent, the unjust line can still be crossed — the verse names the temptation before it happens.',
        practice: 'Audit one income source this week: does it pass the 2:188 test? If gray, seek a scholar.',
      ),
      _TrxLesson(
        title: 'The Birds Leave Hungry',
        body: 'The Prophet \ufdfa said: if you relied upon Allah as He should be relied upon, He would provide you as He provides the birds — they leave hungry in the morning and return full (Tirmidhi 2344, hasan per Darussalam). Rizq is not chased; it is met.',
        practice: 'Name one thing you chase in fear. This week, chase it with tawakkul instead — plan, then release.',
      ),
      _TrxLesson(
        title: 'The Honest Measure',
        body: 'Woe to the defrauders — those who take full measure when they receive, but give less when they measure for others (83:1-3). The Prophet \ufdfa passed by a heap of food, put his hand in it, and found it wet underneath — the seller had watered the top. He said: the one who cheats is not one of us (Muslim 102).',
        practice: 'Check one measure this week — a scale, a deadline, a promise. Make it exact.',
      ),
      _TrxLesson(
        title: 'Honest Work Over Easy Wealth',
        body: 'The Prophet \ufdfa said: Allah loves a servant who is pious, independent, and hidden (Muslim 2965). And the honest laborer is better than the one who begs persistently — the hand that works is raised in dua, the hand that only receives is lowered.',
        practice: 'Do one hour of honest work this week that no one will see or praise — write, build, fix, deliver.',
      ),
    ],
  ),
  _TrxUnit(
    title: 'Riba — The War You Declared',
    frame: 'Allah declares war on the riba-taker (2:278-279). No other sin gets this word.',
    lessons: <_TrxLesson>[
      _TrxLesson(
        title: 'What Riba Actually Is',
        body: 'Riba is stipulated increase on a loan — interest, usury. Allah permitted trade and forbidden riba (2:275). The lender is not an investor; a loan is a trust, not a product. The distinction matters more as every app offers \'buy now, pay later.\'',
        practice: 'Check one of your financial products this week: is any charge stipulated on the loan itself? Ask a scholar about it.',
      ),
      _TrxLesson(
        title: 'The Riba Economy',
        body: 'Riba consumes wealth the way fire consumes what it touches (2:275). The global economy runs on it — which does not make it halal; it makes escape a discipline. Start small: one riba-based habit exited this year is a jihad.',
        practice: 'Name one riba-adjacent habit (a card balance carried, a BNPL plan). Set an exit date — even a year away — and write it down.',
      ),
      _TrxLesson(
        title: 'Leaving Riba With Dignity',
        body: 'If you are in riba and fear poverty, Allah promises that leaving it opens the door of relief (2:280). The exit is not a loss; it is a declaration of which side of the war you are on. Scholars can help structure the transition — you are not the first to leave.',
        practice: 'If you carry riba debt, make one repayment above the minimum this month — and tell no one but Allah.',
      ),
    ],
  ),
  _TrxUnit(
    title: 'Zakat in Practice & Wealth That Purifies',
    frame: 'The third pillar in the modern wallet: savings, investments, retirement accounts.',
    lessons: <_TrxLesson>[
      _TrxLesson(
        title: 'Zakat on Savings',
        body: 'Zakat is due on zakatable wealth — cash, gold, trade goods — held above the nisab (85 grams of gold) for one lunar year, at 2.5% (see the huda-zakat guide). The recipients are named in one verse (9:60): the poor, the needy, the administrators, those whose hearts are to be reconciled, freeing captives, the debt-ridden, in Allah\u2019s cause, and the stranded traveler.',
        practice: 'Open the zakat guide this week and run the numbers — even if you are below nisab, learn the calculation.',
      ),
      _TrxLesson(
        title: 'Debt and the Door',
        body: 'The Prophet \ufdfa said: whoever leaves a debt, Allah will pay it on their behalf (Bukhari 2387). And he would not pray the janazah of one who left a debt until someone pledged to cover it. Debt is a weight — but the weight has a door, and the door is intention plus effort.',
        practice: 'If you carry debt, write the total down, make a plan, and say the dua of the indebted. Face the number.',
      ),
      _TrxLesson(
        title: 'The Cure for Burnout Is Barakah',
        body: 'The anxious professional checks everything twice and sleeps poorly; the believer works the same hours and sleeps differently. Not because the work is lighter — but because the rizq is Someone else\u2019s to give. The sabbath of the soul is prayer in the middle of the hustle.',
        practice: 'Protect one prayer this week the way you protect a meeting — calendar it, guard it, attend it.',
      ),
    ],
  ),
];

class TransactionsSchoolScreen extends StatelessWidget {
  const TransactionsSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Transactions & Finance', close: true),
              Text('المعاملات',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'Halal earnings, riba, zakat in practice, and wealth that purifies',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final _TrxUnit unit in kTransactionUnits) ...<Widget>[
                Text(unit.title.toUpperCase(), style: AppText.eyebrow),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(unit.frame,
                      style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.55)),
                ),
                for (final _TrxLesson l in unit.lessons)
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
