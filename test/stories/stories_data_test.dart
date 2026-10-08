import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all shipped story packs parse into valid Stories', () {
    final packs = ['prophets', 'women', 'seerah', 'companions', 'signs', 'tales'];
    var total = 0;
    for (final pack in packs) {
      final f = File('assets/stories/$pack.json');
      if (!f.existsSync()) continue;
      final list = json.decode(f.readAsStringSync()) as List<dynamic>;
      for (final e in list) {
        final s = Story.fromJson(e as Map<String, dynamic>);
        expect(s.id, isNotEmpty);
        expect(s.title, isNotEmpty);
        expect(s.sources, isNotEmpty, reason: 'every story must cite its sources');
        expect(
          s.sourceLabel == 'Established' || s.sourceLabel == 'Interpretive',
          isTrue,
          reason: 'source label must follow the integrity law',
        );
        expect(s.chapters, isNotEmpty);
        expect(s.familyQuestion, isNotEmpty);
        for (final c in s.chapters) {
          expect(c.body.length, greaterThan(100),
              reason: 'chapters must be real chapters');
        }
        total++;
      }
    }
    expect(total, greaterThanOrEqualTo(6));
  });
}
