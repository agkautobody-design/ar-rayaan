import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/academy/presentation/hisn_al_muslim_screen.dart';
import 'package:ar_rayaan/features/huda/presentation/huda_screens.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

List<Guide> loadGuides() {
  final List<dynamic> raw = jsonDecode(
    File('assets/guides/guides.json').readAsStringSync(),
  ) as List<dynamic>;
  return raw.map((dynamic e) => Guide.fromJson(e as Map<String, dynamic>)).toList();
}

void main() {
  group('Hisn al-Muslim grouping', () {
    late List<Story> duas;
    setUpAll(() {
      final List<dynamic> raw = jsonDecode(
        File('assets/stories/dailyduas.json').readAsStringSync(),
      ) as List<dynamic>;
      duas = raw.map((dynamic e) => Story.fromJson(e as Map<String, dynamic>)).toList();
    });

    test('every dua is reachable: none falls into "more", none is lost', () {
      final Map<String, List<Story>> grouped = groupHisnDuas(duas);
      expect(grouped['more'], isEmpty, reason: 'all 42 are filed in a gate');
      final int shown =
          grouped.values.fold(0, (int n, List<Story> l) => n + l.length);
      final int duplicates =
          duas.where((Story s) => s.duplicateOf != null).length;
      expect(shown + duplicates, duas.length);
      expect(duplicates, 3);
      expect(grouped['morning-evening'], isNotEmpty);
      expect(grouped['home'], isNotEmpty);
    });

    test('a duplicate points at a real original and is not listed twice', () {
      final Set<String> ids = duas.map((Story s) => s.id).toSet();
      final Map<String, List<Story>> grouped = groupHisnDuas(duas);
      final Set<String> listed = <String>{
        for (final List<Story> l in grouped.values) ...l.map((Story s) => s.id),
      };
      for (final Story s in duas.where((Story s) => s.duplicateOf != null)) {
        expect(ids.contains(s.duplicateOf), isTrue, reason: s.id);
        expect(listed.contains(s.id), isFalse, reason: s.id);
        expect(listed.contains(s.duplicateOf), isTrue, reason: s.id);
      }
    });

    test('an unknown or missing gate lands under "More duas", not nowhere', () {
      Story make(String id, String? gate) => Story(
            id: id,
            collection: 'dailyduas',
            title: id,
            kicker: 'k',
            subtitle: 's',
            sourceLabel: 'Established',
            sources: const <String>[],
            chapters: const <StoryChapter>[],
            familyQuestion: '',
            hisnCategory: gate,
          );
      final Map<String, List<Story>> grouped =
          groupHisnDuas(<Story>[make('a', null), make('b', 'nope'), make('c', 'home')]);
      expect(grouped['more']!.map((Story s) => s.id), <String>['a', 'b']);
      expect(grouped['home']!.single.id, 'c');
    });
  });

  group('Huda guides', () {
    test('the prayer positions strip and GO DEEPER come from the data', () {
      final List<Guide> guides = loadGuides();
      final List<Guide> withPositions =
          guides.where((Guide g) => g.showPositions).toList();
      expect(withPositions.map((Guide g) => g.id), <String>['huda-prayer']);
      final Guide prayer = guides.firstWhere((Guide g) => g.id == 'huda-prayer');
      expect(prayer.goDeeper, isNotNull);
      expect(prayer.goDeeper!.keys, containsAll(<String>['why', 'evidence', 'commonMistakes']));
    });

    test('How to Pray recites Fatihah before bowing, with no Kursi-first step',
        () {
      final Guide prayer =
          loadGuides().firstWhere((Guide g) => g.id == 'huda-prayer');
      final String all = prayer.steps.join('\n');
      final int fatiha = all.indexOf('Fatihah');
      final int ruku = all.indexOf("Ruku'");
      expect(fatiha, greaterThanOrEqualTo(0));
      expect(ruku, greaterThan(fatiha));
      expect(all.contains('Ayat al-Kursi before'), isFalse);
    });

    testWidgets('the guide page loads from its id when there is no extra',
        (tester) async {
      final List<Guide> guides = loadGuides();
      tester.view.physicalSize = const Size(430, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            guidesProvider.overrideWith((ref) async => guides),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const GuideRouteScreen(guideId: 'huda-prayer'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final Object? error = tester.takeException();
      expect(error, isNull, reason: '$error');
      final Guide prayer = guides.firstWhere((Guide g) => g.id == 'huda-prayer');
      expect(find.text(prayer.title), findsWidgets);
      expect(find.text('GO DEEPER'), findsOneWidget);
    });

    testWidgets('an unknown id says so instead of crashing', (tester) async {
      final List<Guide> guides = loadGuides();
      tester.view.physicalSize = const Size(430, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            guidesProvider.overrideWith((ref) async => guides),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const GuideRouteScreen(guideId: 'no-such-guide'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('That guide could not be found.'), findsOneWidget);
    });
  });
}
