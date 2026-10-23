import 'package:ar_rayaan/app/router.dart';
import 'package:ar_rayaan/features/home/domain/next_step.dart';
import 'package:ar_rayaan/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';

/// Round 3: a two-screen introduction, a Home that reacts to the chosen
/// goal with one "Your next step" card, and the small-phone fixes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('next step rules (pure)', () {
    test('every route the card can open is a real route', () {
      expect(NextStepRoutes.prayer, AppRoutes.prayerTimes);
      expect(NextStepRoutes.adhkar, AppRoutes.adhkar);
      expect(NextStepRoutes.quran, AppRoutes.quran);
      expect(NextStepRoutes.stories, AppRoutes.stories);
      expect(NextStepRoutes.academyGate, AppRoutes.academyGate);
      expect(NextStepRoutes.sakina, AppRoutes.sakina);
      expect(NextStepRoutes.newMuslimPath, AppRoutes.newMuslimPath);
      expect(NextStepRoutes.community, AppRoutes.community);
      expect(NextStepRoutes.family, '/academy/family');
    });

    test('pray: next prayer, then adhkar', () {
      final NextStep s = resolveNextStep(
        need: 'pray',
        academyOn: true,
        nextPrayer: 'Asr at 3:42 PM',
        adhkarLeft: 5,
      );
      expect(s.headline, 'Pray Asr at 3:42 PM');
      expect(s.detail, contains('5 left'));
      expect(s.route, AppRoutes.prayerTimes);
      expect(s.secondaryRoute, AppRoutes.adhkar);
    });

    test('pray without a location asks for one and invents no time', () {
      final NextStep s = resolveNextStep(need: 'pray', academyOn: true);
      expect(s.headline, isNot(contains(' at ')));
      expect(s.route, AppRoutes.prayerTimes);
    });

    test('learn: lesson with the Academy on, stories with it off', () {
      expect(
        resolveNextStep(need: 'learn', academyOn: true).route,
        AppRoutes.academyGate,
      );
      expect(
        resolveNextStep(need: 'learn', academyOn: true, lessonsDone: 2).detail,
        contains('2 lessons'),
      );
      expect(
        resolveNextStep(need: 'learn', academyOn: false).route,
        AppRoutes.stories,
      );
    });

    test('new to Islam: Day N of the path, then start again', () {
      expect(
        resolveNextStep(need: 'new', academyOn: true).headline,
        'Day 1 of the 30-day road',
      );
      expect(
        resolveNextStep(need: 'new', academyOn: true, newMuslimDone: 6)
            .headline,
        'Day 7 of the 30-day road',
      );
      expect(
        resolveNextStep(need: 'new', academyOn: true, newMuslimDone: 30).route,
        AppRoutes.newMuslimPath,
      );
    });

    test('other goals and no goal fall back to the right door', () {
      expect(resolveNextStep(need: 'peace', academyOn: true).route,
          AppRoutes.sakina);
      expect(resolveNextStep(need: 'children', academyOn: true).route,
          '/academy/family');
      expect(resolveNextStep(need: 'community', academyOn: true).route,
          AppRoutes.community);
      final NextStep none = resolveNextStep(need: null, academyOn: true);
      expect(none.route, AppRoutes.quran);
      expect(none.headline, 'Begin with Al-Fatihah');
      expect(
        resolveNextStep(
          need: null,
          academyOn: true,
          quranResume: 'Al-Baqarah 2:5',
        ).headline,
        'Continue reading Al-Baqarah 2:5',
      );
    });
  });

  group('onboarding', () {
    Future<GoRouter> pumpOnboarding(
      WidgetTester tester, {
      double width = 320,
      double height = 568,
      double scale = 1.0,
    }) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      OnboardingScreen.completedThisSession = false;
      final GoRouter router = GoRouter(
        initialLocation: '/onboarding',
        routes: <RouteBase>[
          GoRoute(
            path: '/onboarding',
            builder: (_, _) => const OnboardingScreen(),
          ),
          GoRoute(path: '/home', builder: (_, _) => const Text('HOME-PAGE')),
          GoRoute(
            path: '/prayer',
            builder: (_, _) => const Text('PRAYER-PAGE'),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(milliseconds: 300));
      return router;
    }

    testWidgets('one welcome screen carrying a plain trust line', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      expect(find.byKey(const Key('onboarding-welcome-title')), findsOneWidget);
      expect(
        find.text(OnboardingScreen.welcomeTrustLine),
        findsOneWidget,
      );
      // Never claims what cannot be checked.
      expect(OnboardingScreen.welcomeTrustLine.toLowerCase(),
          isNot(contains('no ads')));
      // Skip stays a 48dp target.
      expect(tester.getSize(find.widgetWithText(TextButton, 'Skip')).height,
          greaterThanOrEqualTo(48));
    });

    testWidgets('step 1: Next shows the goal choice', (tester) async {
      await pumpOnboarding(tester);
      expect(find.text('Next'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('WHAT BRINGS YOU HERE?'), findsOneWidget);
    });

    testWidgets('step 2: six goals are listed', (tester) async {
      await pumpOnboarding(tester);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      for (final String t in <String>[
        'Learning about Islam',
        'Peace for my heart',
        'Teaching my children',
        'Praying on time',
        'New to Islam or just curious',
        'A community',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
    });

    testWidgets('step 3: the last screen says Begin', (tester) async {
      await pumpOnboarding(tester);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Begin'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('step 4: choosing a goal then Begin saves it', (tester) async {
      final GoRouter router = await pumpOnboarding(tester);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Praying on time'));
      await tester.pump();
      await tester.tap(find.text('Begin'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.getString(OnboardingScreen.needPref), 'pray');
      expect(p.getBool(OnboardingScreen.pref), true);
      expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
          '/prayer');
    });

    testWidgets('Skip lands on Home and still marks it seen', (tester) async {
      final GoRouter router = await pumpOnboarding(tester);
      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(milliseconds: 300));
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.getBool(OnboardingScreen.pref), true);
      expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
          '/home');
    });

    testWidgets('200% text on a 320px phone: no overflow, goals reachable', (
      tester,
    ) async {
      await pumpOnboarding(tester, scale: 2.0);
      expect(tester.takeException(), isNull, reason: 'welcome page');
      expect(find.text('Next'), findsOneWidget, reason: 'Next present');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'goal page');
      expect(find.text('A community'), findsOneWidget, reason: 'goal built');
    });
  });

  group('home next step', () {
    testWidgets('no goal chosen: continue reading card', (tester) async {
      await AppHarness.boot(tester);
      expect(find.byKey(const Key('home-next-step')), findsOneWidget);
      expect(find.text('YOUR NEXT STEP'), findsOneWidget);
      expect(find.text('Begin with Al-Fatihah'), findsOneWidget);
    });

    testWidgets('new to Islam: Day N of the 30-day road', (tester) async {
      await AppHarness.boot(
        tester,
        prefsValues: <String, Object>{
          'ar.need': 'new',
          'ar.nm.done.a': true,
          'ar.nm.done.b': true,
        },
      );
      expect(find.text('Day 3 of the 30-day road'), findsOneWidget);
    });

    testWidgets('pray goal with a location: next prayer', (tester) async {
      await AppHarness.boot(
        tester,
        prefsValues: <String, Object>{
          'ar.need': 'pray',
          'ar.location.lat': 24.86,
          'ar.location.lng': 67.0,
          'ar.location.city': 'Karachi',
          'ar.location.country': 'Pakistan',
        },
      );
      expect(
        find.textContaining(RegExp(r'^Pray (Fajr|Dhuhr|Asr|Maghrib|Isha) at ')),
        findsOneWidget,
      );
    });

    testWidgets('learn goal opens the Academy lesson card', (tester) async {
      await AppHarness.boot(
        tester,
        prefsValues: <String, Object>{'ar.need': 'learn'},
      );
      expect(find.text('Start your first lesson'), findsOneWidget);
    });
  });

  group('small phone and big text', () {
    testWidgets('320px: the Prayer Times tile is on the first screen', (
      tester,
    ) async {
      await AppHarness.boot(tester);
      tester.view.physicalSize = const Size(320, 640);
      await AppHarness.settle(tester);
      expect(tester.takeException(), isNull, reason: 'no layout error');
      final Finder tile = find.text('Prayer Times');
      expect(tile, findsWidgets, reason: 'tile built on the first screen');
      final Rect r = tester.getRect(tile.first);
      expect(r.top, lessThan(560), reason: 'tile title at ${r.top}');
    });

    testWidgets('200% text: the Elder Mode card is on the first screen', (
      tester,
    ) async {
      await AppHarness.boot(tester);
      tester.view.physicalSize = const Size(360, 800);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await AppHarness.settle(tester);
      final Rect r = tester.getRect(find.text('ELDER MODE'));
      expect(r.bottom, lessThan(800), reason: 'elder card at ${r.top}');
    });

    testWidgets('320px: the Prayer Times location name is readable', (
      tester,
    ) async {
      await AppHarness.boot(
        tester,
        prefsValues: <String, Object>{
          'ar.location.lat': 24.86,
          'ar.location.lng': 67.0,
          'ar.location.city': 'My Location',
          'ar.location.country': '',
        },
      );
      tester.view.physicalSize = const Size(320, 640);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/prayer');
      expect(tester.takeException(), isNull, reason: 'no layout error');
      final Finder label = find.byKey(const Key('prayer-location-label'));
      expect(label, findsOneWidget);
      expect(tester.getSize(label).width, greaterThan(120));
      final RenderParagraph para = tester.renderObject<RenderParagraph>(label);
      expect(para.didExceedMaxLines, isFalse);
    });
  });
}
