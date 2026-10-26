/// The learning games: Seerah, Prophets, Hadith, Wudu and Salah steps,
/// Arabic Words, Word Search and Word Scramble, and the games that are
/// registered but hidden because the verified content they need is not in
/// the app yet.
///
/// Every game here is fed only from content already in the app. Each question
/// or round shows its source and an explanation after the answer. Nothing is
/// scored by worship, nothing is timed, and hints are free. Nothing is rated:
/// there are no ratings or popularity counts.
///
/// A hidden game is not listed in the hub and has no page. What it needs is
/// written in `docs/content_needed/GAMES_CONTENT_NEEDED.md`; `test/games/
/// learning_games_test.dart` checks that every hidden game is named there.
///
/// Pure Dart (no Flutter).
library;

import 'game_registry.dart';

/// The learning games, in hub order.
const List<GameDef> kLearningGames = <GameDef>[
  GameDef(
    id: 'seerah',
    title: 'Seerah Challenge',
    blurb: 'Questions from the Seerah School, each with its source',
    category: GameCategory.islamic,
    modes: <PlayMode>{PlayMode.solo, PlayMode.passAndPlay},
    route: '/games/g/seerah',
    iconKey: 'seerah',
    kind: GameEngineKind.quiz,
    maxPlayers: 4,
    hasSetup: true,
    hasQuestions: true,
    hasHints: true,
    sourceNote: 'Every question is checked against the words of a story in '
        'the Seerah School, and after you answer it shows that story’s own '
        'source lines. The stories are marked as not yet scholar-reviewed. '
        'No images of any prophet are used.',
    howToPlay: <String>[
      'Choose how many questions.',
      'Pick the answer you think is right. There is no timer.',
      'After each answer you see the source and a short explanation.',
      'A hint hides two wrong answers. You get three free hints a game.',
    ],
  ),
  GameDef(
    id: 'seerah-timeline',
    title: 'Seerah Timeline',
    blurb: 'Put the events of the Seerah in the order they happened',
    category: GameCategory.islamic,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/g/seerah-timeline/play',
    iconKey: 'timeline',
    kind: GameEngineKind.order,
    sourceNote: 'The events are the Seerah School’s own stories, asked in '
        'the order the School tells them. After each round you see the words '
        'of each story and its source.',
    howToPlay: <String>[
      'Use the up and down buttons to move the cards.',
      'Tap Check. A wrong check costs nothing; try again.',
      'A hint puts one card in its place. You get three free hints a game.',
      'There is no timer.',
    ],
  ),
  GameDef(
    id: 'prophets-order',
    title: 'Prophets in Order',
    blurb: 'Who came first? Only orders the Messengers’ tree states',
    category: GameCategory.islamic,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/g/prophets-order/play',
    iconKey: 'tree',
    kind: GameEngineKind.order,
    sourceNote: 'Built from the Messengers’ tree in the Family section. Only '
        'orders the tree states are asked: Adam first, Muhammad ﷺ the Seal '
        'of the Prophets, and fathers before their sons. There are no dates '
        'and no images of any prophet.',
    howToPlay: <String>[
      'Use the up and down buttons to move the cards.',
      'Tap Check. A wrong check costs nothing; try again.',
      'After each round you see why the order is right, and the source.',
      'There is no timer.',
    ],
  ),
  GameDef(
    id: 'hadith',
    title: 'Hadith Knowledge',
    blurb: 'Finish the hadith, name its collection, find its number',
    category: GameCategory.islamic,
    modes: <PlayMode>{PlayMode.solo, PlayMode.passAndPlay},
    route: '/games/g/hadith',
    iconKey: 'hadith',
    kind: GameEngineKind.quiz,
    maxPlayers: 4,
    hasSetup: true,
    hasQuestions: true,
    hasHints: true,
    sourceNote: 'Every question is built from the Forty Hadith of Imam '
        'an-Nawawi bundled in the app. After you answer you see the number, '
        'the collection an-Nawawi names, and the grade with the person who '
        'gave it. A report with no named grader is never asked.',
    howToPlay: <String>[
      'Choose how many questions.',
      'Pick the answer you think is right. There is no timer.',
      'After each answer you see the hadith number, collection and grade.',
      'A hint hides two wrong answers. You get three free hints a game.',
    ],
  ),
  GameDef(
    id: 'salah-wudu',
    title: 'Wudu and Salah Steps',
    blurb: 'Put the steps of wudu or the prayer in order',
    category: GameCategory.islamic,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/g/salah-wudu/play',
    iconKey: 'steps',
    kind: GameEngineKind.order,
    hasSetup: true,
    sourceNote: 'The steps are the Huda guides “Wudu” and “How to Pray” in '
        'the app, in the guide’s own order, with the guide’s own sources. The '
        'app does not give them as any one school’s way; the guide’s note on '
        'schools of law is shown with each round.',
    howToPlay: <String>[
      'Choose wudu or the prayer.',
      'Use the up and down buttons to move the cards.',
      'Tap Check. A wrong check costs nothing; try again.',
      'After each round you see the guide’s words and sources.',
    ],
  ),
  GameDef(
    id: 'arabic-words',
    title: 'Arabic Words',
    blurb: 'Match the Names and the letters of the alphabet',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo, PlayMode.passAndPlay},
    route: '/games/g/arabic-words',
    iconKey: 'letters',
    kind: GameEngineKind.quiz,
    maxPlayers: 4,
    hasSetup: true,
    hasQuestions: true,
    hasHints: true,
    sourceNote: 'Only the 99 Names list and the 28-letter alphabet lessons '
        'in the app are used. Words whose meaning is not sourced in the app '
        'are never used. For meanings, open The 99 Names or Names Memory.',
    howToPlay: <String>[
      'Choose Names, letters, or both, and how many questions.',
      'Match the Arabic to its name, or the name to its Arabic.',
      'After each answer you see the meaning or the lesson it comes from.',
      'A hint hides two wrong answers. You get three free hints a game.',
    ],
  ),
  GameDef(
    id: 'wordsearch',
    title: 'Word Search',
    blurb: 'Find the words of the Huda guides hidden in the grid',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/g/wordsearch/play',
    iconKey: 'grid',
    kind: GameEngineKind.words,
    sourceNote: 'The words and their plain meanings come from the glossary '
        'of the Huda guides. No Name of Allah is hidden in a puzzle.',
    howToPlay: <String>[
      'Tap the first letter of a word, then its last letter.',
      'Words run across, down, or diagonally down and to the right.',
      'Each word you find shows its meaning.',
      'A hint marks where a word starts. Hints are free. There is no timer.',
    ],
  ),
  GameDef(
    id: 'scramble',
    title: 'Word Scramble',
    blurb: 'Put the letters back in order, with the meaning as a clue',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/g/scramble/play',
    iconKey: 'letters',
    kind: GameEngineKind.words,
    sourceNote: 'The words and their plain meanings come from the glossary '
        'of the Huda guides. No Name of Allah is scrambled.',
    howToPlay: <String>[
      'Read the meaning, then tap the letters in the right order.',
      'Tap a placed letter to take it back.',
      'A hint puts the next right letter down. Hints are free.',
      'There is no timer.',
    ],
  ),

  // ---- Registered but hidden: the verified content is not in the app. ----
  GameDef(
    id: 'islamic-history',
    title: 'Islamic History',
    blurb: 'Dated events after the Seerah',
    category: GameCategory.islamic,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games',
    iconKey: 'timeline',
    kind: GameEngineKind.own,
    hidden: true,
    sourceNote: 'Hidden until a dated, sourced list of events is supplied.',
    howToPlay: <String>['Not available yet.'],
  ),
  GameDef(
    id: 'seerah-scenarios',
    title: 'Seerah: How Would You Respond?',
    blurb: 'Choices in the footsteps of the Prophet ﷺ',
    category: GameCategory.islamic,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games',
    iconKey: 'seerah',
    kind: GameEngineKind.own,
    hidden: true,
    sourceNote: 'Hidden until a scholar supplies the situations and answers.',
    howToPlay: <String>['Not available yet.'],
  ),
  GameDef(
    id: 'arabic-spelling',
    title: 'Arabic Spelling',
    blurb: 'Spell Arabic words with the audio',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games',
    iconKey: 'letters',
    kind: GameEngineKind.own,
    hidden: true,
    sourceNote: 'Hidden until a word list with sourced meanings and licensed '
        'audio is supplied.',
    howToPlay: <String>['Not available yet.'],
  ),
  GameDef(
    id: 'hajj-map',
    title: 'Hajj Map',
    blurb: 'Place the rites of Hajj on the map',
    category: GameCategory.islamic,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games',
    iconKey: 'route',
    kind: GameEngineKind.own,
    hidden: true,
    sourceNote: 'Hidden until the map art is supplied and the order of the '
        'rites is checked against the guides.',
    howToPlay: <String>['Not available yet.'],
  ),
];
