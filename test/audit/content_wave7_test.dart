import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// WAVE 7 - new-content integrity: Wasia's curriculum, the Player library,
/// and the Majlis seed must be whole, sourced, and well-formed.
void main() {
  Map<String, dynamic> read(String p) =>
      json.decode(File(p).readAsStringSync()) as Map<String, dynamic>;

  test('W7.1 letters curriculum: 28 lessons, 4 exams, pedagogy intact', () {
    final c = read('assets/academy/letters_curriculum.json');
    var lessons = 0;
    for (final u in c['units'] as List<dynamic>) {
      for (final l in (u as Map)['lessons'] as List<dynamic>) {
        final m = l as Map<String, dynamic>;
        lessons++;
        expect(m['steps'], hasLength(5), reason: m['id']);
        expect((m['steps'] as List).where((s) => (s as Map)['type'] == 'quiz'),
            hasLength(1), reason: '${m['id']} needs exactly one quiz');
        expect((m['title'] as String).isNotEmpty, isTrue);
      }
    }
    expect(lessons, 28);
    expect((c['exams'] as List).length, 4);
    for (final e in c['exams'] as List<dynamic>) {
      final em = e as Map<String, dynamic>;
      expect((em['questions'] as List).length, 10, reason: em['id']);
      for (final q in em['questions'] as List<dynamic>) {
        final qm = q as Map<String, dynamic>;
        expect((qm['answer'] as num).toInt(),
            inInclusiveRange(0, (qm['options'] as List).length - 1));
      }
    }
  });

  test('W7.2 player catalog: 200+ tracks, every entry licensed-honest', () {
    final tracks =
        (read('assets/academy/player_catalog.json')['tracks'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
    expect(tracks.length, greaterThanOrEqualTo(200));
    for (final t in tracks) {
      final playable = (t['audioUrl'] as String? ?? '').isNotEmpty;
      final official = (t['officialUrl'] as String? ?? '').isNotEmpty;
      expect(playable || official, isTrue,
          reason: '${t['id']} must play in-app OR link officially');
      expect((t['title'] as String).isNotEmpty, isTrue);
      expect((t['artist'] as String).isNotEmpty, isTrue);
      expect((t['licenseLine'] as String? ?? '').isNotEmpty, isTrue,
          reason: '${t['id']} owes its license line');
    }
  });

  test('W7.3 majlis seed: room and threads well-formed', () {
    final s = read('assets/majlis/seed.json');
    expect((s['room'] as Map)['id'], 'courtyard');
    final threads = s['threads'] as List<dynamic>;
    expect(threads.length, greaterThanOrEqualTo(3));
    for (final t in threads) {
      final tm = t as Map<String, dynamic>;
      expect((tm['title'] as String).length, greaterThan(4));
      expect((tm['posts'] as List).length, greaterThan(0));
    }
  });
}
