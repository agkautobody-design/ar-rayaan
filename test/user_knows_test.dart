import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_samples.dart';
import 'package:ar_rayaan/features/hadi/application/user_knows_provider.dart';
import 'package:ar_rayaan/features/hadi/data/user_knows.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final DateTime _now = DateTime(2026, 11, 18);

UserKnows _learn(UserKnows k, String q, [DateTime? at]) =>
    UserKnowsRules.learn(k, q, at ?? _now);

Future<ProviderContainer> _container(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final SharedPreferences p = await SharedPreferences.getInstance();
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[sharedPreferencesProvider.overrideWithValue(p)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('subjects and what people say about themselves', () {
    test('plain questions map to a subject', () {
      expect(UserKnowsRules.topicOf('How do I pray Witr?'), 'prayer');
      expect(UserKnowsRules.topicOf('what is zakat on gold'), 'zakat');
      expect(UserKnowsRules.topicOf('how do I make wudu'), 'wudu');
      expect(UserKnowsRules.topicOf('when does ramadan start'), 'fasting');
      expect(UserKnowsRules.topicOf('what is the virtue of surah al kahf'), 'quran');
      expect(UserKnowsRules.topicOf('tell me about the battle of uhud'), 'seerah');
      expect(UserKnowsRules.topicOf('how do i do tawaf'), 'hajj');
      expect(UserKnowsRules.topicOf('what is the weather like'), isNull);
    });

    test('roles are only what the person plainly said', () {
      expect(UserKnowsRules.rolesOf('how do I teach my son to pray'), <String>{'parent'});
      expect(UserKnowsRules.rolesOf('I am a mum of three, any advice'), <String>{'parent'});
      expect(UserKnowsRules.rolesOf('I am studying arabic at university'), <String>{'student'});
      expect(UserKnowsRules.rolesOf('I am a new muslim, where do I start'), <String>{'new'});
      expect(UserKnowsRules.rolesOf('how do I pray witr'), isEmpty);
    });
  });

  group('what is never noticed', () {
    for (final String q in <String>[
      'I want to kill myself, how do I pray',
      'my husband hits me and I want to fast',
      'I have diabetes, can I fast in ramadan',
      'I take medication, can I fast',
      'I am 14 and want to learn to pray',
      'I was drinking last night and want to pray',
      'read https://example.com about prayer please',
      'mail me at a@b.com about zakat',
      'my number is 4165550123 zakat question',
    ]) {
      test('"$q"', () {
        expect(UserKnowsRules.mayLearnFrom(q), isFalse);
        expect(_learn(UserKnows.empty, q), same(UserKnows.empty));
      });
    }

    test('a plain question is fine', () {
      expect(UserKnowsRules.mayLearnFrom('How do I pray Witr?'), isTrue);
    });

    test('the notes never hold the question', () {
      final UserKnows k = _learn(UserKnows.empty, 'How do I pray Witr tonight?');
      expect(k.encode().toLowerCase().contains('witr'), isFalse);
      expect(k.encode().toLowerCase().contains('tonight'), isFalse);
    });
  });

  group('building, forgetting, merging', () {
    test('counts, dates, and a first day', () {
      UserKnows k = _learn(UserKnows.empty, 'how do I pray witr');
      k = _learn(k, 'how do I pray two rakahs');
      k = _learn(k, 'what is zakat on gold');
      expect(k.topics['prayer']!.count, 2);
      expect(k.topics['zakat']!.count, 1);
      expect(k.topics['prayer']!.last, '2026-11-18');
      expect(k.since, '2026-11-18');
      expect(k.asked, 3);
    });

    test('a subject unmentioned for 90 days is forgotten', () {
      final UserKnows k = _learn(UserKnows.empty, 'what is zakat on gold');
      final UserKnows later = _learn(k, 'how do I pray witr', _now.add(const Duration(days: 120)));
      expect(later.topics.containsKey('zakat'), isFalse);
      expect(later.topics.containsKey('prayer'), isTrue);
    });

    test('only the strongest eight subjects are kept', () {
      UserKnows k = UserKnows.empty;
      for (final String q in <String>[
        'how do I pray witr', 'what is zakat on gold', 'how do I make wudu',
        'when does ramadan start', 'virtue of surah al kahf', 'a dua for travel',
        'sahih bukhari hadith on niyyah', 'life of the prophet ibrahim',
        'how do I raise my children well', 'how to have patience',
        'how do I do tawaf', 'how do I learn arabic',
      ]) {
        k = _learn(k, q);
      }
      expect(k.topics.length, lessThanOrEqualTo(UserKnowsRules.maxTopics));
    });

    test('a count never passes its cap', () {
      UserKnows k = UserKnows.empty;
      for (int i = 0; i < 80; i++) {
        k = _learn(k, 'how do I pray witr');
      }
      expect(k.topics['prayer']!.count, UserKnowsRules.maxCount);
    });

    test('two copies merge without losing either', () {
      final UserKnows a = _learn(_learn(UserKnows.empty, 'how do I pray witr'), 'how do I pray witr');
      final UserKnows b = _learn(UserKnows.empty, 'what is zakat on gold');
      final UserKnows m = UserKnowsRules.merge(a, b, _now);
      expect(m.topics['prayer']!.count, 2);
      expect(m.topics['zakat']!.count, 1);
    });

    test('saved text round-trips and garbage reads as empty', () {
      final UserKnows k = _learn(UserKnows.empty, 'how do I pray witr');
      final UserKnows r = UserKnows.decode(k.encode());
      expect(r.topics['prayer']!.count, 1);
      expect(UserKnows.decode('not json').isEmpty, isTrue);
      expect(UserKnows.decode(null).isEmpty, isTrue);
      expect(UserKnows.decode('{"t":{"made_up":{"c":3,"d":"2026-01-01"}}}').isEmpty, isTrue);
    });

    test('describe lists every line plainly', () {
      final UserKnows k = UserKnows(
        topics: const <String, KnownTopic>{
          'prayer': KnownTopic(count: 3, last: '2026-11-18'),
        },
        roles: const <String>{'parent'},
      );
      expect(UserKnowsRules.describe(k), <String>[
        'You have children',
        'You often ask about: Prayer (salah)',
      ]);
    });
  });

  group('suggestions', () {
    test('matching chips move up and nothing is removed', () {
      final UserKnows k = UserKnows(
        topics: const <String, KnownTopic>{
          'zakat': KnownTopic(count: 5, last: '2026-11-18'),
        },
      );
      final List<HadiExchange> out = UserKnowsRules.rank<HadiExchange>(
        kProposedHadiExchanges, k, (HadiExchange e) => e.question,
        window: kHadiOpeningChipCount,
      );
      expect(out.length, kProposedHadiExchanges.length);
      expect(out.toSet(), kProposedHadiExchanges.toSet());
      expect(
        out.take(kHadiOpeningChipCount).map((HadiExchange e) => e.question),
        contains('What is zakat?'),
      );
      // The first chips keep their place.
      expect(out.first.question, kProposedHadiExchanges.first.question);
    });

    test('with nothing noticed the order is untouched', () {
      final List<HadiExchange> out = UserKnowsRules.rank<HadiExchange>(
        kProposedHadiExchanges, UserKnows.empty, (HadiExchange e) => e.question,
      );
      expect(out, same(kProposedHadiExchanges));
    });
  });

  group('the notifier', () {
    test('learns, then deletes one and all', () async {
      final ProviderContainer c = await _container(<String, Object>{});
      final UserKnowsNotifier n = c.read(userKnowsProvider.notifier);
      await n.noteQuestion('how do I pray witr');
      expect(c.read(userKnowsProvider).topics.containsKey('prayer'), isTrue);
      await n.forgetTopic('prayer');
      expect(c.read(userKnowsProvider).isEmpty, isTrue);
      await n.noteQuestion('what is zakat on gold');
      await n.forgetAll();
      expect(c.read(userKnowsProvider).isEmpty, isTrue);
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.getString(UserKnowsNotifier.dataPref), isNull);
    });

    test('learns nothing when switched off', () async {
      final ProviderContainer c =
          await _container(<String, Object>{UserKnowsNotifier.onPref: false});
      await c.read(userKnowsProvider.notifier).noteQuestion('how do I pray witr');
      expect(c.read(userKnowsProvider).isEmpty, isTrue);
    });

    test('learns nothing in Private mode', () async {
      final ProviderContainer c =
          await _container(<String, Object>{'ar.support.private_mode': true});
      await c.read(userKnowsProvider.notifier).noteQuestion('how do I pray witr');
      expect(c.read(userKnowsProvider).isEmpty, isTrue);
    });

    test('learns nothing while a child profile is active', () async {
      final ProviderContainer c =
          await _container(<String, Object>{'ar.family.active': 'child-1'});
      await c.read(userKnowsProvider.notifier).noteQuestion('how do I pray witr');
      expect(c.read(userKnowsProvider).isEmpty, isTrue);
    });

    test('learns nothing from health or crisis text', () async {
      final ProviderContainer c = await _container(<String, Object>{});
      final UserKnowsNotifier n = c.read(userKnowsProvider.notifier);
      await n.noteQuestion('I have diabetes, can I fast');
      await n.noteQuestion('I want to die and I cannot pray');
      expect(c.read(userKnowsProvider).isEmpty, isTrue);
    });

    test('turning it off and the notice answers are remembered', () async {
      final ProviderContainer c = await _container(<String, Object>{});
      final UserKnowsNotifier n = c.read(userKnowsProvider.notifier);
      expect(n.on, isTrue);
      expect(n.noticeSeen, isFalse);
      await n.markNoticeSeen();
      expect(c.read(userKnowsProvider.notifier).noticeSeen, isTrue);
      await c.read(userKnowsProvider.notifier).setOn(false);
      expect(c.read(userKnowsProvider.notifier).on, isFalse);
    });
  });

  test('firestore.rules lets only the owner touch users/{uid}/private', () {
    final String rules = File('firestore.rules').readAsStringSync();
    final int at = rules.indexOf('match /users/{uid}');
    expect(at, greaterThan(0));
    final String block = rules.substring(at, rules.indexOf('// ── Online game rooms', at));
    expect(block, contains('request.auth.uid == uid'));
    expect(block, contains('{document=**}'));
  });
}
