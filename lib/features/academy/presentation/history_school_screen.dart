/// History school — the centuries after the Prophet \ufdfa, era by era.
/// Built on what the library already holds: the companions collection
/// (which includes the four rightly-guided caliphs) and the tales of the
/// early and later periods. Eras with no existing chapter are named in
/// the frame so the road ahead is honest, not empty.
library;

import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _HistEra {
  const _HistEra({
    required this.title,
    required this.frame,
    required this.chapters,
  });

  final String title;
  final String frame;
  final List<_HistChapter> chapters;
}

class _HistChapter {
  const _HistChapter({required this.title, required this.note, this.storyId});

  final String title;
  final String note;
  final String? storyId;
}

const List<_HistEra> kHistoryEras = <_HistEra>[
  _HistEra(
    title: 'The Rashidun — The Righteous Twenty-Nine Years',
    frame:
        'Abu Bakr saved the community from collapsing into apostasy in his two years. Umar spread justice so far the Nile is said to have blessed his letter. Uthman gathered the Quran into one book. Ali carried the law through the first fitna. Four caliphs, one standard: the Prophet\u2019s example, not their own ambition.',
    chapters: <_HistChapter>[
      _HistChapter(
        title: 'Abu Bakr — The Steady One',
        note: 'The first caliph: \'If you worship Muhammad, know that he has died; but if you worship Allah, He lives and does not die.\' He saved zakat and saved the deen in two years.',
        storyId: 'comp-abu-bakr',
      ),
      _HistChapter(
        title: 'Umar — Justice on Horseback',
        note: 'The second caliph, who patrolled Medina at night and answered to no one but Allah — the milk-seller\u2019s story is his most told parable of fairness.',
        storyId: 'comp-umar',
      ),
      _HistChapter(
        title: 'The Pot of Milk',
        note: 'A report (Muwatta Malik, through Zayd ibn Aslam) that Umar made himself vomit milk he learned came from the zakat camels. A report, not an eyewitness chain; not yet scholar-reviewed.',
        storyId: 'tale-umar-milk',
      ),
      _HistChapter(
        title: 'Uthman — The Gatherer of the Quran',
        note: 'The third caliph: gentle by nature, decisive when it mattered — he ordered the one mushaf, and the ummah has read from it ever since.',
        storyId: 'comp-uthman',
      ),
      _HistChapter(
        title: 'Ali — Raised in the Prophet\u2019s House',
        note: 'The fourth caliph, raised in the Prophet\u2019s house — the era\u2019s scholarship begins with him.',
        storyId: 'comp-ali',
      ),
    ],
  ),
  _HistEra(
    title: 'The Generations After — Scholars and Judges',
    frame:
        'From the generation after the companions come the judges, the ascetics, and the scholars whose names became disciplines. The library\u2019s Tales collection carries these voices.',
    chapters: <_HistChapter>[
      _HistChapter(
        title: 'Uwais al-Qarni — Who Honored a Mother',
        note: 'He never met the Prophet \ufdfa, yet the Prophet praised him from afar — for how he treated his mother.',
        storyId: 'tale-uwais',
      ),
      _HistChapter(
        title: 'Jurayj — The Ascetic and the Mother',
        note: 'His mother called him while he prayed, and heaven itself corrected him — worship never outranks the one who raised you.',
        storyId: 'tale-jurayj',
      ),
      _HistChapter(
        title: 'Barsisa — A Tale We Cannot Verify',
        note: 'A monk\u2019s tale some commentaries tell about 59:16. The app does not retell it; it gives the Qur\u2019an\u2019s parable of Shaytan instead.',
        storyId: 'tale-barsisa',
      ),
      _HistChapter(
        title: 'Khalid — Words on His Deathbed',
        note: 'The words reported on Khalid ibn al-Walid\u2019s deathbed (Ibn al-Athir, Usd al-Ghaba; a seerah report, not from the six books, not yet scholar-reviewed).',
        storyId: 'tale-khalid-letter',
      ),
      _HistChapter(
        title: 'The Boy-King — Which World Is Real?',
        note: 'The question that has launched a thousand history seminars: what if power, and not poverty, is the dream?',
        storyId: 'tale-boy-king',
      ),
    ],
  ),
  _HistEra(
    title: 'The Later Ages — Empires, Andalus, Ottoman',
    frame:
        'The story continues: Cordoba\u2019s libraries when Europe\u2019s were dark, Baghdad\u2019s House of Wisdom, the Ottoman centuries holding the two Harams. These eras are named here as the road ahead — the library\u2019s next historical chapters will walk them. What never changes: the carriers of this deen are remembered for their scholarship and their mercy, never their conquests.',
    chapters: <_HistChapter>[
      _HistChapter(
        title: 'Baghdad\u2019s House of Wisdom',
        note: 'In the 9th century, Baghdad\u2019s scholars translated the world\u2019s knowledge into Arabic — Greek philosophy, Indian mathematics, Persian medicine — and added to it algebra (al-Khwarizmi), optics (Ibn al-Haytham), and the hospitals. The empire\u2019s armies carried the message; its scholars carried the light.',
        storyId: null,
      ),
      _HistChapter(
        title: 'Cordoba — The City of Light',
        note: 'While much of Europe\u2019s libraries were closed, Cordoba\u2019s were open — over 70,000 manuscripts, streetlights, and public baths, all while the Quran was recited in the Great Mosque. When the library of Cordoba was catalogued, it filled 44 volumes. The scholars outlived the swords.',
        storyId: null,
      ),
      _HistChapter(
        title: 'The Ottoman Centuries',
        note: 'For 600 years, the Ottomans held the two Harams and the three continents — and their sultans slept in humility while the empire\u2019s greatest monuments were mosques and madrasas. The empire fell; the Quran it protected never did.',
        storyId: null,
      ),
      _HistChapter(
        title: 'The Scholars Outlived the Empires',
        note: 'Empires rose on the map and vanished from it; the Quran, the hadith collections, and the law schools remained — and still govern the daily life of two billion people. Ibn Taymiyyah died in a citadel; Imam Ghazali died with his head on his books. Their works never died. That is the history worth remembering.',
        storyId: null,
      ),
    ],
  ),
];

class HistorySchoolScreen extends StatelessWidget {
  const HistorySchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Islamic History', close: true),
              Text('التاريخ',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'The centuries after the Prophet \ufdfa — caliphs, scholars, and the ages they carried',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final _HistEra era in kHistoryEras) ...<Widget>[
                Text(era.title.toUpperCase(), style: AppText.eyebrow),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(era.frame,
                      style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.55)),
                ),
                for (final _HistChapter ch in era.chapters)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      blur: false,
                      // A chapter that has a story in the library opens it.
                      onTap: ch.storyId == null
                          ? null
                          : () => context.open(
                                '${AppRoutes.storyReader}?id=${Uri.encodeQueryComponent(ch.storyId!)}',
                              ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(children: <Widget>[
                            Expanded(
                              child: Text(ch.title, style: AppText.body.copyWith(
                                  fontWeight: FontWeight.w600, fontSize: 13.5)),
                            ),
                            if (ch.storyId != null)
                              const Icon(Icons.chevron_right,
                                  size: 18, color: AppColors.gold),
                          ]),
                          const SizedBox(height: 4),
                          Text(ch.note, style: AppText.bodyMuted.copyWith(
                              fontSize: 12, height: 1.5)),
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
