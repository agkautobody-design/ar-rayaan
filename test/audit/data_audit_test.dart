import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ADVERSARIAL DATA AUDIT — wave 1.
/// Assumes nothing. Tries to break every pack.
void main() {
  const packs = [
    'prophets', 'women', 'seerah', 'companions', 'ghayb',
    'signs', 'tales', 'khutbahs', 'modernhadith', 'dailyduas',
  ];

  Map<String, dynamic> readJson(String p) =>
      json.decode(File(p).readAsStringSync()) as Map<String, dynamic>;
  List<dynamic> readList(String p) =>
      json.decode(File(p).readAsStringSync()) as List<dynamic>;

  test('W1.1 all story packs exist and parse', () {
    var total = 0;
    for (final p in packs) {
      final f = File('assets/stories/$p.json');
      expect(f.existsSync(), isTrue, reason: 'missing pack $p');
      final list = json.decode(f.readAsStringSync()) as List<dynamic>;
      expect(list, isNotEmpty, reason: 'empty pack $p');
      total += list.length;
    }
    expect(total, greaterThan(150));
  });

  test('W1.2 story entry structure — paranoid field sweep', () {
    final ids = <String>{};
    final lenExceptions = {'modernhadith': 60, 'dailyduas': 60, 'khutbahs': 200};
    for (final p in packs) {
      final minLen = lenExceptions[p] ?? 100;
      for (final e in readList('assets/stories/$p.json')) {
        final m = e as Map<String, dynamic>;
        expect(m['id'], isNotNull, reason: '$p: entry without id');
        expect(ids.add(m['id'] as String), isTrue,
            reason: 'DUPLICATE story id: ${m['id']}');
        expect((m['title'] as String).trim().isNotEmpty, isTrue,
            reason: '${m['id']}: empty title');
        expect((m['kicker'] as String).trim().isNotEmpty, isTrue,
            reason: '${m['id']}: empty kicker');
        expect((m['subtitle'] as String).trim().isNotEmpty, isTrue,
            reason: '${m['id']}: empty subtitle');
        expect((m['familyQuestion'] as String).trim().isNotEmpty, isTrue,
            reason: '${m['id']}: empty familyQuestion');
        final sources = m['sources'] as List<dynamic>;
        expect(sources.length, greaterThan(0), reason: '${m['id']}: no sources');
        for (final s in sources) {
          expect((s as String).trim().length, greaterThan(5),
              reason: '${m['id']}: suspiciously short source');
        }
        expect(m['sourceLabel'] == 'Established' || m['sourceLabel'] == 'Interpretive',
            isTrue, reason: '${m['id']}: illegal sourceLabel');
        final chapters = m['chapters'] as List<dynamic>;
        expect(chapters, isNotEmpty, reason: '${m['id']}: no chapters');
        for (final c in chapters) {
          final cm = c as Map<String, dynamic>;
          expect((cm['body'] as String).length, greaterThan(minLen),
              reason: '${m['id']}: chapter body too short');
          final ar = cm['arabic'];
          if (ar != null) {
            expect((ar as String).length, greaterThan(10),
                reason: '${m['id']}: suspicious arabic block');
          }
        }
      }
    }
  });

  test('W1.3 guides: 40 guides, steps and sources intact', () {
    final list = readList('assets/guides/guides.json');
    expect(list.length, 44, reason: 'guide count drifted (40 + Hajj/Umrah pack)');
    for (final e in list) {
      final m = e as Map<String, dynamic>;
      expect((m['steps'] as List).length, greaterThanOrEqualTo(3),
          reason: '${m['id']}: too few steps');
      expect((m['sources'] as List).isNotEmpty, isTrue,
          reason: '${m['id']}: no sources');
    }
  });

  test('W1.4 trivia: 40 questions, valid answer indices', () {
    final list = readList('assets/games/trivia.json');
    expect(list.length, greaterThanOrEqualTo(40));
    final ids = <String>{};
    for (final e in list) {
      final m = e as Map<String, dynamic>;
      expect(ids.add(m['id'] as String), isTrue);
      final opts = m['options'] as List;
      expect(opts.length, 4, reason: '${m['id']}: options != 4');
      final a = m['answer'] as num;
      expect(a.toInt(), inInclusiveRange(0, 3),
          reason: '${m['id']}: answer index out of range');
      expect((m['why'] as String).length, greaterThan(10),
          reason: '${m['id']}: missing explanation');
    }
  });

  test('W1.5 99 names: exactly 99, unique, complete', () {
    final list = readList('assets/games/names99.json');
    expect(list.length, 99, reason: 'names deck is not 99');
    final names = <String>{};
    for (final e in list) {
      final m = e as Map<String, dynamic>;
      expect(names.add(m['name'] as String), isTrue,
          reason: 'duplicate name ${m['name']}');
      expect((m['meaning'] as String).trim().isNotEmpty, isTrue);
      expect((m['ref'] as String).trim().isNotEmpty, isTrue);
    }
  });

  test('W1.6 family tree: all relational references resolve', () {
    final nodes = (readJson('assets/family/tree.json')['nodes'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final ids = nodes.map((n) => n['id'] as String).toSet();
    expect(ids.length, nodes.length, reason: 'duplicate node ids');
    for (final n in nodes) {
      for (final key in ['parents', 'spouses', 'children']) {
        for (final ref in (n[key] as List<dynamic>? ?? const [])) {
          expect(ids.contains(ref as String), isTrue,
              reason: '${n['id']}: dangling $key reference -> $ref');
        }
      }
      expect(const ['root', 'branch', 'ismail', 'ishaq']
          .contains(n['river'] as String), isTrue,
          reason: '${n['id']}: illegal river');
      expect((n['description'] as String).length, greaterThan(20),
          reason: '${n['id']}: description too short');
      expect((n['sources'] as List).isNotEmpty, isTrue,
          reason: '${n['id']}: no sources');
    }
  });

  test('W1.7 content version manifest covers every shipped pack', () {
    final ver = readJson('assets/content_version.json');
    for (final p in packs) {
      expect(ver['stories/$p.json'], isNotNull,
          reason: '$p.json has no version entry — ContentSync will never fetch it');
    }
    for (final extra in ['family/tree.json', 'guides/guides.json',
        'games/trivia.json', 'games/names99.json', 'feelings/feelings.json']) {
      expect(ver[extra], isNotNull, reason: '$extra unversioned');
    }
  });
}
