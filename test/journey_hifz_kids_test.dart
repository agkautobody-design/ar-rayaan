import 'dart:async';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/core/route_titles.dart';
import 'package:ar_rayaan/features/academy/presentation/hifz_planner_screen.dart';
import 'package:ar_rayaan/features/journey/domain/journey_progress.dart';
import 'package:ar_rayaan/features/kids/presentation/kids_corner_screen.dart';
import 'package:ar_rayaan/features/noor/application/noor_providers.dart';
import 'package:ar_rayaan/features/noor/presentation/reflections_screen.dart';
import 'package:ar_rayaan/features/quran/application/test_me_provider.dart';
import 'package:ar_rayaan/features/quran/presentation/hideable_arabic.dart';
import 'package:ar_rayaan/features/stories/application/story_narrator.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:ar_rayaan/features/stories/domain/story_length.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A voice that records what it is asked to say and can be held mid-speech.
class FakeTts implements TtsEngine {
  final List<String> spoken = <String>[];
  final List<double> rates = <double>[];
  bool hold = false;
  bool available = true;
  Completer<void>? gate;

  @override
  Future<bool> speak(String text, {required double rate}) async {
    spoken.add(text);
    rates.add(rate);
    if (!available) return false;
    if (hold) {
      gate = Completer<void>();
      await gate!.future;
    }
    return true;
  }

  @override
  Future<void> stop() async {
    final Completer<void>? g = gate;
    if (g != null && !g.isCompleted) g.complete();
  }
}

Story _story(String body) => Story(
  id: 's',
  collection: 'prophets',
  title: 'T',
  kicker: 'K',
  subtitle: 'sub',
  sourceLabel: kLabelEstablished,
  sources: const <String>['Q 1:1'],
  chapters: <StoryChapter>[StoryChapter(heading: 'h', body: body)],
  familyQuestion: 'q?',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('journey ring', () {
    test('is exactly 0 when nothing has been done', () {
      expect(ringValue(const RingInputs()), 0);
      expect(ringValue(const RingInputs(adhkarTotal: 600)), 0);
    });

    test('opening a surah alone is 10%, and parts add up', () {
      expect(ringValue(const RingInputs(openedSurah: true)), closeTo(0.10, 1e-9));
      expect(
        ringValue(
          const RingInputs(
            adhkarDone: 300,
            adhkarTotal: 600,
            openedSurah: true,
            reflections: 2,
            lessonsDone: 1,
            ayatMemorised: 5,
          ),
        ),
        closeTo(0.225 + 0.10 + 0.15 + 0.15 + 0.15, 1e-9),
      );
      // Writing down memorised ayat moves the ring (it used to stay at 0%).
      expect(ringValue(const RingInputs(ayatMemorised: 5)), closeTo(0.15, 1e-9));
      final double all = ringParts(const RingInputs())
          .fold<double>(0, (double a, RingPart p) => a + p.weight);
      expect(all, closeTo(1, 1e-9));
    });

    test('never goes past 100% and handles bad totals', () {
      expect(
        ringValue(const RingInputs(adhkarDone: 900, adhkarTotal: 600)),
        closeTo(0.45, 1e-9),
      );
      expect(daysThisWeekText(0), 'Nothing yet, start whenever you like');
      expect(daysThisWeekText(3), '3 of 7 days');
    });
  });

  group('read aloud', () {
    test('splitForSpeech keeps sentences whole and packs them', () {
      expect(splitForSpeech('   '), isEmpty);
      expect(splitForSpeech('One. Two! Three?'), <String>['One. Two! Three?']);
      final String long = List<String>.generate(
        10,
        (int i) => 'Sentence number $i is here and it takes some space.',
      ).join(' ');
      final List<String> parts = splitForSpeech(long, maxChars: 120);
      expect(parts.length, greaterThan(2));
      expect(parts.every((String p) => p.endsWith('.')), isTrue);
      expect(parts.join(' '), long);
    });

    ProviderContainer make(FakeTts fake) {
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[storyTtsEngineProvider.overrideWithValue(fake)],
      );
      addTearDown(c.dispose);
      c.listen(storyNarratorProvider, (NarratorState? a, NarratorState b) {});
      return c;
    }

    test('Listen reads every piece then goes back to idle', () async {
      final FakeTts fake = FakeTts();
      final ProviderContainer c = make(fake);
      final String text = List<String>.generate(
        12,
        (int i) => 'Sentence number $i is here and it takes some space.',
      ).join(' ');
      await c.read(storyNarratorProvider.notifier).toggle(text);
      expect(fake.spoken.length, greaterThan(1));
      expect(fake.spoken.join(' '), text);
      expect(fake.rates.toSet(), <double>{kNarratorNormalRate});
      expect(c.read(storyNarratorProvider).status, NarratorStatus.idle);
    });

    test('Pause keeps the place and Resume continues from it', () async {
      final FakeTts fake = FakeTts()..hold = true;
      final ProviderContainer c = make(fake);
      final StoryNarrator n = c.read(storyNarratorProvider.notifier);
      final String text = List<String>.generate(
        12,
        (int i) => 'Sentence number $i is here and it takes some space.',
      ).join(' ');
      unawaited(n.toggle(text));
      await Future<void>.delayed(Duration.zero);
      expect(c.read(storyNarratorProvider).status, NarratorStatus.playing);
      expect(fake.spoken.length, 1);

      await n.pause();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(storyNarratorProvider).status, NarratorStatus.paused);
      expect(c.read(storyNarratorProvider).chunk, 0);

      fake.hold = false;
      await n.toggle(text); // Resume
      expect(fake.spoken.first, fake.spoken[1]); // piece 0 said again
      expect(c.read(storyNarratorProvider).status, NarratorStatus.idle);
    });

    test('Slow changes the rate', () async {
      final FakeTts fake = FakeTts();
      final ProviderContainer c = make(fake);
      final StoryNarrator n = c.read(storyNarratorProvider.notifier);
      await n.setSlow(true);
      await n.toggle('A short story. It ends.');
      expect(fake.rates, <double>[kNarratorSlowRate]);
    });

    test('no voice: says so instead of failing', () async {
      final FakeTts fake = FakeTts()..available = false;
      final ProviderContainer c = make(fake);
      await c.read(storyNarratorProvider.notifier).toggle('Hello there.');
      final NarratorState s = c.read(storyNarratorProvider);
      expect(s.unavailable, isTrue);
      expect(s.status, NarratorStatus.idle);
    });
  });

  group('story length', () {
    test('short read is derived from the words', () {
      expect(_story('one two three').isShortRead, isTrue);
      expect(_story('one two three').readMinutes, 1);
      final String big = List<String>.filled(400, 'word').join(' ');
      expect(_story(big).isShortRead, isFalse);
      expect(_story(big).readMinutes, 3);
    });
  });

  group('screens', () {
    Future<void> pump(WidgetTester t, Widget w) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: w)));
      await t.pump();
    }

    testWidgets('kids corner has the three big buttons', (t) async {
      await pump(t, const KidsCornerScreen());
      expect(find.text('Arabic letters'), findsOneWidget);
      expect(find.text('Games'), findsOneWidget);
      expect(find.text('Stories school'), findsOneWidget);
      expect(RouteTitles.forPath('/kids'), contains('For Children'));
    });

    test('kids doors drop Academy ones when the Academy is off', () {
      expect(kidsDoorsFor(showAcademy: true).length, 5);
      expect(
        kidsDoorsFor(showAcademy: false).map((KidsDoor d) => d.id),
        <String>['games', 'surahs', 'duas'],
      );
    });

    testWidgets('hifz planner opens on the surah it is given', (t) async {
      await pump(t, const HifzPlannerScreen(initialSurah: 36));
      expect(find.textContaining('36 · '), findsWidgets);
    });

    testWidgets('test-me hides the Arabic until tapped', (t) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(
            home: Scaffold(
              body: HideableArabic(surah: 1, ayah: 2, child: Text('ARABIC')),
            ),
          ),
        ),
      );
      expect(find.text('ARABIC'), findsOneWidget);
      c.read(testMeProvider.notifier).state = true;
      await t.pump();
      expect(find.text('ARABIC'), findsNothing);
      await t.tap(find.byKey(const Key('hidden-ayah-2')));
      await t.pump();
      expect(find.text('ARABIC'), findsOneWidget);
    });

    testWidgets('reflections list shows saved ones, newest first', (t) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      await c.read(noorReflectionsProvider.notifier).add('first');
      await c.read(noorReflectionsProvider.notifier).add('second');
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: ReflectionsScreen()),
        ),
      );
      expect(find.byKey(const Key('reflection-0')), findsOneWidget);
      expect(
        (t.widget(find.byKey(const Key('reflection-0'))) as Text).data,
        'second',
      );
      await t.tap(find.text('first'));
      await t.pump();
      expect(find.text('Your reflection'), findsOneWidget);
    });
  });
}
