/// Arabic Language school — the language of the Qur’an, taught from
/// Qur’anic examples wherever a word is certain. Unit 1 (greetings,
/// family, the definite article) starts the reader on real Arabic, not
/// transliteration.
library;

import '../../../app/core/scholar_review.dart';
import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../reading/presentation/arabic_block.dart';

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
        body: 'As-salamu alaykum — peace be upon you — is a Qur’anic formula: the Prophet \ufdfa is told to greet the believers who come to him with it (6:54), and the angels greet the people of Paradise with \u201cpeace be upon you for what you patiently endured\u201d (13:24). The reply, wa alaykum as-salam, mirrors it. Every time you greet a Muslim, you are speaking Qur’anic Arabic.',
        source: 'Qur’an 6:54; 13:24',
      ),
      _ArLesson(
        title: 'Family Words You Already Own',
        arabic: '\u0623\u064e\u0628\u064c / \u0623\u064f\u0645\u0651\u064c / \u0627\u0628\u0652\u0646\u064c / \u0628\u0650\u0646\u0652\u062a\u064c',
        body: 'Ab (father), umm (mother), ibn/bint (son/daughter) — the same words that carry the Qur’an’s family passages: Yusuf says to his father \u201cya abati\u201d (12:4), a mother carries her child (46:15), Luqman counsels his son (31:13), and Maryam is ibnat ‘Imran (66:12). Learn these four and the family words in many verses will already be familiar.',
        source: 'Qur’an 12:4; 46:15; 31:13; 66:12',
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
        body: 'Allah is the proper Name; rabb is the noun (Lord, Nurturer). In the Qur’an rabb is almost always joined to what it governs — rabbi al-‘alamin (Lord of the worlds), rabbuna (our Lord), rabbuka (your Lord) — rather than standing alone with al-. Watch how the Qur’an uses each word.',
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
        body: 'Iyyaka na’budu — You alone we worship. Iyyaka (You) is placed before the verb; that fronting is what gives the sentence its \u201calone\u201d. Na’budu is the present-tense verb, and the na- at its start means \u201cwe\u201d. Salah is a daily Arabic lesson the body never forgets.',
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
        title: 'The Simplest Sentences',
        arabic: '\u0627\u0644\u0644\u0651\u0647\u064f \u0631\u064e\u0628\u0651\u064f\u0646\u064e\u0627',
        body: 'Arabic needs only two words for a full sentence. Two nouns make a nominal sentence: Allahu rabbuna — Allah is our Lord (42:15), with no word for \u201cis\u201d. A verb and its doer make a verbal sentence: khalaqa Allahu — Allah created (29:44). Most sentences you will read are built from these two patterns.',
        source: 'Qur\'an 42:15; 29:44',
      ),
      _ArLesson(
        title: 'The Verb: Past and Present',
        arabic: '\u062e\u064e\u0644\u064e\u0642\u064e \u0648\u064e\u064a\u064e\u062e\u0644\u064f\u0642\u064f',
        body: 'Khalaqa — He created (past, 96:1). Yakhluqu — He creates (present, 28:68). The past is fixed; the present is alive. Arabic shows time in the verb\'s shape, not in extra words. Learn khalaqa and you have the pattern of a typical three-letter past verb.',
        source: 'Qur\'an 96:1; 28:68',
      ),
      _ArLesson(
        title: 'The Feminine Marker: The Round Ta',
        arabic: '\u0645\u064f\u0624\u0652\u0645\u0650\u0646\u064c \u0648\u064e\u0645\u064f\u0624\u0652\u0645\u0650\u0646\u064e\u0629\u064c',
        body: 'The round ta (\u0629) at the end of a word often marks the feminine: mu\'min (a believing man) and mu\'minah (a believing woman). The Qur\'an uses both: \u201cit is not for a believing man or a believing woman\u201d (33:36). Note that al-Rahman and al-Rahim in the basmala are both masculine forms — the ta marker is a common sign of the feminine, not a rule without exceptions.',
        source: 'Qur\'an 33:36',
      ),
      _ArLesson(
        title: 'The Broken Plural',
        arabic: '\u0643\u064e\u062a\u064e\u0627\u0628\u064c \u2192 \u0643\u064f\u062a\u064f\u0628\u064c',
        body: 'Not every plural adds a sound ending. Kitab (book) becomes kutub (books) — the vowels inside change shape. This is the broken plural, and it is everywhere in the Qur\'an. Learn it as a pattern to recognize, not a rule to fear.',
        source: 'Qur\'an 2:285 (wa-kutubihi)',
      ),
    ],
  ),
  _ArUnit(
    title: 'The Pronouns You Pray With',
    lessons: <_ArLesson>[
      _ArLesson(
        title: 'I, You, He — in the Qur\'an',
        arabic: '\u0625\u0650\u064a\u0651\u064e\u0627\u0643\u064e \u0646\u064e\u0639\u0652\u0628\u064f\u062f\u064f',
        body: 'Ana — I. Anta — you (masculine). Anti — you (feminine). Huwa — he. Hiya — she. In Al-Fatiha you say iyyaka na\'budu — You alone we worship. The -ka is \u201cyou\u201d, and the na- on the verb is \u201cwe\u201d: pronouns can ride inside and on the end of words, invisible until you learn to see them.',
        source: 'Qur\'an 1:5',
      ),
      _ArLesson(
        title: 'The Attached Pronoun: -ka and -ki',
        arabic: '\u0631\u064e\u0628\u0651\u0650\u064a \u0648\u064e\u0631\u064e\u0628\u0651\u064f\u0643\u064e \u0648\u064e\u0631\u064e\u0628\u0651\u064f\u0646\u064e\u0627',
        body: 'Rabbi (my Lord), rabbuka (your Lord, masculine), rabbuki (your Lord, feminine), rabbuna (our Lord). One word, four meanings, one small sound added. This is Arabic\'s economy — a single attached letter carries a whole relationship.',
        source: 'Qur\'an 93:3 (rabbuka); 19:24 (rabbuki); 42:15 (rabbuna)',
      ),
      _ArLesson(
        title: 'The Dual: Two of Something',
        arabic: '\u064a\u064e\u0648\u0652\u0645\u064e\u064a\u0652\u0646\u0650',
        body: 'Yawm (day) becomes yawmayni (two days) — the dual ending -ayni (or -āni when the word is the subject). The Qur\'an uses it precisely: the two gardens of the man in Surah 18 (18:32), and the earth made in two days in Surah 41 (41:9). Arabic counts two as its own number, not as \'two ones.\'',
        source: 'Qur\'an 18:32 (jannatayn); 41:9 (yawmayn)',
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
        source: 'Qur\'an 35:29 (kitaba Allahi)',
      ),
      _ArLesson(
        title: 'Names Are Already Definite',
        arabic: '\u0645\u064f\u062d\u064e\u0645\u0651\u064e\u062f\u064c \u0631\u064e\u0633\u064f\u0648\u0644\u064f \u0627\u0644\u0644\u0651\u0647\u0650',
        body: 'A personal name is already definite, so it never takes al-: Muhammad, never al-Muhammad. Muhammadun rasulu Allah (48:29) is a name followed by an idaafa. A few names also drop the tanwin ending — Ahmadu in 61:6 — a pattern grammarians call a diptote. For now, just notice it.',
        source: 'Qur\'an 48:29; 61:6',
      ),
      _ArLesson(
        title: 'Putting It Together: One Verse, Fully',
        arabic: '\u0627\u0644\u0652\u062d\u064e\u0645\u0652\u062f\u064f \u0644\u0650\u0644\u0651\u0647\u0650 \u0631\u064e\u0628\u0651\u0650 \u0627\u0644\u0652\u0639\u064e\u0627\u0644\u064e\u0645\u064a\u0646\u064e',
        body: 'You now know the parts of this verse: the definite article (al-hamdu, al-‘alamin), the prefix li- meaning \u201cbelongs to\u201d (li-llahi), the idaafa (rabbi al-‘alamin — Lord of the worlds), and the plural ending -in on al-‘alamin (a sound masculine plural). Read it again — you are not transliterating anymore. You are reading.',
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
              const ScholarReviewNote(
                reviewKey: 'school.arabic-language',
                padding: EdgeInsets.only(bottom: 8),
              ),
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
                      blur: false,
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
                            child: ArabicBlock(arabic: l.arabic, arabicSize: 22),
                          ),
                          const SizedBox(height: 8),
                          Text(l.body, style: AppText.body.copyWith(height: 1.65)),
                          const SizedBox(height: 8),
                          Text(l.source, style: AppText.bodyMuted.copyWith(fontSize: 12)),
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
                'Five short units: words, whole verses, sentences, pronouns, and possession — all from the Qur’an itself. This is an introduction to the grammar, not the whole of it.',
                style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
