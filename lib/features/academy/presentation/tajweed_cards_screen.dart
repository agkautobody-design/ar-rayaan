/// Tajweed rule cards — taught, not just listed. Every card names its
/// rule, gives colored examples, cites its classical source, and frames
/// the error honestly: Lahn Jali (major — meaning-changing) vs Lahn
/// Khafi (minor — makruh). Sources: Tuhfat al-Atfal / classical ijazah
/// tradition. [Pending scholar review — labels shown on screen.]
library;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

class TajweedCard {
  const TajweedCard({
    required this.title,
    required this.rule,
    required this.examples,
    required this.jaliKhafi,
    required this.source,
    this.colorKey,
  });

  final String title;
  final String rule;
  final List<String> examples;
  final String jaliKhafi;
  final String source;
  final String? colorKey;
}

const List<TajweedCard> kTajweedCards = <TajweedCard>[
  TajweedCard(
    title: 'Noon Sakinah & Tanween — Ikhfa',
    rule:
        'When noon sakinah or tanween is followed by one of 15 letters, hide the noon sound — ghunnah held two counts, tongue approaching the next letter’s position without touching it.',
    examples: <String>['مِن شَرِّ', 'أَنْعَمْتَ', 'مِن شَرِّ ٱلْوَسْوَاسِ'],
    jaliKhafi:
        'Skipping the ghunnah or fully pronouncing the noon is Lahn Jali (major) — it changes the word. Shortening the ghunnah is Lahn Khafi (minor).',
    source: 'Tuhfat al-Atfal, verses 15–18',
    colorKey: 'ikhfa',
  ),
  TajweedCard(
    title: 'Meem Sakinah — Ikhfa Shafawi',
    rule:
        'A meem sakinah followed by ب gets hidden with lip-closure and a two-count ghunnah: not a full meem, not nothing.',
    examples: <String>['تَرْمِيهِم بِحِجَارَةٍ', 'وَمَا هُم بِمُؤْمِنِينَ'],
    jaliKhafi:
        'Fully closing to a meem is Lahn Jali; dropping the ghunnah entirely is Lahn Jali; a short ghunnah is Lahn Khafi.',
    source: 'Tuhfat al-Atfal, verse 30',
    colorKey: 'ikhfa-shafawi',
  ),
  TajweedCard(
    title: 'Qalqalah',
    rule:
        'The letters ق ط ب ج د echo with a slight bounce when sakinah — strongest when stopping on them, softer mid-word, weakest when carrying them.',
    examples: <String>['ٱلْفَلَقِ', 'وَٱلْفَجْرِ', 'عُدْوَانٍۢ فِيهِ'],
    jaliKhafi:
        'Adding an extra vowel (like a fatha) to the echo is Lahn Jali — it adds a letter the Quran did not write. A heavy, drawn-out bounce is Lahn Khafi.',
    source: 'Tuhfat al-Atfal, verse 21',
    colorKey: 'qalqalah',
  ),
  TajweedCard(
    title: 'Madd — Natural Elongation',
    rule:
        'A madd letter (ا و ي) with a harakah before it stretches two counts — the breath’s natural length, never squeezed, never theatrical.',
    examples: <String>['قَالَ', 'يُوسُفُ', 'فِيهِ'],
    jaliKhafi:
        'Cutting a madd to one count is Lahn Khafi in recitation — makruh, meaning unchanged. Making it comically long is also Lahn Khafi.',
    source: 'Tuhfat al-Atfal, verse 28',
    colorKey: 'madd',
  ),
  TajweedCard(
    title: 'Ghunnah',
    rule:
        'The nasal sound of noon and meem — two counts, voiced through the nose, steady, not squeezed.',
    examples: <String>['إِنسَانٌ', 'مِّن مَّاءٍۢ'],
    jaliKhafi:
        'Skipping ghunnah where required is Lahn Jali — the letter is effectively changed. A thin, short ghunnah is Lahn Khafi.',
    source: 'Tuhfat al-Atfal, verse 19',
    colorKey: 'ghunnah',
  ),
  TajweedCard(
    title: 'Heavy & Light Letters (Tafkheem/Tarqeeq)',
    rule:
        'The seven heavy letters — خ ص ض غ ط ق ظ — rise from the tongue’s back; the rest flow light. Rāʾ follows what carries it.',
    examples: <String>['خَلَقْنَا', 'ٱلصَّلَوٰةِ', 'غَيْرِ ٱلْمَغْضُوبِ'],
    jaliKhafi:
        'Making ق sound like ك or ط like ت — the classic meaning-blurring pairs — is Lahn Jali. Slight heaviness/lightness drift is Lahn Khafi.',
    source: 'Tuhfat al-Atfal, verses 20, 33–35',
    colorKey: 'tafkheem',
  ),
];

class TajweedCardsScreen extends StatelessWidget {
  const TajweedCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: kTajweedCards.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const ScreenHeader(title: 'Tajweed — Learned Gently'),
                      Text(
                        'Every mistake has a name. Major errors (Lahn Jali) change meaning — they matter most. Minor ones (Lahn Khafi) are slips to smooth, not sins to fear. An app can hear dropped words; only a human teacher can hear your makhraj — pair these cards with a live teacher. [Content pending scholar review.]',
                        style: AppText.bodyMuted.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                );
              }
              final TajweedCard c = kTajweedCards[i - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  strong: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(c.title,
                          style: AppText.titleMedium
                              .copyWith(color: AppColors.gold)),
                      const SizedBox(height: 8),
                      Text(c.rule,
                          style: AppText.body.copyWith(height: 1.5)),
                      const SizedBox(height: 10),
                      for (final String ex in c.examples)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              ex,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 24,
                                color: AppColors.sand,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(c.jaliKhafi,
                          style: AppText.caption.copyWith(height: 1.5)),
                      const SizedBox(height: 6),
                      Text('Source: ${c.source}',
                          style: AppText.caption
                              .copyWith(color: AppColors.gold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
