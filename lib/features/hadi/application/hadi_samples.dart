/// Suggested questions and static answers for the Hādī screen (Phase 2 UI).
///
/// STATUS: PROPOSED — pending Founder approval (Master Build Sheet §6.6).
/// Live AI arrives in Phase 4 behind a provider interface (open item O-7).
class HadiExchange {
  const HadiExchange({required this.question, required this.answer});

  final String question;
  final String answer;
}

const List<HadiExchange> kProposedHadiExchanges = [
  HadiExchange(
    question: 'What is the virtue of Surah Al-Kahf?',
    answer:
        'The Prophet ﷺ said: “Whoever reads Surah Al-Kahf on Friday, a light '
        'will shine for him between the two Fridays.” (al-Bayhaqi). It is also '
        'a protection from the trial of the Dajjal. Shall I open it for you?',
  ),
  HadiExchange(
    question: 'A du’a for anxiety',
    answer:
        'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ — “O Allah, I '
        'seek refuge in You from worry and grief, from incapacity and '
        'laziness.” (Bukhari). Repeat it morning and evening, and breathe — '
        'He is near.',
  ),
  HadiExchange(
    question: 'How do I pray Witr?',
    answer:
        'Witr is prayed after ‘Isha until Fajr, as an odd number of rak’ahs — '
        'most simply one rak’ah. After ruku‘ you may recite Qunut: '
        '“Allahumma ihdini fiman hadayt…” Would you like the full text?',
  ),
];

const String kHadiGreeting =
    'As-Salaamu Alaikum. I am Hādi — walking beside you as you seek authentic '
    'knowledge. Ask me anything.';

const String kHadiFallback =
    'A beautiful question. While this preview connects soon to the full '
    'knowledge base — rooted in the Qur’an and Sunnah with the understanding '
    'of the Salaf — try one of the suggested questions above.';
