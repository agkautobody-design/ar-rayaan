import 'package:ar_rayaan/app/core/i18n/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

/// App-level smoke tests: the real app boots into Home INSIDE the bottom-nav
/// shell, the tabs work, unknown links are caught, and the language setting
/// reaches MaterialApp (locale + text direction).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots into Home with the bottom nav around it', (tester) async {
    await AppHarness.boot(tester);

    // Home content.
    expect(find.text('Prayer Times'), findsOneWidget);
    expect(find.text('Today for You'), findsOneWidget);
    // The five locked tabs - Home is in the shell, so they are all visible.
    for (final String tab in <String>['Home', 'Faith', 'Family', 'You']) {
      expect(find.text(tab), findsOneWidget, reason: 'nav tab $tab');
    }
    expect(AppHarness.location(tester, find.text('Faith')), '/home');
  });

  testWidgets('Faith tab opens Explore and Home tab comes back', (
    tester,
  ) async {
    await AppHarness.boot(tester);

    await tester.tap(find.text('Faith'));
    await AppHarness.settle(tester);
    expect(find.text('EXPLORE AR-RAYAAN'), findsOneWidget);
    expect(AppHarness.location(tester, find.text('Faith')), '/explore');

    await tester.tap(find.text('Home'));
    await AppHarness.settle(tester);
    expect(find.text('Prayer Times'), findsOneWidget);
    expect(AppHarness.location(tester, find.text('Faith')), '/home');
  });

  testWidgets('"/" forwards to the shell Home, an unknown link is caught', (
    tester,
  ) async {
    await AppHarness.boot(tester);

    await AppHarness.go(tester, find.text('Faith'), '/');
    expect(AppHarness.location(tester, find.text('Faith')), '/home');
    expect(find.text('Home'), findsOneWidget); // nav still present

    await AppHarness.go(tester, find.text('Faith'), '/definitely-not-a-page');
    expect(find.text('This page is not here.'), findsOneWidget);
  });

  testWidgets('a chosen right-to-left language flips the whole app', (
    tester,
  ) async {
    await AppHarness.boot(
      tester,
      prefsValues: <String, Object>{'ar.locale': 'ar'},
    );
    final BuildContext ctx = tester.element(find.text('Faith'));
    expect(Localizations.localeOf(ctx).languageCode, 'ar');
    expect(Directionality.of(ctx), TextDirection.rtl);
  });

  testWidgets('English stays left-to-right', (tester) async {
    await AppHarness.boot(tester);
    final BuildContext ctx = tester.element(find.text('Faith'));
    expect(Localizations.localeOf(ctx).languageCode, 'en');
    expect(Directionality.of(ctx), TextDirection.ltr);
  });

  test('language helpers: RTL and what is really translated', () {
    expect(LocaleController.isRtl(const Locale('ar')), isTrue);
    expect(LocaleController.isRtl(const Locale('ur')), isTrue);
    expect(LocaleController.isRtl(const Locale('en')), isFalse);
    // Only four languages have any translated UI text.
    expect(LocaleController.translatedChrome(const Locale('ur')), isTrue);
    expect(LocaleController.translatedChrome(const Locale('fr')), isFalse);
    expect(LocaleController.translatedChrome(const Locale('bn')), isFalse);
  });
}
