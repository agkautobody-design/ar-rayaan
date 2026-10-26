import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_stats.dart';
import 'package:ar_rayaan/features/hadi/application/local_knowledge_provider.dart';
import 'package:ar_rayaan/features/hadi/data/local_knowledge.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadi_eval/corpus_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final LocalKnowledge lk = loadRealKnowledge();

  group('tokens', () {
    test('spelling variants fold to one word', () {
      expect(LocalKnowledge.tokens('Wudhu'), <String>['wudu']);
      expect(LocalKnowledge.tokens('namaz'), <String>['salah']);
      expect(LocalKnowledge.tokens('How do I pray?'), <String>['salah']);
      expect(LocalKnowledge.tokens('the of and'), isEmpty);
    });
  });

  group('confident answers quote the right entry', () {
    const Map<String, String> want = <String, String>{
      'how to make wudu': 'huda-wudu',
      'wudhu': 'huda-wudu',
      'how do i do ghusl': 'huda-ghusl',
      'what is tayammum': 'huda-tayammum',
      'how to pray tahajjud': 'huda-tahajjud',
      'what is zakat': 'huda-zakat',
      'what is aqiqah': 'huda-baby',
      'rights of parents': 'huda-parents',
      'who was abu bakr': 'comp-abu-bakr',
      'who is khadijah': 'woman-khadijah',
      'what is the hijrah': 'seerah-13',
      'who is israfil': 'ghayb-israfil',
      'what is barzakh': 'ghayb-jr-barzakh',
    };
    for (final MapEntry<String, String> e in want.entries) {
      test(e.key, () {
        final KnowledgeMatch? m = lk.confident(e.key);
        expect(m, isNotNull, reason: e.key);
        expect(m!.entry.id, e.value);
      });
    }
  });

  group('no guess', () {
    test('nonsense and unknown topics are not answered', () {
      for (final String q in <String>[
        'quantum entanglement',
        'best pizza recipe',
        'asdf qwer',
        'what is the capital of france',
      ]) {
        expect(lk.confident(q), isNull, reason: q);
      }
    });

    test('app lookups are left to the screens', () {
      expect(LocalKnowledge.looksLikeLookup('how do i find qibla'), isTrue);
      expect(LocalKnowledge.looksLikeLookup('prayer times near me'), isTrue);
      expect(LocalKnowledge.looksLikeLookup('how to make wudu'), isFalse);
    });

    test('a broad word never picks between two different topics', () {
      expect(lk.confident('dua'), isNull);
    });
  });

  group('composition is quotation only', () {
    test('a guide answer is built from its own steps and source line', () {
      final KnowledgeMatch m = lk.confident('how to make wudu')!;
      final String text = LocalKnowledge.compose(m.entry);
      expect(text, contains(m.entry.title));
      expect(text, contains(m.entry.body.first));
      expect(text, contains('Source: ${m.entry.source}'));
      expect(text.length, lessThan(2200));
    });

    test('every guide step in a composed answer is verbatim', () {
      for (final KnowledgeEntry e in lk.entries.where(
        (KnowledgeEntry x) => x.kind == 'guide',
      )) {
        final String text = LocalKnowledge.compose(e);
        expect(text, contains(e.body.first), reason: e.id);
      }
    });

    test('an unverified story says so before the story', () {
      final Iterable<KnowledgeEntry> unchecked = lk.entries.where(
        (KnowledgeEntry e) => e.note.startsWith('Unverified'),
      );
      for (final KnowledgeEntry e in unchecked) {
        final String text = LocalKnowledge.compose(e);
        expect(text.indexOf('Unverified'), lessThan(text.indexOf(e.body.first)),
            reason: e.id);
      }
    });
  });

  group('in Hadi', () {
    Future<ProviderContainer> container() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final HadiCorpus corpus = loadRealCorpus();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          hadiCorpusProvider.overrideWith((ref) => corpus),
          localKnowledgeProvider.overrideWith((ref) async => lk),
        ],
      );
      addTearDown(c.dispose);
      await c.read(localKnowledgeProvider.future);
      return c;
    }

    test('a guide question is answered from the guide, with its source',
        () async {
      final ProviderContainer c = await container();
      await c.read(hadiControllerProvider.notifier).ask('who was abu bakr');
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.live, isFalse);
      expect(m.text, contains('Abu Bakr as-Siddiq'));
      expect(m.text, contains('Source:'));
      expect(m.routes, contains('/stories'));
      expect(c.read(hadiStatsProvider).count(HadiAnswerKind.local), 1);
    });

    test('a crisis message is never answered from the index', () async {
      final ProviderContainer c = await container();
      await c.read(hadiControllerProvider.notifier).ask('I want to kill myself');
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.crisis, isNotNull);
      expect(m.text, isNot(contains('Source:')));
    });

    test('a question below the threshold still gets the honest refusal',
        () async {
      final ProviderContainer c = await container();
      await c.read(hadiControllerProvider.notifier).ask('quantum entanglement');
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.text, contains('rather not guess'));
    });
  });
}
