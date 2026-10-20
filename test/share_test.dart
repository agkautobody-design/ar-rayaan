import 'dart:convert';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/quran/data/bundled_quran_repository.dart';
import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/search/domain/quran_search.dart';
import 'package:ar_rayaan/features/share/presentation/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<ShareCard>> loadCards() async {
    final String raw = await rootBundle.loadString('assets/share/cards.json');
    final Map<String, dynamic> d = jsonDecode(raw) as Map<String, dynamic>;
    return (d['cards'] as List<dynamic>)
        .map((dynamic e) => ShareCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  group('verse cards', () {
    test('every Qur’an card quotes the ayah it cites', () async {
      final List<ShareCard> cards = await loadCards();
      final List<Surah> all = await BundledQuranRepository().all();
      final RegExp ref = RegExp(r'^Qur.an (\d+):(\d+)(?:-(\d+))?$');
      int checked = 0;
      for (final ShareCard c in cards.where((ShareCard c) => c.kind == "Qur'an")) {
        final RegExpMatch? m = ref.firstMatch(c.ref);
        expect(m, isNotNull, reason: '${c.id}: unreadable ref "${c.ref}"');
        final int s = int.parse(m!.group(1)!);
        final int a = int.parse(m.group(2)!);
        final int b = m.group(3) == null ? a : int.parse(m.group(3)!);
        expect(s >= 1 && s <= 114, isTrue, reason: c.id);
        final Surah surah = all[s - 1];
        expect(a >= 1 && b >= a && b <= surah.ayahs.length, isTrue,
            reason: '${c.id}: ${c.ref} is not a real ayah range');
        final String cited = surah.ayahs
            .sublist(a - 1, b)
            .map((Ayah x) => arabicSkeleton(x.arabic))
            .join(' ');
        expect(c.arabic, isNotEmpty, reason: c.id);
        final String quoted = arabicSkeleton(c.arabic);
        expect(cited.contains(quoted), isTrue,
            reason: '${c.id}: Arabic is not part of ${c.ref}');
        // The English is the bundled Saheeh International wording.
        final String en = foldEnglish(
            surah.ayahs.sublist(a - 1, b).map((Ayah x) => x.english).join(' '));
        final String shown = foldEnglish(c.text);
        final List<String> words = shown.split(' ');
        final int hit = words.where((String w) => en.contains(w)).length;
        expect(hit / words.length, greaterThan(0.9),
            reason: '${c.id}: English is not the cited ayah');
        checked++;
      }
      expect(checked, 6);
    });

    test('the Fajr card is 26:78, not another ayah', () async {
      final List<ShareCard> cards = await loadCards();
      final ShareCard fajr = cards.firstWhere((ShareCard c) => c.id == 's-fajr');
      expect(fajr.ref, "Qur'an 26:78");
      expect(foldArabic(fajr.arabic), foldArabic('الَّذِي خَلَقَنِي فَهُوَ يَهْدِينِ'));
    });

    test('hadith cards carry a collection and number', () async {
      final List<ShareCard> cards = await loadCards();
      for (final ShareCard c in cards.where((ShareCard c) => c.kind == 'Hadith')) {
        expect(c.ref, matches(RegExp(r'(Bukhari|Muslim|Tirmidhi|Dawud|Majah|Nasa).* \d+')),
            reason: c.id);
      }
    });
  });

  test('appUrlProvider honors the override', () {
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        appUrlProvider.overrideWithValue('https://ar-rayaan.app'),
      ],
    );
    addTearDown(c.dispose);
    expect(c.read(appUrlProvider), 'https://ar-rayaan.app');
  });

  testWidgets('share screen shows the beta QR, live link and a verse card',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // rootBundle I/O needs the real event loop - FakeAsync never delivers it.
    await tester.runAsync(
        () => rootBundle.loadString('assets/share/cards.json'));

    // Collect framework errors so a failure names the exception.
    final List<String> errors = <String>[];
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails d) =>
        errors.add('${d.exceptionAsString()}\n${d.stack}');
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appUrlProvider.overrideWithValue('https://beta.ar-rayaan.test'),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const ShareScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final Object? error = tester.takeException();
    expect(error, isNull, reason: '$error');
    expect(find.text('BETA \u00b7 INVITE A TESTER'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('https://beta.ar-rayaan.test'), findsOneWidget);
    expect(find.text('ADD TO ANY HOME SCREEN'), findsOneWidget);
    // First card is the Rahman verse, shown with its reference.
    expect(find.textContaining('55:13'), findsOneWidget);

    // Tear the screen down inside the test so dispose-time errors surface.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(errors, isEmpty, reason: errors.join('\n---\n'));
  });
}
