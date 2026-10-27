import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:ar_rayaan/features/hadi/presentation/hadi_screen.dart';
import 'package:ar_rayaan/features/hadi/presentation/hadi_widgets.dart';
import 'package:ar_rayaan/features/stories/data/stories_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'app_harness.dart';
import 'hadi_eval/corpus_fixture.dart';

/// Round 5 first-time-user study, Hādi: one plain scope reply, a plain
/// header label that does not overlap the chat, and buttons that wrap.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const List<String> everyday = <String>[
    'what time is it in Tokyo',
    'how do i make friends in a new city',
    'what should i have for lunch',
    'what is the best laptop',
    'Who will win the football match?',
    'how to plan my weekend',
    'time management tips',
  ];

  group('one plain scope reply for everything Hādi cannot answer', () {
    test('every everyday question gets the same reply, with no jargon',
        () async {
      for (final String q in everyday) {
        final String a = await const OfflineHadiProvider()
            .ask(q, const <HadiMessage>[]);
        expect(OfflineHadiProvider.isDecline(a), isTrue, reason: q);
        expect(a.contains('API'), isFalse, reason: q);
        expect(a.toLowerCase().contains('key'), isFalse, reason: q);
        expect(a.contains('settings'), isFalse, reason: q);
      }
      expect(OfflineHadiProvider.offTopicReply, OfflineHadiProvider.decline);
      expect(OfflineHadiProvider.declineKeyed, OfflineHadiProvider.decline);
    });

    test('the same reply with or without a live key', () async {
      for (final String q in everyday) {
        final String a = await const OfflineHadiProvider(hasKey: true)
            .ask(q, const <HadiMessage>[]);
        expect(OfflineHadiProvider.isDecline(a), isTrue, reason: q);
      }
    });

    test('an unreadable script no longer mentions an API key', () {
      expect(OfflineHadiProvider.scriptReply.contains('API'), isFalse);
      expect(OfflineHadiProvider.scriptReplyUrdu.contains('API'), isFalse);
    });

    test('no unrelated buttons under an everyday question', () async {
      for (final String q in everyday) {
        final String a = await const OfflineHadiProvider()
            .ask(q, const <HadiMessage>[]);
        expect(OfflineHadiProvider.refusalRoutes(q, a), isEmpty, reason: q);
      }
    });

    test('a question near a topic still gets that topic and Search',
        () async {
      const String q = 'who was abu bakr';
      final String a =
          await const OfflineHadiProvider().ask(q, const <HadiMessage>[]);
      final List<String> routes = OfflineHadiProvider.refusalRoutes(q, a);
      expect(routes.first, '/stories');
      expect(routes, contains('/search'));
      expect(routes.contains('/prayer'), isFalse);
    });
  });

  group('the action button never clips its label', () {
    Future<void> pumpButton(
      WidgetTester tester, {
      required double width,
      required double scale,
      required String label,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: width,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      HadiActionButton(
                        label: label,
                        icon: Icons.arrow_forward,
                        strong: true,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (final double scale in <double>[1.0, 2.0]) {
      testWidgets('a long label wraps in full at ${scale}x text',
          (WidgetTester tester) async {
        const String label = 'Open Questions and Answers about the four schools';
        await pumpButton(tester, width: 288, scale: scale, label: label);
        expect(tester.takeException(), isNull);
        final Finder text = find.text(label);
        expect(text, findsOneWidget);
        final Text widget = tester.widget<Text>(text);
        expect(widget.softWrap, isTrue);
        expect(widget.overflow, isNull);
        expect(widget.maxLines, isNull);
        final Size button = tester.getSize(find.byType(HadiActionButton));
        expect(button.height, greaterThanOrEqualTo(48));
        expect(button.width, lessThanOrEqualTo(288));
        // The text box sits fully inside the button.
        final Rect b = tester.getRect(find.byType(HadiActionButton));
        final Rect t = tester.getRect(text);
        expect(t.left, greaterThanOrEqualTo(b.left));
        expect(t.right, lessThanOrEqualTo(b.right));
        expect(t.top, greaterThanOrEqualTo(b.top));
        expect(t.bottom, lessThanOrEqualTo(b.bottom));
      });
    }

    testWidgets('a short label is still 48 dp tall and one line',
        (WidgetTester tester) async {
      await pumpButton(tester, width: 300, scale: 1, label: 'Open Prayer Times');
      expect(
        tester.getSize(find.byType(HadiActionButton)).height,
        greaterThanOrEqualTo(48),
      );
      expect(find.text('Open Prayer Times'), findsOneWidget);
    });
  });

  group('the Hādi screen', () {
    List<Override> fixtures() => <Override>[
          hadiCorpusProvider.overrideWith((ref) => loadRealCorpus()),
          storiesProvider.overrideWith((ref) async => const []),
        ];

    void resize(WidgetTester tester, double w, double h, double scale) {
      tester.view.physicalSize = Size(w, h);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    for (final (double, double, double) c in <(double, double, double)>[
      (320, 640, 1.0),
      (360, 800, 1.3),
      (1100, 800, 1.0),
    ]) {
      testWidgets('plain header label, no overlap, at ${c.$1}dp ${c.$3}x',
          (WidgetTester tester) async {
        await AppHarness.boot(tester, overrides: fixtures());
        await AppHarness.go(tester, find.byType(Scaffold).first, '/hadi');
        resize(tester, c.$1, c.$2, c.$3);
        await AppHarness.settle(tester);
        expect(find.text('Hādi · built-in library'), findsOneWidget);
        expect(find.text('Hādi · offline'), findsNothing);
        final Finder pill = find.byKey(const Key('hadi-status-pill'));
        expect(pill, findsOneWidget);
        final Rect pillRect = tester.getRect(pill);
        final Rect list = tester.getRect(find
            .descendant(
                of: find.byType(HadiScreen), matching: find.byType(ListView))
            .first);
        // The chat starts below the header band.
        expect(pillRect.bottom, lessThanOrEqualTo(list.top));
        // The pill is never squeezed to nothing.
        expect(pillRect.width, greaterThan(120));
        // Every suggestion button is 48 dp tall at least.
        for (final Element e
            in find.byType(HadiActionButton).evaluate()) {
          expect(
            (e.renderObject! as RenderBox).size.height,
            greaterThanOrEqualTo(48),
          );
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('an everyday question shows the one scope reply and a small '
        'optional online line, with no unrelated buttons',
        (WidgetTester tester) async {
      await AppHarness.boot(tester, overrides: fixtures());
      await AppHarness.go(tester, find.byType(Scaffold).first, '/hadi');
      final Finder field = find.descendant(
          of: find.byType(HadiScreen), matching: find.byType(TextField));
      await tester.enterText(field, 'what time is it in Tokyo');
      await tester.pump();
      await tester.tap(find.descendant(
          of: find.byType(HadiScreen), matching: find.byIcon(Icons.send)));
      await AppHarness.settle(tester);
      expect(find.textContaining('I only cover Islam'), findsOneWidget);
      expect(find.textContaining('API key'), findsNothing);
      expect(find.byKey(const Key('hadi-online-mode')), findsOneWidget);
      expect(find.text('Open Prayer Times'), findsNothing);
      expect(find.textContaining('These may help'), findsNothing);
    });
  });
}
