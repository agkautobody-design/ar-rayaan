import 'package:ar_rayaan/app/core/content_loader.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/app/theme/widgets/screen_header.dart';
import 'package:ar_rayaan/features/quran/application/quran_offline.dart';
import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/quran/domain/surah_search.dart';
import 'package:ar_rayaan/features/quran/presentation/quran_offline_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Round-3 Qur'an reader fixes: spelling folding in the surah search, the
/// "save for offline" flow and its wording, and whole-word header titles.
SurahMeta meta(int n, String tl, String ar, String en) => SurahMeta(
  number: n,
  arabicName: ar,
  transliteration: tl,
  englishMeaning: en,
  revelationType: 'meccan',
  ayahCount: 7,
);

class _FakeSave extends QuranOfflineController {
  _FakeSave(this.initial);

  final QuranSaveState initial;
  int saves = 0;

  @override
  QuranSaveState build() => initial;

  @override
  Future<void> save() async {
    saves++;
  }
}

void main() {
  final List<SurahMeta> all = <SurahMeta>[
    meta(2, 'Al-Baqarah', 'البقرة', 'The Cow'),
    meta(3, "Ali 'Imran", 'آل عمران', 'Family of Imran'),
    meta(12, 'Yusuf', 'يوسف', 'Joseph'),
    meta(24, 'An-Nur', 'النور', 'The Light'),
    meta(36, 'Ya-Sin', 'يس', 'Ya Sin'),
    meta(112, 'Al-Ikhlas', 'الإخلاص', 'Sincerity'),
  ];

  group('surah search spellings', () {
    test('Yaseen, Yasin, Ya-Sin and Ya Seen all find Ya-Sin', () {
      for (final String q in <String>[
        'Yaseen',
        'yasin',
        'Ya-Sin',
        'ya seen',
        'Yassin',
      ]) {
        expect(filterSurahs(all, q).map((SurahMeta s) => s.number), <int>[
          36,
        ], reason: q);
      }
    });

    test('other doubled-vowel spellings meet the same name', () {
      expect(filterSurahs(all, 'Noor').single.number, 24);
      expect(filterSurahs(all, 'Yousuf').single.number, 12);
      expect(filterSurahs(all, 'Ikhlaas').single.number, 112);
      expect(filterSurahs(all, 'aal imran').single.number, 3);
    });

    test('folding never hides an exact match or invents one', () {
      expect(filterSurahs(all, 'cow').single.number, 2);
      expect(filterSurahs(all, 'zzzz'), isEmpty);
      expect(filterSurahs(all, '36').single.number, 36);
      expect(foldSpelling('yaseen'), 'yasin');
    });
  });

  group('saveForOffline', () {
    test('stores every file, reports progress, then verifies', () async {
      final Set<String> stored = <String>{};
      final List<String> progress = <String>[];
      final QuranSaveResult r = await saveForOffline(
        <String>['a', 'b', 'c'],
        load: (String k) async {
          stored.add(k);
          return k;
        },
        isStored: (String k) async => stored.contains(k),
        onProgress: (int d, int t) => progress.add('$d/$t'),
      );
      expect(r, QuranSaveResult.saved);
      expect(progress, <String>['0/3', '1/3', '2/3', '3/3']);
    });

    test('a failed fetch is reported as failed, not saved', () async {
      final QuranSaveResult r = await saveForOffline(
        <String>['a', 'b'],
        load: (String k) async {
          if (k == 'b') throw StateError('offline');
          return k;
        },
        isStored: (String k) async => true,
      );
      expect(r, QuranSaveResult.failed);
    });

    test(
      'files that load but are not kept are NOT reported as saved',
      () async {
        final QuranSaveResult r = await saveForOffline(
          <String>['a'],
          load: (String k) async => k,
          isStored: (String k) async => false,
        );
        expect(r, QuranSaveResult.notKept);
      },
    );

    test('covers the Qur’an text, transliteration and credits', () {
      expect(kQuranOfflineAssets, contains('assets/quran/quran.json'));
      expect(kQuranOfflineAssets.length, 5);
    });
  });

  group('offline wording is honest', () {
    test('audio is never promised; phone says it is already inside', () {
      for (final QuranSavePhase p in <QuranSavePhase>[
        QuranSavePhase.idle,
        QuranSavePhase.saved,
      ]) {
        expect(
          quranOfflineMessage(p, web: true, alreadyStored: true),
          contains('audio still needs internet'),
        );
      }
      final String phone = quranOfflineMessage(
        QuranSavePhase.idle,
        web: false,
        alreadyStored: true,
      );
      expect(phone, contains('inside this app'));
      expect(phone, contains('audio still needs internet'));
      expect(
        quranOfflineMessage(
          QuranSavePhase.notKept,
          web: true,
          alreadyStored: false,
        ),
        contains('would not keep a copy'),
      );
    });
  });

  group('QuranOfflineCard', () {
    Future<_FakeSave> pump(
      WidgetTester tester, {
      required QuranSaveState state,
      required bool stored,
      required bool web,
      bool compact = false,
    }) async {
      final _FakeSave fake = _FakeSave(state);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            quranOfflineSaveProvider.overrideWith(() => fake),
            quranOfflineReadyProvider.overrideWith((ref) async => stored),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: QuranOfflineCard(compact: compact, web: web),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return fake;
    }

    testWidgets('web, not saved: shows the button and starts a save', (
      tester,
    ) async {
      final _FakeSave fake = await pump(
        tester,
        state: const QuranSaveState(QuranSavePhase.idle),
        stored: false,
        web: true,
      );
      expect(find.text('Save Qur’an for offline'), findsOneWidget);
      await tester.tap(find.text('Save Qur’an for offline'));
      expect(fake.saves, 1);
    });

    testWidgets('saving shows progress, no button', (tester) async {
      await pump(
        tester,
        state: const QuranSaveState(QuranSavePhase.saving, done: 1, total: 3),
        stored: false,
        web: true,
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('1 of 3 files'), findsOneWidget);
      expect(find.text('Save Qur’an for offline'), findsNothing);
    });

    testWidgets('failed offers Try again', (tester) async {
      await pump(
        tester,
        state: const QuranSaveState(QuranSavePhase.failed),
        stored: false,
        web: true,
      );
      expect(find.textContaining('Could not save'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('saved: says so, no button; compact hint disappears', (
      tester,
    ) async {
      await pump(
        tester,
        state: const QuranSaveState(QuranSavePhase.idle),
        stored: true,
        web: true,
      );
      expect(find.textContaining('Saved on this device'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('compact hint is empty on the phone app and when saved', (
      tester,
    ) async {
      await pump(
        tester,
        state: const QuranSaveState(QuranSavePhase.idle),
        stored: true,
        web: false,
        compact: true,
      );
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.textContaining('Read the Qur'), findsNothing);
    });

    testWidgets('phone settings card explains the text is inside the app', (
      tester,
    ) async {
      await pump(
        tester,
        state: const QuranSaveState(QuranSavePhase.idle),
        stored: true,
        web: false,
      );
      expect(find.textContaining('inside this app'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });

  testWidgets('header title keeps whole words at huge text', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 3.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: ScreenHeader(title: 'Settings')),
      ),
    );
    await tester.pump();
    // One line: a word cut in two ("Settin / gs") would make it two.
    final double h = tester.getSize(find.text('Settings')).height;
    expect(h, lessThan(18 * kHeaderTitleMaxScale * 1.8));
    expect(tester.takeException(), isNull);
  });
}
