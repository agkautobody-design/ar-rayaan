import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/quran/application/quran_providers.dart';
import 'package:ar_rayaan/features/quran/data/bundled_quran_repository.dart';
import 'package:ar_rayaan/features/stories/data/story_layers_repository.dart';
import 'package:ar_rayaan/features/stories/domain/story_layers.dart';
import 'package:ar_rayaan/features/stories/presentation/story_layers_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StoryLayersRepository', () {
    test('finds the layers for a story by id, and nothing for others', () async {
      final StoryLayersRepository repo = StoryLayersRepository();
      expect(await repo.subjectFor('prophet-sulayman'), 'sulayman');
      expect(await repo.subjectFor('ghayb-jinn-created'), 'jinn');
      expect(await repo.subjectFor('ghayb-2am-gog'), 'gog-magog');
      expect(await repo.subjectFor('no-such-story'), isNull);
      final StoryLayers? sulayman = await repo.loadFor('prophet-sulayman');
      expect(sulayman, isNotNull);
      expect(sulayman!.hadith, isNotEmpty);
      expect(sulayman.earlier, isNotEmpty);
      expect(await repo.loadFor('no-such-story'), isNull);
    });
  });

  group('StoryLayersSection', () {
    Future<Widget> app(
      WidgetTester tester,
      String storyId,
      StoryLayers? layers,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      late SharedPreferences prefs;
      final BundledQuranRepository quran = BundledQuranRepository();
      // rootBundle I/O needs the real event loop - FakeAsync never delivers it.
      await tester.runAsync(() async {
        prefs = await SharedPreferences.getInstance();
        await quran.all();
      });
      return ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          quranRepositoryProvider.overrideWithValue(quran),
          storyLayersProvider.overrideWith((ref, String id) async => layers),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StoryLayersSection(storyId: storyId),
            ),
          ),
        ),
      );
    }

    Future<void> openBlock(WidgetTester tester, String key) async {
      final Finder header = find.descendant(
        of: find.byKey(ValueKey<String>(key)),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(header.first);
      await tester.tap(header.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('shows the banner and the four layers for Sulayman',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      StoryLayers? layers;
      await tester.runAsync(() async {
        layers = await StoryLayersRepository().loadFor('prophet-sulayman');
      });
      expect(layers, isNotNull);

      await tester.pumpWidget(await app(tester, 'prophet-sulayman', layers));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('GO DEEPER'), findsOneWidget);
      expect(find.textContaining('Scholar review needed'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('layer-quran')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('layer-hadith')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('layer-scholarly')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('layer-differences')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('layer-earlier')), findsOneWidget);

      // Qur'an passages come from the bundled text.
      await openBlock(tester, 'layer-quran');
      expect(find.textContaining('language of birds'), findsWidgets);
      expect(find.textContaining('Saheeh International'), findsWidgets);

      // Hadith carry grade AND grader.
      await openBlock(tester, 'layer-hadith');
      expect(find.text('Grade: Sahih'), findsWidgets);
      expect(find.textContaining('Graded by: Darussalam'), findsWidgets);
      expect(find.text('Sahih al-Bukhari 3424'), findsOneWidget);

      // Scholars' accounts are labelled as not revelation.
      await openBlock(tester, 'layer-scholarly');
      expect(find.text('Scholarly explanation — not revelation'),
          findsWidgets);

      // Differences are labelled.
      await openBlock(tester, 'layer-differences');
      expect(find.text('Disputed in the sources'), findsWidgets);

      // Earlier accounts: the fixed badge, never reworded.
      await openBlock(tester, 'layer-earlier');
      expect(find.text('NOT FROM THE QUR’AN'), findsWidgets);
      expect(find.textContaining('Contradicts our sources'), findsOneWidget);
    });

    testWidgets('renders nothing for a story with no layers',
        (WidgetTester tester) async {
      await tester.pumpWidget(await app(tester, 'prophet-nuh', null));
      await tester.pump();
      expect(find.text('GO DEEPER'), findsNothing);
    });
  });
}
