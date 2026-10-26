import 'package:ar_rayaan/app/core/packages/hadi_package.dart';
import 'package:ar_rayaan/app/core/packages/usage_meter.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_stats.dart';
import 'package:ar_rayaan/features/hadi/application/local_knowledge_provider.dart';
import 'package:ar_rayaan/features/hadi/data/groq_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_routing.dart';
import 'package:ar_rayaan/features/hadi/data/hosted_ai.dart';
import 'package:ar_rayaan/features/hadi/data/hosted_cache.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadi_eval/corpus_fixture.dart';

/// A scripted hosted backend. Counts calls so a test can prove it was (or
/// was not) reached.
class FakeHostedAi implements HostedAi {
  FakeHostedAi({
    this.reply = 'As-salamu alaikum. That is outside what I can check, but '
        'in general it is a matter of everyday knowledge. Does that help?',
    this.available = true,
    this.error,
  });

  final String reply;
  final bool available;
  final Object? error;
  final List<HostedAiRequest> requests = <HostedAiRequest>[];

  @override
  bool get isAvailable => available;

  @override
  Future<HostedAiReply> ask(HostedAiRequest request) async {
    requests.add(request);
    final Object? e = error;
    if (e != null) throw e;
    return HostedAiReply(reply);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('package table', () {
    test('every package is unlimited by default (owner decision)', () {
      for (final HadiPackage p in HadiPackage.values) {
        final HadiPackageLimits l = kHadiPackageLimits[p]!;
        expect(l.hostedPerDay, isNull, reason: p.name);
        expect(l.hostedPerMonth, isNull, reason: p.name);
        expect(l.maxReplyChars, greaterThan(100));
        expect(kHadiPackageLabels[p], isNotEmpty);
      }
    });

    test('tier ids map to packages and unknown means free', () {
      expect(packageFromTier('plus'), HadiPackage.plus);
      expect(packageFromTier('family'), HadiPackage.family);
      expect(packageFromTier('free'), HadiPackage.free);
      expect(packageFromTier('gold'), HadiPackage.free);
    });
  });

  group('UsageMeter (dormant)', () {
    const HadiPackageLimits tiny = HadiPackageLimits(
      hostedPerDay: 2,
      hostedPerMonth: 3,
      maxReplyChars: 500,
    );

    Future<UsageMeter> meterAt(DateTime Function() clock) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      return UsageMeter(await SharedPreferences.getInstance(), clock: clock);
    }

    test('unlimited limits never block', () async {
      final UsageMeter m = await meterAt(() => DateTime(2026, 3, 10));
      for (int i = 0; i < 50; i++) {
        expect(await m.tryConsume(const HadiPackageLimits()), isTrue);
      }
    });

    test('when limits are switched on, they hold and reset', () async {
      DateTime now = DateTime(2026, 3, 10, 9);
      final UsageMeter m = await meterAt(() => now);
      expect(await m.tryConsume(tiny), isTrue);
      expect(await m.tryConsume(tiny), isTrue);
      expect(await m.tryConsume(tiny), isFalse);
      now = DateTime(2026, 3, 11, 9);
      expect(m.snapshot(tiny).usedToday, 0);
      expect(m.snapshot(tiny).usedThisMonth, 2);
      expect(await m.tryConsume(tiny), isTrue);
      expect(m.snapshot(tiny).canUse, isFalse); // month spent
      now = DateTime(2026, 4, 1, 9);
      expect(m.snapshot(tiny).canUse, isTrue);
    });

    test('refund gives one back and never goes below zero', () async {
      final UsageMeter m = await meterAt(() => DateTime(2026, 3, 10));
      await m.refund();
      expect(m.snapshot(tiny).usedToday, 0);
      await m.tryConsume(tiny);
      await m.refund();
      expect(m.snapshot(tiny).usedToday, 0);
    });
  });

  group('answer cache', () {
    Future<SharedPreferences> prefs() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      return SharedPreferences.getInstance();
    }

    test('questions normalise to one key', () {
      expect(normaliseQuestion('  Please, TELL me: what is Barzakh?!  '),
          'what is barzakh');
      expect(normaliseQuestion('What is Barzakh'),
          normaliseQuestion('what is barzakh?'));
    });

    test('a saved answer is reused until it expires', () async {
      DateTime now = DateTime(2026, 3, 10);
      final HostedAnswerCache c =
          HostedAnswerCache(await prefs(), clock: () => now);
      expect(c.get('k'), isNull);
      await c.put('k', 'an answer');
      expect(c.get('k'), 'an answer');
      now = now.add(const Duration(days: 29));
      expect(c.get('k'), 'an answer');
      now = now.add(const Duration(days: 2));
      expect(c.get('k'), isNull);
    });

    test('the cache is bounded and drops the oldest', () async {
      DateTime now = DateTime(2026, 3, 10);
      final HostedAnswerCache c = HostedAnswerCache(
        await prefs(),
        clock: () => now,
        maxEntries: 3,
      );
      for (int i = 0; i < 5; i++) {
        now = now.add(const Duration(minutes: 1));
        await c.put('k$i', 'a$i');
      }
      expect(c.get('k0'), isNull);
      expect(c.get('k1'), isNull);
      expect(c.get('k4'), 'a4');
    });

    test('empty keys and answers are not stored', () async {
      final HostedAnswerCache c = HostedAnswerCache(await prefs());
      await c.put('', 'x');
      await c.put('k', '  ');
      expect(c.get(''), isNull);
      expect(c.get('k'), isNull);
    });
  });

  group('local counters', () {
    test('count, share and reset', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final HadiStats st = HadiStats(await SharedPreferences.getInstance());
      expect(st.localShare, isNull);
      await st.record(HadiAnswerKind.local);
      await st.record(HadiAnswerKind.local);
      await st.record(HadiAnswerKind.cache);
      await st.record(HadiAnswerKind.hosted);
      expect(st.total, 4);
      expect(st.localShare, 0.75);
      await st.reset();
      expect(st.total, 0);
    });
  });

  group('helpers', () {
    test('limitReply cuts at a sentence end and never inside a token', () {
      final String long = '${'A full sentence here. ' * 40}tail';
      final String cut = limitReply(long, 200);
      expect(cut.length, lessThanOrEqualTo(200));
      expect(cut.endsWith('.'), isTrue);
      expect(limitReply('short', 200), 'short');
      final String tok = '${'x' * 195} [[src:q:94:5-6]]';
      expect(limitReply(tok, 200), isNot(contains('[[')));
    });

    test('ruling-shaped questions are recognised', () {
      expect(isRulingShaped('Is this halal?'), isTrue);
      expect(isRulingShaped('Can I do it?'), isTrue);
      expect(isRulingShaped('How deep is the Mariana Trench?'), isFalse);
    });

    test('hosted scope is Islam-related questions only', () {
      expect(isHostedScope('What is barzakh in Islam?'), isTrue);
      expect(isHostedScope('How deep is the Mariana Trench?'), isFalse);
      expect(isHostedScope('Best pizza recipe'), isFalse);
    });

    test('with no backend, hosted AI is not available', () {
      expect(const UnavailableHostedAi().isAvailable, isFalse);
    });
  });

  group('Hadi with a hosted backend', () {
    // Islam-related questions that the library may not hold. The first test
    // keeps only those it really declines, so a change to the shelf shows up
    // there instead of as a mystery.
    const List<String> candidates = <String>[
      'What is the history of the Umayyad caliphate in Spain?',
      'Explain the story of the Sleepers of the Cave in Islam',
      'Why did the Abbasid caliphate move its capital to Baghdad?',
      'What happened at the battle of Ain Jalut for Muslims?',
      'Who were the great scholars of Andalusia in Islam?',
      'How did Islam spread to Indonesia?',
      'Tell me about Muslim astronomers of the golden age',
      'What is the origin of the Ottoman caliphate in Islam?',
    ];

    Future<List<String>> declined() async {
      final List<String> out = <String>[];
      for (final String q in candidates) {
        final String r = await const OfflineHadiProvider().ask(
          q,
          const <HadiMessage>[],
        );
        if (HadiRouting.isRefusal(r) && !isRulingShaped(q) && isHostedScope(q)) {
          out.add(q);
        }
      }
      return out;
    }

    Future<({ProviderContainer c, FakeHostedAi fake})> setup({
      FakeHostedAi? fake,
    }) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final HadiCorpus corpus = loadRealCorpus();
      final FakeHostedAi f = fake ?? FakeHostedAi();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          hadiCorpusProvider.overrideWith((ref) => corpus),
          hostedAiProvider.overrideWithValue(f),
          localKnowledgeProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(c.dispose);
      return (c: c, fake: f);
    }

    HadiMessage last(ProviderContainer c) =>
        c.read(hadiControllerProvider).messages.last;

    int stat(ProviderContainer c, HadiAnswerKind k) =>
        c.read(hadiStatsProvider).count(k);

    test('the shelf declines enough of the test questions', () async {
      expect((await declined()).length, greaterThanOrEqualTo(3));
    });

    test('an out-of-library question gets a labelled, short hosted request',
        () async {
      final List<String> qs = await declined();
      final s = await setup();
      await s.c.read(hadiControllerProvider.notifier).ask(qs[0]);
      expect(s.fake.requests, hasLength(1));
      final HadiMessage m = last(s.c);
      expect(m.live, isTrue);
      expect(m.text, contains(kHostedAiLabel));
      final HostedAiRequest r = s.fake.requests.single;
      expect(r.package, 'free');
      expect(r.question, contains('Do not issue a fatwa'));
      expect(r.maxOutputTokens, kHostedMaxOutputTokens);
      expect(r.preferSmallModel, isTrue);
      expect(r.history.length, lessThanOrEqualTo(kHostedMaxHistory));
      expect(stat(s.c, HadiAnswerKind.hosted), 1);
    });

    test('the same question twice costs one call', () async {
      final List<String> qs = await declined();
      final s = await setup();
      final HadiController h = s.c.read(hadiControllerProvider.notifier);
      await h.ask(qs[0]);
      await h.ask('Please, ${qs[0].toUpperCase()}');
      expect(s.fake.requests, hasLength(1));
      expect(last(s.c).text, contains(kHostedAiLabel));
      expect(stat(s.c, HadiAnswerKind.hosted), 1);
      expect(stat(s.c, HadiAnswerKind.cache), 1);
    });

    test('a question the library answers never reaches the backend', () async {
      final s = await setup();
      await s.c
          .read(hadiControllerProvider.notifier)
          .ask('How do I make wudu?');
      expect(s.fake.requests, isEmpty);
      expect(last(s.c).live, isFalse);
      expect(last(s.c).text, isNot(contains(kHostedAiLabel)));
      expect(stat(s.c, HadiAnswerKind.local), 1);
    });

    test('a crisis message is never sent', () async {
      final s = await setup();
      await s.c
          .read(hadiControllerProvider.notifier)
          .ask('I want to kill myself');
      expect(s.fake.requests, isEmpty);
      expect(last(s.c).crisis, isNotNull);
      expect(stat(s.c, HadiAnswerKind.safety), 1);
    });

    test('ruling, medical and off-topic questions are not sent', () async {
      final s = await setup();
      final HadiController h = s.c.read(hadiControllerProvider.notifier);
      await h.ask('Is bitcoin halal?');
      await h.ask('What dose of ibuprofen should I take?');
      await h.ask('How deep is the Mariana Trench?');
      expect(s.fake.requests, isEmpty);
    });

    test('a failed hosted call falls back, is not counted or saved', () async {
      final List<String> qs = await declined();
      final s = await setup(
        fake: FakeHostedAi(
          error: const HadiProviderException('The service is down.'),
        ),
      );
      final HadiController h = s.c.read(hadiControllerProvider.notifier);
      await h.ask(qs[0]);
      final HadiMessage m = last(s.c);
      expect(m.live, isFalse);
      expect(m.text, contains('Offline guidance'));
      expect(stat(s.c, HadiAnswerKind.failed), 1);
      expect(
        s.c
            .read(usageMeterProvider)
            .snapshot(kHadiPackageLimits[HadiPackage.free]!)
            .usedToday,
        0,
      );
      await h.ask(qs[0]);
      expect(s.fake.requests, hasLength(2)); // nothing was cached
    });

    test('nothing is capped: many hosted questions all go through', () async {
      final List<String> qs = await declined();
      final s = await setup();
      final HadiController h = s.c.read(hadiControllerProvider.notifier);
      for (final String q in qs) {
        await h.ask(q);
      }
      expect(s.fake.requests, hasLength(qs.length));
      expect(last(s.c).text, contains(kHostedAiLabel));
    });

    test('a long hosted reply is shortened to the package limit', () async {
      final List<String> qs = await declined();
      final s = await setup(
        fake: FakeHostedAi(reply: 'A sentence of plain words. ' * 100),
      );
      await s.c.read(hadiControllerProvider.notifier).ask(qs[0]);
      final int max = kHadiPackageLimits[HadiPackage.free]!.maxReplyChars;
      expect(
        last(s.c).text.length,
        lessThanOrEqualTo(max + kHostedAiLabel.length + 2),
      );
    });

    test('with no backend configured nothing changes', () async {
      final List<String> qs = await declined();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final HadiCorpus corpus = loadRealCorpus();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          hadiCorpusProvider.overrideWith((ref) => corpus),
          localKnowledgeProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(c.dispose);
      await c.read(hadiControllerProvider.notifier).ask(qs[0]);
      expect(last(c).live, isFalse);
      expect(last(c).text, isNot(contains(kHostedAiLabel)));
    });
  });
}
