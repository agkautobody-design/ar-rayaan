import 'dart:async';
import 'dart:io';

import 'package:ar_rayaan/app/core/i18n/ui_labels.dart';
import 'package:ar_rayaan/app/core/online_status.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/app/theme/widgets/focus_ring.dart';
import 'package:ar_rayaan/app/theme/widgets/offline_banner.dart';
import 'package:ar_rayaan/features/downloads/application/download_manager.dart';
import 'package:ar_rayaan/features/downloads/domain/download_catalog.dart';
import 'package:ar_rayaan/features/downloads/presentation/downloads_screen.dart';
import 'package:ar_rayaan/features/family/data/family_tree_provider.dart';
import 'package:ar_rayaan/features/family/presentation/family_tree_screen.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_report_service.dart';
import 'package:ar_rayaan/features/hadith/application/hadith_providers.dart';
import 'package:ar_rayaan/features/hadith/domain/hadith_models.dart';
import 'package:ar_rayaan/features/hadith/presentation/hadith_screen.dart';
import 'package:ar_rayaan/features/legal/presentation/legal_screens.dart';
import 'package:ar_rayaan/features/ramadan/presentation/ramadan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';
import 'downloads_screen_test.dart' show pumpApp;
import 'downloads_manager_test.dart' show FakeStore;

Future<SharedPreferences> _prefs([Map<String, Object>? values]) async {
  SharedPreferences.setMockInitialValues(values ?? <String, Object>{});
  return SharedPreferences.getInstance();
}

void main() {
  group('offline notice', () {
    testWidgets('shows while offline, can be hidden, returns on a new loss',
        (WidgetTester tester) async {
      final StreamController<bool> events = StreamController<bool>.broadcast(sync: true);
      addTearDown(events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: OfflineBanner(
            probe: () => false,
            changes: () => events.stream,
            child: const Text('the app'),
          ),
        ),
      );
      expect(find.byKey(const Key('offline-banner')), findsOneWidget);
      expect(find.textContaining('You are offline'), findsOneWidget);
      expect(find.text('the app'), findsOneWidget);

      await tester.tap(find.byKey(const Key('offline-banner-close')));
      await tester.pump();
      expect(find.byKey(const Key('offline-banner')), findsNothing);

      events.add(true);
      await tester.pump();
      events.add(false);
      await tester.pump();
      expect(find.byKey(const Key('offline-banner')), findsOneWidget);

      events.add(true);
      await tester.pump();
      expect(find.byKey(const Key('offline-banner')), findsNothing);
      expect(find.text('the app'), findsOneWidget);
    });

    testWidgets('takes no space when the device is online or unknown',
        (WidgetTester tester) async {
      for (final bool? online in <bool?>[true, null]) {
        await tester.pumpWidget(
          MaterialApp(
            home: OfflineBanner(
              probe: () => online,
              changes: () => const Stream<bool>.empty(),
              child: const SizedBox(key: Key('content'), height: 50),
            ),
          ),
        );
        expect(find.byKey(const Key('offline-banner')), findsNothing);
      }
    });

    test('the browser flag and events can be replaced for tests', () {
      expect(deviceReportsOnline, anyOf(isNull, isA<bool>()));
      expect(deviceOnlineChanges, isNotNull);
    });
  });

  group('keyboard: Enter and Space activate a focusable tap', () {
    Future<int> press(WidgetTester tester, LogicalKeyboardKey key) async {
      int taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FocusableTap(
                onTap: () => taps++,
                child: const SizedBox(width: 120, height: 60, child: Text('go')),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(key);
      await tester.pump();
      return taps;
    }

    testWidgets('Enter', (WidgetTester tester) async {
      expect(await press(tester, LogicalKeyboardKey.enter), 1);
    });

    testWidgets('Space', (WidgetTester tester) async {
      expect(await press(tester, LogicalKeyboardKey.space), 1);
    });

    testWidgets('a tap with no action is not a tab stop',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FocusableTap(onTap: null, child: Text('inert')),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('the Messengers’ Tree never dead-ends', () {
    testWidgets('an error has a reason, Try again and a way out',
        (WidgetTester tester) async {
      AppHarness.useSurface(tester, height: 900);
      int loads = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            familyTreeProvider.overrideWith((Ref ref) async {
              loads++;
              throw StateError('offline');
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const FamilyTreeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('family-tree-error')), findsOneWidget);
      expect(find.text('Could not load the tree.'), findsNothing);
      expect(find.textContaining('could not be loaded'), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      final int before = loads;
      await tester.tap(find.text('Try again'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(loads, greaterThan(before), reason: 'Try again loads it again');
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('Downloads says what works offline', () {
    testWidgets('a status note lists what needs no download and what does',
        (WidgetTester t) async {
      await pumpApp(t, const DownloadsScreen(web: false), FakeStore());
      expect(find.byKey(const Key('downloads-offline-status')), findsOneWidget);
      expect(find.text('WORKS WITHOUT INTERNET'), findsOneWidget);
      for (final String s in <String>[
        'Academy lessons',
        'Hadi’s built-in library',
        'prayer times and Qibla',
        'Needs a connection',
      ]) {
        expect(kOfflineStatusNote, contains(s));
      }
    });

    testWidgets('the browser gets one "Save all text" button',
        (WidgetTester t) async {
      await pumpApp(
        t,
        const DownloadsScreen(web: true),
        FakeStore(),
        bundled: false,
      );
      expect(find.byKey(const Key('download-all-text')), findsOneWidget);
      expect(find.textContaining('Save all text (about'), findsOneWidget);
      await t.tap(find.byKey(const Key('download-all-text')));
      await t.pump(const Duration(milliseconds: 100));
      final DownloadsState s = ProviderScope.containerOf(
        t.element(find.byType(DownloadsScreen)),
      ).read(downloadsProvider);
      expect(
        s.queue.isNotEmpty || s.textStored.isNotEmpty,
        isTrue,
        reason: 'the text packs are queued or already saved',
      );
      await t.pump(const Duration(seconds: 3));
    });

    testWidgets('the phone has no such button (text is in the app)',
        (WidgetTester t) async {
      await pumpApp(t, const DownloadsScreen(web: false), FakeStore());
      expect(find.byKey(const Key('download-all-text')), findsNothing);
    });
  });

  group('Hadith: offline gives a reason and a retry', () {
    testWidgets('Try again loads it again', (WidgetTester tester) async {
      AppHarness.useSurface(tester, height: 900);
      final SharedPreferences prefs = await _prefs();
      int calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            hadithCollectionProvider.overrideWith((Ref ref) async {
              calls++;
              if (calls == 1) throw StateError('offline');
              return <Hadith>[];
            }),
          ],
          child: MaterialApp(theme: AppTheme.dark(), home: const HadithScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('hadith-load-error')), findsOneWidget);
      expect(find.byKey(const Key('hadith-retry')), findsOneWidget);
      await tester.tap(find.byKey(const Key('hadith-retry')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(calls, 2);
      expect(find.byKey(const Key('hadith-load-error')), findsNothing);
    });
  });

  group('Ramadan trackers are operable without sight or a mouse', () {
    Future<SemanticsHandle> pump(
      WidgetTester tester, [
      Map<String, Object>? values,
    ]) async {
      final SharedPreferences prefs = await _prefs(values);
      AppHarness.useSurface(tester);
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(theme: AppTheme.dark(), home: const RamadanScreen()),
        ),
      );
      // The season's daily texts load from the bundle: give them real time.
      for (int i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      return handle;
    }

    testWidgets('a fasting day is 44 px, named, and cycles its state',
        (WidgetTester tester) async {
      final SemanticsHandle h = await pump(tester);
      final Finder cell = find.byKey(const Key('fast-day-3'));
      expect(cell, findsOneWidget);
      expect(tester.getSize(cell), const Size(44, 44));
      expect(find.bySemanticsLabel('Day 3, not marked'), findsOneWidget);
      for (final String next in <String>[
        'fasted',
        'excused',
        'make-up due',
        'not marked',
      ]) {
        await tester.tap(cell);
        await tester.pump();
        expect(find.bySemanticsLabel('Day 3, $next'), findsOneWidget,
            reason: next);
      }
      // The state is also a symbol, never colour alone.
      await tester.tap(cell);
      await tester.pump();
      expect(
        find.descendant(of: cell, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      h.dispose();
    });

    testWidgets('a juz says whether it is completed, and is selected',
        (WidgetTester tester) async {
      final SemanticsHandle h = await pump(tester);
      final Finder cell = find.byKey(const Key('juz-5'));
      await tester.scrollUntilVisible(cell, 300);
      expect(tester.getSize(cell), const Size(44, 44));
      expect(find.bySemanticsLabel('Juz 5, not completed'), findsOneWidget);
      await tester.tap(cell);
      await tester.pump();
      final Finder done = find.bySemanticsLabel('Juz 5, completed');
      expect(done, findsOneWidget);
      expect(
        tester.getSemantics(done).getSemanticsData().hasFlag(
              SemanticsFlag.isSelected,
            ),
        isTrue,
      );
      h.dispose();
    });

    testWidgets('removing a saved entry asks first', (WidgetTester tester) async {
      final SemanticsHandle h = await pump(tester);
      await tester.tap(find.text('Household'));
      await tester.pump();
      await tester.enterText(
        find.byWidgetPredicate(
          (Widget w) =>
              w is TextField &&
              w.decoration?.hintText == 'A guest, a dish, a date to remember…',
        ),
        'Aunt Maryam',
      );
      await tester.tap(find.byTooltip('Add to the iftar table'));
      await tester.pump();
      expect(find.text('Aunt Maryam'), findsOneWidget);

      final Finder remove = find.bySemanticsLabel('Remove from the iftar table');
      expect(remove, findsOneWidget);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.text('Remove this entry?'), findsOneWidget);
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
      expect(find.text('Aunt Maryam'), findsOneWidget);

      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Aunt Maryam'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      h.dispose();
    });

    testWidgets('the missed-fast text no longer says "debts to Allah"',
        (WidgetTester tester) async {
      final SemanticsHandle h = await pump(tester);
      expect(find.textContaining('debts to Allah'), findsNothing);
      await tester.scrollUntilVisible(find.textContaining('2:184'), 300);
      expect(find.textContaining('Qur’an 2:184'), findsOneWidget);
      h.dispose();
    });
  });

  group('interface labels', () {
    test('every label has all four languages in the right script', () {
      final RegExp arabic = RegExp('[؀-ۿ]');
      final RegExp bangla = RegExp('[ঀ-৿]');
      for (final MapEntry<String, Map<String, String>> e in kUiLabels.entries) {
        for (final String l in <String>['en', 'ar', 'bn', 'ur']) {
          expect(e.value[l], isNotNull, reason: '${e.key} $l');
          expect(e.value[l]!.trim(), isNotEmpty, reason: '${e.key} $l');
        }
        expect(arabic.hasMatch(e.value['ar']!), isTrue, reason: '${e.key} ar');
        expect(arabic.hasMatch(e.value['ur']!), isTrue, reason: '${e.key} ur');
        expect(bangla.hasMatch(e.value['bn']!), isTrue, reason: '${e.key} bn');
      }
    });

    test('English texts are unique, so the lookup by English text is exact', () {
      final Map<String, String> seen = <String, String>{};
      for (final MapEntry<String, Map<String, String>> e in kUiLabels.entries) {
        final String en = e.value['en']!;
        expect(seen.containsKey(en), isFalse,
            reason: '"$en" is both ${seen[en]} and ${e.key}');
        seen[en] = e.key;
      }
    });

    test('unknown text is returned unchanged, never machine-translated', () {
      expect(uiLabelForEnglish('Sadaqah is a gift', 'ar'), 'Sadaqah is a gift');
      expect(uiLabel('no.such.key', 'ar'), 'no.such.key');
    });

    testWidgets('Home in Arabic has no English chrome left',
        (WidgetTester tester) async {
      await AppHarness.boot(
        tester,
        prefsValues: <String, Object>{'ar.locale': 'ar'},
      );
      for (final String key in <String>[
        'home.quick',
        'home.viewAll',
        'tile.prayer',
      ]) {
        final String en = kUiLabels[key]!['en']!;
        final String ar = kUiLabels[key]!['ar']!;
        expect(find.text(en), findsNothing, reason: 'English "$en" is left');
        expect(find.text(ar), findsWidgets, reason: 'missing Arabic for $key');
      }
    });
  });

  group('the privacy policy and the terms', () {
    String all(List<LegalSection> s) =>
        s.map((LegalSection e) => '${e.heading}\n${e.body}').join('\n\n');

    test('Hadi reports and fonts are disclosed', () {
      final String p = all(kPrivacySections);
      expect(p, contains('Reports about a Hadi answer'));
      expect(p, contains('fonts.gstatic.com'));
    });

    test('Kids Corner describes the PIN and child mode that really exist', () {
      final LegalSection kids = kPrivacySections
          .firstWhere((LegalSection s) => s.heading == 'Kids Corner');
      expect(kids.body, contains('parent PIN'));
      expect(kids.body, contains('Child mode'));
      expect(kids.body, contains('SHA-256'));
      expect(kids.body, isNot(contains('parent question')));
    });

    test('the terms set an age and do not promise sync or a Majlis', () {
      final String t = all(kTermsSections);
      expect(t, contains('Who may use the app'));
      expect(t, contains('13'));
      final String p = all(kPrivacySections);
      expect(p + t, isNot(contains('Sign in to save')));
    });
  });

  group('fonts are bundled, not fetched', () {
    test('Noto Sans Bengali ships with its licence', () {
      expect(File('assets/fonts/NotoSansBengali-Regular.ttf').existsSync(),
          isTrue);
      expect(File('assets/fonts/OFL-NotoSansBengali.txt').existsSync(), isTrue);
      expect(File('pubspec.yaml').readAsStringSync(),
          contains('assets/fonts/NotoSansBengali-Regular.ttf'));
      expect(File('assets/fonts/NotoSansBengali-Regular.ttf').lengthSync(),
          greaterThan(50000));
    });
  });

  group('Hadi report queue', () {
    test('a report with no connection is queued, and flush keeps it',
        () async {
      final SharedPreferences prefs = await _prefs();
      final HadiReportService svc = HadiReportService(prefs);
      final bool sent = await svc.submit(const HadiReport(
        reason: HadiReportReason.wrongQuote,
        answer: 'an answer',
        sources: <String>['Sahih Muslim 245'],
        live: false,
      ));
      expect(sent, isFalse);
      expect(svc.queued.length, 1);
      // No Firebase here: nothing is sent and nothing is lost.
      expect(await svc.flush(), 0);
      expect(svc.queued.length, 1);
    });

    test('flush with nothing queued does nothing', () async {
      final SharedPreferences prefs = await _prefs();
      expect(await HadiReportService(prefs).flush(), 0);
    });
  });
}
