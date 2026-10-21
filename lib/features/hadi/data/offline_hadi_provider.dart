import '../../sakina/domain/crisis_detector.dart';
import '../application/hadi_provider.dart';

/// Curated knowledge for offline use — always available, no key, no
/// network. Unknown questions get an honest decline — Hādi never invents.
///
/// Matching is by WHOLE WORDS and whole phrases on normalised text, with a
/// light plural/"-ing" stem: "fasting" finds "fast", but "breakfast" never
/// finds "fast", "business" never finds "sin", "they" never finds "hey",
/// and "beats" never finds "eat".
class OfflineHadiProvider implements HadiProvider {
  const OfflineHadiProvider();

  static const String decline =
      'I don\'t have enough authentic knowledge to answer that with '
      'certainty, and I would rather not guess. For guided learning I '
      'recommend Shaykh Muhammad Saqib Iqbal\'s channel (linked in Our '
      'Sources), or a qualified local scholar. Add a free API key in Hādi '
      'settings and I can reason further.';

  /// For "is X halal / allowed?" questions the shelf has no entry for.
  static const String rulingDecline =
      'I do not have a verified answer on whether that specific thing is '
      'permitted, and a ruling depends on the details and on the school you '
      'follow, so I would rather not guess. Please ask a qualified scholar: '
      'Shaykh Muhammad Saqib Iqbal\'s channel (linked in Our Sources), or '
      'your local masjid.';

  /// Added to an answer to a ruling-shaped question.
  static const String rulingNote =
      'This is a general answer. Rulings can differ between schools and '
      'depend on the details of your situation, so for your own case please '
      'ask a qualified scholar.';

  /// Words that make a question ask for a ruling.
  static const Set<String> _rulingWords = <String>{
    'halal',
    'haram',
    'permissible',
    'allowed',
    'forbidden',
    'lawful',
    'makruh',
    'sinful',
    'fatwa',
    'ruling',
  };

  /// Stem: drops a plural "s" and "-ing". Applied equally to questions and
  /// keywords, so only the same word (in either form) can match.
  static String _stem(String w) {
    if (w.length > 5 && w.endsWith('ing')) return w.substring(0, w.length - 3);
    if (w.length > 3 &&
        w.endsWith('s') &&
        !w.endsWith('ss') &&
        !w.endsWith('us') &&
        !w.endsWith('is')) {
      return w.substring(0, w.length - 1);
    }
    return w;
  }

  /// Normalised, stemmed words of [s] ("du'a" -> ["dua"]).
  static List<String> tokens(String s) {
    final String norm = CrisisDetector.normalize(s);
    if (norm.isEmpty) return const <String>[];
    return <String>[for (final String w in norm.split(' ')) _stem(w)];
  }

  static bool _containsRun(List<String> haystack, List<String> needle) {
    if (needle.isEmpty || needle.length > haystack.length) return false;
    for (int i = 0; i + needle.length <= haystack.length; i++) {
      bool same = true;
      for (int j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) {
          same = false;
          break;
        }
      }
      if (same) return true;
    }
    return false;
  }

  static final List<_IndexedEntry> _index = <_IndexedEntry>[
    for (final _Entry e in _knowledge)
      _IndexedEntry(
        <List<String>>[
          for (final String k in e.keywords)
            if (tokens(k).isNotEmpty) tokens(k),
        ],
        e.answer,
      ),
  ];

  /// How well [entry] fits the question words: the summed length of every
  /// keyword phrase found as whole words, plus a little for each extra word
  /// of a phrase (a phrase is more specific than a word). Also reports which
  /// keyword phrases were found.
  static _Hit _score(_IndexedEntry entry, List<String> q) {
    int score = 0;
    final Set<String> found = <String>{};
    for (final List<String> k in entry.keys) {
      if (_containsRun(q, k)) {
        int len = 0;
        for (final String w in k) {
          len += w.length;
        }
        score += len + 3 * (k.length - 1);
        found.add(k.join(' '));
      }
    }
    return _Hit(score, found);
  }

  @override
  Future<String> ask(String question, List<HadiMessage> history) async {
    // Defence in depth: the controller screens for crisis first, but this
    // provider must never answer a crisis message from the shelf either.
    final CrisisKind? crisis = CrisisDetector.detect(question);
    if (crisis != null) return CrisisResponses.textFor(crisis);

    final List<String> q = tokens(question);
    final bool rulingShaped = q.any(_rulingWords.contains);
    int bestScore = 0;
    int secondScore = 0;
    String bestAnswer = '';
    String secondAnswer = '';
    Set<String> bestFound = <String>{};
    Set<String> secondFound = <String>{};
    for (final _IndexedEntry e in _index) {
      final _Hit hit = _score(e, q);
      if (hit.score == 0) continue;
      if (hit.score > bestScore) {
        secondScore = bestScore;
        secondAnswer = bestAnswer;
        secondFound = bestFound;
        bestScore = hit.score;
        bestAnswer = e.answer;
        bestFound = hit.found;
      } else if (hit.score > secondScore && e.answer != bestAnswer) {
        secondScore = hit.score;
        secondAnswer = e.answer;
        secondFound = hit.found;
      }
    }
    // Nothing found, or only a tiny word inside a long question (a weak,
    // probably accidental match): decline honestly.
    if (bestScore == 0 || (bestScore < 5 && q.length > 5)) {
      return rulingShaped ? rulingDecline : decline;
    }
    String answer = bestAnswer;
    // Near-tie: two plausible readings and the winner is weak — say so
    // honestly instead of answering with false confidence. Two entries that
    // matched on the very same words are one topic, not an ambiguity.
    final bool sameWords = secondFound.every(bestFound.contains);
    if (secondScore > 0 &&
        secondScore * 2 > bestScore &&
        bestScore < 10 &&
        secondAnswer != bestAnswer &&
        !sameWords) {
      answer = 'Perhaps you meant this?\n\n$bestAnswer\n\n'
          'If I read your question wrong, rephrase it and I will try again.';
    }
    if (rulingShaped && !answer.contains('qualified scholar')) {
      answer = '$answer\n\n$rulingNote';
    }
    return answer;
  }
}

class _Hit {
  const _Hit(this.score, this.found);
  final int score;
  final Set<String> found;
}

class _IndexedEntry {
  const _IndexedEntry(this.keys, this.answer);
  final List<List<String>> keys;
  final String answer;
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
    <String>['anxiety', 'anxious', 'worry', 'worried', 'stress', 'grief', 'dua for anxiety', 'dua for worry', 'dua for stress'],
    'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ — “O Allah, I '
    'seek refuge in You from worry and grief, from incapacity and '
    'laziness, from cowardice and miserliness, from the burden of debt '
    'and from being overpowered by men.” (Sahih al-Bukhari 6369). '
    'You will also find it in your Morning Adhkar set.',
  ),
  _Entry(
    <String>['witr'],
    'Witr is prayed after ‘Isha until Fajr, as an odd number of rak\'ahs — '
    'most simply one: the night prayer is two by two, and if dawn is near, '
    'one rak\'ah makes it witr (Sahih al-Bukhari 990). The Prophet ﷺ said '
    'Allah is single (witr) and loves what is single, and told the people '
    'of the Qur\'an to pray witr '
    '(Sunan Abi Dawud 1416, sahih per al-Albani). He also taught al-Hasan ibn Ali a Qunut supplication for '
    'Witr that begins “Allahumma ihdini fiman hadayt…” (Sunan Abi Dawud '
    '1425, sahih per al-Albani). That report does not say whether it is '
    'said before or after ruku‘: ask a scholar of your madhhab.',
  ),
  _Entry(
    <String>['morning adhkar', 'adhkar', 'dhikr', 'remembrance'],
    'Your Dhikr & Du\'a screen holds the morning, evening, and '
    'after-prayer sets from Hisn al-Muslim with meanings. One report: '
    'whoever says a short “In the name of Allah…” formula three times in '
    'the morning is protected from sudden calamity until evening, and three '
    'times in the evening until morning '
    '(Sunan Abi Dawud 5088, sahih per al-Albani). Open it from Home and tap the counters as you recite.',
  ),
  _Entry(
    <String>['ramadan', 'fasting', 'fast', 'sawm', 'siyam', 'roza', 'suhoor', 'iftar'],
    'Fasting Ramadan is the fourth pillar of Islam (Qur\'an 2:183-185). '
    '“Whoever fasts Ramadan out of faith and hope for reward, his past '
    'sins are forgiven.” (Sahih al-Bukhari 38). Take suhoor — “in suhoor '
    'there is blessing” (Bukhari 1923) — and check the Islamic Calendar '
    'screen for this year\'s dates.',
  ),
  _Entry(
    <String>['zakat', 'charity', 'sadaqah', 'almsgiving'],
    'Zakat is the third pillar — 2.5% of qualifying wealth held a lunar '
    'year above the nisab. The Prophet ﷺ told Mu\'adh, when sending him '
    'to Yemen, that Allah has made charity obligatory on their wealth, '
    'taken from the rich and given to the poor (Sahih al-Bukhari 1395). '
    'The Zakat screen in Ar-Rayaan calculates it for '
    'you step by step.',
  ),
  _Entry(
    <String>['prayer time', 'prayer times', 'salah times', 'namaz time'],
    'Your Prayer Times screen calculates today\'s schedule right on your '
    'device — tap GPS or choose your city, and turn on the bell next to '
    'any prayer to be alerted when its time arrives.',
  ),
  _Entry(
    <String>['how do i pray', 'how to pray', 'salah', 'salaat', 'namaz', 'pray witr'],
    'Prayer is the second pillar. “Pray as you have seen me pray.” '
    '(Sahih al-Bukhari 631). Five daily prayers are obligatory; the '
    'Prophet\'s ﷺ complete method is recorded across the six books — '
    'Shaykh Saqib Iqbal\'s channel (in Our Sources) walks through it '
    'beautifully, step by step.',
  ),
  _Entry(
    <String>['quran', 'qur\'an', 'koran', 'recite', 'recitation'],
    'The Qur\'an screen holds all 114 surahs — tap any ayah to hear '
    'recitation by Shaykh Mishary Rashid Alafasy. “The best of you are '
    'those who learn the Qur\'an and teach it.” (Sahih al-Bukhari 5027).',
  ),
  _Entry(
    <String>['du\'a', 'dua', 'supplication'],
    'Du\'a is worship itself (Jami\' at-Tirmidhi 3372, sahih per Darussalam). For a need, '
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
    'Allah says: “do not despair of the mercy of Allah. Indeed, Allah '
    'forgives all sins.” (Qur\'an 39:53). The Prophet ﷺ said: “Every son of Adam '
    'sins, and the best of sinners are those who repent.” (Jami\' '
    'at-Tirmidhi 2499, weak per Darussalam). The door is open — walk through it.',
  ),
  _Entry(
    <String>['mother', 'father', 'parents'],
    'A man asked to go out and fight; the Prophet ﷺ said: “Then stay with '
    'her, for Paradise is beneath her feet.” (Sunan an-Nasa\'i 3104, '
    'sahih per Darussalam). The Prophet ﷺ was asked who most deserves good '
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
    <String>['shahada', 'shahadah', 'kalima', 'testimony', 'declaration of faith'],
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
    'destroyer of pleasures - death." (Jami\' at-Tirmidhi 2307, hasan per Darussalam). '
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
    'Before eating: "Bismillah" - and if you forget at the start, say '
    '"Bismillahi awwalahu wa akhirahu" '
    '(Sunan Abi Dawud 3767, sahih per al-Albani). After eating, the Prophet ﷺ is reported to have said: '
    '"Alhamdulillahilladhi at\'amana wa saqana wa ja\'alana muslimin" - '
    'all praise to Allah who fed us, gave us drink, and made us Muslims '
    '(Sunan Abi Dawud 3850; sunnah.com shows al-Albani\'s grade as da\'if '
    '(weak), so hold it as a reported wording, not a firm Sunnah).',
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
    'For pain: place your hand on the spot that hurts, say "Bismillah" '
    'three times, then seven times seek refuge in Allah and His power from '
    'the harm you feel and fear (Sahih Muslim 2202). When visiting a sick '
    'person whose time has not yet come, say seven times a supplication '
    'asking Allah the Mighty, Lord of the Mighty Throne, to cure him '
    '(Sunan Abi Dawud 3106, sahih per al-Albani). The one who visits a '
    'sick person is, in the Prophet\'s words, in the fruit garden of '
    'Paradise until he returns (Sahih Muslim 2568).',
  ),

  // ── Character and heart ─────────────────────────────────────────────
  _Entry(
    <String>['anxious', 'anxiety', 'worried', 'worry', 'depressed', 'overwhelmed', 'scared', 'afraid'],
    'For a heavy heart: "Hasbunallahu wa ni\'mal wakeel" - Allah is '
    'sufficient for us, and He is the best Disposer of affairs '
    '(Al-Imran 173) - the words of Ibrahim and our Prophet in '
    'distress. And when something distressed him, the Prophet (peace be upon him) '
    'would say: "Ya Hayyu ya Qayyum, bi-rahmatika astagheeth." '
    '(Jami\' at-Tirmidhi 3524, hasan per Darussalam). '
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
    'to you." (Jami\' at-Tirmidhi 1924, hasan per Darussalam). "He who does not show mercy '
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
    'the path is charity." (Jami\' at-Tirmidhi 1956, hasan per Darussalam). The zakat '
    'calculator in this app handles the obligatory share; beyond it, '
    '"protect yourselves from the Fire even with half a date" '
    '(Sahih al-Bukhari 1417).',
  ),
  _Entry(
    <String>['tawbah', 'repent', 'repentance', 'forgiveness', 'forgive me', 'sinned'],
    'Allah says: "do not despair of the mercy of Allah. Indeed, Allah '
    'forgives all sins." (Az-Zumar 53). The Prophet said: "By the One '
    'in Whose hand is my soul, if you did not sin, Allah would '
    'replace you with people who sin and seek forgiveness - and He '
    'would forgive them." (Sahih Muslim 2749). Repentance: leave the '
    'sin, regret it, resolve not to return - and restore rights if '
    'anyone was wronged.',
  ),
  _Entry(
    <String>['hajj', 'pilgrimage', 'makkah trip'],
    'Hajj, the fifth pillar, is owed once in a lifetime by whoever '
    'can find a way: "And [due] to Allah from the people is a pilgrimage '
    'to the House - for whoever is able to find thereto a way" (Al-'
    'Imran 97). "An accepted Hajj has no reward but Paradise." '
    '(Sahih al-Bukhari 1773). Its rites gather at the Ka\'bah, '
    'Arafat, Muzdalifah, and Mina across Dhul-Hijjah.',
  ),
  _Entry(
    <String>['umrah', 'minor pilgrimage', 'omra'],
    'Umrah is the shorter pilgrimage, performable any time of year: '
    'ihram, tawaf of the Ka\'bah, sa\'i between Safa and Marwah, '
    'and shaving or shortening the hair. The Prophet ﷺ told a woman who '
    'had missed the Hajj to perform Umrah in Ramadan, because an Umrah in '
    'Ramadan carries the reward of Hajj (Sahih al-Bukhari 1782).',
  ),
  _Entry(
    <String>['tahajjud', 'night prayer', 'qiyam', 'pray at night'],
    '"The best prayer after the obligatory prayers is the night '
    'prayer." (Sahih Muslim 1163). Tahajjud is prayed after sleeping '
    'a portion of the night, in units of two: "They arise from [their] '
    'beds; they supplicate their Lord in fear and aspiration" (As-Sajdah '
    '16). Start with two rak\'ah before Fajr; Allah descends to the '
    'lowest heaven asking who is calling upon Him. (Bukhari 1145)',
  ),
  _Entry(
    <String>['istikhara', 'decision dua', 'should i do', 'big decision', 'choice dua'],
    'For any matter - marriage, a job, a move - pray two units of '
    'non-obligatory prayer, then the du\'a of istikhara taught by '
    'the Prophet himself: "Allahumma inni astakhiruka bi-\'ilmik..." '
    '- O Allah, I seek Your choice by Your knowledge... Then go ahead '
    'with what you decide and rely on Allah. The Prophet ﷺ taught the '
    'istikhara to his companions as he taught them a surah of the '
    'Qur\'an, saying: "If one of you is concerned about a matter, let '
    'him pray two rak\'ahs other than the obligatory prayer." '
    '(Sahih al-Bukhari 1166)',
  ),
  _Entry(
    <String>['laylatul qadr', 'night of decree', 'qadr', 'best night', 'odd nights'],
    'Laylatul Qadr, in the last ten nights of Ramadan - in the odd '
    'nights, the 21st, 23rd, 25th, 27th, 29th: "Better than a '
    'thousand months" (Al-Qadr 3). The Prophet ﷺ said: "Search for '
    'it in the odd nights of the last ten nights of Ramadan" (Sahih '
    'al-Bukhari 2017). So stand, recite, ask. What would you do with 83 '
    'years of worship in one night?',
  ),
  _Entry(
    <String>['breaking fast', 'iftar dua', 'iftar', 'end of fast'],
    'When breaking the fast, the Prophet ﷺ said: "Dhahaba al-zama\'u '
    'wabtallat al-urooqu wa thabata al-ajru in sha Allah" - The thirst is '
    'gone, the veins are moistened, and the reward is fixed, if Allah '
    'wills. (Sunan Abi Dawud 2357, hasan per al-Albani). The fasting person has a du\'a '
    'at the moment of breaking that is not rejected. (Ibn Majah 1753, hasan per Darussalam)',
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
    'The Prophet ﷺ said you will not enter Paradise until you believe, and '
    'you will not believe until you love one another - and showed the way: '
    'spread the greeting of peace among yourselves (Sahih Muslim 54). Asked '
    'which part of Islam is best, he named feeding people and greeting '
    'those you know and those you do not (Sahih al-Bukhari 28). The '
    'greeting of Islam - "As-salamu alaikum warahmatullah" - carries '
    'three levels: peace, then mercy, then Allah\'s blessings.',
  ),

  // ── Knowledge and daily life ────────────────────────────────────────
  _Entry(
    <String>['seeking knowledge', 'learn islam', 'study', 'ilm', 'become a scholar'],
    '"Seeking knowledge is an obligation upon every Muslim." (Sunan '
    'Ibn Majah 224, very weak per Darussalam - the chain is debated, but the meaning is '
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
    'dog water - Allah accepted the deed and forgave him. (Sahih al-Bukhari 2363) '
    'No good deed is too small for His scale.',
  ),
  _Entry(
    <String>['names on the day of judgment', 'resurrection names', 'called by name', 'name on judgment day'],
    'It is reported that the Prophet said you will be called on the Day '
    'of Resurrection by your names and the names of your fathers, so make '
    'your names beautiful '
    '(Sunan Abi Dawud 4948 - graded da\'if (weak) by al-Albani, so held as a weak report only). A reflection, not a '
    'hadith: a name carried with goodness becomes a light.',
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
    'are guided, sufficed, and protected. '
    '(Sunan Abi Dawud 5095, sahih per al-Albani). Entering home: mention Allah\'s name as you enter '
    '(Sahih Muslim 2018) and give greetings of peace (Qur\'an 24:61).',
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
    'The Prophet taught: the righteous dream is from Allah; the '
    'distressing dream is from shaytan - spit to your left and seek '
    'refuge in Allah from its evil, and it will not harm you (Sahih '
    'al-Bukhari 3292); the report in Sahih Muslim 2261 says to spit '
    'three times. Not every dream '
    'carries a meaning - most are what the daytime leaves behind.',
  ),
  _Entry(
    <String>['evil eye', 'hasad', 'envy', 'someone envied me', 'nazr', 'ruqyah', 'protect my children'],
    'The Prophet ﷺ said the evil eye is real, that if anything could '
    'outrun the decree it would be the evil eye, and that when you are '
    'asked to wash for it, you should wash (Sahih Muslim 2188). Many '
    'Muslims recite Ayat al-Kursi and the three Quls for protection. For '
    'ruqyah, the greatest of it is '
    'Al-Fatiha - a Companion once recited it over a tribal chief who had been bitten, and '
    'the Prophet approved the payment he accepted. (Bukhari 5736)',
  ),

  // ── Family milestones ───────────────────────────────────────────────
  _Entry(
    <String>['marriage proposal', 'getting married', 'choosing spouse', 'marry someone', 'marriage advice', 'marry', 'marriage'],
    'The Prophet\'s counsel: "When someone whose religion and '
    'character pleases you proposes to you, then marry him. If you '
    'do not, there will be corruption in the land and widespread '
    'evil." (Jami\' at-Tirmidhi 1085, weak per Darussalam). Religion first - beauty and '
    'wealth open like flowers and close like them; faith is the '
    'root that stays.',
  ),
  _Entry(
    <String>['wedding dua', 'nikkah dua', 'just married', 'newlywed'],
    'The blessed wedding du\'a: "Barakallahu laka wa baraka '
    '\'alaika wa jama\'a bainakuma fi khayr" - May Allah bless '
    'you, shower blessings upon you, and join you both in goodness. '
    '(Sunan Abi Dawud 2130, sahih per al-Albani). A reflection, not a '
    'hadith: the house of the newlyweds is built upon five - gratitude, '
    'gentleness, patience, honesty, and prayer together.',
  ),
  _Entry(
    <String>['new baby', 'newborn', 'baby born', 'child born', 'aqiqah', 'tahnik', 'baby'],
    'For the newborn: the Prophet ﷺ called the adhan in the ear of '
    'al-Hasan when he was born '
    '(Sunan Abi Dawud 5105, hasan per al-Albani). Tahnik: a softened date on the palate, and pray for the '
    'child. (Sahih al-Bukhari 5469). And the aqiqah: "Every child is '
    'pledged to its aqiqah" - an animal sacrificed on the seventh day, and '
    'the child named. (Tirmidhi 1513, hasan per Darussalam)',
  ),
  _Entry(
    <String>['children', 'raising kids', 'my child', 'teaching children', 'kids behavior'],
    '"Every child is born upon the fitrah - the natural readiness for '
    'Islam; its parents make it a Jew, a Christian, or a Magian '
    '(Zoroastrian)." (Sahih al-Bukhari 1385). Be the first kindness they '
    'know: the Prophet carried children, shortened the prayer when he heard '
    'a baby cry, and said: "He is not of us who does not have mercy on our '
    'young." (Tirmidhi 1919, hasan per Darussalam)',
  ),

  // ── Friday, Eid, and the rhythm of the week ─────────────────────────
  _Entry(
    <String>['friday', 'jumuah', 'jumma', 'surah kahf', 'best hour friday'],
    'Friday: purify and adorn, go early to the masjid, and leave '
    'trading aside when the call is made - "And when the prayer has been '
    'concluded, disperse within the land and seek from the bounty of '
    'Allah" (Al-Jumuah 9-10). The Prophet said Friday has an hour in '
    'which no Muslim happens to ask Allah for good but that He gives '
    'it - and it is believed to be the last hour after Asr. (Sahih '
    'al-Bukhari 935). Reciting Surah al-Kahf on Friday is reported to '
    'bring light (reported; number and grade not verified here).',
  ),
  _Entry(
    <String>['eid', 'eid dua', 'eid mubarak', 'eid salah'],
    'The Prophet said: "Every nation has its festival, and this is '
    'ours" (Sahih al-Bukhari 952). He used to return from the Eid '
    'prayer by a different road from the one he went by (Sahih '
    'al-Bukhari 986). Allah says to complete the fast and glorify Him '
    'for His guidance (Qur\'an 2:185). The '
    'takbeer: "Allahu Akbar, Allahu Akbar, la ilaha illallah, '
    'wallahu Akbar, Allahu Akbar wa lillahil hamd" - aloud on the '
    'roads, softly in the heart.',
  ),
  _Entry(
    <String>['fasting shawwal', 'six days of shawwal', 'monday fasting', 'thursday fasting', 'white days', 'extra fasts', 'fast the year'],
    'Beyond Ramadan: fasting Ramadan then six days of Shawwal "is '
    'like fasting the whole year" (Sahih Muslim 1164). The Prophet '
    'fasted Mondays and Thursdays - deeds are presented on those '
    'days (Jami\' at-Tirmidhi 747, hasan per Darussalam) - and the three white days, the '
    '13th, 14th, and 15th of the lunar month (Abu Dawud 2449, sahih per al-Albani). The '
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
    'practiced by the Prophet every Ramadan, ten days, and in the '
    'year he passed away, twenty (Sahih al-Bukhari 2044). Scholars differ '
    'on its minimum length, so ask a scholar of your madhhab; the essence is '
    'to leave the world at the door and keep only conversation with '
    'Allah.',
  ),
  _Entry(
    <String>['feed a fasting person', 'feeding iftar', 'iftar for someone', 'feed'],
    '"Whoever provides the food for a fasting person to break his '
    'fast earns the same reward as his, without the fasting '
    'person\'s reward being diminished in any way." (Jami\' '
    'at-Tirmidhi 807, sahih per Darussalam). A date and a glass of milk suffice - and the '
    'angels make du\'a for the giver all that evening.',
  ),

  // ── Weather, seasons, and the sky ───────────────────────────────────
  _Entry(
    <String>['rain dua', 'it\'s raining', 'rain blessing', 'rain shower', 'rain'],
    'When the rain falls: "Allahumma sayyiban nafi\'an" - O Allah, '
    'make it a beneficial rain. (Sahih al-Bukhari 1032). Make '
    'du\'a at the time of rain; the specific report that the du\'a '
    'under rain is not rejected is not verified here. Expose some of it to the '
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
    '(Jami\' at-Tirmidhi 3451, weak per Darussalam; at-Tirmidhi himself called it hasan gharib). The sighting ties the ummah to the sky - '
    'the month begins when the crescent is seen, not when the '
    'calendar guesses.',
  ),

  // ── Earnings, trade, and the table ──────────────────────────────────
  _Entry(
    <String>['halal income', 'halal earnings', 'haram money', 'riba', 'interest', 'halal work'],
    '"O people, Allah is Pure and accepts only what is pure - He commands '
    'the believers as He commanded the messengers: eat of the good and do '
    'righteous work." (Sahih Muslim 1015). Earnings built on riba are '
    'fought by the Prophet himself: he cursed the one who consumes riba, '
    'the one who gives it, the one who records it, and its two witnesses - '
    '"they are alike." (Muslim 1598). Trade is blessed; the Prophet was a '
    'merchant and praised the honest trader.',
  ),
  _Entry(
    <String>['gambling', 'lottery', 'betting', 'casino', 'poker'],
    '"O you who have believed, indeed, intoxicants, gambling, ... and '
    'divining arrows are but defilement from the work of Satan, so avoid '
    'it that you may be successful. Satan only wants to cause between you '
    'animosity and hatred through intoxicants and gambling and to avert '
    'you from the remembrance of Allah and from prayer." '
    '(Al-Ma\'idah 90-91). The money of '
    'gambling is built on taking without consent - the blessed '
    'exit door is always open.',
  ),
  _Entry(
    <String>['alcohol', 'drinking', 'wine', 'beer', 'intoxicants'],
    '"Every intoxicant is khamr, and every khamr is unlawful." '
    '(Sahih Muslim 2003). It is also reported that the prayer of one '
    'who drinks khamr is not accepted for forty days, and that Allah '
    'accepts his repentance if he repents (Jami at-Tirmidhi 1862 - graded '
    'da\'if by Darussalam; al-Tirmidhi himself called it hasan). What '
    'poisons the mind is barred from the body, '
    'whatever shape the bottle takes.',
  ),
  _Entry(
    <String>['eating manners', 'right hand eating', 'wash hands eating', 'table manners islam', 'eat with the right hand', 'manners of eating', 'etiquette of eating'],
    'The Sunnah of the table: mention Allah\'s name, eat with the right '
    'hand, and eat from what is nearest to you (Sahih al-Bukhari 5376; '
    'see also Sahih Muslim 2017 and 2020). If you forget to mention Allah '
    'at the start, say: Bismillahi awwalahu wa akhirahu (Sunan Abi Dawud '
    '3767, sahih per al-Albani). Washing the hands before and after the '
    'meal is reported to bring blessing in the food '
    '(Sunan Abi Dawud 3761 - graded da\'if (weak) by al-Albani, so held as a weak report). Eat '
    'together and mention Allah\'s name: the Prophet ﷺ told his Companions '
    'that the food would then be blessed for them '
    '(Sunan Abi Dawud 3764, hasan per al-Albani).',
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
    'From the Sunnah of healing: honey - "healing for people" '
    '(An-Nahl 69), and the Prophet said healing is in three: the '
    'cut of the cupper, a drink of honey, and cauterization with '
    'fire - but he forbade his ummah cauterization. (Sahih '
    'al-Bukhari, Book of Medicine). And black seed: "the healing for every '
    'disease except death" (Bukhari 5688). Medicine of the body '
    'and the ruqyah of the heart travel together.',
  ),
  _Entry(
    <String>['zamzam', 'drinking zamzam', 'umrah zamzam'],
    '"The water of Zamzam is for whatever it is drunk for" - drink '
    'it with an intention: knowledge, healing, forgiveness, a '
    'righteous child. (Sunan Ibn Majah 3062, hasan per Darussalam). It sprang for Ismail '
    'in the desert of Makkah and has not ceased - five thousand '
    'years of answered thirst.',
  ),
  _Entry(
    <String>['cupping', 'hijamah', 'blood cupping'],
    'The Prophet praised cupping: "The best of your treatments is '
    'hijamah" - and had it done on the veins at the back of his '
    'neck, paying the cupper his wage. (reported; number not verified here). '
    'Even treatment has an etiquette: seek the skilled, pay '
    'fairly, and pair it with du\'a.',
  ),
  _Entry(
    <String>['cats', 'kittens', 'pet cat'],
    'Kindness to cats is from the Sunnah: cats are not impure, the '
    'Prophet said; they are among those who go about among you, and '
    'water a cat has drunk from remains usable. (Jami\' at-Tirmidhi 92, sahih per Darussalam).',
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
    '(Jami\' at-Tirmidhi 3431, weak per Darussalam). Gratitude without the afflicted '
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
    'The Prophet said: "If you relied upon Allah as He should be relied '
    'upon, He would provide for you as He provides for the birds - they '
    'leave in the morning with empty stomachs and return full." (Jami\' '
    'at-Tirmidhi 2344, hasan per Darussalam). And: "Tie your camel, then trust in Allah." '
    '(Tirmidhi 2517, hasan per Darussalam). Tawakkul is not the abandonment of means - it is the '
    'heart\'s grip on Allah while the hand grips the rope. Rizq is written '
    'for each person when the angel is sent to breathe in the soul, after '
    'three stages of forty days in the womb (Sahih al-Bukhari 3208, Sahih Muslim 2643); what is '
    'yours will walk to you.',
  ),
  _Entry(
    <String>['hurt myself', 'want to die', 'end my life', 'no point living', 'self harm', 'suicidal', 'don\'t want to live', 'kill myself', 'no will to live'],
    'Please - stop, and breathe. Your pain is real, and so is '
    'Allah\'s promise: "Allah does not charge a soul except [with that '
    'within] its capacity" (Al-Baqarah 286), and "do not despair of the '
    'mercy of Allah" (Az-Zumar 53). This world can hurt unbearably, but '
    'the Prophet said: "No fatigue, nor illness, nor anxiety, nor '
    'sorrow, nor harm reaches a Muslim but that Allah expiates by '
    'it - even a thorn." (Sahih al-Bukhari 5641). You are not '
    'alone. If you might act on these thoughts, please call your local '
    'emergency number or a crisis line right now, or go to someone near '
    'you; the Sakina room lists help lines. '
    'Stay - the One who made you is not done with you.',
  ),
  _Entry(
    <String>['hijab', 'covering', 'modesty dress', 'why do muslim women cover'],
    'Allah says: "And tell the believing women to reduce [some] of their '
    'vision and guard their private parts and not expose their adornment '
    'except that which [necessarily] appears thereof and to wrap [a '
    'portion of] their headcovers over their chests..." (An-Nur 31), '
    'and: "O Prophet, tell your wives and your daughters and the women of '
    'the believers to bring down over themselves [part] of their outer '
    'garments." (Al-Ahzab 59). The '
    'Prophet ﷺ is reported to have told Asma\' that once a woman reaches '
    'puberty, nothing should be shown of her but this and this - and he '
    'pointed to his face and hands '
    '(Sunan Abi Dawud 4104 - Abu Dawud himself called it mursal, meaning a link in the chain is missing; al-Albani graded it sahih; scholars differ on how it applies, so ask '
    'a scholar of your madhhab). It is worship, obedience, and - for many '
    'who wear it - peace.',
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
    'slowly, without artificiality. Begin with one surah perfected; the Qur\'an '
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
  // ── The Prophets, peace be upon them all ───────────────────────────
  _Entry(
    <String>['adam', 'first human', 'adam and eve', 'hawa'],
    'Adam - the first human and the first prophet - was taught the '
    'names of all things by Allah Himself (Al-Baqarah 31). From Adam '
    'and Hawwa came every nation; from their repentance we learn '
    'that the door of return never closes, for them or for us.',
  ),
  _Entry(
    <String>['nuh', 'noah', 'the flood', 'ark'],
    'Nuh, peace be upon him, called his people by day in openness '
    'and by night in secret - for nine hundred and fifty years '
    '(Al-Ankabut 14). When the flood came, the ark carried the '
    'believers and pairs of every kind. The lesson: success is '
    'measured by faithfulness to the message, not by who listens.',
  ),
  _Entry(
    <String>['ibrahim', 'abraham', 'kaaba builder', 'friend of allah'],
    'Ibrahim, Khalilullah - the Friend of Allah - smashed the idols '
    'his people worshipped and walked out of the fire they lit for '
    'him - Ibn Abbas reported that he said "Allah is sufficient for us, '
    'and He is the best disposer" (Sahih al-Bukhari 4563), words the '
    'Qur\'an also gives to the believers: "Sufficient for us is Allah, '
    'and [He is] the best Disposer of affairs." (Al-Imran 173). He and his '
    'son Ismail raised the foundations of the Ka\'bah together '
    '(Al-Baqarah 127). Every prophet after him is of his house, '
    'and we send peace upon him in every prayer.',
  ),
  _Entry(
    <String>['yusuf', 'joseph', 'best of stories'],
    'Yusuf was thrown into a well by his own brothers, sold as a '
    'slave, slandered by a minister\'s wife, and imprisoned - then '
    'raised to the treasury of Egypt. The Qur\'an calls his story '
    'the best of stories (Yusuf 3). Its thread: no betrayal outruns '
    'Allah\'s plan, and forgiveness is the crown of the wronged - '
    '"No blame will there be upon you today." (Yusuf 92).',
  ),
  _Entry(
    <String>['musa', 'moses', 'red sea', 'pharaoh', 'firawn'],
    'Musa, the one Allah spoke to directly (An-Nisa 164), stood '
    'before Pharaoh with a staff and a brother - and the sea split '
    'at his strike (Ash-Shuara 63). He received the Tawrah on the '
    'mountain and led Bani Israel through forty years of lessons. '
    'When Khidr outpaced his patience, Musa learned: knowledge is '
    'deeper than what we see (Al-Kahf 60-82).',
  ),
  _Entry(
    <String>['dawud', 'david', 'zabur', 'psalms'],
    'Dawud was given the Zabur - the Psalms - and iron was softened '
    'for him: "Make full coats of mail and calculate [precisely] the links" '
    '(Saba 10-11). Mountains and birds would echo his glorification '
    'with him (Saba 10). He judged between people with justice and '
    'repented at speed when rebuked by two disputants.',
  ),
  _Entry(
    <String>['sulayman', 'solomon', 'kingdom', 'jinn and animals'],
    'Sulayman inherited Dawud\'s kingdom and was given what no one '
    'after him was given: the wind traveled a month\'s journey each '
    'morning and evening for him, the jinn built at his command, '
    'and even the ants had a language he understood (An-Naml 16-19). '
    'He asked for a kingdom no one after him would have - and it '
    'was given (Sad 35).',
  ),
  _Entry(
    <String>['isa', 'jesus', 'mary', 'messiah'],
    'Isa, the Messiah, was born to the virgin Maryam - she was '
    'dedicated to the temple by her mother and miraculously '
    'sustained (Al-Imran 35-37; Maryam 16-34). He spoke in the '
    'cradle, healed by Allah\'s leave, and called to worship '
    'Allah alone: "Indeed, Allah is my Lord and your Lord, so '
    'worship Him" (Maryam 36). The Qur\'an says plainly: he is the '
    'messenger of Allah, His word to Maryam, not a son - "Exalted '
    'is He above having a son" (An-Nisa 171).',
  ),
  _Entry(
    <String>['muhammad', 'life of the prophet', 'the prophet\'s story', 'seerah summary', 'final prophet'],
    'Muhammad ibn Abdullah, the Seal of the Prophets (Al-Ahzab 40), '
    'was born in Makkah in the Year of the Elephant, orphaned '
    'young, known as As-Sadiq Al-Amin - the Truthful, the '
    'Trustworthy - long before revelation. At forty, in the cave '
    'of Hira, Jibreel brought him: "Iqra" - Read. He endured '
    'thirteen years of Makkan persecution, walked to Madinah when '
    'the assassination plot was laid, and in ten years there built '
    'a community that changed history - forgiving the city that '
    'stoned him at its conquest: "Go, you are free." He passed at '
    'sixty-three with his armor pledged for wheat - leaving no '
    'gold and a religion that now carries two billion hearts.',
  ),
  _Entry(
    <String>['order of prophets', 'list of prophets', '25 prophets', 'how many prophets', 'prophets mentioned'],
    'The Qur\'an names twenty-five prophets; from Adam, the first, '
    'to Muhammad, the last. The named ones: Adam, Idris, Nuh, Hud, '
    'Salih, Ibrahim, Lut, Ismail, Ishaq, Ya\'qub, Yusuf, Ayyub, '
    'Shu\'ayb, Musa, Harun, Dhul-Kifl, Dawud, Sulayman, Ilyas, '
    'Al-Yasa, Yunus, Zakariya, Yahya, Isa, and Muhammad - peace '
    'be upon them all. The stories shelf of this app walks many of '
    'them, story by story.',
  ),
  _Entry(
    <String>['difference between prophet and messenger', 'nabi vs rasul', 'messenger vs prophet'],
    'A prophet (nabi) receives revelation from Allah. A messenger '
    '(rasul) is a prophet sent with a book or a law to a people - '
    'every messenger is a prophet, but not every prophet was '
    'entrusted with a new scripture. The five of strongest resolve '
    '(ulu al-\'azm) are Nuh, Ibrahim, Musa, Isa, and Muhammad - '
    'peace be upon them all.',
  ),

  // ── The Qur\'an, its chapters and its history ──────────────────────
  _Entry(
    <String>['fatiha', 'opening chapter', 'first surah'],
    'Al-Fatiha - the Opening - is the seven verses no prayer stands '
    'without: the Prophet ﷺ said the one who does not recite the Opening '
    'of the Book has not validly performed the prayer (Sahih Muslim 394). '
    'It is Umm al-Qur\'an, and he said the like of it was not revealed in '
    'the Tawrah, the Injil, the Zabur or the Furqan (Jami at-Tirmidhi 2875, '
    'sahih per Darussalam).',
  ),
  _Entry(
    <String>['ayat al-kursi', 'kursi', 'greatest verse', 'throne verse'],
    'Ayat al-Kursi (Al-Baqarah 255) is the greatest verse of the '
    'Qur\'an - the Prophet affirmed it when Ubayy asked. A report '
    'in an-Nasa\'i says nothing prevents the one who recites it after '
    'every obligatory prayer from Paradise except death (reported; '
    'number and grade not verified here). '
    'Its beginning: "Allah - there is no deity except Him, the '
    'Ever-Living, the Sustainer of all."',
  ),
  _Entry(
    <String>['ya-sin', 'yaseen', 'heart of the quran'],
    'Ya-Sin is the heart of the Qur\'an, as the Prophet named it '
    '(Jami\' at-Tirmidhi 2887, weak per Darussalam). Because that report is '
    'weak, practices attached to it (reciting it for the dying or over a '
    'need) are not presented here as Sunnah: ask a scholar.',
  ),
  _Entry(
    <String>['al-mulk', 'surah mulk', 'before sleep surah'],
    'Surah Al-Mulk (The Sovereignty) is reported to be a surah of thirty '
    'verses that pleads for its reciter until he is forgiven (Sunan Abi '
    'Dawud 1400, hasan per al-Albani; Jami at-Tirmidhi 2891, hasan per '
    'Darussalam). A separate report says it delivers from the punishment '
    'of the grave (Jami at-Tirmidhi 2890 - graded da\'if by Darussalam; '
    'al-Tirmidhi himself called it hasan gharib).',
  ),
  _Entry(
    <String>['al-ikhlas', 'ikhlas', 'qul huwallahu'],
    'Qul Huwallahu Ahad - Al-Ikhlas, the Sincerity - is said to equal a '
    'third of the Qur\'an (Sahih al-Bukhari 5013). Four verses that name Allah: The One, the '
    'Eternal Refuge, who begets not and was not begotten - and '
    'nothing is comparable to Him.',
  ),
  _Entry(
    <String>['last two verses of baqarah', 'kursi dua night', 'suffice him'],
    'Whoever recites the last two verses of Al-Baqarah at night, '
    'they will suffice him (Sahih al-Bukhari 5009). At bedtime the '
    'Prophet ﷺ also cupped his hands, recited the three Quls into them, '
    'blew into them and wiped what he could of his body, three times '
    '(Sahih al-Bukhari 5017).',
  ),
  _Entry(
    <String>['recitation reward', 'letter of quran reward', 'reading quran reward'],
    'The reciter is not paid by the page but by the letter: '
    '"Whoever recites a letter of the Book of Allah has a reward '
    'for it, and each reward is multiplied ten times - I do not '
    'say alif-lam-mim is a letter, but alif is a letter..." '
    '(Jami\' at-Tirmidhi 2910, hasan per Darussalam). A slow page outearns a rushed '
    'volume.',
  ),
  _Entry(
    <String>['compiled quran', 'who compiled the quran', 'uthman', 'quran history'],
    'Revelation ended with the Prophet\'s passing, and the '
    'compilation followed: Abu Bakr gathered the Qur\'an into one '
    'book after the Battle of Yamamah, at Umar\'s insistence '
    '(Sahih al-Bukhari 4986). Uthman standardized the consonantal '
    'text and sent copies to the cities - the manuscripts we read '
    'descend from those. Allah promised the preservation Himself: '
    '"Indeed, it is We who sent down the Qur\'an and indeed, We will be '
    'its guardian" (Al-Hijr 9).',
  ),
  _Entry(
    <String>['al-waqiah', 'waqiah', 'rizq surah', 'poverty surah'],
    'The tradition says recite Surah Al-Waqi\'ah - the Event, the '
    'surah of provision - between Maghrib and Isha for '
    'sufficiency from poverty (reported by Ibn Masud in the '
    'collections of ad-Darimi and others). Its opening strikes the '
    'heart: when the inevitable event arrives...',
  ),

  // ── The Names of Allah ──────────────────────────────────────────────
  _Entry(
    <String>['names of allah meanings', 'names of allah', 'asma ul husna', 'attributes of allah', 'who is allah', 'meanings of the names'],
    'The Prophet said Allah has ninety-nine names - one hundred '
    'less one - whoever preserves them enters Paradise (Sahih '
    'al-Bukhari 2736). A few of their lights: Ar-Rahman - the '
    'Entirely Merciful; Ar-Rahim - the Especially Merciful to '
    'believers; Al-Malik - the King; Al-Quddus - the Most Holy; '
    'Al-Wadud - the Most Loving; Al-Latif - the Most Subtle and '
    'Kind; Al-Khabir - the All-Aware; Al-Fattah - the Opener; '
    'Al-Alim - the All-Knowing; Al-Hakim - the All-Wise; '
    'Al-Ghafoor - the Ever-Forgiving; As-Sabur - the Most '
    'Patient; Al-Wakeel - the Best Disposer of Affairs; Al-Hayy - '
    'the Ever-Living; Al-Qayyum - the Sustainer; An-Nur - the '
    'Light; Al-Haqq - the Absolute Truth; Al-Mateen - the Firm. '
    'The 99 Names game walks them one by one with meanings and '
    'references.',
  ),

  // ── Purification and prayer fiqh ────────────────────────────────────
  _Entry(
    <String>['ghusl', 'full bath', 'janabah', 'major impurity', 'after intimacy'],
    'Ghusl - the full wash - is owed after intimacy, after '
    'menstruation, and after post-natal bleeding. The Prophet\'s '
    'way: wash the hands, rinse the mouth and nose, wash the head '
    'and right side then left - as one continuous wash. (Sahih '
    'al-Bukhari 248). Water reaches every part, once or more.',
  ),
  _Entry(
    <String>['tayammum', 'no water', 'dust ablution', 'dry wudu'],
    'When water is absent - or using it would harm you - Allah '
    'permitted tayammum: "then seek clean earth and wipe over your '
    'faces and your hands [with it]" (An-Nisa 43). Strike clean dust with the palms, wipe '
    'the face, then the hands to the elbows (Al-Ma\'idah 6). The '
    'earth itself is made for purification, said the Prophet. '
    '(Sahih al-Bukhari 344)',
  ),
  _Entry(
    <String>['breaks wudu', 'nullify wudu', 'invalid wudu', 'wudu broken'],
    'What nullifies wudu: anything that exits the two private '
    'passes; deep sleep; and loss of consciousness or sanity. '
    'Scholars differ on touching the private part: one report says to '
    'make wudu after it (Sunan Abi Dawud 181, sahih per al-Albani) and '
    'another likens it to any other part of the body (Jami at-Tirmidhi '
    '85, sahih per Darussalam); ask a scholar of your madhhab. Doubt does '
    'not remove certainty of purity (Sahih Muslim 362). Scholars also '
    'differ on eating camel meat, so ask a scholar.',
  ),
  _Entry(
    <String>['period', 'menstruation', 'hayd', 'can I pray on my period', 'menses'],
    'The menstruating woman does not pray and does not fast - the '
    'Prophet told Fatimah bint Abi Hubaysh: leave prayer during '
    'the days, then wash and pray. (Sahih al-Bukhari 306) She '
    'makes up the fasts, not the prayers: the Prophet ﷺ did not order '
    'women to make up the prayers they missed in their periods (Sahih '
    'al-Bukhari 321). Worship does not '
    'stop - dhikr, du\'a, Qur\'an listening and good deeds all '
    'remain open.',
  ),
  _Entry(
    <String>['missed prayer', 'make up prayer', 'qada prayer', 'overslept prayer', 'forgot prayer'],
    'Whoever sleeps through a prayer or forgets it, let him pray '
    'it when he remembers - "there is no expiation for it except '
    'this" (Sahih al-Bukhari 597). The missed prayers are a debt '
    'on the neck; the scholars hold a person of resolve pays them '
    'in order with each day\'s prayers until cleared.',
  ),
  _Entry(
    <String>['combine prayers', 'travel prayers', 'jam', 'qasr', 'shorten prayer travel'],
    'The traveler shortens the four-unit prayers to two - a gift '
    'of the Sunnah the Prophet said is charity Allah gave: "It is '
    'a charity Allah has given you, so accept His charity." '
    '(Sahih Muslim 686) And on a real journey he combined - '
    'Zuhr with Asr, Maghrib with Isha - as he did at Arafat and '
    'Muzdalifah (Sahih Muslim 1218).',
  ),
  _Entry(
    <String>['congregation', 'jamaah', 'pray together', 'mosque prayer', 'pray in the masjid'],
    'Prayer in congregation outweighs solitary prayer by '
    'twenty-seven degrees (Sahih al-Bukhari 645). The mu\'adhdhin '
    'calls, the rows form shoulder to shoulder, the imam leads - '
    'and the angels pray behind the rows. Twenty-seven: the '
    'scholars said it is as if a man prayed every day and night '
    'for five and twenty.',
  ),
  _Entry(
    <String>['adhan', 'call to prayer', 'muadhin', 'repeat after adhan'],
    'When the adhan sounds, repeat the words after the '
    'mu\'adhdhin - then send blessings upon the Prophet, and ask '
    'for al-Wasilah: "O Allah, Lord of this perfect call and the '
    'established prayer, grant Muhammad the Wasilah..." '
    '(Sahih Muslim 384). "My intercession will be obligatory for '
    'him" - it was said of whoever asks it once. (Bukhari 614)',
  ),
  _Entry(
    <String>['khuffs', 'leather socks', 'wipe socks', 'masah', 'winter socks'],
    'The traveler wipes over leather socks for three days and '
    'nights, the resident for one day and night - then the wash '
    'is owed. (Sahih Muslim 276) Ali said he saw the Prophet ﷺ wipe the '
    'top of his leather socks, and that if religion were by opinion the '
    'underside would seem more fitting to wipe '
    '(Sunan Abi Dawud 162, sahih per al-Albani).',
  ),

  // ── Creed, gently held ──────────────────────────────────────────────
  _Entry(
    <String>['tawhid', 'oneness of allah', 'three types of tawhid', 'uluhiyyah'],
    'Tawhid is that Allah alone is God - in His lordship '
    '(Ar-Rububiyyah: He alone creates and sustains), in His '
    'worship (Al-Uluhiyyah: Him alone we worship and invoke), and '
    'in His names and attributes (Al-Asma was-Sifat: as He '
    'described Himself, without likeness). "Allah witnesses that '
    'there is no deity except Him, and [so do] the angels and those of '
    'knowledge" (Al-Imran 18).',
  ),
  _Entry(
    <String>['shirk', 'polytheism', 'associating partners'],
    'Shirk - joining partners with Allah - is the gravest of '
    'sins: "Indeed, Allah does not forgive association with Him, '
    'but He forgives what is less than that for whom He wills" '
    '(An-Nisa 48). It is not only idols - showing off in worship '
    'is the hidden shirk the Prophet warned of (Ahmad). The cure '
    'is what the caller to Islam repeats: La ilaha illallah.',
  ),
  _Entry(
    <String>['qadar', 'destiny', 'predestination', 'qadr', 'why did allah allow'],
    'Belief in qadar - the decree - is the sixth pillar of '
    'faith. The Prophet told the slave seeking freedom: "Say: I '
    'trust in Allah, there is no might nor power except with '
    'Allah" - and taught that this saying is a rescue from every '
    'hardship. (Sahih al-Bukhari) And he said you will not enter Paradise until you '
    'believe, and you will not believe until you love one another '
    '(Sahih Muslim 54). '
    'What reached you could never have missed you; what missed '
    'you could never have reached you.',
  ),
  _Entry(
    <String>['angels', 'jibreel', 'gabriel', 'recording angels', 'mika\'il'],
    'Belief in the angels is the second pillar of faith. '
    'Jibreel brings revelation; Mika\'il is charged with rain '
    'and provision; Israfil will blow the Trumpet; Malik keeps '
    'the Fire; and Kiraman Katibin - the noble scribes - record '
    'every word: "Man does not utter any word except that with him is an '
    'observer prepared [to record]" (Qaf 18). (See Al-Baqarah 97-98, Fatir '
    '1, Az-Zukhruf 77)',
  ),
  _Entry(
    <String>['jinn', 'qarin', 'evil spirits', 'demons'],
    'The jinn were created before man from fire: "from scorching fire" '
    '(Al-Hijr 27), "from a smokeless flame of fire" (Ar-Rahman 15) - some '
    'believers, some not. The Prophet ﷺ said that every one of us has a '
    'companion from the jinn assigned to him; asked whether that included '
    'him, he said yes, but Allah helped him against it so it only urges '
    'him to good (Sahih Muslim 2814). Their harm is real but bounded. '
    'Reciting Ayat al-Kursi before sleep brings a protector from Allah '
    'and no devil comes near until morning (Sahih al-Bukhari 2311), and '
    'the last two verses of Al-Baqarah at night will suffice him (Sahih '
    'al-Bukhari 5009).',
  ),
  _Entry(
    <String>['magic', 'sihr', 'spell', 'witchcraft', 'someone did magic on me'],
    'Sihr is real - the two angels Harut and Marut taught the '
    'test, and people learn from them that "by which they cause '
    'separation between a man and his wife" (Al-Baqarah 102). The Prophet was affected by a '
    'spell and was healed by Jibreel with the Mu\'awwidhat. '
    '(Sahih al-Bukhari 5763) The defense is not fear but '
    'remembrance: the three Quls, Ayat al-Kursi, and the dua '
    '"Bismillahilladhi la yadurru ma\'a ismihi shay\'un..." (Jami\' at-Tirmidhi 3388, hasan per Darussalam) - '
    'nothing harms the one who says them morning and evening.',
  ),
  _Entry(
    <String>['bid\'ah', 'innovation', 'newly invented', 'bida'],
    '"The worst of matters are the newly invented; every '
    'innovation is misguidance, and every misguidance is in the '
    'Fire." (Sahih Muslim 867). This is why the companions '
    'guarded the practice so carefully - what was not worship in '
    'the Prophet\'s day is not worship in ours. And yet the '
    'doors of mercy remain wide: whatever eases people without '
    'contradicting the revelation finds its place in the '
    'scholars\' categories.',
  ),

  // ── Life's paperwork and relationships ──────────────────────────────
  _Entry(
    <String>['non-muslim family', 'non muslim parents', 'my non muslim', 'christian family', 'jewish friends'],
    'Allah said: "Allah does not forbid you from those who do '
    'not fight you because of religion and do not expel you from '
    'your homes - from being righteous toward them and acting '
    'justly toward them. Indeed, Allah loves those who act '
    'justly" (Al-Mumtahanah 8). Kindness to parents is owed even '
    'if they do not share your faith: " accompany them in this '
    'world with appropriate kindness" (Luqman 15) - while '
    'worship remains Allah\'s alone.',
  ),
  _Entry(
    <String>['fidya', 'cannot fast', 'unable to fast', 'old age fasting', 'pregnant fasting'],
    'For the one who cannot fast from old age or lasting '
    'illness: "a ransom [as substitute] of feeding a poor person '
    '[each day]" (Al-Baqarah 184); Ibn Abbas said this verse was not '
    'abrogated for the old man and old woman who cannot fast (Sahih '
    'al-Bukhari 4505). The pregnant or nursing woman who fears for '
    'herself or her child: scholars differ on whether she makes the '
    'fast up, feeds a poor person, or both - ask a scholar. '
    'Fiqh is mercy before it is arithmetic.',
  ),
  _Entry(
    <String>['wasiyyah', 'write a will', 'write my will', 'my will', 'estate', 'one third will'],
    'The Prophet heard that Sa\'d wished to bequeath all his '
    'wealth: "One third, and one third is much - to leave your '
    'heirs rich is better than leaving them poor, begging from '
    'people." (Sahih al-Bukhari 2742) A wasiyyah is made for '
    'non-heirs - up to a third - and debt is settled before '
    'any inheritance moves.',
  ),
  _Entry(
    <String>['faraid', 'inheritance', 'who inherits', 'islamic inheritance'],
    'It is reported that the Prophet ﷺ told Abu Hurairah to learn the '
    'rules of inheritance and teach them, for they are half of knowledge '
    '(Sunan Ibn Majah 2719 - graded da\'if (weak) by Darussalam, so held '
    'as a weak report). The shares are fixed in An-Nisa 11-12: the son\'s '
    'share, the daughter\'s half, the spouse\'s quarter or '
    'eighth, the parents\' sixths - apportioned after the '
    'burial, the debt, and the wasiyyah. It was a science the '
    'companions called half of knowledge because families '
    'stand or split on it.',
  ),

  // ========== PRAYER & WUDU ==========
  _Entry(
    <String>['wudu', 'ablution', 'how to make wudu', 'wudhu'],
    'Wudu has six obligatory steps: (1) intention, (2) washing the face, '
    '(3) washing the hands to the elbows, (4) wiping the head, (5) washing '
    'the feet to the ankles, (6) maintaining sequence. The Prophet ﷺ said that '
    'whoever performs wudu well, his sins come out of his body, even from '
    'beneath his fingernails (Sahih Muslim 245).',
  ),
  _Entry(
    <String>['wudu nullifiers', 'breaks wudu', 'nullify wudu', 'lost wudu'],
    'Wudu is nullified by: (1) anything exiting the private parts, (2) deep '
    'sleep, (3) loss of consciousness, (4) touching the private parts with '
    'the palm of the hand (directly, according to the stronger view). The '
    'Prophet ﷺ said: "Whoever touches his private part, let him perform '
    'wudu." (Sunan al-Tirmidhi).',
  ),
  _Entry(
    <String>['tayammum', 'dry ablution', 'no water', 'sand prayer'],
    'If water is unavailable or harmful to use, perform tayammum: strike '
    'clean earth once with both hands, wipe the face, then wipe the back of '
    'the hands. Allah says: "And if you are ill or on a journey or one of you '
    'comes from the place of relieving himself or you have contacted women '
    'and find no water, then seek clean earth." (Qur\'an 4:43, 5:6).',
  ),
  _Entry(
    <String>['ghusl', 'ritual bath', 'janabah', 'major impurity'],
    'Ghusl requires: (1) intention, (2) washing the entire body including '
    'the mouth and nose. The Prophet ﷺ said: "When a person performs ghusl, '
    'let him rinse his mouth and nose." (Sahih al-Bukhari 248). It is '
    'obligatory after sexual relations, menstruation, postpartum bleeding, '
    'and ejaculation.',
  ),
  _Entry(
    <String>['fajr', 'dawn prayer', 'morning prayer', 'subh'],
    'Fajr is two rak\'ahs, prayed from true dawn until sunrise. The Prophet '
    'ﷺ said: "Whoever prays the two cool prayers (Fajr and Asr) will enter '
    'Paradise." (Sahih al-Bukhari 574). It is the prayer most often missed; '
    'the Prophet called it the prayer of the believers.',
  ),
  _Entry(
    <String>['dhuhr', 'zuhr', 'noon prayer', 'midday prayer'],
    'Dhuhr is four rak\'ahs, prayed after the sun passes its zenith until '
    'the shadow of an object equals its length (plus the zenith shadow). The '
    'Prophet ﷺ said that prayer is light (Sahih Muslim 223).',
  ),
  _Entry(
    <String>['asr', 'afternoon prayer'],
    'Asr is four rak\'ahs, prayed from when the shadow of an object equals '
    'its length until sunset. The Prophet ﷺ said: "May Allah have mercy on '
    'a man who prays four rak\'ahs before Asr." (Sunan Abi Dawud). Missing '
    'Asr is described as losing one\'s family and wealth.',
  ),
  _Entry(
    <String>['maghrib', 'sunset prayer', 'evening prayer'],
    'Maghrib is three rak\'ahs, prayed immediately after sunset until '
    'twilight disappears. The Prophet ﷺ said: "My Ummah will continue to be '
    'upon good as long as they hasten to break the fast and delay the suhur." '
    '(Sahih al-Bukhari 1957). Hastening Maghrib is from the sunnah.',
  ),
  _Entry(
    <String>['isha', 'night prayer'],
    'Isha is four rak\'ahs, prayed from the disappearance of twilight until '
    'midnight (or until dawn). The Prophet ﷺ said: "If someone prays Isha in '
    'congregation, it is as if he prayed half the night. And if he prays '
    'Fajr in congregation, it is as if he prayed the entire night." '
    '(Sahih Muslim 656).',
  ),
  _Entry(
    <String>['sujood sahw', 'forgetfulness prostration', 'mistake in prayer'],
    'If you add, omit, or doubt a part of prayer, perform two prostrations '
    'of forgetfulness (sujood as-sahw) before the taslim. The Prophet ﷺ '
    'prayed Zuhr with five rak\'ahs, then performed two prostrations after '
    'the taslim when reminded. (Sahih al-Bukhari 401, Sahih Muslim 572).',
  ),
  _Entry(
    <String>['qada', 'make up prayers', 'missed prayer', 'qaza'],
    'Missed prayers must be made up in order. The Prophet ﷺ said: "When any '
    'of you sleeps through the prayer or forgets it, let him pray it when he '
    'remembers." (Sahih al-Bukhari 597, Sahih Muslim 684). There is no '
    'expiation except performing the prayer itself.',
  ),
  _Entry(
    <String>['taraweeh', 'tarawih', 'night ramadan prayer'],
    'Taraweeh is the night prayer of Ramadan, prayed in sets of two rak\'ahs. '
    'The Prophet ﷺ prayed it in the mosque for a few nights with people '
    'joining him, then stayed away fearing it would become obligatory for '
    'them (Sahih al-Bukhari 1129, Sahih Muslim 761). Umar later gathered '
    'the people behind one reciter, Ubayy ibn Ka\'b, and called it a good '
    'innovation (Sahih al-Bukhari 2010).',
  ),
  _Entry(
    <String>['witr', 'witr prayer', 'odd prayer'],
    'Witr is one rak\'ah prayed after Isha, typically after Tahajjud or '
    'Taraweeh. The Prophet ﷺ said: "Allah has prescribed witr for you, so '
    'pray witr." (Sunan al-Nasa\'i). It is strongly recommended and '
    'considered wajib by some scholars.',
  ),
  _Entry(
    <String>['tahajjud', 'night prayer', 'qiyam al-layl'],
    'Tahajjud is the voluntary night prayer, best performed in the last '
    'third of the night. Allah says: "Indeed, the righteous will be among '
    'gardens and springs, accepting what their Lord has given them. Indeed, '
    'they were before that doers of good. They used to sleep but little of '
    'the night, and in the hours before dawn they would ask forgiveness." '
    '(Qur\'an 51:15-18).',
  ),
  _Entry(
    <String>['janazah', 'funeral prayer', 'dead prayer'],
    'The funeral prayer (Salat al-Janazah) is a communal obligation (fard '
    'kifayah). It has four takbirs: (1) after the first, recite Fatiha; (2) '
    'after the second, send blessings on the Prophet; (3) after the third, '
    'make dua for the deceased; (4) after the fourth, say salam. The Prophet '
    'ﷺ said: "Whoever follows a funeral until the prayer is offered will '
    'have one qirat of reward." (Sahih al-Bukhari 1325).',
  ),
  _Entry(
    <String>['eid prayer', 'eid salat', 'salat al eid'],
    'Eid prayer is two rak\'ahs with extra takbirs: seven in the first '
    'rak\'ah and five in the second (before recitation). The Prophet ﷺ said: '
    '"Every nation has its day of celebration, and this is our day of '
    'celebration." (Sahih al-Bukhari 952, Sahih Muslim 892). It is '
    'recommended for women, children, and menstruating women to attend.',
  ),

  // ========== COMMON DUAS ==========
  _Entry(
    <String>['dua before sleep', 'sleeping dua', 'night dua'],
    'Before sleeping, say: "Bismika Allahumma amutu wa ahya" (In Your name, '
    'O Allah, I die and I live) (Sahih Muslim 2711). Make wudu and lie on '
    'your right side (Sahih al-Bukhari 247, Sahih Muslim 2710). The Prophet '
    'ﷺ also placed his right hand under his cheek and said: "Allahumma qini '
    'adhabaka yawma tab\'athu ibadaka" (O Allah, protect me from Your '
    'punishment on the Day You resurrect Your servants) (Sunan Abi Dawud '
    '5045, sahih per al-Albani).',
  ),
  _Entry(
    <String>['dua after waking', 'morning dua', 'waking up'],
    'Upon waking, say: "Alhamdu lillahi alladhi ahyana ba\'da ma amatana '
    'wa ilayhi an-nushur" (All praise is for Allah who gave us life after '
    'having taken it from us, and to Him is the resurrection). (Sahih '
    'al-Bukhari 6324, Sahih Muslim 2711).',
  ),
  _Entry(
    <String>['dua before eating', 'eating dua', 'food dua'],
    'Before eating, say: "Bismillah." If you forget, say: "Bismillahi fi '
    'awwalihi wa akhirihi" (In the name of Allah at its beginning and at '
    'its end). The Prophet ﷺ said: "When one of you eats, let him mention '
    'the name of Allah. If he forgets at the beginning, let him say: '
    'Bismillahi fi awwalihi wa akhirihi." (Sunan al-Tirmidhi 1858, sahih per Darussalam).',
  ),
  _Entry(
    <String>['dua after eating', 'finished eating'],
    'After eating, say: "Alhamdu lillahi alladhi at\'amani hadha wa '
    'razaqanihi min ghayri hawlin minni wa la quwwah" (All praise is for '
    'Allah who fed me this and provided it for me without any might or '
    'power from me). (Sunan Abi Dawud 3850, weak per al-Albani).',
  ),
  _Entry(
    <String>['dua entering home', 'entering house', 'coming home'],
    'When entering your home, say: "Bismillahi walajna, wa bismillahi '
    'kharajna, wa \'ala rabbina tawakkalna" (In the name of Allah we enter, '
    'and in the name of Allah we leave, and upon our Lord we rely). The '
    'Prophet ﷺ said: "Then say: Allahumma inni as\'aluka khayra al-mawliji '
    'wa khayra al-makhraji" (O Allah, I ask You for the best of entering '
    'and the best of leaving). (Sunan Abi Dawud 5096, weak per al-Albani).',
  ),
  _Entry(
    <String>['dua leaving home', 'leaving house', 'going out'],
    'When leaving home, say: "Bismillahi, tawakkaltu \'ala Allah, la hawla '
    'wa la quwwata illa billah" (In the name of Allah, I place my trust in '
    'Allah; there is no might and no power except with Allah). The Prophet '
    'ﷺ said: "It will be said to him: You are guided, sufficed, and '
    'protected." (Sunan Abi Dawud 5095, sahih per al-Albani).',
  ),
  _Entry(
    <String>['dua for travel', 'traveling dua', 'safar'],
    'When traveling, say: "Allahu akbar, Allahu akbar, Allahu akbar. '
    'Subhana alladhi sakhkhara lana hadha wa ma kunna lahu muqrinin, wa '
    'inna ila rabbina lamunqalibun" (Allah is the Greatest x3. Glory be to '
    'Him who has subjected this to us, and we could not have done it. And '
    'indeed we will return to our Lord). (Sahih Muslim 1342).',
  ),
  _Entry(
    <String>['dua for rizq', 'provision dua', 'money dua', 'wealth dua'],
    'The Prophet ﷺ taught: "Allahumma akfini bi halalika \'an haramika, wa '
    'aghnini bi fadlika \'amman siwaka" (O Allah, suffice me with what You '
    'have made lawful against what You have made forbidden, and enrich me '
    'with Your bounty beyond anyone else). (Sunan al-Tirmidhi 3563, hasan per Darussalam).',
  ),
  _Entry(
    <String>['dua for marriage', 'spouse dua', 'husband dua', 'wife dua'],
    'The Prophet ﷺ taught those seeking marriage to say: "Rabbana hab lana '
    'min azwajina wa dhurriyyatina qurrata a\'yunin wa-j\'alna lil-muttaqina '
    'imama" (Our Lord, grant us from among our wives and offspring comfort '
    'to our eyes and make us an example for the righteous). (Qur\'an 25:74). '
    'Also: "Allahumma inni as\'aluka khayraha wa khayra ma jabaltaha '
    '\'alayhi, wa a\'udhu bika min sharriha wa sharri ma jabaltaha \'alayhi." '
    '(Sunan Ibn Majah).',
  ),
  _Entry(
    <String>['dua for children', 'child dua', 'baby dua', 'pregnancy dua'],
    'Faith is a gift to ask for: Allah says He has endeared the faith to '
    'the believers and made disbelief, defiance and disobedience hateful to '
    'them (Qur\'an 49:7) - so ask Him to keep it so. For pregnancy: "Rabbi hab li min ladunka dhurriyyatan tayyibah" '
    '(My Lord, grant me from Yourself a good offspring). (Qur\'an 3:38).',
  ),
  _Entry(
    <String>['dua for health', 'sickness dua', 'healing dua', 'shifa'],
    'The Prophet ﷺ said that if someone visits a sick person whose time '
    'has not yet come and says seven times a supplication asking Allah, '
    'the Mighty, Lord of the Mighty Throne, to cure him, Allah will '
    'relieve him of that illness '
    '(Sunan Abi Dawud 3106, sahih per al-Albani).',
  ),
  _Entry(
    <String>['dua for protection', 'protection dua', 'safe dua'],
    'The Prophet ﷺ said: "Whoever says three times every morning and '
    'evening: Bismillahi alladhi la yadurru ma\'asmihi shay\'un fi al-ardi wa '
    'la fi al-sama\'i, wa huwa al-sami\'u al-\'alim — In the name of Allah, '
    'with whose name nothing on earth or in heaven can cause harm, and He '
    'is the All-Hearing, All-Knowing — nothing will harm him." (Sunan '
    'al-Tirmidhi 3388, hasan per Darussalam).',
  ),
  _Entry(
    <String>['dua for exam', 'test dua', 'study dua', 'knowledge dua'],
    'The Prophet ﷺ taught: "Allahumma infa\'ni bima \'allamtani, wa \'allimni '
    'ma yanfa\'uni, wa zidni \'ilman" (O Allah, benefit me with what You have '
    'taught me, teach me what benefits me, and increase me in knowledge). '
    '(Sunan Ibn Majah).',
  ),
  _Entry(
    <String>['dua for distress', 'hardship dua', 'difficulty dua'],
    'The Prophet ﷺ said: "The supplication of Dhun-Nun (Yunus) when he '
    'supplicated while in the belly of the whale: La ilaha illa anta, '
    'subhanaka, inni kuntu min al-zalimin — There is no god but You, glory '
    'be to You, indeed I was among the wrongdoers. No Muslim supplicates '
    'with it for anything but Allah answers him." (Sunan al-Tirmidhi 3505, sahih per Darussalam).',
  ),
  _Entry(
    <String>['dua for debt', 'loan dua', 'owe money dua'],
    'The Prophet ﷺ said: "Whoever is burdened with debt and says: Allahumma '
    'akfini bi halalika \'an haramika, wa aghnini bi fadlika \'amman siwaka — '
    'O Allah, suffice me with Your lawful against Your forbidden, and '
    'enrich me with Your bounty beyond anyone else — Allah will suffice '
    'him." (Sunan al-Tirmidhi 3563, hasan per Darussalam).',
  ),
  _Entry(
    <String>['dua for righteous death', 'good death', 'husn al-khatimah'],
    'The Prophet ﷺ said: "When you finish the obligatory prayer, say: '
    'Allahumma inni a\'udhu bika min al-jubni wa al-bukhl, wa a\'udhu bika '
    'min an uradda ila ardhal al-\'umur, wa a\'udhu bika min fitnat al-dunya '
    'wa fitnat al-qabr wa fitnat al-masih al-dajjal." (Sahih Muslim 588). '
    'Also seek: "Allahumma inni as\'aluka husn al-khatimah" (O Allah, I ask '
    'You for a good ending).',
  ),
  _Entry(
    <String>['dua entering masjid', 'masjid entrance', 'mosque dua'],
    'When entering the masjid, say: "Allahumma ftah li abwaba rahmatik" '
    '(O Allah, open for me the doors of Your mercy). When leaving, say: '
    '"Allahumma inni as\'aluka min fadlik" (O Allah, I ask You from Your '
    'bounty). (Sahih Muslim 713).',
  ),
  _Entry(
    <String>['dua for parents', 'father dua', 'mother dua', 'parents forgiveness'],
    'Allah says: "And lower to them the wing of humility out of mercy and '
    'say: My Lord, have mercy upon them as they brought me up when I was '
    'small." (Qur\'an 17:24). The Prophet ﷺ said: "The pleasure of the Lord '
    'is in the pleasure of the parent, and the displeasure of the Lord is '
    'in the displeasure of the parent." (Sunan al-Tirmidhi 1899, hasan per al-Tirmidhi).',
  ),
  _Entry(
    <String>['dua for forgiveness', 'istighfar', 'seek forgiveness', 'sin'],
    'The Prophet ﷺ said: "The most superior way of asking for forgiveness '
    'is to say: Allahumma anta rabbi, la ilaha illa anta, khalaqtani wa ana '
    '\'abduka, wa ana \'ala ahdika wa wa\'dika mastata\'tu, a\'udhu bika min '
    'sharri ma sana\'tu, abu\'u laka bi ni\'matika \'alayya, wa abu\'u laka '
    'bi dhanbi, fa ighfir li, fa innahu la yaghfiru al-dhunuba illa anta." '
    '(O Allah, You are my Lord. There is no god but You. You created me, and '
    'I am Your servant, and I am faithful to my covenant and promise to You '
    'as best I can. I seek refuge in You from the evil of what I have done. '
    'I acknowledge Your blessings upon me, and I acknowledge my sin. So '
    'forgive me, for none forgives sins but You.) (Sahih al-Bukhari 6306).',
  ),

  // ========== FIQH BASICS ==========
  _Entry(
    <String>['what is halal', 'what is haram', 'halal and haram', 'meaning of halal', 'meaning of haram'],
    'Allah says: "He has only forbidden to you dead animals, blood, the '
    'flesh of swine, and that which has been dedicated to other than '
    'Allah." (Qur\'an 2:173). The Prophet ﷺ said: "What Allah has made '
    'lawful in His Book is halal, what He has made forbidden is haram, and '
    'what He has remained silent about is a pardon." (Sunan al-Tirmidhi; scholars discuss its chain). For a specific question, ask a qualified scholar.',
  ),
  _Entry(
    <String>['fard', 'obligatory', 'wajib', 'mandatory'],
    'Fard (obligatory) acts are those for which there is definitive evidence '
    'in the Qur\'an or mutawatir hadith. Neglecting them is sinful. Examples: '
    'the five daily prayers, fasting Ramadan, zakat, Hajj. The Prophet ﷺ said: '
    '"Islam is built upon five: testifying that there is no god but Allah and '
    'Muhammad is His Messenger, establishing prayer, giving zakat, fasting '
    'Ramadan, and performing Hajj." (Sahih al-Bukhari 8, Sahih Muslim 16).',
  ),
  _Entry(
    <String>['sunnah', 'mustahabb', 'recommended', 'nafl', 'voluntary'],
    'Sunnah acts are those the Prophet ﷺ regularly performed and '
    'encouraged. They are divided into: Sunnah muakkadah (emphasized, like '
    'the two rak\'ahs before Fajr) and Sunnah ghayr muakkadah '
    '(non-emphasized). The Prophet ﷺ said: "Allah loves that His sunnahs '
    'are followed." (Sunan al-Nasa\'i).',
  ),
  _Entry(
    <String>['makruh', 'disliked', 'discouraged'],
    'Makruh (disliked) acts are those for which there is evidence of '
    'discouragement but not prohibition. Examples: eating with the left '
    'hand, wasting water during wudu, praying after Asr until sunset. The '
    'Prophet ﷺ said: "Do not waste water, even if you are at a flowing '
    'river." (Sunan Ibn Majah).',
  ),
  _Entry(
    <String>['bidah', 'innovation', 'biddah'],
    'The Prophet ﷺ said: "Whoever introduces into this matter of ours '
    '(Islam) something that is not part of it, it will be rejected." (Sahih '
    'al-Bukhari 2697, Sahih Muslim 1718). Bidah is any newly invented matter '
    'in religion that has no basis in the Qur\'an or authentic Sunnah. However, '
    'worldly innovations (technology, medicine) are not bidah.',
  ),
  _Entry(
    <String>['shirk', 'associating partners', 'polytheism'],
    'Allah says: "Indeed, Allah does not forgive association with Him, but '
    'He forgives what is less than that for whom He wills." (Qur\'an 4:48). '
    'Shirk is the greatest sin — associating partners with Allah in worship, '
    'lordship, or names/attributes. The Prophet ﷺ said: "Shall I not inform '
    'you of the greatest of major sins? They are: associating partners with '
    'Allah, disobeying parents, and bearing false testimony." (Sahih '
    'al-Bukhari 2654, Sahih Muslim 87).',
  ),
  _Entry(
    <String>['tawbah', 'repentance', 'turning back'],
    'Allah says: "Say, O My servants who have transgressed against '
    'themselves, do not despair of the mercy of Allah. Indeed, Allah forgives '
    'all sins. Indeed, it is He who is the Forgiving, the Merciful." (Qur\'an '
    '39:53). The Prophet ﷺ said: "Allah is more delighted with the repentance '
    'of His servant than one of you who finds his lost camel." (Sahih '
    'al-Bukhari 6309, Sahih Muslim 2747).',
  ),
  _Entry(
    <String>['tawakkul', 'trust in allah', 'reliance'],
    'Allah says: "And whoever relies upon Allah — then He is sufficient for '
    'him." (Qur\'an 65:3). The Prophet ﷺ said: "If you had relied upon Allah '
    'with true reliance, He would have provided for you as He provides for '
    'the bird: it goes out hungry in the morning and returns full in the '
    'evening." (Sunan al-Tirmidhi 2344, hasan per Darussalam).',
  ),
  _Entry(
    <String>['ikhlas', 'sincerity', 'pure intention'],
    'Allah says: "And they were not commanded except to worship Allah, '
    'being sincere to Him in religion, inclining to truth." (Qur\'an 98:5). '
    'The Prophet ﷺ said: "Actions are but by intentions, and every person '
    'will have what he intended." (Sahih al-Bukhari 1, Sahih Muslim 1907). '
    'Ikhlas is doing everything solely for Allah\'s pleasure.',
  ),
  _Entry(
    <String>['ihsan', 'excellence', 'perfection'],
    'The Prophet ﷺ said: "Ihsan is to worship Allah as if you see Him, and '
    'if you do not see Him, then indeed He sees you." (Sahih al-Bukhari 50, '
    'Sahih Muslim 8). Ihsan is the highest level of faith — excellence in '
    'every action, knowing Allah is always watching.',
  ),

  // ========== FAMILY & MARRIAGE ==========
  _Entry(
    <String>['marriage', 'nikah', 'getting married', 'wedding'],
    'The Prophet ﷺ said: "Marriage is part of my sunnah, and whoever does '
    'not follow my sunnah is not of me." (Sunan Ibn Majah 1846, hasan per Darussalam). The '
    'essential conditions are: offer and acceptance, mahr (dowry), two '
    'witnesses, and the wali (guardian) for the bride.',
  ),
  _Entry(
    <String>['mahr', 'dowry', 'bride price'],
    'Allah says: "And give the women [upon marriage] their [bridal] gifts '
    'graciously." (Qur\'an 4:4). The mahr is the husband\'s gift to the wife, which becomes her '
    'exclusive property. The Prophet ﷺ said: "The best of mahrs is the '
    'easiest." (Sunan al-Nasa\'i).',
  ),
  _Entry(
    <String>['walima', 'wedding feast', 'marriage banquet'],
    'The Prophet ﷺ said: "The worst of food is the food of a walima to '
    'which the rich are invited and the poor are left out. And whoever does '
    'not respond to the invitation has disobeyed Allah and His Messenger." '
    '(Sahih al-Bukhari 5173, Sahih Muslim 1429). The walima is a sunnah '
    'strongly encouraged on the day of marriage or within three days.',
  ),
  _Entry(
    <String>['divorce', 'talaq', 'ending marriage'],
    'Allah says: "Divorce is twice. Then, either keep her in an acceptable '
    'manner or release her with good treatment." (Qur\'an 2:229). The '
    'Prophet ﷺ said: "The most hated of permissible things to Allah is '
    'divorce." (Sunan Abi Dawud). It must be pronounced clearly during a '
    'period of purity (not menstruation) without intimacy.',
  ),
  _Entry(
    <String>['rights of wife', 'wife rights', 'husband duties'],
    'The Prophet ﷺ said in his farewell sermon: "Fear Allah concerning '
    'women. Indeed, you have taken them under Allah\'s trust, and their '
    'private parts are lawful to you by the word of Allah." (Sahih Muslim '
    '1218). Rights include: mahr, maintenance (food, clothing, housing), '
    'kind treatment, and not harming physically or emotionally.',
  ),
  _Entry(
    <String>['rights of husband', 'husband rights', 'wife duties'],
    'A report about a wife who prays her five prayers, fasts her month, '
    'guards her chastity and obeys her husband entering Paradise from any '
    'gate she wishes is found in Musnad Ahmad; we could not check its '
    'grading here, so we do not quote it. Rights are mutual; the usual '
    'summary includes obedience in permissible matters, protection of '
    'honor, and managing the household - ask a scholar of your madhhab '
    'for specifics.',
  ),
  _Entry(
    <String>['child rights', 'children rights', 'raising children'],
    'The Prophet ﷺ said: "Each of you is a shepherd and each of you is '
    'responsible for his flock. The man is a shepherd over his household and '
    'he is responsible for them." (Sahih al-Bukhari 893, Sahih Muslim 1829). '
    'Children have rights: good name, proper upbringing, education, '
    'affection, and fair treatment between siblings.',
  ),
  _Entry(
    <String>['breastfeeding', 'nursing', 'infant feeding'],
    'Allah says: "Mothers may breastfeed their children two complete years '
    'for whoever wishes to complete the nursing period." (Qur\'an 2:233). '
    'Nursing also creates family ties: among those a person may not marry '
    'Allah lists "your [milk] mothers who nursed you, your sisters through '
    'nursing" (Qur\'an 4:23). For the details of foster-nursing rulings, '
    'ask a scholar.',
  ),
  _Entry(
    <String>['circumcision', 'khitan', 'sunan al-fitrah'],
    'The Prophet ﷺ said: "Five are from the fitrah: circumcision, shaving '
    'the pubic hair, trimming the mustache, cutting the nails, and plucking '
    'the armpit hair." (Sahih al-Bukhari 5889, Sahih Muslim 257). '
    'Circumcision is obligatory for men and recommended for women (according '
    'to the majority view).',
  ),
  _Entry(
    <String>['aqiqah', 'newborn sacrifice', 'baby sacrifice'],
    'The Prophet ﷺ said: "Every child is held in pledge for his aqiqah, '
    'which is sacrificed for him on his seventh day, and he is named on his '
    'seventh day, and his head is shaved." (Sunan Abi Dawud 2838, sahih per al-Albani). Two '
    'sheep for a boy and one for a girl.',
  ),

  // ========== FINANCIAL ==========
  _Entry(
    <String>['zakat', 'zakah', 'alms', 'charity obligation'],
    'Allah says: "And establish prayer and give zakah." (Qur\'an 2:110). '
    'Zakat is 2.5% of wealth held for one lunar year above the nisab '
    '(threshold: the value of 595 g of silver or 85 g of gold — the Zakat '
    'calculator shows today\'s figure). It is due on gold, '
    'silver, cash, trade goods, and livestock. The Prophet ﷺ said: "Whoever '
    'is made wealthy by Allah and does not pay its zakat, his wealth will be '
    'made into a bald snake on the Day of Resurrection." (Sahih al-Bukhari '
    '1403).',
  ),
  _Entry(
    <String>['zakat calculation', 'how to calculate zakat', 'nisab'],
    'Zakat is due when wealth reaches the nisab (85g of gold or 595g of '
    'silver) and is held for one lunar year. Rate: 2.5% on cash, gold, '
    'silver, and trade goods. Agricultural produce: 5% (irrigated) or 10% '
    '(rain-fed). Livestock varies by number. The Prophet ﷺ said: "There is '
    'no zakat on less than five camels, less than five awaq of silver, and '
    'less than five wasaq of dates." (Sahih al-Bukhari 1447).',
  ),
  _Entry(
    <String>['sadaqah', 'voluntary charity', 'giving'],
    'The Prophet ﷺ said: "Charity does not decrease wealth. No one forgives '
    'another except that Allah increases him in honor. And no one humbles '
    'himself for Allah except that Allah raises him." (Sahih Muslim 2588). '
    'Sadaqah can be money, food, a smile, removing harm from the road, or '
    'even a kind word.',
  ),
  _Entry(
    <String>['riba', 'interest', 'usury', 'bank interest'],
    'Allah says: "But Allah has permitted trade and has forbidden '
    'interest." (Qur\'an 2:275). The Prophet ﷺ said: "Allah has cursed the one who '
    'consumes riba, the one who gives it, the one who records it, and the '
    'two witnesses to it." (Sahih Muslim 1598). Conventional bank interest '
    'on savings and loans is riba and forbidden.',
  ),
  _Entry(
    <String>['stocks', 'shares', 'investment', 'halal investing'],
    'Investing in stocks is permissible if the company\'s primary business '
    'is halal and its debt-to-asset ratio is below 33% (majority scholarly '
    'view). The Prophet ﷺ said: "The upper hand is better than the lower '
    'hand." (Sahih al-Bukhari 1419, Sahih Muslim 2588). Avoid companies in '
    'alcohol, gambling, pork, interest-based banking, and weapons.',
  ),
  _Entry(
    <String>['insurance', 'life insurance', 'halal insurance'],
    'Conventional insurance involves riba (interest), gharar (excessive '
    'uncertainty), and maysir (gambling), making it forbidden by the majority '
    'of scholars. Takaful (Islamic cooperative insurance) is the alternative, '
    'based on donation and mutual assistance rather than commercial '
    'transaction.',
  ),
  _Entry(
    <String>['inheritance', 'mirath', 'wasiyyah', 'islamic will', 'writing a will'],
    'Allah says: "Allah instructs you concerning your children: for the '
    'male, what is equal to the share of two females." (Qur\'an 4:11). '
    'Islamic inheritance is obligatory (fard) and cannot be willed away. '
    'Only up to one-third can be bequeathed to non-heirs. The Prophet ﷺ '
    'said: "Allah has given everyone who has a right his right, so there is '
    'no bequest for an heir." (Sunan al-Tirmidhi).',
  ),

  // ========== DEATH & AFTERLIFE ==========
  _Entry(
    <String>['burial', 'burying dead', 'grave', 'kafan'],
    'The Prophet ﷺ said: "Hasten the funeral. If the deceased was righteous, '
    'you are advancing him toward good. If otherwise, you are putting evil '
    'off your necks." (Sahih al-Bukhari 1315, Sahih Muslim 944). The body is '
    'washed, shrouded in white cloth (kafan), prayed over, and buried facing '
    'the qiblah.',
  ),
  _Entry(
    <String>['visiting graves', 'graveyard', 'cemetery'],
    'The Prophet ﷺ said: "I used to forbid you from visiting graves, but '
    'now visit them, for they remind you of the Hereafter." (Sahih '
    'Muslim 977). When visiting, greet the deceased '
    'with peace, make dua for them, and reflect on death.',
  ),
  _Entry(
    <String>['dua for deceased', 'dead person dua', 'funeral dua'],
    'The Prophet ﷺ taught: "Allahumma ighfir li hayyina wa mayyitina, wa '
    'shahidina wa gha\'ibina, wa saghirina wa kabirina, wa dhakarina wa '
    'unthana" (O Allah, forgive our living and our dead, our present and '
    'our absent, our young and our old, our males and our females). (Sunan '
    'Abi Dawud 3201, sahih per al-Albani).',
  ),
  _Entry(
    <String>['barzakh', 'grave life', 'punishment of grave'],
    'The Prophet ﷺ said: "The grave is the first of the stages of the '
    'Hereafter; whoever is saved from it, what comes after is easier, and '
    'whoever is not saved from it, what comes after is harder." (Sunan '
    'al-Tirmidhi). The soul experiences questioning by Munkar and Nakir, '
    'and either comfort or punishment.',
  ),
  _Entry(
    <String>['day of judgment', 'qiyamah', 'last day', 'resurrection'],
    'Allah says: "The Day every soul will find what it has done of good '
    'present [before it] and what it has done of evil." (Qur\'an 3:30). The Prophet ﷺ said: "The '
    'first thing a person will be asked about on the Day of Resurrection is '
    'his prayer. If it is sound, he will be successful; if not, he will be '
    'ruined." (Sunan al-Tirmidhi).',
  ),
  _Entry(
    <String>['jannah', 'paradise', 'heaven'],
    'Allah says: "And no soul knows what has been hidden for them of '
    'comfort for eyes as reward for what they used to do." (Qur\'an 32:17). '
    'The Prophet ﷺ said: "Allah says: I have prepared for My righteous '
    'servants what no eye has seen, no ear has heard, and no heart has '
    'imagined." (Sahih al-Bukhari 3244, Sahih Muslim 2824).',
  ),
  _Entry(
    <String>['jahannam', 'hellfire', 'hell', 'nar'],
    'Allah says: "Indeed, Hell has been lying in wait for the '
    'transgressors." (Qur\'an 78:21-22). The Prophet ﷺ said that a stone '
    'thrown into Hell seventy years ago was still falling until it '
    'only now reached the bottom. (Sahih Muslim 2844).',
  ),

  // ========== EMOTIONAL SUPPORT ==========
  _Entry(
    <String>['depression', 'sad', 'hopeless', 'empty'],
    'Allah says: "And We will surely test you with something of fear and '
    'hunger and a loss of wealth and lives and fruits, but give good tidings '
    'to the patient." (Qur\'an 2:155). The Prophet ﷺ experienced deep grief '
    '— he wept for Ibrahim, he lost Khadijah and Abu Talib in the same year. '
    'Depression is not a lack of faith; it is a test. Seek help: medical, '
    'spiritual, and communal.',
  ),
  _Entry(
    <String>['loneliness', 'alone', 'no friends', 'isolated'],
    'Allah says: "And He is with you wherever you are." (Qur\'an 57:4). The '
    'Prophet ﷺ said: "Allah says: I am as My servant thinks of Me. I am with '
    'him when he remembers Me." (Sahih al-Bukhari 7405, Sahih Muslim 2675). '
    'Loneliness is real, but you are never truly alone. The One who created '
    'you is closer than your jugular vein.',
  ),
  _Entry(
    <String>['betrayal', 'cheated', 'lied to', 'backstabbed'],
    'The Prophet ﷺ said: "There are three signs of a hypocrite: when he '
    'speaks, he lies; when he makes a promise, he breaks it; and when he is '
    'entrusted, he betrays." (Sahih al-Bukhari 33, Sahih Muslim 59). If you '
    'have been betrayed, know that the Prophet ﷺ was betrayed by his own '
    'uncle and tribe. Your pain is understood.',
  ),
  _Entry(
    <String>['anger', 'mad', 'furious', 'rage'],
    'The Prophet ﷺ said: "The strong is not the one who overcomes people by '
    'his strength, but the strong is the one who controls himself while in '
    'anger." (Sahih al-Bukhari 6114, Sahih Muslim 2609). When angry, sit down '
    'if standing, lie down if sitting, and make wudu — the physical change '
    'breaks the emotional spiral.',
  ),
  _Entry(
    <String>['laziness', 'procrastination', 'can\'t start', 'unmotivated'],
    'Allah says: "So when you have finished [your duties], then stand up '
    '[for worship]. And to your Lord direct [your] longing." (Qur\'an '
    '94:7-8). '
    'The Prophet ﷺ sought refuge from laziness: "Allahumma inni a\'udhu bika '
    'min al-\'ajzi wa al-kasal" (O Allah, I seek refuge in You from '
    'incapacity and laziness). (Sahih al-Bukhari 6369).',
  ),
  _Entry(
    <String>['fear', 'scared', 'afraid', 'terror'],
    'Allah says: "Fear not. Indeed, I am with you both; I hear and I '
    'see." (Qur\'an 20:46). The Prophet ﷺ said: "Allah says: I am as My '
    'servant expects of Me." (Sahih al-Bukhari 7405, Sahih Muslim 2675). Say '
    'Hasbunallahu wa ni\'mal wakeel (Allah is sufficient for us, and He is '
    'the best Disposer of affairs) — the same words Ibrahim said when thrown '
    'into the fire.',
  ),
  _Entry(
    <String>['guilt', 'ashamed', 'regret', 'remorse'],
    'Allah says: "Say, O My servants who have transgressed against '
    'themselves, do not despair of the mercy of Allah. Indeed, Allah forgives '
    'all sins." (Qur\'an 39:53). Guilt that leads to repentance is from '
    'Allah. Guilt that leads to despair is from Shaytan. The door of tawbah '
    'is open until the soul reaches the throat.',
  ),
  _Entry(
    <String>['envy', 'jealous', 'hasad', 'evil eye'],
    'The Prophet ﷺ said: "The evil eye is real." (Sahih al-Bukhari 5740, '
    'Sahih Muslim 2187). Protect yourself with: (1) regular adhkar, (2) '
    'reciting the last three surahs morning and evening, (3) saying '
    '"MashaAllah, la quwwata illa billah" when admiring something. If you '
    'feel envy, make dua for the person — it transforms the poison into '
    'prayer.',
  ),
  _Entry(
    <String>['nightmares', 'bad dreams', 'scary dream'],
    'The Prophet ﷺ said: "Dreams are of three types: from Allah, from '
    'Shaytan, and from the self. If one of you sees something he dislikes, '
    'let him spit dryly to his left three times and seek refuge in Allah from '
    'its evil, and it will not harm him." (Sahih Muslim 2261). Do not tell '
    'others about bad dreams.',
  ),
  _Entry(
    <String>['ocd', 'waswasa', 'whispers', 'doubts'],
    'The Prophet ﷺ said: "The Shaytan comes to one of you and says: Who '
    'created this? Who created that? Until he says: Who created your Lord? '
    'When that happens, let him seek refuge in Allah and stop." (Sahih '
    'al-Bukhari 3276, Sahih Muslim 134). Waswasa about wudu and prayer is '
    'from Shaytan. Do not repeat acts beyond three times.',
  ),

  // ========== RAMADAN SPECIFICS ==========
  _Entry(
    <String>['laylatul qadr', 'night of decree', 'power night'],
    'Allah says: "Indeed, We sent the Qur\'an down during the Night of Decree. And '
    'what can make you know what is the Night of Decree? The Night of Decree '
    'is better than a thousand months." (Qur\'an 97:1-3). The Prophet ﷺ said: '
    '"Seek it in the last ten nights, on the odd nights." (Sahih al-Bukhari '
    '2017, Sahih Muslim 1169).',
  ),
  _Entry(
    <String>['itikaf', 'spiritual retreat', 'mosque retreat'],
    'The Prophet ﷺ used to perform i\'tikaf (spiritual retreat) in the last '
    'ten days of Ramadan (Sahih al-Bukhari 2025, Sahih Muslim 1172). It involves staying in the masjid with the '
    'intention of worship, abstaining from sins, and increasing in Quran, '
    'dhikr, and dua.',
  ),
  _Entry(
    <String>['zakat ul fitr', 'fitrana', 'eid charity'],
    'The Prophet ﷺ made zakat al-fitr obligatory: a sa\' (approx. 2.5kg) of '
    'dates, barley, wheat, or raisins, or its monetary equivalent. It must '
    'be given before the Eid prayer. He said: "It is a purification for the '
    'fasting person from idle talk and obscenity, and food for the poor." '
    '(Sunan Abi Dawud).',
  ),
  _Entry(
    <String>['breaking fast', 'iftar', 'opening fast'],
    'The Prophet ﷺ said: "The people will remain upon goodness as long as '
    'they hasten to break the fast." (Sahih al-Bukhari 1957, Sahih Muslim '
    '1098). Break with dates and water, saying: "Dhahaba al-zama\'u wa '
    'abtalat al-\'uruq wa thabata al-ajru inshaAllah" (The thirst is gone, '
    'the veins are moistened, and the reward is confirmed, if Allah wills).',
  ),
  _Entry(
    <String>['suhoor', 'sehri', 'pre-dawn meal'],
    'The Prophet ﷺ said: "Eat suhoor, for in suhoor there is blessing." '
    '(Sahih al-Bukhari 1923, Sahih Muslim 1095). The best time is the last '
    'third of the night. Delay it as close to Fajr as possible without '
    'risking eating after the adhan.',
  ),
  _Entry(
    <String>['kaffarah', 'fast expiation', 'broken fast'],
    'Allah says: "And upon those who are able [to fast, but with hardship] '
    '- a ransom [as substitute] of feeding a poor person [each day]." '
    '(Qur\'an 2:184). Scholars call this ransom fidya; ask a scholar whether '
    'it applies to you. For '
    'deliberately breaking a fast without excuse: free a slave, or fast two '
    'consecutive months, or feed sixty poor people. (Sahih al-Bukhari 1936).',
  ),

  // ========== COMMON MISCONCEPTIONS ==========
  _Entry(
    <String>['music', 'singing', 'nasheed', 'songs'],
    'The majority of scholars throughout Islamic history have held that '
    'musical instruments are forbidden, based on numerous hadith. The Prophet '
    'ﷺ said: "From among my Ummah there will be people who will consider '
    'zina, silk, alcohol, and musical instruments as lawful." (Sahih '
    'al-Bukhari 5590). Vocals without instruments (anasheed) are permissible '
    'if the content is wholesome.',
  ),
  _Entry(
    <String>['images', 'photos', 'pictures', 'drawing'],
    'The Prophet ﷺ said that the makers of images will receive the '
    'severest punishment on the Day of Resurrection (Sahih al-Bukhari '
    '5954, Sahih Muslim 2109). Photography of living beings is a matter of scholarly '
    'difference. The majority of contemporary scholars permit it for '
    'necessity (ID, education, journalism).',
  ),
  _Entry(
    <String>['dogs', 'pet dog', 'keeping dog'],
    'The Prophet ﷺ said: "Whoever keeps a dog, except a dog for hunting, '
    'farming, or herding livestock, will have his reward deducted by two '
    'qirats every day." (Sahih al-Bukhari 2322, Sahih Muslim 1574). Dogs are '
    'not impure themselves, but their saliva requires washing (seven times, '
    'one with soil).',
  ),
  _Entry(
    <String>['gold silk men', 'men wear gold', 'men silk'],
    'The Prophet ﷺ said: "Gold and silk have been permitted for the women '
    'of my Ummah and forbidden for the men." (Sunan al-Nasa\'i). Men may not '
    'wear gold rings, chains, or clothing with silk. Women may wear both.',
  ),
  _Entry(
    <String>['beard', 'shave beard', 'trim beard'],
    'The Prophet ﷺ said: "Trim the mustaches and leave the beard." (Sahih '
    'Muslim 259). The majority of scholars consider growing the beard '
    'obligatory for men and shaving it sinful. Trimming it shorter than a '
    'fistful is also discouraged.',
  ),
  _Entry(
    <String>['siwak', 'miswak', 'tooth stick'],
    'The Prophet ﷺ said: "If I did not fear hardship for my Ummah, I would '
    'have commanded them to use the siwak with every prayer." (Sahih '
    'al-Bukhari 887, Sahih Muslim 252). It is a strongly recommended sunnah '
    'before every prayer, before reading Quran, and upon entering home.',
  ),

  // ========== QURAN & MEMORIZATION ==========
  _Entry(
    <String>['tajweed', 'quran recitation', 'pronunciation'],
    'The Prophet ﷺ said: "The one who is proficient in the recitation of '
    'the Qur\'an will be with the honorable and obedient scribes (angels), '
    'and he who recites the Qur\'an and finds it difficult to recite, doing '
    'his best to recite it in the best way possible, will have a double '
    'reward." (Sahih al-Bukhari 4937, Sahih Muslim 798).',
  ),
  _Entry(
    <String>['memorize quran', 'hifz', 'memorization'],
    'The Prophet ﷺ said: "The best of you are those who learn the Qur\'an '
    'and teach it." (Sahih al-Bukhari 5027). For '
    'memorization: (1) read with understanding, (2) repeat each ayah 10 '
    'times, (3) connect ayahs, (4) review daily, (5) recite in prayer.',
  ),
  _Entry(
    <String>['quran adab', 'quran manners', 'reading quran'],
    'When reading the Qur\'an: be in a state of wudu, face the qiblah if '
    'possible, begin with ta\'awwudh (a\'udhu billahi min al-shaytan '
    'al-rajim), read with tartil (measured recitation), and weep or try to '
    'weep. The Prophet ﷺ said: "Recite the Qur\'an, for on the Day of '
    'Resurrection it will come as an intercessor for its companions." (Sahih '
    'Muslim 804).',
  ),
  _Entry(
    <String>['ayat al kursi', 'throne verse', 'greatest verse'],
    'The Prophet ﷺ said: "Whoever recites Ayat al-Kursi at the end of every '
    'obligatory prayer, nothing prevents him from entering Paradise except '
    'death." (Sunan al-Nasa\'i). It is the greatest verse of the Qur\'an '
    '(Qur\'an 2:255), containing the greatest name of Allah.',
  ),
  _Entry(
    <String>['surah ikhlas', 'surah falaq', 'surah nas', 'muawwidhat'],
    'The Prophet ﷺ said: "Say: He is Allah, the One (Ikhlas) and the two '
    'surahs of refuge (Falaq and Nas) in the evening and morning three '
    'times — they will suffice you against everything." (Sunan '
    'al-Tirmidhi). These three surahs are called al-Mu\'awwidhatayn and are '
    'the strongest protection.',
  ),
  _Entry(
    <String>['last two ayahs baqarah', 'baqarah end', 'amana rasul'],
    'The Prophet ﷺ said: "Whoever recites the last two verses of Surah '
    'al-Baqarah at night, they will suffice him." (Sahih al-Bukhari 4008, '
    'Sahih Muslim 808).',
  ),

  // ========== SUNNAH PRACTICES ==========
  _Entry(
    <String>['dua after adhan', 'adhan response', 'call to prayer'],
    'When the mu\'adhin says "Hayya \'ala al-salah" and "Hayya \'ala '
    'al-falah," say: "La hawla wa la quwwata illa billah." After the adhan, '
    'send blessings on the Prophet and say: "Allahumma rabba hadhihi '
    'al-da\'wati al-tammah, wa al-salati al-qaimah, ati Muhammadan '
    'al-wasilata wa al-fadilah, wa b\'athhu maqaman mahmudan alladhi wa\'adtahu." '
    '(Sahih al-Bukhari 614, Sahih Muslim 384).',
  ),
  _Entry(
    <String>['dua between sajdas', 'sujood', 'prostration'],
    'In sujood, say: "Subhana rabbiy al-a\'la" (Glory be to my Lord, the '
    'Most High) at least three times. Between the two sajdas, say: "Rabbi '
    'ighfir li, warhamni, wahdini, wa \'afini, warzuqni" (My Lord, forgive '
    'me, have mercy on me, guide me, grant me well-being, and provide for '
    'me). (Sunan Abi Dawud).',
  ),
  _Entry(
    <String>['tasbih', 'subhanallah', 'glorification'],
    'The Prophet ﷺ said: "Is one of you unable to earn a thousand hasanat '
    'every day?" They said: How? He said: "Say SubhanAllah one hundred '
    'times, and a thousand hasanat are written for him, or a thousand sins '
    'are removed." (Sahih Muslim 2698).',
  ),
  _Entry(
    <String>['tahmid', 'alhamdulillah', 'praise'],
    'The Prophet ﷺ said: "Alhamdulillah fills the scale." (Sahih Muslim '
    '223). Saying it after every blessing — a meal, safety, health — is the '
    'sign of a grateful heart. Allah says: "If you are grateful, I will '
    'surely increase you." (Qur\'an 14:7).',
  ),
  _Entry(
    <String>['takbir', 'allahu akbar', 'magnification'],
    'The Prophet ﷺ said: "For me to say SubhanAllah, walhamdulillah, wa '
    'la ilaha illa Allah, wa Allahu akbar is more beloved to me than '
    'everything the sun rises upon." (Sahih Muslim 2137). These four phrases '
    'are the best dhikr and are called the tasbihat.',
  ),
  _Entry(
    <String>['tahlil', 'la ilaha illallah', 'oneness'],
    'The Prophet ﷺ said: "The best dhikr is La ilaha illa Allah, and the '
    'best supplication is Alhamdulillah." (Sunan al-Tirmidhi). It is the '
    'word of tawhid, the key to Paradise, and the phrase that removes sins '
    'like leaves fall from a tree.',
  ),
  _Entry(
    <String>['salawat', 'durud', 'blessings on prophet'],
    'The Prophet ﷺ said: "Whoever sends blessings upon me once, Allah will '
    'send blessings upon him ten times." (Sahih Muslim 408). The minimum is '
    '"Allahumma salli \'ala Muhammad wa \'ala ali Muhammad." It is said in '
    'tashahhud, after adhan, when hearing his name, and in times of distress.',
  ),
  _Entry(
    <String>['morning adhkar', 'evening adhkar', 'daily adhkar'],
    'The Prophet ﷺ said: "Whoever says in the morning and evening: '
    'Bismillahi alladhi la yadurru ma\'asmihi shay\'un fi al-ardi wa la fi '
    'al-sama\'i, wa huwa al-sami\'u al-\'alim — three times — nothing will '
    'harm him that day or night." (Sunan al-Tirmidhi 3388, hasan per Darussalam).',
  ),

  // ========== HAJJ & UMRAH ==========
  _Entry(
    <String>['hajj', 'pilgrimage', 'fifth pillar'],
    'Allah says: "And [due] to Allah from the people is a pilgrimage to '
    'the House - for whoever is able to find thereto a way." (Qur\'an 3:97). The Prophet ﷺ said: '
    '"Whoever performs Hajj and does not commit any obscenity or '
    'transgression, he returns as the day his mother bore him." (Sahih '
    'al-Bukhari 1521, Sahih Muslim 1350).',
  ),
  _Entry(
    <String>['umrah', 'minor pilgrimage', 'lesser pilgrimage'],
    'The Prophet ﷺ said: "Umrah is an expiation for what comes between it '
    'and the previous Umrah." (Sahih al-Bukhari 1773, Sahih Muslim 1349). It '
    'can be performed any time of year and consists of: ihram, tawaf, sa\'i, '
    'and shaving or trimming the hair.',
  ),
  _Entry(
    <String>['ihram', 'pilgrimage state', 'hajj clothes'],
    'Ihram is the sacred state entered before Hajj or Umrah. For men: two '
    'unstitched white cloths. For women: any modest clothing. Prohibitions '
    'in ihram: cutting hair or nails, wearing perfume, hunting, marital '
    'relations, and arguing. The Prophet ﷺ said: "The Hajj is Arafah." '
    '(Sunan al-Tirmidhi).',
  ),
  _Entry(
    <String>['tawaf', 'circumambulation', 'kaaba'],
    'Tawaf is circling the Kaaba seven times, starting from the Black '
    'Stone, with the Kaaba on the left. The Prophet ﷺ said: "The Black '
    'Stone descended from Paradise whiter than milk, but the sins of the '
    'sons of Adam turned it black." (reported in Jami\' at-Tirmidhi, Book '
    'of Hajj; number and grade not yet verified in this app).',
  ),
  _Entry(
    <String>['saee', 'safa marwa', 'running'],
    'Sa\'i is walking seven times between Safa and Marwa, commemorating '
    'Hajar\'s search for water for Ismail. The Prophet ﷺ said that had '
    'she left the water alone, it would have flowed on the surface of the '
    'earth (Sahih al-Bukhari 3365).',
  ),

  // ========== PROTECTION & SPIRITUAL WARFARE ==========
  _Entry(
    <String>['ruqyah', 'healing verses', 'spiritual healing'],
    'Each night before sleeping the Prophet ﷺ recited Al-Ikhlas, Al-Falaq and '
    'An-Nas into his cupped hands, blew into them and wiped over his body '
    '(Sahih al-Bukhari 5017). Ruqyah is '
    'permissible if: (1) using Allah\'s words or His names, (2) in Arabic or '
    'a language understood, (3) believing the cure is from Allah alone.',
  ),
  _Entry(
    <String>['black magic', 'sihr', 'witchcraft'],
    'Allah says: "And from the evil of the blowers in knots." (Qur\'an '
    '113:4). The Prophet ﷺ was affected by magic (Sahih al-Bukhari 3268, '
    'Sahih Muslim 2189). Treatment: (1) regular adhkar, (2) ruqyah, (3) medical '
    'evaluation for physical symptoms.',
  ),
  _Entry(
    <String>['jinn', 'shaytan', 'devil', 'satan'],
    'Allah says: "Indeed, Satan is an enemy to you; so take him as an '
    'enemy." (Qur\'an 35:6). The Prophet ﷺ said: "Satan runs through the '
    'son of Adam like blood runs through his veins." (Sahih al-Bukhari 3281, '
    'Sahih Muslim 2174). Protection: regular adhkar, seeking refuge before '
    'entering home and before eating, and avoiding sin.',
  ),
  _Entry(
    <String>['hasad', 'evil eye', 'ayn', 'nazar'],
    'The Prophet ﷺ said the evil eye is real (Sahih Muslim 2188). Common '
    'practices, which are advice rather than a ruling: (1) conceal '
    'blessings when possible, (2) say "MashaAllah, la quwwata illa billah," '
    '(3) recite the three Quls morning and evening, (4) ruqyah for the '
    'affected.',
  ),
  _Entry(
    <String>['salah on time', 'prayer punctuality', 'pray on time'],
    'Allah says: "Indeed, prayer has been decreed upon the believers a '
    'decree of specified times." (Qur\'an 4:103). The Prophet ﷺ said: "The '
    'first matter that the slave will be brought to account for on the Day '
    'of Judgment is the prayer. If it is sound, he will be successful." '
    '(Sunan al-Tirmidhi).',
  ),
  _Entry(
    <String>['congregation', 'jamaah', 'praying together', 'group prayer'],
    'The Prophet ﷺ said: "Prayer in congregation is twenty-seven times '
    'better than prayer alone." (Sahih al-Bukhari 645, Sahih Muslim 650). '
    'For men, it is strongly emphasized to pray in the masjid. For women, '
    'praying at home is better but the masjid is permitted.',
  ),
  _Entry(
    <String>['women prayer', 'women masjid', 'ladies prayer'],
    'The Prophet ﷺ said: "Do not prevent the female servants of Allah from '
    'the mosques of Allah." (Sahih al-Bukhari 900, Sahih Muslim 442). Women '
    'have full right to attend the masjid, though praying at home is '
    'considered better for them. They should dress modestly and avoid '
    'perfume.',
  ),
  _Entry(
    <String>['menstruation', 'period', 'menses', 'hayd'],
    'Allah says: "They ask you about menstruation. Say: It is harm, so '
    'keep away from wives during menstruation." (Qur\'an 2:222). A '
    'menstruating woman does not pray or fast (Sahih al-Bukhari 304); '
    'scholars differ on touching the Qur\'an and entering the masjid - '
    'ask a scholar. She makes up missed fasts but not prayers. The Prophet ﷺ '
    'said to Aisha when her period came: "This is something Allah has '
    'decreed for the daughters of Adam." (Sahih al-Bukhari 294).',
  ),
  _Entry(
    <String>['postpartum', 'nifas', 'bleeding after birth'],
    'Postpartum bleeding (nifas) lasts up to forty days. The woman does not '
    'pray or fast during this period. After forty days, if bleeding '
    'continues, it is considered istihadha (irregular bleeding) and she '
    'performs wudu for each prayer. (Fiqh consensus based on Sahih al-Bukhari '
    'and Sahih Muslim).',
  ),
  _Entry(
    <String>['istihadha', 'irregular bleeding', 'spotting'],
    'Istihadha is bleeding outside the normal menstrual cycle. The woman '
    'performs wudu for each prayer time and prays. The Prophet ﷺ told '
    'Fatimah bint Abi Hubaysh that her bleeding was from a vein and not '
    'menstruation: pause the prayer for the days of her real period, then '
    'wash off the blood and pray. (Sahih al-Bukhari 228).',
  ),

  // ========== SOCIAL & COMMUNITY ==========
  _Entry(
    <String>['neighbors', 'rights of neighbor', 'neighbor rights'],
    'The Prophet ﷺ said: "Jibril kept advising me to treat neighbors well '
    'until I thought he would make them heirs." (Sahih al-Bukhari 6014, '
    'Sahih Muslim 2625). Rights include: greeting, helping in need, '
    'protecting their honor, not harming them with noise or smell, and '
    'sharing food.',
  ),
  _Entry(
    <String>['guests', 'hospitality', 'guest rights'],
    'The Prophet ﷺ said: "Whoever believes in Allah and the Last Day, let '
    'him honor his guest." (Sahih al-Bukhari 6018, Sahih Muslim 47). The '
    'sunnah of hospitality: welcome with a smile, offer the best food, do '
    'not ask when they will leave, and escort them to the door.',
  ),
  _Entry(
    <String>['backbiting', 'gossip', 'ghibah', 'slander'],
    'Allah says: "And do not spy or backbite each other. Would one of you '
    'like to eat the flesh of his brother when dead? You would detest it." '
    '(Qur\'an 49:12). The Prophet ﷺ '
    'said: "Backbiting is to mention your brother with what he dislikes." '
    '(Sahih Muslim 2589). Even if true, it is forbidden.',
  ),
  _Entry(
    <String>['lying', 'truth', 'honesty'],
    'The Prophet ﷺ taught that truthfulness leads to righteousness and '
    'righteousness to Paradise, while lying leads to wickedness and '
    'wickedness to the Fire (Sahih al-Bukhari 6094, Sahih Muslim 2607). '
    'He said that whoever reconciles people by saying good is not a liar; '
    'the narrator Ibn Shihab al-Zuhri added that he had not heard lying '
    'permitted except in three cases: war, reconciling people, and speech '
    'between husband and wife (Sahih Muslim 2605).',
  ),
  _Entry(
    <String>['cheating', 'dishonesty', 'fraud', 'deception'],
    'The Prophet ﷺ said: "Whoever cheats us is not one of us." (Sahih '
    'Muslim 101). Cheating in business, exams, or relationships is '
    'forbidden. Allah says: "Woe to those who give less [than due], Who, '
    'when they take a measure from people, take in full, But if they give '
    'by measure or by weight to them, they cause loss." (Qur\'an 83:1-3).',
  ),
  _Entry(
    <String>['forgiveness', 'forgive others', 'let go'],
    'Allah says: "and let them pardon and overlook. Would you not like '
    'that Allah should forgive you?" (Qur\'an 24:22). The Prophet ﷺ said: "The '
    'strong is not the one who overcomes people by his strength, but the '
    'strong is the one who controls himself while in anger." (Sahih '
    'al-Bukhari 6114, Sahih Muslim 2609).',
  ),
  _Entry(
    <String>['gratitude', 'shukr', 'thankful', 'appreciation'],
    'Allah says: "If you are grateful, I will surely increase you." (Qur\'an '
    '14:7). The Prophet ﷺ said: "Whoever is not grateful to people is not '
    'grateful to Allah." (Sunan Abi Dawud 4811, sahih per al-Albani). Gratitude is not just '
    'saying alhamdulillah — it is using blessings in obedience to Allah.',
  ),
  _Entry(
    <String>['sabr', 'patience', 'endurance', 'perseverance'],
    'Allah says: "Indeed, the patient will be given their reward without '
    'account." (Qur\'an 39:10). The Prophet ﷺ said: "Patience is at the '
    'first stroke of calamity." (Sahih al-Bukhari 1302, Sahih Muslim 926). '
    'There are three types: patience in obedience, patience against sin, and '
    'patience in affliction.',
  ),
  _Entry(
    <String>['contentment', 'qanaah', 'satisfied', 'enough'],
    'The Prophet ﷺ said: "Richness is not having many possessions. Rather, '
    'true richness is the richness of the soul." (Sahih al-Bukhari 6446, '
    'Sahih Muslim 1051). Contentment (qana\'ah) is a treasure that no one '
    'can steal.',
  ),
  _Entry(
    <String>['humility', 'tawadu', 'modest', 'humble'],
    'The Prophet ﷺ said: "Whoever humbles himself for Allah, Allah will '
    'raise him." (Sahih Muslim 2588). He was the most humble of people — he '
    'mended his own clothes, milked goats, and sat with the poor.',
  ),
  _Entry(
    <String>['generosity', 'sakhaw', 'giving', 'charitable'],
    'The Prophet ﷺ said: "The generous is close to Allah, close to '
    'Paradise, close to people, and far from the Fire. The miser is far '
    'from Allah, far from Paradise, far from people, and close to the '
    'Fire." (Sunan al-Tirmidhi).',
  ),
  _Entry(
    <String>['courage', 'shajaah', 'brave', 'fearless'],
    'The Prophet ﷺ said: "The strong believer is better and more beloved '
    'to Allah than the weak believer, while there is good in both." (Sahih '
    'Muslim 2664). Courage in Islam is not absence of fear — it is acting '
    'rightly despite fear.',
  ),
  _Entry(
    <String>['wisdom', 'hikmah', 'understanding', 'insight'],
    'Allah says: "He gives wisdom to whom He wills, and whoever has been '
    'given wisdom has certainly been given much good." (Qur\'an 2:269). The '
    'Prophet ﷺ said: "The beginning of wisdom is the fear of Allah." (Sunan '
    'Abi Dawud).',
  ),
  _Entry(
    <String>['justice', 'adl', 'fairness', 'equity'],
    'Allah says: "Indeed, Allah commands you to render trusts to whom they '
    'are due and when you judge between people to judge with justice." '
    '(Qur\'an 4:58). The Prophet ﷺ said: "The just will be with Allah on '
    'pulpits of light." (Sahih Muslim 1827).',
  ),
  _Entry(
    <String>['unity', 'ummah', 'muslim unity', 'brotherhood'],
    'Allah says: "And hold firmly to the rope of Allah all together and do '
    'not become divided." (Qur\'an 3:103). The Prophet ﷺ said: "The '
    'believers in their mutual love, mercy, and compassion are like a single '
    'body." (Sahih al-Bukhari 6011, Sahih Muslim 2586).',
  ),
  _Entry(
    <String>['dawah', 'inviting', 'calling to islam', 'share islam'],
    'Allah says: "Invite to the way of your Lord with wisdom and good '
    'instruction, and argue with them in a way that is best." (Qur\'an 16:125). '
    'The Prophet ﷺ said: "Convey from me even if it is one verse." (Sahih '
    'al-Bukhari 3461).',
  ),
  _Entry(
    <String>['jihad', 'struggle', 'striving'],
    'Allah says: "And strive for Allah with the striving due to Him." '
    '(Qur\'an 22:78). The Prophet ﷺ said: "The best jihad is a word of truth '
    'spoken to a tyrant." (Sunan Abi Dawud). Restraining one\'s own desires '
    'for Allah\'s sake is also a form of striving.',
  ),
  _Entry(
    <String>['caliphate', 'khilafah', 'islamic state', 'political islam'],
    'The Prophet ﷺ said: "The caliphate will remain among my Ummah for '
    'thirty years, then there will be kingship." (Sunan Abi Dawud). The '
    'Rightly Guided Caliphs (Abu Bakr, Umar, Uthman, Ali) are the model. '
    'Political engagement is part of Islam, but must be through legitimate '
    'means.',
  ),
  _Entry(
    <String>['shariah', 'islamic law', 'fiqh'],
    'Shariah is the divine law revealed by Allah. Fiqh is the human '
    'understanding and application of that law. The Prophet ﷺ said: "The '
    'scholars are the heirs of the prophets." (Sunan Abi Dawud). There are '
    'four major schools of fiqh: Hanafi, Maliki, Shafi\'i, and Hanbali.',
  ),
  _Entry(
    <String>['fiqh schools', 'madhab', 'hanafi', 'maliki', 'shafii', 'hanbali'],
    'The four schools are valid paths to the same truth. The Prophet ﷺ '
    'said: Differences between qualified scholars on questions open to '
    'ijtihad are recognised as legitimate, and Muslims are asked to be '
    'gentle with each other about them. A layperson should follow one '
    'school consistently under a qualified teacher.',
  ),
  _Entry(
    <String>['ijtihad', 'scholarly reasoning', 'independent judgment'],
    'Ijtihad is the effort to derive rulings from the Qur\'an and Sunnah. '
    'The Prophet ﷺ said: "When a judge gives a ruling, striving to apply his '
    'reasoning, and is correct, he has two rewards. If he gives a ruling and '
    'errs, he has one reward." (Sahih al-Bukhari 7352, Sahih Muslim 1716).',
  ),
  _Entry(
    <String>['qiyas', 'analogy', 'deductive reasoning'],
    'Qiyas is analogical reasoning: applying a known ruling to a new case '
    'based on a shared underlying cause (\'illah). It is accepted by the '
    'majority of scholars as a source of Islamic law, provided the original '
    'ruling is from the Qur\'an or authentic Sunnah.',
  ),
  _Entry(
    <String>['ijma', 'consensus', 'scholarly agreement'],
    'Ijma is the consensus of the qualified scholars of the Ummah on a '
    'particular issue. The Prophet ﷺ said: "My Ummah will not agree on an '
    'error." (Sunan Ibn Majah).',
  ),
  _Entry(
    <String>['hadith sciences', 'isnad', 'matn', 'hadith authentication'],
    'The Prophet ﷺ said: "May Allah brighten a man who hears something from '
    'us and conveys it as he heard it." (Sunan al-Tirmidhi). Hadith '
    'authentication examines: (1) the chain (isnad), (2) the text (matn), '
    '(3) the narrators\' reliability. Classifications: sahih, hasan, da\'if, '
    'mawdu\'.',
  ),
  _Entry(
    <String>['sahih', 'authentic hadith', 'sound hadith'],
    'Sahih is a hadith with a continuous chain of reliable narrators, free '
    'from defects, and not contradictory to stronger evidence. The most '
    'authentic collections are Sahih al-Bukhari and Sahih Muslim. The '
    'Prophet ﷺ said: "May Allah have mercy on a man who hears a hadith from '
    'us and memorizes it." (Sunan al-Tirmidhi).',
  ),
  _Entry(
    <String>['hasan', 'good hadith', 'fair hadith'],
    'Hasan is a hadith with a continuous chain of narrators who are mostly '
    'reliable but may have slight weaknesses. It is accepted as evidence in '
    'Islamic law. The collections of Sunan al-Tirmidhi, Sunan Abi Dawud, '
    'Sunan al-Nasa\'i, and Sunan Ibn Majah contain many hasan hadiths.',
  ),
  _Entry(
    <String>['daif', 'weak hadith', 'unreliable hadith'],
    'Da\'if is a hadith with a chain containing a narrator who is weak '
    '(unreliable memory, unknown, or accused of lying). It cannot be used as '
    'independent evidence for rulings but may be used for virtues (fada\'il) '
    'and encouragement (targhib).',
  ),
  _Entry(
    <String>['mawdu', 'fabricated hadith', 'fake hadith'],
    'Mawdu is a fabricated hadith, invented and falsely attributed to the '
    'Prophet ﷺ. It is a major sin to fabricate hadith. The Prophet ﷺ said: '
    '"Whoever lies about me intentionally, let him take his seat in the '
    'Fire." (Sahih al-Bukhari 106, Sahih Muslim 3).',
  ),
  _Entry(
    <String>['zina', 'adultery', 'fornication', 'boyfriend', 'girlfriend',
        'relationship before marriage', 'haram relationship', 'talking to a girl',
        'talking to a boy'],
    'Allah says: “And do not approach unlawful sexual intercourse. '
    'Indeed, it is ever an immorality and is evil as a way.” (Qur’an 17:32). The verse '
    'says do not even APPROACH it — so the early steps matter, not only the '
    'last one. And for whatever has already happened, the door of return is '
    'open: “Do not despair of the mercy of Allah — indeed, Allah forgives '
    'all sins.” (Qur’an 39:53). For your specific situation, a trusted local '
    'scholar can walk with you privately.',
  ),
];
