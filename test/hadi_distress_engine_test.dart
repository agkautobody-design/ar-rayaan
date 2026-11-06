import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/support/data/pack_repository.dart';
import 'package:ar_rayaan/features/support/domain/support_pack.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadi_eval/corpus_fixture.dart';

/// Distress support with the REAL packs loaded from disk (being_heard,
/// grief_loss, shame_despair). Where hadi_distress_routing_test.dart pins
/// the no-pack fallback wording, this file pins the full engine behaviour:
/// the shape of a first reply, the move toward a small step, faith offered
/// once and not pushed, the du'a follow-up after a condolence, and the
/// privacy rule that a live provider never sees the private thread.
class _RecSpy implements HadiProvider {
  int calls = 0;
  final List<List<HadiMessage>> histories = <List<HadiMessage>>[];

  @override
  Future<String> ask(String q, List<HadiMessage> h) async {
    calls++;
    histories.add(h);
    return 'Here is a normal answer.';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void loadRealPacks() {
    final List<SupportPack> packs = <SupportPack>[
      for (final String n in <String>[
        'being_heard',
        'grief_loss',
        'shame_despair',
      ])
        SupportPack.parse(
          File('assets/support/packs/$n.json').readAsStringSync(),
        )!,
    ];
    SupportPackRepository.setPacks(packs);
    addTearDown(SupportPackRepository.debugReset);
  }

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

  String? kindOf(String id) {
    for (final SupportPack p in SupportPackRepository.packs) {
      for (final SupportSnippet s in p.snippets) {
        if (s.id == id) return s.kind;
      }
    }
    return null;
  }

  List<String> kindsOf(HadiMessage m) =>
      <String>[for (final String id in m.supportIds) kindOf(id) ?? '?'];

  List<HadiMessage> hadiReplies(ProviderContainer c) => <HadiMessage>[
        for (final HadiMessage m in c.read(hadiControllerProvider).messages)
          if (m.fromHadi && m.support != null) m,
      ];

  group('with the real packs loaded', () {
    test('a first disclosure is oriented, reflected, and asked — all on '
        'the device', () async {
      loadRealPacks();
      final ProviderContainer c = await container();
      final _RecSpy live = _RecSpy();
      final String reply = await c.read(hadiControllerProvider.notifier).ask(
          'I feel anxious and heavy most days, and I am tired of carrying '
          'it alone.',
          provider: live);
      expect(live.calls, 0);
      expect(reply.trim(), isNotEmpty);
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.support, 'being_heard');
      expect(m.sensitive, isTrue);
      expect(m.helpScope, 'general');
      final List<String> kinds = kindsOf(m);
      expect(kinds, contains('orient'), reason: kinds.toString());
      expect(kinds, contains('reflect'), reason: kinds.toString());
      // Exactly one question is asked — never an interrogation.
      expect(kinds.where((String k) => k == 'ask').length, 1,
          reason: kinds.toString());
      expect('?'.allMatches(reply).length, lessThanOrEqualTo(1),
          reason: reply);
    });

    test('the conversation moves toward a small step, not endless listening',
        () async {
      loadRealPacks();
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      final _RecSpy live = _RecSpy();
      await ctrl.ask('I feel anxious and heavy most days.', provider: live);
      for (final String q in <String>[
        'It is like this most days, I cannot switch my mind off.',
        'I barely sleep any more.',
        'It wears me down every single day.',
        'Some days I just sit and stare at the wall.',
      ]) {
        await ctrl.ask(q, provider: live);
      }
      expect(live.calls, 0);
      final List<String> allKinds = <String>[
        for (final HadiMessage m in hadiReplies(c)) ...kindsOf(m),
      ];
      // Within a few turns the person is offered something to DO — a small
      // step — not only more listening.
      expect(allKinds, contains('plan-step'), reason: allKinds.toString());
    });

    test('faith is offered once in a shame conversation, never pushed',
        () async {
      loadRealPacks();
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      final _RecSpy live = _RecSpy();
      await ctrl.ask('I hate myself, I feel like a hypocrite.',
          provider: live);
      for (final String q in <String>[
        'It just keeps coming back.',
        'I keep messing up.',
        'Yes, that is exactly it.',
        'It has been like this for years.',
      ]) {
        await ctrl.ask(q, provider: live);
      }
      expect(live.calls, 0);
      final List<String> allKinds = <String>[
        for (final HadiMessage m in hadiReplies(c)) ...kindsOf(m),
      ];
      expect(allKinds.where((String k) => k == 'islamic').length,
          lessThanOrEqualTo(1),
          reason: allKinds.toString());
    });

    test('every reply in a long heavy conversation keeps the house rules',
        () async {
      loadRealPacks();
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      final _RecSpy live = _RecSpy();
      final RegExp moralising =
          RegExp(r'\b(?:haram|sins?|punish\w*|forbidden)\b');
      await ctrl.ask('I am so lonely, nobody cares about me.',
          provider: live);
      for (final String q in <String>[
        'Everyone seems to manage except me.',
        'I am burnt out and drained.',
        'Things at home are hurting me too.',
        'It has been like this for months.',
        'I do not know what else to say.',
      ]) {
        await ctrl.ask(q, provider: live);
      }
      expect(live.calls, 0);
      final List<HadiMessage> replies = hadiReplies(c);
      expect(replies.length, 6);
      String? previous;
      for (final HadiMessage m in replies) {
        expect(m.sensitive, isTrue);
        expect(m.text.trim(), isNotEmpty);
        expect('?'.allMatches(m.text).length, lessThanOrEqualTo(1),
            reason: m.text);
        expect(moralising.hasMatch(m.text.toLowerCase()), isFalse,
            reason: m.text);
        expect(RegExp(r'\d{3,}').hasMatch(m.text), isFalse, reason: m.text);
        // Never the identical line twice in a row.
        expect(m.text == previous, isFalse, reason: m.text);
        previous = m.text;
      }
    });

    test('a live provider never receives the private thread', () async {
      loadRealPacks();
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      final _RecSpy live = _RecSpy();
      await ctrl.ask('I feel far from Allah and it hurts.', provider: live);
      await ctrl.ask('It has been like this for months.', provider: live);
      expect(live.calls, 0);
      // Now a knowledge request — this leaves the listening mode and MAY
      // go live.
      final String a = await ctrl.ask('Tell me about the five daily prayers',
          provider: live);
      expect(a.trim(), isNotEmpty);
      expect(live.calls, greaterThan(0),
          reason: 'the knowledge request should have reached the provider');
      for (final List<HadiMessage> h in live.histories) {
        for (final HadiMessage m in h) {
          expect(m.sensitive, isFalse,
              reason: 'a sensitive message reached a live provider');
          expect(m.text.toLowerCase().contains('far from allah'), isFalse,
              reason: 'private words reached a live provider');
        }
      }
    });

    test('grief with the real pack: heard first, then the du\'a from the '
        'checked shelf', () async {
      loadRealPacks();
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask('My mother died last week',
          provider: const OfflineHadiProvider());
      final HadiMessage first =
          c.read(hadiControllerProvider).messages.last;
      expect(first.support, 'grief_loss');
      expect(first.sensitive, isTrue);
      expect(kindsOf(first), contains('orient'),
          reason: kindsOf(first).toString());
      final String reply = await ctrl.ask('Yes please, the dua for my mother',
          provider: const OfflineHadiProvider());
      expect(reply, contains('Allahumma ighfir li hayyina'));
    });

    test('thanks mid-conversation is met warmly, still on the device',
        () async {
      loadRealPacks();
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      final _RecSpy live = _RecSpy();
      await ctrl.ask('I feel anxious and heavy most days.', provider: live);
      final String thanks =
          await ctrl.ask('JazakAllah khair, that helps.', provider: live);
      expect(live.calls, 0);
      expect(thanks.trim(), isNotEmpty);
      expect('?'.allMatches(thanks).length, lessThanOrEqualTo(1),
          reason: thanks);
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.sensitive, isTrue);
    });

    test('a real question mid-conversation leaves the listening mode',
        () async {
      loadRealPacks();
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask('I feel far from Allah and it hurts.',
          provider: const OfflineHadiProvider());
      await ctrl.ask('What is the dua for anxiety?',
          provider: const OfflineHadiProvider());
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      // The question is answered as a question — not met with another
      // listening turn.
      expect(m.support, isNull, reason: m.text);
      expect(m.text.trim(), isNotEmpty);
    });
  });
}
