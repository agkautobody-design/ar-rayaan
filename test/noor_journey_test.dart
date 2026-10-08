import 'package:ar_rayaan/app/app.dart';
import 'package:ar_rayaan/app/core/env_config.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/adhkar/application/adhkar_providers.dart';
import 'package:ar_rayaan/features/adhkar/data/bundled_adhkar_repository.dart';
import 'package:ar_rayaan/features/journey/application/journey_providers.dart';
import 'package:ar_rayaan/features/noor/application/noor_providers.dart';
import 'package:ar_rayaan/features/noor/data/bundled_noor_repository.dart';
import 'package:ar_rayaan/features/noor/domain/noor_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('noor repository', () {
    test('serves 30 authentic entries with sources and prompts', () async {
      final BundledNoorRepository repo = BundledNoorRepository();
      final List<NoorEntry> all = await repo.entries();
      expect(all.length, 30);
      expect(all.where((e) => e.kind == NoorKind.quran).length, 24);
      expect(all.where((e) => e.kind == NoorKind.hadith).length, 6);
      expect(
        all.every(
          (e) =>
              e.arabic.isNotEmpty &&
              e.english.isNotEmpty &&
              e.prompt.isNotEmpty &&
              e.source.isNotEmpty,
        ),
        isTrue,
      );
      // Verbatim from the bundled Qur'an (Saheeh International).
      final NoorEntry verse = all.first;
      expect(verse.reference, '13:28');
      expect(verse.english, contains('remembrance of Allah'));
    });

    test('maps each calendar day to a stable rotating entry', () async {
      final BundledNoorRepository repo = BundledNoorRepository();
      final NoorEntry a = await repo.entryFor(DateTime(2026, 7, 19));
      final NoorEntry a2 = await repo.entryFor(DateTime(2026, 7, 19));
      final NoorEntry b = await repo.entryFor(DateTime(2026, 7, 20));
      expect(a.reference, a2.reference); // stable within the day
      expect(a.reference, isNot(b.reference)); // rotates daily
      // 30 days later the cycle repeats.
      final NoorEntry c = await repo.entryFor(DateTime(2026, 8, 18));
      expect(a.reference, c.reference);
    });
  });

  group('noor reflections controller', () {
    test(
      'adds, trims, ignores blanks and persists across containers',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final ProviderContainer c1 = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(c1.dispose);
        final NoorReflectionsController ctrl1 = c1.read(
          noorReflectionsProvider.notifier,
        );
        await ctrl1.add('  first light  ');
        await ctrl1.add('   ');
        expect(c1.read(noorReflectionsProvider), <String>['first light']);

        final ProviderContainer c2 = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(c2.dispose);
        expect(c2.read(noorReflectionsProvider), <String>['first light']);
      },
    );

    test('caps at 50 reflections, newest first', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      final NoorReflectionsController ctrl = c.read(
        noorReflectionsProvider.notifier,
      );
      for (int i = 1; i <= 55; i++) {
        await ctrl.add('reflection $i');
      }
      final List<String> state = c.read(noorReflectionsProvider);
      expect(state.length, 50);
      expect(state.first, 'reflection 55');
      expect(state.last, 'reflection 6');
    });
  });

  group('journey stats', () {
    test('starts at zero and grows with real signals', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final BundledAdhkarRepository adhkarRepo = BundledAdhkarRepository();
      await adhkarRepo.sets();
      final ProviderContainer c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          adhkarRepositoryProvider.overrideWithValue(adhkarRepo),
        ],
      );
      addTearDown(c.dispose);

      JourneyStats s = await c.read(journeyStatsProvider.future);
      expect(s.progress, 0);
      expect(s.adhkarDone, 0);
      expect(s.adhkarTotal, greaterThan(700));
      expect(s.readingStarted, isFalse);
      expect(s.reflections, 0);

      // A reflection contributes 15%.
      await c.read(noorReflectionsProvider.notifier).add('a light');
      s = await c.read(journeyStatsProvider.future);
      expect(s.progress, closeTo(0.15, 0.001));
    });
  });

  testWidgets('daily NOOR and journey ring are real end-to-end', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final BundledNoorRepository noorRepo = BundledNoorRepository();
    final BundledAdhkarRepository adhkarRepo = BundledAdhkarRepository();
    await tester.runAsync(() async {
      await noorRepo.entries();
      await adhkarRepo.sets();
    });
    final NoorEntry today = await noorRepo.entryFor(DateTime.now());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noorRepositoryProvider.overrideWithValue(noorRepo),
          adhkarRepositoryProvider.overrideWithValue(adhkarRepo),
        ],
        child: ArRayaanApp(env: EnvConfig.fromDefines()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcome-continue')));
    await tester.pumpAndSettle();

    // Today's NOOR shows the rotating entry with its real source.
    final BuildContext home = tester.element(find.text('Prayer Times'));
    // ignore: use_build_context_synchronously
    GoRouter.of(home).go('/noor');
    await tester.pumpAndSettle();
    expect(find.text('— ${today.source.toUpperCase()}'), findsOneWidget);
    expect(find.text(today.prompt), findsOneWidget);

    // Save a reflection.
    await tester.tap(find.text('Reflect Now'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Alhamdulillah for today',
    );
    await tester.tap(find.text('Save Reflection'));
    await tester.pumpAndSettle();
    expect(find.text('YOUR REFLECTIONS'), findsOneWidget);
    expect(find.text('Alhamdulillah for today'), findsOneWidget);

    // Journey ring reflects the reflection (15%).
    final BuildContext noorCtx = tester.element(find.text('YOUR REFLECTIONS'));
    // ignore: use_build_context_synchronously
    GoRouter.of(noorCtx).go('/journey');
    await tester.pumpAndSettle();
    expect(find.textContaining('REFLECTIONS 1'), findsOneWidget);
    expect(find.text('15%'), findsOneWidget);
  });
}
