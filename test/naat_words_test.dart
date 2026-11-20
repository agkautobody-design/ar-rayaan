import 'package:ar_rayaan/features/academy/domain/naat_words.dart';
import 'package:ar_rayaan/features/academy/presentation/naat_words_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final RegExp _latin = RegExp(r'[A-Za-z]');
final RegExp _arabicScript = RegExp(r'[؀-ۿ]');
final RegExp _bangla = RegExp(r'[ঀ-৿]');

void main() {
  group('the library', () {
    test('has works, with unique ids', () {
      expect(kNaatWorks.length, greaterThanOrEqualTo(3));
      expect(
        kNaatWorks.map((NaatWork w) => w.id).toSet().length,
        kNaatWorks.length,
      );
    });

    for (final NaatWork w in kNaatWorks) {
      test('${w.id}: every line has the original, how to say it, and meaning',
          () {
        expect(w.lines, isNotEmpty);
        expect(w.source.trim(), isNotEmpty);
        expect(w.about.trim(), isNotEmpty);
        for (final NaatLine l in w.lines) {
          // The original is in Arabic script only (no Latin letters).
          expect(_arabicScript.hasMatch(l.original), isTrue, reason: l.original);
          expect(_latin.hasMatch(l.original), isFalse, reason: l.original);
          // The sounds are Latin letters, with the same number of halves.
          expect(_latin.hasMatch(l.sounds), isTrue);
          expect(l.sounds.split('\n').length, l.original.split('\n').length,
              reason: l.original);
          // Every language except the original's own is present and not empty.
          for (final String lang in kNaatLanguages.keys) {
            if (lang == w.originalLang) {
              expect(l.meaning.containsKey(lang), isFalse);
              continue;
            }
            final String? t = l.meaning[lang];
            expect(t, isNotNull, reason: '${w.id} $lang: ${l.original}');
            expect(t!.trim(), isNotEmpty);
          }
          // Scripts match their language (guards against a swapped column).
          expect(_bangla.hasMatch(l.meaning['bn']!), isTrue);
          if (l.meaning['ur'] != null) {
            expect(_arabicScript.hasMatch(l.meaning['ur']!), isTrue);
          }
          if (l.meaning['ar'] != null) {
            expect(_arabicScript.hasMatch(l.meaning['ar']!), isTrue);
          }
          expect(_latin.hasMatch(l.meaning['en'] ?? 'x'), isTrue);
        }
      });
    }

    test('only public-domain or traditional works are held', () {
      // Poets died long ago or the work is anonymous and traditional.
      const Set<String> allowed = <String>{
        'tala-al-badru',
        'burda-opening',
        'lab-pe-aati-hai-dua',
      };
      for (final NaatWork w in kNaatWorks) {
        expect(allowed.contains(w.id), isTrue,
            reason: '${w.id}: add a licence note before adding new works');
      }
    });
  });

  group('the screens', () {
    Future<void> boot(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(430, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: home)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('the list names every work', (WidgetTester tester) async {
      await boot(tester, const NaatWordsScreen());
      for (final NaatWork w in kNaatWorks) {
        expect(find.text(w.title), findsOneWidget);
      }
      expect(find.text('Scholar review needed'), findsOneWidget);
    });

    testWidgets('an Urdu poem opens in English and switches to Arabic', (
      WidgetTester tester,
    ) async {
      await boot(tester, const NaatReaderScreen(id: 'lab-pe-aati-hai-dua'));
      expect(find.byKey(const Key('naat-lang-ur')), findsNothing);
      expect(
        find.textContaining('may my life be like a candle'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('naat-lang-ar')));
      await tester.pump();
      expect(find.textContaining('ليكن عمري كالشمعة'), findsOneWidget);
      await tester.tap(find.byKey(const Key('naat-lang-bn')));
      await tester.pump();
      expect(find.textContaining('মোমবাতির'), findsOneWidget);
    });

    testWidgets('an Arabic poem can be learned in Urdu, and the sounds hide', (
      WidgetTester tester,
    ) async {
      await boot(tester, const NaatReaderScreen(id: 'tala-al-badru'));
      expect(find.byKey(const Key('naat-lang-ar')), findsNothing);
      expect(find.textContaining('ṭalaʿa l-badru'), findsOneWidget);
      await tester.tap(find.byKey(const Key('naat-lang-ur')));
      await tester.pump();
      expect(find.textContaining('چودھویں کا چاند'), findsOneWidget);
      await tester.tap(find.byKey(const Key('naat-sounds')));
      await tester.pump();
      expect(find.textContaining('ṭalaʿa l-badru'), findsNothing);
    });

    testWidgets('an unknown id says so instead of crashing', (
      WidgetTester tester,
    ) async {
      await boot(tester, const NaatReaderScreen(id: 'nope'));
      expect(find.text('That poem is not in the library.'), findsOneWidget);
    });
  });
}
