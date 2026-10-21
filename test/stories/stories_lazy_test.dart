import 'package:ar_rayaan/app/theme/widgets/glass_card.dart';
import 'package:ar_rayaan/features/stories/data/stories_repository.dart';
import 'package:ar_rayaan/features/stories/data/story_layers_repository.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:ar_rayaan/features/stories/presentation/stories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Story _story(int i, String collection) => Story(
      id: 'perf-$i',
      collection: collection,
      title: 'Perf story $i',
      kicker: 'KICKER',
      subtitle: 'Subtitle $i',
      sourceLabel: 'Established',
      sources: const <String>['Qur’an 1:1'],
      chapters: const <StoryChapter>[
        StoryChapter(heading: 'One', body: 'Body'),
      ],
      familyQuestion: 'Question?',
    );

void main() {
  testWidgets('300 stories: only the visible cards are built, none blurred',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final List<Story> stories = <Story>[
      for (int i = 0; i < 150; i++) _story(i, 'prophets'),
      for (int i = 150; i < 300; i++) _story(i, 'companions'),
    ];

    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[
        storiesProvider.overrideWith((ref) async => stories),
        storyIdsWithLayersProvider
            .overrideWith((ref) async => <String>{'perf-0'}),
      ],
      child: const MaterialApp(home: StoriesScreen()),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('300 STORIES LOADED'), findsOneWidget);
    expect(find.text('Stories of the Prophets'), findsOneWidget);
    expect(find.text('Perf story 0'), findsOneWidget);
    final int cards = find.byType(GlassCard).evaluate().length;
    expect(cards, greaterThan(0));
    expect(cards, lessThan(30), reason: 'cards: $cards of 300');
    expect(find.text('Perf story 299'), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);

    // Scrolling to the end builds the last story.
    await tester.scrollUntilVisible(
      find.text('Perf story 299'),
      600,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 400,
    );
    await tester.pumpAndSettle();
    expect(find.text('Perf story 299'), findsOneWidget);
    expect(find.text('Perf story 0'), findsNothing);
  });

  testWidgets('empty library still shows the retry prompt',
      (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[
        storiesProvider.overrideWith((ref) async => <Story>[]),
        storyIdsWithLayersProvider.overrideWith((ref) async => <String>{}),
      ],
      child: const MaterialApp(home: StoriesScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('The shelves are empty'), findsOneWidget);
    expect(find.text('TAP TO RETRY'), findsOneWidget);
  });
}
