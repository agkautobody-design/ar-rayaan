import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/adhkar/application/adhkar_providers.dart';
import 'package:ar_rayaan/features/adhkar/data/bundled_adhkar_repository.dart';
import 'package:ar_rayaan/features/adhkar/domain/adhkar_models.dart';
import 'package:ar_rayaan/features/hadith/data/bundled_hadith_repository.dart';
import 'package:ar_rayaan/features/hadith/domain/hadith_models.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/adhkar/presentation/adhkar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

    test('no invisible bidi control characters hide in the Arabic', () async {
      final List<Hadith> hadiths = await BundledHadithRepository().collection();
      for (final Hadith h in hadiths) {
        expect(h.arabic, isNot(contains('\u202b')), reason: 'hadith ${h.number}');
        expect(h.arabic, isNot(contains('\u202c')), reason: 'hadith ${h.number}');
      }
    });
  });

  group('adhkar repository', () {
    test('serves morning/evening/after-prayer sets with counts', () async {
      final BundledAdhkarRepository repo = BundledAdhkarRepository();
      final List<AdhkarSet> sets = await repo.sets();
      expect(sets.length, 3);
      final AdhkarSet morning = sets.first;
      expect(morning.id, 'morning');
      // 23 items: #23 (the evening-only "perfect words" dhikr) lives only in
      // the evening set. Numbers are stable ids, so #23 is a gap here.
      expect(morning.items.length, 23);
      expect(morning.items.any((d) => d.number == 23), isFalse);
      expect(
        morning.totalRepetitions,
        morning.items.fold<int>(0, (int s, Dhikr d) => s + d.count),
      );
      expect(morning.totalRepetitions, 351);
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

    test('every dhikr names its source, and no markup artifacts remain',
        () async {
      final List<AdhkarSet> sets = await BundledAdhkarRepository().sets();
      for (final AdhkarSet s in sets) {
        for (final Dhikr d in s.items) {
          final String why = '${s.id} #${d.number}';
          expect(d.source, isNotNull, reason: why);
          expect(d.source!.trim().length, greaterThan(8), reason: why);
          expect(
            d.source!,
            matches(RegExp(
                r"Qur.an|Bukhari|Muslim|Tirmidhi|Abi Dawud|Abu Dawud|Ibn Majah|Nasa|Ahmad|Hakim|Tabarani")),
            reason: why,
          );
          expect(d.arabic, isNot(contains('((')), reason: why);
          expect(d.arabic, isNot(contains('))')), reason: why);
          expect(d.arabic, isNot(contains('*')), reason: why);
        }
      }
    });

    test('weak or disputed reports are labelled, not sold as guaranteed',
        () async {
      final List<AdhkarSet> sets = await BundledAdhkarRepository().sets();
      final AdhkarSet morning = sets.firstWhere((s) => s.id == 'morning');
      String src(int n) =>
          morning.items.firstWhere((d) => d.number == n).source!;
      String en(int n) =>
          morning.items.firstWhere((d) => d.number == n).translation!;
      expect(src(6), contains('daʿif'));
      expect(src(9), contains('mawduʿ'));
      expect(en(9), isNot(contains('Allah suffices you in the concerns')));
      expect(src(24), contains('weak'));
      expect(en(24), isNot(contains('he attains the Prophet')));
      // Verified sahih anchors.
      expect(src(3), contains('Muslim 2723'));
      expect(src(5), contains('Bukhari 6306'));
      expect(src(20), contains('Muslim 2726'));
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
      // Morning-only items (said "when you wake") are not in the evening set.
      for (final int n in <int>[19, 20, 21]) {
        expect(evening.items.any((d) => d.number == n), isFalse,
            reason: 'evening #$n is a morning-only dhikr');
      }
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

  testWidgets('adhkar counters work and show their source', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final BundledAdhkarRepository adhkarRepo = BundledAdhkarRepository();
    final List<AdhkarSet> sets =
        (await tester.runAsync(() => adhkarRepo.sets()))!;
    final int total = sets.first.totalRepetitions;

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          adhkarRepositoryProvider.overrideWithValue(adhkarRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const AdhkarScreen(initialSet: 'morning'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Object? error = tester.takeException();
    expect(error, isNull, reason: '$error');
    expect(find.text('Morning Adhkar'), findsWidgets);
    expect(
      find.text('0 of $total repetitions \u00b7 $total remaining'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('dhikr-morning-1-source')), findsOneWidget);

    // Item 2 prescribes 3 repetitions: two taps leave 1 of its 3 to do.
    await tester.ensureVisible(find.byKey(const Key('dhikr-morning-2-remaining')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('dhikr-morning-2-remaining')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('dhikr-morning-2-remaining')));
    await tester.pump();
    await tester.fling(find.byType(Scrollable).first, const Offset(0, 3000), 3000);
    await tester.pumpAndSettle();
    expect(
      find.text('2 of $total repetitions \u00b7 ${total - 2} remaining'),
      findsOneWidget,
    );
  });
}
