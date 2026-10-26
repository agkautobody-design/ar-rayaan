import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/app/theme/widgets/app_bottom_nav.dart';
import 'package:ar_rayaan/features/games/data/game_history.dart';
import 'package:ar_rayaan/features/games/data/games_store.dart';
import 'package:ar_rayaan/features/games/engine/game_registry.dart';
import 'package:ar_rayaan/features/games/engine/quiz_engine.dart';
import 'package:ar_rayaan/features/games/presentation/community_stub_screen.dart';
import 'package:ar_rayaan/features/games/presentation/game_details_screen.dart';
import 'package:ar_rayaan/features/games/presentation/game_history_screen.dart';
import 'package:ar_rayaan/features/games/presentation/game_results_screen.dart';
import 'package:ar_rayaan/features/games/presentation/game_setup_screen.dart';
import 'package:ar_rayaan/features/games/presentation/games_screens.dart';
import 'package:ar_rayaan/features/games/presentation/memory_game_screen.dart';
import 'package:ar_rayaan/features/games/presentation/quiz_play_screen.dart';
import 'package:ar_rayaan/features/games/ui/games_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_harness.dart';

/// The Games section on screen: the hub, a game's page, the setup screen,
/// the quiz from first question to results, history, memory, and the
/// hidden community page. Phone width and 2x text must lay out cleanly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<TriviaQ> trivia = <TriviaQ>[
    for (int i = 0; i < 6; i++)
      TriviaQ(
        id: 'g$i',
        category: i < 3 ? 'Prophets' : 'Seerah',
        question: 'Question number $i?',
        options: <String>['Right $i', 'Wrong A$i', 'Wrong B$i', 'Wrong C$i'],
        answer: 0,
        why: 'The reason for $i (21:${i + 1}).',
      ),
  ];
  final List<Name99> names = <Name99>[
    for (int i = 1; i <= 8; i++)
      Name99(
        n: i,
        name: 'Name$i',
        meaning: 'Meaning $i',
        ref: '59:$i',
        arabic: 'الاسم$i',
      ),
  ];

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Map<String, Object> prefsValues = const <String, Object>{},
    double width = 430,
    double height = 3000,
    double scale = 1,
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          triviaProvider.overrideWith((ref) async => trivia),
          namesProvider.overrideWith((ref) async => names),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: screen),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
  }

  group('the hub', () {
    testWidgets('lists the registered games in sections, without ratings', (
      tester,
    ) async {
      await pumpScreen(tester, const GamesScreen(), height: 8000);
      expect(tester.takeException(), isNull);
      for (final GameCategory c in GameCategory.values) {
        expect(
          find.widgetWithText(SectionHeading, c.label),
          findsOneWidget,
          reason: c.label,
        );
      }
      for (final GameDef g in visibleGames(showAcademy: true)) {
        expect(find.text(g.title), findsOneWidget, reason: g.id);
      }
      for (final GameDef g in hiddenGames) {
        expect(find.text(g.title), findsNothing, reason: g.id);
      }
      for (final String bad in <String>[
        'Popular Games',
        '4.8',
        'Coming soon',
        'Top players',
      ]) {
        expect(find.textContaining(bad), findsNothing, reason: bad);
      }
      expect(find.text('Play with friends'), findsNothing);
      expect(find.text('Game history'), findsOneWidget);
      expect(find.textContaining('No ads, no coins'), findsOneWidget);
    });

    testWidgets('a filter chip narrows the list', (tester) async {
      await pumpScreen(tester, const GamesScreen());
      await tester.tap(find.widgetWithText(GameChip, 'Strategy'));
      await tester.pump();
      expect(find.text('Shatranj (chess)'), findsOneWidget);
      expect(find.text('Ludo'), findsNothing);
      expect(find.text('Qur’an Knowledge'), findsNothing);
      await tester.tap(find.widgetWithText(GameChip, 'Family'));
      await tester.pump();
      expect(find.text('Ludo'), findsOneWidget);
      expect(find.text('Qur’an Knowledge'), findsOneWidget);
      expect(find.text('The 99 Names'), findsNothing);
    });

    testWidgets('an unfinished game shows under Continue playing', (
      tester,
    ) async {
      final QuizSession s = QuizSession(
        config: const QuizConfig(gameId: 'stories', count: 2),
        questions: const <QuizQuestion>[
          QuizQuestion(
            id: 'a',
            prompt: 'p',
            options: <String>['x', 'y'],
            answer: 0,
            explanation: 'e',
            citation: 'c',
          ),
          QuizQuestion(
            id: 'b',
            prompt: 'p2',
            options: <String>['x', 'y'],
            answer: 0,
            explanation: 'e',
            citation: 'c',
          ),
        ],
      )..pick(0);
      final ProviderContainer c = await pumpScreen(tester, const GamesScreen());
      await c.read(gamesStoreProvider.notifier).saveSession(s);
      await tester.pump();
      expect(find.text('Continue playing'), findsOneWidget);
      expect(find.text('1 of 2 answered'), findsOneWidget);
    });

    testWidgets('Elder Mode shows three large cards and More games', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const GamesScreen(),
        prefsValues: <String, Object>{'ar.elder.mode': true},
      );
      expect(find.text('Qur’an Knowledge'), findsOneWidget);
      expect(find.text('The 99 Names'), findsOneWidget);
      expect(find.text('Names Memory'), findsOneWidget);
      expect(find.text('Ludo'), findsNothing);
      expect(find.text('Strategy'), findsNothing, reason: 'no filter chips');
      await tester.tap(find.text('More games'));
      await tester.pump();
      expect(find.text('Ludo'), findsOneWidget);
    });

    for (final double scale in <double>[1, 2]) {
      testWidgets('lays out on a 360px phone at ${scale}x text', (tester) async {
        await pumpScreen(
          tester,
          const GamesScreen(),
          width: 360,
          height: 900,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('a game’s pages', () {
    testWidgets('details: how to play, ways to play, source and policy link', (
      tester,
    ) async {
      await pumpScreen(tester, const GameDetailsScreen(gameId: 'qk'));
      expect(find.text('How to play'), findsOneWidget);
      expect(find.text('Ways to play'), findsOneWidget);
      expect(find.text('Where the content comes from'), findsOneWidget);
      expect(find.textContaining('Not yet scholar-reviewed'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.textContaining('Hints are free'), findsOneWidget);
    });

    testWidgets('details of an unknown game says so', (tester) async {
      await pumpScreen(tester, const GameDetailsScreen(gameId: 'nope'));
      expect(find.textContaining('not in this version'), findsOneWidget);
    });

    testWidgets('setup: Qur’an Knowledge offers the choices', (tester) async {
      await pumpScreen(tester, const GameSetupScreen(gameId: 'qk'));
      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Challenge'), findsOneWidget);
      expect(find.text('Free hints'), findsOneWidget);
      expect(find.text('Complete the ayah'), findsOneWidget);
      expect(find.text('Players'), findsNothing);
      await tester.tap(find.text('Pass and play').first);
      await tester.pump();
      expect(find.text('Players'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('setup: a link can preselect the ayah topic', (tester) async {
      await pumpScreen(
        tester,
        const GameSetupScreen(gameId: 'qk', initialTopic: 'ayah'),
      );
      expect(find.text('Complete the ayah'), findsOneWidget);
    });

    testWidgets('setup: Stories Trivia offers only what the pool can give', (
      tester,
    ) async {
      await pumpScreen(tester, const GameSetupScreen(gameId: 'stories'));
      expect(find.text('Questions'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('10'), findsNothing, reason: 'only 6 questions exist');
      expect(find.text('All topics'), findsOneWidget);
      expect(find.text('Difficulty'), findsNothing);
    });

    testWidgets('setup: Ludo and Shatranj open with a mode, no hints', (
      tester,
    ) async {
      await pumpScreen(tester, const GameSetupScreen(gameId: 'ludo'));
      expect(find.text('Play Hadi'), findsOneWidget);
      expect(find.text('With a friend online'), findsOneWidget);
      expect(find.text('Free hints'), findsNothing);
      await pumpScreen(tester, const GameSetupScreen(gameId: 'chess'));
      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('Easy'), findsNothing);
      expect(find.text('Challenge'), findsNothing);
      expect(find.text('No clock'), findsOneWidget);
    });

    testWidgets('setup: Names Memory asks for pairs', (tester) async {
      await pumpScreen(tester, const GameSetupScreen(gameId: 'memory'));
      expect(find.text('Pairs'), findsOneWidget);
      expect(find.text('6 pairs'), findsOneWidget);
    });

    for (final String id in <String>['qk', 'stories', 'ludo', 'chess', 'memory']) {
      testWidgets('setup of $id lays out on 360px at 2x text', (tester) async {
        await pumpScreen(
          tester,
          GameSetupScreen(gameId: id),
          width: 360,
          height: 900,
          scale: 2,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the community page is honest and stays unlinked', (
      tester,
    ) async {
      await pumpScreen(tester, const CommunityGamesStubScreen());
      expect(find.text('Coming with community'), findsWidgets);
      expect(find.textContaining('There is no chat'), findsOneWidget);
    });
  });

  group('the quiz', () {
    testWidgets('plays a full game: hint, answers, sources, results, history', (
      tester,
    ) async {
      final ProviderContainer c = await pumpScreen(
        tester,
        const QuizPlayScreen(
          gameId: 'stories',
          config: QuizConfig(gameId: 'stories', count: 3),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('QUESTION 1 OF 3'), findsOneWidget);
      expect(find.text('Hint (3 left)'), findsOneWidget);
      await tester.tap(find.text('Hint (3 left)'));
      await tester.pump();
      expect(find.text('Hint (2 left)'), findsOneWidget);
      expect(find.text('Removed by your hint'), findsNWidgets(2));

      for (int q = 0; q < 3; q++) {
        final Finder right = find.textContaining(RegExp(r'^Right \d$'));
        expect(right, findsOneWidget);
        await tester.tap(right);
        await tester.pump();
        expect(find.text('Correct'), findsOneWidget);
        expect(find.textContaining('Source: Qur’an 21:'), findsOneWidget);
        await tester.tap(find.text(q == 2 ? 'See results' : 'Next question'));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('FINISHED'), findsOneWidget);
      expect(find.text('3 of 3'), findsOneWidget);
      await tester.tap(find.text('Review answers'));
      await tester.pump();
      expect(find.textContaining('Source: Qur’an 21:'), findsNWidgets(3));

      final List<GameResult> saved = c.read(gamesStoreProvider).results;
      expect(saved.length, 1);
      expect(saved.first.summary, '3 of 3');
      expect(c.read(gamesStoreProvider).saved, isEmpty);
    });

    testWidgets('a wrong answer is neutral and still shows the source', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const QuizPlayScreen(
          gameId: 'stories',
          config: QuizConfig(gameId: 'stories', count: 2, hints: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Hint ('), findsNothing);
      await tester.tap(find.textContaining(RegExp(r'^Wrong A\d$')));
      await tester.pump();
      expect(find.text('Not quite'), findsOneWidget);
      expect(find.text('Right answer'), findsOneWidget);
      expect(find.textContaining('Source:'), findsOneWidget);
      expect(find.textContaining('lost'), findsNothing);
    });

    testWidgets('pass and play names the next player', (tester) async {
      await pumpScreen(
        tester,
        const QuizPlayScreen(
          gameId: 'stories',
          config: QuizConfig(gameId: 'stories', count: 4, players: 2),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Player 1, it is your turn'), findsOneWidget);
      await tester.tap(find.textContaining(RegExp(r'^Right \d$')));
      await tester.pump();
      expect(find.text('Pass to Player 2'), findsOneWidget);
    });

    testWidgets('the game is saved after an answer and can be resumed', (
      tester,
    ) async {
      final ProviderContainer c = await pumpScreen(
        tester,
        const QuizPlayScreen(
          gameId: 'stories',
          config: QuizConfig(gameId: 'stories', count: 3),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(RegExp(r'^Right \d$')));
      await tester.pump();
      final GamesState s = c.read(gamesStoreProvider);
      expect(s.saved.length, 1);
      expect(s.saved.first.answered, 1);
      expect(c.read(gamesStoreProvider.notifier).savedSession('stories'), isNotNull);
    });

    testWidgets('lays out on 360px at 2x text, question and answer', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const QuizPlayScreen(
          gameId: 'stories',
          config: QuizConfig(gameId: 'stories', count: 3),
        ),
        width: 360,
        height: 900,
        scale: 2,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.textContaining(RegExp(r'^Right \d$')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('history and results', () {
    testWidgets('empty history says so and offers no clear button', (
      tester,
    ) async {
      await pumpScreen(tester, const GameHistoryScreen());
      expect(find.textContaining('No games yet'), findsOneWidget);
      expect(find.text('Clear history'), findsNothing);
    });

    testWidgets('lists a finished game, filters it and clears it', (
      tester,
    ) async {
      final ProviderContainer c = await pumpScreen(
        tester,
        const GameHistoryScreen(),
      );
      await c.read(gamesStoreProvider.notifier).record(
            const GameResult(
              id: 'qk-1',
              gameId: 'qk',
              title: 'Qur’an Knowledge',
              finishedMs: 1790000000000,
              correct: 8,
              total: 10,
              difficulty: 'Standard',
            ),
          );
      await c.read(gamesStoreProvider.notifier).record(
            const GameResult(
              id: 'chess-1',
              gameId: 'chess',
              title: 'Shatranj (chess)',
              finishedMs: 1790000001000,
              outcome: 'Checkmate: White wins',
            ),
          );
      await tester.pump();
      expect(find.text('Qur’an Knowledge'), findsOneWidget);
      expect(find.text('Shatranj (chess)'), findsOneWidget);
      await tester.tap(find.text('Islamic'));
      await tester.pump();
      expect(find.text('Shatranj (chess)'), findsNothing);
      await tester.tap(find.text('Ongoing'));
      await tester.pump();
      expect(find.text('Qur’an Knowledge'), findsNothing);
      await tester.tap(find.text('All'));
      await tester.pump();
      await tester.tap(find.text('Clear history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(c.read(gamesStoreProvider).results, isEmpty);
    });

    testWidgets('a result page shows the score in plain words', (tester) async {
      final ProviderContainer c = await pumpScreen(
        tester,
        const GameResultScreen(gameId: 'qk', resultId: 'qk-1'),
      );
      await c.read(gamesStoreProvider.notifier).record(
            const GameResult(
              id: 'qk-1',
              gameId: 'qk',
              title: 'Qur’an Knowledge',
              finishedMs: 1790000000000,
              correct: 7,
              total: 10,
              players: 2,
              playerScores: <int>[4, 3],
            ),
          );
      await tester.pump();
      expect(find.text('7 of 10'), findsOneWidget);
      expect(find.text('Played together'), findsOneWidget);
      expect(find.text('Player 1: 4 of 5'), findsOneWidget);
      expect(find.text('Player 2: 3 of 5'), findsOneWidget);
    });
  });

  group('names memory', () {
    testWidgets('turns two cards and shows the meaning on a match', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const MemoryGameScreen(pairs: 6),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('PAIRS FOUND 0 OF 6'), findsOneWidget);
      // Twelve cards, all face down.
      expect(find.byIcon(Icons.stars_outlined), findsNWidgets(12));
      await tester.tap(find.byIcon(Icons.stars_outlined).first);
      await tester.pump();
      expect(find.byIcon(Icons.stars_outlined), findsNWidgets(11));
      await tester.tap(find.byIcon(Icons.stars_outlined).first);
      await tester.pump();
      final bool matched = find.text('A match').evaluate().isNotEmpty;
      final bool missed = find.text('Turn the cards back').evaluate().isNotEmpty;
      expect(matched || missed, isTrue);
      // Let a missed pair turn back by itself.
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out on 360px at 2x text', (tester) async {
      await pumpScreen(
        tester,
        const MemoryGameScreen(pairs: 8, players: 2),
        width: 360,
        height: 900,
        scale: 2,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('through the real router', () {
    testWidgets('the hub is a tab of the shell and old links redirect', (
      tester,
    ) async {
      await AppHarness.boot(tester);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/games');
      expect(find.byType(AppBottomNav), findsOneWidget);
      expect(find.text('Qur’an Knowledge'), findsOneWidget);
      expect(
        AppHarness.location(tester, find.byType(Scaffold).first),
        '/games',
      );

      await AppHarness.go(tester, find.byType(Scaffold).first, '/games/trivia');
      expect(
        AppHarness.location(tester, find.byType(Scaffold).first),
        '/games/g/stories',
      );

      await AppHarness.go(tester, find.byType(Scaffold).first, '/games/ayah');
      expect(
        AppHarness.location(tester, find.byType(Scaffold).first),
        '/games/g/qk/setup',
      );
      expect(find.text('Complete the ayah'), findsOneWidget);
    });

    testWidgets('the community page is not reachable while it is off', (
      tester,
    ) async {
      await AppHarness.boot(tester);
      await AppHarness.go(
        tester,
        find.byType(Scaffold).first,
        '/games/community',
      );
      expect(
        AppHarness.location(tester, find.byType(Scaffold).first),
        '/games',
      );
    });

    testWidgets('Home has a Games tile that opens the hub', (tester) async {
      await AppHarness.boot(tester);
      await tester.tap(find.text('Games').first);
      await AppHarness.settle(tester);
      expect(
        AppHarness.location(tester, find.byType(Scaffold).first),
        '/games',
      );
    });

    testWidgets('Ludo and Shatranj start in the mode chosen in setup', (
      tester,
    ) async {
      await AppHarness.boot(tester);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/games/ludo?mode=2');
      expect(find.text('Two players'), findsNothing,
          reason: 'the table menu is skipped');
      expect(find.textContaining('Two players — Red and Yellow'), findsOneWidget);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/games/shatranj?mode=1');
      expect(find.textContaining('You are White'), findsOneWidget);
    });
  });
}
