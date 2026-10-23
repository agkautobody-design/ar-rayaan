import 'package:ar_rayaan/features/academy/presentation/academy_family.dart';
import 'package:ar_rayaan/features/noor/application/noor_providers.dart';
import 'package:ar_rayaan/features/noor/domain/noor_entry.dart';
import 'package:ar_rayaan/features/stories/data/stories_repository.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

/// Large text on a narrow phone: the screens below must lay out without an
/// overflow and keep whole words (no label broken one letter per line).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const NoorEntry noor = NoorEntry(
    kind: NoorKind.quran,
    reference: '13:28',
    arabic: 'أَلَا بِذِكْرِ',
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
    sources: const <String>['Q 1:1'],
    chapters: const <StoryChapter>[
      StoryChapter(heading: 'h', body: 'long enough body text here to pass'),
    ],
    familyQuestion: 'q?',
  );

  void bigText(WidgetTester tester, {double width = 360, double height = 800}) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> expectCleanAt(
    WidgetTester tester,
    String path, {
    double width = 360,
  }) async {
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
    bigText(tester, width: width);
    await AppHarness.settle(tester);
    // Let the Academy gate's three-second pause run out (no pending timer).
    await tester.pump(const Duration(seconds: 4));
    final List<String> errors = <String>[];
    Object? e = tester.takeException();
    while (e != null) {
      errors.add(e.toString().split('\n').first);
      e = tester.takeException();
    }
    expect(errors, isEmpty, reason: '$path at ${width}px, text 2.0x: $errors');
  }

  for (final String path in <String>[
    '/settings',
    '/menu',
    '/explore',
    '/profile',
    '/noor',
    '/stories',
    '/home/elder',
    '/academy/gate',
  ]) {
    testWidgets('$path lays out at 360px wide and 2.0x text', (tester) async {
      await expectCleanAt(tester, path);
    });
  }

  testWidgets('Settings keeps "Ambient Sound" whole on a very narrow screen', (
    tester,
  ) async {
    await expectCleanAt(tester, '/settings', width: 280);
    final Finder label = find.text('Ambient Sound');
    expect(label, findsOneWidget);
    // One letter per line would make the label dozens of lines tall.
    expect(tester.getSize(label).height, lessThan(120));
  });

  testWidgets('the Academy gate draws no sharp copy of the artwork', (
    tester,
  ) async {
    await expectCleanAt(tester, '/academy/gate');
    // Only the blurred, covering backdrop: the artwork has the Welcome screen's words
    // baked in and must not sit under the gate's own text.
    final Iterable<Image> sharp = tester
        .widgetList<Image>(find.byType(Image))
        .where((Image i) => i.fit == BoxFit.contain);
    expect(sharp, isEmpty);
  });

  group('child consent dialog', () {
    Future<void> open(WidgetTester tester, List<bool> out) async {
      bigText(tester, height: 700);
      await tester.pumpWidget(
        MaterialApp(
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

    testWidgets('the tick box stays visible and Continue says why it waits', (
      tester,
    ) async {
      final List<bool> out = <bool>[];
      await open(tester, out);
      expect(tester.takeException(), isNull);
      expect(find.byType(CheckboxListTile).hitTestable(), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.byKey(const Key('consent-hint')), findsOneWidget);
      expect(out, isEmpty, reason: 'not agreed: dialog stays open');

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(find.byKey(const Key('consent-hint')), findsNothing);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(out, <bool>[true]);
    });
  });

  testWidgets('sharing Today’s NOOR copies it and says so', (tester) async {
    String? copied;
    final TestDefaultBinaryMessenger messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await AppHarness.boot(
      tester,
      overrides: [todayNoorProvider.overrideWith((ref) async => noor)],
    );
    await AppHarness.go(tester, find.byType(Scaffold).first, '/noor');
    final Finder share = find.byKey(const Key('noor-share'));
    expect(share, findsOneWidget);
    expect(tester.getSize(share).shortestSide, greaterThanOrEqualTo(48));
    await tester.tap(share);
    await tester.pump();
    expect(find.textContaining('Copied'), findsOneWidget);
    expect(copied, contains('Verily, in the remembrance of Allah'));
  });
}
