import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/adhkar/application/adhkar_providers.dart';
import 'package:ar_rayaan/features/adhkar/data/bundled_adhkar_repository.dart';
import 'package:ar_rayaan/features/adhkar/domain/adhkar_models.dart';
import 'package:ar_rayaan/features/adhkar/presentation/adhkar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dhikr & Du'a opens on a chooser of moments, not on a 351-count set.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('chooser data', () {
    test('every single dua it links to exists in the Daily Duas pack', () {
      final List<dynamic> pack = jsonDecode(
        File('assets/stories/dailyduas.json').readAsStringSync(),
      ) as List<dynamic>;
      final Set<String> ids = <String>{
        for (final dynamic s in pack) (s as Map<String, dynamic>)['id'] as String,
      };
      for (final AdhkarChoice c in kAdhkarDuaChoices) {
        expect(c.storyId, isNotNull);
        expect(ids, contains(c.storyId), reason: c.label);
      }
      // Worry or anxiety goes to the existing "Heart's Unrest" dua.
      final AdhkarChoice worry = kAdhkarDuaChoices
          .firstWhere((AdhkarChoice c) => c.label == 'Worry or anxiety');
      expect(worry.storyId, 'dua-anxiety');
      final Map<String, dynamic> unrest = pack
          .cast<Map<String, dynamic>>()
          .firstWhere((Map<String, dynamic> s) => s['id'] == 'dua-anxiety');
      expect(unrest['title'], "The Heart's Unrest");
    });

    test('every counted set it links to exists in the adhkar data', () {
      final Map<String, dynamic> data = jsonDecode(
        File('assets/adhkar/adhkar.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final Set<String> ids = <String>{
        for (final dynamic s in data['sets'] as List<dynamic>)
          (s as Map<String, dynamic>)['id'] as String,
      };
      for (final AdhkarChoice c in kAdhkarSetChoices) {
        expect(ids, contains(c.setId), reason: c.label);
      }
    });

    test('labels are short and plain', () {
      for (final AdhkarChoice c in <AdhkarChoice>[
        ...kAdhkarSetChoices,
        ...kAdhkarDuaChoices,
      ]) {
        expect(c.label.length, lessThanOrEqualTo(20), reason: c.label);
        expect(c.label, isNot(contains('Ayat')));
      }
    });
  });

  group('screen', () {
    Future<(BundledAdhkarRepository, SharedPreferences)> setUpData(
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final BundledAdhkarRepository repo = BundledAdhkarRepository();
      await tester.runAsync(() => repo.sets());
      return (repo, prefs);
    }

    Future<void> pump(
      WidgetTester tester,
      Widget home,
      BundledAdhkarRepository repo,
      SharedPreferences prefs,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            adhkarRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(theme: AppTheme.dark(), home: home),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('opens on the chooser, with no repetition count', (
      WidgetTester tester,
    ) async {
      final (BundledAdhkarRepository repo, SharedPreferences prefs) =
          await setUpData(tester);
      await pump(tester, const AdhkarScreen(), repo, prefs);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('adhkar-chooser')), findsOneWidget);
      for (final String label in <String>[
        'Morning',
        'Evening',
        'After prayer',
        'Before sleep',
        'Waking up',
        'Worry or anxiety',
        'Travel',
        'Entering home',
        'Forgiveness',
        'All duas by moment',
        'For Your Heart',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.textContaining('351'), findsNothing);
      expect(find.textContaining('repetitions'), findsNothing);
    });

    testWidgets('a counted set opens from the chooser and goes back', (
      WidgetTester tester,
    ) async {
      final (BundledAdhkarRepository repo, SharedPreferences prefs) =
          await setUpData(tester);
      await pump(tester, const AdhkarScreen(), repo, prefs);
      await tester.tap(find.text('Evening'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('adhkar-chooser')), findsNothing);
      expect(find.text('Evening Adhkar'), findsWidgets);
      await tester.tap(find.byKey(const Key('adhkar-all-duas')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('adhkar-chooser')), findsOneWidget);
    });

    testWidgets('a deep link to a set still opens that set', (
      WidgetTester tester,
    ) async {
      final (BundledAdhkarRepository repo, SharedPreferences prefs) =
          await setUpData(tester);
      await pump(tester, const AdhkarScreen(initialSet: 'evening'), repo, prefs);
      expect(find.byKey(const Key('adhkar-chooser')), findsNothing);
      expect(find.text('Evening Adhkar'), findsWidgets);
    });

    testWidgets('an unknown set id falls back to the chooser', (
      WidgetTester tester,
    ) async {
      final (BundledAdhkarRepository repo, SharedPreferences prefs) =
          await setUpData(tester);
      await pump(tester, const AdhkarScreen(initialSet: 'nope'), repo, prefs);
      expect(find.byKey(const Key('adhkar-chooser')), findsOneWidget);
    });

    testWidgets('"Worry or anxiety" opens the Heart\'s Unrest dua', (
      WidgetTester tester,
    ) async {
      final (BundledAdhkarRepository repo, SharedPreferences prefs) =
          await setUpData(tester);
      String? opened;
      final GoRouter router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext c, GoRouterState s) => const AdhkarScreen(),
          ),
          GoRoute(
            path: '/stories/read',
            builder: (BuildContext c, GoRouterState s) {
              opened = s.uri.toString();
              return const Scaffold(body: Text('story page'));
            },
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            adhkarRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp.router(
            theme: AppTheme.dark(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Worry or anxiety'));
      await tester.pumpAndSettle();
      expect(opened, '/stories/read?id=dua-anxiety');
    });

    testWidgets('a transliteration, when the data has one, is shown', (
      WidgetTester tester,
    ) async {
      final (BundledAdhkarRepository _, SharedPreferences prefs) =
          await setUpData(tester);
      const AdhkarSet set = AdhkarSet(
        id: 'morning',
        titleEn: 'Morning Adhkar',
        titleAr: 'x',
        items: <Dhikr>[
          Dhikr(
            number: 1,
            arabic: 'x',
            count: 1,
            translation: 'meaning',
            transliteration: 'sample reading',
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            adhkarSetsProvider.overrideWith((ref) async => <AdhkarSet>[set]),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const AdhkarScreen(initialSet: 'morning'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('sample reading'), findsOneWidget);
    });
  });
}
