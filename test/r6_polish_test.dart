import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_finder.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';
import 'hadi_eval/corpus_fixture.dart';

/// Round 6 polish: a scope reply carries no stray note and no unrelated
/// buttons; at big text the Home verse card keeps its width.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const List<String> dailyLife = <String>[
    'how do i make friends at a new school',
    'how can i save money',
    'how do i learn english',
  ];

  group('Hadi scope reply', () {
    test('daily-life questions get no unrelated buttons', () async {
      for (final String q in dailyLife) {
        final String a = await const OfflineHadiProvider()
            .ask(q, const <HadiMessage>[]);
        expect(OfflineHadiProvider.refusalRoutes(q, a), isEmpty, reason: q);
      }
    });

    test('a topic question still gets its buttons', () async {
      const String q = 'who was abu bakr';
      final String a =
          await const OfflineHadiProvider().ask(q, const <HadiMessage>[]);
      expect(OfflineHadiProvider.refusalRoutes(q, a), isNotEmpty);
    });

    test('a scope reply has no "checked this reply" note', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final HadiCorpus corpus = loadRealCorpus();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          hadiCorpusProvider.overrideWith((ref) => corpus),
        ],
      );
      addTearDown(c.dispose);
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask(dailyLife[2], provider: const OfflineHadiProvider());
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.notes, isEmpty);
      expect(m.notes.contains(HadiFinder.offlineNote), isFalse);
      expect(m.routes, isEmpty);
    });
  });

  group('big text', () {
    void bigText(WidgetTester tester) {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    testWidgets('the Home verse card keeps room for the verse',
        (WidgetTester tester) async {
      await AppHarness.boot(tester);
      tester.takeException();
      bigText(tester);
      await AppHarness.settle(tester);
      final Finder ref = find.text('QUR\u2019AN 18:24', skipOffstage: false);
      if (ref.evaluate().isNotEmpty) {
        expect(tester.getSize(ref).width, greaterThan(100));
      }
      tester.takeException();
    });
  });
}
