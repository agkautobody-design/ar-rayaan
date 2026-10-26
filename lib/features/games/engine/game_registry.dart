/// The one list of games the Games hub shows.
///
/// Rules this file keeps (and `test/games/game_registry_test.dart` checks):
///  * a game is listed here only when it exists and works today; nothing is
///    shown as "coming soon" in the hub;
///  * no game is scored by worship, no game sells hints, nothing is rated:
///    there are no ratings, popularity counts, coins or points anywhere;
///  * removing a game from the hub is one deleted entry.
///
/// Pure Dart (no Flutter), so the logic can be checked with a plain Dart SDK.
library;

import '../data/ludo_rules.dart';

/// Where a game sits in the hub.
enum GameCategory { islamic, strategy, family, words }

extension GameCategoryLabel on GameCategory {
  /// The section title and the filter chip.
  String get label => switch (this) {
        GameCategory.islamic => 'Islamic',
        GameCategory.strategy => 'Strategy',
        GameCategory.family => 'Family',
        GameCategory.words => 'Words and puzzles',
      };

  String get sectionBlurb => switch (this) {
        GameCategory.islamic => 'Learn from the Qur’an and the stories',
        GameCategory.strategy => 'Think a few moves ahead',
        GameCategory.family => 'One device, passed around the table',
        GameCategory.words => 'Match, remember and recall',
      };
}

/// How people can play a game.
enum PlayMode { solo, passAndPlay, friends }

extension PlayModeLabel on PlayMode {
  String get label => switch (this) {
        PlayMode.solo => 'Solo',
        PlayMode.passAndPlay => 'Pass and play',
        PlayMode.friends => 'With a friend online',
      };

  String get blurb => switch (this) {
        PlayMode.solo => 'Play by yourself',
        PlayMode.passAndPlay => 'Take turns on this one device',
        PlayMode.friends =>
          'Share a six-letter code. Needs the internet and the online hall.',
      };
}

/// How hard a game is. Only some games use it.
enum GameDifficulty { easy, standard, challenge }

extension GameDifficultyLabel on GameDifficulty {
  String get label => switch (this) {
        GameDifficulty.easy => 'Easy',
        GameDifficulty.standard => 'Standard',
        GameDifficulty.challenge => 'Challenge',
      };
}

/// How a game is started.
enum GameEngineKind {
  /// The shared quiz engine (`/games/g/<id>/play`).
  quiz,

  /// A board with its own screen (Ludo, Shatranj).
  board,

  /// The memory-pairs game.
  memory,

  /// A single-purpose screen with nothing to set up.
  own,
}

/// One game.
class GameDef {
  const GameDef({
    required this.id,
    required this.title,
    required this.blurb,
    required this.category,
    required this.modes,
    required this.route,
    required this.iconKey,
    required this.kind,
    required this.howToPlay,
    this.maxPlayers = 1,
    this.hasSetup = false,
    this.hasQuestions = false,
    this.hasDifficulty = false,
    this.hasHints = false,
    this.isAcademy = false,
    this.elderFeatured = false,
    this.sourceNote,
  });

  /// Stable id used in routes and in saved history ('qk', 'ludo' ...).
  final String id;
  final String title;
  final String blurb;
  final GameCategory category;
  final Set<PlayMode> modes;

  /// Where Play goes for a game with no setup, and what a legacy link opens.
  final String route;

  /// Key into the hub's icon table (kept as text so this file stays pure).
  final String iconKey;
  final GameEngineKind kind;

  /// Plain, non-religious rules text, one short line per step.
  final List<String> howToPlay;
  final int maxPlayers;

  /// True when the setup screen has something to choose.
  final bool hasSetup;

  /// The setup screen offers a question count.
  final bool hasQuestions;

  /// The setup screen offers a difficulty.
  final bool hasDifficulty;

  /// The game has free hints (a fixed number per game, never bought).
  final bool hasHints;

  /// Hidden together with the Academy when its kill switch is off.
  final bool isAcademy;

  /// One of the three large cards the hub shows in Elder Mode.
  final bool elderFeatured;

  /// Where the content of an Islamic game comes from, shown on its page.
  final String? sourceNote;

  /// True for the games built on the shared quiz engine.
  bool get isQuiz => kind == GameEngineKind.quiz;

  /// True when more than one person can play on one device.
  bool get canPassAndPlay => modes.contains(PlayMode.passAndPlay);
}

/// The most hints a person gets in one game. Hints are free, never bought,
/// never earned and never traded.
const int kHintsPerGame = 3;

/// The longest the saved history list grows before the oldest drop off.
const int kHistoryLimit = 50;

/// The games that exist and work. Order is the order the hub shows them in.
const List<GameDef> kGames = <GameDef>[
  GameDef(
    id: 'qk',
    title: 'Qur’an Knowledge',
    blurb: 'Complete the ayah, and learn the surahs by name and number',
    category: GameCategory.islamic,
    modes: <PlayMode>{PlayMode.solo, PlayMode.passAndPlay},
    route: '/games/g/qk',
    iconKey: 'quran',
    kind: GameEngineKind.quiz,
    maxPlayers: 4,
    hasSetup: true,
    hasQuestions: true,
    hasDifficulty: true,
    hasHints: true,
    elderFeatured: true,
    sourceNote: 'Every question is built from the Qur’an text bundled '
        'in the app, and shows its surah and ayah after you answer. Only the '
        'Arabic text and the surah list are used; nothing is paraphrased.',
    howToPlay: <String>[
      'Choose how many questions and how hard.',
      'Pick the answer you think is right. There is no timer.',
      'After each answer you see the source and a short explanation.',
      'A hint hides two wrong answers. You get three free hints a game.',
    ],
  ),
  GameDef(
    id: 'stories',
    title: 'Stories Trivia',
    blurb: 'Questions from the stories, each with its source',
    category: GameCategory.islamic,
    modes: <PlayMode>{PlayMode.solo, PlayMode.passAndPlay},
    route: '/games/g/stories',
    iconKey: 'stories',
    kind: GameEngineKind.quiz,
    maxPlayers: 4,
    hasSetup: true,
    hasQuestions: true,
    hasHints: true,
    sourceNote: 'Questions come from the app’s own story notes. Only '
        'questions that name a source (a surah and ayah, a hadith book and '
        'number, or a seerah book) are used, and the source is shown after '
        'each answer.',
    howToPlay: <String>[
      'Choose a topic and how many questions.',
      'Pick the answer you think is right. There is no timer.',
      'After each answer you see the source and a short explanation.',
      'A hint hides two wrong answers. You get three free hints a game.',
    ],
  ),
  GameDef(
    id: 'names99',
    title: 'The 99 Names',
    blurb: 'The beautiful names, one flashcard at a time',
    category: GameCategory.islamic,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/names99',
    iconKey: 'names',
    kind: GameEngineKind.own,
    elderFeatured: true,
    sourceNote: 'Each Name shows the Qur’an reference it comes from.',
    howToPlay: <String>[
      'Tap a card to turn it over and see the meaning.',
      'Use Next and Previous to move through the Names.',
      'Switch to the list to see all 99 together.',
    ],
  ),
  GameDef(
    id: 'lineage',
    title: 'Lineage Challenge',
    blurb: 'Who begot whom: the Messengers’ tree as a game',
    category: GameCategory.islamic,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/lineage',
    iconKey: 'tree',
    kind: GameEngineKind.own,
    sourceNote: 'Built from the Messengers’ tree in the Family section. '
        'Only people marked Established are asked about.',
    howToPlay: <String>[
      'Read the question and pick an answer.',
      'The explanation tells you why.',
    ],
  ),
  GameDef(
    id: 'hijrah',
    title: 'The Hijrah Journey',
    blurb: 'Makkah to Madinah, station by station',
    category: GameCategory.islamic,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/hijrah',
    iconKey: 'route',
    kind: GameEngineKind.own,
    sourceNote: 'Each station names the source it comes from.',
    howToPlay: <String>[
      'Scroll down the road, station by station.',
      'Each station says where its account comes from.',
    ],
  ),
  GameDef(
    id: 'hifz',
    title: 'Hifz practice',
    blurb: 'Cover the Arabic and recite, then check yourself',
    category: GameCategory.islamic,
    modes: <PlayMode>{PlayMode.solo},
    route: '/academy/hifz',
    iconKey: 'hifz',
    kind: GameEngineKind.own,
    isAcademy: true,
    sourceNote: 'Opens the Hifz Planner. In the Qur’an reader, '
        '“Hide text / test me” covers the Arabic until you tap it. '
        'There are no scores for memorising.',
    howToPlay: <String>[
      'Choose a surah in the Hifz Planner.',
      'Open it in the reader and tap “Hide text / test me”.',
      'Recite, then tap an ayah to check yourself.',
    ],
  ),
  GameDef(
    id: 'chess',
    title: 'Shatranj (chess)',
    blurb: 'Chess against Hadi’s engine, or a friend beside you',
    category: GameCategory.strategy,
    modes: <PlayMode>{
      PlayMode.solo,
      PlayMode.passAndPlay,
      PlayMode.friends,
    },
    route: '/games/shatranj',
    iconKey: 'chess',
    kind: GameEngineKind.board,
    maxPlayers: 2,
    hasSetup: true,
    hasDifficulty: true,
    howToPlay: <String>[
      'White moves first. Tap a piece, then a square it can reach.',
      'Win by checkmate. A stalemate is a draw.',
      'This version has no castling or en passant, no clock and no undo.',
    ],
  ),
  GameDef(
    id: 'ludo',
    title: 'Ludo',
    blurb: 'Dice, captures and four pawns racing home',
    category: GameCategory.family,
    modes: <PlayMode>{
      PlayMode.solo,
      PlayMode.passAndPlay,
      PlayMode.friends,
    },
    route: '/games/ludo',
    iconKey: 'ludo',
    kind: GameEngineKind.board,
    maxPlayers: 4,
    hasSetup: true,
    howToPlay: LudoRules.howToPlay,
  ),
  GameDef(
    id: 'memory',
    title: 'Names Memory',
    blurb: 'Match each of Allah’s Names in Arabic to its spelling',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo, PlayMode.passAndPlay},
    route: '/games/memory',
    iconKey: 'memory',
    kind: GameEngineKind.memory,
    maxPlayers: 4,
    hasSetup: true,
    elderFeatured: true,
    sourceNote: 'The Names, their Arabic and meanings come from the same '
        'verified list as The 99 Names.',
    howToPlay: <String>[
      'Turn over two cards. If an Arabic Name and its spelling match, they stay.',
      'A match shows the meaning and where the Name is found.',
      'There is no timer. Take as long as you like.',
    ],
  ),
];

/// The game with [id], or null.
GameDef? gameById(String id) {
  for (final GameDef g in kGames) {
    if (g.id == id) return g;
  }
  return null;
}

/// Games to show, optionally without the Academy ones.
List<GameDef> visibleGames({required bool showAcademy}) => <GameDef>[
      for (final GameDef g in kGames)
        if (showAcademy || !g.isAcademy) g,
    ];

/// The hub's filter chips. `null` is All. Family means "can be played
/// together on one device", so it can include games from other sections.
enum HubFilter { all, islamic, strategy, family, words }

extension HubFilterLabel on HubFilter {
  String get label => switch (this) {
        HubFilter.all => 'All',
        HubFilter.islamic => 'Islamic',
        HubFilter.strategy => 'Strategy',
        HubFilter.family => 'Family',
        HubFilter.words => 'Words and puzzles',
      };
}

/// The games a filter shows.
List<GameDef> gamesForFilter(List<GameDef> games, HubFilter f) =>
    <GameDef>[
      for (final GameDef g in games)
        if (switch (f) {
          HubFilter.all => true,
          HubFilter.islamic => g.category == GameCategory.islamic,
          HubFilter.strategy => g.category == GameCategory.strategy,
          HubFilter.family => g.canPassAndPlay,
          HubFilter.words => g.category == GameCategory.words,
        })
          g,
    ];
