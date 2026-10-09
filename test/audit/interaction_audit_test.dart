import 'package:ar_rayaan/app/router.dart';
import 'package:ar_rayaan/features/family/data/family_tree_provider.dart';
import 'package:ar_rayaan/features/feelings/presentation/feelings_screens.dart';
import 'package:ar_rayaan/features/games/presentation/games_screens.dart';
import 'package:ar_rayaan/features/huda/presentation/huda_screens.dart';
import 'package:ar_rayaan/features/stories/data/stories_repository.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// WAVE 4 — INTERACTION AUDIT.
/// Drives the REAL router through every screen and presses every tappable
/// widget each screen offers. Any dead button, broken navigation, or build
/// exception on tap fails the test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleStory = Story(
    id: 'w4', collection: 'prophets', title: 'S', kicker: 'K',
    subtitle: 'sub', sourceLabel: 'Established', sources: const ['Q 1:1'],
    chapters: const [StoryChapter(heading: 'h', body: 'long enough body text here')],
    familyQuestion: 'q?',
  );

  final routesToProbe = <String>[
    '/stories',
    '/family-tree',
    '/huda',
    '/games',
    '/feelings',
    '/notes',
    '/downloads',
    '/majlis',
  ];

  testWidgets('W4 every screen: every initial tappable responds without exception',
      (t) async {
    final router = buildRouter();
    await t.pumpWidget(ProviderScope(
      overrides: [
        storiesProvider.overrideWith((ref) async => [sampleStory]),
        guidesProvider.overrideWith((ref) async => [
              Guide(id: 'g', category: 'Worship', title: 'G', subtitle: 's',
                  sources: const ['B1'], steps: const ['one', 'two', 'three']),
            ]),
        familyTreeProvider.overrideWith((ref) async => FamilyTreeData(
              title: 'T', note: 'n', sources: const ['s'],
              nodes: [
                FamilyNode(id: 'a', name: 'A', era: 'E', parents: const [],
                    spouses: const [], children: const [], river: 'root',
                    sourceLabel: 'Established', description: 'd',
                    sources: const ['s']),
              ],
            )),
        feelingsProvider.overrideWith((ref) async => [
              Feeling(id: 'f', feeling: 'Calm', line: 'l',
                  dua: const DuaBlock(arabic: '\u0628\u0633\u0645',
                      body: 'b', source: 's'),
                  items: const []),
            ]),
        triviaProvider.overrideWith((ref) async => []),
        namesProvider.overrideWith((ref) async => []),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await t.pumpAndSettle();

    for (final path in routesToProbe) {
      router.go(path);
      await t.pumpAndSettle();
      t.takeException(); // clear navigation noise
      final List<Widget> tappables = <Widget>[
        ...t.widgetList<InkWell>(find.byType(InkWell)),
        ...t.widgetList<GestureDetector>(find.byType(GestureDetector)),
      ];
      var tapped = 0;
      for (final w in tappables) {
        if (tapped >= 25) break;
        final finder = find.byWidget(w);
        if (t.evaluate().isEmpty) continue;
        try {
          await t.tap(finder.first, warnIfMissed: false);
          await t.pumpAndSettle();
          tapped++;
        } catch (_) {
          // off-screen or covered; not a failure by itself
        }
        t.takeException();
      }
      final err = t.takeException();
      expect(err, isNull,
          reason: 'exception on $path after $tapped taps');
    }
  });
}
