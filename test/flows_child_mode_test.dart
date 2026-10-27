import 'package:ar_rayaan/app/core/child_mode.dart';
import 'package:ar_rayaan/app/core/kids_mode.dart';
import 'package:ar_rayaan/app/core/parent_pin.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/academy/presentation/academy_family.dart';
import 'package:ar_rayaan/features/academy/presentation/widgets/parent_gate.dart';
import 'package:ar_rayaan/features/kids/presentation/kids_corner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';

Future<SharedPreferences> _prefs([Map<String, Object>? values]) async {
  SharedPreferences.setMockInitialValues(values ?? <String, Object>{});
  return SharedPreferences.getInstance();
}

void main() {
  tearDown(() {
    kChildMode.value = false;
    kKidsMode.value = false;
  });

  group('ParentPin', () {
    test('4 to 6 digits, and not an obvious run', () {
      expect(ParentPin.problemWith('4827'), isNull);
      expect(ParentPin.problemWith('482715'), isNull);
      expect(ParentPin.problemWith('482'), isNotNull);
      expect(ParentPin.problemWith('4827159'), isNotNull);
      expect(ParentPin.problemWith('48a7'), isNotNull);
      expect(ParentPin.problemWith('1111'), isNotNull);
      expect(ParentPin.problemWith('1234'), isNotNull);
      expect(ParentPin.problemWith('9876'), isNotNull);
      expect(ParentPin.problemWith('0000'), isNotNull);
    });

    test('keeps a salted hash, never the PIN, and checks it', () async {
      final SharedPreferences prefs = await _prefs();
      final ParentPin pin = ParentPin(prefs);
      expect(pin.isSet, isFalse);
      await pin.set('4827');
      expect(pin.isSet, isTrue);
      final String stored = prefs.getString('ar.parent.pin.v1')!;
      expect(stored.contains('4827'), isFalse);
      expect(await pin.verify('4827'), isTrue);
      expect(await pin.verify('4828'), isFalse);
      // The same PIN on another device is stored differently (own salt).
      final SharedPreferences other = await _prefs();
      await ParentPin(other).set('4827');
      expect(other.getString('ar.parent.pin.v1'), isNot(stored));
    });

    test('five wrong tries lock it, even for the right PIN, for five minutes',
        () async {
      final SharedPreferences prefs = await _prefs();
      final ParentPin pin = ParentPin(prefs);
      await pin.set('4827');
      final DateTime t = DateTime(2026, 10, 20, 12);
      for (int i = 0; i < ParentPin.maxTries; i++) {
        expect(await pin.verify('0000', t), isFalse);
      }
      expect(pin.lockedFor(t), isNotNull);
      expect(await pin.verify('4827', t), isFalse, reason: 'still locked');
      expect(
        pin.lockedFor(t.add(const Duration(minutes: 4))),
        isNotNull,
      );
      final DateTime later = t.add(const Duration(minutes: 6));
      expect(pin.lockedFor(later), isNull);
      expect(await pin.verify('4827', later), isTrue);
    });

    test('the lock survives a reload (it is saved, not in memory)', () async {
      final SharedPreferences prefs = await _prefs();
      await ParentPin(prefs).set('4827');
      final DateTime t = DateTime(2026, 10, 20, 12);
      for (int i = 0; i < ParentPin.maxTries; i++) {
        await ParentPin(prefs).verify('0000', t);
      }
      expect(ParentPin(prefs).lockedFor(t), isNotNull);
    });
  });

  group('the PIN dialog', () {
    Future<List<bool>> open(
      WidgetTester tester,
      SharedPreferences prefs,
    ) async {
      final List<bool> results = <bool>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (BuildContext context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      results.add(await showParentGate(context));
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('no sum a child could answer', (WidgetTester tester) async {
      await open(tester, await _prefs());
      expect(find.text('For parents'), findsOneWidget);
      expect(find.textContaining('What is'), findsNothing);
      expect(find.textContaining('×'), findsNothing);
    });

    testWidgets('the first grown-up chooses a PIN, typed twice',
        (WidgetTester tester) async {
      final SharedPreferences prefs = await _prefs();
      final List<bool> results = await open(tester, prefs);
      expect(find.text('Save PIN'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('parent-pin-input')), '1234');
      await tester.enterText(find.byKey(const Key('parent-pin-confirm')), '1234');
      await tester.tap(find.text('Save PIN'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('parent-pin-error')), findsOneWidget);
      expect(find.textContaining('run of numbers'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('parent-pin-input')), '4827');
      await tester.enterText(find.byKey(const Key('parent-pin-confirm')), '4828');
      await tester.tap(find.text('Save PIN'));
      await tester.pumpAndSettle();
      expect(find.textContaining('not the same'), findsOneWidget);
      expect(results, isEmpty);

      await tester.enterText(find.byKey(const Key('parent-pin-confirm')), '4827');
      await tester.tap(find.text('Save PIN'));
      await tester.pumpAndSettle();
      expect(results, <bool>[true]);
      expect(ParentPin(prefs).isSet, isTrue);
    });

    testWidgets('with a PIN set: wrong tries are counted, then it locks',
        (WidgetTester tester) async {
      final SharedPreferences prefs = await _prefs();
      await ParentPin(prefs).set('4827');
      final List<bool> results = await open(tester, prefs);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byKey(const Key('parent-pin-confirm')), findsNothing);

      await tester.enterText(find.byKey(const Key('parent-pin-input')), '0001');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.textContaining('4 tries left'), findsOneWidget);

      for (int i = 0; i < 4; i++) {
        await tester.enterText(
          find.byKey(const Key('parent-pin-input')),
          '000${i + 2}',
        );
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Too many tries'), findsOneWidget);

      // The right PIN is refused while it is locked.
      await tester.enterText(find.byKey(const Key('parent-pin-input')), '4827');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(results, isEmpty);
      expect(find.textContaining('Too many tries'), findsOneWidget);
    });

    testWidgets('the right PIN opens it', (WidgetTester tester) async {
      final SharedPreferences prefs = await _prefs();
      await ParentPin(prefs).set('4827');
      final List<bool> results = await open(tester, prefs);
      await tester.enterText(find.byKey(const Key('parent-pin-input')), '4827');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(results, <bool>[true]);
    });

    testWidgets('Cancel is false', (WidgetTester tester) async {
      final List<bool> results = await open(tester, await _prefs());
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(results, <bool>[false]);
    });
  });

  group('child mode rules', () {
    test('only Kids Corner, the letters and the stories are for children', () {
      for (final String ok in <String>[
        '/kids',
        '/academy/letters',
        '/academy/letters/lesson/alif',
        '/academy/stories',
        '/stories/read',
      ]) {
        expect(childModeAllows(ok), isTrue, reason: ok);
      }
      for (final String no in <String>[
        '/',
        '/home',
        '/menu',
        '/hadi',
        '/settings',
        '/finance',
        '/finance/floor',
        '/academy',
        '/academy/family',
        '/academy/family-life',
        '/academy/youth',
        '/community/hub',
        '/games',
        '/quran',
        '/kidsandmore',
        '/stories',
      ]) {
        expect(childModeAllows(no), isFalse, reason: no);
      }
    });

    test('the redirect only acts while child mode is on', () {
      kChildMode.value = false;
      expect(childModeRedirect('/menu'), isNull);
      kChildMode.value = true;
      expect(childModeRedirect('/menu'), '/kids');
      expect(childModeRedirect('/kids'), isNull);
    });

    test('it is saved, and loaded again at start-up', () async {
      final SharedPreferences prefs = await _prefs();
      await setChildMode(prefs, true);
      expect(kChildMode.value, isTrue);
      expect(kKidsMode.value, isTrue);
      kChildMode.value = false;
      kKidsMode.value = false;
      loadChildMode(prefs);
      expect(kChildMode.value, isTrue);
      expect(kKidsMode.value, isTrue);
      await setChildMode(prefs, false);
      loadChildMode(prefs);
      expect(kChildMode.value, isFalse);
    });

    test('the games door is left out in child mode', () {
      expect(
        kidsDoorsFor(showAcademy: true, childMode: true)
            .map((KidsDoor d) => d.id),
        <String>['letters', 'stories'],
      );
      expect(
        kidsDoorsFor(showAcademy: true).map((KidsDoor d) => d.id),
        contains('games'),
      );
    });
  });

  group('child mode in the app', () {
    testWidgets('every adult screen leads back to Kids Corner, no menus',
        (WidgetTester tester) async {
      kChildMode.value = true;
      kKidsMode.value = true;
      await AppHarness.boot(tester);
      Finder anchor() => find.byType(Scaffold).first;
      expect(AppHarness.location(tester, anchor()), '/kids');
      for (final String p in <String>[
        '/home',
        '/menu',
        '/hadi',
        '/settings',
        '/finance',
        '/academy/family-life',
        '/academy/family',
        '/community/hub',
        '/games',
        '/quran',
      ]) {
        await AppHarness.go(tester, anchor(), p);
        expect(AppHarness.location(tester, anchor()), '/kids', reason: p);
      }
      // No bottom navigation, no Settings gear, no Ask Hadi pill, no Games.
      expect(find.text('Faith'), findsNothing);
      expect(find.byTooltip('Settings'), findsNothing);
      expect(find.text('Ask Hādi'), findsNothing);
      expect(find.text('Games'), findsNothing);
      expect(find.text('Arabic letters'), findsOneWidget);
      expect(find.text('Stories school'), findsOneWidget);
      expect(find.byKey(const Key('kids-child-mode')), findsNothing);
    });

    testWidgets('leaving needs the PIN, and turns child mode off',
        (WidgetTester tester) async {
      kChildMode.value = true;
      kKidsMode.value = true;
      final AppHarness h = await AppHarness.boot(
        tester,
        prefsValues: <String, Object>{'ar.childMode.v1': true},
      );
      await ParentPin(h.prefs).set('4827');
      await tester.tap(find.byTooltip('Back'));
      await AppHarness.settle(tester);
      expect(find.text('For parents'), findsOneWidget);
      // A wrong PIN keeps it shut.
      await tester.enterText(find.byKey(const Key('parent-pin-input')), '9999');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(kChildMode.value, isTrue);
      expect(find.textContaining('not the PIN'), findsOneWidget);
      // The right one opens the app again.
      await tester.enterText(find.byKey(const Key('parent-pin-input')), '4827');
      await tester.tap(find.text('Continue'));
      await AppHarness.settle(tester);
      expect(kChildMode.value, isFalse);
      expect(h.prefs.getBool('ar.childMode.v1'), isFalse);
      expect(
        AppHarness.location(tester, find.byType(Scaffold).first),
        '/home',
      );
      expect(find.text('Faith'), findsOneWidget);
    });

    testWidgets('a parent starts child mode from Kids Corner',
        (WidgetTester tester) async {
      final AppHarness h = await AppHarness.boot(tester);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/kids');
      expect(find.text('Games'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsNothing);
      await tester.tap(find.byKey(const Key('kids-child-mode')));
      await AppHarness.settle(tester);
      expect(find.text('Save PIN'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('parent-pin-input')), '4827');
      await tester.enterText(find.byKey(const Key('parent-pin-confirm')), '4827');
      await tester.tap(find.text('Save PIN'));
      await AppHarness.settle(tester);
      expect(kChildMode.value, isTrue);
      expect(h.prefs.getBool('ar.childMode.v1'), isTrue);
      expect(ParentPin(h.prefs).isSet, isTrue);
      expect(find.text('Games'), findsNothing);
      expect(find.text('Faith'), findsNothing);
      expect(find.byKey(const Key('kids-child-mode')), findsNothing);
    });

    testWidgets('Kids Corner closes the parent gate when it opens',
        (WidgetTester tester) async {
      await AppHarness.boot(tester);
      final ProviderContainer c = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      c.read(parentGateProvider.notifier).unlock();
      expect(c.read(parentGateProvider.notifier).isOpen(), isTrue);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/kids');
      expect(c.read(parentGateProvider.notifier).isOpen(), isFalse);
    });
  });

  group('the Family Wing', () {
    testWidgets('has a Lock button that shuts it again',
        (WidgetTester tester) async {
      final SharedPreferences prefs = await _prefs();
      AppHarness.useSurface(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            parentGateProvider.overrideWith((Ref ref) {
              final ParentGateNotifier n = ParentGateNotifier()..unlock();
              return n;
            }),
          ],
          child: const MaterialApp(home: FamilyScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('family-lock')), findsOneWidget);
      expect(find.byKey(const Key('child-mode-start')), findsOneWidget);
      await tester.tap(find.byKey(const Key('family-lock')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('family-lock')), findsNothing);
      expect(find.byKey(const Key('family-locked-about')), findsOneWidget);
    });
  });
}
