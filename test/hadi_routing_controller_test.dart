import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_routing.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:ar_rayaan/features/hadi/presentation/hadi_screen.dart';
import 'package:ar_rayaan/features/stories/application/saved_stories_controller.dart';
import 'package:ar_rayaan/features/stories/data/stories_repository.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';
import 'hadi_eval/corpus_fixture.dart';

Story _story(String id, String title) => Story(
      id: id,
      collection: 'prophets',
      title: title,
      kicker: '',
      subtitle: '',
      sourceLabel: kLabelEstablished,
      sources: const <String>[],
      chapters: const <StoryChapter>[],
      familyQuestion: '',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<Story> stories = <Story>[
    _story('p-yusuf', 'Yusuf (Joseph)'),
    _story('p-musa', 'Musa (Moses)'),
  ];

  Future<ProviderContainer> container() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final HadiCorpus corpus = loadRealCorpus();
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        hadiCorpusProvider.overrideWith((ref) => corpus),
        storiesProvider.overrideWith((ref) async => stories),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('Hadi only says it saved a story when it did', () {
    test('"Bookmark Yusuf" really saves it and says where it is', () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      final String reply =
          await ctrl.ask('Bookmark Yusuf', provider: const OfflineHadiProvider());
      expect(c.read(savedStoriesProvider), contains('p-yusuf'));
      expect(reply, contains('Saved.'));
      expect(reply, contains('Yusuf (Joseph)'));
      final HadiMessage last = c.read(hadiControllerProvider).messages.last;
      expect(last.routes, <String>['/journey']);
      expect(last.fromHadi, isTrue);
    });

    test('a request that names no story saves nothing and claims nothing',
        () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      final String reply = await ctrl.ask('bookmark the moon landing',
          provider: const OfflineHadiProvider());
      expect(c.read(savedStoriesProvider), isEmpty);
      expect(reply.contains('Saved.'), isFalse);
    });

    test('the shelf tells the person how to ask, and where it ends up',
        () async {
      final String a = await const OfflineHadiProvider()
          .ask('how do I bookmark a story', const <HadiMessage>[]);
      expect(a, contains('bookmark Yusuf'));
      expect(a, contains('[GO:/journey]'));
    });
  });

  group('a refusal in the chat is never a dead end', () {
    test('the first refusal keeps its text and gets buttons', () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask('Tell me about quantum entanglement',
          provider: const OfflineHadiProvider());
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.text, contains('would rather not guess'));
      expect(m.text, contains(HadiRouting.refusalLeadIn));
      expect(m.routes, contains('/search'));
      expect(m.routes.length, 2);
    });

    test('asking again in other words does not repeat the refusal', () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask('Tell me about quantum entanglement',
          provider: const OfflineHadiProvider());
      final String first = c.read(hadiControllerProvider).messages.last.text;
      await ctrl.ask('what is quantum entanglement then',
          provider: const OfflineHadiProvider());
      final HadiMessage second = c.read(hadiControllerProvider).messages.last;
      expect(second.text, isNot(first));
      expect(second.routes, contains('/search'));
    });

    test('a ruling it cannot answer points to Our Sources', () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask('Is it halal to do the thing',
          provider: const OfflineHadiProvider());
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.routes.first, '/sources');
    });
  });

  group('"Yes please" after a condolence gives the du\'a', () {
    test('through the controller', () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask('my mother died last week',
          provider: const OfflineHadiProvider());
      final String reply = await ctrl.ask('Yes please, the dua for my mother',
          provider: const OfflineHadiProvider());
      expect(reply, contains('Allahumma ighfir li hayyina'));
    });
  });

  group('every route the routing code can offer is allowed', () {
    test('each quoted path in hadi_routing.dart is on the whitelist', () {
      final String src =
          File('lib/features/hadi/data/hadi_routing.dart').readAsStringSync();
      final Set<String> paths = <String>{
        for (final RegExpMatch m
            in RegExp(r"'(/[a-z0-9\-/]+)'").allMatches(src))
          m.group(1)!,
      };
      expect(paths, isNotEmpty);
      for (final String p in paths) {
        expect(kHadiNavWhitelist.contains(p), isTrue, reason: p);
      }
    });
  });

  group('a question carried in the route', () {
    testWidgets('is asked once when Hadi opens', (WidgetTester tester) async {
      await AppHarness.boot(tester);
      await AppHarness.go(
        tester,
        find.byType(Scaffold).first,
        '/hadi?q=Tell%20me%20about%20quantum%20entanglement',
      );
      final ProviderContainer c =
          ProviderScope.containerOf(tester.element(find.byType(HadiScreen)));
      List<String> asked() => <String>[
            for (final HadiMessage m in c.read(hadiControllerProvider).messages)
              if (!m.fromHadi) m.text,
          ];
      expect(asked(), <String>['Tell me about quantum entanglement']);
      await AppHarness.settle(tester);
      expect(asked().length, 1, reason: 'the question must not be sent twice');
    });

    testWidgets('nothing is asked when there is no question',
        (WidgetTester tester) async {
      await AppHarness.boot(tester);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/hadi');
      final ProviderContainer c =
          ProviderScope.containerOf(tester.element(find.byType(HadiScreen)));
      expect(c.read(hadiControllerProvider).messages.length, 1);
    });
  });
}
