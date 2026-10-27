/// How to play the games in the app, built from the game list itself
/// (`kGames`), so what Hādi says can never drift from what the game says: if
/// a rule or a mode changes in the registry, this answer changes with it.
///
/// Pure Dart (no Flutter).
library;

import '../../games/engine/game_registry.dart';
import 'hadi_core.dart';

/// A name people use for a game, in canonical (apostrophe-free, lower-case)
/// form. A `weak` name is also an ordinary word, so it counts only when the
/// question also talks about playing.
class _Alias {
  const _Alias(this.id, this.words, {this.weak = false});
  final String id;
  final List<String> words;
  final bool weak;
}

abstract final class HadiGameHelp {
  static const List<_Alias> _aliases = <_Alias>[
    _Alias('memory', <String>['names memory', 'memory match', 'memory game',
      'memory pairs', 'matching game', 'match the names']),
    _Alias('memory', <String>['memory'], weak: true),
    _Alias('qk', <String>['quran knowledge', 'quran quiz', 'complete the ayah']),
    _Alias('stories', <String>['stories trivia', 'story trivia', 'stories quiz']),
    _Alias('names99', <String>['99 names', 'ninety nine names',
      'names of allah game']),
    _Alias('lineage', <String>['lineage challenge', 'lineage game']),
    _Alias('lineage', <String>['lineage'], weak: true),
    _Alias('hijrah', <String>['hijrah journey', 'hijrah game']),
    _Alias('hifz', <String>['hifz practice', 'hifz game']),
    _Alias('chess', <String>['chess', 'shatranj']),
    _Alias('ludo', <String>['ludo']),
    _Alias('seerah-timeline', <String>['seerah timeline', 'timeline game']),
    _Alias('seerah-timeline', <String>['timeline'], weak: true),
    _Alias('seerah', <String>['seerah challenge', 'seerah quiz', 'seerah game']),
    _Alias('prophets-order', <String>['prophets in order', 'order of the prophets game',
      'order the prophets']),
    _Alias('hadith', <String>['hadith knowledge', 'hadith quiz', 'hadith game']),
    _Alias('salah-wudu', <String>['wudu and salah steps', 'wudu steps game',
      'salah steps game', 'wudu game', 'prayer steps game']),
    _Alias('arabic-words', <String>['arabic words game', 'arabic words']),
    _Alias('wordsearch', <String>['word search']),
    _Alias('scramble', <String>['word scramble']),
    _Alias('scramble', <String>['scramble'], weak: true),
  ];

  static final RegExp _playing = RegExp(
      r'\b(?:play|plays|playing|played|game|games|app|quiz|puzzle|rules?|'
      r'start|open|find|where|how)\b');

  /// Words that make this a question about a ruling, not about the game: those
  /// are for the built-in answers and the ruling gate.
  static final RegExp _ruling = RegExp(
      r'\b(?:haram|halal|sin|sinful|allowed|permissible|permitted|forbidden|'
      r'makruh|ruling|fatwa|islamic view|islam say|islam says)\b');

  static final RegExp _asksQuiz = RegExp(
      r'\b(?:trivia|quiz|quizzes)\b');

  static final RegExp _asksList = RegExp(
      r'\b(?:what|which) games\b|\bgames (?:are there|do you have|does the app have|'
      r'in the app|available)\b|\blist (?:of )?(?:the )?games\b|'
      r'\bwhere (?:are|is) (?:the )?games\b');

  static String _title(GameDef g) => g.title;

  /// The reply for [question], or null when it is not about a game.
  static String? answer(String question) {
    final String q = HadiCore.canon(question);
    if (q.isEmpty || _ruling.hasMatch(q)) return null;

    if (_asksList.hasMatch(q)) return _listReply();

    final bool playing = _playing.hasMatch(q);
    for (final _Alias a in _aliases) {
      if (a.weak && !playing) continue;
      if (a.words.any((String w) => _has(q, w))) {
        final GameDef? g = gameById(a.id);
        if (g != null) return _gameReply(g);
      }
    }
    if (playing && _asksQuiz.hasMatch(q)) return _quizReply();
    return null;
  }

  static bool _has(String q, String phrase) =>
      RegExp('(?:^| )${RegExp.escape(phrase)}(?: |\$)').hasMatch(q);

  static String _gameReply(GameDef g) {
    final StringBuffer b = StringBuffer()
      ..writeln('${_title(g)}: ${g.blurb}.')
      ..writeln();
    if (g.howToPlay.isNotEmpty) {
      b.writeln('How to play:');
      for (int i = 0; i < g.howToPlay.length; i++) {
        b.writeln('${i + 1}. ${g.howToPlay[i]}');
      }
      b.writeln();
    }
    final List<PlayMode> modes = <PlayMode>[
      for (final PlayMode m in PlayMode.values)
        if (g.modes.contains(m)) m,
    ];
    b.writeln('You can play: ${modes.map((PlayMode m) => m.label).join(', ')}.');
    for (final PlayMode m in modes) {
      if (m == PlayMode.friends) {
        b.writeln('With a friend online: ${m.blurb} If the online hall is '
            'not switched on, the setup screen tells you.');
      }
    }
    if (g.maxPlayers > 1) {
      b.writeln('Up to ${g.maxPlayers} players.');
    }
    if (g.hasDifficulty) {
      b.writeln('You can choose how hard it is.');
    }
    if (g.hasHints) {
      b.writeln('Hints are free: $kHintsPerGame in a game.');
    }
    b.writeln();
    b.writeln(g.isAcademy
        ? 'Find it in the Games screen, under "${g.category.label}" (it opens '
            'in the Academy).'
        : 'To start: open the Games screen, find "${_title(g)}" under '
            '"${g.category.label}"${g.hasSetup ? ', choose your options' : ''}'
            ' and tap ${g.hasSetup ? 'Start' : 'Play'}.');
    if (g.sourceNote != null) {
      b.writeln();
      b.writeln('Where the content comes from: ${g.sourceNote}');
    }
    b.writeln();
    b.write('A game you leave half-way is kept under "Continue playing" at '
        'the top of the Games screen; finished games are in Game history.');
    b.write(_route(g));
    return b.toString();
  }

  /// A button for the game's own screen when it has a plain one, otherwise the
  /// Games screen.
  static String _route(GameDef g) {
    const Set<String> direct = <String>{
      '/games/names99',
      '/games/ludo',
      '/games/shatranj',
      '/games/memory',
      '/academy/hifz',
    };
    final String r = direct.contains(g.route) ? g.route : '/games';
    return '\n[GO:$r]';
  }

  static String _quizReply() {
    final List<GameDef> quizzes = <GameDef>[
      for (final GameDef g in visibleGames(showAcademy: true))
        if (g.isQuiz) g,
    ];
    final StringBuffer b = StringBuffer()
      ..writeln('The quiz games are in the Games screen. Each question shows '
          'its source after you answer, there is no timer, and hints are '
          'free. They are:');
    for (final GameDef g in quizzes) {
      b.writeln('- ${_title(g)}: ${g.blurb}.');
    }
    b.writeln();
    b.write('Ask me about one by name, for example "how do I play '
        '${quizzes.isEmpty ? 'a quiz' : _title(quizzes.first)}".');
    b.write('\n[GO:/games/trivia]');
    return b.toString();
  }

  static String _listReply() {
    final StringBuffer b = StringBuffer()
      ..writeln('These are the games in the app today:');
    for (final GameCategory c in GameCategory.values) {
      final List<GameDef> inCat = <GameDef>[
        for (final GameDef g in visibleGames(showAcademy: true))
          if (g.category == c) g,
      ];
      if (inCat.isEmpty) continue;
      b.writeln();
      b.writeln('${c.label}: ${c.sectionBlurb}');
      for (final GameDef g in inCat) {
        b.writeln('- ${_title(g)}: ${g.blurb}.');
      }
    }
    b.writeln();
    b.write('Ask me about any of them by name and I will tell you how it is '
        'played.');
    b.write('\n[GO:/games]');
    return b.toString();
  }
}
