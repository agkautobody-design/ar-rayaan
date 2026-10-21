/// Duʿa & Adhkar school — the teaching wrapper over the adhkar module.
/// The adhkar CONTENT is owned by features/adhkar (formats, doesn't
/// duplicate); this screen adds the pedagogy: what the words mean,
/// when the Prophet ﷺ taught them, and a memory nudge that routes to
/// the module itself.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _DuaLesson {
  const _DuaLesson({
    required this.title,
    required this.arabic,
    required this.meaning,
    required this.when,
    required this.source,
  });

  final String title;
  final String arabic;
  final String meaning;
  final String when;
  final String source;
}

const List<_DuaLesson> kDuaLessons = <_DuaLesson>[
  _DuaLesson(
    title: 'Ayat al-Kursi — after Fajr, protection',
    arabic:
        'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ',
    meaning:
        'Allah — there is no god but He, the Ever-Living, the Sustainer. Neither drowsiness nor sleep overtakes Him… (2:255) — the Prophet ﷺ said nothing prevents him who recites it from entering Paradise but death (Nasai).',
    when: 'After each obligatory prayer, and morning/evening.',
    source: 'Qur’an 2:255 · reported in an-Nasa’i (ungraded here; number not verified)',
  ),
  _DuaLesson(
    title: 'Sayyid al-Istighfar — the master of seeking forgiveness',
    arabic:
        'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ',
    meaning:
        'O Allah, You are my Lord; there is no god but You. You created me and I am Your servant… Whoever says it with conviction morning or evening and dies that day enters Paradise (Bukhari 6306).',
    when: 'Morning and evening.',
    source: 'Bukhari 6306',
  ),
  _DuaLesson(
    title: 'Before sleeping',
    arabic:
        'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
    meaning:
        'In Your name, O Allah, I die and I live. The Prophet ﷺ would place his right hand under his cheek and say it (Bukhari 6314).',
    when: 'On lying down to sleep.',
    source: 'Bukhari 6314',
  ),
  _DuaLesson(
    title: 'Before eating',
    arabic: 'بِسْمِ اللَّهِ',
    meaning:
        'In the name of Allah. The Prophet ﷺ said: mention Allah’s name, eat with your right hand, and eat from what is nearest (Muslim 2022).',
    when: 'Before the first bite.',
    source: 'Muslim 2022',
  ),
  // --- Morning & evening -----------------------------------------------
  _DuaLesson(
    title: 'The Three Quls — the evening shield',
    arabic:
        'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
    meaning:
        'Say: He is Allah, One… Say: I seek refuge in the Lord of daybreak… Say: I seek refuge in the Lord of mankind (112–114). The Prophet ﷺ taught them morning and evening three times — they suffice the servant against everything.',
    when: 'Morning and evening, three times each.',
    source: 'Abu Dawud 5082, hasan per al-Albani; Tirmidhi 3575, hasan per Darussalam',
  ),
  _DuaLesson(
    title: 'Leaving the home — the morning departure',
    arabic:
        'بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    meaning:
        'In the name of Allah; I place my trust in Allah; there is no might nor power except with Allah (Abu Dawud 5095, sahih per al-Albani). Taught as the morning\'s first sentence when the foot crosses the threshold.',
    when: 'When leaving the house.',
    source: 'Abu Dawud 5095, sahih per al-Albani',
  ),

  // --- Home & table ------------------------------------------------------
  _DuaLesson(
    title: 'After eating — the thanked meal',
    arabic:
        'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِينَ',
    meaning:
        'Praise be to Allah who fed us, gave us drink, and made us Muslims (Tirmidhi 3457, weak per Darussalam). The meal becomes worship when the end matches the beginning.',
    when: 'After finishing a meal.',
    source: 'Tirmidhi 3457, weak per Darussalam',
  ),
  _DuaLesson(
    title: 'Entering the home — the threshold greeting',
    arabic:
        'بِسْمِ اللَّهِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ الْمَوْلَجِ وَخَيْرَ الْمَخْرَجِ',
    meaning:
        'In the name of Allah. O Allah, I ask You for the good of entering and the good of leaving (Abu Dawud 5096, weak per al-Albani). The home is entered with His name, not with the day\'s residue.',
    when: 'When entering the house.',
    source: 'Abu Dawud 5096, weak per al-Albani',
  ),

  // --- Masjid ------------------------------------------------------------
  _DuaLesson(
    title: 'Entering the mosque — asking the doors of mercy',
    arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
    meaning:
        'O Allah, open for me the doors of Your mercy (Muslim 713). Said with the right foot at the mosque\'s door.',
    when: 'Entering the mosque.',
    source: 'Sahih Muslim 713',
  ),
  _DuaLesson(
    title: 'After the prayer — the closing words',
    arabic:
        'أَسْتَغْفِرُ اللَّهَ (×٣) اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ',
    meaning:
        'I seek Allah\'s forgiveness (three times). O Allah, You are Peace and from You comes peace… (Muslim 591). The prayer does not end; it hands you to the next worship.',
    when: 'After each obligatory prayer.',
    source: 'Sahih Muslim 591',
  ),

  // --- Travel & hardship -------------------------------------------------
  _DuaLesson(
    title: 'Boarding any transport — the borrowed ride',
    arabic:
        'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ',
    meaning:
        'Glory to Him who subjected this to us, and we could never have accomplished it ourselves (43:13). The Prophet ﷺ recited it mounting his ride, then said Allahu Akbar three times (Muslim 1342).',
    when: 'Boarding a vehicle, mount, or seat of travel.',
    source: 'Qur\'an 43:13; Sahih Muslim 1342',
  ),
  _DuaLesson(
    title: 'In distress — the dua of the afflicted',
    arabic:
        'لَا إِلَٰهَ إِلَّا اللَّهُ الْعَظِيمُ الْحَلِيمُ، لَا إِلَٰهَ إِلَّا اللَّهُ رَبُّ الْعَرْشِ الْعَظِيمِ',
    meaning:
        'There is no god but Allah, the Magnificent, the Forbearing; there is no god but Allah, Lord of the Mighty Throne (Bukhari 6346). The Prophet ﷺ taught it to the distressed as a prayer Allah does not refuse.',
    when: 'In any hardship, anxiety, or tightness of the chest.',
    source: 'Sahih al-Bukhari 6346',
  ),
  _DuaLesson(
    title: 'Hasbunallahu wa ni\'mal wakil — the sufficiency clause',
    arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
    meaning:
        'Allah is sufficient for us, and He is the best Disposer of affairs (3:173) — the words of the believers in 3:173 when they were warned that people had gathered against them. Spoken, the chest loosens.',
    when: 'When facing what you cannot control.',
    source: "Qur'an 3:173",
  ),
  _DuaLesson(
    title: 'The master of forgiveness — morning anchor',
    arabic:
        'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ',
    meaning:
        'O Allah, You are my Lord; there is no god but You. You created me and I am Your servant… (Bukhari 6306). Whoever says it with conviction in the morning or evening and dies that day or night enters Paradise.',
    when: 'Morning and evening.',
    source: 'Sahih al-Bukhari 6306',
  ),
];

class DuaSchoolScreen extends StatelessWidget {
  const DuaSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              const ScreenHeader(title: 'Duʿa & Adhkar'),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'A dua you understand is worth more than a hundred recited blindly. Learn the meaning here; practice inside the Dhikr & Duʿa module, anchored to your prayer times. [Content pending scholar review.]',
                  style: AppText.bodyMuted.copyWith(height: 1.5),
                ),
              ),
              for (final _DuaLesson l in kDuaLessons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    strong: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(l.title,
                            style: AppText.titleMedium
                                .copyWith(color: AppColors.gold)),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            l.arabic,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 22,
                              height: 1.6,
                              color: AppColors.sand,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(l.meaning,
                            style: AppText.body.copyWith(height: 1.5)),
                        const SizedBox(height: 8),
                        Text('When: ${l.when}',
                            style: AppText.caption),
                        Text('Source: ${l.source}',
                            style: AppText.caption
                                .copyWith(color: AppColors.gold)),
                      ],
                    ),
                  ),
                ),
              GlassCard(
                onTap: () => context.go('/adhkar'),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.wb_sunny_outlined, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Open Dhikr & Duʿa to practice',
                          style: AppText.body),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.gold),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
