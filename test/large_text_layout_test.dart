import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/app/theme/widgets/switch_row.dart';
import 'package:ar_rayaan/features/academy/presentation/academy_family.dart';
import 'package:ar_rayaan/features/auth/application/auth_providers.dart';
import 'package:ar_rayaan/features/auth/data/fake_auth_repository.dart';
import 'package:ar_rayaan/features/elder/presentation/elder_home_screen.dart';
import 'package:ar_rayaan/features/noor/application/noor_providers.dart';
import 'package:ar_rayaan/features/noor/domain/noor_entry.dart';
import 'package:ar_rayaan/features/noor/presentation/noor_screen.dart';
import 'package:ar_rayaan/features/profile/presentation/profile_screen.dart';
import 'package:ar_rayaan/features/stories/data/stories_repository.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';

/// Large text on a narrow phone: the screens below must lay out without an
/// overflow and keep whole words (no label broken one letter per line).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const NoorEntry noor = NoorEntry(
    kind: NoorKind.quran,
    reference: '13:28',
    arabic: 'أَلَا',
    english: 'Verily, in the remembrance of Allah do hearts find rest.',
    source: 'Qur’an 13:28',
    prompt: 'Pause and remember.',
  );

  const Story story = Story(
    id: 'lt1',
    collection: 'prophets',
    title: 'A story with a rather long title to wrap',
    kicker: 'K',
    subtitle: 'A subtitle that is long enough to need two lines on a phone',
    sourceLabel: 'Established',
    sources: <String>['Q 1:1'],
    chapters: <StoryChapter>[
      StoryChapter(heading: 'h', body: 'long enough body text here to pass'),
    ],
    familyQuestion: 'q?',
  );

  void bigText(
    WidgetTester tester, {
    double width = 360,
    double height = 800,
    double scale = 2.0,
  }) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  List<String> drain(WidgetTester tester) {
    final List<String> errors = <String>[];
    Object? e = tester.takeException();
    while (e != null) {
      errors.add(e.toString().split('\n').first);
      e = tester.takeException();
    }
    return errors;
  }

  // ---- Through the real router -------------------------------------------

  Future<void> expectCleanAt(WidgetTester tester, String path) async {
    await AppHarness.boot(
      tester,
      overrides: [
        todayNoorProvider.overrideWith((ref) async => noor),
        storiesProvider.overrideWith((ref) async => <Story>[story]),
      ],
    );
    // Open the screen at the normal size first, so Home (which other work is
    // fixing) is gone before the big text starts; only the screen under test
    // is laid out at 2.0x.
    await AppHarness.go(tester, find.byType(Scaffold).first, path);
    tester.takeException();
    bigText(tester);
    await AppHarness.settle(tester);
    // Let the Academy gate's three-second pause run out (no pending timer).
    await tester.pump(const Duration(seconds: 4));
    final List<String> errors = drain(tester);
    expect(errors, isEmpty, reason: '$path at 360px, text 2.0x: $errors');
  }

  for (final String path in <String>[
    '/settings',
    '/menu',
    '/explore',
    '/stories',
    '/academy/gate',
  ]) {
    testWidgets('$path lays out at 360px wide and 2.0x text', (tester) async {
      await expectCleanAt(tester, path);
    });
  }

  testWidgets('the Academy gate draws no sharp copy of the artwork', (
    tester,
  ) async {
    await expectCleanAt(tester, '/academy/gate');
    // Only the blurred, covering backdrop: the artwork has the Welcome
    // screen's words baked in and must not sit under the gate's own text.
    final Iterable<Image> sharp = tester
        .widgetList<Image>(find.byType(Image))
        .where((Image i) => i.fit == BoxFit.contain);
    expect(sharp, isEmpty);
  });

  // ---- A screen on its own -----------------------------------------------

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    List<Override> overrides = const <Override>[],
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final FakeAuthRepository auth = FakeAuthRepository(prefs);
    await auth.init();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
          ...overrides,
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: screen),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('the You tab lays out at 360px wide and 2.0x text', (
    tester,
  ) async {
    bigText(tester);
    await pumpScreen(tester, const ProfileScreen());
    expect(drain(tester), isEmpty);
  });

  testWidgets('the Elder home lays out at 360px wide and 2.0x text', (
    tester,
  ) async {
    bigText(tester);
    await pumpScreen(tester, const ElderHomeScreen());
    expect(drain(tester), isEmpty);
  });

  testWidgets('Today’s NOOR lays out at 360px wide and 2.0x text', (
    tester,
  ) async {
    bigText(tester);
    await pumpScreen(
      tester,
      const NoorScreen(),
      overrides: [todayNoorProvider.overrideWith((ref) async => noor)],
    );
    expect(drain(tester), isEmpty);
  });

  testWidgets('a switch row keeps whole words in a very narrow column', (
    tester,
  ) async {
    bigText(tester, width: 180, scale: 1.0);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: SwitchRow(
                icon: Icons.graphic_eq,
                title: 'Ambient Sound',
                subtitle: 'Gentle soundscape',
                value: true,
                onChanged: (bool _) {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(drain(tester), isEmpty);
    // One letter per line would make the title dozens of lines tall.
    expect(tester.getSize(find.text('Ambient Sound')).height, lessThan(80));
  });

  // ---- Consent dialog ----------------------------------------------------

  group('child consent dialog', () {
    Future<void> open(WidgetTester tester, List<bool> out) async {
      bigText(tester, height: 600, scale: 1.0);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () async =>
                  out.add(await showChildrenConsent(context)),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens without an overflow', (tester) async {
      await open(tester, <bool>[]);
      expect(drain(tester), isEmpty);
    });

    testWidgets('the tick box is on screen, not scrolled away', (tester) async {
      await open(tester, <bool>[]);
      expect(find.byType(CheckboxListTile).hitTestable(), findsOneWidget);
    });

    testWidgets('Continue without the tick says why and stays open', (
      tester,
    ) async {
      final List<bool> out = <bool>[];
      await open(tester, out);
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.byKey(const Key('consent-hint')), findsOneWidget);
      expect(out, isEmpty);
    });

    testWidgets('ticking the box lets Continue agree', (tester) async {
      final List<bool> out = <bool>[];
      await open(tester, out);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(out, <bool>[true]);
    });
  });

  // ---- Share on Today's NOOR --------------------------------------------

  group('Today’s NOOR share', () {
    testWidgets('is a 48dp tap target', (tester) async {
      await pumpScreen(
        tester,
        const NoorScreen(),
        overrides: [todayNoorProvider.overrideWith((ref) async => noor)],
      );
      final Finder share = find.byKey(const Key('noor-share'));
      expect(share, findsOneWidget);
      expect(tester.getSize(share).shortestSide, greaterThanOrEqualTo(48));
    });

    testWidgets('copies the entry and shows a snackbar', (tester) async {
      String? copied;
      final TestDefaultBinaryMessenger messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await pumpScreen(
        tester,
        const NoorScreen(),
        overrides: [todayNoorProvider.overrideWith((ref) async => noor)],
      );
      await tester.ensureVisible(find.byKey(const Key('noor-share')));
      await tester.tap(find.byKey(const Key('noor-share')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Copied'), findsOneWidget);
      expect(copied, contains('Verily, in the remembrance of Allah'));
    });
  });
}
