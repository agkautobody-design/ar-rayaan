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
import 'learning_games.dart';

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
        PlayMode.friends => 'Play online with a friend',
      };

  String get blurb => switch (this) {
        PlayMode.solo => 'Play by yourself',
        PlayMode.passAndPlay => 'Take turns on this one device',
        PlayMode.friends =>
          'Invite a friend with a link. Needs the internet and the online hall.',
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

  /// Put things in order (`/games/g/<id>/play`): the Seerah timeline,
  /// Prophets in Order, the Wudu and Salah steps.
  order,

  /// Word Search and Word Scramble (`/games/g/<id>/play`).
  words,
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
    this.hidden = false,
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

  /// True for a game that is registered but not shown or playable yet,
  /// because the verified content it needs is not in the app. Each one is
  /// listed in `docs/content_needed/GAMES_CONTENT_NEEDED.md`.
  final bool hidden;

  /// Where the content of an Islamic game comes from, shown on its page.
  final String? sourceNote;

  /// True for the games built on the shared quiz engine.
  bool get isQuiz => kind == GameEngineKind.quiz;

  /// True when more than one person can play on one device.
  bool get canPassAndPlay => modes.contains(PlayMode.passAndPlay);

  /// Whether [m] is offered on screen. A child in child mode is never shown
  /// "With a friend online": the online hall is a parent's choice, so the
  /// label must not invite something the child cannot do.
  bool offersMode(PlayMode m, {bool child = false}) =>
      (modes.contains(m) || (m == PlayMode.friends && canRace)) &&
      !(child && m == PlayMode.friends);

  /// Quiz, ordering, word and memory games can be raced with a friend
  /// online: both get the same game (one shared seed) and see each other's
  /// progress. The explorer screens (Names, Lineage, Hijrah, Hifz) have
  /// nothing to race (Lineage and the Names, which has a meaning quiz, can be), and Ludo and
  /// Shatranj have their own tables.
  bool get canRace =>
      kind == GameEngineKind.quiz ||
      kind == GameEngineKind.order ||
      kind == GameEngineKind.words ||
      kind == GameEngineKind.memory ||
      id == 'lineage' ||
      id == 'names99' ||
      kRacePuzzleIds.contains(id);
}

/// The own-engine puzzles that can be raced with a friend: both get the same
/// puzzle (one shared seed). Their screens are in `puzzle_games.dart`.
const Set<String> kRacePuzzleIds = <String>{
  'maze',
  'mathquest',
  'pattern',
  'sliding',
  'merge',
  'logicgrid',
  'colorsort',
  'tower',
  'memnum',
  'cluehunt',
  'sudoku',
  'shapes',
};

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
    sourceNote: 'Every question names its source: a surah and ayah, or a '
        'hadith in Sahih al-Bukhari or Sahih Muslim, with the number. The '
        'wording is checked against the Saheeh International text and the '
        'hadith collections, and the source is shown after each answer.',
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
    sourceNote: 'Each Name shows an ayah where the Name itself, or the verb '
        'it comes from, appears in the Qur’an. The meanings are '
        'explanations, not translations of the Name.',
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
      'Rook: any number of squares along a row or a column. Bishop: any '
          'number along a diagonal. Queen: like a rook and a bishop together.',
      'Knight: an L shape, two squares one way and one to the side. It is '
          'the only piece that jumps over others.',
      'King: one square in any direction, never onto a square that is '
          'attacked. Pawn: one square forward (two from its first move), and '
          'it captures one square diagonally forward.',
      'Check means your king is attacked. You must answer it at once: move '
          'the king, block the attack or capture the attacker. If you cannot, '
          'it is checkmate.',
      'Win by checkmate. A stalemate, the same position three times, fifty '
          'moves with no capture or pawn move, or too few pieces left are draws.',
      'Castling, en passant and choosing your promotion piece all work. You '
          'can undo, ask for a hint, offer a draw or resign. A clock is '
          'optional and off unless you choose one.',
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
  GameDef(
    id: 'maze',
    title: 'Maze Escape',
    blurb: 'Find the way out, three mazes, each bigger',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/maze',
    iconKey: 'route',
    kind: GameEngineKind.own,
    howToPlay: <String>[
      'Move with the arrow buttons or your keyboard arrows.',
      'Walls block you. Reach the gold square at the bottom right.',
      'Three mazes, each bigger than the last. There is no timer.',
    ],
  ),
  GameDef(
    id: 'mathquest',
    title: 'Math Quest',
    blurb: 'Ten sums, from easy to a little harder',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/mathquest',
    iconKey: 'grid',
    kind: GameEngineKind.own,
    howToPlay: <String>[
      'Work out the sum and pick the right answer.',
      'Multiplication and division come before adding and taking away.',
      'There is no timer. Take your time.',
    ],
  ),
  GameDef(
    id: 'pattern',
    title: 'Pattern Sequence',
    blurb: 'Watch the symbols, then repeat them',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/pattern',
    iconKey: 'grid',
    kind: GameEngineKind.own,
    howToPlay: <String>[
      'Watch the symbols light up one by one.',
      'Tap them in the same order.',
      'Each round adds one more symbol. Six rounds in all.',
    ],
  ),
  GameDef(
    id: 'sliding',
    title: 'Sliding Tile',
    blurb: 'Slide the tiles into order, 1 to 15',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/sliding',
    iconKey: 'grid',
    kind: GameEngineKind.own,
    howToPlay: <String>[
      'Tap a tile next to the gap to slide it in.',
      'Put the tiles in order, 1 to 15, with the gap last.',
      'There is no timer. Fewer moves is a nice goal, not a rule.',
    ],
  ),
  GameDef(
    id: 'merge',
    title: 'Number Merge',
    blurb: 'Slide and join equal tiles to make bigger ones',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/merge',
    iconKey: 'grid',
    kind: GameEngineKind.own,
    howToPlay: <String>[
      'Swipe or use the arrows to slide every tile.',
      'Two equal tiles that touch join into one.',
      'Keep going until no move is left. Racing a friend: the first to make 256 wins.',
    ],
  ),
  GameDef(
    id: 'logicgrid',
    title: 'Logic Grid',
    blurb: 'Four people, four houses: work out who lives where',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/logicgrid',
    iconKey: 'grid',
    kind: GameEngineKind.own,
    howToPlay: <String>[
      'Read the clues. Every clue is true.',
      'Choose a house, 1 to 4, for each person. Each house holds one person.',
      'Tap Check my answer when you think you have it.',
    ],
  ),
  GameDef(
    id: 'colorsort',
    title: 'Colour Sort',
    blurb: 'Pour the colours until every tube is one colour',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/colorsort',
    iconKey: 'grid',
    kind: GameEngineKind.own,
    howToPlay: <String>[
      'Tap a tube, then the tube to pour into.',
      'You can pour onto the same colour, or into an empty tube.',
      'Sort all the colours. There is no timer.',
    ],
  ),
  GameDef(
    id: 'tower',
    title: 'Tower Builder',
    blurb: 'Move the tower, one disc at a time',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/tower',
    iconKey: 'grid',
    kind: GameEngineKind.own,
    howToPlay: <String>[
      'Tap a peg to pick up its top disc, then tap where to put it.',
      'Never put a bigger disc on a smaller one.',
      'Move all five discs to the third peg.',
    ],
  ),
  GameDef(
    id: 'matching',
    title: 'Matching',
    blurb: 'Pair each Name of Allah with its meaning',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/matching',
    iconKey: 'grid',
    kind: GameEngineKind.own,
    howToPlay: <String>[
      'Tap a Name in Arabic, then the meaning that goes with it.',
      'A right pair leaves the board. A wrong one is counted.',
      'Clear all six to finish.',
    ],
  ),
  GameDef(
    id: 'flashcards',
    title: 'Flashcards',
    blurb: 'Learn the Names of Allah, card by card',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/flashcards',
    iconKey: 'grid',
    kind: GameEngineKind.own,
    howToPlay: <String>[
      'See the Name in Arabic. Tap the card to turn it over.',
      'Say whether you knew it. Cards you miss come back.',
      'Ten cards a round, until you know them all.',
    ],
  ),
  GameDef(
    id: 'memnum',
    title: 'Memory Numbers',
    blurb: 'Look at a number, hold it, type it back',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/memnum',
    iconKey: 'grid',
    kind: GameEngineKind.own,
    howToPlay: <String>[
      'A number shows for a few seconds. Remember it.',
      'Then type it back. Each round adds a digit.',
      'Seven numbers in all, from three digits to nine.',
    ],
  ),
  GameDef(
    id: 'cluehunt',
    title: 'Clue Hunt',
    blurb: 'Find the hidden code from the clues',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/cluehunt',
    iconKey: 'grid',
    kind: GameEngineKind.own,
    howToPlay: <String>[
      'A hidden code has four different symbols.',
      'Pick four and try. You see how many are in the right place, and how many are right but elsewhere.',
      'You have eight tries.',
    ],
  ),
  GameDef(
    id: 'sudoku',
    title: 'Sudoku',
    blurb: 'Fill the grid so no number repeats',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/sudoku',
    iconKey: 'grid',
    kind: GameEngineKind.own,
    howToPlay: <String>[
      'Fill every row, column and box with 1 to 9.',
      'Tap a square, then a number.',
      'Three mistakes end the game.',
    ],
  ),
  GameDef(
    id: 'connect4',
    title: 'Four in a Row',
    blurb: 'Drop tokens and line up four',
    category: GameCategory.strategy,
    modes: <PlayMode>{PlayMode.solo, PlayMode.passAndPlay},
    route: '/games/connect4',
    iconKey: 'chess',
    kind: GameEngineKind.own,
    maxPlayers: 2,
    howToPlay: <String>[
      'Choose the computer (easy, medium or hard) or two players on one device.',
      'Take turns dropping a token into a column.',
      'The first to line up four, across, down or diagonally, wins.',
    ],
  ),
  GameDef(
    id: 'draughts',
    title: 'Checkers',
    blurb: 'A classic game for focus, strategy and patience',
    category: GameCategory.strategy,
    modes: <PlayMode>{PlayMode.solo, PlayMode.passAndPlay},
    route: '/games/draughts',
    iconKey: 'chess',
    kind: GameEngineKind.own,
    maxPlayers: 2,
    howToPlay: <String>[
      'Choose the computer or two players on one device.',
      'Move a piece diagonally forward onto an empty dark square.',
      'A capture is compulsory. Reach the far row to be crowned and move both ways.',
    ],
  ),
  GameDef(
    id: 'shapes',
    title: 'Shape Quest',
    blurb: 'Sides, corners and angles of shapes',
    category: GameCategory.words,
    modes: <PlayMode>{PlayMode.solo},
    route: '/games/shapes',
    iconKey: 'grid',
    kind: GameEngineKind.own,
    howToPlay: <String>[
      'Ten questions about shapes: sides, corners and the angles inside.',
      'Pick the answer you think is right.',
      'There is no timer. Take your time.',
    ],
  ),
  ...kLearningGames,
];

/// The game with [id], or null.
GameDef? gameById(String id) {
  for (final GameDef g in kGames) {
    if (g.id == id && !g.hidden) return g;
  }
  return null;
}

/// The games that are registered but hidden for lack of verified content.
List<GameDef> get hiddenGames => <GameDef>[
      for (final GameDef g in kGames)
        if (g.hidden) g,
    ];

/// Games to show, optionally without the Academy ones.
List<GameDef> visibleGames({required bool showAcademy}) => <GameDef>[
      for (final GameDef g in kGames)
        if (!g.hidden && (showAcademy || !g.isAcademy)) g,
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
