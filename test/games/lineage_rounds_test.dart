import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ar_rayaan/features/games/data/lineage_rounds.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Lineage Challenge used to ask "who is the parent" with parents.first
/// (so Fatima's other parent could be a wrong choice), put every answer first,
/// and say "carries the line of Ismail" for everyone. These tests read the real
/// family tree and run the game's builder over many seeds.
void main() {
  late Map<String, dynamic> tree;
  late Map<String, Map<String, dynamic>> byName;
  late Map<String, Map<String, dynamic>> byId;

  List<String> strings(Map<String, dynamic> n, String key) =>
      ((n[key] as List<dynamic>?) ?? <dynamic>[]).cast<String>();

  setUpAll(() {
    tree = json.decode(File('assets/family/tree.json').readAsStringSync())
        as Map<String, dynamic>;
    final List<Map<String, dynamic>> nodes = (tree['nodes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    byName = <String, Map<String, dynamic>>{
      for (final Map<String, dynamic> n in nodes) n['name'] as String: n,
    };
    byId = <String, Map<String, dynamic>>{
      for (final Map<String, dynamic> n in nodes) n['id'] as String: n,
    };
  });

  List<List<LineageRound>> manyGames() => <List<LineageRound>>[
        for (int seed = 0; seed < 300; seed++)
          buildLineageRounds(tree, Random(seed)),
      ];

  test('every game has parent rounds and river rounds', () {
    for (final List<LineageRound> game in manyGames()) {
      expect(game.where((LineageRound r) => !r.isRiver).length,
          greaterThanOrEqualTo(6));
      expect(game.where((LineageRound r) => r.isRiver).length, 2);
    }
  });

  test('a parent round has exactly one true parent among its choices', () {
    for (final List<LineageRound> game in manyGames()) {
      for (final LineageRound r in game.where((LineageRound r) => !r.isRiver)) {
        final Map<String, dynamic> child = byName[r.subject]!;
        final Set<String> parentNames = <String>{
          for (final String p in strings(child, 'parents'))
            byId[p]!['name'] as String,
        };
        expect(r.options.length, 3, reason: r.prompt);
        expect(r.options.toSet().length, 3, reason: '${r.prompt}: duplicate choice');
        final int trueOnes =
            r.options.where((String o) => parentNames.contains(o)).length;
        expect(trueOnes, 1,
            reason: '${r.prompt}: a second true parent is offered as a wrong choice');
        expect(parentNames.contains(r.options[r.answer]), isTrue,
            reason: '${r.prompt}: the marked answer is not a parent');
        // The explanation names every parent, not just parents.first.
        for (final String name in parentNames) {
          expect(r.why.contains(name), isTrue, reason: '${r.prompt} / $name');
        }
      }
    }
  });

  test('a person with two parents can be asked about either one', () {
    final Set<String> seenForMaryam = <String>{};
    for (final List<LineageRound> game in manyGames()) {
      for (final LineageRound r in game) {
        if (r.subject == 'Maryam bint Imran' && !r.isRiver) {
          seenForMaryam.add(r.options[r.answer]);
        }
      }
    }
    expect(seenForMaryam, <String>{
      'Imran, father of Maryam',
      'The wife of Imran',
    });
  });

  test('only Established people are asked about; no folded rows, no guesses', () {
    for (final List<LineageRound> game in manyGames()) {
      for (final LineageRound r in game) {
        final Map<String, dynamic> n = byName[r.subject]!;
        expect(n['sourceLabel'], 'Established', reason: r.prompt);
        for (final String o in r.options) {
          expect(o.contains('…'), isFalse, reason: '${r.prompt}: "$o"');
        }
        expect(r.prompt.contains('…'), isFalse);
        if (!r.isRiver) {
          for (final String p in strings(n, 'parents')) {
            expect(byId[p]!['sourceLabel'], 'Established',
                reason: '${r.subject} has a parent that is not Established');
            expect((byId[p]!['name'] as String).startsWith('…'), isFalse);
          }
        }
      }
    }
  });

  test('the river round names the right river and moves the answer around', () {
    final Set<int> positions = <int>{};
    final Set<String> asked = <String>{};
    for (final List<LineageRound> game in manyGames()) {
      for (final LineageRound r in game.where((LineageRound r) => r.isRiver)) {
        asked.add(r.subject);
        positions.add(r.answer);
        expect(r.options.toSet(),
            <String>{kFirstRiver, kSecondRiver, kNeitherRiver});
        if (r.subject == 'Ismail') {
          expect(r.options[r.answer], kFirstRiver);
          expect(r.why.contains('Kinana'), isTrue);
          expect(r.why.contains('second river'), isFalse);
        } else {
          expect(r.options[r.answer], kSecondRiver, reason: r.subject);
          // The old explanation said "carries the line of Ismail" for everyone.
          expect(r.why.contains('Ismail'), isFalse, reason: r.subject);
          expect(r.why.contains('second river'), isTrue, reason: r.subject);
        }
      }
    }
    expect(positions.length, 3, reason: 'the correct choice must not always be first');
    expect(asked, <String>{'Ismail', 'Ishaq', 'Ya\'qub (Israel)', 'Yusuf'});
  });

  test('Ibrahim, Sarah and Hajar are never put on a single river', () {
    for (final List<LineageRound> game in manyGames()) {
      for (final LineageRound r in game.where((LineageRound r) => r.isRiver)) {
        expect(<String>['Ibrahim', 'Sarah', 'Hajar'].contains(r.subject), isFalse);
      }
    }
  });
}
