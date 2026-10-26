import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/games/data/game_settings.dart';
import 'package:ar_rayaan/features/games/data/learning_loader.dart';
import 'package:ar_rayaan/features/games/engine/game_registry.dart';
import 'package:ar_rayaan/features/games/engine/order_engine.dart';
import 'package:ar_rayaan/features/games/engine/quiz_engine.dart';
import 'package:ar_rayaan/features/games/engine/word_engine.dart';
import 'package:ar_rayaan/features/games/presentation/game_settings_screen.dart';
import 'package:ar_rayaan/features/games/ui/games_art.dart';
import 'package:ar_rayaan/features/games/ui/learning_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Object? _read(String path) => json.decode(File(path).readAsStringSync());

/// All the text inside a JSON value, joined.
String _allText(Object? o) {
  if (o is String) return o;
  if (o is List) return o.map(_allText).join('\n');
  if (o is Map) return o.values.map(_allText).join('\n');
  return '';
}

String _norm(String s) => s.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

double _ratio(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = max(la, lb);
  final double lo = min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void _checkBank(List<QuizQuestion> qs, String what) {
  expect(qs, isNotEmpty, reason: what);
  final Set<String> ids = <String>{};
  for (final QuizQuestion q in qs) {
    expect(ids.add(q.id), isTrue, reason: '$what: duplicate id ${q.id}');
    expect(q.prompt.trim(), isNotEmpty, reason: q.id);
    expect(q.citation.trim(), isNotEmpty, reason: '${q.id} has no source');
    expect(q.explanation.trim(), isNotEmpty, reason: q.id);
    expect(q.options.length, 4, reason: q.id);
    expect(q.options.toSet().length, 4, reason: '${q.id} repeats an option');
    expect(q.answer, inInclusiveRange(0, 3), reason: q.id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Seerah Challenge', () {
    test('every question has a source, and its evidence is in the story', () async {
      final List<QuizQuestion> qs =
          await LearningLoader.seerahQuiz(Random(1), 1000);
      _checkBank(qs, 'seerah');
      expect(qs.length, greaterThanOrEqualTo(40));

      final Map<String, dynamic> bank =
          _read('assets/games/seerah_quiz.json') as Map<String, dynamic>;
      final Map<String, String> story = <String, String>{
        for (final dynamic s in _read('assets/stories/seerah.json') as List)
          (s as Map<String, dynamic>)['id'] as String: _norm(_allText(s)),
      };
      for (final dynamic q in bank['questions'] as List) {
        final Map<String, dynamic> m = q as Map<String, dynamic>;
        final String ev = _norm(m['evidence'] as String);
        expect(ev, isNotEmpty, reason: '${m['id']}');
        expect(story[m['story']], isNotNull, reason: '${m['id']}: no story');
        expect(story[m['story']]!.contains(ev), isTrue,
            reason: '${m['id']}: evidence not in ${m['story']}');
      }
    });
  });

  group('Hadith Knowledge', () {
    test('every question cites number, collection and a named grader', () async {
      final List<QuizQuestion> qs =
          await LearningLoader.hadithQuiz(Random(2), 1000);
      _checkBank(qs, 'hadith');
      for (final QuizQuestion q in qs) {
        expect(q.citation, contains('No.'), reason: q.id);
        expect(q.explanation.toLowerCase(), contains('grad'),
            reason: '${q.id} shows no grade');
      }
    });

    test('a report with no named grader is never asked', () async {
      final List<dynamic> forty =
          _read('assets/hadith/nawawi40.json') as List<dynamic>;
      final Set<int> ungraded = <int>{
        for (final dynamic h in forty)
          if ((h as Map<String, dynamic>)['grade'] == null ||
              '${h['grade']}'.trim().isEmpty)
            h['n'] as int,
      };
      final List<QuizQuestion> qs =
          await LearningLoader.hadithQuiz(Random(3), 1000);
      for (final int n in ungraded) {
        for (final QuizQuestion q in qs) {
          expect(q.citation.contains('No. $n '), isFalse,
              reason: 'ungraded hadith $n asked in ${q.id}');
        }
      }
    });
  });

  group('Arabic Words', () {
    for (final String topic in ArabicWordTopicsForTest.all) {
      test('the $topic bank has sources and four distinct options', () async {
        final List<QuizQuestion> qs =
            await LearningLoader.arabicWordsQuiz(Random(4), 1000, topic);
        _checkBank(qs, topic);
      });
    }
  });

  group('Ordering games', () {
    test('Seerah timeline: story numbers rise, facts and sources present', () async {
      final Map<String, dynamic> d =
          _read('assets/games/order_rounds.json') as Map<String, dynamic>;
      final List<dynamic> ev =
          (d['seerah'] as Map<String, dynamic>)['events'] as List<dynamic>;
      expect(ev.length, greaterThanOrEqualTo(8));
      int last = 0;
      final Map<String, String> story = <String, String>{
        for (final dynamic s in _read('assets/stories/seerah.json') as List)
          (s as Map<String, dynamic>)['id'] as String: _norm(_allText(s)),
      };
      for (final dynamic e in ev) {
        final Map<String, dynamic> m = e as Map<String, dynamic>;
        final int n = int.parse((m['story'] as String).split('-').last);
        expect(n, greaterThan(last), reason: '${m['id']} is out of order');
        last = n;
        expect(story[m['story']], isNotNull);
        expect(story[m['story']]!.contains(_norm(m['fact'] as String)), isTrue,
            reason: '${m['id']}: fact is not the story\'s own words');
      }
      final List<OrderRound> rs =
          await LearningLoader.orderRounds('seerah-timeline', '', Random(5));
      expect(rs, isNotEmpty);
      _checkRounds(rs);
    });

    test('Prophets in Order: each round is supported by the tree', () async {
      final List<OrderRound> rs =
          await LearningLoader.orderRounds('prophets-order', '', Random(6));
      expect(rs, isNotEmpty);
      _checkRounds(rs);
      final Map<String, dynamic> tree =
          _read('assets/family/tree.json') as Map<String, dynamic>;
      final Map<String, Map<String, dynamic>> nodes =
          <String, Map<String, dynamic>>{
        for (final dynamic n in tree['nodes'] as List)
          (n as Map<String, dynamic>)['id'] as String: n,
      };
      for (final OrderRound r in rs) {
        final List<String> ids = r.items.map((OrderItem i) => i.id).toList();
        for (int i = 0; i < ids.length; i++) {
          for (int j = i + 1; j < ids.length; j++) {
            expect(prophetOrderReason(nodes, ids[i], ids[j]), isNotNull,
                reason: '${r.id}: ${ids[i]} before ${ids[j]}');
            expect(prophetOrderReason(nodes, ids[j], ids[i]), isNull,
                reason: '${r.id}: ${ids[j]} before ${ids[i]} must not hold');
          }
        }
      }
    });

    for (final String topic in <String>['wudu', 'salah']) {
      test('$topic steps: 3 rounds, guide order, school-of-law note', () async {
        final List<OrderRound> rs =
            await LearningLoader.orderRounds('salah-wudu', topic, Random(7));
        expect(rs.length, 3);
        _checkRounds(rs);
        for (final OrderRound r in rs) {
          expect(r.note, isNotNull, reason: r.id);
          expect(r.note!.toLowerCase(), contains('school'), reason: r.id);
        }
      });
    }

    test('hints are free, fix one card each, and stop at three', () async {
      final List<OrderRound> rs =
          await LearningLoader.orderRounds('seerah-timeline', '', Random(8));
      final OrderSession s = OrderSession(rs, Random(9));
      expect(s.hintsLeft, kHintsPerOrderGame);
      int used = 0;
      while (s.canUseHint && used < 10) {
        final int? p = s.useHint();
        if (p == null) break;
        expect(s.locked.contains(p), isTrue);
        expect(s.arrangement[p], p);
        used += 1;
      }
      expect(used, lessThanOrEqualTo(kHintsPerOrderGame));
      expect(s.hintsLeft, kHintsPerOrderGame - used);
      expect(OrderSession(rs, Random(1), hints: false).canUseHint, isFalse);
    });

    test('a wrong check costs nothing and the order can be fixed', () async {
      final List<OrderRound> rs =
          await LearningLoader.orderRounds('seerah-timeline', '', Random(10));
      final OrderSession s = OrderSession(rs, Random(11));
      expect(s.check(), isFalse);
      expect(s.misses, 1);
      for (int g = 0; g < 50 && !s.solved; g++) {
        if (s.useHint() == null) {
          // No free hints left: bubble the cards into place by hand.
          for (int p = 0; p < s.arrangement.length; p++) {
            while (s.arrangement[p] != p) {
              final int at = s.arrangement.indexOf(p);
              s.moveUp(at);
            }
          }
        }
        s.check();
      }
      expect(s.solved, isTrue);
    });
  });

  group('Word games', () {
    test('words come from the glossary and never name Allah', () {
      final List<WordClue> pool = LearningLoader.wordPool();
      expect(pool.length, greaterThanOrEqualTo(10));
      final Set<String> names = <String>{
        for (final dynamic n in _read('assets/games/names99.json') as List)
          _norm((n as Map<String, dynamic>)['name'] as String)
              .replaceAll(RegExp('[^a-z]'), ''),
      };
      for (final WordClue w in pool) {
        expect(w.clue.trim(), isNotEmpty, reason: w.word);
        expect(names.contains(w.word), isFalse, reason: '${w.word} is a Name');
      }
    });

    test('the grid hides its words where they can be found', () {
      final List<WordClue> pool = LearningLoader.wordPool();
      final WordGrid? g = buildWordGrid(pool, Random(12));
      expect(g, isNotNull);
      expect(g!.placed.length, greaterThanOrEqualTo(3));
      final SearchSession s = SearchSession(g);
      for (final PlacedWord p in g.placed) {
        final String spelled = <String>[
          for (int i = 0; i < p.clue.word.length; i++) g.at(p.cellAt(i)),
        ].join();
        expect(spelled, p.clue.word);
        expect(s.tryLine(p.cellAt(0), p.cellAt(p.clue.word.length - 1)), isNotNull);
      }
      expect(s.finished, isTrue);
    });

    test('a scramble never equals the word', () {
      for (final WordClue w in LearningLoader.wordPool()) {
        final List<String> t = scrambleLetters(w.word, Random(13));
        expect(t.join() == w.word, w.word.split('').toSet().length < 2,
            reason: w.word);
        expect(List<String>.of(t)..sort(), w.word.split('')..sort());
      }
    });
  });

  group('Registry', () {
    test('every hidden game is named in GAMES_CONTENT_NEEDED.md', () {
      final String doc =
          File('docs/content_needed/GAMES_CONTENT_NEEDED.md').readAsStringSync();
      expect(hiddenGames, isNotEmpty);
      for (final GameDef g in hiddenGames) {
        expect(g.hidden, isTrue);
        expect(doc.contains('`${g.id}`'), isTrue, reason: '${g.id} not listed');
        expect(gameById(g.id), isNull, reason: g.id);
        expect(
          visibleGames(showAcademy: true).any((GameDef v) => v.id == g.id),
          isFalse,
        );
      }
    });

    test('the new games state a source and invent no popularity', () {
      for (final GameDef g in kLearningGames.where((GameDef g) => !g.hidden)) {
        expect(g.sourceNote.trim(), isNotEmpty, reason: g.id);
        expect(g.howToPlay, isNotEmpty, reason: g.id);
        expect(g.blurb.toLowerCase(), isNot(contains('rated')), reason: g.id);
        expect(g.blurb.toLowerCase(), isNot(contains('popular')), reason: g.id);
      }
    });

    test('the board slots are in the manifest as fallbacks and the docs', () {
      final String doc =
          File('docs/content_needed/GAMES_ART_NEEDED.md').readAsStringSync();
      final Map<String, dynamic> fb = (_read('assets/games/art/manifest.json')
          as Map<String, dynamic>)['fallback'] as Map<String, dynamic>;
      for (final ArtSlot s in <ArtSlot>[
        ArtSlot.seerahTimelineBoard,
        ArtSlot.prophetsOrderBoard,
        ArtSlot.wuduStepsBoard,
        ArtSlot.salahStepsBoard,
        ArtSlot.wordSearchGrid,
        ArtSlot.scrambleTile,
        ArtSlot.hajjMap,
      ]) {
        expect(fb.containsKey(s.name), isTrue, reason: s.name);
        expect(doc.contains('`${s.name}`'), isTrue, reason: s.name);
      }
    });
  });

  group('Game settings', () {
    test('sound is off and hints are shown by default', () {
      const GameSettings s = GameSettings();
      expect(s.sound, isFalse);
      expect(s.showHints, isTrue);
    });

    test('every palette keeps text readable (4.5:1)', () {
      for (final GameCardTheme t in GameCardTheme.values) {
        final GamePalette p = GamePalette.of(t);
        expect(_ratio(p.text, p.fill), greaterThanOrEqualTo(4.5), reason: '$t');
        expect(_ratio(p.accent, p.fill), greaterThanOrEqualTo(4.5), reason: '$t');
        expect(_ratio(p.good, p.fill), greaterThanOrEqualTo(4.5), reason: '$t');
      }
    });

    testWidgets('the settings screen lays out at 2x text and saves a choice', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(430, 3000);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const GameSettingsScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      final ProviderContainer c =
          ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
      expect(c.read(gameSettingsProvider).sound, isFalse);
      c.read(gameSettingsProvider.notifier).setTheme(GameCardTheme.parchment);
      expect(prefs.getString(GameSettingsKeys.theme), 'parchment');
    });
  });
}

void _checkRounds(List<OrderRound> rs) {
  for (final OrderRound r in rs) {
    expect(r.citation.trim(), isNotEmpty, reason: '${r.id} has no source');
    expect(r.explanation.trim(), isNotEmpty, reason: r.id);
    expect(r.items.length, greaterThanOrEqualTo(2), reason: r.id);
    expect(r.items.map((OrderItem i) => i.id).toSet().length, r.items.length,
        reason: r.id);
  }
}

/// The Arabic Words topics, spelled out so a renamed topic fails here.
abstract final class ArabicWordTopicsForTest {
  static const List<String> all = <String>['mixed', 'names', 'letters'];
}
