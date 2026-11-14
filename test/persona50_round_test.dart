import 'dart:async';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadi_eval/corpus_fixture.dart';

class _Spy implements HadiProvider {
  @override
  Future<String> ask(String q, List<HadiMessage> h) async =>
      throw StateError('no live model in the persona dump');
}

/// The 50-persona round of 13 Nov 2026: every persona's first question goes
/// through the real controller in a fresh conversation. Each must answer
/// within five seconds (a phone froze on two of them), and the answers are
/// printed so a person can read the whole round.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const List<(String, String)> asks = <(String, String)>[
    ('1', "I just became Muslim yesterday. I don't know how to pray and my family is Christian and angry. What do I do first?"),
    ('2', "I converted last month but my parents don't know. I'm scared to tell them."),
    ('3', 'I know nothing about Islam. Where do I start?'),
    ('4', 'Why should I believe God exists at all?'),
    ('5', 'What do Muslims believe about Jesus?'),
    ('6', 'How is Islam different from Christianity, Judaism, Hinduism and Buddhism?'),
    ('7', 'What do Hindus believe and how is it different from Islam?'),
    ('8', 'Is Buddhism compatible with Islam?'),
    ('9', 'Do Muslims and Jews worship the same God?'),
    ('10', 'Which religion is true?'),
    ('11', 'Tell me the story of Prophet Yunus'),
    ('12', 'Tell me about Prophet Hud and the people of Aad'),
    ('13', 'who was jonah in islam'),
    ('14', 'story of yusuf and his brothers'),
    ('15', 'list all the prophets in order'),
    ('17', "I can't read Arabic. How do I learn to read the Quran?"),
    ('18', 'I want to learn Arabic so I can understand the Quran. How?'),
    ('21', 'How can I memorise Surah Al-Mulk?'),
    ('22', 'I am 8 years old. Who is Allah?'),
    ('24', 'How do I teach my 6 year old son to pray without forcing him?'),
    ('25', "My 15 year old daughter won't pray and is always on her phone."),
    ('26', 'My husband shouts at me and controls all the money. I feel trapped.'),
    ('27', 'My wife and I barely talk anymore. How do I fix my marriage?'),
    ('28', 'Is divorce allowed in Islam?'),
    ('29', 'I have been drinking every night and I am ashamed. I want to stop.'),
    ('30', "I'm addicted to painkillers and I can't stop"),
    ('31', 'I keep betting on sports and lost my savings'),
    ('32', 'I keep watching porn and I feel disgusting after'),
    ('33', "My mother died last week. I can't stop crying."),
    ('34', 'I feel so alone, nobody cares about me'),
    ('35', 'I have panic attacks before work'),
    ('36', "I don't want to live anymore"),
    ('37', 'how do i do wudu'),
    ('38', 'when is fajr'),
    ('39', "It's my first Ramadan, how do I fast?"),
    ('40', 'How much zakat do I pay on \$10,000 savings?'),
    ('41', 'What are the steps of Hajj?'),
    ('42', 'Tell me about the life of Prophet Muhammad'),
    ('43', 'Give me a hadith about kindness'),
    ('44', 'Is shrimp halal?'),
    ('46', "I lost my job and can't pay rent"),
    ('47', "I'm Muslim but I have doubts about my faith"),
    ('48', 'Is hijab compulsory?'),
    ('49', 'What is the difference between Sunni and Shia?'),
    ('50', 'Can you just talk to me for a bit? I had a bad day.'),
  ];
  for (final (String id, String q) in asks) {
    test('persona $id answers in time', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final HadiCorpus corpus = loadRealCorpus();
      final ProviderContainer c = ProviderContainer(overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        hadiCorpusProvider.overrideWith((ref) => corpus),
      ]);
      addTearDown(c.dispose);
      final Stopwatch sw = Stopwatch()..start();
      final String a = await c
          .read(hadiControllerProvider.notifier)
          .ask(q, provider: _Spy())
          .timeout(const Duration(seconds: 5));
      final HadiMessage last = c.read(hadiControllerProvider).messages.last;
      // ignore: avoid_print
      print('PERSONA $id [${sw.elapsedMilliseconds}ms] '
          'crisis=${last.crisis?.name} support=${last.support?.name} '
          'routes=${last.routes}\nQ: $q\nA: ${a.replaceAll('\n', ' ')}\n');
      expect(sw.elapsedMilliseconds, lessThan(5000));
    }, timeout: const Timeout(Duration(seconds: 20)));
  }
}
