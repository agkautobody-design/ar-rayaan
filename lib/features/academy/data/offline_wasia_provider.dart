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

  @override
  Future<String> ask(String question, List<HadiMessage> history) async {
    final String q = ' ' + question.toLowerCase().trim() + ' ';
    int bestScore = 0;
    String bestAnswer = decline;
    for (final _Entry e in _knowledge) {
      int score = 0;
      for (final String k in e.keywords) {
        if (q.contains(k)) score += k.length;
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
  // Letter 1 of 28
  _Entry(<String>['alif', 'letter alif', 'the alif'],
    'Alif (ا) — From the empty space of the mouth — open it fully. You meet it in words like الله. Open the Letters school in the Academy and tap 'Alif' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 2 of 28
  _Entry(<String>['ba', 'baa', 'letter ba', 'the ba'],
    'Bā (ب) — Both lips together. You meet it in words like بِسْمِ. Open the Letters school in the Academy and tap 'Bā' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 3 of 28
  _Entry(<String>['ta', 'taa', 'letter ta', 'the ta'],
    'Tā (ت) — Tip of the tongue to the upper front teeth. You meet it in words like تَبَّتْ. Open the Letters school in the Academy and tap 'Tā' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 4 of 28
  _Entry(<String>['tha', 'letter tha', 'the tha'],
    'Thā (ث) — Tongue tip between the front teeth (gentle). You meet it in words like ثُمَّ. Open the Letters school in the Academy and tap 'Thā' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 5 of 28
  _Entry(<String>['jim', 'jeem', 'letter jim', 'the jim'],
    'Jīm (ج) — Middle of the tongue with the palate. You meet it in words like جَنَّة. Open the Letters school in the Academy and tap 'Jīm' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 6 of 28
  _Entry(<String>['ha deep', 'deep ha', 'Ḥā', 'heavy ha', 'letter ḥā', 'the ḥā'],
    'Ḥā (ḥ) — Deep in the throat, a gentle breath. You meet it in words like الرَّحْمَٰن. Open the Letters school in the Academy and tap 'Ḥā' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 7 of 28
  _Entry(<String>['kha', 'letter kha', 'the kha'],
    'Khā (خ) — Back of the tongue to the soft palate. You meet it in words like خَلَقَ. Open the Letters school in the Academy and tap 'Khā' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 8 of 28
  _Entry(<String>['dal', 'daal', 'letter dal', 'the dal'],
    'Dāl (د) — Tongue tip to the upper teeth (heavy). You meet it in words like دِين. Open the Letters school in the Academy and tap 'Dāl' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 9 of 28
  _Entry(<String>['dhal', 'dhaal', 'letter dhal', 'the dhal'],
    'Dhāl (ذ) — Tongue tip between the teeth (heavy). You meet it in words like ذَٰلِك. Open the Letters school in the Academy and tap 'Dhāl' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 10 of 28
  _Entry(<String>['ra '],
    'Rā (ر) — Tongue tip vibrates against the palate. You meet it in words like رَبِّ. Open the Letters school in the Academy and tap 'Rā' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 11 of 28
  _Entry(<String>['zay', 'zain', 'letter zay', 'the zay'],
    'Zāy (ز) — Tongue tip to the teeth, voiced. You meet it in words like زَكَاة. Open the Letters school in the Academy and tap 'Zāy' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 12 of 28
  _Entry(<String>['sin '],
    'Sīn (س) — Tongue tip near the teeth, a whistle. You meet it in words like سَمَاء. Open the Letters school in the Academy and tap 'Sīn' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 13 of 28
  _Entry(<String>['shin', 'letter shin', 'the shin'],
    'Shīn (ش) — Tongue with the palate, wide. You meet it in words like شَمْس. Open the Letters school in the Academy and tap 'Shīn' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 14 of 28
  _Entry(<String>['sad heavy', 'heavy sad', 'ṣad', 'suad', 'letter ṣad', 'the ṣad'],
    'Ṣād (ص) — Heavy: tongue flat, lips rounded. You meet it in words like صَلَاة. Open the Letters school in the Academy and tap 'Ṣād' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 15 of 28
  _Entry(<String>['dad heavy', 'heavy dad', 'ḍad', 'duad', 'letter ḍad', 'the ḍad'],
    'Ḍād (ض) — Heavy: tongue side pressed to the molars. You meet it in words like ضَالَّ. Open the Letters school in the Academy and tap 'Ḍād' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 16 of 28
  _Entry(<String>['ta heavy', 'heavy ta', 'ṭa', 'toa', 'letter ṭa', 'the ṭa'],
    'Ṭā (ط) — Heavy: tongue tip to the gums firmly. You meet it in words like طَيِّبَة. Open the Letters school in the Academy and tap 'Ṭā' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 17 of 28
  _Entry(<String>['za heavy', 'dha heavy', 'ẓa', 'zoha', 'letter ẓa', 'the ẓa'],
    'Ẓā (ظ) — Heavy: tongue tip between the teeth. You meet it in words like ظَهَرَ. Open the Letters school in the Academy and tap 'Ẓā' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 18 of 28
  _Entry(<String>['ayn', 'ain', 'letter ayn', 'the ayn'],
    'ʿAyn (ع) — Middle of the throat, voiced. You meet it in words like عِلْم. Open the Letters school in the Academy and tap 'ʿAyn' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 19 of 28
  _Entry(<String>['ghayn', 'ghain', 'letter ghayn', 'the ghayn'],
    'Ghayn (غ) — Back of the throat, voiced growl. You meet it in words like غَفُور. Open the Letters school in the Academy and tap 'Ghayn' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 20 of 28
  _Entry(<String>['fa '],
    'Fā (ف) — Lower lip to the upper front teeth. You meet it in words like فِي. Open the Letters school in the Academy and tap 'Fā' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 21 of 28
  _Entry(<String>['qaf', 'letter qaf', 'the qaf'],
    'Qāf (ق) — Back of the tongue to the soft palate. You meet it in words like قُلْ. Open the Letters school in the Academy and tap 'Qāf' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 22 of 28
  _Entry(<String>['kaf', 'letter kaf', 'the kaf'],
    'Kāf (ك) — Tongue to the palate, lighter than qāf. You meet it in words like كِتَاب. Open the Letters school in the Academy and tap 'Kāf' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 23 of 28
  _Entry(<String>['lam', 'laam', 'letter lam', 'the lam'],
    'Lām (ل) — Tongue tip to the palate, flowing. You meet it in words like لِلَّه. Open the Letters school in the Academy and tap 'Lām' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 24 of 28
  _Entry(<String>['mim', 'meem', 'letter mim', 'the mim'],
    'Mīm (م) — Both lips closed, humming. You meet it in words like مُحَمَّد. Open the Letters school in the Academy and tap 'Mīm' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 25 of 28
  _Entry(<String>['nun', 'letter nun', 'the nun'],
    'Nūn (ن) — Tongue tip to the gums, voiced. You meet it in words like نُور. Open the Letters school in the Academy and tap 'Nūn' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 26 of 28
  _Entry(<String>['ha light', 'light ha', 'soft ha', 'hā '],
    'Hā (ه) — A light breath from the throat. You meet it in words like هُوَ. Open the Letters school in the Academy and tap 'Hā' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 27 of 28
  _Entry(<String>['waw', 'waww', 'letter waw', 'the waw'],
    'Wāw (و) — Lips rounded, then opened. You meet it in words like وَ. Open the Letters school in the Academy and tap 'Wāw' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),
  // Letter 28 of 28
  _Entry(<String>['ya '],
    'Yā (ي) — Middle of the tongue to the palate. You meet it in words like يَوْم. Open the Letters school in the Academy and tap 'Yā' — you will see the letter, hear it in a verse, and practice it step by step. Say its name three times, slowly. Which letter did you learn just before this one?',
  ),

  // --- The curriculum: units, exams, pacing --------------------------------

  _Entry(<String>['what do you teach', 'what can you teach', 'curriculum',
      'what is the academy', 'about the academy', 'wasia academy'],
    'Al-Wasia Academy teaches the letters of the Qur’an, one gentle step at a '
    'time: 28 letters in 4 units, each unit ending with an exam. There are '
    'also word decks, tajweed cards, and a du’a school in the Academy. '
    'Which would you like to explore — letters, words, or du’as?',
  ),
  _Entry(<String>['how many lessons', 'how many letters', 'how long',
      'how many units', 'structure'],
    'The letters school has 28 lessons in 4 units of 7 lessons each — Unit 1 '
    '“The First Letters”, Unit 2 “The Middle Letters”, Unit 3 “The Deep '
    'Letters”, Unit 4 “The Final Letters”. One short lesson a day is a '
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
    'with their name, and the Academy keeps their lessons and exams for '
    'them. Every lesson they finish and every exam they take is recorded '
    'under their name. Would you like me to walk you through what the '
    'Family Wing shows?',
  ),
  _Entry(<String>['progress', 'how is my child doing', 'report', 'how do i '
      'see', 'track'],
    'The Family Wing in the Academy shows each child’s lessons completed and '
    'exam results — it updates as they learn. You can open it any time and '
    'see exactly where your child stands. What is your child’s name, so I '
    'can encourage them properly?',
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
    'four units yet?',
  ),
  _Entry(<String>['no sound', 'audio not working', 'hear it', 'listening'],
    'Every letter lesson has a “hear it” — a short verified verse where the '
    'letter sounds. If sound is off, the settings screen has the sound '
    'toggle at the very top. Shall we try one letter together right now?',
  ),
];
