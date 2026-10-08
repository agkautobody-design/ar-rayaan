import 'package:ar_rayaan/app/app.dart';
import 'package:ar_rayaan/app/core/env_config.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/adhkar/application/adhkar_providers.dart';
import 'package:ar_rayaan/features/adhkar/data/bundled_adhkar_repository.dart';
import 'package:ar_rayaan/features/adhkar/domain/adhkar_models.dart';
import 'package:ar_rayaan/features/hadith/application/hadith_providers.dart';
import 'package:ar_rayaan/features/hadith/data/bundled_hadith_repository.dart';
import 'package:ar_rayaan/features/hadith/domain/hadith_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('hadith repository', () {
    test('serves the Forty Hadith with Arabic + English', () async {
      final BundledHadithRepository repo = BundledHadithRepository();
      final List<Hadith> hadiths = await repo.collection();
      expect(hadiths.length, 42);
      expect(hadiths.first.number, 1);
      expect(hadiths.first.arabic, contains('النِّيَّاتِ'));
      expect(hadiths.first.english.toLowerCase(), contains('umar'));
      expect(
        hadiths.every((h) => h.arabic.isNotEmpty && h.english.isNotEmpty),
        isTrue,
      );
    });
  });

  group('adhkar repository', () {
    test('serves morning/evening/after-prayer sets with counts', () async {
      final BundledAdhkarRepository repo = BundledAdhkarRepository();
      final List<AdhkarSet> sets = await repo.sets();
      expect(sets.length, 3);
      final AdhkarSet morning = sets.first;
      expect(morning.id, 'morning');
      expect(morning.items.length, 24);
      expect(morning.totalRepetitions, 354);
      expect(morning.items[1].count, 3);
      expect(morning.items.every((d) => d.arabic.isNotEmpty), isTrue);
    });

    test('every dhikr carries an English meaning (O-12)', () async {
      final BundledAdhkarRepository repo = BundledAdhkarRepository();
      final List<AdhkarSet> sets = await repo.sets();
      for (final AdhkarSet s in sets) {
        for (final Dhikr d in s.items) {
          expect(d.translation, isNotNull, reason: '${s.id} #${d.number}');
          expect(d.translation!.length, greaterThan(20),
              reason: '${s.id} #${d.number}');
        }
      }
    });

    test('evening set uses authentic evening wording', () async {
      final BundledAdhkarRepository repo = BundledAdhkarRepository();
      final List<AdhkarSet> sets = await repo.sets();
      final AdhkarSet evening =
          sets.firstWhere((s) => s.id == 'evening');
      String ar(int n) => evening.items.firstWhere((d) => d.number == n).arabic;
      expect(ar(3), contains('أَمْسَيْنَا'));
      expect(ar(4), contains('الْمَصِيرُ'));
      expect(ar(6), contains('أَمْسَيْتُ'));
      expect(ar(7), contains('أَمْسَى'));
      expect(ar(15), contains('اللَّيْلَةِ'));
      expect(ar(16), contains('أَمْسَيْنَا'));
      // Morning set must not leak evening notes.
      final AdhkarSet morning = sets.firstWhere((s) => s.id == 'morning');
      for (final Dhikr d in morning.items) {
        expect(d.arabic, isNot(contains('وإذا أمسى')),
            reason: 'morning #${d.number}');
      }
    });
  });

  group('adhkar progress', () {
    test('increment caps at prescribed count; reset clears', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final AdhkarProgressController ctrl = container.read(
        adhkarProgressProvider.notifier,
      );

      await ctrl.increment('morning', 2, 3);
      await ctrl.increment('morning', 2, 3);
      expect(ctrl.doneFor('morning', 2), 2);
      await ctrl.increment('morning', 2, 3);
      await ctrl.increment('morning', 2, 3); // beyond max — ignored
      expect(ctrl.doneFor('morning', 2), 3);

      final AdhkarSet morning = (await BundledAdhkarRepository().sets()).first;
      expect(ctrl.completedInSet(morning), 3);

      await ctrl.resetSet('morning');
      expect(ctrl.doneFor('morning', 2), 0);
    });

    test('progress persists for the same day', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c1 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      await c1.read(adhkarProgressProvider.notifier).increment('evening', 1, 1);
      c1.dispose();

      final ProviderContainer c2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c2.dispose);
      expect(c2.read(adhkarProgressProvider.notifier).doneFor('evening', 1), 1);
    });
  });

  testWidgets('hadith screen and adhkar counters work end-to-end', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final BundledHadithRepository hadithRepo = BundledHadithRepository();
    final BundledAdhkarRepository adhkarRepo = BundledAdhkarRepository();
    await tester.runAsync(() async {
      await hadithRepo.collection();
      await adhkarRepo.sets();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hadithRepositoryProvider.overrideWithValue(hadithRepo),
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

    // Hadith tile → collection
    await tester.tap(find.text('Hadith'));
    await tester.pumpAndSettle();
    expect(
      find.text('The Forty Hadith of Imam an-Nawawi · 42 hadiths'),
      findsOneWidget,
    );
    expect(find.text('HADITH 1'), findsOneWidget);

    // Back home, then Dhikr & Du'a tile → counters
    final BuildContext ctx = tester.element(find.text('HADITH 1'));
    // ignore: use_build_context_synchronously
    GoRouter.of(ctx).go('/home');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dhikr & Du’a'));
    await tester.pumpAndSettle();

    expect(
      find.text('Morning Adhkar'),
      findsWidgets,
    ); // picker chip + progress card
    expect(find.text('0 of 354 repetitions · 354 remaining'), findsOneWidget);

    // Item 2 prescribes 3 repetitions: tap its counter twice → 1 remains
    await tester.tap(find.byKey(const Key('dhikr-morning-2-remaining')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('dhikr-morning-2-remaining')));
    await tester.pump();
    expect(find.text('2 of 354 repetitions · 352 remaining'), findsOneWidget);
  });
}
