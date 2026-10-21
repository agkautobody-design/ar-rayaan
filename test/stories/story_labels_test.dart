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
  unverifiedLabelTests();
  test('weak narrations in source lines are detected', () {
    int weak = 0;
    for (final String pack in _packs) {
      for (final Story s in _load(pack)) {
        final bool named = s.sources.any((String x) =>
            x.toLowerCase().contains('daif') ||
            x.toLowerCase().contains("da'if"));
        expect(s.hasWeakNarration, named, reason: s.id);
        if (named) weak++;
      }
    }
    expect(weak, greaterThan(0));
  });
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
        } else if (labs.contains(kLabelSeerah)) {
          expect(s.sourceLabel, kLabelSeerah, reason: s.id);
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

  test('a chapter labelled Seerah report names the book and page it was read in', () {
    for (final String pack in _packs) {
      final List<dynamic> raw = json.decode(
        File('assets/stories/$pack.json').readAsStringSync(),
      ) as List<dynamic>;
      for (final dynamic e in raw) {
        final Map<String, dynamic> m = e as Map<String, dynamic>;
        final List<dynamic> chapters = m['chapters'] as List<dynamic>;
        final bool has = chapters.any(
            (dynamic c) => (c as Map<String, dynamic>)['label'] == kLabelSeerah);
        if (!has) continue;
        final String src = (m['sources'] as List<dynamic>).join(' ');
        expect(RegExp(r'Ibn Hisham|al-Tabari|Ibn Kathir|Ibn al-Athir|Ibn Sa.d|al-Waqidi')
            .hasMatch(src), isTrue, reason: '${m['id']}: names no book');
        expect(RegExp(r'vol\. ?\d|ج ?\d|p\. ?\d|pp\. ?\d').hasMatch(src), isTrue,
            reason: '${m['id']}: names no volume/page');
        final String audit = File('docs/story_audit.md').readAsStringSync();
        expect(
            audit.split('\n').any((String l) =>
                l.contains('| ${m['id']} |') &&
                l.contains('Label: Seerah report. Read:')),
            isTrue,
            reason: '${m['id']}: no "Label: Seerah report. Read:" row in docs/story_audit.md');
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

void unverifiedLabelTests() {
  group('unverified wording', () {
    test('unchecked labels are shown as Unverified', () {
      expect(isUnverifiedLabel(kLabelSeerahUnchecked), isTrue);
      expect(isUnverifiedLabel(kLabelHadithUnchecked), isTrue);
      expect(isUnverifiedLabel(kLabelSeerah), isFalse);
      expect(storyLabelDisplay(kLabelSeerahUnchecked), startsWith('Unverified'));
      expect(storyLabelDisplay(kLabelHadithUnchecked), startsWith('Unverified'));
      expect(storyLabelMeaning(kLabelSeerahUnchecked), startsWith('UNVERIFIED'));
      expect(storyLabelMeaning(kLabelHadithUnchecked), startsWith('UNVERIFIED'));
    });
  });
}
