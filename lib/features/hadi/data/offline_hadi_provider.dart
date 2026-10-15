import '../application/hadi_provider.dart';

/// Curated authentic knowledge for offline use — always available, no key,
/// no network. Every entry is sourced from the Qur'an or the Sihah Sitta
/// (the Founder's approved sources). Unknown questions get an honest
/// decline — Hādi never invents.
class OfflineHadiProvider implements HadiProvider {
  const OfflineHadiProvider();

  static const String decline =
      'I don\'t have enough authentic knowledge to answer that with '
      'certainty, and I would rather not guess. For guided learning I '
      'recommend Shaykh Muhammad Saqib Iqbal\'s channel (linked in Our '
      'Sources), or a qualified local scholar. Add a free API key in Hādi '
      'settings and I can reason further.';

  @override
  Future<String> ask(String question, List<HadiMessage> history) async {
    final String q = question.toLowerCase();
    int bestScore = 0;
    String bestAnswer = decline;
    for (final _Entry e in _knowledge) {
      int score = 0;
      for (final String k in e.keywords) {
        if (q.contains(k)) score += k.length; // longer match = more specific
      }
      if (score > bestScore) {
        bestScore = score;
        bestAnswer = e.answer;
      }
    }
    return bestAnswer;
  }
}

class _Entry {
  const _Entry(this.keywords, this.answer);
  final List<String> keywords;
  final String answer;
}

const List<_Entry> _knowledge = <_Entry>[
  _Entry(
    <String>['al-kahf', 'kahf', 'friday'],
    'The Prophet ﷺ said: “Whoever reads Surah Al-Kahf on Friday, a light '
    'will shine for him between the two Fridays.” (al-Bayhaqi, classed '
    'sahih). Its first ten verses are also a protection from the trial of '
    'the Dajjal (Sahih Muslim).',
  ),
  _Entry(
    <String>['anxiety', 'anxious', 'worry', 'worried', 'stress', 'grief'],
    'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ — “O Allah, I '
    'seek refuge in You from worry and grief, from incapacity and '
    'laziness, from cowardice and miserliness, from the burden of debt '
    'and from being overpowered by men.” (Sahih al-Bukhari 6369). '
    'You will also find it in your Morning Adhkar set.',
  ),
  _Entry(
    <String>['witr'],
    'Witr is prayed after ‘Isha until Fajr, as an odd number of rak\'ahs — '
    'most simply one. “Allah is Witr (One) and loves witr.” (Sahih '
    'al-Bukhari 990). After ruku‘ you may recite Qunut: “Allahumma ihdini '
    'fiman hadayt…” (Sunan Abu Dawood 1425).',
  ),
  _Entry(
    <String>['morning adhkar', 'adhkar', 'dhikr', 'remembrance'],
    'Your Dhikr & Du\'a screen holds the morning, evening, and '
    'after-prayer sets from Hisn al-Muslim with meanings. The Prophet ﷺ '
    'said the morning and evening adhkar protect the one who says them '
    '(Sunan Abu Dawood 5088). Open it from Home and tap the counters as '
    'you recite.',
  ),
  _Entry(
    <String>['ramadan', 'fasting', 'fast', 'sawm', 'suhoor', 'iftar'],
    'Fasting Ramadan is the fourth pillar of Islam (Qur\'an 2:183-185). '
    '“Whoever fasts Ramadan out of faith and hope for reward, his past '
    'sins are forgiven.” (Sahih al-Bukhari 38). Take suhoor — “in suhoor '
    'there is blessing” (Bukhari 1923) — and check the Islamic Calendar '
    'screen for this year\'s dates.',
  ),
  _Entry(
    <String>['zakat', 'charity', 'sadaqah'],
    'Zakat is the third pillar — 2.5% of qualifying wealth held a lunar '
    'year above the nisab. “Whoever pays it seeking reward…” (Sahih '
    'al-Bukhari 1395). The Zakat screen in Ar-Rayaan calculates it for '
    'you step by step.',
  ),
  _Entry(
    <String>['prayer time', 'prayer times', 'salah times', 'namaz time'],
    'Your Prayer Times screen calculates today\'s schedule right on your '
    'device — tap GPS or choose your city, and turn on the bell next to '
    'any prayer to be alerted when its time arrives.',
  ),
  _Entry(
    <String>['how do i pray', 'how to pray', 'salah', 'pray witr'],
    'Prayer is the second pillar. “Pray as you have seen me pray.” '
    '(Sahih al-Bukhari 631). Five daily prayers are obligatory; the '
    'Prophet\'s ﷺ complete method is recorded across the six books — '
    'Shaykh Saqib Iqbal\'s channel (in Our Sources) walks through it '
    'beautifully, step by step.',
  ),
  _Entry(
    <String>['quran', 'qur\'an', 'recite', 'recitation'],
    'The Qur\'an screen holds all 114 surahs — tap any ayah to hear '
    'recitation by Shaykh Mishary Rashid Alafasy. “The best of you are '
    'those who learn the Qur\'an and teach it.” (Sahih al-Bukhari 5027).',
  ),
  _Entry(
    <String>['dua for anxiety', 'du\'a', 'dua', 'supplication'],
    'Du\'a is worship itself (Jami\' at-Tirmidhi 3372). For a need, '
    'begin with praise of Allah and salawat on the Prophet ﷺ, then ask '
    'with certainty. Your Dhikr & Du\'a screen carries the authentic '
    'daily supplications with their meanings.',
  ),
  _Entry(
    <String>['eid'],
    'The two Eids are days of prayer, takbir, and celebration (Sahih '
    'al-Bukhari 950-956). Eid al-Fitr follows Ramadan; Eid al-Adha falls '
    'on 10 Dhul-Hijjah, the day after Arafah. Exact dates for this year '
    'are on the Islamic Calendar screen.',
  ),
  _Entry(
    <String>['sources', 'authentic', 'hadith book', 'sihah', 'bukhari'],
    'Ar-Rayaan builds only on the Qur\'an and the Sihah Sitta — the six '
    'authentic books: Sahih al-Bukhari, Sahih Muslim, Sunan Abu Dawood, '
    'Jami\' at-Tirmidhi, Sunan an-Nasa\'i, and Sunan Ibn Majah — with '
    'Shaykh Muhammad Saqib Iqbal\'s channel for guided learning. See the '
    'full list on the Our Sources screen.',
  ),
  _Entry(
    <String>['hajj', 'umrah', 'pilgrimage'],
    'Hajj is the fifth pillar, owed once in a lifetime by those able '
    '(Qur\'an 3:97). “An accepted Hajj has no reward but Paradise.” '
    '(Sahih al-Bukhari 1773). Umrah can be performed any time of year.',
  ),
  _Entry(
    <String>['tahajjud', 'night prayer', 'qiyam'],
    'The night prayer is the best prayer after the obligatory ones '
    '(Sahih Muslim 1163). The last third of the night is a special time '
    'for du\'a — your Prayer Times screen shows tonight\'s window.',
  ),
  _Entry(
    <String>['forgive', 'repent', 'tawbah', 'sin'],
    'Allah says: “Do not despair of Allah\'s mercy; indeed Allah forgives '
    'all sins.” (Qur\'an 39:53). The Prophet ﷺ said: “Every son of Adam '
    'sins, and the best of sinners are those who repent.” (Jami\' '
    'at-Tirmidhi 2499, sahih). The door is open — walk through it.',
  ),
  _Entry(
    <String>['mother', 'father', 'parents'],
    '“Paradise lies beneath the feet of mothers.” (Sunan an-Nasa\'i '
    '3104, sahih). The Prophet ﷺ was asked who most deserves good '
    'companionship: “Your mother” — three times — “then your father.” '
    '(Sahih al-Bukhari 5971).',
  ),
  _Entry(
    <String>['istighfar', 'sayyid'],
    'Sayyid al-Istighfar is the master supplication for forgiveness — '
    'it opens your Morning Adhkar set. Whoever says it with conviction '
    'in the morning and dies that day enters Paradise (Sahih al-Bukhari '
    '6306).',
  ),
  _Entry(
    <String>['patience', 'sabr', 'hardship', 'difficult', 'trial'],
    '“Indeed, Allah is with the patient.” (Qur\'an 2:153). “Amazing is '
    'the affair of the believer: all of it is good for him — gratitude '
    'in ease, patience in hardship.” (Sahih Muslim 2999). This too '
    'shall pass, and nothing is wasted with Him.',
  ),
  _Entry(
    <String>['name of allah', 'names of allah', '99'],
    '“Allah has ninety-nine names; whoever preserves them enters '
    'Paradise.” (Sahih al-Bukhari 2736). Begin with Ar-Rahman — the '
    'Most Merciful — the name He opens His Book with.',
  ),
  // ── Conversational packs ────────────────────────────────────────────
  _Entry(
    <String>['salaam', 'salam', 'assalamu', 'wa alaikum', 'hello', 'hey '],
    'Wa alaikum as-salam wa rahmatullah - and upon you be peace and '
    'mercy. How may I walk beside you today? Ask me about worship, '
    'the Qur\'an, this app, or simply talk.',
  ),
  _Entry(
    <String>['how are you', 'how do you feel'],
    'Alhamdulillah - all praise belongs to Allah. More importantly: '
    'how are YOU? If something weighs on your heart, I can make '
    'du\'a with you, or take you to Sakina for stillness.',
  ),
  _Entry(
    <String>['who are you', 'your name', 'your hadi'],
    'I am Hadi - "the guide" - your companion inside Ar-Rayaan. I '
    'answer from the Qur\'an and the Sihah Sitta: Sahih al-Bukhari, '
    'Sahih Muslim, Sunan Abu Dawood, Jami\' at-Tirmidhi, Sunan '
    'an-Nasa\'i, and Sunan Ibn Majah - and I know every room of this '
    'app. I would rather say "I don\'t know" than invent. My '
    'sister-teacher Wasia runs the letter school.',
  ),
  _Entry(
    <String>['who is wasia', 'what is wasia'],
    'Wasia is the AI teacher of the Wasia Academy - the letter '
    'school built with love. She teaches the Arabic alphabet, reads '
    'with the child, and speaks in three voices: student, parent, '
    'and a Teachers\' Corner for parents. Shall I take you there?\n[GO:/academy/gate]',
  ),
  _Entry(
    <String>['thank', 'jazak', 'shukran', 'thanks'],
    'Wa iyyakum - and you likewise, many times over. May Allah '
    'accept from you. I am here whenever you need me.',
  ),
  _Entry(
    <String>['what can you do', 'what do you do', 'features', 'guide me'],
    'Three things, always: (1) answer from the Qur\'an and the '
    'Sihah Sitta - verses, du\'as, rulings, with sources; (2) teach '
    'you this app room by room - prayer times, Qur\'an, stories, '
    'zakat, games; (3) walk you there myself - just say "take me '
    'to..." and I will. What shall we begin with?',
  ),

  // ── Navigation packs (offline users get walked too) ─────────────────
  _Entry(
    <String>['quran screen', 'read the quran', 'recitation screen', 'open quran'],
    'Opening the Qur\'an - tap any ayah to hear Shaykh Mishary '
    'Rashid Alafasy recite.\n[GO:/quran]',
  ),
  _Entry(
    <String>['prayer times screen', 'prayer screen', 'salah times screen'],
    'Opening your Prayer Times - tap the bell beside any prayer to '
    'be alerted when its time arrives.\n[GO:/prayer]',
  ),
  _Entry(
    <String>['adhkar screen', 'dhikr screen', 'dua screen', 'du\'a screen'],
    'Opening Dhikr & Du\'a - the Hisn al-Muslim sets with counters '
    'and meanings.\n[GO:/adhkar]',
  ),
  _Entry(
    <String>['zakat screen', 'zakat calculator'],
    'Opening the Zakat calculator - it walks you through nisab and '
    'rates step by step.\n[GO:/zakat]',
  ),
  _Entry(
    <String>['stories screen', 'story screen', 'prophets screen'],
    'Opening Stories - Prophets, Women, Seerah, Companions, duas '
    'and khutbahs. Inside any story you can ask me about it as you '
    'read.\n[GO:/stories]',
  ),
  _Entry(
    <String>['search screen', 'find anything', 'find screen'],
    'Opening Find Anything - one search across every shelf of the '
    'app.\n[GO:/search]',
  ),
  _Entry(
    <String>['games screen', 'game screen'],
    'Opening Games - Shatranj, Ludo, Trivia, and the 99 Names.\n[GO:/games]',
  ),
  _Entry(
    <String>['99 names screen', 'names screen', 'names of allah screen'],
    'Opening the 99 Names - learn them one by one; "whoever '
    'preserves them enters Paradise."\n[GO:/games/names99]',
  ),
  _Entry(
    <String>['hadith screen', 'forty hadith', 'nawawi screen'],
    'Opening the Forty Hadith of an-Nawawi, Arabic with meanings.\n[GO:/hadith]',
  ),
  _Entry(
    <String>['qibla screen', 'find qibla', 'qibla direction', 'face qibla'],
    'Opening Qibla - hold your phone flat and it points you to the '
    'Ka\'bah.\n[GO:/qibla]',
  ),
  _Entry(
    <String>['calendar screen', 'islamic calendar', 'ramadan dates', 'eid dates'],
    'Opening the Islamic Calendar - this year\'s months, Ramadan '
    'and Eid dates.\n[GO:/calendar]',
  ),
  _Entry(
    <String>['finance screen', 'stocks screen', 'trading screen', 'halal stocks'],
    'Opening Tayyib Finance - the halal stock screener and a paper '
    'trading floor to practice on.\n[GO:/finance]',
  ),
  _Entry(
    <String>['academy screen', 'school screen', 'letters screen', 'alphabet'],
    'Opening Wasia Academy - where children learn the Arabic '
    'letters with Wasia.\n[GO:/academy/gate]',
  ),
  _Entry(
    <String>['feelings screen', 'heart screen'],
    'Opening For Your Heart - a gentle feelings guide with a du\'a '
    'for every state.\n[GO:/feelings]',
  ),
  _Entry(
    <String>['sakina', 'comfort screen', 'peace screen'],
    'Opening Sakina - a page of stillness for when the heart is '
    'heavy.\n[GO:/sakina]',
  ),
  _Entry(
    <String>['family tree screen', 'messengers screen'],
    'Opening the Messengers\' family tree - from Adam to the '
    'Prophet Muhammad (peace be upon them all).\n[GO:/family-tree]',
  ),
  _Entry(
    <String>['share screen', 'cards screen', 'verse cards'],
    'Opening verse cards - share an ayah with someone you love.\n[GO:/share]',
  ),
  _Entry(
    <String>['sources screen', 'our sources'],
    'Opening Our Sources - every authority this app builds on.\n[GO:/sources]',
  ),
  _Entry(
    <String>['settings screen', 'api key', 'apikey', 'add a key'],
    'Opening Settings - in Hadi\'s section you can add your free '
    'API key so I can reason further; without one I still answer '
    'from the curated shelf.\n[GO:/settings]',
  ),
  _Entry(
    <String>['masajid', 'masjid', 'mosque', 'halal food', 'restaurants'],
    'Opening Masajid & Halal - prayer spaces and halal food near '
    'you.\n[GO:/masajid]',
  ),

  // ── Knowledge packs ─────────────────────────────────────────────────
  _Entry(
    <String>['shahada', 'testimony', 'declaration of faith'],
    'The testimony: "La ilaha illallah, Muhammadur rasulullah" - '
    'there is no god worthy of worship but Allah, and Muhammad is '
    'the Messenger of Allah. The first pillar; on it everything '
    'stands.',
  ),
  _Entry(
    <String>['pillars of islam', 'five pillars'],
    'The five pillars: the testimony of faith, the five daily '
    'prayers, zakat, the fast of Ramadan, and Hajj for those able '
    '- each established in the Qur\'an and the Sunnah.',
  ),
  _Entry(
    <String>['wudu', 'ablution'],
    'Wudu is the purification before prayer: wash the face, hands '
    'to the elbows, wipe head and ears, wash the feet - with '
    'intention and in order. "Allah does not accept prayer without '
    'purification." (Sahih Muslim 224).',
  ),
  _Entry(
    <String>['grave', 'after death', 'hereafter'],
    'The Prophet (peace be upon him) said: "Remember often the '
    'destroyer of pleasures - death." (Jami\' at-Tirmidhi 2307). '
    'Live each prayer as if it were your last; the grave is a '
    'garden from Paradise or a pit from the Fire - and its morning '
    'is near.',
  ),
];
