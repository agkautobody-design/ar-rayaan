import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/quran/application/quran_snippets.dart';
import 'package:ar_rayaan/features/reading/application/generated_translit.dart';
import 'package:ar_rayaan/features/quran/application/quran_translit.dart';
import 'package:ar_rayaan/features/reading/presentation/quran_snippet_views.dart';
import 'package:ar_rayaan/features/reading/application/reading_prefs.dart';
import 'package:ar_rayaan/features/reading/presentation/arabic_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _ar = 'قُلْ هُوَ اللَّهُ أَحَدٌ';
const String _tl = 'Qul huwallaahu ahad';
const String _en = 'Say: He is Allah, One.';

Future<ProviderContainer> _container([
  Map<String, Object> values = const <String, Object>{},
]) async {
  SharedPreferences.setMockInitialValues(values);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Map<String, Object> values = const <String, Object>{},
  double textScale = 1,
  TextDirection dir = TextDirection.ltr,
}) async {
  SharedPreferences.setMockInitialValues(values);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(360, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        builder: (BuildContext context, Widget? w) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: Directionality(textDirection: dir, child: w!),
        ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  generatedTranslitTests();
  generatedFillWidgetTest();
  group('ReadingPrefs', () {
    test('the defaults show everything', () {
      const ReadingPrefs p = ReadingPrefs();
      expect(p.mode, ReadingSupport.beginner);
      expect(p.showTranslit, isTrue);
      expect(p.showMeaning, isTrue);
      expect(p.translit(), LayerView.shown);
      expect(p.meaning, LayerView.shown);
    });

    test('reader mode puts the transliteration behind a button', () {
      const ReadingPrefs p = ReadingPrefs(mode: ReadingSupport.reader);
      expect(p.translit(), LayerView.button);
    });

    test('learning mode only steps back for mastered items', () {
      const ReadingPrefs p = ReadingPrefs(mode: ReadingSupport.learning);
      expect(p.translit(), LayerView.shown);
      expect(p.translit(mastered: true), LayerView.button);
    });

    test('the switches override the mode', () {
      const ReadingPrefs p = ReadingPrefs(
        showTranslit: false,
        showMeaning: false,
      );
      expect(p.translit(), LayerView.hidden);
      expect(p.translit(mastered: true), LayerView.hidden);
      expect(p.meaning, LayerView.hidden);
    });

    test('nothing stored means show everything (existing users)', () async {
      final ProviderContainer c = await _container();
      final ReadingPrefs p = c.read(readingPrefsProvider);
      expect(p.mode, ReadingSupport.beginner);
      expect(p.showTranslit, isTrue);
      expect(p.showMeaning, isTrue);
      expect(p.asked, isFalse);
    });

    test('the answers and switches are stored and read back', () async {
      final ProviderContainer c = await _container();
      final ReadingPrefsController ctl = c.read(readingPrefsProvider.notifier);
      await ctl.answer(ArabicAnswer.yes);
      await ctl.setShowMeaning(false);
      final ProviderContainer again = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
        ],
      );
      addTearDown(again.dispose);
      final ReadingPrefs p = again.read(readingPrefsProvider);
      expect(p.mode, ReadingSupport.reader);
      expect(p.asked, isTrue);
      expect(p.showMeaning, isFalse);
      expect(p.showTranslit, isTrue);
    });

    test('"No" and "A little" keep everything visible', () async {
      for (final ArabicAnswer a in <ArabicAnswer>[
        ArabicAnswer.no,
        ArabicAnswer.little,
      ]) {
        final ProviderContainer c = await _container();
        await c.read(readingPrefsProvider.notifier).answer(a);
        expect(c.read(readingPrefsProvider).mode, ReadingSupport.beginner);
        expect(c.read(readingPrefsProvider).asked, isTrue);
      }
    });
  });

  group('ArabicBlock', () {
    testWidgets('shows Arabic, then transliteration, then meaning',
        (WidgetTester tester) async {
      await _pump(
        tester,
        const ArabicBlock(arabic: _ar, translit: _tl, meaning: _en),
      );
      expect(find.text(_ar), findsOneWidget);
      expect(find.text(_tl), findsOneWidget);
      expect(find.text(_en), findsOneWidget);
      final double a = tester.getTopLeft(find.text(_ar)).dy;
      final double t = tester.getTopLeft(find.text(_tl)).dy;
      final double m = tester.getTopLeft(find.text(_en)).dy;
      expect(a, lessThan(t));
      expect(t, lessThan(m));
    });

    testWidgets('arabic is right to left, transliteration left to right',
        (WidgetTester tester) async {
      await _pump(
        tester,
        const ArabicBlock(arabic: _ar, translit: _tl, meaning: _en),
        dir: TextDirection.rtl,
      );
      final Element ar = tester.element(find.byKey(const Key('arabic-block-arabic')));
      final Element tl = tester.element(find.byKey(const Key('arabic-block-translit')));
      final Element en = tester.element(find.byKey(const Key('arabic-block-meaning')));
      expect(Directionality.of(ar), TextDirection.rtl);
      expect(Directionality.of(tl), TextDirection.ltr);
      expect(Directionality.of(en), TextDirection.ltr);
      final Text tlText = tester.widget<Text>(find.byKey(const Key('arabic-block-translit')));
      expect(tlText.locale, kLatinLocale);
      final Text arText = tester.widget<Text>(find.byKey(const Key('arabic-block-arabic')));
      expect(arText.locale, const Locale('ar'));
    });

    testWidgets('nothing is smaller than 12 even with a tiny Arabic size',
        (WidgetTester tester) async {
      await _pump(
        tester,
        const ArabicBlock(arabic: _ar, translit: _tl, meaning: _en, arabicSize: 10),
      );
      for (final String k in <String>[
        'arabic-block-translit',
        'arabic-block-meaning',
      ]) {
        final Text t = tester.widget<Text>(find.byKey(Key(k)));
        expect(t.style!.fontSize, greaterThanOrEqualTo(12), reason: k);
      }
    });

    testWidgets('a missing transliteration is said, not invented',
        (WidgetTester tester) async {
      await _pump(tester, const ArabicBlock(arabic: _ar, meaning: _en));
      expect(find.byKey(const Key('arabic-block-translit')), findsNothing);
      expect(find.byKey(const Key('arabic-block-missing')), findsOneWidget);
      expect(find.text(kTranslitMissing), findsOneWidget);
    });

    testWidgets('Show transliteration off hides it, meaning stays',
        (WidgetTester tester) async {
      await _pump(
        tester,
        const ArabicBlock(arabic: _ar, translit: _tl, meaning: _en),
        values: const <String, Object>{ReadingPrefsController.keyTranslit: false},
      );
      expect(find.text(_tl), findsNothing);
      expect(find.byKey(const Key('arabic-block-missing')), findsNothing);
      expect(find.text(_en), findsOneWidget);
    });

    testWidgets('Show meaning off hides the meaning, transliteration stays',
        (WidgetTester tester) async {
      await _pump(
        tester,
        const ArabicBlock(arabic: _ar, translit: _tl, meaning: _en),
        values: const <String, Object>{ReadingPrefsController.keyMeaning: false},
      );
      expect(find.text(_tl), findsOneWidget);
      expect(find.text(_en), findsNothing);
    });

    testWidgets('reader mode: one tap on Read it shows the transliteration',
        (WidgetTester tester) async {
      await _pump(
        tester,
        const ArabicBlock(arabic: _ar, translit: _tl, meaning: _en),
        values: const <String, Object>{ReadingPrefsController.keyMode: 'reader'},
      );
      expect(find.text(_tl), findsNothing);
      await tester.tap(find.byKey(const Key('arabic-block-read-it')));
      await tester.pump();
      expect(find.text(_tl), findsOneWidget);
      await tester.tap(find.byKey(const Key('arabic-block-hide-it')));
      await tester.pump();
      expect(find.text(_tl), findsNothing);
    });

    testWidgets('test mode covers all three together until tapped',
        (WidgetTester tester) async {
      await _pump(
        tester,
        const ArabicBlock(arabic: _ar, translit: _tl, meaning: _en, testMode: true),
      );
      expect(find.text(_ar), findsNothing);
      expect(find.text(_tl), findsNothing);
      expect(find.text(_en), findsNothing);
      await tester.tap(find.byKey(const Key('arabic-block-covered')));
      await tester.pump();
      expect(find.text(_ar), findsOneWidget);
      expect(find.text(_tl), findsOneWidget);
      expect(find.text(_en), findsOneWidget);
    });

    testWidgets('review note shows for a machine-made transliteration',
        (WidgetTester tester) async {
      await _pump(
        tester,
        const ArabicBlock(
          arabic: _ar,
          translit: _tl,
          meaning: _en,
          needsReview: true,
          translitSource: 'quran-json',
        ),
      );
      expect(find.textContaining('Scholar review needed'), findsOneWidget);
    });

    testWidgets('large text on a narrow phone does not overflow',
        (WidgetTester tester) async {
      await _pump(
        tester,
        const ArabicBlock(
          arabic: _ar,
          translit: 'Allaahu laa ilaaha illaa huw, al-hayyul-qayyoom, laa ta\'khudhuhoo sinatuw walaa nawm',
          meaning: 'Allah - there is no deity except Him, the Ever-Living, the Sustainer of [all] existence.',
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Qur\'an transliteration data', () {
    final Map<String, dynamic> file = jsonDecode(
      File('assets/quran/translit_en.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final List<dynamic> quran = jsonDecode(
      File('assets/quran/quran.json').readAsStringSync(),
    ) as List<dynamic>;

    test('has an entry for every ayah of quran.json and nothing else', () {
      final Set<String> keys = <String>{
        for (final dynamic s in quran)
          for (final dynamic v in (s as Map<String, dynamic>)['v'] as List<dynamic>)
            '${s['n']}:${(v as List<dynamic>)[0]}',
      };
      final Map<String, dynamic> map = file['map'] as Map<String, dynamic>;
      expect(keys.length, 6236);
      expect(map.keys.toSet(), keys);
    });

    test('is plain Latin letters only, one scheme, never empty', () {
      final RegExp ok = RegExp(r"^[A-Za-z' ,.\-]+$");
      final Map<String, dynamic> map = file['map'] as Map<String, dynamic>;
      final List<String> bad = <String>[
        for (final MapEntry<String, dynamic> e in map.entries)
          if (!ok.hasMatch(e.value as String)) e.key,
      ];
      expect(bad, isEmpty, reason: bad.take(5).join(', '));
    });

    test('says where it came from, its licence and that it is unreviewed', () {
      expect(file['source'], contains('quran-json'));
      expect(file['license'], contains('CC BY-SA 4.0'));
      expect(file['review'], contains('Scholar review needed'));
    });

    test('the parser reads the file and survives garbage', () {
      final Map<String, String> m = parseQuranTranslit(
        File('assets/quran/translit_en.json').readAsStringSync(),
      );
      expect(m.length, 6236);
      expect(m['39:9'], isNotNull);
      expect(parseQuranTranslit('not json'), isEmpty);
      expect(parseQuranTranslit('[1,2]'), isEmpty);
      expect(parseQuranTranslit('{"map": 3}'), isEmpty);
    });
  });

  group('Qur\'an snippets (Bismillah, 39:9 part)', () {
    final String raw = File('assets/quran/snippets.json').readAsStringSync();
    final List<dynamic> quran = jsonDecode(
      File('assets/quran/quran.json').readAsStringSync(),
    ) as List<dynamic>;
    final Map<String, String> tl = parseQuranTranslit(
      File('assets/quran/translit_en.json').readAsStringSync(),
    );

    test('the Bismillah is 1:1 exactly as the registry has it', () {
      final QuranSnippet b = QuranSnippet.parse(raw, 'bismillah')!;
      final List<dynamic> v =
          ((quran[0] as Map<String, dynamic>)['v'] as List<dynamic>)[0] as List<dynamic>;
      expect(b.arabic, v[1]);
      expect(b.english, v[2]);
      expect(b.translit, tl['1:1']);
    });

    test('the 39:9 part is cut from the ayah and its transliteration', () {
      final QuranSnippet k = QuranSnippet.parse(raw, 'knowledge')!;
      final List<dynamic> v =
          ((quran[38] as Map<String, dynamic>)['v'] as List<dynamic>)[8] as List<dynamic>;
      expect((v[1] as String).contains(k.arabic), isTrue);
      expect(tl['39:9']!.contains(k.translit), isTrue);
      expect(k.ref, '39:9');
    });

    test('a bad file gives nothing, not a crash', () {
      expect(QuranSnippet.parse('nope', 'bismillah'), isNull);
      expect(QuranSnippet.parse('{"bismillah": {"ref": "1:1"}}', 'bismillah'), isNull);
    });

    testWidgets('the knowledge verse shows Arabic, transliteration, meaning',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final QuranSnippet k = QuranSnippet.parse(raw, 'knowledge')!;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            quranSnippetsProvider.overrideWith(
              (ref) async => <String, QuranSnippet>{'knowledge': k},
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(body: SingleChildScrollView(child: KnowledgeVerseView())),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text(k.arabic), findsOneWidget);
      expect(find.text(k.translit), findsOneWidget);
      expect(find.text(k.english), findsOneWidget);
      expect(find.textContaining('39:9'), findsOneWidget);
    });
  });
}

void generatedTranslitTests() {
  group('generated transliteration', () {
    test('every entry is Latin, non-empty and keyed by tidy Arabic', () {
      final String raw = File('assets/translit/generated.json').readAsStringSync();
      final Map<String, String> m = parseGeneratedTranslit(raw);
      expect(m, isNotEmpty);
      m.forEach((String k, String v) {
        expect(normaliseArabicKey(k), k);
        expect(RegExp(r"^[A-Za-z\s',.\-]+$").hasMatch(v), isTrue, reason: v);
      });
      expect(json.decode(raw)['review'], contains('Scholar review needed'));
    });
  });
}

void generatedFillWidgetTest() {
  testWidgets('a block with no transliteration of its own uses the generated one', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          generatedTranslitProvider.overrideWith(
            (ref) async => <String, String>{'سُبْحَانَ اللَّهِ': 'Subhaana l-lah'},
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: ArabicBlock(arabic: 'سُبْحَانَ  اللَّهِ', meaning: 'Glory be to Allah'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Subhaana l-lah'), findsOneWidget);
    expect(find.byKey(const Key('arabic-block-review')), findsOneWidget);
    expect(find.byKey(const Key('arabic-block-missing')), findsNothing);
  });
}
