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
  // ── Daily-life du'as ────────────────────────────────────────────────
  _Entry(
    <String>['morning adhkar', 'evening adhkar', 'morning dua', 'evening dua', 'morning remembrance', 'evening remembrance'],
    'The morning and evening adhkar are the shield of the day: Ayat '
    'al-Kursi, the three Quls, "Raditu billahi rabba..." - whoever '
    'says them morning and evening is sufficed. They live in your '
    'Dhikr & Du\'a sets with counters and meanings.',
  ),
  _Entry(
    <String>['before eating', 'after eating', 'eating dua', 'food dua', 'eat dua'],
    'Before eating: "Bismillah" - and if you forget, say "Bismillahi '
    'awwalahu wa akhirahu". After: "Alhamdulillahilladhi at\'amana '
    'wa saqana wa ja\'alana muslimin" - all praise to Allah who fed '
    'us, gave us drink, and made us Muslims. (Abu Dawood 3761, 3201)',
  ),
  _Entry(
    <String>['dua for parents', 'my parents', 'parents', 'mother dua', 'father dua'],
    'The Qur\'an itself teaches the du\'a: "Rabbir hamhumaa kamaa '
    'rabbayaani saghira" - My Lord, have mercy on them as they '
    'raised me when I was small (Al-Isra 24). Say it after every '
    'prayer; it is among the most beloved of speech.',
  ),
  _Entry(
    <String>['dua for the sick', 'someone sick', 'visiting the sick', 'ill dua', 'cure dua'],
    'For the sick: place your hand where it hurts and say "Bismillah" '
    'three times, then "As\'alullah al-\'Azim Rabbal-\'arshil-'
    'azim an yashfiyak" - I ask Allah the Magnificent, Lord of the '
    'Magnificent Throne, to cure you - seven times. (Sahih al-Bukhari '
    '5675). And visiting the sick is an expiation: its fruits ripen '
    'in Paradise. (Bukhari 5402)',
  ),

  // ── Character and heart ─────────────────────────────────────────────
  _Entry(
    <String>['anxious', 'anxiety', 'worried', 'worry', 'depressed', 'overwhelmed', 'scared', 'afraid'],
    'For a heavy heart: "Hasbunallahu wa ni\'mal wakeel" - Allah is '
    'sufficient for us, and He is the best Disposer of affairs '
    '(Al-Imran 173) - the words of Ibrahim and our Prophet in '
    'distress. And the Prophet (peace be upon him) said: "There is '
    'no worry or grief for the servant who, in hardship, says: Ya '
    'Hayyu ya Qayyum, bi-rahmatika astagheeth." (Sunan Ibn Majah 3881). '
    'Sakina is in this app for you too.',
  ),
  _Entry(
    <String>['niyyah', 'intention', 'why do we', 'actions are'],
    '"Actions are only by intentions, and every person shall have '
    'what he intended." (Sahih al-Bukhari 1 - the very first hadith). '
    'The reward of an act lives in its intention: prayer for showing '
    'off is empty, and sweeping a floor for Allah is worship.',
  ),
  _Entry(
    <String>['mercy', 'be kind', 'kindness', 'gentle', 'compassion'],
    '"The merciful are shown mercy by Ar-Rahman. Be merciful to '
    'those on earth, and the One above the heavens will be merciful '
    'to you." (Jami\' at-Tirmidhi 1924). "He who does not show mercy '
    'will not be shown mercy." (Sahih al-Bukhari 6013). Kindness - '
    'rifq - beautifies everything it touches.',
  ),
  _Entry(
    <String>['neighbor', 'neighbour', 'next door'],
    'Jibreel kept advising the Prophet about the neighbor until he '
    'thought he would make him an heir: the neighbor has a right '
    'almost of kinship. (Sahih al-Bukhari 6015) Good neighborhood - '
    'guarding dignity, sharing food, soft greetings - is faith in '
    'daily dress.',
  ),
  _Entry(
    <String>['gossip', 'backbite', 'speak good', 'talk bad', 'rumors'],
    '"Whoever believes in Allah and the Last Day, let him speak '
    'good or remain silent." (Sahih al-Bukhari 6018). Backbiting - '
    'mentioning your brother with what he dislikes - is described in '
    'the Qur\'an as eating the flesh of a dead brother (Al-Hujurat '
    '12). If speech is not good, silence is worship.',
  ),

  // ── Worship deep-dives ──────────────────────────────────────────────
  _Entry(
    <String>['sadaqah', 'charity', 'give money', 'donate'],
    '"Charity does not decrease wealth." (Sahih Muslim 2588). "Your '
    'smile in your brother\'s face is charity; removing harm from '
    'the path is charity." (Jami\' at-Tirmidhi 1956). The zakat '
    'calculator in this app handles the obligatory share; beyond it, '
    'even half a date shields against the Fire. (Bukhari 5049)',
  ),
  _Entry(
    <String>['tawbah', 'repent', 'repentance', 'forgiveness', 'forgive me', 'sinned'],
    'Allah says: "Despair not of the mercy of Allah; indeed Allah '
    'forgives all sins" (Az-Zumar 53). The Prophet said: "By the One '
    'in Whose hand is my soul, if you did not sin, Allah would '
    'replace you with people who sin and seek forgiveness - and He '
    'would forgive them." (Sahih Muslim 2749). Repentance: leave the '
    'sin, regret it, resolve not to return - and restore rights if '
    'anyone was wronged.',
  ),
  _Entry(
    <String>['hajj', 'pilgrimage', 'makkah trip'],
    'Hajj, the fifth pillar, is owed once in a lifetime by whoever '
    'can find a way: "And to Allah is a duty upon mankind - the '
    'pilgrimage of the House - for whoever can make the way" (Al-'
    'Imran 97). "An accepted Hajj has no reward but Paradise." '
    '(Sahih al-Bukhari 1521). Its rites gather at the Ka\'bah, '
    'Arafat, Muzdalifah, and Mina across Dhul-Hijjah.',
  ),
  _Entry(
    <String>['umrah', 'minor pilgrimage', 'omra'],
    'Umrah is the shorter pilgrimage, performable any time of year: '
    'ihram, tawaf of the Ka\'bah, sa\'i between Safa and Marwah, '
    'and shaving or shortening the hair. The Prophet said an Umrah '
    'in Ramadan equals a Hajj with him in reward. (Sahih al-Bukhari '
    '1782)',
  ),
  _Entry(
    <String>['tahajjud', 'night prayer', 'qiyam', 'pray at night'],
    '"The best prayer after the obligatory prayers is the night '
    'prayer." (Sahih Muslim 1163). Tahajjud is prayed after sleeping '
    'a portion of the night, in units of two: "Their sides forsake '
    'their beds, calling their Lord in fear and hope" (As-Sajdah '
    '16). Start with two rak\'ah before Fajr; Allah descends to the '
    'lowest heaven asking who is calling upon Him. (Bukhari 1145)',
  ),
  _Entry(
    <String>['istikhara', 'decision dua', 'should i do', 'big decision', 'choice dua'],
    'For any matter - marriage, a job, a move - pray two units of '
    'non-obligatory prayer, then the du\'a of istikhara taught by '
    'the Prophet himself: "Allahumma inni astakhiruka bi-\'ilmik..." '
    '- O Allah, I seek Your choice by Your knowledge... Then choose '
    'what feels settled in your heart, for the Prophet said: "If '
    'one of you intends a matter, let him pray two rak\'ah." '
    '(Sahih al-Bukhari 1162)',
  ),
  _Entry(
    <String>['laylatul qadr', 'night of decree', 'qadr', 'best night', 'odd nights'],
    'Laylatul Qadr, in the last ten nights of Ramadan - in the odd '
    'nights, the 21st, 23rd, 25th, 27th, 29th: "Better than a '
    'thousand months" (Al-Qadr 3). Seek it in the odd nights: stand, '
    'recite, ask - "There is no night in which the servants descend '
    'more numerous..." (Bukhari 2017). What would you do with 83 '
    'years of worship in one night?',
  ),
  _Entry(
    <String>['breaking fast', 'iftar dua', 'iftar', 'end of fast'],
    'At iftar, before eating, say: "Dhahaba al-zama\'u wabtallat '
    'al-urooqu wa thabata al-ajru in sha Allah" - The thirst is gone, '
    'the veins are moistened, and the reward is fixed, if Allah '
    'wills. (Sunan Abu Dawood 2357). The fasting person has a du\'a '
    'at the moment of breaking that is not rejected. (Ibn Majah 1753)',
  ),
  _Entry(
    <String>['durood', 'salawat', 'bless the prophet', 'blessings on the prophet'],
    '"Whoever sends one blessing upon me, Allah sends ten upon him." '
    '(Sahih Muslim 408). The least of it: "Allahumma salli \'ala '
    'Muhammad" - O Allah, send Your peace and blessings upon '
    'Muhammad. It is the signature of love: your prayer is not '
    'complete without it.',
  ),
  _Entry(
    <String>['spread salam', 'say salam', 'greeting islam', 'how to greet'],
    '"Spread salam among yourselves." (Sahih al-Bukhari 28). The '
    'greeting of Islam - "As-salamu alaikum warahmatullah" - carries '
    'three levels: peace, then mercy, then Allah\'s blessings; add '
    'them all, for each raises the giver a degree and wipes a sin.',
  ),

  // ── Knowledge and daily life ────────────────────────────────────────
  _Entry(
    <String>['seeking knowledge', 'learn islam', 'study', 'ilm', 'become a scholar'],
    '"Seeking knowledge is an obligation upon every Muslim." (Sunan '
    'Ibn Majah 224 - the chain is debated, but the meaning is '
    'carried by the whole religion). The best of you, said the '
    'Prophet, are those who learn the Qur\'an and teach it. (Sahih '
    'al-Bukhari 5027). Ten minutes daily outlasts a weekend of '
    'regret.',
  ),
  _Entry(
    <String>['plant a tree', 'small deeds', 'tiny good deed', 'good deeds small'],
    '"If a Muslim plants a tree, or sows a crop, and a bird or a '
    'person or an animal eats of it, it is counted as charity for '
    'him." (Sahih al-Bukhari 2320). And the man who gave a thirsty '
    'dog water - Allah thanked him and forgave him. (Bukhari 3467) '
    'No good deed is too small for His scale.',
  ),
  _Entry(
    <String>['names on the day of judgment', 'resurrection names', 'called by name', 'name on judgment day'],
    'The Prophet said: "You will be called on the Day of '
    'Resurrection by your names and the names of your fathers, so '
    'make your names beautiful." (Sunan Abu Dawood 4948) - a name '
    'carried with goodness becomes a light.',
  ),
  _Entry(
    <String>['sick suffering', 'going through hardship', 'why me', 'afflicted', 'trials'],
    'The Prophet said: "When Allah wills good for a slave, He '
    'afflicts him." (Sahih al-Bukhari 5645) - and "No fatigue, '
    'illness, anxiety, sorrow, harm or sadness touches a Muslim, '
    'even a thorn, but Allah expiates by it." (Bukhari 5641). The '
    'pain you did not choose becomes the expiation you did not '
    'earn.',
  ),
  // ── Home, travel, and daily moments ─────────────────────────────────
  _Entry(
    <String>['leaving home', 'entering home', 'go out', 'come back home', 'exit the house'],
    'Leaving home: "Bismillahi, tawakkaltu \'alallah, la hawla wa la '
    'quwwata illa billah" - In Allah\'s name, I trust in Allah; there '
    'is no might nor power except with Allah - it is said to you: you '
    'are guided, sufficed, and protected. (Sunan Abu Dawood 5095). '
    'Entering home: greet with salam, say "Bismillah" as you enter, '
    'and "Allahumma inni as\'aluka khayral mawla...". (Muslim 2018)',
  ),
  _Entry(
    <String>['travel dua', 'going on a trip', 'road trip dua', 'flying dua', 'journey dua', 'travel', 'trip'],
    'Before and during travel: "Subhanalladhi sakhkhara lana hadha '
    'wa ma kunna lahu muqrinin, wa inna ila rabbina lamunqalibun" - '
    'Glory to Him who subjected this to us, and we could never have '
    'accomplished it ourselves - and indeed, to our Lord we will '
    'return. (Sahih Muslim 1342). Shorten the four-unit prayers when '
    'you travel beyond the city.',
  ),
  _Entry(
    <String>['sneezing', 'sneeze', 'alhamdulillah sneeze', 'bless sneeze'],
    'When someone sneezes and praises Allah ("Alhamdulillah"), say '
    '"Yarhamukumullah" - may Allah have mercy on you. The sneezer '
    'replies "Yahdikumullah..." (Sahih al-Bukhari 6224). A learned '
    'custom: sneeze in privacy, praise Allah, and be answered with '
    'mercy.',
  ),
  _Entry(
    <String>['dream interpretation', 'had a dream', 'strange dream', 'bad dream', 'nightmare', 'dream'],
    'The Prophet taught: the righteous dream is from Allah - '
    'thank Him and tell whom you love; the distressing dream is '
    'from shaytan - seek refuge in Allah from its evil, do not '
    'narrate it, and it will not harm you. Spit lightly to your '
    'left three times. (Sahih al-Bukhari 3292). Not every dream '
    'carries a meaning - most are what the daytime leaves behind.',
  ),
  _Entry(
    <String>['evil eye', 'hasad', 'envy', 'someone envied me', 'nazr', 'ruqyah', 'protect my children'],
    'The Prophet said: "The evil eye is real and can put a man in '
    'the grave and a camel into the cooking pot." (Sahih Muslim 2188). '
    'The shield: Ayat al-Kursi, the three Quls said morning and '
    'evening, and "la ilaha illallah wahdahu la sharika lah..." for '
    'one hundred mornings. For ruqyah, the greatest of it is '
    'Al-Fatiha - the Prophet once healed a tribesman with it and '
    'was paid thirty sheep. (Bukhari 5748)',
  ),

  // ── Family milestones ───────────────────────────────────────────────
  _Entry(
    <String>['marriage proposal', 'getting married', 'choosing spouse', 'marry someone', 'marriage advice', 'marry', 'marriage'],
    'The Prophet\'s counsel: "When someone whose religion and '
    'character pleases you proposes to you, then marry him. If you '
    'do not, there will be corruption in the land and widespread '
    'evil." (Jami\' at-Tirmidhi 1085). Religion first - beauty and '
    'wealth open like flowers and close like them; faith is the '
    'root that stays.',
  ),
  _Entry(
    <String>['wedding dua', 'nikkah dua', 'just married', 'newlywed'],
    'The blessed wedding du\'a: "Barakallahu laka wa baraka '
    '\'alaika wa jama\'a bainakuma fi khayr" - May Allah bless '
    'you, shower blessings upon you, and join you both in goodness. '
    '(Sunan Abu Dawood 2130). And the house of the newlyweds is '
    'built upon five: gratitude, gentleness, patience, honesty, '
    'and prayer together.',
  ),
  _Entry(
    <String>['new baby', 'newborn', 'baby born', 'child born', 'aqiqah', 'tahnik', 'baby'],
    'For the newborn: give the adhan in the right ear and the iqamah '
    'in the left - the first voice it hears is the call to Allah. '
    '(Sunan Abu Dawood 5105). Tahnik: a softened date on the palate, '
    'and pray for the child. (Sahih al-Bukhari 5469). And the '
    'aqiqah: "Every child is pledged to its aqiqah" - an animal '
    'sacrificed on the seventh day, its weight in silver given as '
    'charity, and the child named. (Tirmidhi 1513)',
  ),
  _Entry(
    <String>['children', 'raising kids', 'my child', 'teaching children', 'kids behavior'],
    '"Every child is born upon the fitrah - the natural readiness '
    'for Islam; its parents make it a Jew, a Christian, or a '
    'Persian." (Sahih al-Bukhari 1385). Be the first kindness they '
    'know: the Prophet carried children, shortened the prayer when '
    'he heard a baby cry, and said: "He is not of us who does not '
    'have mercy on our young." (Tirmidhi 1919)',
  ),

  // ── Friday, Eid, and the rhythm of the week ─────────────────────────
  _Entry(
    <String>['friday', 'jumuah', 'jumma', 'surah kahf', 'best hour friday'],
    'Friday: purify and adorn, go early to the masjid, and leave '
    'trading aside when the call is made - "And when the prayer is '
    'concluded, disperse within the land and seek the bounty of '
    'Allah" (Al-Jumuah 9-10). The Prophet said Friday has an hour in '
    'which no Muslim happens to ask Allah for good but that He gives '
    'it - and it is believed to be the last hour after Asr. (Sahih '
    'al-Bukhari 935). Recite Surah al-Kahf: "a light between this '
    'Friday and the next." (Tirmidhi 2810)',
  ),
  _Entry(
    <String>['eid', 'eid dua', 'eid mubarak', 'eid salah'],
    'The Prophet said: "Every nation has its festival, and this is '
    'ours" - take a different route going and returning, praise '
    'Allah on the way, and embrace. (Sahih al-Bukhari 952). The '
    'takbeer: "Allahu Akbar, Allahu Akbar, la ilaha illallah, '
    'wallahu Akbar, Allahu Akbar wa lillahil hamd" - aloud on the '
    'roads, softly in the heart.',
  ),
  _Entry(
    <String>['fasting shawwal', 'six days of shawwal', 'monday fasting', 'thursday fasting', 'white days', 'extra fasts', 'fast the year'],
    'Beyond Ramadan: fasting Ramadan then six days of Shawwal "is '
    'like fasting the whole year" (Sahih Muslim 1164). The Prophet '
    'fasted Mondays and Thursdays - deeds are presented on those '
    'days (Jami\' at-Tirmidhi 747) - and the three white days, the '
    '13th, 14th, and 15th of the lunar month (Tirmidhi 762). The '
    'most beloved fast to Allah is Dawud\'s: a day on, a day off. '
    '(Sahih al-Bukhari 3420)',
  ),
  _Entry(
    <String>['suhoor', 'sehri', 'pre-dawn meal'],
    '"Take suhoor, for in suhoor there is blessing." (Sahih '
    'al-Bukhari 1923). Delay it toward dawn; the Prophet said the '
    'difference between our fasting and the fasting of the People '
    'of the Book is the pre-dawn meal. (Muslim 1096). Even dates '
    'and water carry the barakah.',
  ),
  _Entry(
    <String>['itikaf', 'spiritual retreat', 'last ten nights'],
    'I\'tikaf - secluding oneself in the masjid for worship - was '
    'practiced by the Prophet every Ramadan, ten nights, and in the '
    'year he passed away, twenty. (Sahih al-Bukhari 2025). The '
    'minimum is a moment of intention in the masjid; the essence is '
    'to leave the world at the door and keep only conversation with '
    'Allah.',
  ),
  _Entry(
    <String>['feed a fasting person', 'feeding iftar', 'iftar for someone', 'feed'],
    '"Whoever provides the food for a fasting person to break his '
    'fast earns the same reward as his, without the fasting '
    'person\'s reward being diminished in any way." (Jami\' '
    'at-Tirmidhi 807). A date and a glass of milk suffice - and the '
    'angels make du\'a for the giver all that evening.',
  ),

  // ── Weather, seasons, and the sky ───────────────────────────────────
  _Entry(
    <String>['rain dua', 'it\'s raining', 'rain blessing', 'rain shower', 'rain'],
    'When the rain falls: "Allahumma sayyiban nafi\'an" - O Allah, '
    'make it a beneficial rain. (Sahih al-Bukhari 1032). And the '
    'downpour is an hour of answer: "Two are not rejected - the '
    'du\'a at the time of rain and the du\'a of the oppressed." '
    '(Abu Dawood 2540, Ibn Majah 3878). Expose some of it to the '
    'rain - it has newly come from its Lord.',
  ),
  _Entry(
    <String>['wind dua', 'storm dua', 'strong wind', 'thunder dua', 'lightning', 'wind', 'storm'],
    'For the wind: "Allahumma inni as\'aluka khayraha, wa khayra '
    'ma fiiha, wa khayra ma ursilat bihi, wa a\'udhu bika min '
    'sharriha..." - O Allah, I ask You for its good, the good in '
    'it, the good it was sent with, and I seek refuge in You from '
    'its evil. (Sahih Muslim 899). The thunder glorifies the praise '
    'of its Lord - say Subhan Allah as it rolls. (Musnad Ahmad)',
  ),
  _Entry(
    <String>['new moon', 'crescent moon', 'moon sighting', 'hilal', 'moon'],
    'Seeing the new crescent: "Allahumma ahillahu \'alaina bil '
    'amni wal iman, was-salamati wal islam..." - O Allah, let this '
    'moon rise over us with security, faith, safety, and Islam. '
    '(Sahih Muslim 1742). The sighting ties the ummah to the sky - '
    'the month begins when the crescent is seen, not when the '
    'calendar guesses.',
  ),

  // ── Earnings, trade, and the table ──────────────────────────────────
  _Entry(
    <String>['halal income', 'halal earnings', 'haram money', 'riba', 'interest', 'halal work', 'halal', 'haram'],
    '"O people, Allah is Pure and accepts only what is pure - He '
    'commands the believers as He commanded the messengers: eat of '
    'the good and do righteous work." (Sahih Muslim 1015). '
    'Earnings built on riba are fought by the Prophet himself: he '
    'cursed the one who consumes riba, the one who gives it, the '
    'one who records it, and its two witnesses - "they are alike." '
    '(Muslim 1598). Trade is blessed; the Prophet was a merchant '
    'and praised the honest trader.',
  ),
  _Entry(
    <String>['gambling', 'lottery', 'betting', 'casino', 'poker'],
    '"O you who believe, intoxicants, gambling, idols, and divining '
    'arrows are but filth of Satan\'s handiwork - avoid it that '
    'you may succeed. Satan only intends to cause enmity and hatred '
    'between you through it and to bar you from the remembrance of '
    'Allah and from prayer." (Al-Ma\'idah 90-91). The money of '
    'gambling is built on taking without consent - the blessed '
    'exit door is always open.',
  ),
  _Entry(
    <String>['alcohol', 'drinking', 'wine', 'beer', 'intoxicants'],
    '"Every intoxicant is khamr, and every khamr is unlawful." '
    '(Sahih Muslim 2003) - and prayer is not accepted from one who '
    'is intoxicated for forty days if he does not repent. (Tirmidhi '
    '3773). What poisons the mind is barred from the body, '
    'whatever shape the bottle takes.',
  ),
  _Entry(
    <String>['eating manners', 'right hand eating', 'wash hands eating', 'table manners islam', 'eat', 'eating'],
    'The Sunnah of the table: mention Allah\'s name, eat with the '
    'right hand, and eat from what is nearest - "If he forgets to '
    'mention Allah, let him say: Bismillahi awwalahu wa akhirahu." '
    '(Sahih Muslim 2017, 2020). Wash the hands before and after '
    'eating, for blessing descends when the hands are washed. '
    '(Sunan Abu Dawood 3755). Sit together - the shared meal is '
    'mercy and separation is from the shaytan. (Abu Dawood 3764)',
  ),
  _Entry(
    <String>['miswak', 'tooth stick', 'brush teeth sunnah'],
    '"Were it not that I might overburden my ummah, I would have '
    'commanded them to use the miswak before every prayer." '
    '(Sahih al-Bukhari 887). The Prophet cleaned his teeth at '
    'wudu, before prayer, before reciting, on waking - a different '
    'part of worship than fresh breath alone.',
  ),

  // ── Prophetic medicine and creatures ────────────────────────────────
  _Entry(
    <String>['honey', 'black seed', 'tibben nabawi', 'prophetic medicine', 'natural remedy'],
    'From the Sunnah of healing: honey - "healing for the people" '
    '(An-Nahl 69), and the Prophet said healing is in three: the '
    'cut of the cupper, a drink of honey, and cauterization with '
    'fire - but he forbade his ummah cauterization. (Sahih '
    'al-Bukhari 5356). And black seed: "the healing for every '
    'disease except death" (Bukhari 5688). Medicine of the body '
    'and the ruqyah of the heart travel together.',
  ),
  _Entry(
    <String>['zamzam', 'drinking zamzam', 'umrah zamzam'],
    '"The water of Zamzam is for whatever it is drunk for" - drink '
    'it with an intention: knowledge, healing, forgiveness, a '
    'righteous child. (Sunan Ibn Majah 3062). It sprang for Ismail '
    'in the desert of Makkah and has not ceased - five thousand '
    'years of answered thirst.',
  ),
  _Entry(
    <String>['cupping', 'hijamah', 'blood cupping'],
    'The Prophet praised cupping: "The best of your treatments is '
    'hijamah" - and had it done on the veins at the back of his '
    'neck, paying the cupper his wage. (Jami\' at-Tirmidhi 1190). '
    'Even treatment has an etiquette: seek the skilled, pay '
    'fairly, and pair it with du\'a.',
  ),
  _Entry(
    <String>['cats', 'kittens', 'pet cat'],
    'Kindness to cats is from the Sunnah: a cat once slept on the '
    'Prophet\'s cloak; he cut the sleeve off rather than wake it '
    'when he stood for prayer - and he used its water for wudu. '
    'Cats are not impure, he said; they are among those who go '
    'about among you. (Jami\' at-Tirmidhi 91). Muezza, they say, '
    'was the name of his own.',
  ),

  // ── Sleep, waking, and the night ────────────────────────────────────
  _Entry(
    <String>['sleep dua', 'going to sleep', 'bedtime', 'sleep on right side', 'wake up dua', 'waking up', 'sleep'],
    'Before sleep: wudu as you washed for prayer, lie on the right '
    'side, and recite Ayat al-Kursi - "a protector from Allah is '
    'appointed over you, and no devil comes near you until '
    'morning." (Sahih al-Bukhari 2311). Dust the bedding three '
    'times - "for you do not know what came to rest upon it." '
    '(Bukhari 6320). Waking: "Alhamdulillahilladhi ahyana ba\'da '
    'ma amatana wa ilaihin nushur" - all praise to Allah who gave '
    'us life after death, and to Him is the resurrection. (Bukhari '
    '6312)',
  ),
  _Entry(
    <String>['seeing someone sick', 'someone else afflicted', 'heard bad news'],
    'When you see someone afflicted: "Alhamdulillahil-ladhi '
    '\'afani mimabtalaaka bihi wa faddalani \'ala kathirin mimman '
    'khalaqa tafdila" - praise to Allah who spared me what He '
    'afflicted you with and favored me over much of His creation. '
    '(Jami\' at-Tirmidhi 3433). Gratitude without the afflicted '
    'hearing it; the reward and the mercy both remain.',
  ),

  // ── Hard moments, held gently ───────────────────────────────────────
  _Entry(
    <String>['someone died', 'death of a loved one', 'lost my mother', 'lost my father', 'grief', 'mourning', 'funeral', 'visiting graves', 'passed away', 'died', 'lost'],
    'When death takes someone you love: "Inna lillahi wa inna '
    'ilaihi raji\'un - Allahumma\'jurni fi musibati wakhluf li '
    'khayran minha" - To Allah we belong and to Him we return; O '
    'Allah, reward me in my calamity and replace it for me with '
    'better. (Sahih Muslim 918). The Prophet said: "Allah says to '
    'the angels: build for My servant a palace in Paradise and '
    'call it the House of Praise." For the deceased: wash, shroud, '
    'pray over, and bury - attending carries the reward of two '
    'great qirats. (Bukhari 1325) And visit the graves - "they '
    'remind you of the Hereafter" (Muslim 977). Say to the '
    'grieving: "May Allah magnify your reward, beautify your '
    'patience, and forgive your departed."',
  ),
  _Entry(
    <String>['trust in allah', 'tawakkul', 'my rizq', 'provision', 'how will i survive', 'jobless', 'no money', 'money'],
    'The Prophet said: "If you relied upon Allah as He should be '
    'relied upon, He would provide for you as He provides for the '
    'birds - they leave in the morning with empty stomachs and '
    'return full." (Jami\' at-Tirmidhi 2344). And: "Tie your '
    'camel, then trust in Allah." (Tirmidhi 2517). Tawakkul is '
    'not the abandonment of means - it is the heart\'s grip on '
    'Allah while the hand grips the rope. Rizq was written when '
    'you were sixty days in the womb; what is yours will walk to '
    'you.',
  ),
  _Entry(
    <String>['hurt myself', 'want to die', 'end my life', 'no point living', 'self harm', 'suicidal', 'don\'t want to live', 'kill myself', 'no will to live'],
    'Please - stop, and breathe. Your pain is real, and so is '
    'Allah\'s promise: "Allah does not burden a soul beyond what '
    'it can bear" (Al-Baqarah 286), and "Despair not of the mercy '
    'of Allah" (Az-Zumar 53). This world can hurt unbearably, but '
    'the Prophet said: "No fatigue, nor illness, nor anxiety, nor '
    'sorrow, nor harm reaches a Muslim but that Allah expiates by '
    'it - even a thorn." (Sahih al-Bukhari 5641). You are not '
    'alone: the Prayer Times screen can connect you to a human '
    'near you, and Sakina is open whenever the night is heavy. '
    'Stay - the One who made you is not done with you.',
  ),
  _Entry(
    <String>['hijab', 'covering', 'modesty dress', 'why do muslim women cover'],
    'Allah says: "And tell the believing women to lower their gaze '
    'and guard their private parts and not expose their adornment '
    'except that which appears thereof, and to draw their coverings '
    'over their chests..." (An-Nur 31), and: "O Prophet, tell your '
    'wives and daughters and the women of the believers to draw '
    'their outer garments over themselves." (Al-Ahzab 59). The '
    'Prophet said that when a woman reaches menstruation, nothing '
    'should be seen of her but this and this - and he pointed to '
    'the face and hands. (Abu Dawood 4104) It is worship, '
    'obedience, and - for many who wear it - peace.',
  ),

  // ── Learning the Qur'an and Arabic ──────────────────────────────────
  _Entry(
    <String>['memorize quran', 'hifz', 'memorization tips', 'learn quran', 'quran study tips', 'memorize'],
    'The memorizer\'s method, unchanged for a thousand years: a '
    'daily portion - new and revision - with recitation to a '
    'teacher who corrects. Ibn al-Jazari said: "Committing to what '
    'you can bear - even a little - is better than burning out on '
    'a lot." Recite in the same copy, at the same hour, and '
    'listen to one reciter only until the passage settles. The '
    'promise is sealed in the hadith: "The best of you are those '
    'who learn the Qur\'an and teach it." (Sahih al-Bukhari 5027)',
  ),
  _Entry(
    <String>['tajweed', 'pronunciation quran', 'recitation rules', 'makhraj'],
    'Tajweed is giving every letter its right: from its makhraj - '
    'its exit point - and with its sifah - its characteristics - '
    'slowly, without artificiality. The Prophet listened to Ibn '
    'Umar\'s recitation for a long while and said: "Have mercy on '
    'yourself" - beautiful, unhurried recitation is loved. (Abu '
    'Dawood 802) Begin with one surah perfected; the Qur\'an '
    'itself teaches: "And recite the Qur\'an with measured '
    'recitation." (Al-Muzzammil 4)',
  ),
  _Entry(
    <String>['learn arabic', 'arabic alphabet', 'arabic learning tips', 'arabic'],
    'The alphabet is a door, not a mountain: twenty-nine letters, '
    'each with a shape at the start, middle, and end of a word. '
    'The Wasia Academy in this app walks children through every '
    'letter with sound and practice - and what works for them '
    'works for you: one letter a day, said aloud, written twice, '
    'found in a word you already know. Ten weeks of one letter a '
    'day, and the script that carried the revelation is yours.',
  ),
];
