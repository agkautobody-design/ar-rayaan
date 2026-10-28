/// Stories school — the library\u2019s collections as a moral curriculum.
/// Four themes, each a set of chapters that open real stories with the
/// virtue they carry and a family question to talk through. Every story
/// id references an existing collection entry.
library;

import '../../../app/core/scholar_review.dart';
import 'package:flutter/material.dart';

import '../../../app/core/child_mode.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';

class _StoryChapter {
  const _StoryChapter({
    required this.title,
    required this.virtue,
    required this.familyQuestion,
    required this.storyId,
  });

  final String title;
  final String virtue;
  final String familyQuestion;
  final String storyId;
}

class _StoriesUnit {
  const _StoriesUnit({required this.title, required this.frame, required this.chapters});
  final String title;
  final String frame;
  final List<_StoryChapter> chapters;
}

const List<_StoriesUnit> kStoriesUnits = <_StoriesUnit>[
  _StoriesUnit(
    title: 'Patience & Trust',
    frame: 'The Prophets were not supermen — they were the most patient men. These chapters teach waiting without despairing.',
    chapters: <_StoryChapter>[
      _StoryChapter(
        title: 'Yusuf — From Well to Throne',
        virtue: 'Betrayed by brothers, sold, imprisoned — and he forgave them by name. Patience that keeps its softness.',
        familyQuestion: 'Has anyone wronged you that you could forgive by name?',
        storyId: 'prophet-yusuf',
      ),
      _StoryChapter(
        title: 'Ayyub — The Patient One',
        virtue: 'Everything taken, years of illness, one dua at the end — and the mountain moved. Long patience, short words.',
        familyQuestion: 'What would you say to Allah if you could only say one sentence?',
        storyId: 'prophet-ayyub',
      ),
      _StoryChapter(
        title: 'Ya\u2019qub — The Beautiful Patience',
        virtue: 'He lost a son, then another — and said \'I only complain of my suffering and my grief to Allah\' (12:86). Grief and patience can share a chest.',
        familyQuestion: 'What does \'beautiful patience\' look like in our house this week?',
        storyId: 'prophet-yaqub',
      ),
      _StoryChapter(
        title: 'Nuh — The Long Building',
        virtue: 'He built the ship for decades before a drop of rain, and called his people for 950 years. Persistence is a form of worship.',
        familyQuestion: 'What are you building that no one can see yet?',
        storyId: 'prophet-nuh',
      ),
      _StoryChapter(
        title: 'The Man Who Killed 99',
        virtue: 'The road to paradise is measured in miles — and he walked them. Repentance has a geography: move toward the righteous.',
        familyQuestion: 'What is one step you could take toward a better place this month?',
        storyId: 'tale-99',
      ),
    ],
  ),
  _StoriesUnit(
    title: 'Courage & Conviction',
    frame: 'Standing alone against everyone — and standing anyway.',
    chapters: <_StoryChapter>[
      _StoryChapter(
        title: 'Ibrahim — The Two Rivers of Reason',
        virtue: 'He argued a star, a moon, a sun into the ground, then walked into a fire that became cool. Conviction that reasons and then leaps.',
        familyQuestion: 'What belief would you hold even if everyone mocked it?',
        storyId: 'prophet-ibrahim',
      ),
      _StoryChapter(
        title: 'Musa — Before Pharaoh',
        virtue: 'Musa was sent to the world\u2019s tyrant with a message, and asked Allah to untie the knot from his tongue and to send his brother Harun, who was more fluent, beside him (Qur\u2019an 20:27-30; 28:34). Courage is speaking while asking for help.',
        familyQuestion: 'What is your \'staff\' — the small thing you carry that could face something big?',
        storyId: 'prophet-musa',
      ),
      _StoryChapter(
        title: 'Maryam — The Palm Tree',
        virtue: 'Alone, laboring, accused — and the infant spoke from the cradle. Solitude with Allah is never abandonment.',
        familyQuestion: 'When have you felt alone but not abandoned?',
        storyId: 'woman-maryam',
      ),
      _StoryChapter(
        title: 'Bilal — One Word',
        virtue: 'The mountain of sand could not crush one word: Ahad. The word outlived the empire that buried him under it.',
        familyQuestion: 'What is your one word — the thing you would not stop saying?',
        storyId: 'comp-bilal',
      ),
      _StoryChapter(
        title: 'Sumayyah — The First to Give Everything',
        virtue: 'The first martyr of Islam: a slave woman who refused to curse the Prophet. She taught the ummah its first lesson in standing.',
        familyQuestion: 'What does \'standing for something\' cost, and what does it buy?',
        storyId: 'woman-sumayyah',
      ),
    ],
  ),
  _StoriesUnit(
    title: 'Mercy & Forgiveness',
    frame: 'The strongest ones lowered the wing — and the door of repentance never closed.',
    chapters: <_StoryChapter>[
      _StoryChapter(
        title: 'Adam — The First Repentance',
        virtue: 'One honest sentence opened the door of mercy for every sinner after him. Repentance is the oldest human skill.',
        familyQuestion: 'What does a real apology look like — from you to someone else, or to Allah?',
        storyId: 'prophet-adam',
      ),
      _StoryChapter(
        title: 'The Prostitute\u2019s Thirst',
        virtue: 'One bowl of water for a thirsty dog — and her ledger was closed by mercy. No one is beyond a door Allah opens.',
        familyQuestion: 'What small kindness might count more than you think?',
        storyId: 'tale-dog',
      ),
      _StoryChapter(
        title: 'Yunus — The Whale\u2019s Belly',
        virtue: 'He ran from the call and landed in the darkest place — and one sentence reached the Throne from inside a fish. No place is too dark for la ilaha illa anta.',
        familyQuestion: 'What is your \'whale\u2019s belly\' — the dark place you could pray from right now?',
        storyId: 'prophet-yunus',
      ),
      _StoryChapter(
        title: 'Umm Salama — Whose Question Became a Verse',
        virtue: 'She said the dua of the afflicted — \'to You we return\' — and her heartache became revelation. Grief itself can be worship.',
        familyQuestion: 'What dua could turn your hardest day into an address to Allah?',
        storyId: 'woman-umm-salama',
      ),
      _StoryChapter(
        title: 'Barsisa — A Tale We Cannot Verify',
        virtue: 'A monk\u2019s tale some commentaries tell about 59:16. It is not from the Qur\u2019an or an authentic hadith, so the app gives the Qur\u2019an\u2019s parable of Shaytan (59:16; 14:22) and not the tale.',
        familyQuestion: 'What does this story warn you about — and what does it promise you?',
        storyId: 'tale-barsisa',
      ),
    ],
  ),
  _StoriesUnit(
    title: 'Gratitude & Contentment',
    frame: 'The ones who counted their blessings instead of their lacks — and found the scale already tipped.',
    chapters: <_StoryChapter>[
      _StoryChapter(
        title: 'Sulayman — The Kingdom',
        virtue: 'A kingdom no one will have after him — and his dua was only \'make me grateful.\' Might chose gratitude.',
        familyQuestion: 'What do you have that you never asked for?',
        storyId: 'prophet-sulayman',
      ),
      _StoryChapter(
        title: 'The Two Gardens',
        virtue: 'The man who counted his harvest forgot his Lord — one night of frost took it all. \'Wealth and children are [but] adornment of the worldly life. But the enduring good deeds are better to your Lord for reward\' (18:46).',
        familyQuestion: 'What is your \'garden\' — and what would remain if it vanished tonight?',
        storyId: 'tale-two-gardens',
      ),
      _StoryChapter(
        title: 'Hagar — She Ran Seven Times',
        virtue: 'Alone in a desert with a crying child — and \'He will not waste us\' became the walk between two hills that every pilgrim still walks.',
        familyQuestion: 'Where are you \'running between the hills\' right now?',
        storyId: 'woman-hagar',
      ),
      _StoryChapter(
        title: 'Asiya — A House Built Wrong',
        virtue: 'She lived in Pharaoh\u2019s palace and was heartbroken in it — and Allah showed her her house in Paradise. Sometimes the palace is the test.',
        familyQuestion: 'What \'house\' are you in that feels wrong — and what house are you building instead?',
        storyId: 'woman-asiya',
      ),
      _StoryChapter(
        title: 'The Sleepers of the Cave',
        virtue: 'They slept through an empire and woke to find their small faith had outlasted the world that hunted them. Hold what you have; time is on your side.',
        familyQuestion: 'What small thing are you holding that history may one day vindicate?',
        storyId: 'tale-cave-people',
      ),
    ],
  ),
  _StoriesUnit(
    title: 'The Companions — The Living Curriculum',
    frame: 'The men who carried the message into the world. Each one teaches a trait by having lived it.',
    chapters: <_StoryChapter>[
      _StoryChapter(
        title: 'Abu Bakr — The Steady One',
        virtue: 'The first caliph who held the ummah together with two years of steady, unglamorous work. When others panicked, he was already planning.',
        familyQuestion: 'Who holds your family together with steady, unglamorous work? Thank them.',
        storyId: 'comp-abu-bakr',
      ),
      _StoryChapter(
        title: 'Umar — Justice on Horseback',
        virtue: 'The second caliph patrolled Medina at night and answered to no one but Allah. The milk-seller\u2019s story is his most told parable of fairness.',
        familyQuestion: 'Who in your life models justice that no one can buy?',
        storyId: 'comp-umar',
      ),
      _StoryChapter(
        title: 'Uthman — The Gatherer',
        virtue: 'The third caliph ordered the one mushaf and the ummah has read from it ever since. Gentleness and decisiveness in the same hands.',
        familyQuestion: 'What could you gather or preserve that would outlive you?',
        storyId: 'comp-uthman',
      ),
      _StoryChapter(
        title: 'Ali — Raised in the Prophet\u2019s House',
        virtue: 'The fourth caliph, raised in the Prophet\u2019s house. The era\u2019s scholarship begins with him.',
        familyQuestion: 'What knowledge could you pass on — who could you teach this month?',
        storyId: 'comp-ali',
      ),
      _StoryChapter(
        title: 'Bilal — One Word',
        virtue: 'The mountain of sand could not crush one word: Ahad. The word outlived the empire that buried him under it.',
        familyQuestion: 'What is your one word — the thing you would not stop saying?',
        storyId: 'comp-bilal',
      ),
      _StoryChapter(
        title: 'Salman — The Seeker',
        virtue: 'A Persian who left one religion after another searching for truth — and found it in the Prophet\u2019s description of a man between two marks. Seeking is a virtue when it is honest.',
        familyQuestion: 'Are you still seeking — and is your seeking honest?',
        storyId: 'comp-salman',
      ),
      _StoryChapter(
        title: 'Abu Hurayrah — The Memorizer',
        virtue: 'He came to Islam late and memorized more hadith than any companion — by hunger and repetition. The one who writes down what he hears outlasts the one who only listens.',
        familyQuestion: 'What have you heard this month that you should write down before it is lost?',
        storyId: 'comp-abu-hurayrah',
      ),
      _StoryChapter(
        title: 'Khabbab — The Patient One',
        virtue: 'He was tortured on burning coals and asked the Prophet: will you not ask Allah to help us? The Prophet\u2019s answer taught patience that counts in years, not days.',
        familyQuestion: 'What are you asking for that might arrive in years, not days?',
        storyId: 'comp-khabbab',
      ),
      _StoryChapter(
        title: 'Ibn Masud — The Reciter',
        virtue: 'A shepherd boy who followed the Prophet and became one of the greatest reciters. The first to recite Qur\u2019an aloud in Makkah — and the Quraysh beat him for it.',
        familyQuestion: 'What are you willing to be beaten for?',
        storyId: 'comp-ibn-masud',
      ),
      _StoryChapter(
        title: 'Musab — The Handsome Ambassador',
        virtue: 'Sent to Madinah alone to teach a city — he taught with the mushaf in one hand and adab in the other. Died at Uhud holding the flag.',
        familyQuestion: 'Where are you an ambassador — and are you teaching adab or just facts?',
        storyId: 'comp-musab',
      ),
      _StoryChapter(
        title: 'Ammar — The Builder',
        virtue: 'He built the masjid in the heat of the sun while others rested, and the Prophet\u2019s dua made the heat easy. Work done for Allah is never wasted.',
        familyQuestion: 'What are you building that no one will credit you for?',
        storyId: 'comp-ammar',
      ),
      _StoryChapter(
        title: 'Suhayb — The Arsonist\u2019s Price',
        virtue: 'He bought his freedom from Quraysh with every dirham he owned. The Prophet\u2019s comment: \'Suhayb has profited.\' Sometimes the price of freedom is everything you have — and it is still cheap.',
        familyQuestion: 'What price would you pay for your freedom — and is it worth more than what you hold?',
        storyId: 'comp-suhayb',
      ),
      _StoryChapter(
        title: 'Khalid ibn al-Walid — The Drawn Sword',
        virtue: 'The general who never lost a battle, who drew his sword at Mu\u2019tah and wrote the letter of honor to the defeated. Strength that answers to a higher command.',
        familyQuestion: 'Where is your strength — and does it answer to a higher command?',
        storyId: 'comp-thawr',
      ),
      _StoryChapter(
        title: 'Abu Ubaydah — The Trustworthy',
        virtue: 'The commander the Prophet ﷺ trusted with the army — so trustworthy that the Prophet ﷺ said every ummah has a trustee, and Abu Ubaydah is the trustee of this ummah.',
        familyQuestion: 'Who trusts you with what matters most — and are you worthy of the trust?',
        storyId: 'comp-ubayy',
      ),
      _StoryChapter(
        title: 'Sa\u2019d ibn Abi Waqqas — The Archer of Uhud',
        virtue: 'The first to shoot an arrow in the path of Allah; the Prophet ﷺ gave him his own arrows and said: shoot, may my father and mother be your ransom.',
        familyQuestion: 'What is your arrow — the skill you can aim for Allah\u2019s cause?',
        storyId: 'comp-saad',
      ),
      _StoryChapter(
        title: 'Talhah — The Shield of Uhud',
        virtue: 'He shielded the Prophet ﷺ with his own body at Uhud, taking the arrows meant for him. The one who shields another carries the reward of both.',
        familyQuestion: 'Who are you shielding — and what is it costing you?',
        storyId: 'comp-talha-zubayr',
      ),
      _StoryChapter(
        title: 'Az-Zubayr — The Disciplined',
        virtue: 'The Prophet ﷺ said every prophet has a hawari and Az-Zubayr is mine — the disciple who carried the standard and the discipline.',
        familyQuestion: 'Whose disciple are you — and what are you learning from them?',
        storyId: 'comp-hudhayfah',
      ),
      _StoryChapter(
        title: 'Abd ar-Rahman ibn Awf — The Wealthy Ascetic',
        virtue: 'One of the ten promised Paradise, and one of the wealthiest — he gave so much in one day that the caravan could not carry it. Wealth that flowed, not pooled.',
        familyQuestion: 'Does your wealth flow or pool — and what would change the direction?',
        storyId: 'comp-abdurrahman',
      ),
      _StoryChapter(
        title: 'Sa\u2019id ibn Zayd — The Hidden One',
        virtue: 'One of the ten promised Paradise, and one of the least known — the hidden ones are not forgotten. The ten included the famous and the nearly anonymous.',
        familyQuestion: 'Are you content to be the hidden one — the reward is the same?',
        storyId: 'comp-said-zayd',
      ),
      _StoryChapter(
        title: 'Zayd ibn Harithah — The Freed Slave General',
        virtue: 'Taken as a slave, freed, adopted, then given command of armies while the greatest men served under him. Rank is given by taqwa, not lineage.',
        familyQuestion: 'What rank have you been given that you did not earn — and are you using it well?',
        storyId: 'comp-said-zayd',
      ),
      _StoryChapter(
        title: 'Uthman ibn Maz\u2019un — The Ascetic',
        virtue: 'The first muhajir to die in Madinah; he gave up everything and the Prophet ﷺ wept at his grave. The one who left the dunya before the dunya left him.',
        familyQuestion: 'What could you leave of the dunya today without regret?',
        storyId: 'comp-hudhayfah',
      ),
      _StoryChapter(
        title: 'Abdullah ibn Umar — The Strict Follower',
        virtue: 'He followed every sunna so literally that people thought he was extreme — until they realized he was simply unwilling to add or subtract from the Prophet\u2019s way.',
        familyQuestion: 'Is there a sunna you know but do not follow — and what is stopping you?',
        storyId: 'comp-ibn-umar',
      ),
      _StoryChapter(
        title: 'Anas ibn Malik — The Servant',
        virtue: 'He served the Prophet ﷺ for ten years, from age ten to twenty — and the Prophet ﷺ never once said uff to him. Ten years, zero harsh words.',
        familyQuestion: 'Who serves you — and have you said uff to them this month?',
        storyId: 'comp-anas',
      ),
      _StoryChapter(
        title: 'Jabir ibn Abdullah — The Young Witness',
        virtue: 'Eighteen at Uhud, burying his father and brother with his own hands — and still fighting. The young are not exempt from standing.',
        familyQuestion: 'What battle is your generation facing — and are you standing?',
        storyId: 'comp-hamza',
      ),
      _StoryChapter(
        title: 'Abu Dharr — The Uncompromising',
        virtue: 'He spoke truth to power until Umar sent him away — and he lived the rest of his days in humility. The one who would not bend the truth for any throne.',
        familyQuestion: 'What truth have you bent to avoid discomfort — and could you unbend it?',
        storyId: 'comp-abu-dharr',
      ),
      _StoryChapter(
        title: 'Muadh ibn Jabal — The Scholar',
        virtue: 'The Prophet ﷺ said the most knowledgeable of my ummah in halal and haram is Muadh — and sent him to Yemen to teach. Knowledge that travels.',
        familyQuestion: 'What knowledge do you have that needs to travel — and who is waiting to receive it?',
        storyId: 'comp-muadh',
      ),
    ],
  ),
  _StoriesUnit(
    title: 'The Unseen World',
    frame: 'The angels who write, the jinn who whisper, and the realities behind the veil — the ghayb that faith embraces.',
    chapters: <_StoryChapter>[
      _StoryChapter(
        title: 'Jibril — The Trustworthy Spirit',
        virtue: 'The angel who brought revelation to every prophet, who taught the Quran to Muhammad \ufdfa, who comforted Maryam. The most honored creature is a messenger — service is rank.',
        familyQuestion: 'What message has been entrusted to you to deliver — and to whom?',
        storyId: 'ghayb-jibril',
      ),
      _StoryChapter(
        title: 'The Scribes — Who Write',
        virtue: 'Honorable scribes record every word — sitting on the right and the left. You are being written; write well.',
        familyQuestion: 'If your words today were published, would you sign them?',
        storyId: 'ghayb-scribes',
      ),
      _StoryChapter(
        title: 'Munkar and Nakir — The Questioners',
        virtue: 'Two angels question every soul in the grave. The preparation for their questions is the preparation for every exam: know your Lord, your religion, your prophet.',
        familyQuestion: 'What three answers would you give them today — are they ready?',
        storyId: 'ghayb-munkar-nakir',
      ),
      _StoryChapter(
        title: 'The Whisperer — Who Slips Away',
        virtue: 'Shaytan whispers and then withdraws, leaving you to carry the doubt. Recognize the whisper as foreign — it is not your voice.',
        familyQuestion: 'When doubt whispers, how do you answer it — and does your answer help?',
        storyId: 'ghayb-whisper',
      ),
      _StoryChapter(
        title: 'The Qarin — The Constant Companion',
        virtue: 'Every human has a companion from the jinn assigned to them. The Prophet \ufdfa showed that this companionship can be turned to good — the qarin of a believer becomes a helper.',
        familyQuestion: 'Is your constant companion helping you toward good — or are you helping it toward harm?',
        storyId: 'ghayb-companion-qarin',
      ),
    ],
  ),
  _StoriesUnit(
    title: 'The Last Days',
    frame: 'The signs that precede the final hour — not to frighten, but to wake the sleeping heart.',
    chapters: <_StoryChapter>[
      _StoryChapter(
        title: 'The Twelve Signs',
        virtue: 'The Prophet \ufdfa described the major signs in order — the smoke, the beast, the rising of the sun from the west. They arrive like dominoes; the believer reads them as reminders, not as terror.',
        familyQuestion: 'Which sign feels closest in your lifetime — and does it change how you live today?',
        storyId: 'sign-01',
      ),
      _StoryChapter(
        title: 'Knowledge Lost, Ignorance Widespread',
        virtue: 'The Prophet \ufdfa foretold that knowledge would be taken away and ignorance would prevail — not because books vanished, but because the hearts that carried them did.',
        familyQuestion: 'What knowledge are you responsible to keep alive in your family — and who are you teaching it to?',
        storyId: 'sign-02',
      ),
      _StoryChapter(
        title: 'The Hour Is Closer',
        virtue: 'The Prophet \ufdfa was asked about the Hour and said: what have you prepared for it? The question turns every timeline into a to-do list.',
        familyQuestion: 'What have you prepared? Name one thing — and one more you could add this month.',
        storyId: 'sign-12',
      ),
    ],
  ),
  _StoriesUnit(
    title: 'The Modern Life',
    frame: 'The hadith applied to the daily battles — the phone, the debt, the burnout, the feed.',
    chapters: <_StoryChapter>[
      _StoryChapter(
        title: 'The Seven Under the Shade',
        virtue: 'Seven whom Allah will shade — the youth in worship, the one who weeps alone, the one who gives in secret. Your youth is capital; spend it on the shade.',
        familyQuestion: 'Which of the seven is within your reach this year?',
        storyId: 'mh-youth-seven',
      ),
      _StoryChapter(
        title: 'The Birds Leave Hungry',
        virtue: 'Tawakkul is the bird\u2019s departure — the wings move, but the rizq is not the bird\u2019s to manage. Plan, then release.',
        familyQuestion: 'What are you chasing in fear that you could chase with tawakkul instead?',
        storyId: 'mh-money-birds',
      ),
      _StoryChapter(
        title: 'The Refuge of the Debtor',
        virtue: 'The debtor\u2019s supplication is answered until the debt is paid — but the debt must still be paid. Face the number, make the plan.',
        familyQuestion: 'Do you know your total debt? Write it down — the first step of every exit.',
        storyId: 'mh-money-debt',
      ),
      _StoryChapter(
        title: 'The Upper Hand',
        virtue: 'The upper hand gives; the lower hand receives. The Prophet ﷺ said the upper hand is better — and the one who gives while he fears poverty has outwitted Shaytan.',
        familyQuestion: 'Which hand are you — and could you move it one notch upward this month?',
        storyId: 'mh-money-hand',
      ),
      _StoryChapter(
        title: 'The Weeping Eye',
        virtue: 'The eye that weeps from the fear of Allah, and the eye that stays awake guarding the borders — both are written as worship. Tears are not weakness.',
        familyQuestion: 'When did you last weep — for Allah, or for His creation? Is that too long?',
        storyId: 'mh-soul-tears',
      ),
      _StoryChapter(
        title: 'Solitude Is a Room',
        virtue: 'You were not created for the crowd. The Prophet ﷺ sought the cave before the mission; the quiet hour is where the heart is furnished.',
        familyQuestion: 'Where is your cave — and when did you last sit in it?',
        storyId: 'mh-soul-solitude',
      ),
      _StoryChapter(
        title: 'Speak Good or Stay Silent — Including Online',
        virtue: 'The tongue\u2019s law applies to the keyboard. The comment section is the same fire; the anonymous handle is the same tongue.',
        familyQuestion: 'Run your last five posts through the filter: would you say them with the person standing there?',
        storyId: 'mh-society-tongue',
      ),
      _StoryChapter(
        title: 'The Door That Never Closes',
        virtue: 'The slave who ran from his master and returned — forgiven. The one who killed ninety-nine — forgiven. The door of repentance does not close until the sun rises from the west or the soul reaches the throat.',
        familyQuestion: 'Is there a door you think is closed for you — and are you sure?',
        storyId: 'mh-reflection-023',
      ),
      _StoryChapter(
        title: 'The Returning Heart',
        virtue: 'The heart is between two fingers of the Most Merciful — He turns it as He wills. Your inconsistency is not the end; it is the material of return.',
        familyQuestion: 'When you drift, what calls you back — and who or what is that Caller?',
        storyId: 'mh-reflection-24',
      ),
      _StoryChapter(
        title: 'Visit the Graves',
        virtue: 'The Prophet ﷺ said: I had forbidden you to visit the graves, but now visit them — they remind you of the Hereafter. The reminder that ends every distraction.',
        familyQuestion: 'When did you last stand at a grave — and what did it tell you?',
        storyId: 'mh-death-graves',
      ),
      _StoryChapter(
        title: 'The Work of Your Own Hand',
        virtue: 'The Prophet ﷺ worked with his hands; no one ever fed him without his working. Dignity is in the labor, not the title.',
        familyQuestion: 'What work do you do with your own hands — and do you honor it?',
        storyId: 'mh-work-hand',
      ),
      _StoryChapter(
        title: 'The Eye Weeps and the Heart Grieves',
        virtue: 'The Prophet ﷺ wept at his son\u2019s death and said: we say only what pleases our Lord. Permission to grieve, inside the permission to praise.',
        familyQuestion: 'Are you carrying a grief you have not named — and could you name it to Allah tonight?',
        storyId: 'mh-grief-ibrahim',
      ),
    ],
  ),
  _StoriesUnit(
    title: 'The Prophets — The Long Chain',
    frame: 'Every prophet carried the same message to a different people. Together they are the longest curriculum in history.',
    chapters: <_StoryChapter>[
      _StoryChapter(
        title: 'Adam — The First Repentance',
        virtue: 'One honest sentence opened the door of mercy for every sinner after him. Repentance is the oldest human skill.',
        familyQuestion: 'What does a real apology look like — from you to someone else, or to Allah?',
        storyId: 'prophet-adam',
      ),
      _StoryChapter(
        title: 'Idris — The Scribe',
        virtue: 'He was raised to a high station (19:57) — the first to write by the pen, the first to study the stars for worship. Knowledge was worship before it was a profession.',
        familyQuestion: 'What are you learning that could become worship?',
        storyId: 'prophet-idris',
      ),
      _StoryChapter(
        title: 'Nuh — The Long Building',
        virtue: 'He built the ship for decades before a drop of rain, and called his people for 950 years. Persistence is a form of worship.',
        familyQuestion: 'What are you building that no one can see yet?',
        storyId: 'prophet-nuh',
      ),
      _StoryChapter(
        title: 'Hud and Salih — The Clear Signs',
        virtue: 'Two messengers to two mighty peoples (\u2019Ad and Thamud) — each brought a sign, each was rejected, each was vindicated. The sign is not the problem; the heart is.',
        familyQuestion: 'What sign have you been shown that you have not yet followed?',
        storyId: 'prophet-hud',
      ),
      _StoryChapter(
        title: 'Lut — The Unheeded Warning',
        virtue: 'He warned his people until the angels came — and even then he was told to leave by night. Some doors close while the caller is still calling.',
        familyQuestion: 'When is it time to stop calling someone and start protecting your own household?',
        storyId: 'prophet-lut',
      ),
      _StoryChapter(
        title: 'Ibrahim, Ishaq, and Ya\u2019qub — The Household of Faith',
        virtue: 'One household carried the message for three generations: the father who reasoned to tawhid, the son who submitted, the grandson who named it Israel. Faith is inherited when it is lived.',
        familyQuestion: 'What are you passing down — by your actions, not your words?',
        storyId: 'prophet-ibrahim',
      ),
      _StoryChapter(
        title: 'Ismail — The Willing Son',
        virtue: 'The son who said: O my father, do as you are commanded — you will find me, if Allah wills, of the patient (37:102). The ram replaced the boy, and the ummah still commemorates the surrender at every Eid.',
        familyQuestion: 'What are you willing to surrender that you love — trusting the replacement will come?',
        storyId: 'prophet-ismail',
      ),
      _StoryChapter(
        title: 'Shu\u2019ayb — The Honest Measure',
        virtue: 'He preached to the merchants: give full measure, weigh with the straight scale, do not diminish the people\u2019s goods (11:85). The first economic reformer was a prophet.',
        familyQuestion: 'Is your measure full — at work, at home, in your promises?',
        storyId: 'prophet-shuayb',
      ),
      _StoryChapter(
        title: 'Musa and Harun — The Brother at His Side',
        virtue: 'Musa asked Allah to untie the knot from his tongue and to send Harun, who was more fluent, with him (Qur\u2019an 20:27-30; 28:34). Later reports speak of a speech impediment; the Qur\u2019an does not say so. Asking for support is strength assisted.',
        familyQuestion: 'Who is your Harun — the one you can ask to stand beside you when your own voice shakes?',
        storyId: 'prophet-musa',
      ),
      _StoryChapter(
        title: 'Dawud and Sulayman — The Kingdoms',
        virtue: 'Dawud ruled and recited; Sulayman asked for a kingdom no one would have after him and then asked only to be grateful. Power chose gratitude.',
        familyQuestion: 'What would you ask for if you could ask for anything — and is gratitude in your asking?',
        storyId: 'prophet-sulayman',
      ),
      _StoryChapter(
        title: 'Ayyub — The Patient One',
        virtue: 'Everything taken, years of illness, one dua at the end — and the mountain moved. Long patience, short words.',
        familyQuestion: 'What would you say to Allah if you could only say one sentence?',
        storyId: 'prophet-ayyub',
      ),
      _StoryChapter(
        title: 'Dhul-Kifl — The Oath Kept',
        virtue: 'He swore to judge between his people with justice, day and night. The oath kept is the character written.',
        familyQuestion: 'What oath or promise have you made that you are still keeping?',
        storyId: 'prophet-dhul-kifl',
      ),
      _StoryChapter(
        title: 'Yunus — The Whale\u2019s Belly',
        virtue: 'He ran from the call and landed in the darkest place — and one sentence reached the Throne. No place is too dark for la ilaha illa anta.',
        familyQuestion: 'What is your whale\u2019s belly — and what would you pray from inside it?',
        storyId: 'prophet-yunus',
      ),
      _StoryChapter(
        title: 'Zakariya — The Private Call',
        virtue: 'He asked for a child in a whisper only Allah heard, and the answer came while he was old. Private prayers are not small prayers.',
        familyQuestion: 'What do you pray for that no one else knows — and are you still praying it?',
        storyId: 'prophet-zakariya',
      ),
      _StoryChapter(
        title: 'Isa — The Word from Him',
        virtue: 'Born of a virgin, speaking from the cradle, healing by Allah\u2019s leave — and he said: I am the slave of Allah. The miracles served the message, never the man.',
        familyQuestion: 'What gifts or abilities do you have — and do they serve the message or the ego?',
        storyId: 'prophet-isa',
      ),
      _StoryChapter(
        title: 'Ilyas and Al-Yasa — The Reminders',
        virtue: 'Ilyas reminded his people to worship Allah alone (37:123-126); Al-Yasa succeeded him. The reminder is a relay, not a solo.',
        familyQuestion: 'Who reminded you of Allah when you had forgotten — and have you thanked them?',
        storyId: 'prophet-ilyas',
      ),
      _StoryChapter(
        title: 'Ibrahim\u2019s Sons — The Splitting of the Way',
        virtue: 'From Ishaq came Ya\u2019qub; from Ismail came Muhammad. One father, two branches, one final message. The family tree of faith is wide.',
        familyQuestion: 'What branch of your own family tree could carry a message forward?',
        storyId: 'prophet-ishaq',
      ),
      _StoryChapter(
        title: 'Ibrahim — The Two Rivers of Reason',
        virtue: 'He reasoned his way to tawhid before revelation came — and was thrown into the fire that became cool. Conviction that reasons and then leaps.',
        familyQuestion: 'What belief would you hold even if everyone mocked it?',
        storyId: 'prophet-ibrahim',
      ),
    ],
  ),
  _StoriesUnit(
    title: 'The Khutbahs — Sermons for the Heavy Days',
    frame: 'The Friday sermon, distilled into its theme — for the day you need that exact word.',
    chapters: <_StoryChapter>[
      _StoryChapter(
        title: 'Taif — Praying for Your Enemies\u2019 Grandchildren',
        virtue: 'Stoned and bleeding, and he prayed for the grandchildren of the people who stoned him. The highest form of hope is a dua for your enemy\u2019s children.',
        familyQuestion: 'Who has wronged you — and what would praying for their children look like?',
        storyId: 'kh-taif',
      ),
      _StoryChapter(
        title: 'The Weight of One Atom',
        virtue: 'Whoever does an atom\u2019s weight of good will see it (99:7). The smallest deed is on a scale that never rounds down.',
        familyQuestion: 'What atom-deed did you do today that no one saw?',
        storyId: 'kh-atom',
      ),
      _StoryChapter(
        title: 'The Beautiful Patience',
        virtue: 'Ya\u2019qub said: I only complain of my suffering to Allah (12:86). Grief and patience can share the same chest — the sermon for the grieving.',
        familyQuestion: 'Are you carrying a grief you have not named? Name it tonight.',
        storyId: 'kh-yaqub',
      ),
      _StoryChapter(
        title: 'The First Sermon of the First Caliph',
        virtue: 'Abu Bakr\u2019s first words as caliph: I have been given authority over you, but I am not the best among you. Leadership begins with humility.',
        familyQuestion: 'Where do you lead — and does your leadership begin with humility?',
        storyId: 'kh-abubakr',
      ),
      _StoryChapter(
        title: 'The Grammar of Loss',
        virtue: 'Inna lillahi wa inna ilayhi raji\u2019un — to Allah we belong and to Him we return. The sentence that turns a hit into an address.',
        familyQuestion: 'What loss in your life needs the grammar of return tonight?',
        storyId: 'kh-innalillah',
      ),
      _StoryChapter(
        title: 'The Phone in the Hand',
        virtue: 'The sermon for the screen: the scroll that eats the hour, the feed that is not real. Your attention is an amanah too.',
        familyQuestion: 'What did your phone eat today that you wish it had not?',
        storyId: 'kh-phone',
      ),
      _StoryChapter(
        title: 'Anxiety and the Reframing of Ta\u2019weel',
        virtue: 'Perhaps you dislike a thing and it is good for you (2:216). The re-framing that turns the 3am ceiling into a conversation.',
        familyQuestion: 'What are you anxious about — and what could the ta\u2019weel be?',
        storyId: 'kh-anxiety',
      ),
      _StoryChapter(
        title: 'The Quiet Chain',
        virtue: 'Debt is a chain that gets heavier the longer it is ignored. The sermon for the debtor who is afraid to look at the number.',
        familyQuestion: 'What number are you afraid to look at? Look at it tonight.',
        storyId: 'kh-debt',
      ),
      _StoryChapter(
        title: 'Loneliness in the Crowd',
        virtue: 'Five hundred friends and no one to call. The sermon for the connected and the isolated — and the three doors back.',
        familyQuestion: 'Who could you call tonight that you have not spoken to in a month?',
        storyId: 'kh-lonely',
      ),
      _StoryChapter(
        title: 'Raising Children in the Feed',
        virtue: 'The parent\u2019s sermon: your child is growing up in a feed you did not grow up in. The rules are the same; the arena is new.',
        familyQuestion: 'What rule from your childhood needs a new arena-appropriate version?',
        storyId: 'kh-raising',
      ),
      _StoryChapter(
        title: 'Built to Rest',
        virtue: 'The burnout sermon: the cure is not more productivity — it is barakah. The sabbath of the soul is prayer in the middle of the hustle.',
        familyQuestion: 'When did you last rest without guilt? Schedule one this week.',
        storyId: 'kh-burnout',
      ),
      _StoryChapter(
        title: 'The News That Ate the Heart',
        virtue: 'The news cycle is designed to keep you angry and afraid. Guard your heart — and your duas — from the feed.',
        familyQuestion: 'What news did you consume today that changed nothing you could act on?',
        storyId: 'kh-news',
      ),
      _StoryChapter(
        title: 'For the One Who Is Tired',
        virtue: 'The sermon for exhaustion: with hardship comes ease, in the same sentence twice. The tired one is not the failed one.',
        familyQuestion: 'Are you tired — and have you told Allah, or only the ceiling?',
        storyId: 'kh-tired-013',
      ),
      _StoryChapter(
        title: 'The Load She Carries',
        virtue: 'The sermon for the woman who carries the house and the job and the faith: your load is seen, and it is not forever.',
        familyQuestion: 'What load are you carrying that no one has named? Name it to someone this week.',
        storyId: 'kh-women-carry',
      ),
      _StoryChapter(
        title: 'The Door That Opens With the Pain',
        virtue: 'Sabr is not waiting for the storm to pass — it is learning to stand in the rain. The sermon for the season that has lasted too long.',
        familyQuestion: 'What storm are you standing in — and are you standing or running?',
        storyId: 'kh-patience',
      ),
      _StoryChapter(
        title: 'The Increase Clause',
        virtue: 'If you are grateful, I will surely increase you (14:7). The contract with increase written into it.',
        familyQuestion: 'Name three things before sleep tonight that you never earned.',
        storyId: 'kh-gratitude',
      ),
    ],
  ),
];






/// The gentle stories shown while child mode is on. The others (a man who
/// killed, a woman who sinned, the sermons, the last days) are for older
/// learners; a grown-up opens them after leaving child mode.
const Set<String> kChildStoryIds = <String>{
  'prophet-adam',
  'prophet-nuh',
  'prophet-yunus',
  'prophet-ayyub',
  'prophet-sulayman',
  'tale-cave-people',
  'tale-two-gardens',
};

class StoriesSchoolScreen extends StatelessWidget {
  const StoriesSchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              const ScreenHeader(title: 'Stories', close: true),
              const ScholarReviewNote(
                reviewKey: 'school.stories-school',
                padding: EdgeInsets.only(bottom: 8),
              ),
              Text('القصص',
                  style: AppText.arabic.copyWith(fontSize: 28, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(
                'The library\u2019s stories as a moral curriculum — patience, courage, mercy, gratitude',
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final _StoriesUnit unit in kStoriesUnits)
                if (!kChildMode.value ||
                    unit.chapters.any((c) => kChildStoryIds.contains(c.storyId))) ...<Widget>[
                Text(unit.title.toUpperCase(), style: AppText.eyebrow),
                const SizedBox(height: 6),
                if (!kChildMode.value)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(unit.frame,
                      style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.55)),
                ),
                for (final _StoryChapter ch in unit.chapters)
                  if (!kChildMode.value || kChildStoryIds.contains(ch.storyId))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      // Opens the full story (the id is one of the library's
                      // own story ids; the reader looks it up by that id).
                      onTap: () => context.open(
                        '${AppRoutes.storyReader}?id=${Uri.encodeQueryComponent(ch.storyId)}',
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(children: <Widget>[
                            Expanded(
                              child: Text(ch.title, style: AppText.body.copyWith(
                                  fontWeight: FontWeight.w600, fontSize: 13.5)),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 18, color: AppColors.gold),
                          ]),
                          const SizedBox(height: 4),
                          if (kChildMode.value)
                            Text('A story to read together.',
                                style: AppText.bodyMuted
                                    .copyWith(fontSize: 12, height: 1.5))
                          else ...<Widget>[
                          Text(ch.virtue, style: AppText.bodyMuted.copyWith(
                              fontSize: 12, height: 1.5)),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.3)),
                            ),
                            child: Text('Talk it over: ${ch.familyQuestion}',
                                style: AppText.bodyMuted.copyWith(
                                    fontSize: 12, height: 1.5, color: AppColors.gold)),
                          ),
                          ],
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
