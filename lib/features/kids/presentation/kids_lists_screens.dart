import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';

import '../../../app/core/child_mode.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../domain/child_duas.dart';

/// One short surah in the children's list.
class _KidSurah {
  const _KidSurah(this.number, this.name, this.gloss, this.ayat);

  final int number;
  final String name;

  /// A well-known English name for it, or empty.
  final String gloss;
  final int ayat;
}

// The numbers are exactly [kChildSurahs]; a test keeps the two together.
const List<_KidSurah> _surahs = <_KidSurah>[
  _KidSurah(1, 'Al-Fatihah', 'The Opening', 7),
  _KidSurah(103, 'Al-Asr', 'The Time', 3),
  _KidSurah(105, 'Al-Fil', 'The Elephant', 5),
  _KidSurah(106, 'Quraysh', '', 4),
  _KidSurah(107, 'Al-Ma’un', '', 7),
  _KidSurah(108, 'Al-Kawthar', 'Abundance', 3),
  _KidSurah(109, 'Al-Kafirun', '', 6),
  _KidSurah(110, 'An-Nasr', 'Help', 3),
  _KidSurah(112, 'Al-Ikhlas', 'Sincerity', 4),
  _KidSurah(113, 'Al-Falaq', 'The Daybreak', 5),
  _KidSurah(114, 'An-Nas', 'The People', 6),
];

/// The surah numbers this screen lists (for the test that ties it to
/// [kChildSurahs]).
List<int> get kidsSurahListNumbers => <int>[
      for (final _KidSurah s in _surahs) s.number,
    ];

/// /kids/surahs - the short surahs a child can open, as big buttons.
class KidsSurahsScreen extends StatelessWidget {
  const KidsSurahsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScenicScaffold.pattern(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: <Widget>[
            const ScreenHeader(title: 'Short surahs', showSettings: false),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
              child: Text(
                'Pick a surah to read and listen to. A grown-up can sit with '
                'you.',
                style: AppText.body.copyWith(fontSize: 17, height: 1.4),
              ),
            ),
            for (final _KidSurah s in _surahs)
              if (kChildSurahs.contains(s.number))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    key: Key('kids-surah-${s.number}'),
                    strong: true,
                    semanticsLabel: '${s.name}'
                        '${s.gloss.isEmpty ? '' : ', ${s.gloss}'}. '
                        '${s.ayat} ayat.',
                    onTap: () => context.open(AppRoutes.surah(s.number)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.menu_book_outlined,
                          size: 34,
                          color: AppColors.goldLight,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                s.name,
                                style:
                                    AppText.titleMedium.copyWith(fontSize: 20),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.gloss.isEmpty
                                    ? '${s.ayat} ayat'
                                    : '${s.gloss} · ${s.ayat} ayat',
                                style:
                                    AppText.bodyMuted.copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.gold.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// /kids/duas - the short duas a child can open, each with a meaning written
/// for a child on its own page.
class KidsDuasScreen extends StatelessWidget {
  const KidsDuasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScenicScaffold.pattern(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: <Widget>[
            const ScreenHeader(title: 'Duas', showSettings: false),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
              child: Text(
                'A dua is a way of talking to Allah. Pick one and say it '
                'together, a few words at a time.',
                style: AppText.body.copyWith(fontSize: 17, height: 1.4),
              ),
            ),
            for (final ChildDua d in kChildDuas)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  key: Key('kids-dua-${d.storyId}'),
                  strong: true,
                  semanticsLabel: '${d.title}. ${d.when}.',
                  onTap: () => context.open(
                    '${AppRoutes.storyReader}?id=${d.storyId}',
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.back_hand_outlined,
                        size: 34,
                        color: AppColors.goldLight,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              d.title,
                              style: AppText.titleMedium.copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              d.when,
                              style: AppText.bodyMuted.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.gold.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
