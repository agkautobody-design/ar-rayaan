import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Worship guides audit (October 2026): the rewritten and new guides keep
/// their school-by-school notes and cite a source for every ruling.
void main() {
  final List<Map<String, dynamic>> guides = (json.decode(
    File('assets/guides/guides.json').readAsStringSync(),
  ) as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final Map<String, Map<String, dynamic>> byId = <String, Map<String, dynamic>>{
    for (final Map<String, dynamic> g in guides) g['id'] as String: g,
  };

  const List<String> withSchools = <String>[
    'huda-prayer', 'huda-wudu', 'huda-ghusl', 'huda-tayammum', 'huda-masah',
    'huda-menstruation', 'huda-adhan', 'huda-jumuah', 'huda-qada',
    'huda-nawafil', 'huda-witr', 'huda-sujud-sahw', 'huda-prayer-times',
    'huda-congregation', 'huda-travel-prayer', 'huda-janazah-wash',
    'huda-janazah-prayer', 'huda-janazah-burial', 'huda-mosque',
  ];

  test('rewritten and new worship guides exist with a note on the schools', () {
    for (final String id in withSchools) {
      final Map<String, dynamic>? g = byId[id];
      expect(g, isNotNull, reason: '$id missing');
      final String note = (g!['madhhabNote'] as String?) ?? '';
      expect(note.trim(), isNotEmpty, reason: '$id has no madhhabNote');
      expect(note.contains('Hanafi'), isTrue, reason: '$id note: Hanafi');
      expect(note.contains('Shafi'), isTrue, reason: '$id note: Shafi\'i');
    }
  });

  test('every guide has sources and a unique title', () {
    final Set<String> titles = <String>{};
    for (final Map<String, dynamic> g in guides) {
      expect((g['sources'] as List<dynamic>).isNotEmpty, isTrue,
          reason: '${g['id']}');
      expect(titles.add(g['title'] as String), isTrue,
          reason: 'duplicate title ${g['title']}');
    }
  });

  test('tayammum no longer contradicts itself on the strikes', () {
    final String all = (byId['huda-tayammum']!['steps'] as List<dynamic>).join('\n');
    expect(all.contains('strike again'), isFalse);
    expect((byId['huda-tayammum']!['madhhabNote'] as String).contains('two strikes'),
        isTrue);
  });

  test('qada states the Maliki position and the rawatib do not contradict', () {
    expect((byId['huda-qada']!['madhhabNote'] as String).contains('Maliki'), isTrue);
    final String raw = (byId['huda-nawafil']!['steps'] as List<dynamic>).join('\n');
    expect(raw.contains('four before (and two after)'), isFalse);
  });

  test('no step is a bare fragment or leaves a placeholder', () {
    for (final Map<String, dynamic> g in guides) {
      for (final dynamic s in g['steps'] as List<dynamic>) {
        final String t = s as String;
        expect(t.contains('see below'), isFalse, reason: '${g['id']}: $t');
        expect(t.trim().length, greaterThan(20), reason: '${g['id']}: $t');
      }
    }
  });
}
