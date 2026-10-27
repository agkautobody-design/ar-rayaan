/// Dawah school — how to carry the message with wisdom: the Makkan
/// method, the answer to objections, and the character of the caller.
/// Built on the Taif story, the khutbahs on counsel, and the seerah.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _DawLesson {
  const _DawLesson({required this.title, required this.body, required this.practice});
  final String title;
  final String body;
  final String practice;
}

class _DawUnit {
  const _DawUnit({required this.title, required this.frame, required this.lessons});
  final String title;
  final String frame;
  final List<_DawLesson> lessons;
}

const List<_DawUnit> kDawahUnits = <_DawUnit>[
  _DawUnit(
    title: 'The Method',
    frame: 'The Prophet \ufdfa spent thirteen years in Makkah teaching one family, then one tribe, then a city. The method was patience, not pressure.',
    lessons: <_DawLesson>[
      _DawLesson(
        title: 'Invite to the Oneness First',
        body: 'When the Prophet \ufdfa sent Mus\u2019ab to Madinah, he did not send rulings — he sent the shahada. The first question in dawah is never \'what about hijab\' or \'what about politics\' — it is \'who is Allah, and what does He ask of you?\' Start where the revelation started.',
        practice: 'In your next conversation about Islam, begin with Allah\u2019s mercy and oneness — not the rules. Let the heart open before the law arrives.',
      ),
      _DawLesson(
        title: 'Wisdom Is Knowing the Person',
        body: 'Call to the way of your Lord with wisdom and good instruction, and argue with them in the best way (16:125). The same truth lands differently on a grieving friend, a skeptical coworker, and a curious child. The message is one; the door is tailored.',
        practice: 'Before your next dawah conversation, spend two minutes thinking about the person — what are they carrying today? Speak to that.',
      ),
      _DawLesson(
        title: 'The Taif Standard',
        body: 'On the hardest day he had known, after he was turned away at Taif, the Angel of the Mountains offered to let two mountains fall on those who had rejected him. The Prophet \ufdfa said: no, he hoped Allah would bring from them children who would worship Allah alone (Bukhari 3231). The seerah sources add that he was driven out and stoned there; that detail is not in the hadith. The caller\u2019s job is to deliver, not to destroy.',
        practice: 'When someone mocks your faith this week, respond with the Taif standard — no counter-mockery, no argument. Deliver the mercy, release the result.',
      ),
      _DawLesson(
        title: 'Your Life Is the Loudest Sermon',
        body: 'The Prophet \ufdfa was called al-Amin — the trustworthy — before he was called a prophet. His character opened the door his words then walked through. The coworker who trusts your honesty will listen to your Islam; the one who has been burned by you will not.',
        practice: 'Audit one relationship this week: does your character open the door or close it? Repair the one that closes it.',
      ),
    ],
  ),
  _DawUnit(
    title: 'The Answers',
    frame: 'The Qur\u2019an itself teaches how to answer: with the same verse that raised the question, and with the gentleness that carries it.',
    lessons: <_DawLesson>[
      _DawLesson(
        title: '"Why Do Bad Things Happen?"',
        body: 'Do not say about anything \'I will do that tomorrow\' without adding \'if Allah wills\' (18:23-24). And: perhaps you dislike a thing and it is good for you (2:216). The answer is not a theodicy lecture — it is the trust that the Author sees the whole book while we read one page.',
        practice: 'When someone asks this, answer with 2:216 and a story of your own life where the closed door opened a better one.',
      ),
      _DawLesson(
        title: '"Islam Is Too Strict."',
        body: 'Allah intends for you ease and does not intend for you hardship (2:185). And: fear Allah as much as you are able (64:16). The deen has a floor and a ceiling; the caller shows the floor first — five prayers, honest work, kindness — and lets the person climb.',
        practice: 'In your next conversation, describe Islam by its mercy (the door of repentance, the ease in hardship) before its boundaries.',
      ),
      _DawLesson(
        title: '"The Quran Was Written by a Man."',
        body: 'Bring them a chapter like it — or ten chapters, or the whole book (2:23). The challenge stands 1400 years later. And ask: which man, alone in a cave, produces a book that billions memorize letter-by-letter while its author\u2019s enemies could not produce ten lines?',
        practice: 'Memorize one short surah this month — the challenge is easier to carry when it lives in your own chest.',
      ),
      _DawLesson(
        title: '"I Have Done Too Much Wrong."',
        body: 'Say: O My servants who have transgressed against themselves — do not despair of the mercy of Allah; indeed, Allah forgives all sins (39:53). This is the verse for the one who thinks they are too far gone. The caller\u2019s task is to keep the door visibly open.',
        practice: 'When someone confesses a sin to you, respond with 39:53 before any advice. The verse first, always.',
      ),
    ],
  ),
  _DawUnit(
    title: 'The Caller\u2019s Character',
    frame: 'The message is carried by the messenger. These are the traits that make the carrier trustworthy.',
    lessons: <_DawLesson>[
      _DawLesson(
        title: 'Gentleness Does Not Water Down the Truth',
        body: 'The Prophet \ufdfa said: gentleness is not found in anything except that it adds beauty to it, and it is not removed from anything except that it disgraces it (Muslim 2594). Musa was sent to Pharaoh — the worst tyrant in history — and Allah still commanded him: speak to him mildly (20:44).',
        practice: 'Lower your voice in your next disagreement about Islam. The volume is not the proof.',
      ),
      _DawLesson(
        title: 'Knowledge Before Speech',
        body: 'Say: my Lord has only forbidden what is apparent of immorality and what is concealed (7:33). The caller must know before speaking — a half-answer delivered with confidence closes more doors than silence. When you do not know, say: I will find out. That sentence is dawah.',
        practice: 'This week, when asked something you do not know, practice the sentence: \'That is a beautiful question — let me find out and come back to you.\'',
      ),
      _DawLesson(
        title: 'Release the Result',
        body: 'You are not over them a controller (88:22). Your job is to deliver the message clearly, kindly, and honestly; the heart that opens is Allah\u2019s to open. This releases the caller from the anxiety of rejection — you were never the one being rejected.',
        practice: 'After your next dawah conversation, say quietly: \'I delivered it; You guide the hearts.\' Then let it go.',
      ),
    ],
  ),
];

class DawahSchoolScreen extends StatelessWidget {
  const DawahSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Dawah', close: true),
              Text('الدعوة',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'How to carry the message with wisdom — method, answers, character',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final _DawUnit unit in kDawahUnits) ...<Widget>[
                Text(unit.title.toUpperCase(), style: AppText.eyebrow),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(unit.frame,
                      style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.55)),
                ),
                for (final _DawLesson l in unit.lessons)
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
