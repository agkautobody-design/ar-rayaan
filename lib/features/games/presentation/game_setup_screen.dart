import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/child_mode.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/needs_internet_view.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/switch_row.dart';
import '../data/game_settings.dart';
import '../data/learning_loader.dart';
import '../engine/game_registry.dart';
import '../engine/learning_banks.dart';
import '../engine/memory_engine.dart';
import '../engine/quiz_engine.dart';
import '../ui/games_theme.dart';
import '../data/games_adapters.dart';
import 'games_screens.dart';

/// The query keys the setup screen can be opened with, so a link such as
/// `/games/g/qk/setup?topic=ayah` starts with that choice made.
class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({
    required this.gameId,
    this.initialTopic,
    this.initialMode,
    super.key,
  });

  final String gameId;
  final String? initialTopic;
  final String? initialMode;

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupState();
}

class _GameSetupState extends ConsumerState<GameSetupScreen> {
  PlayMode _mode = PlayMode.solo;
  int _players = 2;
  // Ludo pass-and-play: how many of the seats share this phone.
  int _humans = 2;
  int _count = 10;
  int _pairs = 8;
  GameDifficulty _difficulty = GameDifficulty.standard;
  bool _hints = true;
  String _topic = 'mixed';
  String _playAs = 'white';
  int _minutes = 0;

  @override
  void initState() {
    super.initState();
    _hints = ref.read(gameSettingsProvider).showHints;
    final String? t = widget.initialTopic;
    if (t != null && t.isNotEmpty) _topic = t;
    final GameDef? g = gameById(widget.gameId);
    if (g != null) {
      for (final PlayMode m in PlayMode.values) {
        if (m.name == widget.initialMode &&
            g.offersMode(m, child: kChildMode.value)) {
          _mode = m;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final GameDef? g = gameById(widget.gameId);
    if (g == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView(
          children: const <Widget>[
            ScreenHeader(title: 'Game', showSettings: false),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          ArchHeader(
            title: '${g.title}: set up',
            tagline: g.blurb,
            band: true,
          ),
          ..._body(g),
        ],
      ),
    );
  }

  List<Widget> _body(GameDef g) {
    if (g.id == 'stories') {
      final AsyncValue<List<TriviaQ>> async = ref.watch(triviaProvider);
      return async.when(
        loading: () => const <Widget>[
          SizedBox(height: 40),
          Center(child: CircularProgressIndicator()),
        ],
        error: (Object e, StackTrace s) => <Widget>[
          SizedBox(
            height: 320,
            child: NeedsInternetView(
              what: 'Stories Trivia',
              onRetry: () => ref.invalidate(triviaProvider),
            ),
          ),
        ],
        data: (List<TriviaQ> rows) => _form(g, rows: triviaRows(rows)),
      );
    }
    if (g.id == 'memory') {
      final AsyncValue<List<Name99>> async = ref.watch(namesProvider);
      return async.when(
        loading: () => const <Widget>[
          SizedBox(height: 40),
          Center(child: CircularProgressIndicator()),
        ],
        error: (Object e, StackTrace s) => <Widget>[
          SizedBox(
            height: 320,
            child: NeedsInternetView(
              what: 'The 99 Names',
              onRetry: () => ref.invalidate(namesProvider),
            ),
          ),
        ],
        data: (List<Name99> names) => _form(g, names: names),
      );
    }
    if (g.id == 'seerah' || g.id == 'hadith' || g.id == 'arabic-words') {
      // One size per game: every topic has at least 56 questions.
      final AsyncValue<int> async = ref.watch(
        poolSizeProvider('${g.id}|mixed'),
      );
      return async.when(
        loading: () => const <Widget>[
          SizedBox(height: 40),
          Center(child: CircularProgressIndicator()),
        ],
        error: (Object e, StackTrace s) => <Widget>[
          const SizedBox(height: 24),
          Text(
            'The questions could not be loaded. Please go back and try again.',
            style: AppText.body,
            textAlign: TextAlign.center,
          ),
        ],
        data: (int n) => _form(g, pool: n),
      );
    }
    return _form(g);
  }

  List<Widget> _form(
    GameDef g, {
    List<TriviaRow>? rows,
    List<Name99>? names,
    int? pool,
  }) {
    // What the pool can support.
    List<int> counts = const <int>[5, 10, 15, 20, 30];
    List<String> topics = const <String>[];
    if (g.id == 'stories' && rows != null) {
      topics = <String>['mixed', ...storiesTopics(rows)];
      if (!topics.contains(_topic)) _topic = 'mixed';
      counts = countChoices(storiesPool(rows, topic: _topic).length);
    } else if (g.id == 'qk') {
      topics = QuranTopics.all;
      if (!topics.contains(_topic)) _topic = 'mixed';
    } else if (g.id == 'arabic-words') {
      topics = ArabicWordTopics.all;
      if (!topics.contains(_topic)) _topic = 'mixed';
    } else if (g.id == 'salah-wudu') {
      topics = const <String>['wudu', 'salah'];
      if (!topics.contains(_topic)) _topic = 'wudu';
    }
    if (pool != null) counts = countChoices(pool);
    if (counts.isNotEmpty && !counts.contains(_count)) {
      _count = counts.lastWhere(
        (int n) => n <= _count,
        orElse: () => counts.first,
      );
    }
    List<int> pairChoices = const <int>[];
    if (g.id == 'memory' && names != null) {
      pairChoices = memoryPairChoices(
        memoryCandidates(memoryNames(names)).length,
      );
      if (pairChoices.isNotEmpty && !pairChoices.contains(_pairs)) {
        _pairs = pairChoices.last;
      }
    }
    final bool pass = _mode == PlayMode.passAndPlay;
    final List<int> playerChoices = <int>[
      for (int n = 2; n <= g.maxPlayers; n++) n,
    ];
    if (_players > g.maxPlayers) _players = g.maxPlayers;

    final List<Widget> out = <Widget>[
      _Group(
        title: 'How do you want to play?',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final PlayMode m in PlayMode.values)
                  if (g.offersMode(m, child: kChildMode.value))
                    GameChip(
                      label: _modeLabel(g, m),
                      selected: _mode == m,
                      onTap: () => setState(() => _mode = m),
                    ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _modeNote(g, _mode),
              style: AppText.bodyMuted.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    ];

    final bool ludo = g.id == 'ludo';
    if ((pass || (ludo && _mode == PlayMode.solo)) &&
        playerChoices.length > 1) {
      out.add(
        _Group(
          title: 'Players',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final int n in playerChoices)
                GameChip(
                  label: '$n players',
                  selected: _players == n,
                  onTap: () => setState(() {
                    _players = n;
                    if (_humans > n) _humans = n;
                  }),
                ),
            ],
          ),
        ),
      );
    }

    // Ludo, pass and play with 3 or 4 seats: the rest are computer players.
    if (ludo && pass && _players > 2) {
      if (_humans > _players) _humans = _players;
      if (_humans < 2) _humans = 2;
      out.add(
        _Group(
          title: 'People on this phone',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (int n = 2; n <= _players; n++)
                GameChip(
                  label: '$n',
                  selected: _humans == n,
                  onTap: () => setState(() => _humans = n),
                ),
            ],
          ),
        ),
      );
    }

    if (topics.length > 1) {
      out.add(
        _Group(
          title: 'Topic',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String t in topics)
                GameChip(
                  label: _topicLabel(g, t),
                  selected: _topic == t,
                  onTap: () => setState(() => _topic = t),
                ),
            ],
          ),
        ),
      );
    }

    if (g.hasQuestions) {
      out.add(
        _Group(
          title: 'Questions',
          child: counts.isEmpty
              ? Text('No questions are available.', style: AppText.bodyMuted)
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final int n in counts)
                      GameChip(
                        label: '$n',
                        selected: _count == n,
                        onTap: () => setState(() => _count = n),
                      ),
                  ],
                ),
        ),
      );
    }

    if (g.id == 'memory' && pairChoices.isNotEmpty) {
      out.add(
        _Group(
          title: 'Pairs',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final int n in pairChoices)
                GameChip(
                  label: '$n pairs',
                  selected: _pairs == n,
                  onTap: () => setState(() => _pairs = n),
                ),
            ],
          ),
        ),
      );
    }

    if (g.hasDifficulty && (g.id != 'chess' || _mode == PlayMode.solo)) {
      final bool chess = g.id == 'chess';
      final List<GameDifficulty> levels = GameDifficulty.values;
      out.add(
        _Group(
          title: chess ? 'Hadi’s strength' : 'Difficulty',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final GameDifficulty d in levels)
                GameChip(
                  label: chess ? _chessLevelLabel(d) : d.label,
                  selected: _difficulty == d,
                  onTap: () => setState(() => _difficulty = d),
                ),
            ],
          ),
        ),
      );
    }

    if (g.id == 'chess' && _mode != PlayMode.friends) {
      if (_mode == PlayMode.solo) {
        out.add(
          _Group(
            title: 'Play as',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String a in const <String>[
                  'white',
                  'black',
                  'random',
                ])
                  GameChip(
                    label: '${a[0].toUpperCase()}${a.substring(1)}',
                    selected: _playAs == a,
                    onTap: () => setState(() => _playAs = a),
                  ),
              ],
            ),
          ),
        );
      }
      out.add(
        _Group(
          title: 'Clock per player',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final int t in const <int>[0, 5, 10, 15, 30])
                GameChip(
                  label: t == 0 ? 'No clock' : '$t min',
                  selected: _minutes == t,
                  onTap: () => setState(() => _minutes = t),
                ),
            ],
          ),
        ),
      );
    }

    if (g.hasHints) {
      out.add(
        _Group(
          title: 'Hints',
          child: SwitchRow(
            icon: Icons.lightbulb_outline,
            title: 'Free hints',
            subtitle: '$kHintsPerGame a game. A hint hides two wrong answers.',
            value: _hints,
            onChanged: (bool v) => setState(() => _hints = v),
          ),
        ),
      );
    }

    out.add(const SizedBox(height: 8));
    out.add(
      Center(
        child: PlayButton(
          label: _mode == PlayMode.friends ? 'Go to the table' : 'Start',
          icon: Icons.play_arrow_rounded,
          onPressed: _canStart(g, counts, pairChoices)
              ? () => context.open(_startRoute(g))
              : null,
        ),
      ),
    );
    return out;
  }

  String _topicLabel(GameDef g, String t) {
    if (g.id == 'qk') return QuranTopics.label(t);
    if (g.id == 'arabic-words') return ArabicWordTopics.label(t);
    if (g.id == 'salah-wudu') return t == 'salah' ? 'The prayer (salah)' : 'Wudu';
    return t == 'mixed' ? 'All topics' : t;
  }

  bool _canStart(GameDef g, List<int> counts, List<int> pairChoices) {
    if (g.hasQuestions && counts.isEmpty) return false;
    if (g.id == 'memory' && pairChoices.isEmpty) return false;
    return true;
  }

  String _modeLabel(GameDef g, PlayMode m) {
    if (g.kind == GameEngineKind.board && m == PlayMode.solo) {
      return 'Play Hadi';
    }
    return m.label;
  }

  String _chessLevelLabel(GameDifficulty d) => switch (d) {
        GameDifficulty.easy => 'Beginner',
        GameDifficulty.standard => 'Intermediate',
        GameDifficulty.challenge => 'Advanced',
      };

  String _modeNote(GameDef g, PlayMode m) {
    if (g.kind == GameEngineKind.board) {
      switch (m) {
        case PlayMode.solo:
          return g.id == 'chess'
              ? 'You play White against Hadi’s engine.'
              : 'You are Red. Hadi, and computer players for any other '
                  'seat, take the rest.';
        case PlayMode.passAndPlay:
          return g.id == 'ludo'
              ? 'Two to four players take turns on this device. Computer '
                  'players fill any seat nobody sits in.'
              : 'Two players share this device and take turns.';
        case PlayMode.friends:
          return 'Opens the table screen, where you create a table or join '
              'one with a six-letter code. It needs the internet and the '
              'online hall to be switched on; if it is not, you are told.';
      }
    }
    return m == PlayMode.passAndPlay
        ? 'Players take turns on this device. Everyone answers different '
            'questions, and the results are shown together.'
        : 'You play by yourself.';
  }

  String _startRoute(GameDef g) {
    if (g.kind == GameEngineKind.order || g.kind == GameEngineKind.words) {
      return Uri(
        path: '/games/g/${g.id}/play',
        queryParameters: <String, String>{'topic': _topic},
      ).toString();
    }
    if (g.isQuiz) {
      final QuizConfig c = QuizConfig(
        gameId: g.id,
        topic: _topic,
        count: _count,
        difficulty: _difficulty,
        players: _mode == PlayMode.passAndPlay ? _players : 1,
        hints: _hints,
      );
      return Uri(
        path: '/games/g/${g.id}/play',
        queryParameters: c.toQuery(),
      ).toString();
    }
    if (g.id == 'memory') {
      return Uri(
        path: '/games/memory',
        queryParameters: <String, String>{
          'players': '${_mode == PlayMode.passAndPlay ? _players : 1}',
          'pairs': '$_pairs',
        },
      ).toString();
    }
    // Ludo and Shatranj: 1 = Hadi, 2 = two players, 0 = the table menu.
    final int mode = switch (_mode) {
      PlayMode.solo => 1,
      PlayMode.passAndPlay => 2,
      PlayMode.friends => 0,
    };
    return Uri(
      path: g.route,
      queryParameters: <String, String>{
        'mode': '$mode',
        if (g.id == 'ludo' && _mode != PlayMode.friends) ...<String, String>{
          'players': '$_players',
          if (_mode == PlayMode.passAndPlay)
            'humans': '${_players == 2 ? 2 : _humans}',
        },
        if (g.id == 'chess' && _mode == PlayMode.solo) ...<String, String>{
          'd': _difficulty.name,
          'as': _playAs,
        },
        if (g.id == 'chess' && _mode != PlayMode.friends && _minutes > 0)
          't': '$_minutes',
      },
    ).toString();
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GamePanel(
        ornate: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                title,
                style: AppText.titleMedium.copyWith(
                  color: GamesTheme.champagne,
                ),
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
