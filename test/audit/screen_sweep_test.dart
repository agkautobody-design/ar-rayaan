import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/router.dart';
import 'package:ar_rayaan/features/academy/presentation/wasia_lessons.dart';
import 'package:ar_rayaan/features/family/data/family_tree_provider.dart';
import 'package:ar_rayaan/features/feelings/presentation/feelings_screens.dart';
import 'package:ar_rayaan/features/games/presentation/games_screens.dart';
import 'package:ar_rayaan/features/huda/presentation/huda_screens.dart';
import 'package:ar_rayaan/features/stories/data/stories_repository.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// WAVE 8 - THE FULL SCREEN SWEEP. Every route in the app, pumped one by
/// one through the real router; any build exception on any screen fails
/// the test. This is the "check every screen individually" law, automated.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleStory = Story(
    id: 'w8', collection: 'prophets', title: 'S', kicker: 'K',
    subtitle: 'sub', sourceLabel: 'Established', sources: const ['Q 1:1'],
    chapters: const [StoryChapter(heading: 'h', body: 'long enough body text here to pass')],
    familyQuestion: 'q?',
  );

  final routes = <String, Object? Function()>{
    '/home/quick': () => null,
    '/home/elder': () => null,
    '/elder-care': () => null,
    '/stories': () => null,
    '/family-tree': () => null,
    '/huda': () => null,
    '/games': () => null,
    '/games/trivia': () => null,
    '/games/names99': () => null,
    '/games/lineage': () => null,
    '/games/ayah': () => null,
    '/games/hijrah': () => null,
    '/games/shatranj': () => null,
    '/games/ludo': () => null,
    '/feelings': () => null,
    '/notes': () => null,
    '/downloads': () => null,
    '/majlis': () => null,
    '/player': () => null,
    '/hadith': () => null,
    '/sakina': () => null,
    '/hadi': () => null,
    '/academy': () => null,
    '/academy/gate': () => null,
    '/academy/letters': () => null,
    '/academy/family': () => null,
    '/qibla': () => null,
  };

  testWidgets('W8 every screen builds without exception', (t) async {
    final router = buildRouter();
    final failures = <String>[];

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
        triviaProvider.overrideWith((ref) async => [
              TriviaQ(id: 'w8', category: 'Prophets', question: 'Who built the ark?',
                  options: const ['Nuh', 'Hud', 'Salih', 'Lut'], answer: 0, why: 'Q 11:37'),
            ]),
        namesProvider.overrideWith((ref) async => [
              const Name99(n: 1, name: 'Ar-Rahman', meaning: 'The Most Compassionate', ref: '55:1'),
            ]),
        appUrlProvider.overrideWith((ref) => 'https://ar-rayaan.onrender.com'),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    for (final entry in routes.entries) {
      final path = entry.key;
      try {
        router.go(path);
        await t.pump();
        await t.pump(const Duration(milliseconds: 350));
        final err = t.takeException();
        if (err != null) failures.add('$path :: $err');
      } catch (e) {
        failures.add('$path :: NAV $e');
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
