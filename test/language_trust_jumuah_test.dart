import 'package:ar_rayaan/app/core/i18n/app_locale.dart';
import 'package:ar_rayaan/app/core/i18n/ui_labels.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/legal/presentation/legal_screens.dart';
import 'package:ar_rayaan/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ar_rayaan/features/prayer/application/jumuah_countdown.dart';
import 'package:ar_rayaan/features/prayer/presentation/prayer_times_screen.dart';
import 'package:ar_rayaan/features/sources/presentation/sources_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home, {ProviderContainer? container}) {
  final Widget app = MaterialApp(theme: AppTheme.dark(), home: home);
  return container == null
      ? ProviderScope(child: app)
      : UncontrolledProviderScope(container: container, child: app);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('string table', () {
    test('looks a key up per language and falls back to English', () {
      expect(uiLabel('nav.home', 'en'), 'Home');
      expect(uiLabel('nav.home', 'ar'), 'الرئيسية');
      expect(uiLabel('nav.home', 'bn'), 'হোম');
      expect(uiLabel('nav.home', 'ur'), 'ہوم');
      // A language without a translation gets English, never a blank.
      expect(uiLabel('nav.home', 'fr'), 'Home');
      // An unknown key comes back as itself.
      expect(uiLabel('no.such.key', 'ar'), 'no.such.key');
    });

    test('every key has English plus Arabic, Bangla and Urdu', () {
      for (final MapEntry<String, Map<String, String>> e in kUiLabels.entries) {
        for (final String lang in <String>['en', ...kUiLabelLanguages]) {
          final String? text = e.value[lang];
          expect(text, isNotNull, reason: '${e.key} $lang');
          expect(text!.trim(), isNotEmpty, reason: '${e.key} $lang');
        }
        // No other language is claimed.
        expect(e.value.keys.toSet(), <String>{
          'en',
          ...kUiLabelLanguages,
        }, reason: e.key);
      }
    });

    test('translates a label written in English, leaves other text alone', () {
      expect(uiLabelForEnglish('Prayer Times', 'ur'), 'نماز کے اوقات');
      expect(uiLabelForEnglish('Prayer Times', 'en'), 'Prayer Times');
      expect(
        uiLabelForEnglish('A sentence nobody translated', 'ar'),
        'A sentence nobody translated',
      );
    });

    test('L10n exposes it by locale', () {
      expect(L10n(const Locale('ar')).ui('ui.next'), 'التالي');
      expect(L10n(const Locale('en')).english('Faith'), 'Faith');
      expect(L10n(const Locale('bn')).english('Faith'), 'ঈমান');
    });
  });

  group('direction and honesty', () {
    test('Arabic and Urdu are right-to-left, Bangla and English are not', () {
      expect(
        LocaleController.layoutDirection(const Locale('ar')),
        TextDirection.rtl,
      );
      expect(
        LocaleController.layoutDirection(const Locale('ur')),
        TextDirection.rtl,
      );
      expect(
        LocaleController.layoutDirection(const Locale('bn')),
        TextDirection.ltr,
      );
      expect(
        LocaleController.layoutDirection(const Locale('en')),
        TextDirection.ltr,
      );
    });

    test('the first-run choices are the four promised, in order', () {
      expect(
        LocaleController.firstRunChoices.map((Locale l) => l.languageCode),
        <String>['en', 'ar', 'bn', 'ur'],
      );
      for (final Locale l in LocaleController.firstRunChoices) {
        expect(LocaleController.supported.containsKey(l), isTrue);
      }
    });

    test('the scope line never claims more than exists', () {
      expect(
        LocaleController.translationScope(const Locale('fr')),
        contains('Not translated'),
      );
      expect(
        LocaleController.translationScope(const Locale('id')),
        contains('Language & Voice'),
      );
      expect(
        LocaleController.translationScope(const Locale('ar')),
        contains('Everything else is English'),
      );
    });
  });

  group('Jumu\'ah countdown', () {
    test('the next Friday at the saved time', () {
      // Thursday 22 Oct 2026.
      final DateTime thu = DateTime(2026, 10, 22, 10);
      expect(nextJumuah(thu, '13:30'), DateTime(2026, 10, 23, 13, 30));
      // Friday before the time: today.
      final DateTime friMorning = DateTime(2026, 10, 23, 12);
      expect(nextJumuah(friMorning, '13:30'), DateTime(2026, 10, 23, 13, 30));
      // Friday after the time: a week on.
      final DateTime friLate = DateTime(2026, 10, 23, 14);
      expect(nextJumuah(friLate, '13:30'), DateTime(2026, 10, 30, 13, 30));
      // Saturday: the coming Friday.
      expect(
        nextJumuah(DateTime(2026, 10, 24, 9), '13:30'),
        DateTime(2026, 10, 30, 13, 30),
      );
    });

    test('no time or a bad time gives null', () {
      expect(nextJumuah(DateTime(2026, 10, 22), null), isNull);
      expect(nextJumuah(DateTime(2026, 10, 22), ''), isNull);
      expect(nextJumuah(DateTime(2026, 10, 22), '25:00'), isNull);
      expect(nextJumuah(DateTime(2026, 10, 22), 'soon'), isNull);
    });

    test('says how far away it is in plain words', () {
      final DateTime fri = DateTime(2026, 10, 23, 12);
      expect(
        jumuahCountdown(fri, DateTime(2026, 10, 23, 13, 30)),
        'Today, in 1h 30m',
      );
      expect(
        jumuahCountdown(fri, DateTime(2026, 10, 23, 12, 20)),
        'Today, in 20 min',
      );
      expect(
        jumuahCountdown(
          DateTime(2026, 10, 22, 10),
          DateTime(2026, 10, 23, 13, 30),
        ),
        'Tomorrow',
      );
      expect(
        jumuahCountdown(
          DateTime(2026, 10, 24, 9),
          DateTime(2026, 10, 30, 13, 30),
        ),
        'In 6 days',
      );
    });
  });

  group('Jumu\'ah row', () {
    testWidgets('with no time it offers to set one', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: JumuahRow(
              time: null,
              isFriday: false,
              now: DateTime(2026, 10, 22, 10),
            ),
          ),
        ),
      );
      expect(find.text('Set time'), findsOneWidget);
      expect(find.byKey(const Key('jumuah-countdown')), findsNothing);
    });

    testWidgets('with a time it shows the countdown to the next Friday', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: JumuahRow(
              time: '13:30',
              isFriday: false,
              now: DateTime(2026, 10, 22, 10),
            ),
          ),
        ),
      );
      expect(find.text('13:30'), findsOneWidget);
      expect(find.textContaining('Tomorrow'), findsOneWidget);
    });
  });

  group('first-run language chooser', () {
    testWidgets('sets the language, on a 320 px screen, without overflow', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _app(const OnboardingScreen(), container: container),
      );
      await tester.pump(const Duration(milliseconds: 300));

      for (final String name in <String>[
        'English',
        'العربية',
        'বাংলা',
        'اردو',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text('Next'), findsOneWidget);

      await tester.ensureVisible(find.text('العربية'));
      await tester.tap(find.text('العربية'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(container.read(localeProvider).languageCode, 'ar');
      expect(find.text('التالي'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('English'));
      await tester.tap(find.text('English'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(container.read(localeProvider).languageCode, 'en');
      expect(find.text('Next'), findsOneWidget);
    });
  });

  group('trust and legal', () {
    testWidgets('Our Sources opens with the plain trust card', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(430, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(const SourcesScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('trust-card')), findsOneWidget);
      expect(find.textContaining('CAN’T DO'), findsOneWidget);
      expect(find.text('Who writes the answers'), findsOneWidget);
      expect(find.text('What is free'), findsOneWidget);
      expect(find.text('What stays on your device'), findsOneWidget);
      expect(
        find.textContaining('No named scholar has reviewed this app'),
        findsOneWidget,
      );
    });

    test(
      'the draft notice says what is pending and no address is invented',
      () {
        expect(kLegalDraftNotice, contains('lawyer'));
        expect(kLegalDraftNotice, contains('contact address'));
        final String all = <String>[
          for (final LegalSection s in kTermsSections) '${s.heading} ${s.body}',
          for (final LegalSection s in kPrivacySections)
            '${s.heading} ${s.body}',
        ].join(' ');
        expect(all, contains(kLegalContactPending));
        expect(
          all.contains('@'),
          isFalse,
          reason: 'no invented e-mail address',
        );
        expect(all.contains('['), isFalse, reason: 'no bracket placeholders');
      },
    );
  });
}
