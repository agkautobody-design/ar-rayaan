import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_decline.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_finder.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_routing.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadi_eval/corpus_fixture.dart';
import 'hadi_eval/hadi_coverage_corpus.dart';
import 'hadi_eval/hadi_coverage_report.dart';

Future<String> ask(String q) =>
    const OfflineHadiProvider().ask(q, const <HadiMessage>[]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('coverage of everyday questions', () {
    late List<CoverageRow> rows;

    setUpAll(() async {
      rows = await runCoverage(knowledge: loadRealKnowledge());
      // The report is regenerated on every run; the committed copy is made
      // with `dart tool/hadi_coverage.dart > docs/hadi_coverage.md`.
      try {
        File('docs/hadi_coverage.md').writeAsStringSync(renderCoverage(rows));
      } catch (_) {}
    });

    test('the corpus is large enough to mean something', () {
      expect(kCoverageQuestions.length, greaterThanOrEqualTo(400));
      expect(kCoverageQuestions.toSet().length, kCoverageQuestions.length);
    });

    test('most questions get an answer or a pointer', () {
      final List<String> misses = <String>[
        for (final CoverageRow r in rows)
          if (r.kind == CoverageKind.miss) r.question,
      ];
      expect(
        misses.length / rows.length,
        lessThan(0.20),
        reason: 'misses (${misses.length}/${rows.length}): '
            '${misses.join(' | ')}',
      );
    });

    test('a miss is never a dead end: closest topics and Search, or a scholar',
        () {
      for (final CoverageRow r in rows) {
        if (r.kind != CoverageKind.miss) continue;
        final bool outside = r.reply.contains(HadiDecline.outOfScopeMarker);
        if (outside) continue;
        expect(r.reply, contains('rather not guess'), reason: r.question);
        if (r.buttons.isEmpty) {
          // No screen resembles the question: the reply itself hands over to
          // a qualified scholar and Our Sources.
          expect(r.reply, contains('qualified'), reason: r.question);
        } else {
          expect(r.buttons, contains('/search'), reason: r.question);
          expect(r.buttons.length, greaterThanOrEqualTo(2),
              reason: r.question);
        }
      }
    });

    test('every button offered anywhere is a screen Hadi may open', () {
      for (final CoverageRow r in rows) {
        for (final String b in r.buttons) {
          expect(HadiTokens.isAllowed(b), isTrue, reason: '${r.question}: $b');
          final bool named = kHadiRouteNames.containsKey(b) ||
              b.startsWith('/huda/guide?id=');
          expect(named, isTrue, reason: '${r.question}: $b has no name');
        }
      }
    });

    test('the question that failed on a phone now has a button', () async {
      for (final String q in <String>[
        'jump near me',
        'Jump near me',
        'jumah near me',
        'juma near me',
        'friday prayer near me',
        'jummah times',
        'mosque near me',
        'masjid near me',
        'halal food near me',
        'nearest mosque',
        'prayer places nearby',
        'jumuah near me',
        'jummah nearby',
      ]) {
        final String a = await ask(q);
        expect(a, contains('[GO:/masajid]'), reason: q);
        expect(HadiRouting.isRefusal(a), isFalse, reason: q);
      }
      expect(await ask('jump near me'), contains('[GO:/prayer]'));
    });

    test('questions about the app answer with one line and a button', () async {
      final Map<String, String> want = <String, String>{
        'where is the tasbeeh': '/tasbeeh',
        'tasbih counter where': '/tasbeeh',
        'where are my bookmarks': '/quran/bookmarks',
        'how do i change language': '/settings/language',
        'make text bigger': '/settings',
        'where can i listen to nasheeds': '/player',
        'show me the 99 names game': '/games/names99',
        'how do i use this app': '/explore',
        'why is hadi offline': '/settings',
      };
      for (final MapEntry<String, String> e in want.entries) {
        final String a = await ask(e.key);
        expect(a, contains('[GO:${e.value}]'), reason: e.key);
      }
    });
  });

  group('the finder', () {
    test('spelling slips of one letter are believed, others are not', () {
      expect(HadiFinder.near('jump', 'juma'), isTrue);
      expect(HadiFinder.near('prayr', 'prayer'), isTrue);
      expect(HadiFinder.near('jump', 'jumuah'), isFalse);
      expect(HadiFinder.near('pray', 'play'), isTrue);
      expect(HadiFinder.near('cat', 'cut'), isFalse);
      expect(HadiFinder.near('zakat', 'balat'), isFalse);
    });

    test('closest topics follow the words of the question', () {
      expect(HadiFinder.closestRoutes('who was abu bakr').first, '/stories');
      expect(HadiFinder.closestRoutes('what is muharram').first, '/calendar');
      expect(HadiFinder.closestRoutes('what is taqwa').first,
          '/academy/aqeedah');
      expect(HadiFinder.closestRoutes('quantum entanglement'), isEmpty);
      expect(HadiFinder.closestRoutes('what is the hijrah'),
          contains('/academy/seerah'));
    });

    test('every route the finder can offer is allowed and named', () {
      for (final String r in kHadiFinderRoutes) {
        expect(HadiTokens.isAllowed(r), isTrue, reason: r);
        expect(
          kHadiRouteNames.containsKey(r) || r.startsWith('/huda/guide?id='),
          isTrue,
          reason: '$r has no button name',
        );
      }
    });

    test('a word that only looks like an app word is not a pointer', () async {
      for (final String q in <String>[
        'what is the text of surah fatiha',
        'what is the counter argument to atheism',
        'how many names does allah have',
        'where is mecca',
      ]) {
        expect(HadiFinder.pointerReply(q), isNull, reason: q);
      }
    });

    test('polite openings do not hide the topic', () async {
      for (final String q in <String>[
        'can you tell me about ramadan',
        'i wanna learn how to pray',
        'please explain wudu',
        'help me with fasting',
      ]) {
        expect(HadiRouting.isRefusal(await ask(q)), isFalse, reason: q);
      }
    });

    test('nothing is invented: unknown things are still refused', () async {
      for (final String q in <String>[
        'Tell me about quantum entanglement',
        'Do I need wudu to touch the Quran?',
        'breakfast',
        'business',
      ]) {
        expect(HadiRouting.isRefusal(await ask(q)), isTrue, reason: q);
      }
    });
  });

  group('in the chat', () {
    Future<ProviderContainer> container() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final HadiCorpus corpus = loadRealCorpus();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          hadiCorpusProvider.overrideWith((ref) => corpus),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('a refusal says it plainly and shows the closest topics', () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask('who was abu bakr', provider: const OfflineHadiProvider());
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.text, contains('I don\'t have a checked answer for that'));
      expect(m.text, contains(HadiRouting.refusalLeadIn));
      expect(m.routes.first, '/stories');
      expect(m.routes.last, '/search');
      expect(m.routes.length, greaterThanOrEqualTo(2));
    });

    test('offline mode is stated once, not on every reply', () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask('how many rakat is fajr',
          provider: const OfflineHadiProvider());
      final HadiMessage first = c.read(hadiControllerProvider).messages.last;
      expect(first.notes, contains(HadiFinder.offlineNote));
      await ctrl.ask('what is zakat', provider: const OfflineHadiProvider());
      final HadiMessage second = c.read(hadiControllerProvider).messages.last;
      expect(second.notes, isEmpty);
    });

    test('a near-me question is not given a ruling footer', () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask('halal food near me',
          provider: const OfflineHadiProvider());
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.routes, contains('/masajid'));
      expect(m.text.contains('not a fatwa'), isFalse);
    });
  });
}
