import 'dart:io';

import 'package:ar_rayaan/app/theme/widgets/app_bottom_nav.dart';
import 'package:ar_rayaan/features/elder/application/elder_mode.dart';
import 'package:ar_rayaan/features/journey/presentation/saved_stories_sheet.dart';
import 'package:ar_rayaan/features/sakina/application/sakina_providers.dart';
import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:ar_rayaan/features/sakina/presentation/widgets/need_help_button.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

/// Round 3: Elder Mode stays Elder Mode (Home tab), the help sheet can be
/// closed and can be pointed at another country, Text size is easy to find,
/// and a saved dua is named as a dua.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Story story(String id, String collection, String title) =>
      Story.fromJson(<String, dynamic>{
        'id': id,
        'collection': collection,
        'title': title,
        'kicker': 'K',
        'subtitle': 'S',
        'sourceLabel': 'Established',
        'sources': <String>['x'],
        'chapters': <Map<String, dynamic>>[
          <String, dynamic>{'heading': 'h', 'body': 'b'},
        ],
        'familyQuestion': 'q',
      });

  group('saved item names', () {
    test('a dua is listed under its own name, not its text title', () {
      expect(
        savedItemTitle(story('dua-anxiety', 'dailyduas', "The Heart's Unrest")),
        'Dua: Worry or anxiety',
      );
    });

    test('a dua without a chooser name still says it is a dua', () {
      expect(
        savedItemTitle(story('dua-other', 'dailyduas', 'Some Title')),
        'Dua: Some Title',
      );
    });

    test('a story keeps its title', () {
      expect(
        savedItemTitle(story('s1', 'prophets', 'The Cave')),
        'The Cave',
      );
    });
  });

  group('help sheet country choices', () {
    test('lists single countries by name, sorted, with Pakistan', () {
      final List<(String, String)> c = helpCountryChoices();
      expect(c.any(((String, String) e) => e.$1 == 'PK'), isTrue);
      expect(
        c.any(((String, String) e) => e.$2 == 'North America'),
        isFalse,
      );
      final List<String> names = <String>[for (final (_, n) in c) n];
      final List<String> sorted = List<String>.of(names)..sort();
      expect(names, sorted);
    });
  });

  group('help sheet', () {
    Future<void> open(WidgetTester tester, String country) async {
      tester.view.physicalSize = const Size(430, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            deviceCountryProvider.overrideWithValue(country),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (BuildContext context) => Scaffold(
                body: TextButton(
                  onPressed: () =>
                      showNeedHelpSheet(context, kind: CrisisKind.selfHarm),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('has a visible Close button that closes it', (tester) async {
      await open(tester, 'US');
      expect(find.byKey(const Key('need-help-close')), findsOneWidget);
      await tester.tap(find.byKey(const Key('need-help-close')));
      await tester.pumpAndSettle();
      expect(find.text('You do not have to carry this alone'), findsNothing);
    });

    testWidgets('a person can choose their own country', (tester) async {
      await open(tester, 'US');
      expect(find.textContaining('1122'), findsNothing);
      await tester.tap(find.byKey(const Key('need-help-country')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pakistan').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('1122'), findsWidgets);
    });

    testWidgets('an unknown country gets the find-your-number line', (
      tester,
    ) async {
      await open(tester, 'ZZ');
      expect(
        find.textContaining('Find your local emergency number'),
        findsOneWidget,
      );
    });
  });

  group('Elder Mode and the Home tab', () {
    testWidgets('Home tab opens the Elder home while Elder Mode is on', (
      tester,
    ) async {
      await AppHarness.boot(
        tester,
        prefsValues: <String, Object>{ElderMode.pref: true},
      );
      await AppHarness.go(tester, find.byType(Scaffold).first, '/explore');
      final Finder home = find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text('Home'),
      );
      expect(home, findsOneWidget);
      await tester.tap(home);
      await AppHarness.settle(tester);
      expect(
        AppHarness.location(tester, find.byType(Scaffold).first),
        ElderMode.homeRoute,
      );
    });

    testWidgets('Home tab still opens the normal Home when it is off', (
      tester,
    ) async {
      await AppHarness.boot(tester);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/explore');
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.text('Home'),
        ),
      );
      await AppHarness.settle(tester);
      expect(
        AppHarness.location(tester, find.byType(Scaffold).first),
        '/home',
      );
    });
  });

  group('Text size is easy to find', () {
    testWidgets('Settings shows Text size before anything else', (
      tester,
    ) async {
      await AppHarness.boot(tester);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/settings');
      final double sizeY = tester.getTopLeft(find.text('Text size')).dy;
      final double soundY = tester.getTopLeft(find.text('SOUND')).dy;
      expect(sizeY, lessThan(soundY));
      expect(sizeY, lessThan(400));
    });

    testWidgets('the Menu has a Text size row that opens Settings', (
      tester,
    ) async {
      await AppHarness.boot(tester);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/menu');
      final Finder row = find.textContaining('Text size');
      expect(row, findsOneWidget);
      await tester.ensureVisible(row);
      await tester.tap(row);
      await AppHarness.settle(tester);
      expect(
        AppHarness.location(tester, find.byType(Scaffold).first),
        '/settings',
      );
    });
  });

  group('layout fixes', () {
    test('Add child is a button in the page, not a floating one', () {
      final String src = File(
        'lib/features/academy/presentation/academy_family.dart',
      ).readAsStringSync();
      expect(src.contains('FloatingActionButton'), isFalse);
      expect(src.contains("Key('add-child')"), isTrue);
    });

    test('the lesson title is written in full, Next is a solid button', () {
      final String src = File(
        'lib/features/academy/presentation/wasia_lessons.dart',
      ).readAsStringSync();
      expect(src.contains("ScreenHeader(title: 'Letters lesson'"), isTrue);
      expect(src.contains("Key('lesson-next')"), isTrue);
    });
  });
}
