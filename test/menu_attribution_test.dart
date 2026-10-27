import 'package:ar_rayaan/app/router.dart';
import 'package:ar_rayaan/features/academy/application/academy_providers.dart';
import 'package:ar_rayaan/features/menu/presentation/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

/// Menu and Explore follow the grouped spec, route real modules, say
/// "Coming soon" for what is not built, and honour the Academy kill switch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('visibleMenuEntries (kill-switch logic)', () {
    const List<MenuEntry> items = <MenuEntry>[
      (Icons.menu_book_outlined, 'Quran', '/quran'),
      (Icons.school_outlined, 'Courses', '/academy'),
      (Icons.school_outlined, 'Gate', '/academy/gate'),
      (Icons.handshake_outlined, 'Marriage', '/academy/family-life'),
      (Icons.search, 'Soon', null),
      (Icons.article_outlined, 'Hadith', '/hadith'),
    ];

    test('switch on keeps every row, in order', () {
      final List<String> labels = visibleMenuEntries(items, showAcademy: true)
          .map((MenuEntry e) => e.$2)
          .toList();
      expect(labels, <String>[
        'Quran',
        'Courses',
        'Gate',
        'Marriage',
        'Soon',
        'Hadith',
      ]);
    });

    test('switch off drops exactly the Academy rows', () {
      final List<String> labels = visibleMenuEntries(items, showAcademy: false)
          .map((MenuEntry e) => e.$2)
          .toList();
      expect(labels, <String>['Quran', 'Soon', 'Hadith']);
    });

    test('isAcademyRoute', () {
      expect(isAcademyRoute('/academy'), isTrue);
      expect(isAcademyRoute('/academy/gate'), isTrue);
      expect(isAcademyRoute('/quran'), isFalse);
      expect(isAcademyRoute(null), isFalse);
    });
  });

  testWidgets('menu follows the grouped spec and routes modules', (
    tester,
  ) async {
    await AppHarness.boot(tester);
    await AppHarness.go(tester, find.text('Faith'), '/menu');

    // Locked groups.
    expect(find.text('FAITH & WORSHIP'), findsOneWidget);
    expect(find.text('FAMILY & COMMUNITY'), findsOneWidget);
    expect(find.text('TOOLS & RESOURCES'), findsOneWidget);

    // One row opens the Family Life school (Marriage is its first unit); the
    // Family Wing row says it is for parents; no dead rows pretend.
    expect(find.text('Marriage & Family Life'), findsOneWidget);
    expect(find.text('Marriage'), findsNothing);
    expect(find.text('Family Life'), findsNothing);
    expect(find.text('Parenting'), findsNothing);
    expect(find.text('Family Wing · for parents'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    // Nothing unbuilt is listed: no Help & Support, no "Coming soon" row.
    expect(find.text('Help & Support'), findsNothing);
    expect(find.text('Coming soon'), findsNothing);
    // The row opens the Journey screen and is named for it.
    expect(find.text('My Profile'), findsNothing);
    expect(find.text('My Journey'), findsOneWidget);
    expect(find.text('Your Journey, Your Progress'), findsOneWidget);
    // A guest has nothing to log out of: the row offers sign-in instead.
    expect(find.text('Log Out'), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
    // The footer claims only what is true.
    expect(find.textContaining('AUTHENTIC'), findsNothing);
    expect(find.text('SOURCES SHOWN · SCHOLAR REVIEW NEEDED'),
        findsOneWidget);

    // A shipped module row routes.
    await tester.tap(find.text('Notes & Bookmarks'));
    await AppHarness.settle(tester);
    expect(
      AppHarness.location(tester, find.byType(Scaffold).first),
      AppRoutes.notes,
    );
  });

  testWidgets('Marriage & Family Life opens the Family Life school', (
    tester,
  ) async {
    await AppHarness.boot(tester);
    await AppHarness.go(tester, find.text('Faith'), '/menu');
    await tester.tap(find.text('Marriage & Family Life'));
    await AppHarness.settle(tester);
    expect(
      AppHarness.location(tester, find.byType(Scaffold).first),
      '/academy/family-life',
    );
  });

  testWidgets('Academy kill switch hides the Menu Academy rows', (
    tester,
  ) async {
    await AppHarness.boot(
      tester,
      overrides: [academyFlagProvider.overrideWith((ref) async => false)],
    );
    await AppHarness.go(tester, find.text('Faith'), '/menu');

    expect(find.text('Islamic Courses'), findsNothing);
    expect(find.text('Marriage & Family Life'), findsNothing);
    expect(find.text('Family Wing · for parents'), findsNothing);
    // Non-Academy rows of the same sections remain.
    expect(find.text('Qur’an'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);
    expect(find.text('Elder Care'), findsOneWidget);
  });

  testWidgets('Explore: Academy row honours the kill switch', (tester) async {
    await AppHarness.boot(tester);
    await tester.tap(find.text('Faith'));
    await AppHarness.settle(tester);
    expect(find.text('The Academy'), findsOneWidget);
    // Light Theme and Help & Support are not built, so they are not listed.
    expect(find.text('Coming soon'), findsNothing);
    expect(find.text('Light Theme'), findsNothing);
    expect(find.text('Help & Support'), findsNothing);
    // The old fake rows are gone.
    expect(find.text('Saved Searches'), findsNothing);
    expect(find.text('Night Mode'), findsNothing);
  });

  testWidgets('Explore: Qibla, How to Pray and the 99 Names are near the top', (
    tester,
  ) async {
    await AppHarness.boot(tester);
    await tester.tap(find.text('Faith'));
    await AppHarness.settle(tester);
    final Finder prayer = find.text('Prayer Times');
    final Finder qibla = find.text('Qibla \u00b7 which way to pray');
    final Finder howTo = find.text('How to Pray \u00b7 step by step');
    final Finder names = find.text('The 99 Names of Allah');
    for (final Finder f in <Finder>[prayer, qibla, howTo, names]) {
      expect(f, findsOneWidget);
    }
    // Prayer Times, Qibla and How to Pray lead the Faith & Worship list.
    final double qiblaY = tester.getTopLeft(qibla).dy;
    expect(tester.getTopLeft(prayer).dy, lessThan(qiblaY));
    expect(qiblaY, lessThan(tester.getTopLeft(howTo).dy));
    expect(
      tester.getTopLeft(howTo).dy,
      lessThan(tester.getTopLeft(find.text('Qur’an')).dy),
    );
    await tester.tap(howTo);
    await AppHarness.settle(tester);
    expect(
      AppHarness.location(tester, find.byType(Scaffold).first),
      AppRoutes.hudaGuide,
    );
  });

  testWidgets('Explore: kill switch removes The Academy', (tester) async {
    await AppHarness.boot(
      tester,
      overrides: [academyFlagProvider.overrideWith((ref) async => false)],
    );
    await tester.tap(find.text('Faith'));
    await AppHarness.settle(tester);
    expect(find.text('The Academy'), findsNothing);
    expect(find.text('Marriage & Family Life'), findsNothing);
    expect(find.text('Qur’an'), findsOneWidget);
  });
}
