import 'package:ar_rayaan/app/core/packages/hadi_package.dart';
import 'package:ar_rayaan/app/core/packages/usage_meter.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/groq_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_routing.dart';
import 'package:ar_rayaan/features/hadi/data/hosted_ai.dart';
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
    test('every package has sane, ordered limits', () {
      for (final HadiPackage p in HadiPackage.values) {
        final HadiPackageLimits l = kHadiPackageLimits[p]!;
        expect(l.hostedPerDay, greaterThan(0), reason: p.name);
        expect(l.hostedPerMonth, greaterThanOrEqualTo(l.hostedPerDay));
        expect(l.maxReplyChars, greaterThan(100));
        expect(kHadiPackageLabels[p], isNotEmpty);
      }
      expect(
        kHadiPackageLimits[HadiPackage.free]!.hostedPerDay,
        lessThanOrEqualTo(kHadiPackageLimits[HadiPackage.plus]!.hostedPerDay),
      );
      expect(
        kHadiPackageLimits[HadiPackage.plus]!.hostedPerDay,
        lessThanOrEqualTo(kHadiPackageLimits[HadiPackage.family]!.hostedPerDay),
      );
    });

    test('tier ids map to packages and unknown means free', () {
      expect(packageFromTier('plus'), HadiPackage.plus);
      expect(packageFromTier('family'), HadiPackage.family);
      expect(packageFromTier('free'), HadiPackage.free);
      expect(packageFromTier('gold'), HadiPackage.free);
    });
  });

  group('UsageMeter', () {
    const HadiPackageLimits tiny = HadiPackageLimits(
      hostedPerDay: 2,
      hostedPerMonth: 3,
      maxReplyChars: 500,
    );

    Future<UsageMeter> meterAt(DateTime Function() clock) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      return UsageMeter(await SharedPreferences.getInstance(), clock: clock);
    }

    test('counts down and stops at the daily cap', () async {
      final UsageMeter m = await meterAt(() => DateTime(2026, 3, 10, 9));
      expect(m.snapshot(tiny).label, '2 of 2 AI messages left today');
      expect(await m.tryConsume(tiny), isTrue);
      expect(m.snapshot(tiny).label, '1 of 2 AI messages left today');
      expect(await m.tryConsume(tiny), isTrue);
      expect(m.snapshot(tiny).canUse, isFalse);
      expect(await m.tryConsume(tiny), isFalse);
      expect(m.snapshot(tiny).usedToday, 2);
    });

    test('the day resets, the month does not', () async {
      DateTime now = DateTime(2026, 3, 10, 23, 59);
      final UsageMeter m = await meterAt(() => now);
      await m.tryConsume(tiny);
      await m.tryConsume(tiny);
      now = DateTime(2026, 3, 11, 0, 1);
      final UsageSnapshot s = m.snapshot(tiny);
      expect(s.usedToday, 0);
      expect(s.usedThisMonth, 2);
      expect(s.leftToday, 2);
      expect(s.label, '1 of 2 AI messages left today'); // month room is 1
      expect(s.remaining, 1);
      expect(await m.tryConsume(tiny), isTrue);
      expect(m.snapshot(tiny).canUse, isFalse);
      expect(m.snapshot(tiny).monthSpent, isTrue);
      expect(m.snapshot(tiny).label, contains('this month'));
    });

    test('a new month starts clean', () async {
      DateTime now = DateTime(2026, 3, 31, 12);
      final UsageMeter m = await meterAt(() => now);
      await m.tryConsume(tiny);
      now = DateTime(2026, 4, 1, 8);
      expect(m.snapshot(tiny).usedThisMonth, 0);
      expect(m.snapshot(tiny).usedToday, 0);
    });

    test('refund gives one back and never goes below zero', () async {
      final UsageMeter m = await meterAt(() => DateTime(2026, 3, 10));
      await m.refund();
      expect(m.snapshot(tiny).usedToday, 0);
      await m.tryConsume(tiny);
      await m.refund();
      expect(m.snapshot(tiny).usedToday, 0);
      expect(m.snapshot(tiny).usedThisMonth, 0);
    });

    test('markDayExhausted spends the rest of the day', () async {
      final UsageMeter m = await meterAt(() => DateTime(2026, 3, 10));
      await m.markDayExhausted(tiny);
      expect(m.snapshot(tiny).canUse, isFalse);
    });

    test('survives a restart (same prefs, new meter)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final DateTime t = DateTime(2026, 3, 10);
      await UsageMeter(prefs, clock: () => t).tryConsume(tiny);
      expect(UsageMeter(prefs, clock: () => t).snapshot(tiny).usedToday, 1);
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

    test('the cap message is kind and names the library', () {
      for (final bool month in <bool>[true, false]) {
        final String m = hostedCapMessage(monthSpent: month);
        expect(m, contains('built-in checked library'));
        expect(m.toLowerCase(), isNot(contains('upgrade')));
        expect(m.toLowerCase(), isNot(contains('pay')));
      }
    });

    test('with no backend, hosted AI is not available', () {
      expect(const UnavailableHostedAi().isAvailable, isFalse);
    });
  });

  group('Hadi with a hosted backend', () {
    // Questions the built-in library declines (checked in the first test, so
    // a change to the shelf shows up here instead of as a mystery).
    const List<String> outside = <String>[
      'How deep is the Mariana Trench?',
      'Who built the pyramids of Giza?',
      'What is the tallest mountain in Africa?',
      'How far away is the planet Neptune?',
      'Which river is the longest in Europe?',
    ];

    Future<({ProviderContainer c, FakeHostedAi fake})> setup({
      FakeHostedAi? fake,
      Map<String, Object> prefsInit = const <String, Object>{},
    }) async {
      SharedPreferences.setMockInitialValues(prefsInit);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final HadiCorpus corpus = loadRealCorpus();
      final FakeHostedAi f = fake ?? FakeHostedAi();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          hadiCorpusProvider.overrideWith((ref) => corpus),
          hostedAiProvider.overrideWithValue(f),
        ],
      );
      addTearDown(c.dispose);
      return (c: c, fake: f);
    }

    HadiMessage last(ProviderContainer c) =>
        c.read(hadiControllerProvider).messages.last;

    test('the shelf declines the test questions', () async {
      for (final String q in outside) {
        final String r = await const OfflineHadiProvider().ask(
          q,
          const <HadiMessage>[],
        );
        expect(HadiRouting.isRefusal(r), isTrue, reason: q);
      }
    });

    test('an out-of-library question gets a labelled hosted answer', () async {
      final s = await setup();
      await s.c.read(hadiControllerProvider.notifier).ask(outside[0]);
      expect(s.fake.requests, hasLength(1));
      final HadiMessage m = last(s.c);
      expect(m.live, isTrue);
      expect(m.text, contains(kHostedAiLabel));
      expect(m.text, contains('As-salamu alaikum'));
      // The server is told the package and the scope rules travel with the
      // question.
      expect(s.fake.requests.single.package, 'free');
      expect(s.fake.requests.single.question, contains('Do not issue a fatwa'));
      // One message spent.
      final UsageSnapshot u = s.c
          .read(usageMeterProvider)
          .snapshot(kHadiPackageLimits[HadiPackage.free]!);
      expect(u.usedToday, 1);
    });

    test('a question the library answers never reaches the backend', () async {
      final s = await setup();
      await s.c
          .read(hadiControllerProvider.notifier)
          .ask('How do I make wudu?');
      expect(s.fake.requests, isEmpty);
      expect(last(s.c).live, isFalse);
      expect(last(s.c).text, isNot(contains(kHostedAiLabel)));
      final UsageSnapshot u = s.c
          .read(usageMeterProvider)
          .snapshot(kHadiPackageLimits[HadiPackage.free]!);
      expect(u.usedToday, 0);
    });

    test('a crisis message is never sent and never counted', () async {
      final s = await setup();
      await s.c
          .read(hadiControllerProvider.notifier)
          .ask('I want to kill myself');
      expect(s.fake.requests, isEmpty);
      expect(last(s.c).crisis, isNotNull);
      expect(last(s.c).text, isNot(contains(kHostedAiLabel)));
      final UsageSnapshot u = s.c
          .read(usageMeterProvider)
          .snapshot(kHadiPackageLimits[HadiPackage.free]!);
      expect(u.usedToday, 0);
    });

    test('a ruling or medical question is not sent to the backend', () async {
      final s = await setup();
      final HadiController h = s.c.read(hadiControllerProvider.notifier);
      await h.ask('Is bitcoin halal?');
      await h.ask('What dose of ibuprofen should I take?');
      expect(s.fake.requests, isEmpty);
    });

    test('at the cap Hadi says so kindly and the library still answers',
        () async {
      final s = await setup();
      final HadiController h = s.c.read(hadiControllerProvider.notifier);
      final int cap = kHadiPackageLimits[HadiPackage.free]!.hostedPerDay;
      for (int i = 0; i < cap; i++) {
        await h.ask(outside[i]);
      }
      expect(s.fake.requests, hasLength(cap));
      await h.ask(outside[cap]);
      // No extra call, no paywall wording, the library's reply is shown.
      expect(s.fake.requests, hasLength(cap));
      final HadiMessage m = last(s.c);
      expect(m.live, isFalse);
      expect(m.text, contains('used today\'s AI messages'));
      expect(m.text, contains('built-in checked library'));
      expect(HadiRouting.isRefusal(m.text), isTrue);
      // Core answers still work at the cap.
      await h.ask('How do I make wudu?');
      expect(last(s.c).text, isNot(contains('used today')));
      expect(last(s.c).text, isNotEmpty);
    });

    test('a failed hosted call is refunded and falls back', () async {
      final s = await setup(
        fake: FakeHostedAi(
          error: const HadiProviderException('The service is down.'),
        ),
      );
      await s.c.read(hadiControllerProvider.notifier).ask(outside[0]);
      expect(s.fake.requests, hasLength(1));
      final HadiMessage m = last(s.c);
      expect(m.live, isFalse);
      expect(m.text, contains('Offline guidance'));
      expect(m.text, isNot(contains(kHostedAiLabel)));
      final UsageSnapshot u = s.c
          .read(usageMeterProvider)
          .snapshot(kHadiPackageLimits[HadiPackage.free]!);
      expect(u.usedToday, 0);
    });

    test('a server-side cap is shown kindly and stops further calls',
        () async {
      final s = await setup(fake: FakeHostedAi(error: const HostedAiCapReached()));
      final HadiController h = s.c.read(hadiControllerProvider.notifier);
      await h.ask(outside[0]);
      final HadiMessage m = last(s.c);
      expect(m.text, contains('built-in checked library'));
      expect(m.retryQuestion, isNull);
      await h.ask(outside[1]);
      expect(s.fake.requests, hasLength(1)); // the meter now blocks locally
    });

    test('a long hosted reply is shortened to the package limit', () async {
      final s = await setup(
        fake: FakeHostedAi(reply: 'A sentence of plain words. ' * 100),
      );
      await s.c.read(hadiControllerProvider.notifier).ask(outside[0]);
      final int max = kHadiPackageLimits[HadiPackage.free]!.maxReplyChars;
      expect(
        last(s.c).text.length,
        lessThanOrEqualTo(max + kHostedAiLabel.length + 2),
      );
      expect(last(s.c).text, contains(kHostedAiLabel));
    });

    test('with no backend configured nothing changes', () async {
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
      await c.read(hadiControllerProvider.notifier).ask(outside[0]);
      expect(c.read(hadiControllerProvider).messages.last.live, isFalse);
      expect(
        c.read(hadiControllerProvider).messages.last.text,
        isNot(contains(kHostedAiLabel)),
      );
    });
  });
}
