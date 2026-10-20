/// Offline Wasia — the Academy's own curated knowledge, always available,
/// no key, no network. Wasia never borrows Hādi's shelf: children ask about
/// letters, lessons, and exams, so her brain is the curriculum itself —
/// the 28 letters (from letters_data.dart), the 4 units and their exams
/// (from letters_curriculum.json), and the parent FAQ. She teaches, praises
/// effort, ends with a tiny question — and when something is beyond her
/// shelf she says so honestly and points to Hādi or a human teacher.
library;

import '../../hadi/application/hadi_provider.dart';

class OfflineWasiaProvider implements HadiProvider {
  const OfflineWasiaProvider();

  static const String decline =
      'That is beyond what I can teach from my lesson shelf, and I would '
      'rather not guess. Hādi in the app answers questions about worship '
      'and daily life — or ask a teacher you trust. Shall we get back to '
      'your letters?';

  static final RegExp _wordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// Lower-cases, turns every non-letter/digit into a space and squeezes
  /// spaces, so keywords match WHOLE WORDS: the old substring test fired
  /// "ba" inside "about" and "ta" inside "start".
  static String normalise(String input) {
    final StringBuffer b = StringBuffer(' ');
    bool lastSpace = true;
    for (final int r in input.toLowerCase().runes) {
      final String ch = String.fromCharCode(r);
      final bool word = _wordChar.hasMatch(ch);
      if (word) {
        b.write(ch);
        lastSpace = false;
      } else if (!lastSpace) {
        b.write(' ');
        lastSpace = true;
      }
    }
    if (!lastSpace) b.write(' ');
    return b.toString();
  }

  /// True when [keyword] occurs in [normalisedQuestion] as whole word(s).
  static bool matches(String normalisedQuestion, String keyword) {
    final String k = normalise(keyword).trim();
    if (k.isEmpty) return false;
    return normalisedQuestion.contains(' $k ');
  }

  @override
  Future<String> ask(String question, List<HadiMessage> history) async {
    final String q = normalise(question);
    int bestScore = 0;
    String bestAnswer = decline;
    for (final _Entry e in _knowledge) {
      int score = 0;
      for (final String k in e.keywords) {
        if (matches(q, k)) score += k.trim().length;
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
  // Makharij follow the standard classification (throat / tongue / lips,
  // heavy letters). Pending review by a qualified reader; the answer below
  // tells the learner to practise with a teacher.
  // Letter 1 of 28
  _Entry(<String>['alif', 'letter alif', 'the alif'],
    'Alif (ا) — Its sound comes from the empty space of the mouth and throat (al-jawf). Open the Letters school in the Academy and start the lesson for Alif: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 2 of 28
  _Entry(<String>['ba', 'baa', 'letter ba', 'the ba'],
    'Bā (ب) — It is made with both lips together. Open the Letters school in the Academy and start the lesson for Bā: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 3 of 28
  _Entry(<String>['ta', 'taa', 'letter ta', 'the ta'],
    'Tā (ت) — It is made with the tip of the tongue touching the gum just above the upper front teeth. Open the Letters school in the Academy and start the lesson for Tā: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 4 of 28
  _Entry(<String>['tha', 'letter tha', 'the tha'],
    'Thā (ث) — It is made with the tip of the tongue just touching the edge of the upper front teeth. Open the Letters school in the Academy and start the lesson for Thā: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 5 of 28
  _Entry(<String>['jim', 'jeem', 'letter jim', 'the jim'],
    'Jīm (ج) — It is made with the middle of the tongue rising to the roof of the mouth. Open the Letters school in the Academy and start the lesson for Jīm: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 6 of 28
  _Entry(<String>['ha deep', 'deep ha', 'ḥā', 'heavy ha', 'letter ḥā', 'the ḥā'],
    'Ḥā (ح) — It is made in the middle of the throat. Open the Letters school in the Academy and start the lesson for Ḥā: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 7 of 28
  _Entry(<String>['kha', 'letter kha', 'the kha'],
    'Khā (خ) — It is made at the top of the throat, nearest the mouth, and it is a heavy letter. Open the Letters school in the Academy and start the lesson for Khā: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 8 of 28
  _Entry(<String>['dal', 'daal', 'letter dal', 'the dal'],
    'Dāl (د) — It is made with the tip of the tongue touching the gum above the upper front teeth. Open the Letters school in the Academy and start the lesson for Dāl: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 9 of 28
  _Entry(<String>['dhal', 'dhaal', 'letter dhal', 'the dhal'],
    'Dhāl (ذ) — It is made with the tip of the tongue at the edge of the upper front teeth. Open the Letters school in the Academy and start the lesson for Dhāl: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 10 of 28
  _Entry(<String>['ra', 'letter ra', 'the ra'],
    'Rā (ر) — It is made with the tip of the tongue touching the roof of the mouth a little behind the front teeth. Open the Letters school in the Academy and start the lesson for Rā: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 11 of 28
  _Entry(<String>['zay', 'zain', 'letter zay', 'the zay'],
    'Zāy (ز) — It is made with the tip of the tongue near the lower front teeth, with a buzzing sound. Open the Letters school in the Academy and start the lesson for Zāy: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 12 of 28
  _Entry(<String>['sin', 'seen', 'letter sin', 'the sin'],
    'Sīn (س) — It is made with the tip of the tongue near the lower front teeth, with a hissing breath. Open the Letters school in the Academy and start the lesson for Sīn: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 13 of 28
  _Entry(<String>['shin', 'sheen', 'letter shin', 'the shin'],
    'Shīn (ش) — It is made with the middle of the tongue against the roof of the mouth, the breath spreading out. Open the Letters school in the Academy and start the lesson for Shīn: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 14 of 28
  _Entry(<String>['sad heavy', 'heavy sad', 'ṣad', 'suad', 'letter ṣad', 'the ṣad'],
    'Ṣād (ص) — It is a heavy letter: the back of the tongue rises towards the roof of the mouth, so the sound is full. Open the Letters school in the Academy and start the lesson for Ṣād: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 15 of 28
  _Entry(<String>['dad heavy', 'heavy dad', 'ḍad', 'duad', 'letter ḍad', 'the ḍad'],
    'Ḍād (ض) — It is a heavy letter, made with the side of the tongue against the upper molars. Open the Letters school in the Academy and start the lesson for Ḍād: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 16 of 28
  _Entry(<String>['ta heavy', 'heavy ta', 'ṭa', 'toa', 'letter ṭa', 'the ṭa'],
    'Ṭā (ط) — It is a heavy letter: the tongue tip touches where Tā does, but the tongue rises and the sound is full. Open the Letters school in the Academy and start the lesson for Ṭā: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 17 of 28
  _Entry(<String>['za heavy', 'dha heavy', 'ẓa', 'zoha', 'letter ẓa', 'the ẓa'],
    'Ẓā (ظ) — It is a heavy letter: the tongue tip is at the edge of the upper front teeth and the tongue rises. Open the Letters school in the Academy and start the lesson for Ẓā: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 18 of 28
  _Entry(<String>['ayn', 'ain', 'letter ayn', 'the ayn'],
    'ʿAyn (ع) — It is made in the middle of the throat. Open the Letters school in the Academy and start the lesson for ʿAyn: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 19 of 28
  _Entry(<String>['ghayn', 'ghain', 'letter ghayn', 'the ghayn'],
    'Ghayn (غ) — It is made at the top of the throat, nearest the mouth, and it is a heavy letter. Open the Letters school in the Academy and start the lesson for Ghayn: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 20 of 28
  _Entry(<String>['fa', 'letter fa', 'the fa'],
    'Fā (ف) — It is made with the upper front teeth touching the inside of the lower lip. Open the Letters school in the Academy and start the lesson for Fā: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 21 of 28
  _Entry(<String>['qaf', 'letter qaf', 'the qaf'],
    'Qāf (ق) — It is a heavy letter, made at the very back of the tongue against the soft palate. Open the Letters school in the Academy and start the lesson for Qāf: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 22 of 28
  _Entry(<String>['kaf', 'letter kaf', 'the kaf'],
    'Kāf (ك) — It is made with the back of the tongue, a little further forward than Qāf. Open the Letters school in the Academy and start the lesson for Kāf: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 23 of 28
  _Entry(<String>['lam', 'laam', 'letter lam', 'the lam'],
    'Lām (ل) — It is made with the edge of the tongue against the gum above the upper front teeth. Open the Letters school in the Academy and start the lesson for Lām: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 24 of 28
  _Entry(<String>['mim', 'meem', 'letter mim', 'the mim'],
    'Mīm (م) — It is made with both lips together, with a hum through the nose. Open the Letters school in the Academy and start the lesson for Mīm: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 25 of 28
  _Entry(<String>['nun', 'letter nun', 'the nun'],
    'Nūn (ن) — It is made with the tip of the tongue touching the gum above the upper front teeth, with a hum through the nose. Open the Letters school in the Academy and start the lesson for Nūn: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 26 of 28
  _Entry(<String>['ha light', 'light ha', 'soft ha', 'hā'],
    'Hā (ه) — It is made at the bottom of the throat, a light easy breath. Open the Letters school in the Academy and start the lesson for Hā: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 27 of 28
  _Entry(<String>['waw', 'waww', 'letter waw', 'the waw'],
    'Wāw (و) — It is made by rounding the lips. Open the Letters school in the Academy and start the lesson for Wāw: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 28 of 28
  _Entry(<String>['ya', 'letter ya', 'the ya'],
    'Yā (ي) — It is made with the middle of the tongue rising towards the roof of the mouth. Open the Letters school in the Academy and start the lesson for Yā: you will see the letter, practise it and answer a gentle question. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),

  // --- The curriculum: units, exams, pacing --------------------------------

  _Entry(<String>['what do you teach', 'what can you teach', 'curriculum',
      'what is the academy', 'about the academy', 'wasia academy'],
    'Al-Wasia Academy teaches the letters of the Qur’an, one gentle step at a '
    'time: 28 letters in 4 units, then 3 more units on short and long '
    'vowels, sukun, shaddah, tanween and joining letters into words, each '
    'unit ending with an exam. There are also word decks, tajweed cards, and a du’a school in the Academy. '
    'Which would you like to explore — letters, words, or du’as?',
  ),
  _Entry(<String>['how many lessons', 'how many letters', 'how long',
      'how many units', 'structure'],
    'The letters school has 40 lessons in 7 units — Unit 1 “The First Letters”, '
    'Unit 2 “The Middle Letters”, Unit 3 “The Deep Letters”, Unit 4 “The '
    'Final Letters” (the 28 letters, 7 lessons each), then Unit 5 “Short and '
    'Long Vowels”, Unit 6 “Sukun, Shaddah and Tanween” and Unit 7 “Joining '
    'Letters into Words”. One short lesson a day is a '
    'beautiful pace. Would you like to know what today’s lesson could be?',
  ),
  _Entry(<String>['unit 1', 'first letters', 'exam 1'],
    'Unit 1 — “The First Letters” — is the first 7 lessons of the letters '
    'school, and it ends with the Unit 1 exam: 10 questions, pass mark 7. '
    'The exam gently checks the letter shapes and names. Is your student '
    'ready to try the first unit?',
  ),
  _Entry(<String>['unit 2', 'middle letters', 'exam 2'],
    'Unit 2 — “The Middle Letters” — lessons 8 to 14, ending with the Unit 2 '
    'exam (10 questions, pass mark 7). It builds directly on Unit 1, so the '
    'letters from the first unit keep appearing. Shall we check how Unit 1 '
    'went first?',
  ),
  _Entry(<String>['unit 3', 'deep letters', 'exam 3'],
    'Unit 3 — “The Deep Letters” — lessons 15 to 21, ending with the Unit 3 '
    'exam (10 questions, pass mark 7). These letters come from deeper in the '
    'mouth and throat, so they take a little more practice — and that is '
    'completely normal. Which deep letter is hardest right now?',
  ),
  _Entry(<String>['unit 4', 'final letters', 'exam 4', 'last unit'],
    'Unit 4 — “The Final Letters” — the last 7 lessons, ending with the Unit '
    '4 exam (10 questions, pass mark 7). After this exam the whole alphabet '
    'is known, and the word decks are the next adventure. How far along is '
    'your student?',
  ),
  _Entry(<String>['exam', 'test', 'quiz', 'how do exams work', 'pass mark'],
    'Each unit ends with a small exam: 10 gentle questions about the letter '
    'shapes and names, and a student passes with 7 correct. It is not a '
    'judgement — it only shows which letters want one more visit. In the '
    'Family Wing you can see every exam result for each child. Would you '
    'like to know where the Family Wing is?',
  ),
  _Entry(<String>['struggling', 'hard time', 'difficult', 'can’t remember',
      'cant remember', 'keeps forgetting', 'frustrated', 'gave up'],
    'Struggling with a letter is not failure — it is the letter asking for '
    'one more gentle meeting. Keep the lessons short: five minutes of '
    'looking, saying, and hearing beats an hour of pushing. Praise the '
    'effort, not the result — children learn letters the way they learn '
    'walking. Which letter is being stubborn today?',
  ),
  _Entry(<String>['joining', 'connected', 'letters together', 'join letters'],
    'Letters change their shape a little when they join into words — that is '
    'the next skill after the alphabet is known. The word decks in the '
    'Academy practice exactly that: real words from the Qur’an, slowly. Has '
    'your student finished all four units yet?',
  ),

  // --- Parent & teacher FAQ -------------------------------------------------

  _Entry(<String>['add a child', 'new child', 'register my child',
      'create profile', 'family wing'],
    'Open the Academy and go to the Family Wing — there you add each child '
    'with a first name or nickname, and the Academy keeps their lessons and '
    'exams for them on this device only. Nothing is sent anywhere, and you '
    'can delete a child at any time. Would you like me to walk you through what the '
    'Family Wing shows?',
  ),
  _Entry(<String>['progress', 'how is my child doing', 'report', 'how do i '
      'see', 'track'],
    'The Family Wing in the Academy shows each child’s lessons completed and '
    'exam results — it updates as they learn. You can open it any time and '
    'see exactly where your child stands. What would you like to practise with them first?',
  ),
  _Entry(<String>['homeschool', 'teach at home', 'classroom', 'teacher',
      'pedagogy', 'sequence'],
    'For teaching at home: one short lesson a day, letters in the Academy’s '
    'order (they are sequenced the classical Qaida way), review yesterday’s '
    'letter before the new one, and celebrate small wins loudly. Exams come '
    'at the end of each unit — give them when the child feels ready, not '
    'before. How old is your student?',
  ),
  _Entry(<String>['three voices', 'personas', 'student voice', 'parent voice',
      'teacher voice', 'who are you'],
    'I am Wasia, the teacher of the letters school — the Academy is named '
    'after the founder’s daughter. I speak in three voices: with students I '
    'teach letters, with parents I explain progress and encourage, and with '
    'teachers and homeschoolers I share how to sequence the lessons. Which '
    'voice do you need today?',
  ),
  _Entry(<String>['tajweed', 'pronunciation', 'makhraj', 'sound of'],
    'Tajweed means giving every letter its right — its own sound and its own '
    'place in the mouth. The letters school teaches each letter’s sound with '
    'a short verse you can hear. The Tajweed Cards in the Academy practice '
    'the rules step by step. Would you like to start with the letters first?',
  ),
  _Entry(<String>['word deck', 'words', 'practice words', 'vocabulary'],
    'The Word Decks in the Academy practice reading real words from the '
    'Qur’an — short ones first, always with meaning. They are the perfect '
    'next step after the 28 letters are known. Has your student met all '
    'seven units yet?',
  ),
  _Entry(<String>['no sound', 'audio not working', 'hear it', 'listening'],
    'Every letter lesson has a “hear it” — a short verified verse where the '
    'letter sounds. If sound is off, the settings screen has the sound '
    'toggle at the very top. Shall we try one letter together right now?',
  ),

  // The wider academy — parents ask, Wasia points
  _Entry(<String>['where can i learn about', 'teach me about', 'school for',
      'academy school', 'what schools', 'more schools'],
    'The Academy holds twenty-one schools covering every subject — prayer, Arabic,'
    ' du\'as, stories, character, family life, and more. Open the Academy home'
    ' from the gate to see them all. For your letters, stay here with me — but'
    ' for anything beyond, there is a school for it.',
  ),
  _Entry(<String>['q&a', 'questions and answers', 'faq', 'frequently asked',
      'common questions'],
    'The Q&A Bank in the Academy answers the twelve questions every Muslim'
    ' asks — fasting, mortgages, missed prayers, and more, all with their'
    ' sources. Shall we get back to your letters?',
  ),
  _Entry(<String>['duas for', 'where are the duas', 'hisn', 'fortress',
      'morning duas', 'evening duas'],
    'Hisn al-Muslim in the Academy holds every authentic dua — morning and'
    ' evening, for travel, for hardship, for protection. The Du\'a School'
    ' teaches what they mean. Shall I tell you about the one for today?',
  ),
  _Entry(<String>['ramadan', 'fasting month', 'taraweeh', 'suhoor'],
    'Ramadan Mode in the app walks the whole month — the pillars, the daily'
    ' rhythm, and the duas of suhoor and iftar. I keep to my letters, but'
    ' the month is well-taught there.',
  ),
];
