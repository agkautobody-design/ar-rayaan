import 'package:ar_rayaan/app/app.dart';
import 'package:ar_rayaan/app/core/env_config.dart';
import 'package:ar_rayaan/features/quran/application/quran_providers.dart';
import 'package:ar_rayaan/features/quran/data/bundled_quran_repository.dart';
import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/quran/presentation/surah_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled repository', () {
    final BundledQuranRepository repo = BundledQuranRepository();

    test('index lists all 114 surahs in order with metadata', () async {
      final List<SurahMeta> index = await repo.index();
      expect(index.length, 114);
      expect(index.first.number, 1);
      expect(index.first.transliteration, 'Al-Fatihah');
      expect(index.first.ayahCount, 7);
      expect(index.first.isMeccan, isTrue);
      expect(index.last.number, 114);
      expect(index[17].transliteration, 'Al-Kahf'); // the Home tile's surah
      expect(index[17].ayahCount, 110);
    });

    test('surah returns full Arabic + English text', () async {
      final Surah fatiha = await repo.surah(1);
      expect(fatiha.ayahs.length, 7);
      expect(fatiha.ayahs.first.arabic, contains('بِسۡمِ'));
      expect(fatiha.ayahs.first.english, contains('In the name of Allah'));

      final Surah ikhlas = await repo.surah(112);
      expect(ikhlas.ayahs.length, 4);
      expect(ikhlas.ayahs.every((a) => a.arabic.isNotEmpty), isTrue);
      expect(ikhlas.ayahs.every((a) => a.english.isNotEmpty), isTrue);
    });

    test('invalid surah number throws', () async {
      expect(() => repo.surah(0), throwsA(isA<ArgumentError>()));
      expect(() => repo.surah(115), throwsA(isA<ArgumentError>()));
    });
  });

  group('helpers', () {
    test('Arabic-Indic numeral conversion', () {
      expect(SurahReaderScreen.toArabicIndic(1), '١');
      expect(SurahReaderScreen.toArabicIndic(18), '١٨');
      expect(SurahReaderScreen.toArabicIndic(286), '٢٨٦');
    });
  });

  testWidgets('index → reader flow saves Continue Reading position', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Pre-warm the bundled Qur'an cache so screens get data in the first
    // frame (avoids spinner/perpetual-animation hangs under fake time).
    final BundledQuranRepository repo = BundledQuranRepository();
    // rootBundle I/O needs the real event loop — FakeAsync never delivers it.
    await tester.runAsync(() => repo.index());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [quranRepositoryProvider.overrideWithValue(repo)],
        child: ArRayaanApp(env: EnvConfig.fromDefines()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4)); // splash
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcome-continue')));
    await tester.pumpAndSettle();

    // Home tile → Qur'an index
    await tester.tap(find.text('Qur’an'));
    await tester.pumpAndSettle();

    expect(find.text('Al-Fatihah'), findsWidgets);
    expect(find.text('Al-Baqarah'), findsOneWidget);
    expect(find.text('Al-Kahf'), findsOneWidget);

    // Open Surah Al-Fatihah
    await tester.tap(find.text('Al-Fatihah').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('In the name of Allah'), findsOneWidget);

    // Tap ayah 4 (unique text) → saves position
    await tester.tap(find.textContaining('Sovereign of the Day'));
    await tester.pump();

    // Back to index → banner shows the saved position
    final BuildContext ctx = tester.element(
      find.textContaining('Sovereign of the Day'),
    );
    // ignore: use_build_context_synchronously
    GoRouter.of(ctx).go('/quran');
    await tester.pumpAndSettle();

    expect(find.text('CONTINUE READING'), findsOneWidget);
    expect(find.text('Surah Al-Fatihah · Ayah 4'), findsOneWidget);
  });
}
