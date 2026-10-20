/// Arabic Language school — the language of the Qur’an, taught from
/// Qur’anic examples wherever a word is certain. Unit 1 (greetings,
/// family, the definite article) starts the reader on real Arabic, not
/// transliteration.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _ArLesson {
  const _ArLesson({
    required this.title,
    required this.arabic,
    required this.body,
    required this.source,
    this.actionRoute,
    this.actionLabel,
  });

  final String title;
  final String arabic;
  final String body;
  final String source;
  final String? actionRoute;
  final String? actionLabel;
}

class _ArUnit {
  const _ArUnit({required this.title, required this.lessons});
  final String title;
  final List<_ArLesson> lessons;
}

const List<_ArUnit> kArabicUnits = <_ArUnit>[
  _ArUnit(
    title: 'First Words, Real Words',
    lessons: <_ArLesson>[
      _ArLesson(
        title: 'The Greeting Is a Qur’anic Sentence',
        arabic: 'السَلامُ عَلَيكُمْ',
        body: 'As-salamu alaykum — peace be upon you — is a Qur’anic formula (6:54: peace be upon you for what you patiently endured). The reply, wa alaykum as-salam, mirrors it. Every time you greet a Muslim, you are speaking Qur’anic Arabic.',
        source: 'Qur’an 6:54',
      ),
      _ArLesson(
        title: 'Family Words You Already Own',
        arabic: 'أَبٌ / أُمٌّ / ابْنٌ / بنتٌ',
        body: 'Ab (father), umm (mother), ibnu/bint (son/daughter) — the same roots that carry the Qur’an’s family passages (12:100; 71:28). Learn these four and you can read entire family verses without translation.',
        source: 'Qur’an 12:100; 71:28',
      ),
      _ArLesson(
        title: 'The Definite Article: Al-',
        arabic: 'الكِتَابُ — كِتَابٌ',
        body: 'Al- makes a word definite: al-kitabu (the book) vs kitabun (a book). You have seen it thousands of times — al-Fatiha, al-hamdu, al-Rahman. Today, name it.',
        source: 'Grammar note',
      ),
      _ArLesson(
        title: 'Allah Is the Name, Rabb Is the Word',
        arabic: 'اللّهُ رَبُّ الْعَالَمينَ',
        body: 'Allah is the proper Name; rabb is the noun (Lord, Nurturer). You cannot change rabb into ar-rabb the way you can add al- to kitab — some words resist the article. Qur’anic Arabic teaches its own rules.',
        source: 'Qur’an 1:2',
        actionRoute: '/quran',
        actionLabel: 'See it in Al-Fatiha',
      ),
    ],
  ),
  _ArUnit(
    title: 'Reading Whole Verses',
    lessons: <_ArLesson>[
      _ArLesson(
        title: 'Al-Fatiha, Word by Word',
        arabic: 'الْحَمْدُ لِلّهِ رَبِّ الْعَالَمينَ',
        body: 'Al-hamdu (the praise) lillahi (belongs to Allah) rabbi (Lord of) al-alamin (the worlds). Every word here is one you can now name. Read the line slowly — you are reading Arabic, not transliteration.',
        source: 'Qur’an 1:2',
        actionRoute: '/quran',
        actionLabel: 'Recite it in the reader',
      ),
      _ArLesson(
        title: 'The Formula You Say 17 Times a Day',
        arabic: 'إِيَّاكَ نَعْبُدُ',
        body: 'Iyyaka na’budu — You alone we worship. Iyyaka carries the kasra twice (to You alone), and na’budu is the present-tense verb. Salah is a daily Arabic lesson the body never forgets.',
        source: 'Qur’an 1:5',
      ),
      _ArLesson(
        title: 'Slow Is the Standard',
        arabic: 'وَرَتِّلِ القُرْآنَ تَرْتِيلاً',
        body: 'And recite the Qur’an with measured recitation (73:4). Slow enough to hear each letter. Arabic learned slowly stays; Arabic rushed evaporates.',
        source: 'Qur’an 73:4',
      ),
    ],
  ),
  _ArUnit(
    title: 'Building Sentences',
    lessons: <_ArLesson>[
      _ArLesson(
        title: 'The Simplest Sentence: Ism and Fi\'l',
        arabic: '\u0627\u0644\u0644\u0651\u0647\u064f \u0631\u064e\u0628\u0651\u064f\u0646\u064e\u0627',
        body: 'Arabic needs only two words for a full sentence: a name (ism) and an action (fi\'l). Allah rabbuna — Allah is our Lord. The ism \'Allah\' and the fi\'l \'rabbuna\' carry the whole meaning. Every sentence you will ever read is built from these two.',
        source: 'Grammar note',
      ),
      _ArLesson(
        title: 'The Verb: Past and Present',
        arabic: '\u062e\u064e\u0644\u064e\u0642\u064e \u0648\u064e\u064a\u064e\u062e\u0644\u064f\u0642\u064f',
        body: 'Khalaqa — He created (past). Yakhlugu — He creates (present). The past is fixed; the present is alive. Arabic shows time in the verb\'s shape, not in extra words. Learn khalaqa and you have the template for every past verb in the Qur\'an.',
        source: 'Qur\'an 16:40 pattern',
      ),
      _ArLesson(
        title: 'The Feminine Marker: The Round Ta',
        arabic: '\u0631\u064e\u062d\u0650\u064a\u0645\u064c \u0648\u064e\u0631\u064e\u062d\u0650\u064a\u0645\u064e\u0629\u064c',
        body: 'The round ta (\u0629) at the end of a word often marks the feminine: rahim (merciful, masculine) and rahimah (merciful, feminine). The basmala uses both: al-Rahman, al-Rahim — the two most merciful Names, one masculine form, one with the round ta.',
        source: 'Qur\'an 1:1',
      ),
      _ArLesson(
        title: 'The Broken Plural',
        arabic: '\u0643\u064e\u062a\u064e\u0627\u0628\u064c \u2192 \u0643\u064f\u062a\u064f\u0628\u064c',
        body: 'Not every plural adds a sound ending. Kitab (book) becomes kutub (books) — the vowels inside change shape. This is the broken plural, and it is everywhere in the Qur\'an. Learn it as a pattern to recognize, not a rule to fear.',
        source: 'Qur\'an 2:2 (al-kutub)',
      ),
    ],
  ),
  _ArUnit(
    title: 'The Pronouns You Pray With',
    lessons: <_ArLesson>[
      _ArLesson(
        title: 'I, You, He — in the Qur\'an',
        arabic: '\u0623\u064e\u0646\u0627\u0653 \u0623\u064e\u0639\u0652\u0628\u064f\u062f\u064f\u0643\u064e',
        body: 'Ana — I. Anta — you (masculine). Anti — you (feminine). Huwa — he. Hiya — she. In Al-Fatiha you say ana and ka together: a\'budu-ka — I worship You. The pronoun -ka (you) rides on the end of the verb, invisible until you learn to see it.',
        source: 'Qur\'an 1:5',
      ),
      _ArLesson(
        title: 'The Attached Pronoun: -ka and -ki',
        arabic: '\u0631\u064e\u0628\u0651\u0650\u064a \u0648\u064e\u0631\u064e\u0628\u0651\u064f\u0643\u064e \u0648\u064e\u0631\u064e\u0628\u0651\u064f\u0646\u064e\u0627',
        body: 'Rabbi (my Lord), rabbuka (your Lord, masculine), rabbuki (your Lord, feminine), rabbuna (our Lord). One word, four meanings, one small sound added. This is Arabic\'s economy — a single attached letter carries a whole relationship.',
        source: 'Qur\'an 1:2 (rabbina)',
      ),
      _ArLesson(
        title: 'The Dual: Two of Something',
        arabic: '\u064a\u064e\u0648\u0652\u0645\u064e\u064a\u0652\u0646\u0650',
        body: 'Yawm (day) becomes yawmayni (two days) — the dual ending -ayni. The Qur\'an uses it precisely: the two gardens of the man in Surah 18, the two days of creation in Surah 41. Arabic counts two as its own number, not as \'two ones.\'',
        source: 'Qur\'an 18:32 (al-jannatani)',
      ),
    ],
  ),
  _ArUnit(
    title: 'Reading With Possession',
    lessons: <_ArLesson>[
      _ArLesson(
        title: 'The Idaafa: Possession in Two Words',
        arabic: '\u0643\u064e\u062a\u064e\u0627\u0628\u064f \u0627\u0644\u0644\u0651\u0647\u0650',
        body: 'Kitabu Allah — the Book of Allah. Two nouns side by side, and the relationship is possession. The first word loses its \'the\' (kitabu, not al-kitabu); the second keeps it (Allah, already definite). This construction is everywhere — every \'of\' in translation is often an idaafa in Arabic.',
        source: 'Qur\'an 2:2 (kitabu Allah)',
      ),
      _ArLesson(
        title: 'The Diptotes: Names That Refuse',
        arabic: '\u0645\u064f\u062d\u064e\u0645\u0651\u064e\u062f\u064c \u0644\u0627 \u064a\u064e\u0642\u0628\u064e\u0644\u064f \u0627\u0644\u0652',
        body: 'Proper names like Muhammad, Ahmad, and many broken plurals refuse the \'the\' (al-) in certain positions. Muhammadun, not al-Muhammadun. The Qur\'an respects the name\'s dignity — learn to spot the names that stand without the article.',
        source: 'Qur\'an 3:144 (Muhammadun)',
      ),
      _ArLesson(
        title: 'Putting It Together: One Verse, Fully',
        arabic: '\u0627\u0644\u0652\u062d\u064e\u0645\u0652\u062f\u064f \u0644\u0650\u0644\u0651\u0647\u0650 \u0631\u064e\u0628\u0651\u0650 \u0627\u0644\u0652\u0639\u064e\u0627\u0644\u064e\u0645\u064a\u0646\u064e',
        body: 'You now know every word of this verse: the definite article (al-), the idaafa (lillahi), the attached pronoun (implicit in lillahi), the noun of lordship (rabbi), the broken plural (alamin). Read it again — you are not transliterating anymore. You are reading.',
        source: 'Qur\'an 1:2',
        actionRoute: '/quran',
        actionLabel: 'Read it in the reader',
      ),
    ],
  ),
];

class ArabicLanguageSchoolScreen extends StatelessWidget {
  const ArabicLanguageSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Arabic Language', close: true),
              Text('العربية',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'The language of the Qur’an — from the words you already say',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final _ArUnit unit in kArabicUnits) ...<Widget>[
                Text(unit.title.toUpperCase(), style: AppText.eyebrow),
                const SizedBox(height: 8),
                for (final _ArLesson l in unit.lessons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      strong: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l.title, style: AppText.titleMedium),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.night,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(l.arabic,
                                textAlign: TextAlign.right,
                                style: AppText.arabic
                                    .copyWith(fontSize: 22, color: AppColors.goldLight)),
                          ),
                          const SizedBox(height: 8),
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
              Text(
                'Unit 1 begins the sequence: words → sentences → grammar, all from the Qur’an itself. Deeper units arrive in the next wave.',
                style: AppText.bodyMuted.copyWith(fontSize: 11, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
