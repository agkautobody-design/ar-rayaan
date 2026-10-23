import 'package:ar_rayaan/features/academy/application/academy_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

/// Home tiles show live/honest subtitles, and the Academy kill switch
/// (ar.flag.academy) removes the Academy tile.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home tiles show live data, not stale placeholders', (
    tester,
  ) async {
    await AppHarness.boot(tester);

    // Stale placeholders are gone.
    expect(find.text('Riyad as-Salihin · Chapter 1'), findsNothing);
    expect(find.text('Dhuhr 12:47 PM'), findsNothing);
    expect(find.text('Morning Adhkar · 28 remaining'), findsNothing);
    expect(find.text('Continue Reading · Surah Al-Kahf'), findsNothing);

    // Live / honest content in their place.
    expect(find.text('The Forty Hadith · An-Nawawi'), findsOneWidget);
    expect(find.text('Begin Reading · Al-Fatihah'), findsOneWidget);
    expect(find.textContaining('Morning Adhkar'), findsWidgets);
    // Knowledge opens the stories library, and says so.
    expect(find.text('Stories, khutbahs & duas'), findsOneWidget);
    expect(find.text('Articles, Lessons & Courses'), findsNothing);
  });

  testWidgets('all ten Home tiles are present with the Academy on', (
    tester,
  ) async {
    await AppHarness.boot(tester);
    for (final String title in <String>[
      'Prayer Times',
      'Qur’an',
      'Dhikr & Du’a',
      'Hadith',
      'Today’s NOOR',
      'Islamic Calendar',
      'Knowledge',
      'Wasia Academy',
      'My Journey',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });

  testWidgets('Home shows today\u2019s Hijri date and the Also shortcuts', (
    tester,
  ) async {
    await AppHarness.boot(tester);
    final Finder hijri = find.byKey(const Key('home-hijri-date'));
    expect(hijri, findsOneWidget);
    expect(tester.widget<Text>(hijri).data, endsWith(' AH'));
    expect(find.text('Mosques & halal food'), findsOneWidget);
    expect(find.text('Qibla'), findsOneWidget);
    expect(find.text('99 Names of Allah'), findsOneWidget);
    // The shortcuts sit below the tiles, never above them.
    expect(
      tester.getTopLeft(find.text('Qibla')).dy,
      greaterThan(tester.getTopLeft(find.text('My Journey')).dy),
    );
  });

  testWidgets('Academy kill switch removes the Academy tile from Home', (
    tester,
  ) async {
    await AppHarness.boot(
      tester,
      overrides: [academyFlagProvider.overrideWith((ref) async => false)],
    );
    expect(find.text('Wasia Academy'), findsNothing);
    // Everything else stays.
    expect(find.text('Prayer Times'), findsOneWidget);
    expect(find.text('My Journey'), findsOneWidget);
  });
}
