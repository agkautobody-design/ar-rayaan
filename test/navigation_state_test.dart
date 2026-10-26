import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/router.dart';
import 'package:ar_rayaan/app/theme/widgets/screen_header.dart';
import 'package:ar_rayaan/features/academy/presentation/stories_school_screen.dart';
import 'package:ar_rayaan/features/games/data/ludo_rules.dart';
import 'package:ar_rayaan/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ar_rayaan/features/stories/application/saved_stories_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';

/// Navigation and small state fixes from the first-time-user study: Back that
/// stays honest, Close that stays in the learning area, a goal that leads
/// somewhere sensible, and the Ludo and bookmark state bugs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parentRouteOf', () {
    test('a lesson closes to its school, a school to the Academy', () {
      expect(parentRouteOf('/academy/letters/lesson/letters-01'),
          '/academy/letters');
      expect(parentRouteOf('/academy/letters'), AppRoutes.academy);
      expect(parentRouteOf('/academy/lesson/c1/u1/l1'), '/academy/course/c1');
      expect(parentRouteOf('/academy/course/c1'), AppRoutes.academy);
      expect(parentRouteOf('/academy/exam/e1'), AppRoutes.academy);
    });

    test('readers return to their library', () {
      expect(parentRouteOf(AppRoutes.storyReader), AppRoutes.stories);
      expect(parentRouteOf('/huda/guide'), AppRoutes.huda);
      expect(parentRouteOf('/feelings/calm'), AppRoutes.feelings);
      expect(parentRouteOf(AppRoutes.sakinaSteady), AppRoutes.sakina);
      expect(parentRouteOf('/games/ludo'), AppRoutes.games);
      expect(parentRouteOf('/quran/2'), AppRoutes.quran);
    });

    test('screens that belong nowhere go Home', () {
      expect(parentRouteOf('/academy'), AppRoutes.home);
      expect(parentRouteOf('/stories'), AppRoutes.home);
      expect(parentRouteOf('/somewhere/unknown'), AppRoutes.home);
      expect(parentRouteOf('/'), AppRoutes.home);
    });
  });

  testWidgets('Close on a lesson with nothing underneath stays in the school',
      (WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: '/academy/letters/lesson/x',
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.home,
          builder: (BuildContext c, GoRouterState s) =>
              const Scaffold(body: Text('HOME PAGE')),
        ),
        GoRoute(
          path: '/academy/letters',
          builder: (BuildContext c, GoRouterState s) =>
              const Scaffold(body: Text('LETTERS PAGE')),
          routes: <RouteBase>[
            GoRoute(
              path: 'lesson/:id',
              builder: (BuildContext c, GoRouterState s) => const Scaffold(
                body: SafeArea(
                  child: ScreenHeader(title: 'Lesson', close: true),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('LETTERS PAGE'), findsOneWidget);
    expect(find.text('HOME PAGE'), findsNothing);
  });

  group('onboarding', () {
    tearDown(() => OnboardingScreen.completedThisSession = false);

    test('every goal opens something that matches it; learn opens Home',
        () async {
      expect(await OnboardingScreen.homeRouteFor('learn'), AppRoutes.home);
      expect(await OnboardingScreen.homeRouteFor('peace'), AppRoutes.sakina);
      expect(await OnboardingScreen.homeRouteFor('pray'),
          AppRoutes.prayerTimes);
      expect(await OnboardingScreen.homeRouteFor('new'),
          AppRoutes.newMuslimPath);
      expect(await OnboardingScreen.homeRouteFor('children'),
          '/academy/family');
      expect(await OnboardingScreen.homeRouteFor('community'),
          AppRoutes.community);
      expect(await OnboardingScreen.homeRouteFor(null), AppRoutes.home);
    });

    test('a finished introduction is not reopened except by a replay', () {
      expect(
        OnboardingScreen.shouldBounce(
            completed: false, uri: Uri.parse('/onboarding')),
        isFalse,
      );
      expect(
        OnboardingScreen.shouldBounce(
            completed: true, uri: Uri.parse('/onboarding')),
        isTrue,
      );
      expect(
        OnboardingScreen.shouldBounce(
            completed: true, uri: Uri.parse('/onboarding?replay=1')),
        isFalse,
      );
    });

    testWidgets('Back into /onboarding after finishing goes Home',
        (WidgetTester tester) async {
      await AppHarness.boot(tester);
      OnboardingScreen.completedThisSession = true;
      await AppHarness.go(tester, find.byType(Scaffold).first, '/onboarding');
      expect(AppHarness.location(tester, find.byType(Scaffold).last),
          AppRoutes.home);
      // A deliberate replay from Settings still works.
      await AppHarness.go(
          tester, find.byType(Scaffold).first, '/onboarding?replay=1');
      expect(AppHarness.location(tester, find.byType(Scaffold).last),
          AppRoutes.onboarding);
    });
  });

  testWidgets('Steady yourself is a real route and Back returns to Sakina',
      (WidgetTester tester) async {
    await AppHarness.boot(tester);
    await AppHarness.go(tester, find.byType(Scaffold).first, AppRoutes.sakina);
    await tester.tap(find.text('Steady yourself'));
    await AppHarness.settle(tester);
    expect(AppHarness.location(tester, find.byType(Scaffold).last),
        AppRoutes.sakinaSteady);
    await tester.tap(find.byTooltip('Back'));
    await AppHarness.settle(tester);
    expect(AppHarness.location(tester, find.byType(Scaffold).last),
        AppRoutes.sakina);
  });

  testWidgets('the story reader without a story returns to the library',
      (WidgetTester tester) async {
    await AppHarness.boot(tester);
    await AppHarness.go(
        tester, find.byType(Scaffold).first, AppRoutes.storyReader);
    expect(AppHarness.location(tester, find.byType(Scaffold).last),
        AppRoutes.stories);
  });

  group('Stories School', () {
    test('every chapter points at a story that exists in the library', () {
      final Set<String> ids = <String>{};
      for (final FileSystemEntity f in Directory('assets/stories').listSync()) {
        if (f is! File || !f.path.endsWith('.json')) continue;
        final List<dynamic> list =
            json.decode(f.readAsStringSync()) as List<dynamic>;
        for (final dynamic s in list) {
          ids.add((s as Map<String, dynamic>)['id'] as String);
        }
      }
      expect(ids, isNotEmpty);
      for (final unit in kStoriesUnits) {
        for (final ch in unit.chapters) {
          expect(ids, contains(ch.storyId), reason: ch.title);
        }
      }
    });
  });

  group('saved stories', () {
    test('saving then removing really changes the state', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      int notified = 0;
      c.listen<Set<String>>(savedStoriesProvider, (_, __) => notified++);
      final SavedStoriesController n = c.read(savedStoriesProvider.notifier);

      await n.toggle('prophet-yusuf');
      expect(c.read(savedStoriesProvider), <String>{'prophet-yusuf'});
      await n.toggle('prophet-yusuf');
      expect(c.read(savedStoriesProvider), isEmpty);
      expect(notified, 2, reason: 'removal must notify the listeners too');
      expect(prefs.getStringList(SavedStoriesController.key), isEmpty);
    });
  });

  group('LudoRules', () {
    List<List<int>> board() => LudoRules.newTokens(4);

    test('a token in the yard needs a six', () {
      final List<List<int>> tok = board();
      expect(LudoRules.validMoves(tok, 0, 3), isEmpty);
      expect(LudoRules.validMoves(tok, 0, 6), <int>[0, 1, 2, 3]);
      expect(LudoRules.onlyBaseTokens(tok, 0), isTrue);
    });

    test('track tokens always move; finished ones never do', () {
      final List<List<int>> tok = board();
      tok[1] = <int>[10, LudoRules.finished, -1, 30];
      expect(LudoRules.validMoves(tok, 1, 2), <int>[0, 3]);
      expect(LudoRules.validMoves(tok, 1, 6), <int>[0, 2, 3]);
      expect(LudoRules.onlyBaseTokens(tok, 1), isFalse);
    });

    test('the home column needs an exact roll', () {
      final List<List<int>> tok = board();
      // two steps from the end
      tok[0] = <int>[LudoRules.finished - 2, -1, -1, -1];
      expect(LudoRules.validMoves(tok, 0, 2), <int>[0]);
      expect(LudoRules.validMoves(tok, 0, 3), isEmpty);
    });

    test('the die keeps showing the last roll between turns', () {
      expect(LudoRules.faceValue(dice: 0, lastRoll: 0), 0);
      expect(LudoRules.faceValue(dice: 0, lastRoll: 4), 4);
      expect(LudoRules.faceValue(dice: 5, lastRoll: 4), 5);
    });
  });
}
