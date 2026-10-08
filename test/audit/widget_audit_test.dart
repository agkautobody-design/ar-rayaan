import 'package:ar_rayaan/app/theme/app_colors.dart';
import 'package:ar_rayaan/features/family/data/family_tree_provider.dart';
import 'package:ar_rayaan/features/feelings/presentation/feelings_screens.dart';
import 'package:ar_rayaan/features/games/presentation/games_screens.dart';
import 'package:ar_rayaan/features/huda/presentation/huda_screens.dart';
import 'package:ar_rayaan/features/stories/data/stories_repository.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:ar_rayaan/features/stories/presentation/stories_screen.dart';
import 'package:ar_rayaan/features/stories/presentation/story_reader_screen.dart';
import 'package:ar_rayaan/features/family/presentation/family_tree_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// WAVE 3 — RENDERING STRESS TEST.
/// Pumps every content screen at multiple device sizes; any overflow or
/// exception fails the test. This is the app trying to break its own screens.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleStory = Story(
    id: 'w3-sample', collection: 'prophets', title: 'Sample Prophet Story',
    kicker: 'THE PROPHETS', subtitle: 'A subtitle long enough to stress the layout at narrow widths',
    sourceLabel: 'Established',
    sources: const ['Qur\u2019an 1:1'],
    chapters: const [
      StoryChapter(heading: 'Chapter One',
        body: 'A long body text that will wrap across several lines on narrow screens and must never overflow. ' * 4,
        arabic: '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064e\u0647\u0650 \u0627\u0644\u0631\u0651\u064e\u062d\u0652\u0645\u064e\u0670\u0646\u0650 \u0627\u0644\u0631\u0651\u064e\u062d\u0650\u064a\u0645\u0650'),
      StoryChapter(heading: 'Chapter Two', body: 'Second chapter body with enough text to matter. ' * 4),
    ],
    familyQuestion: 'A question for the family table?',
  );

  final sampleGuide = Guide(
    id: 'w3-guide', category: 'Worship', title: 'Sample Worship Guide',
    subtitle: 'Step by step', sources: const ['Sahih al-Bukhari 1'],
    steps: const ['First step with a reasonably long instruction line', 'Second step', 'Third step'],
  );

  final sampleTree = FamilyTreeData(
    title: 'The Messengers\u2019 Tree',
    note: 'A note about sources and labels that wraps.',
    sources: const ['Qur\u2019an 6:84'],
    nodes: [
      FamilyNode(id: 'a', name: 'Adam', era: 'The Beginning', parents: const [],
        spouses: const [], children: const ['b'], river: 'root',
        sourceLabel: 'Established', description: 'The first man, father of all.', sources: const ['Qur\u2019an 2:30']),
      FamilyNode(id: 'b', name: 'Nuh', era: 'The Flood', parents: const ['a'],
        spouses: const [], children: const [], river: 'root',
        sourceLabel: 'Established', description: 'The ark builder with a longer description to stress layout.', sources: const ['Qur\u2019an 71']),
    ],
  );

  final sampleFeeling = Feeling(
    id: 'feel-w3', feeling: 'Anxious', line: 'When the chest is tight',
    dua: const DuaBlock(arabic: '\u0627\u0644\u0644\u0651\u064e\u0647\u064f\u0645\u0651\u064e \u0625\u0650\u0646\u0651\u0650\u064a \u0623\u064e\u0639\u064f\u0648\u0630\u064f \u0628\u0650\u0643\u064e',
      body: 'O Allah, I seek refuge in You.', source: 'Sunan Abi Dawud 1551'),
    items: const [FeelingItem(storyId: 'w3-sample', title: 'A match', why: 'Because it fits')],
  );

  final sampleTrivia = [
    TriviaQ(id: 't1', category: 'Prophets', question: 'Who built the ark?',
      options: const ['Nuh', 'Hud', 'Salih', 'Lut'], answer: 0, why: 'Qur\u2019an 11:37'),
  ];

  final sampleNames = [
    const Name99(n: 1, name: 'Ar-Rahman', meaning: 'The Most Compassionate', ref: '55:1'),
  ];

  List<Override> overrides() => [
    storiesProvider.overrideWith((ref) async => [sampleStory]),
    guidesProvider.overrideWith((ref) async => [sampleGuide]),
    familyTreeProvider.overrideWith((ref) async => sampleTree),
    feelingsProvider.overrideWith((ref) async => [sampleFeeling]),
    triviaProvider.overrideWith((ref) async => sampleTrivia),
    namesProvider.overrideWith((ref) async => sampleNames),
  ];

  Future<void> pump(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(ProviderScope(
      overrides: overrides(),
      child: MaterialApp(home: screen),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull,
        reason: 'exception while rendering \${screen.runtimeType} at \$size');
  }

  const phone = Size(390, 844);
  const smallPhone = Size(320, 568);
  const wide = Size(1100, 800);

  testWidgets('W3.1 stories library renders at all sizes', (t) async {
    for (final s in [phone, smallPhone, wide]) {
      await pump(t, const StoriesScreen(), s);
      expect(find.text('Sample Prophet Story'), findsWidgets);
    }
  });

  testWidgets('W3.2 story reader renders (incl. Arabic block)', (t) async {
    for (final s in [phone, smallPhone]) {
      await pump(t, StoryReaderScreen(story: sampleStory), s);
      expect(find.text('Sample Prophet Story'), findsOneWidget);
    }
  });

  testWidgets('W3.3 family tree renders at all sizes', (t) async {
    for (final s in [phone, smallPhone, wide]) {
      await pump(t, const FamilyTreeScreen(), s);
      expect(find.text('Adam'), findsWidgets);
    }
  });

  testWidgets('W3.4 huda guides + guide detail render', (t) async {
    for (final s in [phone, smallPhone]) {
      await pump(t, const HudaScreen(), s);
      await pump(t, GuideScreen(guide: sampleGuide), s);
      expect(find.text('Sample Worship Guide'), findsWidgets);
    }
  });

  testWidgets('W3.5 games hub, trivia, names render', (t) async {
    for (final s in [phone, smallPhone]) {
      await pump(t, const GamesScreen(), s);
      await pump(t, const TriviaScreen(), s);
      await pump(t, const Names99Screen(), s);
      expect(find.text('Ar-Rahman'), findsWidgets);
    }
  });

  testWidgets('W3.6 feelings screens render', (t) async {
    for (final s in [phone, smallPhone]) {
      await pump(t, const FeelingsScreen(), s);
      await pump(t, const FeelingScreen(feelingId: 'feel-w3'), s);
      expect(find.text('Anxious'), findsWidgets);
    }
  });

  testWidgets('W3.7 long content never overflows: stress the reader', (t) async {
    final longStory = Story(
      id: 'w3-long', collection: 'seerah', title: 'A Very Long Title That Could Wrap Awkwardly On Narrow Screens',
      kicker: 'THE SEERAH \u00b7 1 OF 30',
      subtitle: 'An equally long subtitle that keeps going and going to stress every line of the layout engine',
      sourceLabel: 'Established', sources: const ['Sahih al-Bukhari 1'],
      chapters: [
        StoryChapter(heading: 'A long heading ' * 6, body: 'Body. ' * 400),
      ],
      familyQuestion: 'A very long family question that also wraps across multiple lines on small phones?',
    );
    await t.pumpWidget(ProviderScope(
      overrides: overrides(),
      child: MaterialApp(home: StoryReaderScreen(story: longStory)),
    ));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull, reason: 'long-form content overflow');
  });
}
