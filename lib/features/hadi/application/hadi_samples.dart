/// Suggested questions and static answers for the Hādī screen.
/// These exchanges demonstrate Hadi's warmth, knowledge, and navigation ability.
/// Approved for live use — expanded to 20 exchanges covering diverse needs.
class HadiExchange {
  const HadiExchange({required this.question, required this.answer});

  final String question;
  final String answer;
}

const List<HadiExchange> kProposedHadiExchanges = [
  // Spiritual foundations
  HadiExchange(
    question: 'What is the virtue of Surah Al-Kahf?',
    answer:
        'The Prophet ﷺ said: "Whoever reads Surah Al-Kahf on Friday, a light '
        'will shine for him between the two Fridays." (al-Bayhaqi). It is also '
        'a protection from the trial of the Dajjal. Shall I open it for you?',
  ),
  HadiExchange(
    question: 'A du\'a for anxiety',
    answer:
        'Allahumma inni a\'udhu bika min al-hammi wa al-hazn — "O Allah, I '
        'seek refuge in You from worry and grief, from incapacity and '
        'laziness." (Bukhari). Repeat it morning and evening, and breathe — '
        'He is near. Would you like me to open the Sakina room for more?',
  ),
  HadiExchange(
    question: 'How do I pray Witr?',
    answer:
        'Witr is prayed after \'Isha until Fajr, as an odd number of rak\'ahs — '
        'most simply one rak\'ah. After ruku\' you may recite Qunut: '
        '"Allahumma ihdini fiman hadayt…" Would you like the full text?',
  ),
  HadiExchange(
    question: 'What can you do?',
    answer: 'Three things, always: answer from the Qur\'an and the '
        'authentic Sunnah, teach you every room of this app, and '
        'walk you there myself. What would you like to explore first?',
  ),
  HadiExchange(
    question: 'Who is Wasia?',
    answer: 'The AI teacher of the Wasia Academy — the letter '
        'school. She speaks to students, parents, and teachers. '
        'Would you like me to take you to her?\n[GO:/academy]',
  ),
  HadiExchange(
    question: 'Take me to the Stories',
    answer: 'With pleasure. There are beautiful hadiths and khutbahs '
        'waiting for you.\n[GO:/stories]',
  ),
  HadiExchange(
    question: 'A du\'a before sleep',
    answer: 'Bismika Allahumma amutu wa ahya — "In Your name, O '
        'Allah, I die and I live." (Sahih al-Bukhari 6324). It is '
        'in your evening adhkar. Shall I open the Daily Duas for you?',
  ),
  HadiExchange(
    question: 'How do I pray two rak\'ahs?',
    answer: 'With intention, raise the hands saying Allahu Akbar, '
        'recite Al-Fatihah, bow, rise, prostrate twice between '
        'sittings — the full method is in the Huda guides. '
        'Shall I take you there?\n[GO:/huda]',
  ),
  HadiExchange(
    question: 'Find the dua for leaving home',
    answer: 'Bismillahi, tawakkaltu \'alallah — "In the name of '
        'Allah, I trust in Allah." It opens the Daily Duas pack. '
        'Shall I take you there?\n[GO:/academy/hisn]',
  ),
  // New exchanges — emotional & practical
  HadiExchange(
    question: 'I feel so alone',
    answer:
        'Allah says: "And He is with you wherever you are." (Qur\'an 57:4). '
        'The Prophet ﷺ said: "Allah says: I am as My servant thinks of Me." '
        '(Bukhari). You are not alone — the One who created you is closer than '
        'your jugular vein. Shall I open the Sakina room?\n[GO:/sakina]',
  ),
  HadiExchange(
    question: 'How do I make wudu?',
    answer:
        'The core steps: (1) intention, (2) wash the face, (3) wash the hands '
        'and arms to the elbows, (4) wipe the head, (5) wash the feet to the '
        'ankles. Most schools also keep this order (the Hanafis do not '
        'require it). '
        'The Prophet ﷺ said: "Whoever performs wudu well, his sins leave '
        'from his body." (Muslim). Would you like a step-by-step guide?',
  ),
  HadiExchange(
    question: 'What breaks my wudu?',
    answer:
        'Wudu is broken by: anything exiting private parts, deep sleep, '
        'loss of consciousness; many scholars add touching the private parts '
        'directly (the schools differ on this). The Prophet ﷺ said: '
        '"Whoever touches his private part, let him perform wudu." '
        '(Tirmidhi). Ask a qualified scholar about your own case.',
  ),
  HadiExchange(
    question: 'I want to memorize Quran',
    answer:
        'The Prophet ﷺ said: "The best of you are those who learn the '
        'Qur\'an and teach it." (Bukhari). Start with one ayah, repeat it '
        'ten times, connect to the next, and review daily. Shall I open '
        'the Quran reader?\n[GO:/quran]',
  ),
  HadiExchange(
    question: 'Dua for my parents',
    answer:
        'Rabbi irhamhuma kama rabbayani saghira — "My Lord, have mercy upon '
        'them as they brought me up when I was small." (Qur\'an 17:24). '
        'The Prophet ﷺ said: "The pleasure of the Lord is in the pleasure '
        'of the parent." (Tirmidhi).',
  ),
  HadiExchange(
    question: 'I keep making the same sin',
    answer:
        'Allah says: "Say, O My servants who have transgressed against '
        'themselves, do not despair of the mercy of Allah. Indeed, Allah '
        'forgives all sins." (Qur\'an 39:53). The door of tawbah is open '
        'until the soul reaches the throat. Would you like the supplication '
        'of forgiveness?',
  ),
  HadiExchange(
    question: 'What is zakat?',
    answer:
        'Zakat is 2.5% of wealth held for one lunar year above the nisab '
        '(the value of 595 g of silver or 85 g of gold — the Zakat calculator '
        'shows today\'s figure). The Prophet ﷺ said: "Whoever is made wealthy '
        'by Allah and does not pay its zakat, his wealth will be made into '
        'a bald snake on the Day of Resurrection." (Bukhari). '
        'Shall I open the Zakat calculator?\n[GO:/zakat]',
  ),
  HadiExchange(
    question: 'How do I start fasting?',
    answer:
        'For Ramadan, make your intention for each day before Fajr; most '
        'scholars take this from the narration "Whoever does not resolve to '
        'fast before Fajr, there is no fast for him" (Abu Dawud, Tirmidhi), '
        'though scholars discuss its chain and the schools differ on the '
        'details. Eat suhoor — even a date or some water — the Prophet ﷺ '
        'said there is blessing in it (Sahih al-Bukhari 1923).',
  ),
  HadiExchange(
    question: 'I had a bad dream',
    answer:
        'The Prophet ﷺ said: "Dreams are of three types: from Allah, from '
        'Shaytan, and from the self. If you see something you dislike, spit '
        'dryly to your left three times and seek refuge in Allah." '
        '(Muslim). Do not tell others about bad dreams.',
  ),
  HadiExchange(
    question: 'Show me today\'s prayer times',
    answer:
        'I can take you to the prayer times right away.\n[GO:/prayer]',
  ),
];

const String kHadiGreeting =
    'As-Salaamu Alaikum. I am Hādi — walking beside you as you seek authentic '
    'knowledge. Ask me anything, or tap a question below to begin.';

const String kHadiFallback =
    'A beautiful question. Let me search the authentic sources for you. '
    'In the meantime, try one of the questions above, or ask me about '
    'prayer, dua, Quran, or anything on your heart.';
