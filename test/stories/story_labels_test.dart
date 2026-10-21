import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:flutter_test/flutter_test.dart';

const List<String> _packs = <String>[
  'companions', 'women', 'seerah', 'ghayb', 'tales', 'khutbahs',
  'modernhadith', 'signs',
];

List<Story> _load(String pack) {
  final List<dynamic> list = json.decode(
    File('assets/stories/$pack.json').readAsStringSync(),
  ) as List<dynamic>;
  return list
      .map((dynamic e) => Story.fromJson(e as Map<String, dynamic>))
      .toList();
}

void main() {
  test('every chapter label is legal and the story label is the weakest honest one', () {
    for (final String pack in _packs) {
      for (final Story s in _load(pack)) {
        expect(kStoryLabels, contains(s.sourceLabel), reason: s.id);
        final List<String?> labs =
            s.chapters.map((StoryChapter c) => c.label).toList();
        for (final String? l in labs) {
          if (l != null) expect(kStoryLabels, contains(l), reason: s.id);
        }
        if (labs.contains(kLabelSeerahUnchecked)) {
          expect(s.sourceLabel, kLabelSeerahUnchecked, reason: s.id);
        } else if (labs.contains(kLabelHadithUnchecked)) {
          expect(s.sourceLabel, kLabelHadithUnchecked, reason: s.id);
        }
      }
    }
  });

  test('docs/story_audit.md has a row for every story id', () {
    final String audit = File('docs/story_audit.md').readAsStringSync();
    for (final String pack in _packs) {
      for (final Story s in _load(pack)) {
        expect(audit.contains('| ${s.id} |'), isTrue,
            reason: '${s.id} missing from docs/story_audit.md');
      }
    }
  });

  test('label meanings exist for every label', () {
    for (final String l in kStoryLabels) {
      expect(storyLabelMeaning(l), isNotEmpty, reason: l);
    }
  });

  test('Dhul-Qarnayn story and layers are present and unreviewed', () {
    final Story s = _load('tales')
        .firstWhere((Story x) => x.id == 'tale-dhul-qarnayn');
    expect(s.sourceLabel, kLabelEstablished);
    expect(s.sources.join(' '), contains('18:83-98'));
    final String layers =
        File('assets/stories/layers/dhul-qarnayn.json').readAsStringSync();
    expect(layers, contains('Not yet scholar-reviewed'));
    expect(File('assets/stories/earlier/dhul-qarnayn.json').existsSync(), isTrue);
  });
}
