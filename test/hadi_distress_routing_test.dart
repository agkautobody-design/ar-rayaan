import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:ar_rayaan/features/hadi/grounding/distress_signal.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/support_signal.dart';
import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadi_eval/corpus_fixture.dart';

/// Distress routing: a person carrying sadness, anxiety, loneliness, grief,
/// overwhelm or a feeling of being far from Allah is heard by the on-device
/// support engine — never sent to a live model, never saved, never given a
/// ruling card. CLINICIAN and SCHOLAR REVIEW NEEDED for the wording pinned
/// here (docs/SCHOLAR_REVIEW_REGISTER.md).
class _Spy implements HadiProvider {
  int calls = 0;

  @override
  Future<String> ask(String q, List<HadiMessage> h) async {
    calls++;
    return 'Here is a normal answer.';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('the detector', () {
    test('every I Need Help starting point is caught', () {
      // The exact sentences the /i-need-help chips send (need_help_screen).
      expect(
        DistressSignal.packFor('I just need someone to hear me. I do not '
            'want advice yet, I just need to say it to someone who will not '
            'judge me.'),
        'being_heard',
      );
      expect(
        DistressSignal.packFor(
            'I feel far from Allah and it hurts. I do not know how to come back.'),
        'being_heard',
      );
      expect(
        DistressSignal.packFor('I am struggling with a habit I hate and I '
            'feel ashamed. I keep going back to it and I do not want to.'),
        'shame_despair',
      );
      expect(
        DistressSignal.packFor('I feel anxious and heavy most days, and I am '
            'tired of carrying it alone.'),
        'being_heard',
      );
      expect(
        DistressSignal.packFor(
            'Things at home are hurting me and I do not know what to do.'),
        'being_heard',
      );
      expect(
        DistressSignal.packFor(
            'I have lost someone I love and the pain does not leave.'),
        'grief_loss',
      );
      expect(
        DistressSignal.packFor('My marriage is hurting me. We keep having '
            'the same fight and I do not know how to reach them anymore.'),
        'marriage_strain',
      );
      expect(
        DistressSignal.packFor('I am drowning in bills and debt and I '
            'cannot see a way through. I need to say it out loud to someone.'),
        'money_hardship',
      );
      expect(
        DistressSignal.packFor('I am sick and scared, and my body is '
            'hurting. I need someone to hear me.'),
        'illness_pain',
      );
      expect(
        DistressSignal.packFor('My family does not understand me and home '
            'hurts right now. I need to talk about it.'),
        'family_strain',
      );
    });

    test('a death routes to the grief pack', () {
      expect(DistressSignal.packFor('My mother died last week'), 'grief_loss');
      expect(DistressSignal.packFor('his janaza is tomorrow, my heart is broken'),
          'grief_loss');
      // "lost my job" is heavy, but it is not a death — it is money
      // hardship, which has its own pack.
      expect(DistressSignal.packFor('I lost my job and I feel broken'),
          'money_hardship');
    });

    test('marriage, money, illness and family each route to their own pack',
        () {
      expect(
          DistressSignal.packFor('My marriage is hurting me. We keep having '
              'the same fight and I do not know how to reach them anymore.'),
          'marriage_strain');
      expect(DistressSignal.packFor('my husband never listens to me anymore'),
          'marriage_strain');
      expect(
          DistressSignal.packFor('my mother in law interferes in everything '
              'and my husband says nothing'),
          'marriage_strain');
      expect(DistressSignal.packFor('I have been thinking about divorce'),
          'marriage_strain');
      expect(
          DistressSignal.packFor('I am drowning in bills and debt and I '
              'cannot see a way through.'),
          'money_hardship');
      expect(DistressSignal.packFor('I got fired and I cannot tell my family'),
          'money_hardship');
      expect(DistressSignal.packFor('the rent is due and I have nothing'),
          'money_hardship');
      expect(
          DistressSignal.packFor(
              'I was just diagnosed with cancer and I am terrified'),
          'illness_pain');
      expect(
          DistressSignal.packFor(
              'I have been in pain for years and nobody believes me'),
          'illness_pain');
      expect(DistressSignal.packFor('my parents dont understand me at all'),
          'family_strain');
      expect(DistressSignal.packFor('my family disowned me when I converted'),
          'family_strain');
      expect(
          DistressSignal.packFor(
              'my son is drifting and I do not know how to reach him'),
          'family_strain');
    });

    test('idioms and third-person remarks stay out', () {
      // "sick and tired of traffic" is not an illness disclosure.
      expect(DistressSignal.packFor('I am sick and tired of this traffic'),
          isNull);
      // A friend's diagnosis is not the speaker's own body.
      expect(DistressSignal.packFor('my friend was diagnosed with cancer'),
          isNull);
      // A divorce QUESTION is a ruling, not a disclosure.
      expect(DistressSignal.packFor('is talaq valid if said in anger?'),
          isNull);
    });

    test('shame and despair route to their own pack', () {
      expect(DistressSignal.packFor('I hate myself, I feel like a hypocrite'),
          'shame_despair');
      expect(DistressSignal.packFor('I feel hopeless about everything'),
          'shame_despair');
    });

    test('questions stay questions', () {
      expect(DistressSignal.packFor('What is the dua for anxiety?'), isNull);
      expect(DistressSignal.packFor('Is it haram to feel sad?'), isNull);
      expect(DistressSignal.packFor('Do I have depression?'), isNull);
      expect(DistressSignal.packFor('Are you a real person?'), isNull);
      expect(DistressSignal.packFor('Tell me about patience'), isNull);
      expect(
          DistressSignal.packFor('Tell me about the stages of grief in Islam'),
          isNull);
    });

    test('the pain is named so no reply is generic', () {
      expect(DistressSignal.themeFor('I feel anxious and heavy most days'),
          'anxiety');
      expect(DistressSignal.themeFor('I feel far from Allah and it hurts'),
          'far');
      expect(DistressSignal.themeFor('I am so lonely, nobody cares'),
          'loneliness');
      expect(DistressSignal.themeFor('My mother died last week'), 'grief');
      expect(DistressSignal.themeFor('I hate myself'), 'shame');
      expect(DistressSignal.themeFor('I feel hopeless'), 'despair');
      expect(DistressSignal.themeFor('Things at home are hurting me'), 'home');
      expect(DistressSignal.themeFor('I am burnt out and drained'),
          'exhaustion');
      expect(DistressSignal.themeFor('my husband never listens to me'),
          'marriage');
      expect(DistressSignal.themeFor('I am drowning in debt'), 'money');
      expect(DistressSignal.themeFor('I was just diagnosed with cancer'),
          'illness');
      expect(DistressSignal.themeFor('my parents dont understand me'),
          'family');
      expect(DistressSignal.themeFor('Tell me about patience'), isNull);
    });

    test('a third-person remark is not a disclosure', () {
      expect(DistressSignal.packFor('my husband gambles again'), isNull);
      expect(DistressSignal.packFor('why is everyone so stressed nowadays'),
          isNull);
    });
  });

  group('the controller', () {
    test('a heavy heart is heard on the device, never by a live model',
        () async {
      final ProviderContainer c = await container();
      final _Spy live = _Spy();
      final String reply = await c
          .read(hadiControllerProvider.notifier)
          .ask('I feel far from Allah and it hurts', provider: live);
      expect(live.calls, 0);
      expect(reply.trim(), isNotEmpty);
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.fromHadi, isTrue);
      expect(m.sensitive, isTrue);
      expect(m.support, 'being_heard');
      expect(m.helpScope, 'general');
      expect(m.notes, isNotEmpty);
      // The person's own words are marked sensitive too.
      final HadiMessage q = c
          .read(hadiControllerProvider)
          .messages[c.read(hadiControllerProvider).messages.length - 2];
      expect(q.sensitive, isTrue);
    });

    test('the reply names the pain the person named, never a generic line',
        () async {
      final ProviderContainer c = await container();
      final _Spy live = _Spy();
      final String anxious = await c.read(hadiControllerProvider.notifier).ask(
          'I feel anxious and worried all the time', provider: live);
      expect(anxious.toLowerCase(), contains('worr'));
      final ProviderContainer c2 = await container();
      final String far = await c2.read(hadiControllerProvider.notifier).ask(
          'I feel far from Allah and it hurts', provider: _Spy());
      expect(far.toLowerCase(), contains('allah'));
      final ProviderContainer c3 = await container();
      final String lonely = await c3.read(hadiControllerProvider.notifier).ask(
          'I am so lonely, nobody cares about me', provider: _Spy());
      expect(lonely.toLowerCase(), contains('alone'));
    });

    test('a follow-up keeps reflecting the pain the conversation started '
        'with', () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask('I feel far from Allah and it hurts', provider: _Spy());
      final String again =
          await ctrl.ask('it has been like this for months', provider: _Spy());
      // No fresh theme in the follow-up: the same pain is still named.
      expect(again.toLowerCase(), contains('allah'));
    });

    test('grief is answered as grief, still on the device', () async {
      final ProviderContainer c = await container();
      final _Spy live = _Spy();
      await c
          .read(hadiControllerProvider.notifier)
          .ask('My father passed away and I miss him', provider: live);
      expect(live.calls, 0);
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.support, 'grief_loss');
      expect(m.sensitive, isTrue);
    });

    test('a follow-up with no feeling words stays in the same conversation',
        () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      final _Spy live = _Spy();
      await ctrl.ask('I feel anxious and heavy most days', provider: live);
      final String again =
          await ctrl.ask('it has been like this for months', provider: live);
      expect(live.calls, 0);
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.support, isNotNull);
      expect(m.sensitive, isTrue);
      expect(again.trim(), isNotEmpty);
    });

    test('a first "what do I do" about prayers keeps its scholar hand-off',
        () async {
      final ProviderContainer c = await container();
      final _Spy live = _Spy();
      final String a = await c.read(hadiControllerProvider.notifier).ask(
          'I missed my prayers for years, what do I do?',
          provider: live);
      expect(live.calls, 0);
      expect(a.toLowerCase(), contains('qualified scholar'));
    });

    test('after a condolence, "the dua for my mother" is answered by the '
        'checked shelf, not another listening turn', () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask('my mother died last week',
          provider: const OfflineHadiProvider());
      final HadiMessage first =
          c.read(hadiControllerProvider).messages.last;
      expect(first.support, 'grief_loss');
      expect(first.routes, contains('/sakina'));
      final String reply = await ctrl.ask('Yes please, the dua for my mother',
          provider: const OfflineHadiProvider());
      expect(reply, contains('Allahumma ighfir li hayyina'));
    });

    test('every named situation is heard on the device and named back',
        () async {
      const Map<String, List<String>> situations = <String, List<String>>{
        'marriage_strain': <String>[
          'My marriage is hurting me. We keep having the same fight.',
          'marriage',
        ],
        'money_hardship': <String>[
          'I am drowning in bills and debt and I cannot see a way through.',
          'money',
        ],
        'illness_pain': <String>[
          'I was just diagnosed with cancer and I am terrified.',
          'sick',
        ],
        'family_strain': <String>[
          'My family does not understand me and home hurts right now.',
          'family',
        ],
      };
      for (final MapEntry<String, List<String>> e in situations.entries) {
        final ProviderContainer c = await container();
        final _Spy live = _Spy();
        final String reply = await c
            .read(hadiControllerProvider.notifier)
            .ask(e.value[0], provider: live);
        expect(live.calls, 0, reason: e.key);
        expect(reply.trim(), isNotEmpty, reason: e.key);
        final HadiMessage m = c.read(hadiControllerProvider).messages.last;
        expect(m.support, e.key, reason: m.text);
        expect(m.sensitive, isTrue, reason: e.key);
        expect(m.helpScope, 'general', reason: e.key);
        // The reply names the pain the person named, never a generic line.
        expect(reply.toLowerCase(), contains(e.value[1]),
            reason: '${e.key}: $reply');
      }
    });

    test('the crisis layer still wins over distress wording', () async {
      final ProviderContainer c = await container();
      final _Spy live = _Spy();
      await c
          .read(hadiControllerProvider.notifier)
          .ask('I feel hopeless and I want to die', provider: live);
      expect(live.calls, 0);
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.crisis, CrisisKind.selfHarm);
      expect(m.support, isNull);
    });
  });

  group('the fallback wording', () {
    test('every theme has gentle rotated replies with no moralising', () {
      // Word-boundary match, like the pack validator: "confusing" and
      // "single" must not trip on "sin".
      final RegExp banned =
          RegExp(r'\b(?:haram|sins?|punish\w*|forbidden)\b');
      const List<String> themes = <String>[
        'sadness', 'anxiety', 'loneliness', 'far', 'exhaustion',
        'comparison', 'home', 'shame', 'despair', 'heard',
        'marriage', 'money', 'illness', 'family',
      ];
      for (final String theme in themes) {
        final List<String> seen = <String>[
          for (int i = 0; i < 2; i++)
            SupportReplies.buildHeard(prior: i, theme: theme),
        ];
        expect(seen.toSet().length, greaterThan(1), reason: theme);
        for (final String s in seen) {
          expect(banned.hasMatch(s.toLowerCase()), isFalse,
              reason: '$theme: $s');
          expect(RegExp(r'\d').hasMatch(s), isFalse, reason: s);
          expect('?'.allMatches(s).length, lessThanOrEqualTo(1), reason: s);
        }
      }
    });

    test('each theme wording names its own pain', () {
      const Map<String, String> probes = <String, String>{
        'sadness': 'sad',
        'anxiety': 'worr',
        'loneliness': 'alone',
        'far': 'allah',
        'exhaustion': 'worn',
        'comparison': 'everyone',
        'home': 'home',
        'shame': 'shame',
        'despair': 'hopeless',
        'marriage': 'marriage',
        'money': 'money',
        'illness': 'sick',
        'family': 'family',
      };
      probes.forEach((String theme, String needle) {
        final String a = SupportReplies.buildHeard(prior: 0, theme: theme)
            .toLowerCase();
        final String b = SupportReplies.buildHeard(prior: 1, theme: theme)
            .toLowerCase();
        expect(a.contains(needle) || b.contains(needle), isTrue,
            reason: '$theme should name its pain');
      });
    });
  });
}
