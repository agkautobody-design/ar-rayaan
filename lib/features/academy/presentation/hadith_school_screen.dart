/// Hadith school — Imam an-Nawawi\u2019s Forty, taught one hadith per
/// lesson: the text, what it means, and the character it builds. The
/// collection itself lives in assets/hadith/nawawi40.json and is read
/// by the hadith feature; this school is the curriculum around it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_scaffold.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../hadith/application/hadith_providers.dart';

/// The teaching layer for the Forty: one entry per hadith in sequence.
/// Keep in sync with assets/hadith/nawawi40.json order (n 1..40).
class _HadithLesson {
  const _HadithLesson({
    required this.title,
    required this.meaning,
    required this.character,
  });

  final String title;
  final String meaning;
  final String character;
}

const List<_HadithLesson> kHadithLessons = <_HadithLesson>[
  _HadithLesson(
    title: 'Hadith 1 — Actions Are by Intentions',
    meaning:
        'The Prophet \ufdfa said: actions are only by intentions, and every person shall have only what they intended. Migration for Allah and His Messenger is for Allah; migration for worldly gain or marriage is for that. This hadith is one third of knowledge (as the scholars counted) because intention decides the value of everything that follows it.',
    character: 'Check the why before the what — one intention today, named.',
  ),
  _HadithLesson(
    title: 'Hadith 2 — The Core of the Matter',
    meaning:
        'Islam is built on five: the testimony that none is worthy of worship but Allah and Muhammad is His Messenger, establishing prayer, giving zakat, fasting Ramadan, and Hajj to the House for whoever can make the way. The Prophet \ufdfa said this to Jibril when he came as a man to teach the companions — the questions were for you.',
    character: 'Hold the five pillars daily; they are the frame of everything else.',
  ),
  _HadithLesson(
    title: 'Hadith 3 — The Levels of the Deen',
    meaning:
        'Jibril asked about Islam, then Iman, then Ihsan. Islam is the five pillars. Iman is belief in Allah, His angels, His books, His messengers, the Last Day, and decree — good and bad. Ihsan is to worship Allah as though you see Him — and though you do not see Him, He sees you. The deen has a body, a heart, and a beauty.',
    character: 'Practice one act of ihsan today: do something as if He is watching — He is.',
  ),
  _HadithLesson(
    title: 'Hadith 4 — Your Time of Life',
    meaning:
        'The Prophet \ufdfa said: you are in the evening of one day and the morning of the next — your health before your sickness, your wealth before your poverty, your life before your death, and your free time before your busyness. Five before five, none of which return once gone.',
    character: 'Name one of the five-before-five you still hold; spend it today.',
  ),
  _HadithLesson(
    title: 'Hadith 5 — The Allowed and the Forbidden Are Clear',
    meaning:
        'What is lawful is clear and what is unlawful is clear, and between them are doubtful matters unknown to many. Whoever guards the doubtful has protected their religion and honor. Leave what makes you doubt for what does not.',
    character: 'When a choice feels gray, choose the side your heart rests on.',
  ),
  _HadithLesson(
    title: 'Hadith 6 — The Muslim Is the One Whom People Are Safe From',
    meaning:
        'The Muslim is the one from whose tongue and hand the Muslims are safe. And the emigrant is the one who emigrates from what Allah has forbidden. The Prophet \ufdfa described the best of people as those whose goodness is hoped and whose harm is safe — safety is a character, not just a status.',
    character: 'Be someone whose hand and word people do not fear today.',
  ),
  _HadithLesson(
    title: 'Hadith 7 — Religion Is Sincere Counsel',
    meaning:
        'The Prophet \ufdfa said: the religion is sincere counsel. We asked: to whom? He said: to Allah, His Book, His Messenger, the leaders of the Muslims, and their common people. Counsel is not flattery — it is wanting good for the one you advise.',
    character: 'Give one sincere piece of advice today, gently, to someone who needs it.',
  ),
  _HadithLesson(
    title: 'Hadith 8 — The Sanctity of a Muslim',
    meaning:
        'Allah has made sacred the blood, wealth, and honor of every Muslim to every other Muslim. The Muslim is the brother of the Muslim — he does not wrong him, forsake him, or despise him. Whoever fulfills the rights of his brother, Allah will fulfill his.',
    character: 'Guard one Muslim\u2019s honor today — in speech, in silence, in a message.',
  ),
  _HadithLesson(
    title: 'Hadith 9 — Avoid What Is Doubtful',
    meaning:
        'The halal is clear and the haram is clear, and between them are doubtful matters unknown to many. Whoever guards the doubtful has protected his religion and his honor. And in the body is a morsel — if it is sound the whole body is sound, and if it is corrupt the whole body is corrupt. Indeed it is the heart. The stomach\'s halal is the heart\'s halal — they rise and fall together.',
    character: 'Run one purchase through the doubt test this week — if it feels gray, choose the side that lets you sleep.',
  ),
  _HadithLesson(
    title: 'Hadith 10 — Leave What Does Not Concern You',
    meaning:
        'Part of the excellence of a person\'s Islam is leaving what does not concern him. The scroll of the day is finite; every unnecessary glance, word, and scroll is a withdrawal from it. The Prophet ﭑ measured the believer\'s Islam by subtraction as much as addition.',
    character: 'Audit one hour of your week — what did not concern you? Release it and keep the difference.',
  ),
  _HadithLesson(
    title: 'Hadith 11 — Love for Your Brother',
    meaning:
        'None of you truly believes until he loves for his brother what he loves for himself. This hadith is the social constitution of the ummah in one sentence — envy dies where it is practiced, and the heart learns to celebrate another\'s blessing as if it were its own.',
    character: 'When good news reaches someone this week, say alhamdulillah for them before your own heart has time to compare.',
  ),
  _HadithLesson(
    title: 'Hadith 12 — Honoring the Guest',
    meaning:
        'Whoever believes in Allah and the Last Day should honor his guest. Three days and nights of hosting, then the reward is in what was given — the guest\'s comfort is the host\'s worship, and the three-day limit is the mercy that makes hospitality sustainable.',
    character: 'Host or serve one guest this month — a meal, a visit, even a good word at the door.',
  ),
  _HadithLesson(
    title: 'Hadith 13 — The Right of the Neighbor',
    meaning:
        'Whoever believes in Allah and the Last Day should honor his neighbor. The angel Jibril kept advising the Prophet ﭑ about the neighbor until he thought he would make him an heir. The neighbor is the person you did not choose — which makes the kindness worth more, not less.',
    character: 'Do one unasked kindness for a neighbor this week — take in a package, shovel a path, ask how they are.',
  ),
  _HadithLesson(
    title: 'Hadith 14 — The Sanctity of the Muslim',
    meaning:
        'Allah has made sacred the blood, wealth, and honor of every Muslim to every other Muslim. To backbite a Muslim is to eat his flesh (49:12) — and the hadith extends the sanctity to the one who is absent: mention your brother as you would have him mention you.',
    character: 'Guard one Muslim\'s absence this week — correct the story, change the subject, or stay silent.',
  ),
  _HadithLesson(
    title: 'Hadith 15 — The Signs of the Hypocrite',
    meaning:
        'Three are the signs of the hypocrite, even if he fasts and prays: when he speaks he lies, when he promises he breaks, and when he is trusted he betrays. The Prophet ﭑ did not say these sins eject a person from Islam — he said they are the smell of hypocrisy, and the believer checks his own breath.',
    character: 'Check your own three signs this week — one promise you made and have not kept. Keep it.',
  ),
  _HadithLesson(
    title: 'Hadith 16 — Anger Destroys Good Deeds',
    meaning:
        'Anger is a live coal in the heart — do you not see the redness of the eyes and the swelling of the veins? The Prophet ﭑ advised: when one of you becomes angry, seek refuge in Allah, change posture, be silent. And if he is standing, let him sit; if sitting, lie down. The body is the first battlefield.',
    character: 'Ninety seconds: next time anger rises, sit down and stay silent for ninety seconds before speaking.',
  ),
  _HadithLesson(
    title: 'Hadith 17 — The Blessing of Provision',
    meaning:
        'If you were to rely upon Allah as He deserves to be relied upon, He would provide you as He provides the birds — they leave hungry in the morning and return full. Tawakkul is not passivity; it is the bird\'s departure — the wings still move, but the rizq is not the bird\'s to manage.',
    character: 'Name one provision you are anxious about. Plan, then release — go out hungry in the morning.',
  ),
  _HadithLesson(
    title: 'Hadith 18 — The Religion Is Sincere Counsel',
    meaning:
        'The religion is sincere counsel — to Allah, His Book, His Messenger, the leaders of the Muslims, and their common people. Counsel to Allah is to oppose rivals to Him; counsel to the leaders is to correct them honestly, not flatter them; counsel to the common people is the everyday kindness.',
    character: 'Give one sincere counsel this week — to a leader gently, to a friend honestly, to a stranger kindly.',
  ),
  _HadithLesson(
    title: 'Hadith 19 — The Muslim Is Safe',
    meaning:
        'The Muslim is the one from whose tongue and hand the Muslims are safe. And the emigrant is the one who emigrates from what Allah has forbidden. Safety is not the absence of power — it is the decision, made daily, not to use it.',
    character: 'Audit one relationship: do they feel safe from your tongue and hand? Repair the one that does not.',
  ),
  _HadithLesson(
    title: 'Hadith 20 — The Lawful and the Unlawful',
    meaning:
        'Allah is pure and accepts only what is pure. Allah has commanded the believers what He commanded the messengers: eat of the good things and act righteously. The morsel of haram blocks the dua like a locked door — the stomach\'s halal is the first condition of the heart\'s acceptance.',
    character: 'Run one income source through the purity test this week — even small. Clean the morsel.',
  ),
  _HadithLesson(
    title: 'Hadith 21 — Cleanliness of Character',
    meaning:
        'Purity is half of faith. And the believer is not one who taunts, curses, speaks obscenely, or speaks abusively. The tongue\'s cleanliness is the body\'s cleanliness — and the one who guards both has guarded half the deen before a single prayer is prayed.',
    character: 'Clean one word from your vocabulary this week — replace it with a better one, starting today.',
  ),
  _HadithLesson(
    title: 'Hadith 22 — Lowering the Wing of Humility',
    meaning:
        'Allah has revealed to me that you should lower yourselves until no one boasts over another and no one transgresses against another. The strong who controls himself at anger, the one who walks humbly, the one who gives without reminder — these are the ones Paradise was built for.',
    character: 'Lower your voice and your shoulder in one interaction today — let the other person walk taller.',
  ),
  _HadithLesson(
    title: 'Hadith 23 — The Best of the Best',
    meaning:
        'The best among you are those who learn the Quran and teach it. And the best of you in the days of ignorance are the best in Islam, if they understand. Knowledge is the ladder — and the one who climbs it and then holds it for others is the highest of all.',
    character: 'Learn one verse or hadith this week well enough to teach it — then teach it to one person.',
  ),
  _HadithLesson(
    title: 'Hadith 24 — Guarding the Tongue',
    meaning:
        'Whoever believes in Allah and the Last Day should speak good or remain silent. And whoever guarantees me what is between his jaws and what is between his legs, I will guarantee Paradise for him. The tongue is the easiest gate to open and the hardest to close — and its spoils fill more graves than any sword.',
    character: 'One day this week: speak only good or stay silent. Choose the day; mark it; then keep the gate.',
  ),
  _HadithLesson(
    title: 'Hadith 25 — The Righteousness That Matters',
    meaning:
        'Righteousness is not that you turn your faces toward the east or the west — but righteousness is in the one who believes in Allah, gives wealth, establishes prayer, fulfills covenants, and is patient in hardship (2:177). The direction matters; the character matters more.',
    character: 'Check one covenant you made — a promise, a contract, a vow. Fulfill it this week, on time.',
  ),
  _HadithLesson(
    title: 'Hadith 26 — The Obligation of Brotherly Love',
    meaning:
        'None of you believes until he loves for his brother what he loves for himself. The Prophet ﭑ said this three times to three different audiences — the repetition was the emphasis. The ummah\'s unity is not a slogan; it is a daily practice of wanting good for the one next to you.',
    character: 'Make one dua today for a brother or sister you have never met — by description, not by name.',
  ),
  _HadithLesson(
    title: 'Hadith 27 — The Law of Brotherhood',
    meaning:
        'The Muslim is the brother of the Muslim — he does not wrong him, forsake him, or despise him. And whoever fulfills the needs of his brother, Allah fulfills his needs. The ummah is one body: when one limb aches, the whole body responds with fever and wakefulness.',
    character: 'Fulfil one need of one Muslim this week — a ride, a reference, a listening ear. Then ask for nothing.',
  ),
  _HadithLesson(
    title: 'Hadith 28 — The Evil of Oppression',
    meaning:
        'Allah says: My servants, I have forbidden oppression for Myself and made it forbidden among you, so do not oppress one another. Oppression will be darkness on the Day of Judgment — even the small oppressions: the short measure, the unpaid debt, the harsh word to the powerless.',
    character: 'Right one small wrong this week — a debt, a measure, a harsh word remembered. Pay it back.',
  ),
  _HadithLesson(
    title: 'Hadith 29 — The Sanctity of the Blood',
    meaning:
        'The blood, wealth, and honor of a Muslim are sacred to every Muslim — like the sanctity of this day, in this month, in this city. The Prophet ﭑ said this standing at Arafat, on the day of the Farewell Sermon — the three sanctities were the last constitution he gave.',
    character: 'Honor one Muslim\'s honor this week — defend the absent, cover the fault, speak the good word.',
  ),
  _HadithLesson(
    title: 'Hadith 30 — The Rights of the Muslim',
    meaning:
        'The Muslim has six rights over his fellow Muslim: greet him with salam, accept his invitation, answer his sneeze with yarhamuk Allah, visit him when he is sick, follow his funeral, and love for him what you love for yourself. Six doors that keep the ummah\'s house standing.',
    character: 'Practice one of the six this week — the one you most often skip. Just one, done fully.',
  ),
  _HadithLesson(
    title: 'Hadith 31 — The Brotherhood of Faith',
    meaning:
        'The believers are but brothers, so make peace between your brothers and fear Allah that you may receive mercy (49:10). The Prophet ﭑ said: the believers are like a structure, one part strengthening another — the hand holds the wall because the wall holds the hand.',
    character: 'Make peace between two people this month — even by a word, even by a smile, even by leaving.',
  ),
  _HadithLesson(
    title: 'Hadith 32 — No Harm and No Reciprocating Harm',
    meaning:
        'There is no harm and no reciprocating harm. This principle governs traffic, trade, tenancy, and every human contract: you may not harm, and you may not answer harm with harm. The Muslim\'s transaction is clean on both sides of the counter.',
    character: 'Audit one exchange this week — did both sides leave unharmed? If not, be the one who repairs it.',
  ),
  _HadithLesson(
    title: 'Hadith 33 — The Signs of the Believer',
    meaning:
        'The signs of the believer: honesty in speech, returning the trust, and cleanliness of the neighbor. And the worst of the servants are the two-faced — approaching these with one face and those with another. The believer\'s face is the same at the door and behind the door.',
    character: 'Check your two faces this week — the one at work and the one at home. Bring them closer.',
  ),
  _HadithLesson(
    title: 'Hadith 34 — The Value of This World',
    meaning:
        'The world compared to the Hereafter is like one of you dipping his finger in the sea — let him see what returns. The son of Adam says \'my wealth, my wealth\' — but only what he ate and consumed, or wore and wore out, or gave and sent ahead is truly his.',
    character: 'Dip the finger: what did you send ahead this month? Name it; then add one item to the list.',
  ),
  _HadithLesson(
    title: 'Hadith 35 — The Good Word',
    meaning:
        'The good word and the forgiving word are better than charity followed by harm (2:263). And speak to people kindly — the Prophet ﭑ was not crude, loud, or foul-mouthed. The word that forgives is the word that builds; the word that shames is the word that burns.',
    character: 'Speak one forgiving word this week — to the one who owes you, wronged you, or forgot you.',
  ),
  _HadithLesson(
    title: 'Hadith 36 — The Seven Under the Shade',
    meaning:
        'Seven whom Allah will shade on the Day there is no shade but His: the just ruler, the youth who grew up in worship, the man whose heart is attached to the masjid, two who love each other for Allah, the one who weeps alone, the one who gives so the left hand does not know, and the one who remembers Allah alone until the eyes overflow.',
    character: 'You are young now. Pick one of the seven and start building it this month — the shade is real.',
  ),
  _HadithLesson(
    title: 'Hadith 37 — Allah Pardons and Loves Pardon',
    meaning:
        'The servants of the Merciful are those who walk gently, speak softly, and pardon people — and Allah loves those who pardon (3:134). The measure of forgiveness is the size of the wrong — and Allah\'s pardon is described in the same verse as His love. To pardon is to be loved.',
    character: 'Pardon one debt this week — of money, of words, of attention. Let it go before they ask.',
  ),
  _HadithLesson(
    title: 'Hadith 38 — The Reward of Patience',
    meaning:
        'Those who are patient will be given their reward without account (39:10). No scale, no measure — the reward of sabr is weighed by the One who promised, not by the one who endured. Whatever you are carrying that no one sees — it is seen, and it is not measured.',
    character: 'Carry one thing one more day without complaining — and tell no one. Let the account stay with Allah.',
  ),
  _HadithLesson(
    title: 'Hadith 39 — The Best Charity',
    meaning:
        'The best charity is that given when you are healthy and greedy, fearing poverty and hoping for wealth. The Prophet ﭑ said: do not delay until you are at the door saying \'this is for so-and-so and that is for so-and-so\' — when it is already taken from your hand.',
    character: 'Give one sadaqah this week before you feel ready — while the greed is still alive in your hand.',
  ),
  _HadithLesson(
    title: 'Hadith 40 — Be in This World as a Stranger',
    meaning:
        'Be in this world as a stranger or a traveler — and count yourself among the dead. The Prophet ﭑ said: I have nothing to do with the world; I am like a rider who takes shade under a tree, then leaves it and moves on. The traveler does not unpack; the stranger does not renovate.',
    character: 'Live as a traveler this week — use the world, thank for it, and keep the luggage light. One luxury released.',
  ),
];

class HadithSchoolScreen extends ConsumerWidget {
  const HadithSchoolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hadiths = ref.watch(hadithCollectionProvider);
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Hadith School', close: true),
              Text('الحديث',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'Imam an-Nawawi\u2019s Forty — the hadith every Muslim should carry',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => context.go(AppRoutes.hadith),
                child: Text('Open the full Forty reader \u2192',
                    style: AppText.bodyMuted.copyWith(color: AppColors.gold)),
              ),
              const SizedBox(height: 18),
              for (int i = 0; i < kHadithLessons.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    strong: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(kHadithLessons[i].title,
                            style: AppText.titleMedium),
                        const SizedBox(height: 8),
                        hadiths.when(
                          data: (list) => i < list.length
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.night,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    list[i].arabic,
                                    textAlign: TextAlign.right,
                                    style: AppText.arabic.copyWith(
                                        fontSize: 18, color: AppColors.goldLight),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 8),
                        Text(kHadithLessons[i].meaning,
                            style: AppText.body.copyWith(height: 1.6)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.3)),
                          ),
                          child: Text('Carry it: ${kHadithLessons[i].character}',
                              style:
                                  AppText.bodyMuted.copyWith(fontSize: 12.5, height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'The complete Forty — every hadith with its meaning and one character practice. Read them in order; the first ten build the foundation, the rest build the house.',
                style: AppText.bodyMuted.copyWith(fontSize: 11, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
