import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:ar_rayaan/features/support/presentation/need_help_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadi_eval/corpus_fixture.dart';

/// The "I need help" page: being heard comes first, the phone lines are
/// one quiet line at the bottom — and Hādi's opener for it is private,
/// warm and never saved.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NeedHelpScreen', () {
    Future<void> openPage(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(430, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(home: NeedHelpScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets('listening comes first, lines one quiet line at the bottom',
        (tester) async {
      await openPage(tester);
      expect(find.text('I Need Help'), findsOneWidget);
      expect(find.byKey(const Key('need-help-talk')), findsOneWidget);
      // Every starting point is a way in, none of them a phone number.
      for (final String slug in <String>[
        'heard',
        'far-from-allah',
        'habit',
        'heavy',
        'home',
        'lost-someone',
      ]) {
        expect(find.byKey(Key('need-help-chip-$slug')), findsOneWidget,
            reason: slug);
      }
      expect(find.byKey(const Key('need-help-lines')), findsOneWidget);
      // The talk button sits above the help-line link.
      expect(
        tester.getTopLeft(find.byKey(const Key('need-help-talk'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('need-help-lines'))).dy),
      );
    });

    testWidgets('the opener starts a private listening conversation',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final HadiCorpus corpus = loadRealCorpus();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          hadiCorpusProvider.overrideWith((ref) => corpus),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(hadiControllerProvider.notifier)
          .openFromSupport(kNeedHelpOpener);
      final HadiState s = container.read(hadiControllerProvider);
      expect(s.messages.length, 1);
      final HadiMessage m = s.messages.single;
      expect(m.fromHadi, isTrue);
      expect(m.text, kNeedHelpOpener);
      expect(m.sensitive, isTrue);
      expect(m.ephemeral, isTrue);
      expect(m.text, startsWith('As-salamu alaikum'));
      expect(m.text, contains('listening'));
      expect(m.text.toLowerCase(), contains('nothing you say'));
      // No phone numbers, no judgment words in the opener itself.
      expect(RegExp(r'\d{3,}').hasMatch(m.text), isFalse);
      expect(m.text.toLowerCase(), isNot(contains('haram')));
      expect(m.text.toLowerCase(), isNot(contains('sin')));
    });
  });
}
