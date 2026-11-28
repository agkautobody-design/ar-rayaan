import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/data/user_knows.dart';
import 'package:ar_rayaan/features/support/domain/knowledge_answerer.dart';
import 'package:ar_rayaan/features/support/domain/support_pack.dart';

SupportPack _load(String name) {
  final String raw = File('assets/support/packs/$name.json').readAsStringSync();
  final SupportPack? p = SupportPack.parse(raw);
  expect(p, isNotNull, reason: name);
  return p!;
}

void main() {
  final List<SupportPack> packs = <SupportPack>[
    for (final String n in <String>[
      'closeness_to_allah',
      'goals_and_purpose',
      'consistency_habits',
      'patience_gratitude',
      'fresh_start_hope',
      'growth_everyday',
      'character_in_daily_life',
      'family_roles_growth',
      'work_money_study_growth',
      'faith_and_heart',
      'worship_better',
    ])
      _load(n),
  ];

  group('growth packs answer on their own', () {
    test('feeling close to Allah', () {
      final KnowledgeAnswer? a =
          KnowledgeAnswerer.answer('how do I feel closer to Allah', packs);
      expect(a, isNotNull);
      expect(a!.snippet.pack, 'closeness_to_allah');
    });
    test('goals', () {
      expect(KnowledgeAnswerer.answer('help me accomplish my goals', packs)!.snippet.pack,
          'goals_and_purpose');
    });
    test('everyday life questions', () {
      expect(KnowledgeAnswerer.answer('how do I forgive someone who hurt me', packs)!.snippet.pack,
          'character_in_daily_life');
      expect(KnowledgeAnswerer.answer('how do I teach my kids to pray', packs)!.snippet.pack,
          'family_roles_growth');
      expect(KnowledgeAnswerer.answer('why does Allah allow suffering', packs)!.snippet.pack,
          'faith_and_heart');
    });
    test('a plain prayer-time question is left to the app', () {
      final KnowledgeAnswer? a = KnowledgeAnswerer.answer('what time is maghrib', packs);
      expect(a == null || !packs.any((SupportPack p) => p.name == a.snippet.pack && p.name == 'worship_better'), isTrue);
    });
    test('starting again', () {
      expect(KnowledgeAnswerer.answer('can I start again', packs)!.snippet.pack,
          'fresh_start_hope');
    });
  });

  group('follow-ups continue the last answer', () {
    test('detects a follow-up', () {
      expect(KnowledgeAnswerer.isFollowUp('I get that but what can I do to start feeling it'), isTrue);
      expect(KnowledgeAnswerer.isFollowUp('tell me more'), isTrue);
      expect(KnowledgeAnswerer.isFollowUp('how do I pray witr'), isFalse);
      expect(KnowledgeAnswerer.isFollowUp('what is the ruling on interest in a mortgage for a family home'), isFalse);
    });
    test('goes to another answer in the same pack, not the same one', () {
      final KnowledgeAnswer first =
          KnowledgeAnswerer.answer('how do I feel closer to Allah', packs)!;
      final KnowledgeAnswer? next = KnowledgeAnswerer.followUp(
          'I get that but what can I do to start feeling it', first.snippet, packs);
      expect(next, isNotNull);
      expect(next!.snippet.pack, first.snippet.pack);
      expect(next.snippet.id, isNot(first.snippet.id));
    });
    test('skips what was already given', () {
      final KnowledgeAnswer first =
          KnowledgeAnswerer.answer('how do I feel closer to Allah', packs)!;
      final Set<String> seen = <String>{};
      KnowledgeAnswer? n = KnowledgeAnswerer.followUp('what else', first.snippet, packs,
          isSeen: seen.contains);
      while (n != null) {
        expect(seen.add(n.snippet.id), isTrue);
        n = KnowledgeAnswerer.followUp('what else', first.snippet, packs, isSeen: seen.contains);
      }
      expect(seen.length, packs.firstWhere((SupportPack p) => p.name == first.snippet.pack).snippets.length - 1);
    });
  });

  group('places Hadi sends people to', () {
    test('every button route a growth answer carries is allowed', () {
      for (final SupportPack p in packs) {
        for (final SupportSnippet s in p.snippets) {
          for (final String r in KnowledgeAnswerer.routesFor(
            s,
            isGuide: kHadiGuideNames.containsKey,
            screens: kHadiGrowthScreens,
          )) {
            expect(HadiTokens.isAllowed(r), isTrue, reason: '${s.id} $r');
          }
        }
      }
    });
    test('most growth answers point somewhere', () {
      int linked = 0;
      int total = 0;
      for (final SupportPack p in packs) {
        for (final SupportSnippet s in p.snippets) {
          total++;
          if (KnowledgeAnswerer.routesFor(s,
                  isGuide: kHadiGuideNames.containsKey, screens: kHadiGrowthScreens)
              .isNotEmpty) {
            linked++;
          }
        }
      }
      expect(linked / total, greaterThan(0.5));
    });
  });

  group('what Hadi remembers', () {
    test('growth subjects are noticed', () {
      expect(UserKnowsRules.topicOf('how do I feel closer to Allah'), 'closeness');
      expect(UserKnowsRules.topicOf('help me achieve my goals'), 'goals');
      expect(UserKnowsRules.topicOf('how do I stay consistent'), 'habits');
      expect(UserKnowsRules.topicOf('how do I have sabr'), 'patience');
      expect(UserKnowsRules.topicOf('can I start again'), 'freshstart');
      expect(UserKnowsRules.labels.containsKey('closeness'), isTrue);
    });
    test('a knowledge answer id is stored as a valid id', () {
      final String id = UserKnowsRules.coveredId('kn-closeness_to_allah.howto.001');
      expect(UserKnowsRules.idRe.hasMatch(id), isTrue);
      final UserKnows k = UserKnowsRules.learn(
          UserKnows.empty, 'how do I feel closer to Allah', DateTime(2026, 11, 27),
          answerId: id);
      expect(k.covered.containsKey(id), isTrue);
      expect(UserKnows.decode(k.encode()).covered.containsKey(id), isTrue);
    });
  });

  test('pack json is valid', () {
    for (final SupportPack p in packs) {
      expect(jsonDecode(File('assets/support/packs/${p.name}.json').readAsStringSync()), isA<Map<String, dynamic>>());
    }
  });
}
