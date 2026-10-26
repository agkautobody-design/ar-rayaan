import 'dart:io';

import 'package:ar_rayaan/app/core/route_titles.dart';
import 'package:ar_rayaan/features/games/engine/game_registry.dart';
import 'package:ar_rayaan/features/games/games_flags.dart';
import 'package:flutter_test/flutter_test.dart';

import '../audit/router_source.dart';

/// The Games registry is the only list of games the hub shows. These tests
/// keep it honest: every game is a real, titled route; Islamic games say
/// where their content comes from; and nothing in it prices a hint, rates a
/// game, or scores worship.
void main() {
  test('ids are unique and every game has the fields the hub needs', () {
    final Set<String> ids = <String>{};
    for (final GameDef g in kGames) {
      expect(ids.add(g.id), isTrue, reason: 'duplicate id ${g.id}');
      expect(g.title.trim(), isNotEmpty);
      expect(g.blurb.trim(), isNotEmpty);
      expect(g.howToPlay, isNotEmpty, reason: g.id);
      expect(g.modes, isNotEmpty, reason: g.id);
    }
  });

  test('every game opens a real route that has a page title', () {
    final RouterSource router = RouterSource.read();
    for (final GameDef g in kGames) {
      expect(router.resolves(g.route), isTrue, reason: '${g.id}: ${g.route}');
      expect(
        RouteTitles.forPath(g.route.split('?').first),
        isNot(RouteTitles.appName),
        reason: '${g.route} has no title',
      );
      if (g.hasSetup) {
        final String setup = '/games/g/${g.id}/setup';
        expect(router.resolves(setup), isTrue, reason: setup);
      }
      expect(router.resolves('/games/g/${g.id}'), isTrue);
    }
    for (final String p in <String>[
      '/games',
      '/games/history',
      '/games/community',
      '/games/g/qk/play',
      '/games/g/qk/results',
    ]) {
      expect(router.resolves(p), isTrue, reason: p);
      expect(RouteTitles.forPath(p), isNot(RouteTitles.appName), reason: p);
    }
  });

  test('the old links still land: trivia and ayah redirect', () {
    final String src = File('lib/app/router.dart').readAsStringSync();
    expect(src.contains("'/games/g/stories'"), isTrue);
    expect(src.contains("'/games/g/qk/setup?topic=ayah'"), isTrue);
  });

  test('every Islamic game says where its content comes from', () {
    for (final GameDef g in kGames) {
      if (g.category != GameCategory.islamic) continue;
      expect(g.sourceNote, isNotNull, reason: g.id);
      expect(g.sourceNote!.trim(), isNotEmpty, reason: g.id);
    }
  });

  test('games that take hints, questions or difficulty are set up first', () {
    for (final GameDef g in kGames) {
      if (g.hasHints || g.hasQuestions || g.hasDifficulty) {
        expect(g.hasSetup, isTrue, reason: g.id);
      }
      if (g.isQuiz) {
        expect(g.hasQuestions, isTrue, reason: g.id);
        expect(g.hasHints, isTrue, reason: g.id);
      }
    }
  });

  test('no ratings, coins, points for worship, rewards or ads in the text', () {
    final RegExp banned = RegExp(
      r'\b(rating|rated|popular|coins?|points?|rewards?|prizes?|'
      r'leaderboard|tournament|streaks?|ads?|buy|purchase|premium|chat)\b',
      caseSensitive: false,
    );
    for (final GameDef g in kGames) {
      final String all = <String>[
        g.title,
        g.blurb,
        ...g.howToPlay,
        g.sourceNote ?? '',
      ].join(' ');
      // "No timer" and "never bought" are allowed: the rule bans selling and
      // scoring, not saying that they do not exist.
      final String cleaned = all
          .replaceAll(RegExp(r'never (bought|earned)', caseSensitive: false), '')
          .replaceAll(RegExp(r'no scores', caseSensitive: false), '')
          .replaceAll(RegExp(r'no stakes', caseSensitive: false), '');
      expect(banned.hasMatch(cleaned), isFalse,
          reason: '${g.id}: ${banned.firstMatch(cleaned)?.group(0)}');
    }
  });

  test('hints are a small fixed number, free', () {
    expect(kHintsPerGame, 3);
    expect(kHistoryLimit, 50);
  });

  test('the community screens stay hidden until the service exists', () {
    expect(kGamesCommunityEnabled, isFalse);
  });

  test('filters: Family means playable together; others by section', () {
    final List<GameDef> all = visibleGames(showAcademy: true);
    final Set<String> family = <String>{
      for (final GameDef g in gamesForFilter(all, HubFilter.family)) g.id,
    };
    expect(family.contains('ludo'), isTrue);
    expect(family.contains('qk'), isTrue);
    expect(family.contains('names99'), isFalse);
    final Set<String> islamic = <String>{
      for (final GameDef g in gamesForFilter(all, HubFilter.islamic)) g.id,
    };
    expect(islamic.contains('chess'), isFalse);
    expect(gamesForFilter(all, HubFilter.all).length, all.length);
  });

  test('the Academy switch removes the Hifz entry only', () {
    final List<GameDef> off = visibleGames(showAcademy: false);
    expect(off.any((GameDef g) => g.id == 'hifz'), isFalse);
    expect(off.length, visibleGames(showAcademy: true).length - 1);
  });

  test('Elder Mode shows three large cards', () {
    expect(kGames.where((GameDef g) => g.elderFeatured).length, 3);
  });

  test('the quiz games and board games the hub lists really have screens', () {
    final String router = File('lib/app/router.dart').readAsStringSync();
    expect(router.contains('QuizPlayScreen('), isTrue);
    expect(router.contains('MemoryGameScreen('), isTrue);
    expect(router.contains('LudoScreen('), isTrue);
    expect(router.contains('ShatranjScreen('), isTrue);
  });
}
