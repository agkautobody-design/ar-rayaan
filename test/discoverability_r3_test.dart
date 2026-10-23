import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/router.dart';
import 'package:ar_rayaan/features/academy/presentation/my_additions_screen.dart';
import 'package:ar_rayaan/features/calendar/presentation/calendar_screen.dart';
import 'package:ar_rayaan/features/games/presentation/games_screens.dart';
import 'package:ar_rayaan/features/huda/presentation/huda_screens.dart';
import 'package:ar_rayaan/features/stories/presentation/story_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';

/// Round 3 findability and copy fixes: guide headings, Explore entries, the
/// 99 Names list, the calendar's next event, link validation, elided Arabic.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('guide headings', () {
    test('the Nikah and New Baby guides are not filed under The Last Day', () {
      expect(guideCategoryLabel('huda-nikah', 'The Last Day'),
          'Family & Life Events');
      expect(guideCategoryLabel('huda-baby', 'The Last Day'),
          'Family & Life Events');
    });

    test('every other guide keeps its own category', () {
      expect(guideCategoryLabel('huda-janazah-wash', 'The Last Day'),
          'The Last Day');
      expect(guideCategoryLabel('huda-prayer', 'Worship'), 'Worship');
    });
  });

  group('Explore', () {
    testWidgets('lists the Nikah guide and the New Muslim path', (tester) async {
      await AppHarness.boot(tester);
      await tester.tap(find.text('Faith'));
      await AppHarness.settle(tester);
      expect(find.text('Marriage · the Nikah guide'), findsOneWidget);
      expect(find.text('New to Islam · a 30-day path'), findsOneWidget);
      await tester.tap(find.text('New to Islam · a 30-day path'));
      await AppHarness.settle(tester);
      expect(
        AppHarness.location(tester, find.byType(Scaffold).first),
        AppRoutes.newMuslimPath,
      );
    });
  });

  group('99 Names', () {
    test('a verse reference reads as a Qur’an reference', () {
      expect(names99RefLabel('2:163'), 'Qur’an 2:163');
      expect(names99RefLabel('59:22-24'), 'Qur’an 59:22-24');
      expect(names99RefLabel('Allah'), 'Allah');
    });

    testWidgets('the list view shows every name and jumps to one', (
      tester,
    ) async {
      final List<Name99> deck = <Name99>[
        for (int i = 1; i <= 5; i++)
          Name99(n: i, name: 'Name $i', meaning: 'Meaning $i', ref: '2:$i'),
      ];
      await AppHarness.boot(
        tester,
        overrides: <Override>[
          namesProvider.overrideWith((ref) async => deck),
        ],
      );
      await AppHarness.go(tester, find.byType(Scaffold).first, AppRoutes.names99);
      expect(find.text('1 OF 5'), findsOneWidget);

      await tester.tap(find.byKey(const Key('names-mode-list')));
      await tester.pump();
      for (int i = 1; i <= 5; i++) {
        expect(find.byKey(Key('names-row-$i')), findsOneWidget);
      }
      expect(find.text('Meaning 4'), findsOneWidget);

      await tester.tap(find.byKey(const Key('names-row-4')));
      await tester.pump();
      expect(find.text('4 OF 5'), findsOneWidget);
      expect(find.byKey(const Key('names-row-4')), findsNothing);
    });
  });

  group('Islamic Calendar', () {
    testWidgets('puts the next event at the top', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(430, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester.pump();
      final Finder banner = find.byKey(const Key('calendar-next-event'));
      expect(banner, findsOneWidget);
      expect(find.textContaining('Next: '), findsOneWidget);
      // It sits above the date converter, the month grid and the long list.
      expect(
        tester.getTopLeft(banner).dy,
        lessThan(tester.getTopLeft(find.text('DATE CONVERTER')).dy),
      );
      expect(
        tester.getTopLeft(banner).dy,
        lessThan(tester.getTopLeft(find.text('UPCOMING OBSERVANCES')).dy),
      );
    });
  });

  group('My Additions link check', () {
    test('a pasted phrase is refused with a message', () {
      expect(personalLinkError('not a link'), isNotNull);
      expect(personalLinkError(''), isNotNull);
      expect(personalLinkError('ftp://example.com/a.mp3'), isNotNull);
      expect(personalLinkError('https://'), isNotNull);
    });

    test('a real http(s) link passes', () {
      expect(personalLinkError('https://example.com/track.mp3'), isNull);
      expect(personalLinkError('  http://example.com/a  '), isNull);
    });

    test('an empty title is refused', () {
      expect(personalTitleError('   '), isNotNull);
      expect(personalTitleError('Burdah'), isNull);
    });
  });

  group('elided Arabic in a story', () {
    test('detects a cut text', () {
      expect(arabicIsElided('اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...'),
          isTrue);
      expect(arabicIsElided('قُلْ هُوَ اللَّهُ أَحَدٌ ... قُلْ'), isTrue);
      expect(arabicIsElided('بِسْمِ اللَّهِ'), isFalse);
    });

    test('finds the Qur’an reference in the sources', () {
      expect(
        quranRefFromSources(<String>['Sahih al-Bukhari 2311; Qur\'an 2:255']),
        (2, 255),
      );
      expect(
        quranRefFromSources(<String>['Sahih al-Bukhari 5017; Qur\'an 112-114']),
        (112, null),
      );
      expect(quranRefFromSources(<String>['Sahih al-Bukhari 6306']), isNull);
      expect(quranRefFromSources(<String>['Qur\'an 999:1']), isNull);
    });
  });
}
