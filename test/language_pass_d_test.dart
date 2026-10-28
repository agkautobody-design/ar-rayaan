// Pass D (languages): the Arabic, Urdu and Bangla phrase tables, the Text
// wrapper, right-to-left punctuation and times, the support language setting,
// the translated crisis cards and the on-screen "Native-speaker review
// needed" labels. No golden files.
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ar_rayaan/app/core/i18n/app_locale.dart';
import 'package:ar_rayaan/app/core/i18n/bidi.dart';
import 'package:ar_rayaan/app/core/i18n/ui_phrases.dart';
import 'package:ar_rayaan/app/core/i18n/ui_phrases_data.dart';
import 'package:ar_rayaan/app/theme/widgets/tr_text.dart';
import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:ar_rayaan/features/sakina/domain/crisis_l10n.dart';
import 'package:ar_rayaan/features/sakina/domain/sakina_content.dart';
import 'package:ar_rayaan/features/share/application/share_text.dart';
import 'package:ar_rayaan/features/support/application/support_settings.dart';

Widget _app(Locale locale, Widget child) => MaterialApp(
      locale: locale,
      supportedLocales: const <Locale>[
        Locale('en'),
        Locale('ar'),
        Locale('ur'),
        Locale('bn'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (BuildContext c, Widget? w) => Directionality(
        textDirection: LocaleController.layoutDirection(locale),
        child: w!,
      ),
      home: Scaffold(body: child),
    );

void main() {
  group('phrase tables', () {
    test('no missing keys: every row has three non-empty columns', () {
      expect(kUiPhrases, isNotEmpty);
      kUiPhrases.forEach((String en, List<String> cols) {
        expect(cols.length, kPhraseLanguages.length, reason: en);
        for (int i = 0; i < cols.length; i++) {
          expect(cols[i].trim(), isNotEmpty, reason: '$en ${kPhraseLanguages[i]}');
        }
      });
    });

    test('slots are the same in every language', () {
      kUiPhrases.forEach((String en, List<String> cols) {
        final int slots = '{}'.allMatches(en).length;
        for (int i = 0; i < cols.length; i++) {
          for (int n = 1; n <= slots; n++) {
            expect(cols[i].contains('{$n}'), isTrue,
                reason: '$en ${kPhraseLanguages[i]} lacks {$n}');
          }
          expect(RegExp(r'\{(\d+)\}').allMatches(cols[i]).every(
                  (RegExpMatch m) => int.parse(m.group(1)!) <= slots),
              isTrue,
              reason: '$en ${kPhraseLanguages[i]} has an extra slot');
        }
      });
    });

    test('every group has a title and rows', () {
      expect(kUiPhraseGroups.keys.toSet(), kUiPhraseGroupTables.keys.toSet());
      for (final String g in kUiPhraseGroups.keys) {
        expect(kUiPhraseGroupTables[g], isNotEmpty, reason: g);
      }
    });

    test('exact, pattern and fallback translation', () {
      expect(translatePhrase('Prayer Times', 'ur'), isNot('Prayer Times'));
      expect(translatePhrase('Prayer Times', 'en'), 'Prayer Times');
      expect(translatePhrase('A sentence nobody wrote down', 'ar'),
          'A sentence nobody wrote down');
      expect(translatePhrase('Surah 12', 'ar'), contains('12'));
      // Turkish and Indonesian are honestly not translated.
      expect(translatePhrase('Prayer Times', 'tr'), 'Prayer Times');
      expect(translatePhrase('Prayer Times', 'id'), 'Prayer Times');
    });

    test('Native-speaker review needed has all three languages', () {
      for (final String l in kPhraseLanguages) {
        expect(translatePhrase('Native-speaker review needed', l),
            isNot('Native-speaker review needed'));
      }
    });
  });

  group('right-to-left text', () {
    test('Latin-first text is detected, Arabic is not', () {
      expect(startsWithLatin('Free to use'), isTrue);
      expect(startsWithLatin('12 Free to use'), isTrue);
      expect(startsWithLatin('مجاني'), isFalse);
      expect(startsWithRtlScript('مجاني'), isTrue);
      expect(startsWithLatin('বাংলা'), isFalse);
    });

    test('a clock time keeps its order inside a right-to-left sentence', () {
      expect(looksLikeClockTime('4:39 AM'), isTrue);
      expect(looksLikeClockTime('16:05'), isTrue);
      expect(looksLikeClockTime('Fajr'), isFalse);
      expect(isolateLtr('4:39 AM'), '$kLri'
          '4:39 AM$kPdi');
    });

    testWidgets('Latin text on an Arabic screen is laid out left-to-right',
        (WidgetTester t) async {
      await t.pumpWidget(_app(
        const Locale('ar'),
        const Column(children: <Widget>[
          Text('Is this right?', key: Key('latin')),
          Text('Prayer Times', key: Key('known')),
        ]),
      ));
      final RichText latin = t.widget(find.descendant(
          of: find.byKey(const Key('latin')), matching: find.byType(RichText)));
      expect(latin.textDirection, TextDirection.ltr);
      expect(find.text('Prayer Times'), findsNothing);
      expect(find.text(translatePhrase('Prayer Times', 'ar')), findsOneWidget);
    });

    testWidgets('English screen stays as written', (WidgetTester t) async {
      await t.pumpWidget(_app(const Locale('en'), const Text('Prayer Times')));
      expect(find.text('Prayer Times'), findsOneWidget);
    });

    testWidgets('layout is right-to-left for ar and ur, not bn or en',
        (WidgetTester t) async {
      for (final (String code, TextDirection d) in <(String, TextDirection)>[
        ('ar', TextDirection.rtl),
        ('ur', TextDirection.rtl),
        ('bn', TextDirection.ltr),
        ('en', TextDirection.ltr),
      ]) {
        late TextDirection got;
        await t.pumpWidget(_app(
          Locale(code),
          Builder(builder: (BuildContext c) {
            got = Directionality.of(c);
            return const SizedBox();
          }),
        ));
        expect(got, d, reason: code);
      }
    });
  });

  group('Native-speaker review needed label', () {
    testWidgets('shown in ar, ur and bn, hidden in English',
        (WidgetTester t) async {
      for (final String code in <String>['ar', 'ur', 'bn']) {
        await t.pumpWidget(_app(Locale(code), const NativeReviewNote()));
        expect(find.byKey(const Key('native-review-note')), findsOneWidget,
            reason: code);
        expect(find.textContaining(translatePhrase('Native-speaker review needed', code)),
            findsWidgets);
      }
      await t.pumpWidget(_app(const Locale('en'), const NativeReviewNote()));
      expect(find.byKey(const Key('native-review-note')), findsNothing);
      await t.pumpWidget(_app(const Locale('tr'), const NativeReviewNote()));
      expect(find.byKey(const Key('native-review-note')), findsNothing);
    });

    testWidgets('safety variant adds the emergency line',
        (WidgetTester t) async {
      await t.pumpWidget(
          _app(const Locale('ar'), const NativeReviewNote(safety: true)));
      expect(
          find.textContaining(translatePhrase(
              'Some lines on this screen are still in English until a native speaker has checked them. If you are in danger, call your local emergency number.',
              'ar')),
          findsOneWidget);
    });
  });

  group('browser and device language', () {
    test('ar-SA, ur and bn preselect their language; others stay English', () {
      expect(LocaleController.deviceChoice(<Locale>[const Locale('ar', 'SA')]),
          const Locale('ar'));
      expect(LocaleController.deviceChoice(<Locale>[const Locale('ur', 'PK')]),
          const Locale('ur'));
      expect(LocaleController.deviceChoice(<Locale>[const Locale('bn', 'BD')]),
          const Locale('bn'));
      expect(LocaleController.deviceChoice(<Locale>[const Locale('tr')]),
          const Locale('en'));
      expect(
          LocaleController.deviceChoice(
              <Locale>[const Locale('fr'), const Locale('ar')]),
          const Locale('ar'));
      expect(LocaleController.deviceChoice(const <Locale>[]),
          const Locale('en'));
    });
  });

  group('Language for support lines', () {
    test('auto follows the app language; a choice wins', () {
      expect(resolveSupportLanguage(kSupportLanguageAuto, 'ar'), 'ar');
      expect(resolveSupportLanguage(kSupportLanguageAuto, 'bn'), 'bn');
      expect(resolveSupportLanguage(kSupportLanguageAuto, 'tr'), 'en');
      expect(resolveSupportLanguage(kSupportLanguageAuto, 'en'), 'en');
      expect(resolveSupportLanguage('ur', 'en'), 'ur');
      expect(resolveSupportLanguage('en', 'ar'), 'en');
    });
  });

  group('crisis cards in Arabic, Urdu and Bangla', () {
    const String marker = 'LINES-GO-HERE';

    test('every kind has a card in every language, with the review line', () {
      for (final CrisisKind k in CrisisKind.values) {
        for (final String l in kCrisisLanguages) {
          final String? t = crisisCardIn(k, l, marker);
          expect(t, isNotNull, reason: '$k $l');
          expect(t!, contains(marker), reason: '$k $l');
          expect(t, isNot(contains('{lines}')));
          expect(t, isNot(contains('{quran}')));
          expect(t, endsWith(crisisReviewLine(l)), reason: '$k $l');
          expect(crisisReviewLine(l),
              translatePhrase('Native-speaker review needed', l));
          expect(crisisReviewLine(l), isNot(contains('Native-speaker')));
        }
      }
    });

    test('no number is invented: the only digits are the verse pointer', () {
      for (final CrisisKind k in CrisisKind.values) {
        for (final String l in kCrisisLanguages) {
          final String t = crisisCardIn(k, l, marker)!;
          final String digits = t.replaceAll(RegExp(r'[^0-9]'), '');
          expect(digits == '' || digits == '53', isTrue,
              reason: '$k $l has digits "$digits"');
        }
      }
    });

    test('the verse is never translated: a pointer only', () {
      for (final String l in kCrisisLanguages) {
        final String t = crisisCardIn(CrisisKind.selfHarm, l, marker)!;
        expect(t.contains('53'), isTrue, reason: l);
        expect(t.contains('“'), isFalse);
      }
    });

    test('textFor and followUpFor use them, English is unchanged', () {
      final String en = CrisisResponses.textFor(CrisisKind.abuse, countryCode: 'US');
      expect(en, isNot(contains('Native-speaker review needed')));
      for (final String l in kCrisisLanguages) {
        final String t = CrisisResponses.textFor(CrisisKind.abuse,
            countryCode: 'US', lang: l);
        expect(t, contains(crisisReviewLine(l)));
        expect(CrisisResponses.followUpFor(CrisisKind.abuse, lang: l),
            contains(crisisReviewLine(l)));
      }
    });

    test('a language with no wording shows English with a note', () {
      expect(crisisEnglishNote('en'), '');
      expect(crisisEnglishNote('tr'), '');
      expect(crisisEnglishNote('ar'), contains('\n\n'));
      expect(withEnglishFallbackNote('Hello there', 'ar'),
          startsWith(crisisEnglishNote('ar')));
      expect(withEnglishFallbackNote('Hello there', 'en'), 'Hello there');
      expect(withEnglishFallbackNote('مرحبا', 'ar'),
          'مرحبا');
      expect(withEnglishFallbackNote('Hello there', 'bn'),
          startsWith(crisisEnglishNote('bn')));
    });
  });

  group('country messaging never contradicts itself', () {
    test('a known country never gets "could not tell which country"', () {
      final Set<String> codes = <String>{
        for (final HelpResource r in HelpResources.shown)
          if (r.countries.length == 1) r.countries.first,
      };
      expect(codes, isNotEmpty);
      for (final String cc in codes) {
        for (final CrisisKind k in CrisisKind.values) {
          final String en = CrisisResponses.regionNote(cc, kind: k);
          expect(en, isNot(contains('could not tell which country')),
              reason: '$cc $k');
          for (final String l in kCrisisLanguages) {
            final String note = CrisisResponses.regionNote(cc, kind: k, lang: l);
            expect(note, isNot(contains('could not tell')), reason: '$cc $k $l');
            expect(note, isNot(equals(crisisRegionNoteIn(l,
                region: null, picked: false, hasLocalForKind: false))));
          }
        }
      }
    });

    test('no country: says so, in each language', () {
      expect(CrisisResponses.regionNote(null), contains('could not tell'));
      for (final String l in kCrisisLanguages) {
        expect(CrisisResponses.regionNote(null, lang: l), isNotEmpty);
      }
    });

    test('a country with no line of this kind says so', () {
      final String t = crisisRegionNoteIn('ar',
          region: 'Testland', picked: false, hasLocalForKind: false)!;
      expect(t, contains('Testland'));
    });
  });

  group('share footer', () {
    test('English footer is unchanged, others are written in the language', () {
      expect(shareFooter(),
          '$kSharedFromLine\n$kShareDownloadLine\n$kInviteUrl');
      for (final String l in kPhraseLanguages) {
        final String f = shareFooter(lang: l);
        expect(f, contains(kInviteUrl));
        expect(f, contains(translatePhrase(kShareDownloadLine, l)));
        expect(f, isNot(contains(kShareDownloadLine)));
      }
    });
  });
}
