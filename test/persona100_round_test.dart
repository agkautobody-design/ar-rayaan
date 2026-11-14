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

/// The 100-persona round of 14 Nov 2026: every persona's first question goes
/// through the real controller in a fresh conversation. Each must answer
/// within five seconds (a phone froze on two of them), and the answers are
/// printed so a person can read the whole round.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const List<(String, String)> asks = <(String, String)>[
    ('p1', 'how do i memorize quran fast with a full time job'),
    ('p2', 'what is tajweed and do i need it'),
    ('p3', 'which tafsir should a beginner read'),
    ('p4', 'which english translation of the quran is best'),
    ('p5', 'i miss prayers a lot how do i make them up'),
    ('p6', 'how do i pray when travelling'),
    ('p7', 'can i pray at work if there is no prayer room'),
    ('p8', 'im on my period can i read quran'),
    ('p9', 'how do i do ghusl'),
    ('p10', 'can i do wudu with nail polish on'),
    ('p11', 'what is tayammum'),
    ('p12', 'what do i say after the adhan'),
    ('p13', 'how many rakah is each prayer'),
    ('p14', 'my prayer feels empty i cant concentrate'),
    ('p15', 'what is khushu and how do i get it'),
    ('p16', 'how do i start praying fajr on time'),
    ('p17', 'what is istikhara and how do i do it'),
    ('p18', 'what is the dua for anxiety'),
    ('p19', 'dua for when im stressed about exams'),
    ('p20', 'what dua before eating'),
    ('p21', 'what is the best dhikr after prayer'),
    ('p22', 'what is laylatul qadr and what do i do'),
    ('p23', 'how do i prepare for ramadan'),
    ('p24', 'can i fast if i am pregnant'),
    ('p25', 'what breaks the fast'),
    ('p26', 'how is eid prayer done'),
    ('p27', 'what is zakat al fitr and how much'),
    ('p28', 'is bitcoin halal'),
    ('p29', 'is a mortgage haram'),
    ('p30', 'is working at a bank haram'),
    ('p31', 'is music haram'),
    ('p32', 'is it haram to have a boyfriend'),
    ('p33', 'what does islam say about dating'),
    ('p34', 'what does islam say about gay people'),
    ('p35', 'can a muslim have a tattoo'),
    ('p36', 'is hair dye allowed'),
    ('p37', 'is gelatin halal'),
    ('p38', 'can i eat at a non halal restaurant'),
    ('p39', 'is alcohol in vanilla extract haram'),
    ('p40', 'what is the ruling on shaking hands with the opposite gender'),
    ('p41', 'how do i wear hijab at school when people stare'),
    ('p42', 'my friends are making fun of me for being muslim'),
    ('p43', 'i am being bullied at school'),
    ('p44', 'my teenage son is angry all the time and wont talk to me'),
    ('p45', 'how do i talk to my child about death'),
    ('p46', 'my child asked where is allah how do i answer'),
    ('p47', 'how do i get my kids to love quran'),
    ('p48', 'whats a good bedtime story from islam for a 5 year old'),
    ('p49', 'what duas should my kids learn first'),
    ('p50', 'my husband doesnt pray what should i do'),
    ('p51', 'my wife wants a divorce'),
    ('p52', 'what are the rights of a wife in islam'),
    ('p53', 'what are the rights of a husband in islam'),
    ('p54', 'is polygamy allowed and why'),
    ('p55', 'what is mahr'),
    ('p56', 'how should i treat my in laws'),
    ('p57', 'my mother in law is making my life hard'),
    ('p58', 'how do i take care of elderly parents'),
    ('p59', 'my father is very sick im scared'),
    ('p60', 'i had a miscarriage and feel broken'),
    ('p61', 'we cant have children'),
    ('p62', 'i feel depressed and cant get out of bed'),
    ('p63', 'i think i have waswas about wudu and prayer'),
    ('p64', 'i get intrusive thoughts about god'),
    ('p65', 'i think i am cursed by black magic'),
    ('p66', 'what is the evil eye and how to protect from it'),
    ('p67', 'i keep having nightmares what to recite'),
    ('p68', 'what are jinn'),
    ('p69', 'i committed a big sin and think allah will never forgive me'),
    ('p70', 'how do i make sincere tawbah'),
    ('p71', 'i feel far from allah'),
    ('p72', 'i keep falling into the same sin'),
    ('p73', 'i want to quit smoking'),
    ('p74', 'i want to stop being angry'),
    ('p75', 'how do i stop procrastinating'),
    ('p76', 'how to become a better muslim'),
    ('p77', 'how to deal with stress as a muslim student'),
    ('p78', 'how do i make friends as a new muslim'),
    ('p79', 'i feel lonely at the masjid nobody talks to me'),
    ('p80', 'i want to find a halal way to earn'),
    ('p81', 'how do i start a halal business'),
    ('p82', 'what is riba'),
    ('p83', 'how do i calculate zakat on gold'),
    ('p84', 'how do i give sadaqah'),
    ('p85', 'how much does hajj cost and how do i apply'),
    ('p86', 'what are the steps of umrah'),
    ('p87', 'what is zamzam'),
    ('p88', 'how do i find the qibla'),
    ('p89', 'how do i pray in the summer in canada when isha is so late'),
    ('p90', 'how do i know when ramadan starts'),
    ('p91', 'what is the islamic date today'),
    ('p92', 'is evolution compatible with islam'),
    ('p93', 'why does allah allow suffering'),
    ('p94', 'does islam oppress women'),
    ('p95', 'what does islam say about terrorism'),
    ('p96', 'what is jihad'),
    ('p97', 'is the quran the same today as it was revealed'),
    ('p98', 'who wrote the hadith and how do we know they are true'),
    ('p99', 'why are there so many sects'),
    ('p100', 'what happens after death'),
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
      print('${a.contains('not on my shelf') ? 'MISS ' : ''}PERSONA $id [${sw.elapsedMilliseconds}ms] '
          'crisis=${last.crisis?.name} support=${last.support} '
          'routes=${last.routes}\nQ: $q\nA: ${a.replaceAll('\n', ' ')}\n');
      expect(sw.elapsedMilliseconds, lessThan(5000));
    }, timeout: const Timeout(Duration(seconds: 20)));
  }
}
