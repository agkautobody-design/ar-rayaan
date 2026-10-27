import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/sakina/domain/sakina_content.dart';
import 'package:ar_rayaan/features/support/data/helplines_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => HelpResources.extra = <HelpResource>[]);

  test('the shipped file parses to verified rows only', () {
    final String raw = File('assets/support/helplines.json').readAsStringSync();
    final List<HelpResource> rows = HelplinesLoader.parse(raw);
    expect(rows.length, greaterThan(50));
    for (final HelpResource r in rows) {
      expect(r.verified, isTrue, reason: r.name);
      expect(r.source!.startsWith('https://'), isTrue, reason: r.name);
      expect(r.dial != null || r.url != null, isTrue, reason: r.name);
    }
    final Map<String, dynamic> doc = json.decode(raw) as Map<String, dynamic>;
    final Set<String> hidden = <String>{
      for (final dynamic e in doc['toVerify'] as List<dynamic>)
        if (((e as Map<String, dynamic>)['number'] ?? '').toString().isNotEmpty)
          '${e['country']}|${e['number']}',
    };
    for (final HelpResource r in rows) {
      expect(hidden.contains('${r.countries.join(',')}|${r.contact}'), isFalse, reason: 'unverified: ${r.name}');
    }
  });

  test('a row that is not verified, or has no source, is dropped', () {
    final String raw = json.encode(<String, Object>{
      'helplines': <Object>[
        <String, Object?>{
          'id': 'a', 'country': 'US', 'service': 'A', 'number': '988',
          'status': 'unverified', 'verifiedOn': '2026-10-27',
          'source': 'https://x.example/', 'scope': <String>['suicide'],
        },
        <String, Object?>{
          'id': 'b', 'country': 'US', 'service': 'B', 'number': '988',
          'status': 'verified', 'verifiedOn': null,
          'source': 'https://x.example/', 'scope': <String>['suicide'],
        },
        <String, Object?>{
          'id': 'c', 'country': 'US', 'service': 'C', 'number': '988',
          'status': 'verified', 'verifiedOn': '2026-10-27',
          'source': null, 'scope': <String>['suicide'],
        },
      ],
    });
    expect(HelplinesLoader.parse(raw), isEmpty);
    expect(HelplinesLoader.parse('not json'), isEmpty);
  });

  test('loaded rows join by scope and country, country first', () {
    HelpResources.extra =
        HelplinesLoader.parse(File('assets/support/helplines.json').readAsStringSync());
    final List<HelpResource> us = HelplinesLoader.forScope('gambling', 'US');
    expect(us, isNotEmpty);
    expect(us.first.countries, <String>['US']);
    expect(HelplinesLoader.forScope('gambling', null).every(
        (HelpResource r) => r.countries.isEmpty), isTrue);
  });

  test('every emergency row on screen names its source and day', () {
    HelpResources.extra =
        HelplinesLoader.parse(File('assets/support/helplines.json').readAsStringSync());
    for (final HelpResource r in HelpResources.shown) {
      if (r.kinds.contains(HelpKind.emergency)) {
        expect(r.verified, isTrue, reason: '${r.region} ${r.contact}');
      }
    }
  });
}
